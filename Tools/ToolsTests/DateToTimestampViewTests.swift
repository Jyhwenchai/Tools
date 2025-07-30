//
//  DateToTimestampViewTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI
import Testing

@testable import Tools

struct DateToTimestampViewTests {

    // MARK: - View Initialization Tests

    @Test("DateToTimestampView 初始化测试")
    func dateToTimestampViewInitialization() {
        let view = DateToTimestampView()
        #expect(view != nil)
    }

    // MARK: - Date Parsing Tests

    @Test("ISO 8601 日期解析测试")
    func iso8601DateParsing() {
        let service = TimeConverterService()

        // Test valid ISO 8601 formats
        let validISO8601Dates = [
            "2024-01-01T12:00:00Z",
            "2024-12-31T23:59:59Z",
            "2024-06-15T09:30:45.123Z",
            "2024-03-20T14:25:30+08:00",
        ]

        for dateString in validISO8601Dates {
            let isValid = service.validateDateString(dateString, format: .iso8601)
            #expect(isValid, "ISO 8601 date '\(dateString)' should be valid")
        }

        // Test invalid ISO 8601 formats
        let invalidISO8601Dates = [
            "2024-13-01T12:00:00Z",  // Invalid month
            "2024-01-32T12:00:00Z",  // Invalid day
            "2024-01-01T25:00:00Z",  // Invalid hour
            "2024-01-01 12:00:00",  // Missing T separator
            "invalid-date",
        ]

        for dateString in invalidISO8601Dates {
            let isValid = service.validateDateString(dateString, format: .iso8601)
            #expect(!isValid, "ISO 8601 date '\(dateString)' should be invalid")
        }
    }

    @Test("RFC 2822 日期解析测试")
    func rfc2822DateParsing() {
        let service = TimeConverterService()

        // Test valid RFC 2822 formats
        let validRFC2822Dates = [
            "Mon, 01 Jan 2024 12:00:00 GMT",
            "Tue, 31 Dec 2024 23:59:59 GMT",
            "Wed, 15 Jun 2024 09:30:45 GMT",
            "Thu, 20 Mar 2024 14:25:30 GMT",
        ]

        for dateString in validRFC2822Dates {
            let isValid = service.validateDateString(dateString, format: .rfc2822)
            #expect(isValid, "RFC 2822 date '\(dateString)' should be valid")
        }

        // Test invalid RFC 2822 formats
        let invalidRFC2822Dates = [
            "Mon, 32 Jan 2024 12:00:00 GMT",  // Invalid day
            "Mon, 01 Xxx 2024 12:00:00 GMT",  // Invalid month
            "Mon, 01 Jan 2024 25:00:00 GMT",  // Invalid hour
            "2024-01-01T12:00:00Z",  // Wrong format
            "invalid-date",
        ]

        for dateString in invalidRFC2822Dates {
            let isValid = service.validateDateString(dateString, format: .rfc2822)
            #expect(!isValid, "RFC 2822 date '\(dateString)' should be invalid")
        }
    }

