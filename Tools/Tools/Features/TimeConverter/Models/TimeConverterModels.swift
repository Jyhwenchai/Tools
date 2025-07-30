import Foundation

// MARK: - Time Format Enumeration

enum TimeFormat: String, CaseIterable, Identifiable, Codable {
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
    date: Date? = nil
  ) -> TimeConversionResult {
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
  var enableRealTimeConversion: Bool
  var batchProcessingEnabled: Bool
  var validateInput: Bool
  var preserveHistory: Bool
  var autoDetectFormat: Bool

  init(
    sourceFormat: TimeFormat = .timestamp,
    targetFormat: TimeFormat = .iso8601,
    sourceTimeZone: TimeZone = .current,
    targetTimeZone: TimeZone = .current,
    customFormat: String = "yyyy-MM-dd HH:mm:ss",
    includeMilliseconds: Bool = false,
    enableRealTimeConversion: Bool = false,
    batchProcessingEnabled: Bool = false,
    validateInput: Bool = true,
    preserveHistory: Bool = true,
    autoDetectFormat: Bool = false
  ) {
    self.sourceFormat = sourceFormat
    self.targetFormat = targetFormat
    self.sourceTimeZone = sourceTimeZone
    self.targetTimeZone = targetTimeZone
    self.customFormat = customFormat
    self.includeMilliseconds = includeMilliseconds
    self.enableRealTimeConversion = enableRealTimeConversion
    self.batchProcessingEnabled = batchProcessingEnabled
    self.validateInput = validateInput
    self.preserveHistory = preserveHistory
    self.autoDetectFormat = autoDetectFormat
  }
}

// MARK: - Conversion Preset

struct ConversionPreset: Identifiable, Codable, Hashable {
  let id = UUID()
  let name: String
  let sourceFormat: TimeFormat
  let targetFormat: TimeFormat
  let sourceTimeZone: TimeZone
  let targetTimeZone: TimeZone
  let customFormat: String?
  let includeMilliseconds: Bool
  let createdAt: Date

  init(
    name: String,
    sourceFormat: TimeFormat,
    targetFormat: TimeFormat,
    sourceTimeZone: TimeZone,
    targetTimeZone: TimeZone,
    customFormat: String? = nil,
    includeMilliseconds: Bool = false
  ) {
    self.name = name
    self.sourceFormat = sourceFormat
    self.targetFormat = targetFormat
    self.sourceTimeZone = sourceTimeZone
    self.targetTimeZone = targetTimeZone
    self.customFormat = customFormat
    self.includeMilliseconds = includeMilliseconds
    self.createdAt = Date()
  }

  var displayDescription: String {
    "\(sourceFormat.displayName) → \(targetFormat.displayName)"
  }

  // Codable implementation for TimeZone
  enum CodingKeys: String, CodingKey {
    case name, sourceFormat, targetFormat, customFormat, includeMilliseconds, createdAt
    case sourceTimeZoneIdentifier, targetTimeZoneIdentifier
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    sourceFormat = try container.decode(TimeFormat.self, forKey: .sourceFormat)
    targetFormat = try container.decode(TimeFormat.self, forKey: .targetFormat)
    customFormat = try container.decodeIfPresent(String.self, forKey: .customFormat)
    includeMilliseconds = try container.decode(Bool.self, forKey: .includeMilliseconds)
    createdAt = try container.decode(Date.self, forKey: .createdAt)

    let sourceTimeZoneId = try container.decode(String.self, forKey: .sourceTimeZoneIdentifier)
    let targetTimeZoneId = try container.decode(String.self, forKey: .targetTimeZoneIdentifier)
    sourceTimeZone = TimeZone(identifier: sourceTimeZoneId) ?? .current
    targetTimeZone = TimeZone(identifier: targetTimeZoneId) ?? .current
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(sourceFormat, forKey: .sourceFormat)
    try container.encode(targetFormat, forKey: .targetFormat)
    try container.encodeIfPresent(customFormat, forKey: .customFormat)
    try container.encode(includeMilliseconds, forKey: .includeMilliseconds)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(sourceTimeZone.identifier, forKey: .sourceTimeZoneIdentifier)
    try container.encode(targetTimeZone.identifier, forKey: .targetTimeZoneIdentifier)
  }
}

// MARK: - Conversion History

struct ConversionHistory: Identifiable, Codable {
  let id: UUID
  let timestamp: Date
  let input: String
  let output: String
  let options: TimeConversionOptions
  let success: Bool
  let errorMessage: String?

  init(
    input: String,
    output: String,
    options: TimeConversionOptions,
    success: Bool = true,
    errorMessage: String? = nil
  ) {
    self.id = UUID()
    self.timestamp = Date()
    self.input = input
    self.output = output
    self.options = options
    self.success = success
    self.errorMessage = errorMessage
  }

