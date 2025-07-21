import Foundation

// MARK: - Time Converter Service

@Observable
class TimeConverterService {
  // MARK: - Properties

  private let iso8601Formatter: ISO8601DateFormatter
  private let rfc2822Formatter: DateFormatter

  // MARK: - Initialization

  init() {
    // ISO 8601 formatter
    iso8601Formatter = ISO8601DateFormatter()
    iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    // RFC 2822 formatter
    rfc2822Formatter = DateFormatter()
    rfc2822Formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
    rfc2822Formatter.locale = Locale(identifier: "en_US_POSIX")
  }

  // MARK: - Main Conversion Method

  func convertTime(input: String, options: TimeConversionOptions) -> TimeConversionResult {
    guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return .failure(error: "Input cannot be empty")
    }

    // First, parse the input based on source format
    guard let sourceDate = parseInput(
      input,
      format: options.sourceFormat,
      timeZone: options.sourceTimeZone,
      customFormat: options.customFormat)
    else {
      return .failure(
        error: "Failed to parse input with format: \(options.sourceFormat.displayName)")
    }

    // Then, format the date to target format
    let result = formatDate(
      sourceDate,
      format: options.targetFormat,
      timeZone: options.targetTimeZone,
      customFormat: options.customFormat,
      includeMilliseconds: options.includeMilliseconds)

    return .success(
      result: result,
      timestamp: sourceDate.timeIntervalSince1970,
      date: sourceDate)
  }

  // MARK: - Current Time Methods

  func getCurrentTime(
    format: TimeFormat,
    timeZone: TimeZone = .current,
    customFormat: String = "yyyy-MM-dd HH:mm:ss",
    includeMilliseconds: Bool = false) -> String {
    let currentDate = Date()
    return formatDate(
      currentDate,
      format: format,
      timeZone: timeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds)
  }

  func getCurrentTimestamp(includeMilliseconds: Bool = false) -> String {
    let timestamp = Date().timeIntervalSince1970
    if includeMilliseconds {
      return String(format: "%.3f", timestamp)
    } else {
      return String(Int(timestamp))
    }
  }

  // MARK: - Time Zone Conversion

  func convertTimeZone(
    date: Date,
    from sourceTimeZone: TimeZone,
    to targetTimeZone: TimeZone) -> Date {
    let sourceOffset = sourceTimeZone.secondsFromGMT(for: date)
    let targetOffset = targetTimeZone.secondsFromGMT(for: date)
    let offsetDifference = targetOffset - sourceOffset

    return date.addingTimeInterval(TimeInterval(offsetDifference))
  }

  // MARK: - Validation Methods

  func validateTimestamp(_ input: String) -> Bool {
    guard let timestamp = Double(input) else { return false }
    // Check if timestamp is within reasonable range (1970-2100)
    return timestamp >= 0 && timestamp <= 4_102_444_800 // Jan 1, 2100
  }

  func validateDateString(_ input: String, format: TimeFormat, customFormat: String = "") -> Bool {
    parseInput(input, format: format, timeZone: .current, customFormat: customFormat) != nil
  }

  // MARK: - Private Helper Methods

  private func parseInput(
    _ input: String,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String) -> Date? {
    let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

    switch format {
    case .timestamp:
      return parseTimestamp(trimmedInput)

    case .iso8601:
      return parseISO8601(trimmedInput)

    case .rfc2822:
      return parseRFC2822(trimmedInput, timeZone: timeZone)

    case .custom:
      return parseCustomFormat(trimmedInput, format: customFormat, timeZone: timeZone)
    }
  }

  private func parseTimestamp(_ input: String) -> Date? {
    guard let timestamp = Double(input) else { return nil }

    // Handle both seconds and milliseconds timestamps
    let adjustedTimestamp: TimeInterval = if timestamp > 1_000_000_000_000 { // Likely milliseconds
      timestamp / 1000
    } else {
      timestamp
    }

    return Date(timeIntervalSince1970: adjustedTimestamp)
  }

  private func parseISO8601(_ input: String) -> Date? {
    // Try with fractional seconds first
    if let date = iso8601Formatter.date(from: input) {
      return date
    }

    // Try without fractional seconds
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: input)
  }

  private func parseRFC2822(_ input: String, timeZone: TimeZone) -> Date? {
    rfc2822Formatter.timeZone = timeZone
    return rfc2822Formatter.date(from: input)
  }

  private func parseCustomFormat(_ input: String, format: String, timeZone: TimeZone) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.timeZone = timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.date(from: input)
  }

  private func formatDate(
    _ date: Date,
    format: TimeFormat,
    timeZone: TimeZone,
    customFormat: String,
    includeMilliseconds: Bool) -> String {
    switch format {
    case .timestamp:
      let timestamp = date.timeIntervalSince1970
      if includeMilliseconds {
        return String(format: "%.3f", timestamp)
      } else {
        return String(Int(timestamp))
      }

    case .iso8601:
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = timeZone
      if includeMilliseconds {
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      } else {
        formatter.formatOptions = [.withInternetDateTime]
      }
      return formatter.string(from: date)

    case .rfc2822:
      let formatter = DateFormatter()
      formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
      formatter.timeZone = timeZone
      formatter.locale = Locale(identifier: "en_US_POSIX")
      return formatter.string(from: date)

    case .custom:
      let formatter = DateFormatter()
      formatter.dateFormat = customFormat
      formatter.timeZone = timeZone
      formatter.locale = Locale(identifier: "en_US_POSIX")
      return formatter.string(from: date)
    }
  }
}

// MARK: - Time Converter Service Extensions

extension TimeConverterService {
  // MARK: - Batch Conversion

  func batchConvert(inputs: [String], options: TimeConversionOptions) -> [TimeConversionResult] {
    inputs.map { convertTime(input: $0, options: options) }
  }

  // MARK: - Time Difference Calculation

  func calculateTimeDifference(
    from startDate: Date,
    to endDate: Date) -> (days: Int, hours: Int, minutes: Int, seconds: Int) {
    let timeInterval = endDate.timeIntervalSince(startDate)
    let totalSeconds = Int(abs(timeInterval))

    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    return (days: days, hours: hours, minutes: minutes, seconds: seconds)
  }

  // MARK: - Relative Time

  func getRelativeTime(from date: Date, to referenceDate: Date = Date()) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full

    return formatter.localizedString(for: date, relativeTo: referenceDate)
  }

  // MARK: - Format Examples

  func getFormatExamples(for format: TimeFormat, timeZone: TimeZone = .current) -> [String] {
    let sampleDate = Date()
    let pastDate = Date().addingTimeInterval(-86400) // 1 day ago
    let futureDate = Date().addingTimeInterval(86400) // 1 day from now

    return [
      formatDate(
        sampleDate,
        format: format,
        timeZone: timeZone,
        customFormat: "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: false),
      formatDate(
        pastDate,
        format: format,
        timeZone: timeZone,
        customFormat: "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: false),
      formatDate(
        futureDate,
        format: format,
        timeZone: timeZone,
        customFormat: "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: false)
    ]
  }
}
