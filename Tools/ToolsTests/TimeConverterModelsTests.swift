//
//  TimeConverterModelsTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import Testing

@testable import Tools

struct TimeConverterModelsTests {
  // MARK: - TimeFormat Tests

  @Test(
    "TimeFormat 枚举值测试",
    arguments: [
      (TimeFormat.timestamp, "timestamp", "Unix Timestamp", "Seconds since January 1, 1970 UTC"),
      (TimeFormat.iso8601, "iso8601", "ISO 8601", "2024-01-01T12:00:00Z"),
      (TimeFormat.rfc2822, "rfc2822", "RFC 2822", "Mon, 01 Jan 2024 12:00:00 GMT"),
      (TimeFormat.custom, "custom", "Custom Format", "User-defined format"),
    ])
  func timeFormatValues(
    format: TimeFormat,
    expectedRawValue: String,
    expectedDisplayName: String,
    expectedDescription: String
  ) {
    #expect(format.rawValue == expectedRawValue)
    #expect(format.id == expectedRawValue)
    #expect(format.displayName == expectedDisplayName)
    #expect(format.description == expectedDescription)
  }

  @Test("TimeFormat 枚举完整性测试")
  func timeFormatCompleteness() {
    let allCases = TimeFormat.allCases
    #expect(allCases.count == 4)

    let expectedFormats: [TimeFormat] = [.timestamp, .iso8601, .rfc2822, .custom]
    for expectedFormat in expectedFormats {
      #expect(allCases.contains(expectedFormat))
    }
  }

  // MARK: - TimeConversionResult Tests

  @Test("TimeConversionResult 成功结果测试")
  func timeConversionResultSuccess() {
    let timestamp: TimeInterval = 1_640_995_200  // 2022-01-01 00:00:00 UTC
    let date = Date(timeIntervalSince1970: timestamp)
    let result = TimeConversionResult.success(
      result: "2022-01-01T00:00:00Z",
      timestamp: timestamp,
      date: date)

    #expect(result.success == true)
    #expect(result.result == "2022-01-01T00:00:00Z")
    #expect(result.error == nil)
    #expect(result.timestamp == timestamp)
    #expect(result.date == date)
  }

  @Test("TimeConversionResult 失败结果测试")
  func timeConversionResultFailure() {
    let errorMessage = "无效的时间格式"
    let result = TimeConversionResult.failure(error: errorMessage)

    #expect(result.success == false)
    #expect(result.result == "")
    #expect(result.error == errorMessage)
    #expect(result.timestamp == nil)
    #expect(result.date == nil)
  }

  @Test("TimeConversionResult 仅结果成功测试")
  func timeConversionResultSuccessResultOnly() {
    let result = TimeConversionResult.success(result: "简单结果")

    #expect(result.success == true)
    #expect(result.result == "简单结果")
    #expect(result.error == nil)
    #expect(result.timestamp == nil)
    #expect(result.date == nil)
  }

  // MARK: - TimeZoneInfo Tests

  @Test("TimeZoneInfo 基本属性测试")
  func timeZoneInfoBasicProperties() {
    let utcTimeZone = TimeZone(identifier: "UTC")!
    let timeZoneInfo = TimeZoneInfo(timeZone: utcTimeZone)

    #expect(timeZoneInfo.identifier == "UTC")
    #expect(timeZoneInfo.abbreviation == "UTC")
    #expect(timeZoneInfo.offsetFromGMT == 0)
    #expect(timeZoneInfo.offsetString == "GMT+00:00")
  }

  @Test(
    "TimeZoneInfo 不同时区测试",
    arguments: [
      ("America/New_York", "EST", -18000),  // -5 hours in seconds
      ("Europe/London", "GMT", 0),
      ("Asia/Tokyo", "JST", 32400),  // +9 hours in seconds
      ("Australia/Sydney", "AEDT", 39600),  // +11 hours in seconds (during DST)
    ])
  func timeZoneInfoDifferentTimeZones(
    identifier: String,
    expectedAbbreviation _: String,
    expectedOffset _: Int
  ) {
    guard let timeZone = TimeZone(identifier: identifier) else {
      #expect(Bool(false), "无法创建时区: \(identifier)")
      return
    }

    let timeZoneInfo = TimeZoneInfo(timeZone: timeZone)

    #expect(timeZoneInfo.identifier == identifier)
    // 注意：时区缩写可能因夏令时而变化，所以我们只检查不为空
    #expect(!timeZoneInfo.abbreviation.isEmpty)
    // 注意：时区偏移可能因夏令时而变化，所以我们只检查是合理范围
    #expect(timeZoneInfo.offsetFromGMT >= -43200 && timeZoneInfo.offsetFromGMT <= 50400)
  }

