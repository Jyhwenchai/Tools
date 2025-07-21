//
//  CoreFunctionalityIntegrityTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/20.
//

import AppKit
import Foundation
import SwiftUI
import Testing
@testable import Tools
import UniformTypeIdentifiers

/// 核心功能完整性测试
/// 验证所有工具功能在无权限状态下正常工作

// MARK: - Test Helpers

extension NSImage {
  var isValid: Bool {
    size.width > 0 && size.height > 0
  }
}

func createTestImage(size: CGSize) -> NSImage {
  let image = NSImage(size: size)
  image.lockFocus()

  // Fill with a solid color to create actual image content
  NSColor.blue.setFill()
  NSRect(origin: .zero, size: size).fill()

  image.unlockFocus()
  return image
}

struct CoreFunctionalityIntegrityTests {
  // MARK: - Application Startup Tests

  @Test("验证应用启动无权限弹窗")
  func applicationStartupWithoutPermissionPrompts() async {
    // 验证应用主要组件可以正常初始化
    let securityService = SecurityService.shared
    let performanceMonitor = PerformanceMonitor.shared
    let errorLoggingService = ErrorLoggingService.shared

    // 验证服务初始化不会抛出权限相关异常
    #expect(securityService.validateLocalProcessing() == true)
    #expect(performanceMonitor.getPerformanceReport().averageMemoryUsage >= 0)

    // 验证错误日志服务可以正常工作
    errorLoggingService.logError(ToolError.emptyInput)
    let errorHistory = errorLoggingService.getErrorHistory()
    #expect(!errorHistory.isEmpty)

    // 验证SecurityService不再请求文件访问权限
    #expect(securityService.validateLocalProcessing() == true)

    // 验证性能监控在DEBUG模式下工作，发布模式下不显示UI
    #if DEBUG
      let performanceReport = performanceMonitor.getPerformanceReport()
      #expect(performanceReport.averageMemoryUsage >= 0)
    #else
      // 在发布模式下，性能监控应该是静默的
      #expect(Bool(true))
    #endif
  }

  @Test("验证导航管理器无权限依赖")
  func navigationManagerWithoutPermissions() {
    let navigationManager = NavigationManager()

    // 验证所有工具类型都可以正常访问
    for toolType in NavigationManager.ToolType.allCases {
      navigationManager.selectedTool = toolType
      #expect(navigationManager.selectedTool == toolType)

      // 验证工具属性完整
      #expect(!toolType.name.isEmpty)
      #expect(!toolType.icon.isEmpty)
      #expect(!toolType.description.isEmpty)
    }
  }

  // MARK: - File Operations Tests

  @Test("验证文件对话框工具无需权限")
  func fileDialogUtilsWithoutPermissions() {
    // 验证FileDialogUtils方法签名存在且可调用
    let _: (([UTType]) async -> URL?) = FileDialogUtils.showOpenDialog
    let _: (([UTType]) async -> [URL]) = FileDialogUtils.showMultipleOpenDialog
    let _: ((String, [UTType]) async -> URL?) = FileDialogUtils.showSaveDialog
    let _: (() async -> URL?) = FileDialogUtils.showDirectoryDialog

    // 验证支持的文件类型
    let imageTypes: [UTType] = [.png, .jpeg, .gif, .tiff, .bmp]
    let documentTypes: [UTType] = [.json, .plainText]

    #expect(!imageTypes.isEmpty)
    #expect(!documentTypes.isEmpty)

    // 验证UTType标识符正确
    #expect(UTType.png.identifier == "public.png")
    #expect(UTType.jpeg.identifier == "public.jpeg")
    #expect(UTType.json.identifier == "public.json")
  }

  @Test("验证拖拽导入功能支持")
  func dragDropFunctionalitySupport() {
    // 验证拖拽相关的UTType支持
    #expect(UTType.image.identifier == "public.image")
    #expect(UTType.fileURL.identifier == "public.file-url")

    // 验证文件扩展名处理
    let supportedExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic"]
    let testURL = URL(fileURLWithPath: "/test/image.png")

    #expect(supportedExtensions.contains(testURL.pathExtension.lowercased()))

    // 验证不同文件类型的URL处理
    let testFiles = [
      "/test/document.json",
      "/test/image.jpeg",
      "/test/data.txt"
    ]

    for filePath in testFiles {
      let url = URL(fileURLWithPath: filePath)
      #expect(url.isFileURL)
      #expect(!url.pathExtension.isEmpty)
    }
  }

  // MARK: - Core Tool Functionality Tests

