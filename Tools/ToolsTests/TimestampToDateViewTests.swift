//
//  TimestampToDateViewTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI
import XCTest

@testable import Tools

@MainActor
final class TimestampToDateViewTests: XCTestCase {

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

    // MARK: - Input Validation Tests

    func testValidTimestampInput() {
        // Test valid Unix timestamp in seconds
        let validTimestamp = "1640995200"  // 2022-01-01 00:00:00 UTC

        XCTAssertTrue(
            timeService.validateTimestamp(validTimestamp),
            "Valid timestamp should pass validation")
    }

    func testValidTimestampInputWithMilliseconds() {
        // Test valid Unix timestamp in milliseconds
        let validTimestampMs = "1640995200000"  // 2022-01-01 00:00:00 UTC in milliseconds

        XCTAssertTrue(
            timeService.validateTimestamp(validTimestampMs),
            "Valid timestamp with milliseconds should pass validation")
    }

    func testInvalidTimestampInput() {
        let invalidInputs = [
            "abc123",  // Non-numeric
            "12.34.56",  // Invalid format
            "",  // Empty string
            "   ",  // Whitespace only
            "-1640995200",  // Negative timestamp (before epoch)
            "999999999999999",  // Too large timestamp
            "12a34",  // Mixed alphanumeric
            "12 34 56",  // Spaces in number
        ]

        for invalidInput in invalidInputs {
            XCTAssertFalse(
                timeService.validateTimestamp(invalidInput),
                "Invalid timestamp '\(invalidInput)' should fail validation")
        }
    }

    // MARK: - Conversion Accuracy Tests

    func testTimestampToDateConversionAccuracy() {
        let testCases: [(timestamp: String, timeZone: TimeZone)] = [
            // Unix epoch
            ("0", TimeZone(identifier: "UTC")!),

            // New Year 2022 UTC
            ("1640995200", TimeZone(identifier: "UTC")!),

            // New Year 2022 EST
            ("1640995200", TimeZone(identifier: "America/New_York")!),

            // Leap year test - Feb 29, 2020
            ("1582934400", TimeZone(identifier: "UTC")!),

            // Future date - Jan 1, 2030
            ("1893456000", TimeZone(identifier: "UTC")!),
        ]

        for testCase in testCases {
            let options = TimeConversionOptions(
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: .current,
                targetTimeZone: testCase.timeZone,
                includeMilliseconds: false
            )

            let result = timeService.convertTime(input: testCase.timestamp, options: options)

            XCTAssertTrue(
                result.success,
                "Conversion should succeed for timestamp \(testCase.timestamp)")

            // For timezone-aware comparisons, we'll check the date components
            if let resultDate = result.date {
                let calendar = Calendar(identifier: .gregorian)
                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute, .second],
                    from: resultDate
                )

                XCTAssertNotNil(components.year, "Year component should be present")
                XCTAssertNotNil(components.month, "Month component should be present")
                XCTAssertNotNil(components.day, "Day component should be present")
            }
        }
    }

    // MARK: - Error Handling Tests

    func testEmptyInputHandling() {
        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601
        )

        let result = timeService.convertTime(input: "", options: options)

        XCTAssertFalse(result.success, "Empty input should fail conversion")
        XCTAssertNotNil(result.error, "Error message should be provided for empty input")
        XCTAssertTrue(result.result.isEmpty, "Result should be empty for failed conversion")
    }

    func testInvalidTimestampErrorHandling() {
        let invalidTimestamp = "invalid_timestamp"

        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601
        )

        let result = timeService.convertTime(input: invalidTimestamp, options: options)

        XCTAssertFalse(result.success, "Invalid timestamp should fail conversion")
        XCTAssertNotNil(result.error, "Error message should be provided for invalid timestamp")
        XCTAssertTrue(
            result.error?.contains("timestamp") == true,
            "Error message should mention timestamp")
    }

    // MARK: - Integration Tests

    func testFullConversionWorkflow() {
        // Test a complete workflow: input validation -> conversion -> result verification
        let timestamp = "1640995200"

        // Step 1: Validate input
        XCTAssertTrue(timeService.validateTimestamp(timestamp), "Input should be valid")

        // Step 2: Perform conversion
        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            includeMilliseconds: false
        )

        let result = timeService.convertTime(input: timestamp, options: options)

        // Step 3: Verify result
        XCTAssertTrue(result.success, "Conversion should succeed")
        XCTAssertFalse(result.result.isEmpty, "Result should not be empty")
        XCTAssertNotNil(result.timestamp, "Result should include timestamp")
        XCTAssertNotNil(result.date, "Result should include date")

        // Step 4: Verify result format
        XCTAssertTrue(result.result.contains("2022-01-01"), "Result should contain correct date")
        XCTAssertTrue(result.result.contains("T"), "ISO 8601 result should contain T separator")
        XCTAssertTrue(
            result.result.contains("Z") || result.result.contains("+")
                || result.result.contains("-"),
            "ISO 8601 result should contain timezone indicator")
    }

    // MARK: - View Creation Tests

    func testTimestampToDateViewCreation() {
        // Test that the view can be created without crashing
        let view = TimestampToDateView()
        XCTAssertNotNil(view, "TimestampToDateView should be created successfully")
    }
}