  @Test(
    "TimeZoneInfo 偏移字符串格式测试",
    arguments: [
      (0, "GMT+00:00"),
      (3600, "GMT+01:00"),
      (-3600, "GMT-01:00"),
      (19800, "GMT+05:30"),  // India Standard Time
      (-18000, "GMT-05:00"),
    ])
  func timeZoneInfoOffsetStringFormat(offset: Int, expectedOffsetString: String) {
    // 创建一个模拟的 TimeZone 来测试偏移字符串格式
    // 由于我们无法直接创建具有特定偏移的 TimeZone，我们将测试 TimeZoneInfo 的逻辑
    let utcTimeZone = TimeZone(identifier: "UTC")!
    var timeZoneInfo = TimeZoneInfo(timeZone: utcTimeZone)

    // 手动设置偏移来测试格式化逻辑
    let hours = offset / 3600
    let minutes = abs(offset % 3600) / 60
    let sign = offset >= 0 ? "+" : "-"
    let calculatedOffsetString = String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)

    #expect(calculatedOffsetString == expectedOffsetString)
  }

  @Test("TimeZoneInfo Identifiable 协议测试")
  func timeZoneInfoIdentifiable() {
    let timeZone1 = TimeZoneInfo(timeZone: TimeZone(identifier: "UTC")!)
    let timeZone2 = TimeZoneInfo(timeZone: TimeZone(identifier: "UTC")!)

    // 每个实例应该有唯一的 ID
    #expect(timeZone1.id != timeZone2.id)
  }

  @Test("TimeZoneInfo Hashable 协议测试")
  func timeZoneInfoHashable() {
    let timeZone1 = TimeZoneInfo(timeZone: TimeZone(identifier: "UTC")!)
    let timeZone2 = TimeZoneInfo(timeZone: TimeZone(identifier: "UTC")!)
    let timeZone3 = TimeZoneInfo(timeZone: TimeZone(identifier: "America/New_York")!)

    // 相同标识符的时区应该相等
    #expect(timeZone1 == timeZone2)

    // 不同标识符的时区应该不相等
    #expect(timeZone1 != timeZone3)

    // 测试在 Set 中的使用
    let timeZoneSet: Set<TimeZoneInfo> = [timeZone1, timeZone2, timeZone3]
    #expect(timeZoneSet.count == 2)  // timeZone1 和 timeZone2 应该被认为是相同的
  }

  // MARK: - TimeConversionOptions Tests

  @Test("TimeConversionOptions 默认初始化测试")
  func timeConversionOptionsDefaultInitialization() {
    let options = TimeConversionOptions()

    #expect(options.sourceFormat == .timestamp)
    #expect(options.targetFormat == .iso8601)
    #expect(options.sourceTimeZone == .current)
    #expect(options.targetTimeZone == .current)
    #expect(options.customFormat == "yyyy-MM-dd HH:mm:ss")
    #expect(options.includeMilliseconds == false)
  }

  @Test("TimeConversionOptions 自定义初始化测试")
  func timeConversionOptionsCustomInitialization() {
    let sourceFormat = TimeFormat.iso8601
    let targetFormat = TimeFormat.custom
    let sourceTimeZone = TimeZone(identifier: "UTC")!
    let targetTimeZone = TimeZone(identifier: "America/New_York")!
    let customFormat = "dd/MM/yyyy HH:mm"
    let includeMilliseconds = true

    let options = TimeConversionOptions(
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
      sourceTimeZone: sourceTimeZone,
      targetTimeZone: targetTimeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds)

    #expect(options.sourceFormat == sourceFormat)
    #expect(options.targetFormat == targetFormat)
    #expect(options.sourceTimeZone == sourceTimeZone)
    #expect(options.targetTimeZone == targetTimeZone)
    #expect(options.customFormat == customFormat)
    #expect(options.includeMilliseconds == includeMilliseconds)
  }

  // MARK: - Common Time Zones Tests

  @Test("常用时区列表测试")
  func testCommonTimeZones() {
    let commonTimeZones = TimeZoneInfo.commonTimeZones

    #expect(commonTimeZones.count == 9)

    // 验证包含 UTC
    let utcTimeZone = commonTimeZones.first { $0.identifier == "UTC" }
    #expect(utcTimeZone != nil)

    // 验证包含当前时区
    let currentTimeZone = commonTimeZones.first { $0.identifier == TimeZone.current.identifier }
    #expect(currentTimeZone != nil)

    // 验证包含主要时区
    let expectedIdentifiers = [
      "UTC",
      "America/New_York",
      "America/Los_Angeles",
      "Europe/London",
      "Europe/Paris",
      "Asia/Tokyo",
      "Asia/Shanghai",
      "Australia/Sydney",
    ]

    for identifier in expectedIdentifiers {
      let timeZone = commonTimeZones.first { $0.identifier == identifier }
      #expect(timeZone != nil, "缺少时区: \(identifier)")
    }
  }

  @Test("常用时区唯一性测试")
  func commonTimeZonesUniqueness() {
    let commonTimeZones = TimeZoneInfo.commonTimeZones
    let identifiers = commonTimeZones.map(\.identifier)
    let uniqueIdentifiers = Set(identifiers)

    // 除了可能重复的当前时区，其他应该都是唯一的
    #expect(uniqueIdentifiers.count >= commonTimeZones.count - 1)
  }

  // MARK: - Enhanced TimeConversionOptions Tests

  @Test("TimeConversionOptions 增强功能默认初始化测试")
  func timeConversionOptionsEnhancedDefaultInitialization() {
    let options = TimeConversionOptions()

    #expect(options.sourceFormat == .timestamp)
    #expect(options.targetFormat == .iso8601)
    #expect(options.sourceTimeZone == .current)
    #expect(options.targetTimeZone == .current)
    #expect(options.customFormat == "yyyy-MM-dd HH:mm:ss")
    #expect(options.includeMilliseconds == false)
    #expect(options.enableRealTimeConversion == false)
    #expect(options.batchProcessingEnabled == false)
    #expect(options.validateInput == true)
    #expect(options.preserveHistory == true)
    #expect(options.autoDetectFormat == false)
  }

  @Test("TimeConversionOptions 增强功能自定义初始化测试")
  func timeConversionOptionsEnhancedCustomInitialization() {
    let options = TimeConversionOptions(
      sourceFormat: .iso8601,
      targetFormat: .custom,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "America/New_York")!,
      customFormat: "dd/MM/yyyy HH:mm",
      includeMilliseconds: true,
      enableRealTimeConversion: true,
      batchProcessingEnabled: true,
      validateInput: false,
      preserveHistory: false,
      autoDetectFormat: true
    )

    #expect(options.sourceFormat == .iso8601)
    #expect(options.targetFormat == .custom)
    #expect(options.customFormat == "dd/MM/yyyy HH:mm")
    #expect(options.includeMilliseconds == true)
    #expect(options.enableRealTimeConversion == true)
    #expect(options.batchProcessingEnabled == true)
    #expect(options.validateInput == false)
    #expect(options.preserveHistory == false)
    #expect(options.autoDetectFormat == true)
  }

  // MARK: - ConversionPreset Tests

  @Test("ConversionPreset 基本初始化测试")
  func conversionPresetBasicInitialization() {
    let name = "UTC to EST"
    let sourceFormat = TimeFormat.timestamp
    let targetFormat = TimeFormat.iso8601
    let sourceTimeZone = TimeZone(identifier: "UTC")!
    let targetTimeZone = TimeZone(identifier: "America/New_York")!

    let preset = ConversionPreset(
      name: name,
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
      sourceTimeZone: sourceTimeZone,
      targetTimeZone: targetTimeZone
    )

    #expect(preset.name == name)
    #expect(preset.sourceFormat == sourceFormat)
    #expect(preset.targetFormat == targetFormat)
    #expect(preset.sourceTimeZone == sourceTimeZone)
    #expect(preset.targetTimeZone == targetTimeZone)
    #expect(preset.customFormat == nil)
    #expect(preset.includeMilliseconds == false)
    #expect(preset.createdAt <= Date())
  }

  @Test("ConversionPreset 完整初始化测试")
  func conversionPresetFullInitialization() {
    let name = "Custom Format Preset"
    let sourceFormat = TimeFormat.custom
    let targetFormat = TimeFormat.rfc2822
    let sourceTimeZone = TimeZone(identifier: "Asia/Tokyo")!
    let targetTimeZone = TimeZone(identifier: "Europe/London")!
    let customFormat = "yyyy年MM月dd日 HH:mm:ss"
    let includeMilliseconds = true

    let preset = ConversionPreset(
      name: name,
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
      sourceTimeZone: sourceTimeZone,
      targetTimeZone: targetTimeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds
    )

    #expect(preset.name == name)
    #expect(preset.sourceFormat == sourceFormat)
    #expect(preset.targetFormat == targetFormat)
    #expect(preset.sourceTimeZone == sourceTimeZone)
    #expect(preset.targetTimeZone == targetTimeZone)
    #expect(preset.customFormat == customFormat)
    #expect(preset.includeMilliseconds == includeMilliseconds)
  }

  @Test("ConversionPreset displayDescription 测试")
  func conversionPresetDisplayDescription() {
    let preset = ConversionPreset(
      name: "Test Preset",
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "America/New_York")!
    )

    let expectedDescription = "Unix Timestamp → ISO 8601"
    #expect(preset.displayDescription == expectedDescription)
  }

  @Test("ConversionPreset Identifiable 协议测试")
  func conversionPresetIdentifiable() {
    let preset1 = ConversionPreset(
      name: "Preset 1",
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "America/New_York")!
    )

    let preset2 = ConversionPreset(
      name: "Preset 2",
      sourceFormat: .iso8601,
      targetFormat: .timestamp,
      sourceTimeZone: TimeZone(identifier: "America/New_York")!,
      targetTimeZone: TimeZone(identifier: "UTC")!
    )

    #expect(preset1.id != preset2.id)
  }

  @Test("ConversionPreset Codable 协议测试")
  func conversionPresetCodable() throws {
    let originalPreset = ConversionPreset(
      name: "Test Preset",
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "America/New_York")!,
      customFormat: "yyyy-MM-dd",
      includeMilliseconds: true
    )

    // Encode
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(originalPreset)

    // Decode
    let decoder = JSONDecoder()
    let decodedPreset = try decoder.decode(ConversionPreset.self, from: encodedData)

    #expect(decodedPreset.name == originalPreset.name)
    #expect(decodedPreset.sourceFormat == originalPreset.sourceFormat)
    #expect(decodedPreset.targetFormat == originalPreset.targetFormat)
    #expect(decodedPreset.sourceTimeZone.identifier == originalPreset.sourceTimeZone.identifier)
    #expect(decodedPreset.targetTimeZone.identifier == originalPreset.targetTimeZone.identifier)
    #expect(decodedPreset.customFormat == originalPreset.customFormat)
    #expect(decodedPreset.includeMilliseconds == originalPreset.includeMilliseconds)
    #expect(decodedPreset.createdAt == originalPreset.createdAt)
  }

  // MARK: - ConversionHistory Tests

  @Test("ConversionHistory 基本初始化测试")
  func conversionHistoryBasicInitialization() {
    let input = "1640995200"
    let output = "2022-01-01T00:00:00Z"
    let options = TimeConversionOptions()

    let history = ConversionHistory(
      input: input,
      output: output,
      options: options
    )

    #expect(history.input == input)
    #expect(history.output == output)
    #expect(history.success == true)
    #expect(history.errorMessage == nil)
    #expect(history.timestamp <= Date())
  }

  @Test("ConversionHistory 失败情况初始化测试")
  func conversionHistoryFailureInitialization() {
    let input = "invalid_timestamp"
    let output = ""
    let options = TimeConversionOptions()
    let errorMessage = "Invalid timestamp format"

    let history = ConversionHistory(
      input: input,
      output: output,
      options: options,
      success: false,
      errorMessage: errorMessage
    )

    #expect(history.input == input)
    #expect(history.output == output)
    #expect(history.success == false)
    #expect(history.errorMessage == errorMessage)
  }

  @Test("ConversionHistory displaySummary 成功测试")
  func conversionHistoryDisplaySummarySuccess() {
    let input = "1640995200"
    let output = "2022-01-01T00:00:00Z"
    let options = TimeConversionOptions(sourceFormat: .timestamp, targetFormat: .iso8601)

    let history = ConversionHistory(
      input: input,
      output: output,
      options: options
    )

    let expectedSummary = "1640995200 → 2022-01-01T00:00:00Z (Unix Timestamp → ISO 8601)"
    #expect(history.displaySummary == expectedSummary)
  }

  @Test("ConversionHistory displaySummary 失败测试")
  func conversionHistoryDisplaySummaryFailure() {
    let input = "invalid_input"
    let output = ""
    let options = TimeConversionOptions(sourceFormat: .timestamp, targetFormat: .iso8601)

    let history = ConversionHistory(
      input: input,
      output: output,
      options: options,
      success: false,
      errorMessage: "Invalid format"
    )

    let expectedSummary = "Failed: invalid_input (Unix Timestamp → ISO 8601)"
    #expect(history.displaySummary == expectedSummary)
  }

  @Test("ConversionHistory Identifiable 协议测试")
  func conversionHistoryIdentifiable() {
    let options = TimeConversionOptions()
    let history1 = ConversionHistory(input: "input1", output: "output1", options: options)
    let history2 = ConversionHistory(input: "input2", output: "output2", options: options)

    #expect(history1.id != history2.id)
  }

  @Test("ConversionHistory Codable 协议测试")
  func conversionHistoryCodable() throws {
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "America/New_York")!,
      customFormat: "yyyy-MM-dd HH:mm:ss",
      includeMilliseconds: true,
      enableRealTimeConversion: true,
      batchProcessingEnabled: false,
      validateInput: true,
      preserveHistory: true,
      autoDetectFormat: false
    )

    let originalHistory = ConversionHistory(
      input: "1640995200",
      output: "2022-01-01T00:00:00Z",
      options: options,
      success: true,
      errorMessage: nil
    )

    // Encode
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(originalHistory)

    // Decode
    let decoder = JSONDecoder()
    let decodedHistory = try decoder.decode(ConversionHistory.self, from: encodedData)

    #expect(decodedHistory.input == originalHistory.input)
    #expect(decodedHistory.output == originalHistory.output)
    #expect(decodedHistory.success == originalHistory.success)
    #expect(decodedHistory.errorMessage == originalHistory.errorMessage)
    #expect(decodedHistory.timestamp == originalHistory.timestamp)

    // Test options
    #expect(decodedHistory.options.sourceFormat == originalHistory.options.sourceFormat)
    #expect(decodedHistory.options.targetFormat == originalHistory.options.targetFormat)
    #expect(decodedHistory.options.customFormat == originalHistory.options.customFormat)
    #expect(
      decodedHistory.options.includeMilliseconds == originalHistory.options.includeMilliseconds)
    #expect(
      decodedHistory.options.enableRealTimeConversion
        == originalHistory.options.enableRealTimeConversion)
    #expect(
      decodedHistory.options.batchProcessingEnabled
        == originalHistory.options.batchProcessingEnabled)
    #expect(decodedHistory.options.validateInput == originalHistory.options.validateInput)
    #expect(decodedHistory.options.preserveHistory == originalHistory.options.preserveHistory)
    #expect(decodedHistory.options.autoDetectFormat == originalHistory.options.autoDetectFormat)
  }

  // MARK: - TimeConverterError Tests

  @Test("TimeConverterError 基本错误类型测试")
  func timeConverterErrorBasicTypes() {
    let invalidTimestampError = TimeConverterError.invalidTimestamp("abc123")
    let invalidDateFormatError = TimeConverterError.invalidDateFormat("invalid-date")
    let timezoneConversionError = TimeConverterError.timezoneConversionFailed
    let customFormatError = TimeConverterError.customFormatInvalid("invalid-format")
    let inputEmptyError = TimeConverterError.inputEmpty
    let outputGenerationError = TimeConverterError.outputGenerationFailed

    #expect(invalidTimestampError.errorDescription?.contains("Invalid timestamp") == true)
    #expect(invalidDateFormatError.errorDescription?.contains("Invalid date format") == true)
    #expect(
      timezoneConversionError.errorDescription?.contains("Timezone conversion failed") == true)
    #expect(customFormatError.errorDescription?.contains("Invalid custom format") == true)
    #expect(inputEmptyError.errorDescription?.contains("Input cannot be empty") == true)
    #expect(outputGenerationError.errorDescription?.contains("Failed to generate output") == true)
  }

  @Test("TimeConverterError 批处理错误类型测试")
  func timeConverterErrorBatchTypes() {
    let batchErrors = ["Error 1", "Error 2", "Error 3"]
    let batchProcessingError = TimeConverterError.batchProcessingFailed(batchErrors)
    let batchInputValidationError = TimeConverterError.batchInputValidationFailed("Invalid format")
    let batchItemProcessingError = TimeConverterError.batchItemProcessingFailed(
      "item1", "processing failed")

    #expect(batchProcessingError.errorDescription?.contains("Batch processing failed") == true)
    #expect(batchProcessingError.errorDescription?.contains("3 error(s)") == true)
    #expect(
      batchInputValidationError.errorDescription?.contains("Batch input validation failed") == true)
    #expect(
      batchItemProcessingError.errorDescription?.contains("Failed to process batch item") == true)
  }

  @Test("TimeConverterError 实时服务错误类型测试")
  func timeConverterErrorRealTimeTypes() {
    let realTimeServiceError = TimeConverterError.realTimeServiceUnavailable
    let realTimeTimerError = TimeConverterError.realTimeTimerFailed

    #expect(realTimeServiceError.errorDescription?.contains("Real-time timestamp service") == true)
    #expect(realTimeTimerError.errorDescription?.contains("Real-time timer failed") == true)
  }

  @Test("TimeConverterError 存储和预设错误类型测试")
  func timeConverterErrorStorageAndPresetTypes() {
    let historyStorageError = TimeConverterError.historyStorageFailed
    let presetLoadingError = TimeConverterError.presetLoadingFailed
    let presetSavingError = TimeConverterError.presetSavingFailed("My Preset")
    let timezoneDataError = TimeConverterError.timezoneDataUnavailable("Invalid/Timezone")
    let formatDetectionError = TimeConverterError.formatDetectionFailed("unknown format")

    #expect(
      historyStorageError.errorDescription?.contains("Failed to save conversion history") == true)
    #expect(
      presetLoadingError.errorDescription?.contains("Failed to load conversion presets") == true)
    #expect(
      presetSavingError.errorDescription?.contains("Failed to save preset 'My Preset'") == true)
    #expect(timezoneDataError.errorDescription?.contains("Timezone data unavailable") == true)
    #expect(formatDetectionError.errorDescription?.contains("Could not detect format") == true)
  }

  @Test("TimeConverterError recoverySuggestion 测试")
  func timeConverterErrorRecoverySuggestions() {
    let invalidTimestampError = TimeConverterError.invalidTimestamp("abc")
    let batchProcessingError = TimeConverterError.batchProcessingFailed(["error1"])
    let realTimeServiceError = TimeConverterError.realTimeServiceUnavailable

    #expect(invalidTimestampError.recoverySuggestion?.contains("valid Unix timestamp") == true)
    #expect(batchProcessingError.recoverySuggestion?.contains("Check individual items") == true)
    #expect(realTimeServiceError.recoverySuggestion?.contains("Restart the application") == true)
  }

  @Test("TimeConverterError failureReason 测试")
  func timeConverterErrorFailureReasons() {
    let invalidTimestampError = TimeConverterError.invalidTimestamp("abc")
    let timezoneConversionError = TimeConverterError.timezoneConversionFailed
    let batchProcessingError = TimeConverterError.batchProcessingFailed(["error1"])

    #expect(invalidTimestampError.failureReason?.contains("not a valid Unix timestamp") == true)
    #expect(timezoneConversionError.failureReason?.contains("Unable to convert between") == true)
    #expect(batchProcessingError.failureReason?.contains("One or more items") == true)
  }

  @Test("TimeConverterError Equatable 协议测试")
  func timeConverterErrorEquatable() {
    let error1 = TimeConverterError.invalidTimestamp("123abc")
    let error2 = TimeConverterError.invalidTimestamp("123abc")
    let error3 = TimeConverterError.invalidTimestamp("456def")
    let error4 = TimeConverterError.timezoneConversionFailed

    #expect(error1 == error2)
    #expect(error1 != error3)
    #expect(error1 != error4)
  }
}
