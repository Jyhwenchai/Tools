import Testing
import Foundation
import AppKit
import SwiftUI
@testable import Tools

struct QRCodeServiceTests {
  
  // MARK: - Test Properties
  
  let service = QRCodeService()
  let testText = "Hello, QR Code!"
  let longText = String(repeating: "A", count: 1001)
  let veryLongText = String(repeating: "B", count: 3000)
  
  // MARK: - QR Code Generation Tests
  
  @Test("QR码生成 - 基本功能测试")
  func testBasicQRCodeGeneration() throws {
    let options = QRCodeOptions()
    let result = try service.generateQRCode(from: testText, options: options)
    
    #expect(result.inputText == testText)
    #expect(result.options.size == options.size)
    #expect(result.image.size == options.size)
  }
  
  @Test("QR码生成 - 自定义尺寸测试", arguments: [
    CGSize(width: 100, height: 100),
    CGSize(width: 200, height: 200),
    CGSize(width: 300, height: 300),
    CGSize(width: 500, height: 500)
  ])
  func testCustomSizeGeneration(size: CGSize) throws {
    let options = QRCodeOptions(size: size)
    let result = try service.generateQRCode(from: testText, options: options)
    
    #expect(result.image.size.width == size.width)
    #expect(result.image.size.height == size.height)
  }
  
  @Test("QR码生成 - 纠错级别测试", arguments: QRCodeCorrectionLevel.allCases)
  func testCorrectionLevels(level: QRCodeCorrectionLevel) throws {
    let options = QRCodeOptions(correctionLevel: level)
    let result = try service.generateQRCode(from: testText, options: options)
    
    #expect(result.options.correctionLevel == level)
    #expect(!result.image.size.equalTo(.zero))
  }
  
  @Test("QR码生成 - 颜色自定义测试")
  func testCustomColors() throws {
    let options = QRCodeOptions(
      foregroundColor: .red,
      backgroundColor: .blue
    )
    let result = try service.generateQRCode(from: testText, options: options)
    
    #expect(result.options.foregroundColor == .red)
    #expect(result.options.backgroundColor == .blue)
  }
  
  @Test("QR码生成 - 空输入错误测试")
  func testEmptyInputError() {
    let options = QRCodeOptions()
    
    do {
      _ = try service.generateQRCode(from: "", options: options)
      #expect(Bool(false), "应该抛出错误")
    } catch let error as QRCodeError {
      switch error {
      case .emptyInput:
        #expect(Bool(true)) // 期望的错误类型
      default:
        #expect(Bool(false), "错误类型不匹配")
      }
    } catch {
      #expect(Bool(false), "意外的错误类型")
    }
  }
  
  @Test("QR码生成 - 长文本测试")
  func testLongTextGeneration() throws {
    let options = QRCodeOptions(
      size: CGSize(width: 300, height: 300),
      correctionLevel: .high
    )
    let result = try service.generateQRCode(from: longText, options: options)
    
    #expect(result.inputText == longText)
    #expect(!result.image.size.equalTo(.zero))
  }
  
  // MARK: - QR Code Recognition Tests
  
  @Test("QR码识别 - 基本功能测试")
  func testBasicQRCodeRecognition() async throws {
    // 首先生成一个QR码
    let options = QRCodeOptions(size: CGSize(width: 200, height: 200))
    let generationResult = try service.generateQRCode(from: testText, options: options)
    
    // 然后识别它
    let recognitionResults = try await service.recognizeQRCode(from: generationResult.image)
    
    #expect(!recognitionResults.isEmpty)
    #expect(recognitionResults.first?.text == testText)
  }
  
  @Test("QR码识别 - 多个QR码测试")
  func testMultipleQRCodeRecognition() async throws {
    // 生成一个QR码进行测试
    let options = QRCodeOptions(size: CGSize(width: 300, height: 300))
    let result = try service.generateQRCode(from: "Test Multiple", options: options)
    
    let recognitionResults = try await service.recognizeQRCode(from: result.image)
    
    // 至少应该识别到一个QR码
    #expect(!recognitionResults.isEmpty)
    #expect(recognitionResults.contains { $0.text == "Test Multiple" })
  }
  
  @Test("QR码识别 - 无效图像测试")
  func testInvalidImageRecognition() async {
    // 创建一个空白图像
    let image = NSImage(size: CGSize(width: 100, height: 100))
    
    do {
      let results = try await service.recognizeQRCode(from: image)
      // 空白图像应该返回空结果，不应该抛出错误
      #expect(results.isEmpty)
    } catch {
      // 如果抛出错误，应该是识别相关的错误
      #expect(error is QRCodeError)
    }
  }
  
  // MARK: - Validation Tests
  
  @Test("文本验证 - 有效文本测试", arguments: [
    "Hello",
    "https://example.com",
    "短文本",
    String(repeating: "A", count: 100)
  ])
  func testValidTextValidation(text: String) {
    let result = service.validateTextForQRCode(text)
    #expect(result.isValid == true)
  }
  
