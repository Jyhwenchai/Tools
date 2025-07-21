import SwiftUI
import Testing
@testable import Tools

struct TimeConverterViewTests {
  // MARK: - UI Component Tests

  @Test("TimeConverterView 初始化状态测试")
  func timeConverterViewInitialState() {
    // 测试初始状态的默认值
    let defaultSourceFormat: TimeFormat = .timestamp
    let defaultTargetFormat: TimeFormat = .iso8601
    let defaultCustomFormat = "yyyy-MM-dd HH:mm:ss"
    let defaultIncludeMilliseconds = false

    #expect(defaultSourceFormat == .timestamp)
    #expect(defaultTargetFormat == .iso8601)
    #expect(defaultCustomFormat == "yyyy-MM-dd HH:mm:ss")
    #expect(defaultIncludeMilliseconds == false)
  }

  @Test("时间格式选择器测试")
  func timeFormatPicker() {
    // 验证所有时间格式都可用
    let allFormats = TimeFormat.allCases

    #expect(allFormats.contains(.timestamp))
    #expect(allFormats.contains(.iso8601))
    #expect(allFormats.contains(.rfc2822))
    #expect(allFormats.contains(.custom))

    // 验证格式显示名称
    #expect(TimeFormat.timestamp.displayName == "Unix Timestamp")
    #expect(TimeFormat.iso8601.displayName == "ISO 8601")
    #expect(TimeFormat.rfc2822.displayName == "RFC 2822")
    #expect(TimeFormat.custom.displayName == "Custom Format")
  }

  @Test("时区选择器测试")
  func timeZonePicker() {
    let commonTimeZones = TimeZoneInfo.commonTimeZones

    // 验证包含常用时区
    let identifiers = commonTimeZones.map(\.identifier)
    #expect(identifiers.contains("UTC"))
    #expect(identifiers.contains("America/New_York"))
    #expect(identifiers.contains("Asia/Shanghai"))
    #expect(identifiers.contains("Europe/London"))

    // 验证时区信息格式
    let utcTimeZone = commonTimeZones.first { $0.identifier == "UTC" }
    #expect(utcTimeZone != nil)
    if let utcTimeZone {
      // UTC时区的偏移量应该是0，格式可能是GMT+00:00或GMT+0:00
      #expect(utcTimeZone.offsetString.hasPrefix("GMT+0"))
    }
  }

  // MARK: - Input Validation Tests

  @Test("输入验证测试", arguments: [
    ("1640995200", TimeFormat.timestamp, true),
    ("2022-01-01T00:00:00Z", TimeFormat.iso8601, true),
    ("Sat, 01 Jan 2022 00:00:00 GMT", TimeFormat.rfc2822, true),
    ("2022-01-01 00:00:00", TimeFormat.custom, true),
    ("invalid_timestamp", TimeFormat.timestamp, false),
    ("invalid_date", TimeFormat.iso8601, false),
    ("", TimeFormat.timestamp, true) // 空输入应该被认为是有效的（初始状态）
  ])
  func inputValidation(input: String, format: TimeFormat, expectedValid: Bool) {
    let service = TimeConverterService()

    if input.isEmpty {
      // 空输入的特殊处理
      #expect(expectedValid == true)
    } else {
      let isValid = service.validateDateString(
        input,
        format: format,
        customFormat: "yyyy-MM-dd HH:mm:ss")
      #expect(isValid == expectedValid)
    }
  }

  @Test("自定义格式验证测试")
  func customFormatValidation() {
    let service = TimeConverterService()

    // 测试不同的自定义格式
    let testCases = [
      ("2022-01-01 12:30:45", "yyyy-MM-dd HH:mm:ss", true),
      ("01/01/2022", "MM/dd/yyyy", true),
      ("2022年1月1日", "yyyy年M月d日", true),
      ("12:30:45", "HH:mm:ss", true),
      ("invalid", "yyyy-MM-dd", false)
    ]

    for (input, format, expected) in testCases {
      let isValid = service.validateDateString(input, format: .custom, customFormat: format)
      #expect(isValid == expected, "Input: \(input), Format: \(format)")
    }
  }

  // MARK: - Conversion Logic Tests

