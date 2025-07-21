@testable import Tools
import XCTest

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

    let result = service
      .convertTime(input: "1640995200", options: options) // 2022-01-01 00:00:00 UTC

    XCTAssertTrue(result.success)
    // Should be 5 hours earlier in New York (EST)
    XCTAssertTrue(result.result.contains("2021-12-31T19:00:00"))
  }

  func testTimeZoneConversionMethod() {
    let utcDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00 UTC
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
    XCTAssertFalse(service.validateTimestamp("9999999999999")) // Too large
  }

  func testDateStringValidation() {
    XCTAssertTrue(service.validateDateString("2022-01-01T00:00:00Z", format: .iso8601))
    XCTAssertTrue(service.validateDateString("Sat, 01 Jan 2022 00:00:00 GMT", format: .rfc2822))
    XCTAssertTrue(service.validateDateString(
      "2022-01-01 00:00:00",
      format: .custom,
      customFormat: "yyyy-MM-dd HH:mm:ss"))

    XCTAssertFalse(service.validateDateString("invalid date", format: .iso8601))
    XCTAssertFalse(service.validateDateString(
      "2022-13-01T00:00:00Z",
      format: .iso8601)) // Invalid month
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
    let startDate = Date(timeIntervalSince1970: 1_640_995_200) // 2022-01-01 00:00:00
    let endDate = Date(timeIntervalSince1970: 1_641_081_600) // 2022-01-02 00:00:00

    let difference = service.calculateTimeDifference(from: startDate, to: endDate)

    XCTAssertEqual(difference.days, 1)
    XCTAssertEqual(difference.hours, 0)
    XCTAssertEqual(difference.minutes, 0)
    XCTAssertEqual(difference.seconds, 0)
  }

  // MARK: - Relative Time Tests

  func testGetRelativeTime() {
    let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
    let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

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
}