  @Test("文本验证 - 空文本测试")
  func testEmptyTextValidation() {
    let result = service.validateTextForQRCode("")
    #expect(result.isValid == false)
    #expect(result.suggestion != nil)
  }
  
  @Test("文本验证 - 过长文本测试")
  func testTooLongTextValidation() {
    let result = service.validateTextForQRCode(veryLongText)
    #expect(result.isValid == false)
    #expect(result.suggestion?.contains("过长") == true)
  }
  
  @Test("文本验证 - 长文本建议测试")
  func testLongTextSuggestion() {
    let result = service.validateTextForQRCode(longText)
    #expect(result.isValid == true)
    #expect(result.suggestion != nil)
    if let suggestion = result.suggestion {
      #expect(suggestion.contains("建议使用高纠错级别以确保识别准确性"))
    }
  }
  
  // MARK: - Utility Tests
  
  @Test("推荐尺寸测试", arguments: [
    (25, CGSize(width: 150, height: 150)),
    (100, CGSize(width: 200, height: 200)),
    (300, CGSize(width: 250, height: 250)),
    (1000, CGSize(width: 300, height: 300))
  ])
  func testRecommendedSize(textLength: Int, expectedSize: CGSize) {
    let size = service.getRecommendedSize(for: textLength)
    #expect(size == expectedSize)
  }
  
  // MARK: - Model Tests
  
  @Test("QRCodeOptions 默认值测试")
  func testQRCodeOptionsDefaults() {
    let options = QRCodeOptions()
    
    #expect(options.size == CGSize(width: 200, height: 200))
    #expect(options.correctionLevel == .medium)
    #expect(options.foregroundColor == .black)
    #expect(options.backgroundColor == .white)
  }
  
  @Test("QRCodeCorrectionLevel 显示名称测试", arguments: [
    (QRCodeCorrectionLevel.low, "低 (7%)"),
    (QRCodeCorrectionLevel.medium, "中 (15%)"),
    (QRCodeCorrectionLevel.quartile, "高 (25%)"),
    (QRCodeCorrectionLevel.high, "最高 (30%)")
  ])
  func testCorrectionLevelDisplayNames(level: QRCodeCorrectionLevel, expectedName: String) {
    #expect(level.displayName == expectedName)
  }
  
  @Test("QRCodeCorrectionLevel Core Image值测试", arguments: [
    (QRCodeCorrectionLevel.low, "L"),
    (QRCodeCorrectionLevel.medium, "M"),
    (QRCodeCorrectionLevel.quartile, "Q"),
    (QRCodeCorrectionLevel.high, "H")
  ])
  func testCorrectionLevelCoreImageValues(level: QRCodeCorrectionLevel, expectedValue: String) {
    #expect(level.coreImageValue == expectedValue)
  }
  
  @Test("QRCodeGenerationResult 初始化测试")
  func testQRCodeGenerationResult() throws {
    let options = QRCodeOptions()
    let generationResult = try service.generateQRCode(from: testText, options: options)
    let result = QRCodeGenerationResult(
      image: generationResult.image,
      inputText: testText,
      options: options
    )
    
    #expect(result.inputText == testText)
    #expect(result.options.size == options.size)
    #expect(result.timestamp <= Date())
  }
  
  @Test("QRCodeRecognitionResult 初始化测试")
  func testQRCodeRecognitionResult() {
    let result = QRCodeRecognitionResult(
      text: testText,
      confidence: 0.95,
      boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100)
    )
    
    #expect(result.text == testText)
    #expect(result.confidence == 0.95)
    #expect(result.boundingBox != nil)
    #expect(result.timestamp <= Date())
  }
  
  // MARK: - Error Tests
  
  @Test("QRCodeError 错误描述测试")
  func testQRCodeErrorDescriptions() {
    let errors: [QRCodeError] = [
      .emptyInput,
      .generationFailed("测试错误"),
      .recognitionFailed("识别错误"),
      .invalidImage,
      .unsupportedFormat
    ]
    
    for error in errors {
      #expect(error.errorDescription != nil)
      #expect(error.recoverySuggestion != nil)
    }
  }
  
  // MARK: - Performance Tests
  
  @Test("QR码生成性能测试")
  func testQRCodeGenerationPerformance() throws {
    let options = QRCodeOptions(size: CGSize(width: 500, height: 500))
    
    // 生成多个QR码测试性能
    for i in 0..<10 {
      let text = "Performance Test \(i)"
      let result = try service.generateQRCode(from: text, options: options)
      #expect(!result.image.size.equalTo(.zero))
    }
  }
  
  @Test("大尺寸QR码生成测试")
  func testLargeSizeQRCodeGeneration() throws {
    let options = QRCodeOptions(size: CGSize(width: 1000, height: 1000))
    let result = try service.generateQRCode(from: longText, options: options)
    
    #expect(result.image.size.width == 1000)
    #expect(result.image.size.height == 1000)
  }
}

// MARK: - Test Extensions

// CGSize already conforms to Equatable in CoreGraphics, so we don't need to extend it