    @Test("自定义格式日期解析测试")
    func customFormatDateParsing() {
        let service = TimeConverterService()

        // Test various custom formats
        let testCases = [
            (
                format: "yyyy-MM-dd HH:mm:ss",
                validDates: ["2024-01-01 12:00:00", "2024-12-31 23:59:59"],
                invalidDates: ["2024-13-01 12:00:00", "01-01-2024 12:00:00"]
            ),
            (
                format: "MM/dd/yyyy HH:mm", validDates: ["01/01/2024 12:00", "12/31/2024 23:59"],
                invalidDates: ["13/01/2024 12:00", "2024/01/01 12:00"]
            ),
            (
                format: "dd.MM.yyyy HH:mm:ss",
                validDates: ["01.01.2024 12:00:00", "31.12.2024 23:59:59"],
                invalidDates: ["32.01.2024 12:00:00", "01-01-2024 12:00:00"]
            ),
            (
                format: "yyyy年MM月dd日 HH:mm:ss",
                validDates: ["2024年01月01日 12:00:00", "2024年12月31日 23:59:59"],
                invalidDates: ["2024年13月01日 12:00:00", "2024-01-01 12:00:00"]
            ),
        ]

        for testCase in testCases {
            // Test valid dates
            for dateString in testCase.validDates {
                let isValid = service.validateDateString(
                    dateString, format: .custom, customFormat: testCase.format)
                #expect(
                    isValid,
                    "Custom format date '\(dateString)' with format '\(testCase.format)' should be valid"
                )
            }

            // Test invalid dates
            for dateString in testCase.invalidDates {
                let isValid = service.validateDateString(
                    dateString, format: .custom, customFormat: testCase.format)
                #expect(
                    !isValid,
                    "Custom format date '\(dateString)' with format '\(testCase.format)' should be invalid"
                )
            }
        }
    }

    // MARK: - Timestamp Generation Tests

    @Test("日期转时间戳转换测试")
    func dateToTimestampConversion() {
        let service = TimeConverterService()

        // Test ISO 8601 to timestamp conversion
        let iso8601TestCases = [
            (input: "2024-01-01T00:00:00Z", expectedTimestamp: 1_704_067_200),
            (input: "2024-06-15T12:30:45Z", expectedTimestamp: 1_718_456_445),
            (input: "2024-12-31T23:59:59Z", expectedTimestamp: 1_735_689_599),
        ]

        for testCase in iso8601TestCases {
            let options = TimeConversionOptions(
                sourceFormat: .iso8601,
                targetFormat: .timestamp,
                sourceTimeZone: TimeZone(identifier: "UTC")!,
                targetTimeZone: .current,
                includeMilliseconds: false
            )

            let result = service.convertTime(input: testCase.input, options: options)
            #expect(result.success, "Conversion should succeed for '\(testCase.input)'")

            if result.success {
                let timestamp = Int(result.result) ?? 0
                #expect(
                    timestamp == testCase.expectedTimestamp,
                    "Timestamp should match expected value for '\(testCase.input)'")
            }
        }
    }

    @Test("毫秒时间戳生成测试")
    func millisecondsTimestampGeneration() {
        let service = TimeConverterService()

        let options = TimeConversionOptions(
            sourceFormat: .iso8601,
            targetFormat: .timestamp,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: .current,
            includeMilliseconds: true
        )

        let result = service.convertTime(input: "2024-01-01T00:00:00Z", options: options)
        #expect(result.success, "Conversion should succeed")

        if result.success {
            let timestamp = Double(result.result) ?? 0
            #expect(
                timestamp == 1704067200.000, "Milliseconds timestamp should include decimal places")
        }
    }

    // MARK: - Timezone Handling Tests

    @Test("时区处理测试")
    func timezoneHandling() {
        let service = TimeConverterService()

        // Test conversion with different source timezones
        let timezoneTestCases = [
            (timezone: "UTC", input: "2024-01-01T12:00:00Z"),
            (timezone: "America/New_York", input: "2024-01-01T12:00:00-05:00"),
            (timezone: "Asia/Tokyo", input: "2024-01-01T12:00:00+09:00"),
            (timezone: "Europe/London", input: "2024-01-01T12:00:00+00:00"),
        ]

        for testCase in timezoneTestCases {
            guard let sourceTimeZone = TimeZone(identifier: testCase.timezone) else {
                continue
            }

            let options = TimeConversionOptions(
                sourceFormat: .iso8601,
                targetFormat: .timestamp,
                sourceTimeZone: sourceTimeZone,
                targetTimeZone: .current
            )

            let result = service.convertTime(input: testCase.input, options: options)
            #expect(result.success, "Conversion should succeed for timezone '\(testCase.timezone)'")
        }
    }

    @Test("时区兼容性验证测试")
    func timezoneCompatibilityValidation() {
        let service = TimeConverterService()
        let testDate = Date()

        // Test valid timezone combinations
        let validTimezones = [
            (TimeZone(identifier: "UTC")!, TimeZone(identifier: "America/New_York")!),
            (TimeZone(identifier: "Asia/Tokyo")!, TimeZone(identifier: "Europe/London")!),
            (TimeZone.current, TimeZone(identifier: "UTC")!),
        ]

        for (source, target) in validTimezones {
            let isCompatible = service.validateTimezoneCompatibility(
                source: source,
                target: target,
                for: testDate
            )
            #expect(
                isCompatible,
                "Timezones '\(source.identifier)' and '\(target.identifier)' should be compatible")
        }
    }

    // MARK: - Error Handling Tests

    @Test("输入验证错误处理测试")
    func inputValidationErrorHandling() {
        let service = TimeConverterService()

        // Test empty input
        let emptyResult = service.convertTime(
            input: "",
            options: TimeConversionOptions(sourceFormat: .iso8601, targetFormat: .timestamp)
        )
        #expect(!emptyResult.success, "Empty input should fail")
        #expect(emptyResult.error != nil, "Error message should be provided for empty input")

        // Test invalid date format
        let invalidResult = service.convertTime(
            input: "invalid-date",
            options: TimeConversionOptions(sourceFormat: .iso8601, targetFormat: .timestamp)
        )
        #expect(!invalidResult.success, "Invalid date should fail")
        #expect(invalidResult.error != nil, "Error message should be provided for invalid date")
    }

    @Test("自定义格式错误处理测试")
    func customFormatErrorHandling() {
        let service = TimeConverterService()

        // Test invalid custom format
        let options = TimeConversionOptions(
            sourceFormat: .custom,
            targetFormat: .timestamp,
            customFormat: "invalid-format"
        )

        let result = service.convertTime(input: "2024-01-01", options: options)
        #expect(!result.success, "Invalid custom format should fail")
        #expect(result.error != nil, "Error message should be provided for invalid custom format")
    }

    // MARK: - Performance Tests

    @Test("日期解析性能测试")
    func dateParsingPerformance() {
        let service = TimeConverterService()
        let testInput = "2024-01-01T12:00:00Z"
        let options = TimeConversionOptions(
            sourceFormat: .iso8601,
            targetFormat: .timestamp
        )

        let startTime = CFAbsoluteTimeGetCurrent()

        // Perform multiple conversions
        for _ in 0..<1000 {
            let _ = service.convertTime(input: testInput, options: options)
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / 1000.0

        // Average conversion should be under 1ms
        #expect(
            averageTime < 0.001, "Average conversion time should be under 1ms, got \(averageTime)s")
    }

    // MARK: - Edge Cases Tests

    @Test("边界情况测试")
    func edgeCasesHandling() {
        let service = TimeConverterService()

        // Test leap year dates
        let leapYearDates = [
            "2024-02-29T12:00:00Z",  // Valid leap year date
            "2023-02-29T12:00:00Z",  // Invalid leap year date
        ]

        let validLeapYear = service.validateDateString(leapYearDates[0], format: .iso8601)
        #expect(validLeapYear, "Valid leap year date should be accepted")

        let invalidLeapYear = service.validateDateString(leapYearDates[1], format: .iso8601)
        #expect(!invalidLeapYear, "Invalid leap year date should be rejected")

        // Test extreme dates
        let extremeDates = [
            "1970-01-01T00:00:00Z",  // Unix epoch start
            "2038-01-19T03:14:07Z",  // Near 32-bit timestamp limit
            "2100-12-31T23:59:59Z",  // Far future date
        ]

        for dateString in extremeDates {
            let isValid = service.validateDateString(dateString, format: .iso8601)
            #expect(isValid, "Extreme date '\(dateString)' should be valid")
        }
    }

    @Test("特殊字符处理测试")
    func specialCharacterHandling() {
        let service = TimeConverterService()

        // Test dates with various whitespace characters
        let datesWithWhitespace = [
            " 2024-01-01T12:00:00Z ",  // Leading/trailing spaces
            "\t2024-01-01T12:00:00Z\t",  // Tabs
            "\n2024-01-01T12:00:00Z\n",  // Newlines
            "2024-01-01T12:00:00Z\u{00A0}",  // Non-breaking space
        ]

        for dateString in datesWithWhitespace {
            let options = TimeConversionOptions(
                sourceFormat: .iso8601,
                targetFormat: .timestamp
            )

            let result = service.convertTime(input: dateString, options: options)
            #expect(
                result.success,
                "Date with whitespace '\(dateString.debugDescription)' should be handled correctly")
        }
    }

    // MARK: - Real-time Conversion Tests

    @Test("实时转换功能测试")
    func realTimeConversionFeature() {
        let service = TimeConverterService()
        var callbackCount = 0
        var conversionResult: TimeConversionResult?

        let options = TimeConversionOptions(
            sourceFormat: .iso8601,
            targetFormat: .timestamp,
            enableRealTimeConversion: true
        )

        service.startRealTimeConversion(
            input: "2024-01-01T12:00:00Z",
            options: options
        ) { result in
            callbackCount += 1
            conversionResult = result
        }

        // Wait a short time for the callback to be called
        Thread.sleep(forTimeInterval: 0.1)

        service.stopRealTimeConversion()

        #expect(callbackCount >= 1, "Real-time conversion callback should be called at least once")
        #expect(conversionResult?.success == true, "Real-time conversion should succeed")
    }

    // MARK: - Integration Tests

    @Test("完整转换流程集成测试")
    func fullConversionWorkflowIntegration() {
        let service = TimeConverterService()

        // Test complete workflow: date input -> validation -> conversion -> result
        let testCases = [
            (
                input: "2024-01-01T12:00:00Z",
                format: TimeFormat.iso8601,
                expectedSuccess: true
            ),
            (
                input: "Mon, 01 Jan 2024 12:00:00 GMT",
                format: TimeFormat.rfc2822,
                expectedSuccess: true
            ),
            (
                input: "2024-01-01 12:00:00",
                format: TimeFormat.custom,
                expectedSuccess: true
            ),
            (
                input: "invalid-date-format",
                format: TimeFormat.iso8601,
                expectedSuccess: false
            ),
        ]

        for testCase in testCases {
            // Step 1: Validate input
            let customFormat = testCase.format == .custom ? "yyyy-MM-dd HH:mm:ss" : ""
            let isValid = service.validateDateString(
                testCase.input,
                format: testCase.format,
                customFormat: customFormat
            )

            #expect(
                isValid == testCase.expectedSuccess,
                "Validation should match expected result for '\(testCase.input)'")

            // Step 2: Perform conversion
            let options = TimeConversionOptions(
                sourceFormat: testCase.format,
                targetFormat: .timestamp,
                customFormat: customFormat
            )

            let result = service.convertTime(input: testCase.input, options: options)
            #expect(
                result.success == testCase.expectedSuccess,
                "Conversion should match expected result for '\(testCase.input)'")

            // Step 3: Verify result format
            if result.success {
                let timestamp = Double(result.result)
                #expect(
                    timestamp != nil, "Result should be a valid timestamp for '\(testCase.input)'")
                #expect(timestamp! > 0, "Timestamp should be positive for '\(testCase.input)'")
            }
        }
    }
}