  var displaySummary: String {
    let formatInfo = "\(options.sourceFormat.displayName) → \(options.targetFormat.displayName)"
    return success ? "\(input) → \(output) (\(formatInfo))" : "Failed: \(input) (\(formatInfo))"
  }

  // Codable implementation for TimeConversionOptions
  enum CodingKeys: String, CodingKey {
    case id, timestamp, input, output, success, errorMessage
    case sourceFormat, targetFormat, customFormat, includeMilliseconds
    case sourceTimeZoneIdentifier, targetTimeZoneIdentifier
    case enableRealTimeConversion, batchProcessingEnabled, validateInput, preserveHistory,
      autoDetectFormat
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    timestamp = try container.decode(Date.self, forKey: .timestamp)
    input = try container.decode(String.self, forKey: .input)
    output = try container.decode(String.self, forKey: .output)
    success = try container.decode(Bool.self, forKey: .success)
    errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)

    // Decode TimeConversionOptions
    let sourceFormat = try container.decode(TimeFormat.self, forKey: .sourceFormat)
    let targetFormat = try container.decode(TimeFormat.self, forKey: .targetFormat)
    let customFormat = try container.decode(String.self, forKey: .customFormat)
    let includeMilliseconds = try container.decode(Bool.self, forKey: .includeMilliseconds)
    let enableRealTimeConversion =
      try container.decodeIfPresent(Bool.self, forKey: .enableRealTimeConversion) ?? false
    let batchProcessingEnabled =
      try container.decodeIfPresent(Bool.self, forKey: .batchProcessingEnabled) ?? false
    let validateInput = try container.decodeIfPresent(Bool.self, forKey: .validateInput) ?? true
    let preserveHistory = try container.decodeIfPresent(Bool.self, forKey: .preserveHistory) ?? true
    let autoDetectFormat =
      try container.decodeIfPresent(Bool.self, forKey: .autoDetectFormat) ?? false

    let sourceTimeZoneId = try container.decode(String.self, forKey: .sourceTimeZoneIdentifier)
    let targetTimeZoneId = try container.decode(String.self, forKey: .targetTimeZoneIdentifier)
    let sourceTimeZone = TimeZone(identifier: sourceTimeZoneId) ?? .current
    let targetTimeZone = TimeZone(identifier: targetTimeZoneId) ?? .current

    options = TimeConversionOptions(
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
      sourceTimeZone: sourceTimeZone,
      targetTimeZone: targetTimeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds,
      enableRealTimeConversion: enableRealTimeConversion,
      batchProcessingEnabled: batchProcessingEnabled,
      validateInput: validateInput,
      preserveHistory: preserveHistory,
      autoDetectFormat: autoDetectFormat
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(timestamp, forKey: .timestamp)
    try container.encode(input, forKey: .input)
    try container.encode(output, forKey: .output)
    try container.encode(success, forKey: .success)
    try container.encodeIfPresent(errorMessage, forKey: .errorMessage)

    // Encode TimeConversionOptions
    try container.encode(options.sourceFormat, forKey: .sourceFormat)
    try container.encode(options.targetFormat, forKey: .targetFormat)
    try container.encode(options.customFormat, forKey: .customFormat)
    try container.encode(options.includeMilliseconds, forKey: .includeMilliseconds)
    try container.encode(options.enableRealTimeConversion, forKey: .enableRealTimeConversion)
    try container.encode(options.batchProcessingEnabled, forKey: .batchProcessingEnabled)
    try container.encode(options.validateInput, forKey: .validateInput)
    try container.encode(options.preserveHistory, forKey: .preserveHistory)
    try container.encode(options.autoDetectFormat, forKey: .autoDetectFormat)
    try container.encode(options.sourceTimeZone.identifier, forKey: .sourceTimeZoneIdentifier)
    try container.encode(options.targetTimeZone.identifier, forKey: .targetTimeZoneIdentifier)
  }
}

// MARK: - ConversionHistory Hashable and Equatable

extension ConversionHistory: Hashable, Equatable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: ConversionHistory, rhs: ConversionHistory) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Time Converter Error

enum TimeConverterError: LocalizedError, Equatable {
  case invalidTimestamp(String)
  case invalidDateFormat(String)
  case timezoneConversionFailed
  case customFormatInvalid(String)
  case inputEmpty
  case outputGenerationFailed

  // New error types for batch and real-time operations
  case batchProcessingFailed([String])
  case realTimeServiceUnavailable
  case realTimeTimerFailed
  case batchInputValidationFailed(String)
  case batchItemProcessingFailed(String, String)
  case historyStorageFailed
  case presetLoadingFailed
  case presetSavingFailed(String)
  case timezoneDataUnavailable(String)
  case formatDetectionFailed(String)

