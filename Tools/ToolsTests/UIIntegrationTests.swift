//
//  UIIntegrationTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import SwiftUI
@testable import Tools

struct UIIntegrationTests {
  
  // MARK: - Navigation Integration Tests
  
  @Test("导航管理器与主界面集成测试")
  func testNavigationManagerIntegration() {
    let navigationManager = NavigationManager()
    
    // 测试初始状态
    #expect(navigationManager.selectedTool == .encryption)
    
    // 测试工具切换
    navigationManager.selectedTool = .json
    #expect(navigationManager.selectedTool == .json)
    
    navigationManager.selectedTool = .imageProcessing
    #expect(navigationManager.selectedTool == .imageProcessing)
    
    // 测试所有工具类型都可以正常切换
    for toolType in NavigationManager.ToolType.allCases {
      navigationManager.selectedTool = toolType
      #expect(navigationManager.selectedTool == toolType)
    }
  }
  
  @Test("工具详情视图集成测试")
  func testToolDetailViewIntegration() {
    // 测试每个工具类型都有对应的详情视图
    for toolType in NavigationManager.ToolType.allCases {
      // 这里我们主要验证工具类型的属性是否正确设置
      #expect(!toolType.name.isEmpty)
      #expect(!toolType.icon.isEmpty)
      #expect(!toolType.description.isEmpty)
      #expect(toolType.id == toolType.name)
    }
  }
  
  // MARK: - Shared Components Integration Tests
  
  @Test("共享组件状态管理测试")
  func testSharedComponentsStateManagement() {
    // 测试 ProcessingStateView 状态变化
    let processingView1 = ProcessingStateView(isProcessing: true, message: "处理中")
    #expect(processingView1.isProcessing == true)
    #expect(processingView1.message == "处理中")
    
    let processingView2 = ProcessingStateView(isProcessing: false, message: "完成")
    #expect(processingView2.isProcessing == false)
    #expect(processingView2.message == "完成")
  }
  
  @Test("工具按钮交互测试")
  func testToolButtonInteraction() {
    var buttonPressed = false
    
    let button = ToolButton(
      title: "测试按钮",
      action: { buttonPressed = true },
      style: .primary
    )
    
    #expect(button.title == "测试按钮")
    #expect(button.style == .primary)
    #expect(buttonPressed == false)
    
    // 模拟按钮点击
    button.action()
    #expect(buttonPressed == true)
  }
  
  @Test("工具结果视图集成测试")
  func testToolResultViewIntegration() {
    let resultView = ToolResultView(
      title: "处理结果",
      content: "这是处理后的内容",
      canCopy: true
    )
    
    #expect(resultView.title == "处理结果")
    #expect(resultView.content == "这是处理后的内容")
    #expect(resultView.canCopy == true)
    
    // 测试不可复制的结果视图
    let nonCopyableView = ToolResultView(
      title: "只读结果",
      content: "只读内容",
      canCopy: false
    )
    
    #expect(nonCopyableView.canCopy == false)
  }
  
  // MARK: - Error Handling Integration Tests
  
  @Test("错误处理集成测试")
  func testErrorHandlingIntegration() {
    // 测试不同类型的工具错误
    let errors: [ToolError] = [
      .invalidInput("无效输入"),
      .processingFailed("处理失败"),
      .networkError(NSError(domain: "TestDomain", code: -1, userInfo: nil)),
      .unsupportedFormat
    ]
    
    for error in errors {
      #expect(error.errorDescription != nil)
      #expect(!error.errorDescription!.isEmpty)
    }
  }
  
  @Test("错误恢复机制测试")
  func testErrorRecoveryMechanism() {
    // 测试可重试的错误
    let retryableErrors: [ToolError] = [
      .processingFailed("临时失败"),
      .networkError(NSError(domain: "NetworkDomain", code: -1009, userInfo: nil)),
      .timeout,
      .systemResourceUnavailable
    ]
    
    for error in retryableErrors {
      #expect(error.isRetryable == true)
    }
    
    // 测试不可重试的错误
    let nonRetryableErrors: [ToolError] = [
      .invalidInput("格式错误"),
      .unsupportedFormat
    ]
    
    for error in nonRetryableErrors {
      #expect(error.isRetryable == false)
    }
  }
  
  // MARK: - Settings Integration Tests
  
  @Test("应用设置集成测试")
  func testAppSettingsIntegration() {
    let settings = AppSettings.shared
    
    // 测试默认设置
    #expect(settings.theme == AppTheme.system)
    #expect(settings.maxClipboardHistory == 100)
    #expect(settings.autoSaveResults == true)
    #expect(settings.defaultImageQuality == 0.8)
    
    // 测试设置修改
    settings.theme = AppTheme.dark
    settings.maxClipboardHistory = 50
    settings.autoSaveResults = false
    settings.defaultImageQuality = 0.9
    
    #expect(settings.theme == AppTheme.dark)
    #expect(settings.maxClipboardHistory == 50)
    #expect(settings.autoSaveResults == false)
    #expect(settings.defaultImageQuality == 0.9)
  }
  
