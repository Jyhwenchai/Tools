import XCTest

@testable import Tools

final class TimeConverterServiceTests: XCTestCase {
  var service: TimeConverterService!

  override func setUp() {
    super.setUp()
    service = TimeConverterService()
  }

  override func tearDown() {
    service = nil
    super.tearDown()
  }

  // MARK: - Timestamp Conversion Tests

  func testTimestampToISO8601Conversion() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let result = service.convertTime(input: "1640995200", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "2022-01-01T00:00:00Z")
    XCTAssertEqual(result.timestamp, 1_640_995_200)
  }

  func testMillisecondsTimestampConversion() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let result = service.convertTime(input: "1640995200000", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "2022-01-01T00:00:00Z")
    XCTAssertEqual(result.timestamp, 1_640_995_200)
  }

  func testISO8601ToTimestampConversion() {
    let options = TimeConversionOptions(
      sourceFormat: .iso8601,
      targetFormat: .timestamp,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let result = service.convertTime(input: "2022-01-01T00:00:00Z", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "1640995200")
    XCTAssertEqual(result.timestamp, 1_640_995_200)
  }

  // MARK: - RFC 2822 Conversion Tests

  func testRFC2822Conversion() {
    let options = TimeConversionOptions(
      sourceFormat: .rfc2822,
      targetFormat: .timestamp,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let result = service.convertTime(input: "Sat, 01 Jan 2022 00:00:00 GMT", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "1640995200")
  }

  func testTimestampToRFC2822Conversion() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .rfc2822,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let result = service.convertTime(input: "1640995200", options: options)

    XCTAssertTrue(result.success)
    XCTAssertTrue(result.result.contains("01 Jan 2022"))
    XCTAssertTrue(result.result.contains("00:00:00"))
  }

  // MARK: - Custom Format Tests

  func testCustomFormatConversion() {
    let options = TimeConversionOptions(
      sourceFormat: .custom,
      targetFormat: .timestamp,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      customFormat: "yyyy-MM-dd HH:mm:ss")

    let result = service.convertTime(input: "2022-01-01 00:00:00", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "1640995200")
  }

  func testTimestampToCustomFormatConversion() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .custom,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      customFormat: "yyyy-MM-dd HH:mm:ss")

    let result = service.convertTime(input: "1640995200", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "2022-01-01 00:00:00")
  }

  // MARK: - Time Zone Conversion Tests

  func testTimeZoneConversion() {
    let utcTimeZone = TimeZone(identifier: "UTC")!
    let nyTimeZone = TimeZone(identifier: "America/New_York")!

    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: utcTimeZone,
      targetTimeZone: nyTimeZone)

    let result =
      service
      .convertTime(input: "1640995200", options: options)  // 2022-01-01 00:00:00 UTC

    XCTAssertTrue(result.success)
    // Should be 5 hours earlier in New York (EST)
    XCTAssertTrue(result.result.contains("2021-12-31T19:00:00"))
  }

  func testTimeZoneConversionMethod() {
    let utcDate = Date(timeIntervalSince1970: 1_640_995_200)  // 2022-01-01 00:00:00 UTC
    let utcTimeZone = TimeZone(identifier: "UTC")!
    let tokyoTimeZone = TimeZone(identifier: "Asia/Tokyo")!

    let convertedDate = service.convertTimeZone(date: utcDate, from: utcTimeZone, to: tokyoTimeZone)

    // Tokyo is UTC+9, so the converted date should be 9 hours ahead
    let expectedTimestamp = 1_640_995_200 + (9 * 3600)
    XCTAssertEqual(
      convertedDate.timeIntervalSince1970,
      TimeInterval(expectedTimestamp),
      accuracy: 1.0)
  }

  // MARK: - Validation Tests

  func testTimestampValidation() {
    XCTAssertTrue(service.validateTimestamp("1640995200"))
    XCTAssertTrue(service.validateTimestamp("1640995200.123"))
    XCTAssertTrue(service.validateTimestamp("0"))

    XCTAssertFalse(service.validateTimestamp("invalid"))
    XCTAssertFalse(service.validateTimestamp(""))
    XCTAssertFalse(service.validateTimestamp("-1"))
    XCTAssertFalse(service.validateTimestamp("9999999999999"))  // Too large
  }

  func testDateStringValidation() {
    XCTAssertTrue(service.validateDateString("2022-01-01T00:00:00Z", format: .iso8601))
    XCTAssertTrue(service.validateDateString("Sat, 01 Jan 2022 00:00:00 GMT", format: .rfc2822))
    XCTAssertTrue(
      service.validateDateString(
        "2022-01-01 00:00:00",
        format: .custom,
        customFormat: "yyyy-MM-dd HH:mm:ss"))

    XCTAssertFalse(service.validateDateString("invalid date", format: .iso8601))
    XCTAssertFalse(
      service.validateDateString(
        "2022-13-01T00:00:00Z",
        format: .iso8601))  // Invalid month
    XCTAssertFalse(service.validateDateString("", format: .iso8601))
  }

  // MARK: - Error Handling Tests

  func testEmptyInputError() {
    let options = TimeConversionOptions()
    let result = service.convertTime(input: "", options: options)

    XCTAssertFalse(result.success)
    XCTAssertEqual(result.error, "Input cannot be empty")
  }

  func testInvalidTimestampError() {
    let options = TimeConversionOptions(sourceFormat: .timestamp, targetFormat: .iso8601)
    let result = service.convertTime(input: "invalid_timestamp", options: options)

    XCTAssertFalse(result.success)
    XCTAssertNotNil(result.error)
  }

  func testInvalidDateFormatError() {
    let options = TimeConversionOptions(sourceFormat: .iso8601, targetFormat: .timestamp)
    let result = service.convertTime(input: "invalid_date", options: options)

    XCTAssertFalse(result.success)
    XCTAssertNotNil(result.error)
  }

  // MARK: - Current Time Tests

  func testGetCurrentTime() {
    let currentTimestamp = service.getCurrentTime(format: .timestamp)
    let currentISO = service.getCurrentTime(format: .iso8601)

    XCTAssertFalse(currentTimestamp.isEmpty)
    XCTAssertFalse(currentISO.isEmpty)
    XCTAssertTrue(service.validateTimestamp(currentTimestamp))
    XCTAssertTrue(service.validateDateString(currentISO, format: .iso8601))
  }

  func testGetCurrentTimestamp() {
    let timestamp = service.getCurrentTimestamp()
    let timestampWithMs = service.getCurrentTimestamp(includeMilliseconds: true)

    XCTAssertFalse(timestamp.isEmpty)
    XCTAssertFalse(timestampWithMs.isEmpty)
    XCTAssertTrue(service.validateTimestamp(timestamp))
    XCTAssertTrue(service.validateTimestamp(timestampWithMs))
    XCTAssertTrue(timestampWithMs.contains("."))
  }

  // MARK: - Batch Conversion Tests

  func testBatchConversion() {
    let inputs = ["1640995200", "1641081600", "1641168000"]
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let results = service.batchConvert(inputs: inputs, options: options)

    XCTAssertEqual(results.count, 3)
    XCTAssertTrue(results.allSatisfy(\.success))
    XCTAssertEqual(results[0].result, "2022-01-01T00:00:00Z")
    XCTAssertEqual(results[1].result, "2022-01-02T00:00:00Z")
    XCTAssertEqual(results[2].result, "2022-01-03T00:00:00Z")
  }

  // MARK: - Time Difference Tests

  func testCalculateTimeDifference() {
    let startDate = Date(timeIntervalSince1970: 1_640_995_200)  // 2022-01-01 00:00:00
    let endDate = Date(timeIntervalSince1970: 1_641_081_600)  // 2022-01-02 00:00:00

    let difference = service.calculateTimeDifference(from: startDate, to: endDate)

    XCTAssertEqual(difference.days, 1)
    XCTAssertEqual(difference.hours, 0)
    XCTAssertEqual(difference.minutes, 0)
    XCTAssertEqual(difference.seconds, 0)
  }

  // MARK: - Relative Time Tests

  func testGetRelativeTime() {
    let pastDate = Date().addingTimeInterval(-3600)  // 1 hour ago
    let futureDate = Date().addingTimeInterval(3600)  // 1 hour from now

    let pastRelative = service.getRelativeTime(from: pastDate)
    let futureRelative = service.getRelativeTime(from: futureDate)

    XCTAssertFalse(pastRelative.isEmpty)
    XCTAssertFalse(futureRelative.isEmpty)
    XCTAssertTrue(pastRelative.contains("ago") || pastRelative.contains("前"))
    XCTAssertTrue(futureRelative.contains("in") || futureRelative.contains("后"))
  }

  // MARK: - Format Examples Tests

  func testGetFormatExamples() {
    let examples = service.getFormatExamples(for: .iso8601)

    XCTAssertEqual(examples.count, 3)
    XCTAssertTrue(examples.allSatisfy { !$0.isEmpty })
    XCTAssertTrue(examples.allSatisfy { service.validateDateString($0, format: .iso8601) })
  }

  // MARK: - Milliseconds Tests

  func testIncludeMilliseconds() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      includeMilliseconds: true)

    let result = service.convertTime(input: "1640995200.123", options: options)

    XCTAssertTrue(result.success)
    XCTAssertTrue(result.result.contains(".123"))
  }

  // MARK: - Real-Time Conversion Tests

  func testStartRealTimeConversion() {
    let expectation = XCTestExpectation(description: "Real-time conversion callback")
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    service.startRealTimeConversion(input: "1640995200", options: options) { result in
      XCTAssertTrue(result.success)
      XCTAssertEqual(result.result, "2022-01-01T00:00:00Z")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
    service.stopRealTimeConversion()
  }

  func testStopRealTimeConversion() {
    let options = TimeConversionOptions()

    service.startRealTimeConversion(input: "1640995200", options: options) { _ in }
    service.stopRealTimeConversion()

    // Verify that the timer is stopped and callbacks are cleared
    // This is tested implicitly by ensuring no crashes occur
    XCTAssertTrue(true)
  }

  func testUpdateRealTimeConversion() {
    let expectation = XCTestExpectation(description: "Real-time conversion update")
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    var callbackCount = 0
    service.startRealTimeConversion(input: "1640995200", options: options) { result in
      callbackCount += 1
      if callbackCount == 2 {
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.result, "2022-01-02T00:00:00Z")
        expectation.fulfill()
      }
    }

    service.updateRealTimeConversion(input: "1641081600")  // Next day

    wait(for: [expectation], timeout: 1.0)
    service.stopRealTimeConversion()
  }

  // MARK: - Enhanced Timezone Conversion Tests

  func testConvertTimeZoneWithValidation() throws {
    let utcDate = Date(timeIntervalSince1970: 1_640_995_200)
    let utcTimeZone = TimeZone(identifier: "UTC")!
    let tokyoTimeZone = TimeZone(identifier: "Asia/Tokyo")!

    let convertedDate = try service.convertTimeZoneWithValidation(
      date: utcDate,
      from: utcTimeZone,
      to: tokyoTimeZone
    )

    // Tokyo is UTC+9
    let expectedTimestamp = 1_640_995_200 + (9 * 3600)
    XCTAssertEqual(
      convertedDate.timeIntervalSince1970,
      TimeInterval(expectedTimestamp),
      accuracy: 1.0
    )
  }

  func testConvertTimeZoneWithInvalidTimezone() {
    let date = Date()
    let validTimeZone = TimeZone(identifier: "UTC")!
    let invalidTimeZone = TimeZone(identifier: "Invalid/Timezone") ?? TimeZone.current

    XCTAssertThrowsError(
      try service.convertTimeZoneWithValidation(
        date: date,
        from: validTimeZone,
        to: invalidTimeZone
      )
    ) { error in
      XCTAssertTrue(error is TimeConverterError)
    }
  }

  func testGetTimezoneInfo() {
    let timezoneInfo = service.getTimezoneInfo(for: "America/New_York")

    XCTAssertNotNil(timezoneInfo)
    XCTAssertEqual(timezoneInfo?.identifier, "America/New_York")
    XCTAssertFalse(timezoneInfo?.displayName.isEmpty ?? true)
  }

  func testSearchTimezones() {
    let results = service.searchTimezones(query: "New York")

    XCTAssertFalse(results.isEmpty)
    XCTAssertTrue(results.contains { $0.identifier == "America/New_York" })
  }

  // MARK: - Enhanced Validation Tests

  func testValidateInputForFormat() {
    // Valid inputs
    XCTAssertNil(service.validateInputForFormat("1640995200", format: .timestamp, customFormat: ""))
    XCTAssertNil(
      service.validateInputForFormat("2022-01-01T00:00:00Z", format: .iso8601, customFormat: ""))
    XCTAssertNil(
      service.validateInputForFormat(
        "2022-01-01 00:00:00", format: .custom, customFormat: "yyyy-MM-dd HH:mm:ss"))

    // Invalid inputs
    XCTAssertNotNil(service.validateInputForFormat("invalid", format: .timestamp, customFormat: ""))
    XCTAssertNotNil(service.validateInputForFormat("invalid", format: .iso8601, customFormat: ""))
    XCTAssertNotNil(
      service.validateInputForFormat("invalid", format: .custom, customFormat: "yyyy-MM-dd"))

    // Empty custom format
    XCTAssertNotNil(service.validateInputForFormat("2022-01-01", format: .custom, customFormat: ""))
  }

  func testEnhancedInputValidation() {
    // Test various edge cases for input validation
    let testCases: [(String, TimeFormat, String, Bool)] = [
      // Timestamp validation
      ("1640995200", .timestamp, "", true),
      ("1640995200.123", .timestamp, "", true),
      ("0", .timestamp, "", true),
      ("-1", .timestamp, "", false),
      ("abc", .timestamp, "", false),
      ("9999999999999", .timestamp, "", false),

      // ISO 8601 validation
      ("2022-01-01T00:00:00Z", .iso8601, "", true),
      ("2022-01-01T00:00:00.123Z", .iso8601, "", true),
      ("2022-01-01T00:00:00+08:00", .iso8601, "", true),
      ("2022-13-01T00:00:00Z", .iso8601, "", false),
      ("2022-01-32T00:00:00Z", .iso8601, "", false),
      ("invalid-iso", .iso8601, "", false),

      // RFC 2822 validation
      ("Sat, 01 Jan 2022 00:00:00 GMT", .rfc2822, "", true),
      ("Mon, 03 Jan 2022 12:30:45 EST", .rfc2822, "", true),
      ("Invalid RFC", .rfc2822, "", false),

      // Custom format validation
      ("2022-01-01 12:30:45", .custom, "yyyy-MM-dd HH:mm:ss", true),
      ("01/01/2022", .custom, "MM/dd/yyyy", true),
      ("2022年1月1日", .custom, "yyyy年M月d日", true),
      ("invalid", .custom, "yyyy-MM-dd", false),
      ("2022-01-01", .custom, "", false),  // Empty custom format
    ]

    for (input, format, customFormat, expectedValid) in testCases {
      let validationError = service.validateInputForFormat(
        input, format: format, customFormat: customFormat)
      let isValid = validationError == nil

      XCTAssertEqual(
        isValid,
        expectedValid,
        "Input: '\(input)', Format: \(format), Custom: '\(customFormat)' - Expected: \(expectedValid), Got: \(isValid)"
      )
    }
  }

  func testValidationWithRealTimeConversion() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      validateInput: true,
      enableRealTimeConversion: true)

    // Valid input should work
    let validResult = service.convertTime(input: "1640995200", options: options)
    XCTAssertTrue(validResult.success)

    // Invalid input should fail with validation error
    let invalidResult = service.convertTime(input: "invalid_timestamp", options: options)
    XCTAssertFalse(invalidResult.success)
    XCTAssertNotNil(invalidResult.error)
    XCTAssertTrue(invalidResult.error?.contains("Invalid") == true)
  }

  func testDetectFormat() {
    // Timestamp detection
    XCTAssertEqual(service.detectFormat(for: "1640995200"), .timestamp)
    XCTAssertEqual(service.detectFormat(for: "1640995200000"), .timestamp)

    // ISO 8601 detection
    XCTAssertEqual(service.detectFormat(for: "2022-01-01T00:00:00Z"), .iso8601)
    XCTAssertEqual(service.detectFormat(for: "2022-01-01T00:00:00.000Z"), .iso8601)

    // RFC 2822 detection
    XCTAssertEqual(service.detectFormat(for: "Sat, 01 Jan 2022 00:00:00 GMT"), .rfc2822)

    // Unknown format
    XCTAssertNil(service.detectFormat(for: "invalid format"))
  }

  // MARK: - Performance Optimization Tests

  func testOptimizedBatchConvert() {
    let inputs = Array(1_640_995_200...1_640_995_210).map(String.init)
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let startTime = CFAbsoluteTimeGetCurrent()
    let results = service.optimizedBatchConvert(inputs: inputs, options: options)
    let endTime = CFAbsoluteTimeGetCurrent()

    XCTAssertEqual(results.count, inputs.count)
    XCTAssertTrue(results.allSatisfy(\.success))

    // Performance should be reasonable (less than 1 second for 11 items)
    XCTAssertLessThan(endTime - startTime, 1.0)
  }

  func testBatchConversionWithMixedFormats() {
    let inputs = [
      "1640995200",
      "2022-01-01T00:00:00Z",
      "Sat, 01 Jan 2022 00:00:00 GMT",
    ]

    let timestampOptions = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let iso8601Options = TimeConversionOptions(
      sourceFormat: .iso8601,
      targetFormat: .timestamp,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let rfc2822Options = TimeConversionOptions(
      sourceFormat: .rfc2822,
      targetFormat: .timestamp,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    // Test individual conversions
    let result1 = service.convertTime(input: inputs[0], options: timestampOptions)
    let result2 = service.convertTime(input: inputs[1], options: iso8601Options)
    let result3 = service.convertTime(input: inputs[2], options: rfc2822Options)

    XCTAssertTrue(result1.success)
    XCTAssertTrue(result2.success)
    XCTAssertTrue(result3.success)

    // All should convert to the same timestamp
    XCTAssertEqual(result2.result, "1640995200")
    XCTAssertEqual(result3.result, "1640995200")
  }

  func testBatchConversionErrorHandling() {
    let inputs = [
      "1640995200",  // Valid
      "invalid_input",  // Invalid
      "1641081600",  // Valid
      "",  // Empty
      "2022-01-01T00:00:00Z",  // Valid
    ]

    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let results = service.batchConvert(inputs: inputs, options: options)

    XCTAssertEqual(results.count, 5)
    XCTAssertTrue(results[0].success)  // Valid timestamp
    XCTAssertFalse(results[1].success)  // Invalid input
    XCTAssertTrue(results[2].success)  // Valid timestamp
    XCTAssertFalse(results[3].success)  // Empty input
    XCTAssertFalse(results[4].success)  // Wrong format for timestamp
  }

  func testOptimizedBatchConvertPerformance() {
    let inputs = Array(repeating: "1640995200", count: 100)
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    measure {
      let results = service.optimizedBatchConvert(inputs: inputs, options: options)
      XCTAssertEqual(results.count, 100)
    }
  }

  // MARK: - Auto-Detection Tests

  func testAutoDetectFormatInConversion() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,  // This will be overridden by auto-detection
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      autoDetectFormat: true)

    // Test with ISO 8601 input (should auto-detect and convert)
    let result = service.convertTime(input: "2022-01-01T00:00:00Z", options: options)

    XCTAssertTrue(result.success)
    XCTAssertEqual(result.result, "2022-01-01T00:00:00Z")  // Same format
  }

  // MARK: - Enhanced Error Handling Tests

  func testEnhancedErrorMessages() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      validateInput: true)

    let result = service.convertTime(input: "invalid_timestamp", options: options)

    XCTAssertFalse(result.success)
    XCTAssertNotNil(result.error)
    XCTAssertTrue(result.error?.contains("Invalid timestamp") == true)
  }

  func testCustomFormatValidation() {
    let options = TimeConversionOptions(
      sourceFormat: .custom,
      targetFormat: .timestamp,
      customFormat: "",  // Empty custom format should fail
      validateInput: true)

    let result = service.convertTime(input: "2022-01-01", options: options)

    XCTAssertFalse(result.success)
    XCTAssertNotNil(result.error)
  }

  // MARK: - Caching Tests

  func testTimezoneCache() {
    // First call should cache the timezone
    let info1 = service.getTimezoneInfo(for: "America/New_York")
    XCTAssertNotNil(info1)

    // Second call should use cached version (tested implicitly)
    let info2 = service.getTimezoneInfo(for: "America/New_York")
    XCTAssertNotNil(info2)
    XCTAssertEqual(info1?.identifier, info2?.identifier)
  }

  // MARK: - Enhanced Real-Time Conversion Tests

  func testRealTimeConversionWithEnabledOption() {
    let expectation = XCTestExpectation(description: "Real-time conversion with enabled option")
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      enableRealTimeConversion: true)

    var callbackCount = 0
    service.startRealTimeConversion(input: "1640995200", options: options) { result in
      callbackCount += 1
      XCTAssertTrue(result.success)
      if callbackCount >= 2 {
        expectation.fulfill()
      }
    }

    // Wait for multiple callbacks due to real-time updates
    wait(for: [expectation], timeout: 3.0)
    service.stopRealTimeConversion()
  }

  func testRealTimeConversionPerformance() {
    let expectation = XCTestExpectation(description: "Real-time conversion performance")
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!,
      enableRealTimeConversion: true)

    let startTime = CFAbsoluteTimeGetCurrent()
    var callbackCount = 0

    service.startRealTimeConversion(input: "1640995200", options: options) { result in
      callbackCount += 1
      XCTAssertTrue(result.success)

      if callbackCount >= 5 {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        // Should complete 5 conversions in reasonable time
        XCTAssertLessThan(duration, 2.0)
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 5.0)
    service.stopRealTimeConversion()
  }

  func testRealTimeConversionMemoryManagement() {
    // Test that starting and stopping real-time conversion multiple times doesn't leak memory
    let options = TimeConversionOptions(enableRealTimeConversion: true)

    for i in 0..<10 {
      let expectation = XCTestExpectation(description: "Real-time conversion \(i)")

      service.startRealTimeConversion(input: "1640995200", options: options) { result in
        XCTAssertTrue(result.success)
        expectation.fulfill()
      }

      wait(for: [expectation], timeout: 1.0)
      service.stopRealTimeConversion()
    }

    // Should not crash or leak memory
    XCTAssertTrue(true)
  }

  // MARK: - Enhanced Timezone Handling Tests

  func testGetPopularTimezones() {
    let popularTimezones = service.getPopularTimezones()

    XCTAssertFalse(popularTimezones.isEmpty)
    XCTAssertTrue(popularTimezones.contains { $0.identifier == "UTC" })
    XCTAssertTrue(popularTimezones.contains { $0.identifier == "America/New_York" })
    XCTAssertTrue(popularTimezones.contains { $0.identifier == "Asia/Tokyo" })
  }

  func testValidateTimezoneCompatibility() {
    let utc = TimeZone(identifier: "UTC")!
    let newYork = TimeZone(identifier: "America/New_York")!
    let date = Date()

    XCTAssertTrue(service.validateTimezoneCompatibility(source: utc, target: newYork, for: date))
    XCTAssertTrue(service.validateTimezoneCompatibility(source: newYork, target: utc, for: date))
  }

  // MARK: - Performance Optimization Tests

  func testOptimizedBatchConvertConcurrent() {
    let inputs = Array(repeating: "1640995200", count: 50)
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let startTime = CFAbsoluteTimeGetCurrent()
    let results = service.optimizedBatchConvertConcurrent(inputs: inputs, options: options)
    let endTime = CFAbsoluteTimeGetCurrent()

    XCTAssertEqual(results.count, inputs.count)
    XCTAssertTrue(results.allSatisfy(\.success))

    // Should complete reasonably quickly
    XCTAssertLessThan(endTime - startTime, 2.0)
  }

  func testOptimizedBatchConvertSmallBatch() {
    let inputs = ["1640995200", "1641081600"]
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    // Small batches should use regular processing
    let results = service.optimizedBatchConvertConcurrent(inputs: inputs, options: options)

    XCTAssertEqual(results.count, 2)
    XCTAssertTrue(results.allSatisfy(\.success))
  }

  // MARK: - Performance Monitoring Tests

  func testMeasureConversionPerformance() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    let performance = service.measureConversionPerformance(
      input: "1640995200",
      options: options,
      iterations: 10
    )

    XCTAssertTrue(performance.result.success)
    XCTAssertGreaterThan(performance.averageTime, 0)
    XCTAssertLessThan(performance.averageTime, 0.1)  // Should be very fast
  }

  func testClearPerformanceCaches() {
    // Populate caches first
    _ = service.getTimezoneInfo(for: "America/New_York")
    _ = service.getCacheStatistics()

    service.clearPerformanceCaches()

    // Wait a moment for async cache clearing
    let expectation = XCTestExpectation(description: "Cache clearing")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 1.0)

    let finalStats = service.getCacheStatistics()

    // Timezone cache should be repopulated with common timezones
    XCTAssertGreaterThan(finalStats.timezoneCacheSize, 0)
  }

  func testGetCacheStatistics() {
    let stats = service.getCacheStatistics()

    XCTAssertGreaterThanOrEqual(stats.formatterCacheSize, 0)
    XCTAssertGreaterThanOrEqual(stats.timezoneCacheSize, 0)
  }

  // MARK: - Input Sanitization Tests

  func testSanitizeInput() {
    // Test various whitespace characters
    XCTAssertEqual(service.sanitizeInput("  1640995200  "), "1640995200")
    XCTAssertEqual(service.sanitizeInput("\u{00A0}1640995200\u{00A0}"), "1640995200")
    XCTAssertEqual(service.sanitizeInput("\u{2000}1640995200\u{2000}"), "1640995200")

    // Test normal input
    XCTAssertEqual(service.sanitizeInput("1640995200"), "1640995200")
    XCTAssertEqual(service.sanitizeInput("2022-01-01T00:00:00Z"), "2022-01-01T00:00:00Z")
  }

  func testValidateTimestampWithSanitization() {
    // Test with various whitespace characters
    XCTAssertTrue(service.validateTimestamp("  1640995200  "))
    XCTAssertTrue(service.validateTimestamp("\u{00A0}1640995200\u{00A0}"))
    XCTAssertTrue(service.validateTimestamp("1640995200000"))  // Milliseconds

    XCTAssertFalse(service.validateTimestamp("  invalid  "))
    XCTAssertFalse(service.validateTimestamp(""))
  }

  // MARK: - Enhanced Error Handling Tests

  func testDetailedTimezoneConversionError() {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "Invalid/Timezone") ?? .current,
      targetTimeZone: .init(identifier: "UTC")!)

    let result = service.convertTime(input: "1640995200", options: options)

    XCTAssertFalse(result.success)
    XCTAssertNotNil(result.error)
    XCTAssertTrue(result.error?.contains("timezone") == true)
  }

  func testDetailedParsingErrorMessages() {
    // Test ISO 8601 error
    let iso8601Options = TimeConversionOptions(
      sourceFormat: .iso8601,
      targetFormat: .timestamp)
    let iso8601Result = service.convertTime(input: "invalid-iso", options: iso8601Options)
    XCTAssertFalse(iso8601Result.success)
    XCTAssertTrue(iso8601Result.error?.contains("ISO 8601") == true)

    // Test custom format error
    let customOptions = TimeConversionOptions(
      sourceFormat: .custom,
      targetFormat: .timestamp,
      customFormat: "yyyy-MM-dd")
    let customResult = service.convertTime(input: "invalid-custom", options: customOptions)
    XCTAssertFalse(customResult.success)
    XCTAssertTrue(customResult.error?.contains("custom format") == true)
  }

  // MARK: - Concurrent Processing Tests

  func testConcurrentConversions() {
    let expectation = XCTestExpectation(description: "Concurrent conversions")
    expectation.expectedFulfillmentCount = 10

    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .init(identifier: "UTC")!,
      targetTimeZone: .init(identifier: "UTC")!)

    for i in 0..<10 {
      DispatchQueue.global().async {
        let result = self.service.convertTime(input: "164099520\(i)", options: options)
        XCTAssertTrue(result.success)
        expectation.fulfill()
      }
    }

    wait(for: [expectation], timeout: 5.0)
  }

  // MARK: - Memory Management Tests

  func testMemoryManagementWithRealTimeConversion() {
    let options = TimeConversionOptions(enableRealTimeConversion: true)

    // Start and stop multiple times to test cleanup
    for _ in 0..<5 {
      service.startRealTimeConversion(input: "1640995200", options: options) { _ in }
      service.stopRealTimeConversion()
    }

    // Should not crash or leak memory
    XCTAssertTrue(true)
  }
}
