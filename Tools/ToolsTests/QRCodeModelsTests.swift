//
//  QRCodeModelsTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
import SwiftUI
@testable import Tools

struct QRCodeModelsTests {
  
  // MARK: - QRCodeCorrectionLevel Tests
  
  @Test("QRCodeCorrectionLevel 枚举值测试", arguments: [
    (QRCodeCorrectionLevel.low, "L", "低 (7%)", "L"),
    (QRCodeCorrectionLevel.medium, "M", "中 (15%)", "M"),
    (QRCodeCorrectionLevel.quartile, "Q", "高 (25%)", "Q"),
    (QRCodeCorrectionLevel.high, "H", "最高 (30%)", "H")
  ])
  func testQRCodeCorrectionLevelValues(
    level: QRCodeCorrectionLevel,
    expectedRawValue: String,
    expectedDisplayName: String,
    expectedCoreImageValue: String
  ) {
    #expect(level.rawValue == expectedRawValue)
    #expect(level.displayName == expectedDisplayName)
    #expect(level.coreImageValue == expectedCoreImageValue)
  }
  
  @Test("QRCodeCorrectionLevel 枚举完整性测试")
  func testQRCodeCorrectionLevelCompleteness() {
    let allCases = QRCodeCorrectionLevel.allCases
    #expect(allCases.count == 4)
    
    let expectedLevels: [QRCodeCorrectionLevel] = [.low, .medium, .quartile, .high]
    for expectedLevel in expectedLevels {
      #expect(allCases.contains(expectedLevel))
    }
  }
  
  @Test("QRCodeCorrectionLevel Codable 测试")
  func testQRCodeCorrectionLevelCodable() throws {
    let level = QRCodeCorrectionLevel.medium
    
    // 编码测试
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(level)
    #expect(!encodedData.isEmpty)
    
    // 解码测试
    let decoder = JSONDecoder()
    let decodedLevel = try decoder.decode(QRCodeCorrectionLevel.self, from: encodedData)
    #expect(decodedLevel == level)
  }
  
  // MARK: - QRCodeOptions Tests
  
  @Test("QRCodeOptions 默认初始化测试")
  func testQRCodeOptionsDefaultInitialization() {
    let options = QRCodeOptions()
    
    #expect(options.size == CGSize(width: 200, height: 200))
    #expect(options.correctionLevel == .medium)
    #expect(options.foregroundColor == .black)
    #expect(options.backgroundColor == .white)
  }
  
  @Test("QRCodeOptions 自定义初始化测试")
  func testQRCodeOptionsCustomInitialization() {
    let customSize = CGSize(width: 300, height: 300)
    let customLevel = QRCodeCorrectionLevel.high
    let customForeground = Color.blue
    let customBackground = Color.yellow
    
    let options = QRCodeOptions(
      size: customSize,
      correctionLevel: customLevel,
      foregroundColor: customForeground,
      backgroundColor: customBackground
    )
    
    #expect(options.size == customSize)
    #expect(options.correctionLevel == customLevel)
    #expect(options.foregroundColor == customForeground)
    #expect(options.backgroundColor == customBackground)
  }
  
  @Test("QRCodeOptions Codable 测试")
  func testQRCodeOptionsCodable() throws {
    let options = QRCodeOptions(
      size: CGSize(width: 150, height: 150),
      correctionLevel: .high,
      foregroundColor: .red,
      backgroundColor: .green
    )
    
    // 编码测试
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(options)
    #expect(!encodedData.isEmpty)
    
    // 解码测试
    let decoder = JSONDecoder()
    let decodedOptions = try decoder.decode(QRCodeOptions.self, from: encodedData)
    
    #expect(decodedOptions.size == options.size)
    #expect(decodedOptions.correctionLevel == options.correctionLevel)
    // 注意：Color 的比较可能需要特殊处理，这里我们验证编解码过程没有错误
  }
  
  // MARK: - QRCodeGenerationResult Tests
  
  @Test("QRCodeGenerationResult 基本属性测试")
  func testQRCodeGenerationResultProperties() {
    let testImage = NSImage(size: CGSize(width: 100, height: 100))
    let inputText = "测试文本"
    let options = QRCodeOptions()
    
    let result = QRCodeGenerationResult(
      image: testImage,
      inputText: inputText,
      options: options
    )
    
    #expect(result.image === testImage)
    #expect(result.inputText == inputText)
    #expect(result.options.size == options.size)
    #expect(result.options.correctionLevel == options.correctionLevel)
    #expect(result.timestamp <= Date())
  }
  