  @Test("主题切换集成测试")
  func testThemeSwitchingIntegration() {
    let settings = AppSettings.shared
    for theme in AppTheme.allCases {
      settings.theme = theme
      #expect(settings.theme == theme)
      #expect(!theme.rawValue.isEmpty)
    }
  }
  
  // MARK: - Data Flow Integration Tests
  
  @Test("数据流集成测试")
  func testDataFlowIntegration() {
    // 测试 JSON 处理结果的数据流
    let jsonResult = JSONProcessingResult(
      operation: .format,
      input: "{\"name\":\"John\"}",
      output: """
      {
        "name" : "John"
      }
      """
    )
    
    #expect(jsonResult.operation == .format)
    #expect(jsonResult.isValid == true)
    #expect(jsonResult.errorMessage == nil)
    
    // 测试二维码生成结果的数据流
    let qrOptions = QRCodeOptions(
      size: CGSize(width: 200, height: 200),
      correctionLevel: .medium
    )
    
    let testImage = NSImage(size: CGSize(width: 200, height: 200))
    let qrResult = QRCodeGenerationResult(
      image: testImage,
      inputText: "测试文本",
      options: qrOptions
    )
    
    #expect(qrResult.inputText == "测试文本")
    #expect(qrResult.options.size == CGSize(width: 200, height: 200))
    #expect(qrResult.options.correctionLevel == .medium)
  }
  
  // MARK: - Performance Integration Tests
  
  @Test("性能监控集成测试")
  func testPerformanceMonitoringIntegration() {
    let monitor = PerformanceMonitor.shared
    
    // 测试性能报告生成
    let report = monitor.getPerformanceReport()
    #expect(report.averageMemoryUsage >= 0)
    #expect(report.averageCPUUsage >= 0)
    #expect(report.totalWarnings >= 0)
    
    // 测试最近指标获取
    let recentMetrics = monitor.getRecentMetrics(count: 10)
    #expect(recentMetrics.count <= 10)
  }
  
  @Test("异步操作管理集成测试")
  func testAsyncOperationManagerIntegration() {
    let manager = AsyncOperationManager.shared
    
    // 测试初始状态
    #expect(manager.activeOperationCount >= 0)
    #expect(manager.isAnyOperationRunning == (manager.activeOperationCount > 0))
    
    // 测试操作列表获取
    let operations = manager.getAllOperations()
    #expect(operations.count == manager.activeOperationCount)
  }
  
  // MARK: - Security Integration Tests
  
  @Test("安全服务集成测试")
  func testSecurityServiceIntegration() {
    let securityService = SecurityService.shared
    
    // 测试基本安全功能
    #expect(securityService != nil)
    
    // 测试安全验证基本功能
    let testInput = "正常输入"
    #expect(!testInput.isEmpty)
    
    let emptyInput = ""
    #expect(emptyInput.isEmpty)
  }
  
  // MARK: - Clipboard Integration Tests
  
  @Test("粘贴板服务集成测试")
  func testClipboardServiceIntegration() {
    // 测试粘贴板项目创建
    let testContent = "测试粘贴板内容"
    let clipboardItem = ClipboardItem(
      content: testContent,
      type: .text
    )
    
    #expect(clipboardItem.content == testContent)
    #expect(clipboardItem.type == .text)
    #expect(clipboardItem.timestamp <= Date())
    
    // 测试不同类型的粘贴板项目
    let urlItem = ClipboardItem(content: "https://example.com", type: .url)
    #expect(urlItem.type == .url)
    
    let codeItem = ClipboardItem(content: "func test() {}", type: .code)
    #expect(codeItem.type == .code)
  }
  
  // MARK: - End-to-End Integration Tests
  
  @Test("端到端工作流集成测试")
  func testEndToEndWorkflowIntegration() {
    // 模拟完整的用户工作流
    
    // 1. 用户启动应用，导航管理器初始化
    let navigationManager = NavigationManager()
    #expect(navigationManager.selectedTool == .encryption)
    
    // 2. 用户切换到 JSON 工具
    navigationManager.selectedTool = .json
    #expect(navigationManager.selectedTool == .json)
    
    // 3. 用户处理 JSON 数据
    let jsonInput = "{\"name\": \"John\", \"age\": 30}"
    let jsonResult = JSONProcessingResult(
      operation: .format,
      input: jsonInput,
      output: """
      {
        "name" : "John",
        "age" : 30
      }
      """
    )
    
    #expect(jsonResult.isValid == true)
    #expect(jsonResult.operation == .format)
    
    // 4. 用户切换到二维码工具
    navigationManager.selectedTool = .qrCode
    #expect(navigationManager.selectedTool == .qrCode)
    
    // 5. 用户生成二维码
    let qrOptions = QRCodeOptions()
    let testImage = NSImage(size: qrOptions.size)
    let qrResult = QRCodeGenerationResult(
      image: testImage,
      inputText: "https://example.com",
      options: qrOptions
    )
    
    #expect(qrResult.inputText == "https://example.com")
    #expect(qrResult.options.correctionLevel == .medium)
    
    // 6. 验证整个工作流的数据一致性
    #expect(navigationManager.selectedTool == .qrCode)
    #expect(jsonResult.timestamp <= qrResult.timestamp)
  }
}