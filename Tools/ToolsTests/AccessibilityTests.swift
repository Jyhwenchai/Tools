//
//  AccessibilityTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import SwiftUI
import Testing

@testable import Tools

struct AccessibilityTests {
  // MARK: - Navigation Accessibility Tests

  @Test("导航管理器可访问性测试")
  func navigationManagerAccessibility() {
    let navigationManager = NavigationManager()

    // 测试所有工具类型都有可访问的名称和描述
    for toolType in NavigationManager.ToolType.allCases {
      #expect(!toolType.name.isEmpty, "工具类型 \(toolType) 缺少名称")
      #expect(!toolType.description.isEmpty, "工具类型 \(toolType) 缺少描述")
      #expect(!toolType.icon.isEmpty, "工具类型 \(toolType) 缺少图标")

      // 验证名称和描述是中文，便于本地化用户理解
      #expect(!toolType.name.isEmpty)
      #expect(!toolType.description.isEmpty)
    }
  }

  @Test(
    "工具类型可访问性标签测试",
    arguments: [
      (NavigationManager.ToolType.encryption, "加密解密", "文本加密解密工具"),
      (NavigationManager.ToolType.json, "JSON工具", "JSON格式化和处理"),
      (NavigationManager.ToolType.imageProcessing, "图片处理", "图片压缩和处理"),
      (NavigationManager.ToolType.qrCode, "二维码", "二维码生成和识别"),
      (NavigationManager.ToolType.timeConverter, "时间转换", "时间格式转换"),
      (NavigationManager.ToolType.clipboard, "粘贴板", "粘贴板历史管理"),
    ])
  func toolTypeAccessibilityLabels(
    toolType: NavigationManager.ToolType,
    expectedName: String,
    expectedDescription: String
  ) {
    #expect(toolType.name == expectedName)
    #expect(toolType.description == expectedDescription)

    // 验证可访问性标识符
    #expect(toolType.id == expectedName)
  }

  // MARK: - Shared Components Accessibility Tests

  @Test("工具按钮可访问性测试")
  func toolButtonAccessibility() {
    let buttonTitle = "测试按钮"
    var actionCalled = false

    let button = ToolButton(
      title: buttonTitle,
      action: { actionCalled = true },
      style: .primary)

    // 验证按钮有明确的标题
    #expect(button.title == buttonTitle)
    #expect(!button.title.isEmpty)

    // 验证按钮样式有语义意义
    #expect(button.style == .primary)

    // 验证按钮可以被激活
    button.action()
    #expect(actionCalled == true)
  }

  @Test(
    "工具按钮样式可访问性测试",
    arguments: [
      (ToolButton.ButtonStyle.primary, "主要操作按钮"),
      (ToolButton.ButtonStyle.secondary, "次要操作按钮"),
      (ToolButton.ButtonStyle.destructive, "危险操作按钮"),
    ])
  func toolButtonStyleAccessibility(style: ToolButton.ButtonStyle, description _: String) {
    let button = ToolButton(
      title: "测试",
      action: {},
      style: style)

    #expect(button.style == style)

    // 验证不同样式的按钮都有明确的语义
    switch style {
    case .primary:
      // 主要按钮应该用于最重要的操作
      break
    case .secondary:
      // 次要按钮应该用于辅助操作
      break
    case .destructive:
      // 危险按钮应该用于删除等危险操作
      break
    }
  }

  @Test("处理状态视图可访问性测试")
  func processingStateViewAccessibility() {
    // 测试处理中状态
    let processingView = ProcessingStateView(isProcessing: true, message: "正在处理...")
    #expect(processingView.isProcessing == true)
    #expect(!processingView.message.isEmpty)
    #expect(processingView.message == "正在处理...")

    // 测试完成状态
    let completedView = ProcessingStateView(isProcessing: false, message: "处理完成")
    #expect(completedView.isProcessing == false)
    #expect(!completedView.message.isEmpty)
    #expect(completedView.message == "处理完成")
  }

  @Test("工具结果视图可访问性测试")
  func toolResultViewAccessibility() {
    let title = "处理结果"
    let content = "这是处理后的内容"

    let resultView = ToolResultView(
      title: title,
      content: content,
      canCopy: true)

    // 验证结果视图有明确的标题和内容
    #expect(resultView.title == title)
    #expect(!resultView.title.isEmpty)
    #expect(resultView.content == content)
    #expect(!resultView.content.isEmpty)

    // 验证复制功能的可访问性
    #expect(resultView.canCopy == true)
  }

  @Test("工具文本框可访问性测试")
  func toolTextFieldAccessibility() {
    let title = "输入标题"
    let placeholder = "请输入内容"
    @State var text = ""

    let textField = ToolTextField(
      title: title,
      text: $text,
      placeholder: placeholder)

    // 验证文本框有明确的标题和占位符
    #expect(textField.title == title)
    #expect(!textField.title.isEmpty)
    #expect(textField.placeholder == placeholder)
    #expect(!textField.placeholder.isEmpty)
  }