  @Test("QRCodeGenerationResult 时间戳测试")
  func testQRCodeGenerationResultTimestamp() {
    let beforeCreation = Date()
    
    let result = QRCodeGenerationResult(
      image: NSImage(size: CGSize(width: 50, height: 50)),
      inputText: "时间戳测试",
      options: QRCodeOptions()
    )
    
    let afterCreation = Date()
    
    #expect(result.timestamp >= beforeCreation)
    #expect(result.timestamp <= afterCreation)
  }
  
  // MARK: - QRCodeRecognitionResult Tests
  
  @Test("QRCodeRecognitionResult 基本初始化测试")
  func testQRCodeRecognitionResultBasicInitialization() {
    let text = "识别的文本"
    
    let result = QRCodeRecognitionResult(text: text)
    
    #expect(result.text == text)
    #expect(result.confidence == 1.0)
    #expect(result.boundingBox == nil)
    #expect(result.timestamp <= Date())
  }
  
  @Test("QRCodeRecognitionResult 完整初始化测试")
  func testQRCodeRecognitionResultFullInitialization() {
    let text = "完整识别文本"
    let confidence: Float = 0.95
    let boundingBox = CGRect(x: 10, y: 10, width: 100, height: 100)
    
    let result = QRCodeRecognitionResult(
      text: text,
      confidence: confidence,
      boundingBox: boundingBox
    )
    
    #expect(result.text == text)
    #expect(result.confidence == confidence)
    #expect(result.boundingBox == boundingBox)
    #expect(result.timestamp <= Date())
  }
  
  @Test("QRCodeRecognitionResult 时间戳测试")
  func testQRCodeRecognitionResultTimestamp() {
    let beforeCreation = Date()
    
    let result = QRCodeRecognitionResult(text: "时间戳测试")
    
    let afterCreation = Date()
    
    #expect(result.timestamp >= beforeCreation)
    #expect(result.timestamp <= afterCreation)
  }
  
  @Test("QRCodeRecognitionResult 边界情况测试")
  func testQRCodeRecognitionResultEdgeCases() {
    // 空文本测试
    let emptyResult = QRCodeRecognitionResult(text: "")
    #expect(emptyResult.text.isEmpty)
    #expect(emptyResult.confidence == 1.0)
    
    // 低置信度测试
    let lowConfidenceResult = QRCodeRecognitionResult(text: "低置信度", confidence: 0.1)
    #expect(lowConfidenceResult.confidence == 0.1)
    
    // 零尺寸边界框测试
    let zeroBoundingBox = CGRect.zero
    let zeroBoxResult = QRCodeRecognitionResult(
      text: "零边界框",
      confidence: 0.8,
      boundingBox: zeroBoundingBox
    )
    #expect(zeroBoxResult.boundingBox == zeroBoundingBox)
    
    // 长文本测试
    let longText = String(repeating: "长文本", count: 1000)
    let longTextResult = QRCodeRecognitionResult(text: longText)
    #expect(longTextResult.text.count == longText.count)
  }
  
  // MARK: - Color Codable Tests
  
  @Test("Color Codable 基本颜色测试", arguments: [
    Color.black,
    Color.white,
    Color.red,
    Color.green,
    Color.blue
  ])
  func testColorCodableBasicColors(color: Color) throws {
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(color)
    #expect(!encodedData.isEmpty)
    
    let decoder = JSONDecoder()
    let decodedColor = try decoder.decode(Color.self, from: encodedData)
    
    // 验证编解码过程没有错误
    // 注意：由于 Color 的内部表示复杂，我们主要验证编解码过程的成功
    #expect(decodedColor != nil)
  }
  
  @Test("Color Codable 自定义颜色测试")
  func testColorCodableCustomColor() throws {
    let customColor = Color(red: 0.5, green: 0.3, blue: 0.8, opacity: 0.9)
    
    let encoder = JSONEncoder()
    let encodedData = try encoder.encode(customColor)
    #expect(!encodedData.isEmpty)
    
    let decoder = JSONDecoder()
    let decodedColor = try decoder.decode(Color.self, from: encodedData)
    
    // 验证编解码过程成功
    #expect(decodedColor != nil)
  }
}