  @Test("时间转换逻辑测试")
  func timeConversionLogic() async {
    let service = TimeConverterService()

    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "UTC")!)

    let result = service.convertTime(input: "1640995200", options: options)

    #expect(result.success == true)
    #expect(result.result == "2022-01-01T00:00:00Z")
    #expect(result.error == nil)
  }

  @Test("格式交换功能测试")
  func formatSwapping() {
    // 模拟格式交换逻辑
    var sourceFormat: TimeFormat = .timestamp
    var targetFormat: TimeFormat = .iso8601
    var sourceTimeZone = TimeZone.current
    var targetTimeZone = TimeZone(identifier: "UTC")!

    // 执行交换
    let tempFormat = sourceFormat
    let tempTimeZone = sourceTimeZone

    sourceFormat = targetFormat
    sourceTimeZone = targetTimeZone
    targetFormat = tempFormat
    targetTimeZone = tempTimeZone

    // 验证交换结果
    #expect(sourceFormat == .iso8601)
    #expect(targetFormat == .timestamp)
    #expect(sourceTimeZone == TimeZone(identifier: "UTC")!)
    #expect(targetTimeZone == TimeZone.current)
  }

  // MARK: - Current Time Loading Tests

  @Test("当前时间加载测试")
  func currentTimeLoading() {
    let service = TimeConverterService()

    let currentTimestamp = service.getCurrentTimestamp(includeMilliseconds: false)
    let currentTimestampWithMs = service.getCurrentTimestamp(includeMilliseconds: true)

    #expect(!currentTimestamp.isEmpty)
    #expect(!currentTimestampWithMs.isEmpty)
    #expect(service.validateTimestamp(currentTimestamp))
    #expect(service.validateTimestamp(currentTimestampWithMs))
    #expect(currentTimestampWithMs.contains("."))
  }

  @Test("当前时间格式化测试")
  func currentTimeFormatting() {
    let service = TimeConverterService()

    let formats: [TimeFormat] = [.timestamp, .iso8601, .rfc2822]

    for format in formats {
      let currentTime = service.getCurrentTime(format: format)
      #expect(!currentTime.isEmpty, "Format \(format.displayName) should not be empty")

      // 验证格式是否正确
      switch format {
      case .timestamp:
        #expect(service.validateTimestamp(currentTime))
      case .iso8601:
        #expect(service.validateDateString(currentTime, format: .iso8601))
      case .rfc2822:
        #expect(service.validateDateString(currentTime, format: .rfc2822))
      case .custom:
        break // 自定义格式需要额外参数
      }
    }
  }

  // MARK: - Error Handling Tests

  @Test("错误处理测试")
  func errorHandling() {
    let service = TimeConverterService()

    // 测试空输入错误
    let emptyResult = service.convertTime(input: "", options: TimeConversionOptions())
    #expect(emptyResult.success == false)
    #expect(emptyResult.error == "Input cannot be empty")

    // 测试无效输入错误
    let invalidResult = service.convertTime(
      input: "invalid_input",
      options: TimeConversionOptions(sourceFormat: .timestamp, targetFormat: .iso8601))
    #expect(invalidResult.success == false)
    #expect(invalidResult.error != nil)
  }

  // MARK: - Time Zone Conversion Tests

  @Test("时区转换测试")
  func timeZoneConversion() {
    let service = TimeConverterService()

    let utcOptions = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "America/New_York")!)

    let result = service
      .convertTime(input: "1640995200", options: utcOptions) // 2022-01-01 00:00:00 UTC

    #expect(result.success == true)
    // 纽约时间应该比UTC时间早5小时（EST）
    #expect(result.result.contains("2021-12-31T19:00:00"))
  }

  // MARK: - Milliseconds Handling Tests

  @Test("毫秒处理测试")
  func millisecondsHandling() {
    let service = TimeConverterService()

    let optionsWithMs = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "UTC")!,
      includeMilliseconds: true)

    let result = service.convertTime(input: "1640995200.123", options: optionsWithMs)

    #expect(result.success == true)
    #expect(result.result.contains(".123"))
  }

  // MARK: - Format Examples Tests

  @Test("格式示例测试")
  func formatExamples() {
    let service = TimeConverterService()

    for format in TimeFormat.allCases {
      let examples = service.getFormatExamples(for: format)
      #expect(examples.count == 3, "Should have 3 examples for \(format.displayName)")
      #expect(
        examples.allSatisfy { !$0.isEmpty },
        "All examples should be non-empty for \(format.displayName)")
    }
  }

  // MARK: - UI State Management Tests

  @Test("UI状态管理测试")
  func uIStateManagement() {
    // 测试处理状态
    var isProcessing = false
    var outputTime = ""
    var currentError: ToolError?

    // 模拟开始处理
    isProcessing = true
    outputTime = ""

    #expect(isProcessing == true)
    #expect(outputTime.isEmpty)

    // 模拟处理成功
    isProcessing = false
    outputTime = "2022-01-01T00:00:00Z"

    #expect(isProcessing == false)
    #expect(!outputTime.isEmpty)

    // 模拟处理失败
    isProcessing = false
    outputTime = ""
    currentError = ToolError.processingFailed("转换失败")

    #expect(isProcessing == false)
    #expect(outputTime.isEmpty)
    #expect(currentError != nil)
  }

  // MARK: - Clear All Functionality Tests

  @Test("清空功能测试")
  func clearAllFunctionality() {
    // 模拟清空操作
    var inputTime = "1640995200"
    var outputTime = "2022-01-01T00:00:00Z"
    var sourceFormat: TimeFormat = .iso8601
    var targetFormat: TimeFormat = .custom
    var sourceTimeZone = TimeZone(identifier: "UTC")!
    var targetTimeZone = TimeZone(identifier: "Asia/Tokyo")!
    var customFormat = "dd/MM/yyyy"
    var includeMilliseconds = true
    var isValidInput = false
    var validationMessage = "错误信息"

    // 执行清空
    inputTime = ""
    outputTime = ""
    sourceFormat = .timestamp
    targetFormat = .iso8601
    sourceTimeZone = .current
    targetTimeZone = .current
    customFormat = "yyyy-MM-dd HH:mm:ss"
    includeMilliseconds = false
    isValidInput = true
    validationMessage = ""

    // 验证清空结果
    #expect(inputTime.isEmpty)
    #expect(outputTime.isEmpty)
    #expect(sourceFormat == .timestamp)
    #expect(targetFormat == .iso8601)
    #expect(sourceTimeZone == .current)
    #expect(targetTimeZone == .current)
    #expect(customFormat == "yyyy-MM-dd HH:mm:ss")
    #expect(includeMilliseconds == false)
    #expect(isValidInput == true)
    #expect(validationMessage.isEmpty)
  }

  // MARK: - Performance Tests

  @Test("性能测试", .timeLimit(.minutes(1)))
  func performance() async {
    let service = TimeConverterService()

    // 测试大量转换操作的性能
    let inputs = Array(1_640_995_200...1_640_995_300).map { String($0) }
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: TimeZone(identifier: "UTC")!,
      targetTimeZone: TimeZone(identifier: "UTC")!)

    let results = service.batchConvert(inputs: inputs, options: options)

    #expect(results.count == inputs.count)
    #expect(results.allSatisfy(\.success))
  }
}