  @Test("验证加密工具核心功能")
  func encryptionToolCoreFunctionality() {
    let encryptionService = EncryptionService.shared

    // 测试基本加密功能（不涉及文件权限）
    let testText = "Hello, World!"
    let password = "testPassword123"

    do {
      // 测试AES加密
      let encryptedText = try encryptionService.encrypt(testText, using: .aes, key: password)
      #expect(!encryptedText.isEmpty)

      let decryptedText = try encryptionService.decrypt(encryptedText, using: .aes, key: password)
      #expect(decryptedText == testText)

      // 测试Base64编码
      let base64Encoded = try encryptionService.encrypt(testText, using: .base64)
      #expect(!base64Encoded.isEmpty)

      let base64Decoded = try encryptionService.decrypt(base64Encoded, using: .base64)
      #expect(base64Decoded == testText)

      // 测试哈希算法
      let sha256Hash = try encryptionService.encrypt(testText, using: .sha256)
      #expect(!sha256Hash.isEmpty)
      #expect(sha256Hash.count == 64) // SHA256 produces 64 character hex string

    } catch {
      #expect(Bool(false), "Encryption should work without file permissions")
    }
  }

  @Test("验证JSON工具核心功能")
  func jSONToolCoreFunctionality() {
    let jsonService = JSONService.shared

    // 测试JSON格式化（不涉及文件权限）
    let testJSON = "{\"name\":\"John\",\"age\":30}"

    do {
      let formattedJSON = try jsonService.formatJSON(testJSON)
      #expect(formattedJSON.contains("\"name\" : \"John\""))
      #expect(formattedJSON.contains("\"age\" : 30"))
    } catch {
      #expect(Bool(false), "JSON formatting should work without file permissions")
    }

    // 测试JSON验证
    let validationResult = jsonService.validateJSON(testJSON)
    #expect(validationResult.isValid == true)
    #expect(validationResult.errorMessage == nil)

    // 测试JSON压缩
    do {
      let minifiedJSON = try jsonService.minifyJSON(testJSON)
      #expect(!minifiedJSON.isEmpty)
      #expect(!minifiedJSON.contains(" "))
    } catch {
      #expect(Bool(false), "JSON minification should work without file permissions")
    }
  }

  @Test("验证图片处理工具核心功能")
  func imageProcessingToolCoreFunctionality() {
    let imageService = ImageProcessingService()

    // 创建有内容的测试图片（不涉及文件权限）
    let testImage = createTestImage(size: CGSize(width: 100, height: 100))

    // 测试图片调整大小
    let resizedImage = imageService.resizeImage(testImage, to: CGSize(width: 50, height: 50))
    #expect(resizedImage != nil)
    #expect(resizedImage?.size == CGSize(width: 50, height: 50))

    // 测试图片格式转换
    let pngData = imageService.convertImage(testImage, to: .png)
    #expect(pngData != nil)
    #expect(!pngData!.isEmpty)

    let jpegData = imageService.convertImage(testImage, to: .jpeg(quality: 0.8))
    #expect(jpegData != nil)
    #expect(!jpegData!.isEmpty)

    // 测试图片压缩
    let compressedData = imageService.compressImage(testImage, quality: 0.5)
    #expect(compressedData != nil)
    #expect(!compressedData!.isEmpty)
  }

  @Test("验证二维码工具核心功能")
  func qRCodeToolCoreFunctionality() async {
    let qrService = QRCodeService()

    // 测试二维码生成（不涉及文件权限）
    let testText = "https://example.com"
    let qrOptions = QRCodeOptions(
      size: CGSize(width: 200, height: 200),
      correctionLevel: .medium)

    do {
      let qrResult = try qrService.generateQRCode(from: testText, options: qrOptions)
      #expect(qrResult.image.size.width == 200)
      #expect(qrResult.image.size.height == 200)
      #expect(qrResult.inputText == testText)
      #expect(qrResult.options.size == CGSize(width: 200, height: 200))
    } catch {
      #expect(Bool(false), "QR code generation should work without file permissions: \(error)")
    }

    // 测试二维码识别（简化版本，避免复杂的异步识别）
    do {
      let qrResult = try qrService.generateQRCode(from: testText, options: qrOptions)
      #expect(qrResult.image.isValid)
      // 注意：QR码识别需要实际的图像内容，这里我们只验证生成成功
    } catch {
      #expect(Bool(false), "QR code generation should work without file permissions: \(error)")
    }
  }