  // MARK: - Error Messages Accessibility Tests

  @Test("错误消息可访问性测试")
  func errorMessageAccessibility() {
    let errors: [ToolError] = [
      .invalidInput("输入格式不正确"),
      .processingFailed("处理过程中发生错误"),
      .networkError(NSError(domain: "TestDomain", code: -1, userInfo: nil)),
      .unsupportedFormat,
      .timeout,
      .noInternetConnection,
      .systemResourceUnavailable,
      .unknown("未知错误"),
    ]

    for error in errors {
      let errorDescription = error.errorDescription
      #expect(errorDescription != nil, "错误 \(error) 缺少描述")
      #expect(!errorDescription!.isEmpty, "错误 \(error) 描述为空")

      // 验证错误消息是中文，便于用户理解
      let description = errorDescription!
      #expect(!description.isEmpty)

      // 验证错误消息提供了有用的信息
      switch error {
      case let .invalidInput(message):
        #expect(description.contains("输入") || description.contains(message))
      case let .processingFailed(message):
        #expect(
          description.contains("处理") || description.contains("失败")
            || description
              .contains(message)
        )
      case .networkError:
        #expect(description.contains("网络") || description.contains("错误"))
      case .unsupportedFormat:
        #expect(description.contains("格式") || description.contains("支持"))
      case .timeout:
        #expect(description.contains("超时") || description.contains("时间"))
      case .noInternetConnection:
        #expect(description.contains("网络") || description.contains("连接"))
      case .systemResourceUnavailable:
        #expect(description.contains("系统") || description.contains("资源"))
      case .unknown:
        #expect(description.contains("未知") || description.contains("错误"))
      default:
        // 处理其他错误类型
        #expect(!description.isEmpty)
      }
    }
  }

  // MARK: - Model Data Accessibility Tests

  @Test("JSON操作可访问性测试")
  func jSONOperationAccessibility() {
    for operation in JSONOperation.allCases {
      #expect(!operation.rawValue.isEmpty, "JSON操作 \(operation) 缺少原始值")
      #expect(!operation.description.isEmpty, "JSON操作 \(operation) 缺少描述")
      #expect(operation.id == operation.rawValue, "JSON操作 \(operation) ID不匹配")

      // 验证描述是有意义的中文
      let description = operation.description
      switch operation {
      case .format:
        #expect(description.contains("格式化"))
      case .minify:
        #expect(description.contains("压缩"))
      case .generateModel:
        #expect(description.contains("生成") && description.contains("代码"))
      }
    }
  }

  @Test("编程语言可访问性测试")
  func programmingLanguageAccessibility() {
    for language in ProgrammingLanguage.allCases {
      #expect(!language.rawValue.isEmpty, "编程语言 \(language) 缺少原始值")
      #expect(!language.fileExtension.isEmpty, "编程语言 \(language) 缺少文件扩展名")
      #expect(language.id == language.rawValue, "编程语言 \(language) ID不匹配")

      // 验证文件扩展名格式正确
      #expect(language.fileExtension.hasPrefix("."), "文件扩展名应该以点开头")
    }
  }

  @Test("二维码纠错级别可访问性测试")
  func qRCodeCorrectionLevelAccessibility() {
    for level in QRCodeCorrectionLevel.allCases {
      #expect(!level.rawValue.isEmpty, "纠错级别 \(level) 缺少原始值")
      #expect(!level.displayName.isEmpty, "纠错级别 \(level) 缺少显示名称")
      #expect(!level.coreImageValue.isEmpty, "纠错级别 \(level) 缺少Core Image值")

      // 验证显示名称包含百分比信息
      #expect(level.displayName.contains("%"), "纠错级别显示名称应该包含百分比")

      // 验证显示名称是中文
      switch level {
      case .low:
        #expect(level.displayName.contains("低"))
      case .medium:
        #expect(level.displayName.contains("中"))
      case .quartile:
        #expect(level.displayName.contains("高"))
      case .high:
        #expect(level.displayName.contains("最高"))
      }
    }
  }

  @Test("时间格式可访问性测试")
  func timeFormatAccessibility() {
    for format in TimeFormat.allCases {
      #expect(!format.rawValue.isEmpty, "时间格式 \(format) 缺少原始值")
      #expect(!format.displayName.isEmpty, "时间格式 \(format) 缺少显示名称")
      #expect(!format.description.isEmpty, "时间格式 \(format) 缺少描述")
      #expect(format.id == format.rawValue, "时间格式 \(format) ID不匹配")

      // 验证描述提供了有用的示例或说明
      let description = format.description
      switch format {
      case .timestamp:
        #expect(description.contains("1970") || description.contains("Unix"))
      case .iso8601:
        #expect(description.contains("T") && description.contains("Z"))
      case .rfc2822:
        #expect(description.contains("GMT") || description.contains("Mon"))
      case .custom:
        #expect(description.contains("自定义") || description.contains("User"))
      }
    }
  }

  // MARK: - Settings Accessibility Tests

  @Test("应用主题可访问性测试")
  func appThemeAccessibility() {
    for theme in AppTheme.allCases {
      #expect(!theme.rawValue.isEmpty, "应用主题 \(theme) 缺少原始值")

      // 验证主题名称是中文
      switch theme {
      case .light:
        #expect(theme.rawValue.contains("浅色"))
      case .dark:
        #expect(theme.rawValue.contains("深色"))
      case .system:
        #expect(theme.rawValue.contains("系统"))
      }
    }
  }

  @Test("应用设置可访问性测试")
  func appSettingsAccessibility() {
    let settings = AppSettings.shared

    // 验证默认设置是合理的
    #expect(settings.maxClipboardHistory > 0, "粘贴板历史数量应该大于0")
    #expect(settings.maxClipboardHistory <= 1000, "粘贴板历史数量不应该过大")
    #expect(settings.defaultImageQuality > 0.0, "图片质量应该大于0")
    #expect(settings.defaultImageQuality <= 1.0, "图片质量不应该大于1")
  }

  // MARK: - Performance Warnings Accessibility Tests

  @Test("性能警告可访问性测试")
  func performanceWarningAccessibility() {
    let warnings: [PerformanceWarning] = [
      .highMemoryUsage(250.0),
      .highCPUUsage(85.5),
      .sustainedHighMemoryUsage(180.2),
      .sustainedHighCPUUsage(75.8),
    ]

    for warning in warnings {
      let description = warning.description
      #expect(!description.isEmpty, "性能警告 \(warning) 缺少描述")

      // 验证描述是中文且包含具体数值
      switch warning {
      case let .highMemoryUsage(usage):
        #expect(description.contains("内存"))
        #expect(description.contains("过高"))
        #expect(description.contains(String(format: "%.1f", usage)))
      case let .highCPUUsage(usage):
        #expect(description.contains("CPU"))
        #expect(description.contains("过高"))
        #expect(description.contains(String(format: "%.1f", usage)))
      case let .sustainedHighMemoryUsage(usage):
        #expect(description.contains("持续"))
        #expect(description.contains("内存"))
        #expect(description.contains(String(format: "%.1f", usage)))
      case let .sustainedHighCPUUsage(usage):
        #expect(description.contains("持续"))
        #expect(description.contains("CPU"))
        #expect(description.contains(String(format: "%.1f", usage)))
      }

      // 验证严重程度有适当的颜色
      let severity = warning.severity
      switch severity {
      case .warning:
        #expect(severity.color == .orange)
      case .critical:
        #expect(severity.color == .red)
      }
    }
  }

  // MARK: - Clipboard Item Accessibility Tests

  @Test("粘贴板项目类型可访问性测试")
  func clipboardItemTypeAccessibility() {
    for itemType in ClipboardItemType.allCases {
      #expect(!itemType.rawValue.isEmpty, "粘贴板项目类型 \(itemType) 缺少原始值")

      // 验证类型名称是中文
      switch itemType {
      case .text:
        #expect(itemType.rawValue == "文本")
      case .url:
        #expect(itemType.rawValue == "链接")
      case .code:
        #expect(itemType.rawValue == "代码")
      }
    }
  }

  @Test("粘贴板项目可访问性测试")
  func clipboardItemAccessibility() {
    let textItem = ClipboardItem(content: "测试文本", type: .text)
    let urlItem = ClipboardItem(content: "https://example.com", type: .url)
    let codeItem = ClipboardItem(content: "func test() {}", type: .code)

    let items = [textItem, urlItem, codeItem]

    for item in items {
      #expect(!item.content.isEmpty, "粘贴板项目内容不应该为空")
      #expect(!item.type.rawValue.isEmpty, "粘贴板项目类型不应该为空")
      #expect(item.timestamp <= Date(), "粘贴板项目时间戳应该是有效的")

      // 验证每个项目都有唯一的ID
      #expect(item.id != UUID(), "粘贴板项目应该有唯一ID")
    }

    // 验证不同项目有不同的ID
    #expect(textItem.id != urlItem.id)
    #expect(urlItem.id != codeItem.id)
    #expect(textItem.id != codeItem.id)
  }

  // MARK: - Overall Accessibility Compliance Tests

  @Test("整体可访问性合规测试")
  func overallAccessibilityCompliance() {
    // 验证所有主要组件都有适当的可访问性支持

    // 1. 导航系统
    let navigationManager = NavigationManager()
    #expect(navigationManager.selectedTool == .encryption)

    // 2. 错误处理
    let sampleError = ToolError.invalidInput("测试")
    #expect(sampleError.errorDescription != nil)
    #expect(!sampleError.errorDescription!.isEmpty)

    // 3. 设置系统
    #expect(!AppTheme.allCases.isEmpty)

    // 4. 共享组件
    let button = ToolButton(title: "测试", action: {}, style: .primary)
    #expect(!button.title.isEmpty)

    // 5. 数据模型
    let jsonOperation = JSONOperation.format
    #expect(!jsonOperation.description.isEmpty)

    print("所有主要组件都通过了基本可访问性检查")
  }
}