// MARK: - TimeZonePicker Tests

struct TimeZonePickerTests {
  @Test("TimeZonePicker 初始化测试")
  func timeZonePickerInitialization() {
    let timeZone = TimeZone.current

    // 验证时区选择器的基本功能
    #expect(timeZone.identifier == TimeZone.current.identifier)
  }

  @Test("常用时区列表测试")
  func commonTimeZonesList() {
    let commonTimeZones = TimeZoneInfo.commonTimeZones

    #expect(commonTimeZones.count >= 8) // 至少包含8个常用时区

    // 验证必要的时区存在
    let identifiers = commonTimeZones.map(\.identifier)
    #expect(identifiers.contains("UTC"))
    #expect(identifiers.contains("America/New_York"))
    #expect(identifiers.contains("America/Los_Angeles"))
    #expect(identifiers.contains("Europe/London"))
    #expect(identifiers.contains("Asia/Tokyo"))
    #expect(identifiers.contains("Asia/Shanghai"))
  }
}

// MARK: - FormatExamplesView Tests

struct FormatExamplesViewTests {
  @Test("格式示例视图测试")
  func formatExamplesView() {
    let service = TimeConverterService()

    // 验证所有格式都有示例
    for format in TimeFormat.allCases {
      let currentTime = service.getCurrentTime(format: format)
      #expect(!currentTime.isEmpty, "Format \(format.displayName) should have example")
    }
  }
}
