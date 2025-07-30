//
//  SingleConversionViewTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI
import XCTest

@testable import Tools

@MainActor
final class SingleConversionViewTests: XCTestCase {

    // MARK: - Test Properties

    private var timeService: TimeConverterService!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        timeService = TimeConverterService()
    }

    override func tearDown() {
        timeService = nil
        super.tearDown()
    }

    // MARK: - View Creation Tests

    func testSingleConversionViewCreation() {
        // Test that the view can be created without crashing
        let view = SingleConversionView()
        XCTAssertNotNil(view, "SingleConversionView should be created successfully")
    }

    // MARK: - Conversion Mode Tests

    func testConversionModeEnumeration() {
        // Test that all conversion modes are available
        let allModes = SingleConversionView.ConversionMode.allCases

        XCTAssertEqual(allModes.count, 2, "Should have exactly 2 conversion modes")
        XCTAssertTrue(allModes.contains(.timestampToDate), "Should contain timestampToDate mode")
        XCTAssertTrue(allModes.contains(.dateToTimestamp), "Should contain dateToTimestamp mode")
    }

    func testConversionModeDisplayNames() {
        // Test display names for conversion modes
        XCTAssertEqual(
            SingleConversionView.ConversionMode.timestampToDate.displayName,
            "时间戳转日期",
            "Timestamp to date mode should have correct display name"
        )

        XCTAssertEqual(
            SingleConversionView.ConversionMode.dateToTimestamp.displayName,
            "日期转时间戳",
            "Date to timestamp mode should have correct display name"
        )
    }

    func testConversionModeIdentifiers() {
        // Test that mode identifiers are unique and correct
        XCTAssertEqual(
            SingleConversionView.ConversionMode.timestampToDate.id,
            "timestamp_to_date",
            "Timestamp to date mode should have correct identifier"
        )

        XCTAssertEqual(
            SingleConversionView.ConversionMode.dateToTimestamp.id,
            "date_to_timestamp",
            "Date to timestamp mode should have correct identifier"
        )
    }

    // MARK: - TimeZone Picker Tests

    func testTimeZonePickerCreation() {
        // Test that TimeZonePicker can be created with a binding
        @State var selectedTimeZone: TimeZone = .current
        let picker = TimeZonePicker(selection: $selectedTimeZone)

        XCTAssertNotNil(picker, "TimeZonePicker should be created successfully")
    }

    func testCommonTimeZonesAvailability() {
        // Test that common time zones are available
        let commonTimeZones = TimeZoneInfo.commonTimeZones

        XCTAssertGreaterThan(commonTimeZones.count, 0, "Should have common time zones available")

        // Check for specific important time zones
        let timeZoneIdentifiers = commonTimeZones.map { $0.identifier }

        XCTAssertTrue(
            timeZoneIdentifiers.contains("UTC"),
            "Should include UTC time zone"
        )

        XCTAssertTrue(
            timeZoneIdentifiers.contains(TimeZone.current.identifier),
            "Should include current system time zone"
        )
    }

    func testTimeZoneInfoProperties() {
        // Test TimeZoneInfo properties
        let utcTimeZone = TimeZone(identifier: "UTC")!
        let timeZoneInfo = TimeZoneInfo(timeZone: utcTimeZone)

        XCTAssertEqual(timeZoneInfo.identifier, "UTC", "Should have correct identifier")
        XCTAssertEqual(timeZoneInfo.offsetFromGMT, 0, "UTC should have zero offset from GMT")
        XCTAssertEqual(
            timeZoneInfo.offsetString, "GMT+00:00", "UTC should have correct offset string")
    }

    // MARK: - Integration Tests

    func testTimestampToDateIntegration() {
        // Test the complete workflow for timestamp to date conversion
        let testTimestamp = "1640995200"  // 2022-01-01 00:00:00 UTC

        // Validate the timestamp
        XCTAssertTrue(
            timeService.validateTimestamp(testTimestamp),
            "Test timestamp should be valid"
        )

        // Perform conversion
        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: .current,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            includeMilliseconds: false
        )

        let result = timeService.convertTime(input: testTimestamp, options: options)

        XCTAssertTrue(result.success, "Timestamp to date conversion should succeed")
        XCTAssertFalse(result.result.isEmpty, "Conversion result should not be empty")
        XCTAssertTrue(result.result.contains("2022-01-01"), "Result should contain correct date")
    }

    func testDateToTimestampIntegration() {
        // Test the complete workflow for date to timestamp conversion
        let testDate = "2022-01-01T00:00:00Z"

        // Validate the date string
        XCTAssertTrue(
            timeService.validateDateString(testDate, format: .iso8601, customFormat: ""),
            "Test date should be valid"
        )

        // Perform conversion
        let options = TimeConversionOptions(
            sourceFormat: .iso8601,
            targetFormat: .timestamp,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: .current,
            includeMilliseconds: false
        )

        let result = timeService.convertTime(input: testDate, options: options)

        XCTAssertTrue(result.success, "Date to timestamp conversion should succeed")
        XCTAssertFalse(result.result.isEmpty, "Conversion result should not be empty")
        XCTAssertEqual(result.result, "1640995200", "Result should be correct timestamp")
    }

    func testBidirectionalConversion() {
        // Test that converting timestamp to date and back gives the same result
        let originalTimestamp = "1640995200"

        // Convert timestamp to date
        let timestampToDateOptions = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: .current,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            includeMilliseconds: false
        )

        let dateResult = timeService.convertTime(
            input: originalTimestamp,
            options: timestampToDateOptions
        )

        XCTAssertTrue(dateResult.success, "Timestamp to date conversion should succeed")

        // Convert date back to timestamp
        let dateToTimestampOptions = TimeConversionOptions(
            sourceFormat: .iso8601,
            targetFormat: .timestamp,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: .current,
            includeMilliseconds: false
        )

        let timestampResult = timeService.convertTime(
            input: dateResult.result,
            options: dateToTimestampOptions
        )

        XCTAssertTrue(timestampResult.success, "Date to timestamp conversion should succeed")
        XCTAssertEqual(
            timestampResult.result,
            originalTimestamp,
            "Bidirectional conversion should return to original value"
        )
    }

    // MARK: - Error Handling Tests

    func testInvalidInputHandling() {
        // Test handling of invalid inputs in both conversion modes
        let invalidInputs = ["", "invalid", "12.34.56", "abc123"]

        for invalidInput in invalidInputs {
            // Test timestamp validation
            XCTAssertFalse(
                timeService.validateTimestamp(invalidInput),
                "Invalid input '\(invalidInput)' should fail timestamp validation"
            )

            // Test date validation
            XCTAssertFalse(
                timeService.validateDateString(invalidInput, format: .iso8601, customFormat: ""),
                "Invalid input '\(invalidInput)' should fail date validation"
            )
        }
    }

    func testTimezoneConversionEdgeCases() {
        // Test timezone conversion with edge cases
        let testCases: [(timestamp: String, sourceTimeZone: String, targetTimeZone: String)] = [
            ("1640995200", "UTC", "America/New_York"),
            ("1640995200", "Asia/Tokyo", "Europe/London"),
            ("1640995200", "Australia/Sydney", "America/Los_Angeles"),
        ]

        for testCase in testCases {
            let options = TimeConversionOptions(
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: TimeZone(identifier: testCase.sourceTimeZone)!,
                targetTimeZone: TimeZone(identifier: testCase.targetTimeZone)!,
                includeMilliseconds: false
            )

            let result = timeService.convertTime(input: testCase.timestamp, options: options)

            XCTAssertTrue(
                result.success,
                "Timezone conversion from \(testCase.sourceTimeZone) to \(testCase.targetTimeZone) should succeed"
            )
            XCTAssertFalse(
                result.result.isEmpty,
                "Timezone conversion result should not be empty"
            )
        }
    }

    // MARK: - Performance Tests

    func testConversionPerformance() {
        // Test performance of conversion operations
        let testTimestamp = "1640995200"
        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            includeMilliseconds: false
        )

        measure {
            for _ in 0..<100 {
                let result = timeService.convertTime(input: testTimestamp, options: options)
                XCTAssertTrue(result.success, "Conversion should succeed in performance test")
            }
        }
    }

    func testValidationPerformance() {
        // Test performance of input validation
        let testInputs = [
            "1640995200",
            "1640995200000",
            "2022-01-01T00:00:00Z",
            "invalid_input",
            "",
        ]

        measure {
            for _ in 0..<100 {
                for input in testInputs {
                    _ = timeService.validateTimestamp(input)
                    _ = timeService.validateDateString(input, format: .iso8601, customFormat: "")
                }
            }
        }
    }

    // MARK: - Accessibility Tests

    func testConversionModeAccessibility() {
        // Test that conversion modes have proper accessibility support
        let timestampMode = SingleConversionView.ConversionMode.timestampToDate
        let dateMode = SingleConversionView.ConversionMode.dateToTimestamp

        XCTAssertFalse(
            timestampMode.displayName.isEmpty,
            "Timestamp mode should have non-empty display name for accessibility"
        )
        XCTAssertFalse(
            dateMode.displayName.isEmpty,
            "Date mode should have non-empty display name for accessibility"
        )

        XCTAssertNotEqual(
            timestampMode.displayName,
            dateMode.displayName,
            "Conversion modes should have distinct display names"
        )
    }

    // MARK: - State Management Tests

    func testConversionModeStateManagement() {
        // Test that conversion mode state can be managed properly
        @State var selectedMode: SingleConversionView.ConversionMode = .timestampToDate

        // Initial state
        XCTAssertEqual(selectedMode, .timestampToDate, "Initial mode should be timestamp to date")

        // State change
        selectedMode = .dateToTimestamp
        XCTAssertEqual(selectedMode, .dateToTimestamp, "Mode should change to date to timestamp")

        // State change back
        selectedMode = .timestampToDate
        XCTAssertEqual(
            selectedMode, .timestampToDate, "Mode should change back to timestamp to date")
    }
}
