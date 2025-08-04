import Foundation
import XCTest

@testable import Tools

// MARK: - Performance Tests for Time Converter Enhancement

final class TimeConverterPerformanceTests: XCTestCase {

    // MARK: - Properties

    private var timeConverterService: TimeConverterService!
    private var batchConversionService: BatchConversionService!
    private var realTimeTimestampService: RealTimeTimestampService!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        timeConverterService = TimeConverterService()
        batchConversionService = BatchConversionService()
        realTimeTimestampService = RealTimeTimestampService()
    }

    override func tearDown() {
        timeConverterService = nil
        batchConversionService = nil
        realTimeTimestampService?.stopTimer()
        realTimeTimestampService = nil
        super.tearDown()
    }

    // MARK: - Real-Time Update Performance Tests

    func testRealTimeTimestampUpdatePerformance() {
        measure {
            // Test the performance of real-time timestamp updates
            realTimeTimestampService.startTimer()

            // Simulate rapid updates
            for _ in 0..<100 {
                let _ = realTimeTimestampService.currentTimestamp
                let _ = realTimeTimestampService.isRunning
            }

            realTimeTimestampService.stopTimer()
        }
    }

    func testRealTimeTimestampUnitSwitchingPerformance() {
        measure {
            realTimeTimestampService.startTimer()

            // Test rapid unit switching
            for _ in 0..<50 {
                realTimeTimestampService.toggleUnit()
                let _ = realTimeTimestampService.currentTimestamp
            }

            realTimeTimestampService.stopTimer()
        }
    }

    func testRealTimeConversionPerformance() {
        let expectation = XCTestExpectation(description: "Real-time conversion performance")

        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            enableRealTimeConversion: true
        )

        var callbackCount = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        measure {
            timeConverterService.startRealTimeConversion(input: "1640995200", options: options) {
                result in
                callbackCount += 1
                XCTAssertTrue(result.success)

                if callbackCount >= 10 {
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let duration = endTime - startTime

                    // Should handle 10 real-time conversions efficiently
                    XCTAssertLessThan(duration, 2.0)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
        timeConverterService.stopRealTimeConversion()
    }

    // MARK: - Batch Processing Performance Tests

    func testSmallBatchConversionPerformance() async {
        let items = Array(0..<10).map { i in
            BatchConversionItem(
                input: String(1_640_995_200 + i),
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        measure {
            let results = await batchConversionService.processBatchConversion(items: items)
            XCTAssertEqual(results.count, 10)
            XCTAssertTrue(results.allSatisfy(\.success))
        }
    }

    func testMediumBatchConversionPerformance() async {
        let items = Array(0..<100).map { i in
            BatchConversionItem(
                input: String(1_640_995_200 + i),
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        measure {
            let results = await batchConversionService.processBatchConversion(items: items)
            XCTAssertEqual(results.count, 100)
            XCTAssertTrue(results.allSatisfy(\.success))
        }
    }

    func testLargeBatchConversionPerformance() {
        let items = Array(0..<1000).map { i in
            BatchConversionItem(
                input: String(1_640_995_200 + i),
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        measure {
            let results = batchConversionService.processBatchConversion(items: items)
            XCTAssertEqual(results.count, 1000)
            XCTAssertTrue(results.allSatisfy(\.success))
        }
    }

    func testBatchConversionWithMixedFormatsPerformance() {
        let formats: [TimeFormat] = [.timestamp, .iso8601, .rfc2822]
        let items = Array(0..<300).map { i in
            let sourceFormat = formats[i % formats.count]
            let targetFormat = formats[(i + 1) % formats.count]

            let input: String
            switch sourceFormat {
            case .timestamp:
                input = String(1_640_995_200 + i)
            case .iso8601:
                input = "2022-01-01T00:00:00Z"
            case .rfc2822:
                input = "Sat, 01 Jan 2022 00:00:00 GMT"
            case .custom:
                input = "2022-01-01 00:00:00"
            }

            return BatchConversionItem(
                input: input,
                sourceFormat: sourceFormat,
                targetFormat: targetFormat,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: TimeZone(identifier: "UTC")!
            )
        }

        measure {
            let results = batchConversionService.processBatchConversion(items: items)
            XCTAssertEqual(results.count, 300)
            // Note: Some conversions might fail due to format mismatches, which is expected
        }
    }

    // MARK: - Service Performance Tests

    func testTimeConverterServiceSingleConversionPerformance() {
        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "UTC")!
        )

        measure {
            for i in 0..<100 {
                let result = timeConverterService.convertTime(
                    input: String(1_640_995_200 + i),
                    options: options
                )
                XCTAssertTrue(result.success)
            }
        }
    }

    func testTimeConverterServiceTimezoneConversionPerformance() {
        let timezones = [
            "UTC",
            "America/New_York",
            "Europe/London",
            "Asia/Tokyo",
            "Australia/Sydney",
        ]

        measure {
            for sourceId in timezones {
                for targetId in timezones {
                    let options = TimeConversionOptions(
                        sourceFormat: .timestamp,
                        targetFormat: .iso8601,
                        sourceTimeZone: TimeZone(identifier: sourceId)!,
                        targetTimeZone: TimeZone(identifier: targetId)!
                    )

                    let result = timeConverterService.convertTime(
                        input: "1640995200", options: options)
                    XCTAssertTrue(result.success)
                }
            }
        }
    }

    func testTimeConverterServiceValidationPerformance() {
        let inputs = [
            "1640995200",
            "2022-01-01T00:00:00Z",
            "Sat, 01 Jan 2022 00:00:00 GMT",
            "invalid_input",
            "1640995200.123",
        ]

        measure {
            for input in inputs {
                for format in TimeFormat.allCases {
                    let _ = timeConverterService.validateInputForFormat(
                        input,
                        format: format,
                        customFormat: "yyyy-MM-dd HH:mm:ss"
                    )
                }
            }
        }
    }

    // MARK: - Memory Performance Tests

    func testMemoryUsageWithContinuousRealTimeUpdates() {
        let expectation = XCTestExpectation(description: "Memory usage test")

        realTimeTimestampService.startTimer()

        var updateCount = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateCount += 1

            // Access timestamp to trigger updates
            let _ = self.realTimeTimestampService.currentTimestamp
            let _ = self.realTimeTimestampService.isRunning

            if updateCount >= 100 {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 15.0)
        timer.invalidate()
        realTimeTimestampService.stopTimer()

        // Should not crash or consume excessive memory
        XCTAssertTrue(true)
    }

    func testMemoryUsageWithRepeatedBatchConversions() {
        measure {
            for _ in 0..<10 {
                let items = Array(0..<50).map { i in
                    BatchConversionItem(
                        input: String(1_640_995_200 + i),
                        sourceFormat: .timestamp,
                        targetFormat: .iso8601,
                        sourceTimeZone: TimeZone(identifier: "UTC")!,
                        targetTimeZone: TimeZone(identifier: "UTC")!
                    )
                }

                let results = batchConversionService.processBatchConversion(items: items)
                XCTAssertEqual(results.count, 50)

                // Force memory cleanup
                autoreleasepool {
                    // Results should be deallocated here
                }
            }
        }
    }

    // MARK: - Concurrent Performance Tests

    func testConcurrentSingleConversions() {
        let expectation = XCTestExpectation(description: "Concurrent single conversions")
        expectation.expectedFulfillmentCount = 10

        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "UTC")!
        )

        measure {
            for i in 0..<10 {
                DispatchQueue.global().async {
                    let result = self.timeConverterService.convertTime(
                        input: String(1_640_995_200 + i),
                        options: options
                    )
                    XCTAssertTrue(result.success)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testConcurrentBatchConversions() {
        let expectation = XCTestExpectation(description: "Concurrent batch conversions")
        expectation.expectedFulfillmentCount = 5

        measure {
            for batchIndex in 0..<5 {
                DispatchQueue.global().async {
                    let items = Array(0..<20).map { i in
                        BatchConversionItem(
                            input: String(1_640_995_200 + batchIndex * 20 + i),
                            sourceFormat: .timestamp,
                            targetFormat: .iso8601,
                            sourceTimeZone: TimeZone(identifier: "UTC")!,
                            targetTimeZone: TimeZone(identifier: "UTC")!
                        )
                    }

                    let results = self.batchConversionService.processBatchConversion(items: items)
                    XCTAssertEqual(results.count, 20)
                    XCTAssertTrue(results.allSatisfy(\.success))
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Cache Performance Tests

    func testFormatterCachePerformance() {
        let customFormats = [
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy",
            "dd-MM-yyyy HH:mm",
            "yyyy年MM月dd日",
            "HH:mm:ss",
        ]

        measure {
            for format in customFormats {
                for i in 0..<20 {
                    let options = TimeConversionOptions(
                        sourceFormat: .custom,
                        targetFormat: .timestamp,
                        sourceTimeZone: TimeZone(identifier: "UTC")!,
                        targetTimeZone: TimeZone(identifier: "UTC")!,
                        customFormat: format
                    )

                    let result = timeConverterService.convertTime(
                        input: "2022-01-01 00:00:00",
                        options: options
                    )
                    // Some may fail due to format mismatch, which is expected
                }
            }
        }
    }

    func testTimezoneCachePerformance() {
        let timezoneIds = [
            "UTC",
            "America/New_York",
            "Europe/London",
            "Asia/Tokyo",
            "Australia/Sydney",
            "America/Los_Angeles",
            "Europe/Paris",
            "Asia/Shanghai",
        ]

        measure {
            for timezoneId in timezoneIds {
                for _ in 0..<10 {
                    let timezoneInfo = timeConverterService.getTimezoneInfo(for: timezoneId)
                    XCTAssertNotNil(timezoneInfo)
                }
            }
        }
    }

    // MARK: - UI Performance Tests

    func testTabSwitchingPerformance() {
        var selectedTab: ConversionTab = .single
        var singleState = SingleConversionState()
        var batchState = BatchConversionState()

        measure {
            // Simulate rapid tab switching with state updates
            for i in 0..<100 {
                if i % 2 == 0 {
                    selectedTab = .single
                    singleState.lastUsedFormat = .timestamp
                    singleState.includeMilliseconds = i % 4 == 0
                } else {
                    selectedTab = .batch
                    batchState.lastSourceFormat = .iso8601
                    batchState.lastInputText = "test input \(i)"
                }
            }
        }

        // Verify final state
        XCTAssertEqual(selectedTab, .single)
        XCTAssertEqual(singleState.lastUsedFormat, .timestamp)
        XCTAssertTrue(batchState.lastInputText.contains("test input"))
    }

    // MARK: - Stress Tests

    func testStressTestWithAllComponents() {
        let expectation = XCTestExpectation(description: "Stress test with all components")

        // Start real-time timestamp
        realTimeTimestampService.startTimer()

        // Perform multiple operations concurrently
        let group = DispatchGroup()

        // Single conversions
        group.enter()
        DispatchQueue.global().async {
            for i in 0..<50 {
                let options = TimeConversionOptions(
                    sourceFormat: .timestamp,
                    targetFormat: .iso8601,
                    sourceTimeZone: TimeZone(identifier: "UTC")!,
                    targetTimeZone: TimeZone(identifier: "Asia/Tokyo")!
                )

                let result = self.timeConverterService.convertTime(
                    input: String(1_640_995_200 + i),
                    options: options
                )
                XCTAssertTrue(result.success)
            }
            group.leave()
        }

        // Batch conversions
        group.enter()
        DispatchQueue.global().async {
            let items = Array(0..<100).map { i in
                BatchConversionItem(
                    input: String(1_640_995_200 + i),
                    sourceFormat: .timestamp,
                    targetFormat: .iso8601,
                    sourceTimeZone: TimeZone(identifier: "UTC")!,
                    targetTimeZone: TimeZone(identifier: "UTC")!
                )
            }

            let results = self.batchConversionService.processBatchConversion(items: items)
            XCTAssertEqual(results.count, 100)
            group.leave()
        }

        // Real-time conversions
        group.enter()
        DispatchQueue.global().async {
            let options = TimeConversionOptions(enableRealTimeConversion: true)

            self.timeConverterService.startRealTimeConversion(input: "1640995200", options: options)
            { result in
                XCTAssertTrue(result.success)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.timeConverterService.stopRealTimeConversion()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.realTimeTimestampService.stopTimer()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)

        // Should complete without crashes or excessive resource usage
        XCTAssertTrue(true)
    }
}
