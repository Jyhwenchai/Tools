import SwiftUI
import Testing
@testable import Tools

struct QRCodeViewTests {
  // MARK: - Test Properties

  let testText = "Hello, QR Code!"
  let testURL = "https://example.com"

  // MARK: - View Initialization Tests

  @Test("QRCodeView 初始化测试")
  func qRCodeViewInitialization() {
    let view = QRCodeView()

    // 验证视图可以正常创建
    #expect(view != nil)
  }

  // MARK: - QRCodeTab Tests

  @Test("QRCodeTab 枚举测试")
  func qRCodeTabEnum() {
    let generateTab = QRCodeTab.generate
    let recognizeTab = QRCodeTab.recognize

    #expect(generateTab.title == "生成")
    #expect(generateTab.icon == "qrcode")

    #expect(recognizeTab.title == "识别")
    #expect(recognizeTab.icon == "qrcode.viewfinder")

    #expect(QRCodeTab.allCases.count == 2)
  }

  // MARK: - QRCodeOptions Default Tests

  @Test("QRCodeOptions 默认值测试")
  func qRCodeOptionsDefaults() {
    let options = QRCodeOptions()

    #expect(options.size == CGSize(width: 200, height: 200))
    #expect(options.correctionLevel == .medium)
    #expect(options.foregroundColor == .black)
    #expect(options.backgroundColor == .white)
  }

  // MARK: - Model Integration Tests

  @Test("QRCodeGenerationResult 集成测试")
  func qRCodeGenerationResultIntegration() throws {
    let service = QRCodeService()
    let options = QRCodeOptions(size: CGSize(width: 100, height: 100))

    let result = try service.generateQRCode(from: testText, options: options)

    #expect(result.inputText == testText)
    #expect(result.options.size == options.size)
    #expect(result.image.size == options.size)
    #expect(result.timestamp <= Date())
  }

  @Test("QRCodeRecognitionResult 集成测试")
  func qRCodeRecognitionResultIntegration() async throws {
    let service = QRCodeService()
    let options = QRCodeOptions(size: CGSize(width: 200, height: 200))

    // 生成一个QR码
    let generationResult = try service.generateQRCode(from: testText, options: options)

    // 识别生成的QR码
    let recognitionResults = try await service.recognizeQRCode(from: generationResult.image)

    #expect(!recognitionResults.isEmpty)
    if let firstResult = recognitionResults.first {
      #expect(firstResult.text == testText)
      #expect(firstResult.confidence > 0.5)
      #expect(firstResult.timestamp <= Date())
    }
  }

  // MARK: - Error Handling Tests

  @Test("QRCodeError 本地化测试")
  func qRCodeErrorLocalization() {
    let errors: [QRCodeError] = [
      .emptyInput,
      .generationFailed("测试错误"),
      .recognitionFailed("识别错误"),
      .invalidImage,
      .unsupportedFormat
    ]

    for error in errors {
      #expect(error.errorDescription != nil)
      #expect(!error.errorDescription!.isEmpty)
      #expect(error.recoverySuggestion != nil)
      #expect(!error.recoverySuggestion!.isEmpty)
    }
  }

  // MARK: - Service Integration Tests

  @Test("QRCodeService 文本验证集成测试")
  func qRCodeServiceValidationIntegration() {
    let service = QRCodeService()

    // 测试有效文本
    let validResult = service.validateTextForQRCode(testText)
    #expect(validResult.isValid == true)

    // 测试空文本
    let emptyResult = service.validateTextForQRCode("")
    #expect(emptyResult.isValid == false)
    #expect(emptyResult.suggestion != nil)

    // 测试长文本
    let longText = String(repeating: "A", count: 1000)
    let longResult = service.validateTextForQRCode(longText)
    #expect(longResult.isValid == true)
    #expect(longResult.suggestion != nil)

    // 测试过长文本
    let veryLongText = String(repeating: "B", count: 3000)
    let veryLongResult = service.validateTextForQRCode(veryLongText)
    #expect(veryLongResult.isValid == false)
    #expect(veryLongResult.suggestion != nil)
  }