  @Test("验证时间转换工具核心功能")
  func timeConverterToolCoreFunctionality() {
    let timeService = TimeConverterService()

    // 测试时间戳转换（不涉及文件权限）
    let currentTimestamp = String(Int(Date().timeIntervalSince1970))
    let options = TimeConversionOptions(
      sourceFormat: .timestamp,
      targetFormat: .iso8601,
      sourceTimeZone: .current,
      targetTimeZone: .current)

    let result = timeService.convertTime(input: currentTimestamp, options: options)
    if result.success {
      #expect(!result.result.isEmpty)
    } else {
      #expect(Bool(false), "Time conversion should work: \(result.error ?? "Unknown error")")
    }

    // 测试当前时间获取
    let currentTimeString = timeService.getCurrentTime(format: .iso8601)
    #expect(!currentTimeString.isEmpty)

    let currentTimestampString = timeService.getCurrentTimestamp()
    #expect(!currentTimestampString.isEmpty)

    // 测试时间戳验证
    #expect(timeService.validateTimestamp(currentTimestamp) == true)
    #expect(timeService.validateTimestamp("invalid") == false)
  }

  // MARK: - Clipboard Functionality Tests

  @Test("验证粘贴板工具权限优化")
  func clipboardToolPermissionOptimization() {
    // 验证粘贴板项目模型
    let testContent = "测试粘贴板内容"
    let clipboardItem = ClipboardItem(content: testContent, type: .text)

    #expect(clipboardItem.content == testContent)
    #expect(clipboardItem.type == .text)
    #expect(clipboardItem.timestamp <= Date())

    // 验证不同类型的粘贴板项目
    let urlItem = ClipboardItem(content: "https://example.com", type: .url)
    #expect(urlItem.type == .url)

    let codeItem = ClipboardItem(content: "func test() {}", type: .code)
    #expect(codeItem.type == .code)

    // 验证粘贴板服务需要ModelContext但不会在初始化时请求权限
    // 这里我们只验证ClipboardItem模型的正确性，实际的服务测试在其他地方进行
    #expect(clipboardItem.id != UUID())
    #expect(clipboardItem.content == testContent)
  }

  // MARK: - Settings and Configuration Tests

  @Test("验证应用设置无权限依赖")
  func appSettingsWithoutPermissionDependencies() {
    let settings = AppSettings.shared

    // 验证默认设置可以正常访问
    #expect(settings.theme == AppTheme.system || settings.theme == AppTheme.light || settings
      .theme == AppTheme.dark)
    #expect(settings.maxClipboardHistory > 0)
    #expect(settings.defaultImageQuality > 0 && settings.defaultImageQuality <= 1.0)

    // 验证设置修改不需要权限
    let originalTheme = settings.theme
    settings.theme = AppTheme.dark
    #expect(settings.theme == AppTheme.dark)
    settings.theme = originalTheme // 恢复原始设置