  var errorDescription: String? {
    switch self {
    case .invalidTimestamp(let value):
      return "Invalid timestamp: '\(value)'. Please enter a valid Unix timestamp."
    case .invalidDateFormat(let value):
      return "Invalid date format: '\(value)'. Please check the date format and try again."
    case .timezoneConversionFailed:
      return "Timezone conversion failed. Please verify the selected timezones."
    case .customFormatInvalid(let format):
      return "Invalid custom format: '\(format)'. Please use a valid date format pattern."
    case .inputEmpty:
      return "Input cannot be empty. Please enter a value to convert."
    case .outputGenerationFailed:
      return "Failed to generate output. Please check your input and try again."
    case .batchProcessingFailed(let errors):
      return
        "Batch processing failed with \(errors.count) error(s): \(errors.joined(separator: ", "))"
    case .realTimeServiceUnavailable:
      return "Real-time timestamp service is currently unavailable."
    case .realTimeTimerFailed:
      return "Real-time timer failed to start. Please try again."
    case .batchInputValidationFailed(let details):
      return "Batch input validation failed: \(details)"
    case .batchItemProcessingFailed(let item, let error):
      return "Failed to process batch item '\(item)': \(error)"
    case .historyStorageFailed:
      return "Failed to save conversion history."
    case .presetLoadingFailed:
      return "Failed to load conversion presets."
    case .presetSavingFailed(let name):
      return "Failed to save preset '\(name)'."
    case .timezoneDataUnavailable(let identifier):
      return "Timezone data unavailable for '\(identifier)'."
    case .formatDetectionFailed(let input):
      return "Could not detect format for input: '\(input)'"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .invalidTimestamp:
      return
        "Enter a valid Unix timestamp (e.g., 1640995200 for seconds or 1640995200000 for milliseconds)."
    case .invalidDateFormat:
      return "Use a standard date format like 'YYYY-MM-DD HH:mm:ss' or select a predefined format."
    case .timezoneConversionFailed:
      return "Select valid source and target timezones from the dropdown menus."
    case .customFormatInvalid:
      return "Use standard date format patterns like 'yyyy-MM-dd HH:mm:ss' or 'MM/dd/yyyy'."
    case .inputEmpty:
      return "Enter a timestamp or date value in the input field."
    case .outputGenerationFailed:
      return "Verify your input format and conversion settings."
    case .batchProcessingFailed:
      return "Check individual items in your batch input for formatting errors."
    case .realTimeServiceUnavailable:
      return "Restart the application or check system permissions."
    case .realTimeTimerFailed:
      return "Try stopping and starting the real-time display again."
    case .batchInputValidationFailed:
      return "Ensure all batch items are properly formatted and separated."
    case .batchItemProcessingFailed:
      return "Check the format and content of the failed item."
    case .historyStorageFailed:
      return "Check available storage space and application permissions."
    case .presetLoadingFailed:
      return "Try restarting the application or reset presets to default."
    case .presetSavingFailed:
      return "Ensure the preset name is unique and valid."
    case .timezoneDataUnavailable:
      return "Select a different timezone or update system timezone data."
    case .formatDetectionFailed:
      return "Manually specify the input format or use a standard format."
    }
  }

  var failureReason: String? {
    switch self {
    case .invalidTimestamp:
      return "The provided value is not a valid Unix timestamp."
    case .invalidDateFormat:
      return "The date string does not match the expected format."
    case .timezoneConversionFailed:
      return "Unable to convert between the specified timezones."
    case .customFormatInvalid:
      return "The custom date format pattern is not valid."
    case .inputEmpty:
      return "No input value was provided."
    case .outputGenerationFailed:
      return "The conversion process failed to produce a result."
    case .batchProcessingFailed:
      return "One or more items in the batch failed to process."
    case .realTimeServiceUnavailable:
      return "The real-time timestamp service could not be initialized."
    case .realTimeTimerFailed:
      return "The timer for real-time updates failed to start."
    case .batchInputValidationFailed:
      return "The batch input contains invalid or malformed data."
    case .batchItemProcessingFailed:
      return "A specific item in the batch could not be processed."
    case .historyStorageFailed:
      return "Unable to save the conversion to history."
    case .presetLoadingFailed:
      return "Conversion presets could not be loaded from storage."
    case .presetSavingFailed:
      return "The conversion preset could not be saved."
    case .timezoneDataUnavailable:
      return "The requested timezone information is not available."
    case .formatDetectionFailed:
      return "Automatic format detection was unsuccessful."
    }
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
  ]
}