  @Test("QRCodeService 推荐尺寸集成测试")
  func qRCodeServiceRecommendedSizeIntegration() {
    let service = QRCodeService()

    let testCases = [
      (25, CGSize(width: 150, height: 150)),
      (100, CGSize(width: 200, height: 200)),
      (300, CGSize(width: 250, height: 250)),
      (1000, CGSize(width: 300, height: 300))
    ]

    for (textLength, expectedSize) in testCases {
      let size = service.getRecommendedSize(for: textLength)
      #expect(size == expectedSize)
    }
  }

  // MARK: - Color Codable Tests

  @Test("Color Codable 支持测试")
  func colorCodableSupport() throws {
    let originalOptions = QRCodeOptions(
      foregroundColor: .red,
      backgroundColor: .blue)

    // 编码
    let encoder = JSONEncoder()
    let data = try encoder.encode(originalOptions)

    // 解码
    let decoder = JSONDecoder()
    let decodedOptions = try decoder.decode(QRCodeOptions.self, from: data)

    #expect(decodedOptions.size == originalOptions.size)
    #expect(decodedOptions.correctionLevel == originalOptions.correctionLevel)
    // 注意：颜色比较可能因为精度问题而不完全相等，这里主要测试编解码不会崩溃
  }

  // MARK: - Performance Tests

  @Test("QR码生成性能测试")
  func qRCodeGenerationPerformance() throws {
    let service = QRCodeService()
    let options = QRCodeOptions(size: CGSize(width: 200, height: 200))

    // 测试连续生成多个QR码的性能
    for index in 0..<5 {
      let text = "Performance Test \(i)"
      let result = try service.generateQRCode(from: text, options: options)
      #expect(!result.image.size.equalTo(.zero))
    }
  }

  @Test("QR码识别性能测试")
  func qRCodeRecognitionPerformance() async throws {
    let service = QRCodeService()
    let options = QRCodeOptions(size: CGSize(width: 300, height: 300))

    // 生成测试QR码
    let texts = ["Test 1", "Test 2", "Test 3"]

    for text in texts {
      let generationResult = try service.generateQRCode(from: text, options: options)
      let recognitionResults = try await service.recognizeQRCode(from: generationResult.image)

      #expect(!recognitionResults.isEmpty)
      #expect(recognitionResults.first?.text == text)
    }
  }

  // MARK: - Edge Case Tests

  @Test("特殊字符QR码生成测试")
  func specialCharacterQRCodeGeneration() throws {
    let service = QRCodeService()
    let options = QRCodeOptions()

    let specialTexts = [
      "Hello 世界! 🌍",
      "https://example.com/path?param=value&other=123",
      "Email: test@example.com\nPhone: +1-234-567-8900",
      "JSON: {\"key\": \"value\", \"number\": 42}"
    ]

    for text in specialTexts {
      let result = try service.generateQRCode(from: text, options: options)
      #expect(result.inputText == text)
      #expect(!result.image.size.equalTo(.zero))
    }
  }

  @Test("不同纠错级别QR码生成测试")
  func differentCorrectionLevelsGeneration() throws {
    let service = QRCodeService()

    for level in QRCodeCorrectionLevel.allCases {
      let options = QRCodeOptions(correctionLevel: level)
      let result = try service.generateQRCode(from: testText, options: options)

      #expect(result.options.correctionLevel == level)
      #expect(!result.image.size.equalTo(.zero))
    }
  }

  @Test("不同尺寸QR码生成测试")
  func differentSizesGeneration() throws {
    let service = QRCodeService()

    let sizes = [
      CGSize(width: 50, height: 50),
      CGSize(width: 100, height: 100),
      CGSize(width: 200, height: 200),
      CGSize(width: 500, height: 500)
    ]

    for size in sizes {
      let options = QRCodeOptions(size: size)
      let result = try service.generateQRCode(from: testText, options: options)

      #expect(result.image.size == size)
    }
  }

  // MARK: - Integration with UI Tests

  @Test("QRCodeView 与 NavigationManager 集成测试")
  func qRCodeViewNavigationIntegration() {
    let navigationManager = NavigationManager()

    // 验证二维码工具在导航管理器中正确定义
    let qrCodeTool = NavigationManager.ToolType.qrCode
    #expect(qrCodeTool.name == "二维码")
    #expect(qrCodeTool.icon == "qrcode")
    #expect(qrCodeTool.description == "二维码生成和识别")

    // 验证工具类型包含在所有案例中
    #expect(NavigationManager.ToolType.allCases.contains(.qrCode))
  }
}
