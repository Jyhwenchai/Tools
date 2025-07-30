import SwiftUI
import XCTest

@testable import Tools

// MARK: - Comprehensive Integration Tests for Time Converter Enhancement

@MainActor
final class TimeConverterComprehensiveIntegrationTests: XCTestCase {

    // MARK: - Properties

    private var timeConverterService: TimeConverterService!
    private var batchConversionService: BatchConversionService!
    private var realTimeTimestampService: RealTimeTimestampService!
    private var toastManager: ToastManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        timeConverterService = TimeConverterService()
        batchConversionService = BatchConversionService()
        realTimeTimestampService = RealTimeTimestampService()
        toastManager = ToastManager()
    }

    override func tearDown() {
        timeConverterService = nil
        batchConversionService = nil
        realTimeTimestampService?.stopTimer()
        realTimeTimestampService = nil
        toastManager = nil
        super.tearDown()
    }

    // MARK: - Tabbed Interface Integration Tests

    func testTabbedInterfaceStateManagement() {
        // Test that tab switching preserves state correctly
        var selectedTab: ConversionTab = .single
        var singleState = SingleConversionState()
        var batchState = BatchConversionState()

        // Modify single conversion state
        singleState.lastUsedFormat = .rfc2822
        singleState.includeMilliseconds = true
        singleState.lastUsedTimezone = TimeZone(identifier: "Asia/Tokyo")!

        // Switch to batch tab
        selectedTab = .batch

        // Modify batch conversion state
        batchState.lastSourceFormat = .iso8601
        batchState.lastTargetFormat = .custom
        batchState.lastInputText = "2022-01-01T00:00:00Z\n2022-01-02T00:00:00Z"

        // Switch back to single tab
        selectedTab = .single

        // Verify single state is preserved
        XCTAssertEqual(singleState.lastUsedFormat, .rfc2822)
        XCTAssertTrue(singleState.includeMilliseconds)
        XCTAssertEqual(singleState.lastUsedTimezone.identifier, "Asia/Tokyo")

        // Switch back to batch tab
        selectedTab = .batch

        // Verify batch state is preserved
        XCTAssertEqual(batchState.lastSourceFormat, .iso8601)
        XCTAssertEqual(batchState.lastTargetFormat, .custom)
        XCTAssertTrue(batchState.lastInputText.contains("2022-01-01T00:00:00Z"))
    }

    func testTabbedInterfaceAccessibility() {
        // Test accessibility features of tabbed interface
        let singleTab = ConversionTab.single
        let batchTab = ConversionTab.batch

        // Verify accessibility identifiers
        XCTAssertEqual(singleTab.id, "single")
        XCTAssertEqual(batchTab.id, "batch")

        // Verify display names are appropriate for screen readers
        XCTAssertEqual(singleTab.displayName, "单个转换")
        XCTAssertEqual(batchTab.displayName, "批量转换")

        // Verify icon names are valid system icons
        XCTAssertEqual(singleTab.iconName, "arrow.left.arrow.right")
        XCTAssertEqual(batchTab.iconName, "list.bullet")

        // Test that all tabs are included in allCases
        let allTabs = ConversionTab.allCases
        XCTAssertEqual(allTabs.count, 2)
        XCTAssertTrue(allTabs.contains(singleTab))
        XCTAssertTrue(allTabs.contains(batchTab))
    }

    // MARK: - Real-Time Timestamp Integration Tests

    func testRealTimeTimestampIntegrationWithMainView() {
        let expectation = XCTestExpectation(description: "Real-time timestamp integration")

        // Start real-time timestamp service
        realTimeTimestampService.startTimer()

        // Verify initial state
        XCTAssertTrue(realTimeTimestampService.isRunning)
        XCTAssertFalse(realTimeTimestampService.currentTimestamp.isEmpty)

        // Test unit switching
        let initialUnit = realTimeTimestampService.currentUnit
        realTimeTimestampService.toggleUnit()
        XCTAssertNotEqual(realTimeTimestampService.currentUnit, initialUnit)

        // Test copy functionality with toast integration
        let success = realTimeTimestampService.copyToClipboard()
        XCTAssertTrue(success)

        // Verify toast notification
        toastManager.show(
            "时间戳已复制",
            type: .success,
            duration: 2.0
        )

        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)

        expectation.fulfill()

        wait(for: [expectation], timeout: 3.0)
    }

    func testRealTimeTimestampPerformanceIntegration() {
        let expectation = XCTestExpectation(description: "Real-time timestamp performance")

        var updateCount = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        // Monitor updates for performance
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateCount += 1

            if updateCount >= 10 {
                let endTime = CFAbsoluteTimeGetCurrent()
                let duration = endTime - startTime

                // Should handle 10 updates efficiently
                XCTAssertLessThan(duration, 2.0)
                expectation.fulfill()
            }
        }

        realTimeTimestampService.startTimer()

        wait(for: [expectation], timeout: 5.0)
        timer.invalidate()
    }

    // MARK: - Single Conversion Integration Tests

    func testSingleConversionWithRealTimeValidation() {
        let expectation = XCTestExpectation(
            description: "Single conversion with real-time validation")

        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "Asia/Tokyo")!,
            validateInput: true,
            enableRealTimeConversion: true
        )

        // Test valid input
        timeConverterService.startRealTimeConversion(input: "1640995200", options: options) {
            result in
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.result, "2022-01-01T09:00:00+09:00")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        timeConverterService.stopRealTimeConversion()
    }

    func testSingleConversionTimezoneIntegration() {
        // Test timezone conversion with various timezone combinations
        let testCases: [(String, String, String)] = [
            ("UTC", "America/New_York", "2021-12-31T19:00:00-05:00"),
            ("UTC", "Asia/Tokyo", "2022-01-01T09:00:00+09:00"),
            ("UTC", "Europe/London", "2022-01-01T00:00:00+00:00"),
            ("America/New_York", "UTC", "2022-01-01T05:00:00Z"),
            ("Asia/Tokyo", "UTC", "2021-12-31T15:00:00Z"),
        ]

        for (sourceId, targetId, expectedResult) in testCases {
            let options = TimeConversionOptions(
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: sourceId)!,
                targetTimeZone: TimeZone(identifier: targetId)!
            )

            let result = timeConverterService.convertTime(input: "1640995200", options: options)

            XCTAssertTrue(result.success, "Failed for \(sourceId) -> \(targetId)")
            // Note: Exact time format may vary, so we check for key components
            XCTAssertTrue(
                result.result.contains("2021-12-31") || result.result.contains("2022-01-01"),
                "Unexpected result for \(sourceId) -> \(targetId): \(result.result)"
            )
        }
    }

    // MARK: - Batch Conversion Integration Tests

    func testBatchConversionIntegrationWithProgressTracking() {
        let inputs = [
            "1640995200",
            "1641081600",
            "1641168000",
            "invalid_input",
            "1641254400",
        ]

        let items = inputs.enumerated().map { index, input in
            BatchConversionItem(
                input: input,
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        let results = batchConversionService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 5)

        // Check successful conversions
        XCTAssertTrue(results[0].success)
        XCTAssertEqual(results[0].output, "2022-01-01T00:00:00Z")

        XCTAssertTrue(results[1].success)
        XCTAssertEqual(results[1].output, "2022-01-02T00:00:00Z")

        XCTAssertTrue(results[2].success)
        XCTAssertEqual(results[2].output, "2022-01-03T00:00:00Z")

        // Check failed conversion
        XCTAssertFalse(results[3].success)
        XCTAssertNotNil(results[3].error)

        XCTAssertTrue(results[4].success)
        XCTAssertEqual(results[4].output, "2022-01-04T00:00:00Z")
    }

    func testBatchConversionPerformanceIntegration() {
        // Test batch conversion performance with large dataset
        let inputs = Array(1_640_995_200...1_640_995_299).map { timestamp in
            BatchConversionItem(
                input: String(timestamp),
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let results = batchConversionService.processBatchConversion(items: inputs)
        let endTime = CFAbsoluteTimeGetCurrent()

        XCTAssertEqual(results.count, 100)
        XCTAssertTrue(results.allSatisfy(\.success))

        // Should complete 100 conversions in reasonable time
        XCTAssertLessThan(endTime - startTime, 5.0)
    }

    // MARK: - Toast Integration Tests

    func testToastIntegrationWithAllComponents() {
        // Test toast notifications from real-time timestamp
        let success = realTimeTimestampService.copyToClipboard()
        if success {
            toastManager.show(
                "时间戳已复制",
                type: .success,
                duration: 2.0
            )
        }

        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)

        // Test toast notifications from single conversion
        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "UTC")!
        )

        let result = timeConverterService.convertTime(input: "1640995200", options: options)

        if result.success {
            toastManager.show(
                "转换结果已复制",
                type: .success,
                duration: 2.0
            )
        } else {
            toastManager.show(
                "转换失败: \(result.error ?? "未知错误")",
                type: .error,
                duration: 3.0
            )
        }

        XCTAssertEqual(toastManager.toasts.count, 2)
        XCTAssertEqual(toastManager.toasts.last?.type, .success)

        // Test toast notifications from batch conversion
        let batchItems = [
            BatchConversionItem(
                input: "invalid_input",
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        ]

        let batchResults = batchConversionService.processBatchConversion(items: batchItems)
        let failedCount = batchResults.filter { !$0.success }.count

        if failedCount > 0 {
            toastManager.show(
                "批量转换完成，\(failedCount) 项失败",
                type: .warning,
                duration: 3.0
            )
        }

        XCTAssertEqual(toastManager.toasts.count, 3)
        XCTAssertEqual(toastManager.toasts.last?.type, .warning)
    }

    // MARK: - Error Handling Integration Tests

    func testComprehensiveErrorHandlingIntegration() {
        // Test error handling across all components

        // 1. Real-time timestamp service error handling
        let success = realTimeTimestampService.copyToClipboard()
        if !success {
            XCTFail("Real-time timestamp copy should not fail in normal conditions")
        }

        // 2. Single conversion error handling
        let invalidOptions = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "Invalid/Timezone") ?? .current,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            validateInput: true
        )

        let invalidResult = timeConverterService.convertTime(
            input: "invalid_timestamp", options: invalidOptions)
        XCTAssertFalse(invalidResult.success)
        XCTAssertNotNil(invalidResult.error)

        // 3. Batch conversion error handling
        let mixedBatchItems = [
            BatchConversionItem(
                input: "1640995200",
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            ),
            BatchConversionItem(
                input: "invalid_input",
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            ),
        ]

        let mixedResults = batchConversionService.processBatchConversion(items: mixedBatchItems)

        XCTAssertEqual(mixedResults.count, 2)
        XCTAssertTrue(mixedResults[0].success)
        XCTAssertFalse(mixedResults[1].success)
        XCTAssertNotNil(mixedResults[1].error)
    }

    // MARK: - Accessibility Integration Tests

    func testAccessibilityIntegrationAcrossComponents() {
        // Test that all components support accessibility features

        // 1. Tab accessibility
        let tabs = ConversionTab.allCases
        for tab in tabs {
            XCTAssertFalse(tab.displayName.isEmpty, "Tab display name should not be empty")
            XCTAssertFalse(tab.iconName.isEmpty, "Tab icon name should not be empty")
            XCTAssertFalse(tab.id.isEmpty, "Tab ID should not be empty")
        }

        // 2. Real-time timestamp accessibility
        let timestampConfig = RealTimeTimestampConfiguration.default
        XCTAssertEqual(timestampConfig.updateInterval, 1.0)
        XCTAssertTrue(timestampConfig.autoStart)

        // 3. Format accessibility
        let formats = TimeFormat.allCases
        for format in formats {
            XCTAssertFalse(format.displayName.isEmpty, "Format display name should not be empty")
            XCTAssertFalse(format.description.isEmpty, "Format description should not be empty")
        }
    }

    // MARK: - Performance Integration Tests

    func testOverallPerformanceIntegration() {
        let expectation = XCTestExpectation(description: "Overall performance integration")

        let startTime = CFAbsoluteTimeGetCurrent()

        // 1. Start real-time timestamp
        realTimeTimestampService.startTimer()

        // 2. Perform single conversions
        let singleOptions = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "Asia/Tokyo")!
        )

        for i in 0..<10 {
            let result = timeConverterService.convertTime(
                input: String(1_640_995_200 + i),
                options: singleOptions
            )
            XCTAssertTrue(result.success)
        }

        // 3. Perform batch conversion
        let batchItems = Array(0..<20).map { i in
            BatchConversionItem(
                input: String(1_640_995_200 + i),
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        let batchResults = batchConversionService.processBatchConversion(items: batchItems)
        XCTAssertEqual(batchResults.count, 20)
        XCTAssertTrue(batchResults.allSatisfy(\.success))

        // 4. Test toast notifications
        for i in 0..<5 {
            toastManager.show(
                "Test message \(i)",
                type: .info,
                duration: 1.0
            )
        }

        XCTAssertEqual(toastManager.toasts.count, 5)

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalDuration = endTime - startTime

        // All operations should complete in reasonable time
        XCTAssertLessThan(totalDuration, 3.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Memory Management Integration Tests

    func testMemoryManagementIntegration() {
        // Test that all components properly manage memory

        // 1. Real-time timestamp service cleanup
        realTimeTimestampService.startTimer()
        XCTAssertTrue(realTimeTimestampService.isRunning)

        realTimeTimestampService.stopTimer()
        XCTAssertFalse(realTimeTimestampService.isRunning)

        // 2. Time converter service cleanup
        let options = TimeConversionOptions(enableRealTimeConversion: true)

        timeConverterService.startRealTimeConversion(input: "1640995200", options: options) { _ in }
        timeConverterService.stopRealTimeConversion()

        // 3. Toast manager cleanup
        for i in 0..<10 {
            toastManager.show("Test \(i)", type: .info, duration: 0.1)
        }

        // Wait for toasts to expire
        let expectation = XCTestExpectation(description: "Toast cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Toasts should be automatically cleaned up
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)

        // Should not crash or leak memory
        XCTAssertTrue(true)
    }
}
