import Foundation

// MARK: - Time Format Enumeration

enum TimeFormat: String, CaseIterable, Identifiable {
  case timestamp
  case iso8601
  case rfc2822
  case custom

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .timestamp:
      "Unix Timestamp"
    case .iso8601:
      "ISO 8601"
    case .rfc2822:
      "RFC 2822"
    case .custom:
      "Custom Format"
    }
  }

  var description: String {
    switch self {
    case .timestamp:
      "Seconds since January 1, 1970 UTC"
    case .iso8601:
      "2024-01-01T12:00:00Z"
    case .rfc2822:
      "Mon, 01 Jan 2024 12:00:00 GMT"
    case .custom:
      "User-defined format"
    }
  }
}

// MARK: - Time Conversion Result

struct TimeConversionResult {
  let success: Bool
  let result: String
  let error: String?
  let timestamp: TimeInterval?
  let date: Date?

  static func success(
    result: String,
    timestamp: TimeInterval? = nil,
    date: Date? = nil) -> TimeConversionResult {
    TimeConversionResult(
      success: true,
      result: result,
      error: nil,
      timestamp: timestamp,
      date: date)
  }

  static func failure(error: String) -> TimeConversionResult {
    TimeConversionResult(success: false, result: "", error: error, timestamp: nil, date: nil)
  }
}

// MARK: - Time Zone Info

struct TimeZoneInfo: Identifiable, Hashable {
  let id = UUID()
  let identifier: String
  let displayName: String
  let abbreviation: String
  let offsetFromGMT: Int

  init(timeZone: TimeZone) {
    identifier = timeZone.identifier
    displayName = timeZone.localizedName(for: .standard, locale: .current) ?? timeZone.identifier
    abbreviation = timeZone.abbreviation() ?? ""
    offsetFromGMT = timeZone.secondsFromGMT()
  }

  var offsetString: String {
    let hours = offsetFromGMT / 3600
    let minutes = abs(offsetFromGMT % 3600) / 60
    let sign = offsetFromGMT >= 0 ? "+" : "-"
    return String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)
  }
}

// MARK: - Time Conversion Options

struct TimeConversionOptions {
  var sourceFormat: TimeFormat
  var targetFormat: TimeFormat
  var sourceTimeZone: TimeZone
  var targetTimeZone: TimeZone
  var customFormat: String
  var includeMilliseconds: Bool

  init(
    sourceFormat: TimeFormat = .timestamp,
    targetFormat: TimeFormat = .iso8601,
    sourceTimeZone: TimeZone = .current,
    targetTimeZone: TimeZone = .current,
    customFormat: String = "yyyy-MM-dd HH:mm:ss",
    includeMilliseconds: Bool = false) {
    self.sourceFormat = sourceFormat
    self.targetFormat = targetFormat
    self.sourceTimeZone = sourceTimeZone
    self.targetTimeZone = targetTimeZone
    self.customFormat = customFormat
    self.includeMilliseconds = includeMilliseconds
  }
}

// MARK: - Common Time Zones

extension TimeZoneInfo {
  static let commonTimeZones: [TimeZoneInfo] = [
    TimeZoneInfo(timeZone: TimeZone(identifier: "UTC")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "America/New_York")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "America/Los_Angeles")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "Europe/London")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "Europe/Paris")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "Asia/Tokyo")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "Asia/Shanghai")!),
    TimeZoneInfo(timeZone: TimeZone(identifier: "Australia/Sydney")!),
    TimeZoneInfo(timeZone: TimeZone.current)
  ]
}
