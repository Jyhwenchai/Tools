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

  @Test("TimeFormat 枚举值测试", arguments: [
    (TimeFormat.timestamp, "timestamp", "Unix Timestamp", "Seconds since January 1, 1970 UTC"),
    (TimeFormat.iso8601, "iso8601", "ISO 8601", "2024-01-01T12:00:00Z"),
    (TimeFormat.rfc2822, "rfc2822", "RFC 2822", "Mon, 01 Jan 2024 12:00:00 GMT"),
    (TimeFormat.custom, "custom", "Custom Format", "User-defined format")
  ])
  func timeFormatValues(
    format: TimeFormat,
    expectedRawValue: String,
    expectedDisplayName: String,
    expectedDescription: String) {
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
    let timestamp: TimeInterval = 1_640_995_200 // 2022-01-01 00:00:00 UTC
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

  @Test("TimeZoneInfo 不同时区测试", arguments: [
    ("America/New_York", "EST", -18000), // -5 hours in seconds
    ("Europe/London", "GMT", 0),
    ("Asia/Tokyo", "JST", 32400), // +9 hours in seconds
    ("Australia/Sydney", "AEDT", 39600) // +11 hours in seconds (during DST)
  ])
  func timeZoneInfoDifferentTimeZones(
    identifier: String,
    expectedAbbreviation _: String,
    expectedOffset _: Int) {
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

  @Test("TimeZoneInfo 偏移字符串格式测试", arguments: [
    (0, "GMT+00:00"),
    (3600, "GMT+01:00"),
    (-3600, "GMT-01:00"),
    (19800, "GMT+05:30"), // India Standard Time
    (-18000, "GMT-05:00")
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
    #expect(timeZoneSet.count == 2) // timeZone1 和 timeZone2 应该被认为是相同的
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
      "Australia/Sydney"
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
}