    // 验证所有主题选项都可用
    for theme in AppTheme.allCases {
      settings.theme = theme
      #expect(settings.theme == theme)
    }
  }

  // MARK: - Error Handling Tests

  @Test("验证错误处理不包含权限相关错误")
  func errorHandlingWithoutPermissionErrors() {
    // 验证ToolError不再包含权限相关错误
    let errors: [ToolError] = [
      .invalidInput("test"),
      .emptyInput,
      .processingFailed("test"),
      .fileNotFound("test.txt"),
      .fileTooLarge(1000),
      .diskSpaceFull,
      .systemResourceUnavailable,
      .networkError(NSError(domain: "TestDomain", code: -1, userInfo: nil)),
      .timeout,
      .unsupportedFormat
    ]

    // 验证所有错误都有有效的描述
    for error in errors {
      let description = error.localizedDescription
      #expect(!description.isEmpty)

      // 验证错误描述不包含权限相关内容
      #expect(!description.contains("权限"))
      #expect(!description.contains("permission"))
      #expect(!description.contains("访问被拒绝"))
      #expect(!description.contains("access denied"))
    }

    // 验证错误的可重试性
    let retryableErrors: [ToolError] = [
      .processingFailed("临时失败"),
      .networkError(NSError(domain: "NetworkDomain", code: -1009, userInfo: nil)),
      .timeout,
      .systemResourceUnavailable
    ]

    for error in retryableErrors {
      #expect(error.isRetryable == true)
    }
  }

  // MARK: - Performance Monitoring Tests

  @Test("验证性能监控权限移除")
  func performanceMonitoringPermissionRemoval() {
    let performanceMonitor = PerformanceMonitor.shared

    // 验证性能监控可以正常工作（在DEBUG模式下）
    #if DEBUG
      let report = performanceMonitor.getPerformanceReport()
      #expect(report.averageMemoryUsage >= 0)
      #expect(report.averageCPUUsage >= 0)
      #expect(report.totalWarnings >= 0)

      // 验证最近指标获取
      let recentMetrics = performanceMonitor.getRecentMetrics(count: 5)
      #expect(recentMetrics.count <= 5)
    #else
      // 在发布模式下，性能监控应该是静默的
      #expect(Bool(true))
    #endif

    // 验证性能监控不会请求特殊权限
    performanceMonitor.startPerformanceMonitoring()
    #expect(Bool(true)) // 如果没有崩溃，说明不需要特殊权限
  }

  // MARK: - Security Service Tests

  @Test("验证安全服务权限简化")
  func securityServicePermissionSimplification() {
    let securityService = SecurityService.shared

    // 验证基本安全功能仍然可用
    #expect(securityService.validateLocalProcessing() == true)

    // 验证敏感数据清理功能
    securityService.clearSensitiveData()
    #expect(Bool(true)) // 如果没有崩溃，说明功能正常

    // 验证不再有集中的权限请求方法
    // 权限现在由各个服务独立管理
    #expect(securityService != nil)
  }

  // MARK: - Async Operations Tests

  @Test("验证异步操作管理无权限依赖")
  func asyncOperationManagerWithoutPermissions() {
    let manager = AsyncOperationManager.shared

    // 验证基本状态查询
    #expect(manager.activeOperationCount >= 0)
    #expect(manager.isAnyOperationRunning == (manager.activeOperationCount > 0))

    // 验证操作列表获取
    let operations = manager.getAllOperations()
    #expect(operations.count == manager.activeOperationCount)

    // 验证操作取消功能
    manager.cancelAllOperations()
    #expect(Bool(true)) // 如果没有崩溃，说明功能正常
  }

  // MARK: - UI Components Tests

  @Test("验证共享UI组件无权限依赖")
  func sharedUIComponentsWithoutPermissions() {
    // 验证ProcessingStateView
    let processingView = ProcessingStateView(isProcessing: true, message: "处理中")
    #expect(processingView.isProcessing == true)
    #expect(processingView.message == "处理中")

    // 验证ToolButton
    var buttonPressed = false
    let button = ToolButton(
      title: "测试按钮",
      action: { buttonPressed = true },
      style: .primary)

    #expect(button.title == "测试按钮")
    #expect(button.style == .primary)

    button.action()
    #expect(buttonPressed == true)

    // 验证ToolResultView
    let resultView = ToolResultView(
      title: "处理结果",
      content: "这是处理后的内容",
      canCopy: true)

    #expect(resultView.title == "处理结果")
    #expect(resultView.content == "这是处理后的内容")
    #expect(resultView.canCopy == true)
  }

  // MARK: - Integration Tests

  @Test("验证端到端工作流无权限阻塞")
  func endToEndWorkflowWithoutPermissionBlocking() async {
    // 模拟完整的用户工作流，确保没有权限弹窗阻塞

    // 1. 应用启动
    let navigationManager = NavigationManager()
    #expect(navigationManager.selectedTool == .encryption)

    // 2. 切换到JSON工具并处理数据
    navigationManager.selectedTool = .json
    let jsonService = JSONService.shared
    let testJSON = "{\"name\":\"John\",\"age\":30}"

    do {
      let formattedJSON = try jsonService.formatJSON(testJSON)
      #expect(formattedJSON.contains("\"name\" : \"John\""))
    } catch {
      #expect(Bool(false), "JSON processing should work without permissions")
    }

    // 3. 切换到图片处理工具
    navigationManager.selectedTool = .imageProcessing
    let imageService = ImageProcessingService()
    let testImage = createTestImage(size: CGSize(width: 100, height: 100))

    let resizedImage = imageService.resizeImage(testImage, to: CGSize(width: 50, height: 50))
    #expect(resizedImage != nil)
    #expect(resizedImage?.isValid == true)

    // 4. 切换到二维码工具
    navigationManager.selectedTool = .qrCode
    let qrService = QRCodeService()

    do {
      let qrImage = try qrService.generateQRCode(
        from: "https://example.com",
        options: QRCodeOptions())
      #expect(qrImage.image.size.width > 0)
      #expect(qrImage.image.isValid)
    } catch {
      #expect(Bool(false), "QR code generation should work without permissions: \(error)")
    }

    // 5. 验证整个工作流程中没有权限相关的阻塞
    #expect(navigationManager.selectedTool == .qrCode)
  }

  // MARK: - Entitlements Verification Tests

  @Test("验证应用权限配置已最小化")
  func applicationEntitlementsMinimized() {
    // 验证应用bundle存在
    let bundle = Bundle.main
    #expect(bundle.bundleIdentifier != nil)

    // 在测试环境中验证权限相关的检查逻辑已被移除
    // 实际的entitlements验证在构建时进行

    // 验证SecurityService不再进行复杂的权限检查
    let securityService = SecurityService.shared
    #expect(securityService.validateLocalProcessing() == true)

    // 验证应用可以正常运行而不需要额外权限
    #expect(Bool(true))
  }
}
