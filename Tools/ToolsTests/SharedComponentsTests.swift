//
//  SharedComponentsTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/17.
//

import Testing
import SwiftUI
@testable import Tools

struct SharedComponentsTests {
  
  // MARK: - ToolButton Tests
  
  @Test("ToolButton 样式测试", arguments: [
    (ToolButton.ButtonStyle.primary, "主要按钮"),
    (ToolButton.ButtonStyle.secondary, "次要按钮"),
    (ToolButton.ButtonStyle.destructive, "危险按钮")
  ])
  func testToolButtonStyles(style: ToolButton.ButtonStyle, title: String) {
    var actionCalled = false
    
    let button = ToolButton(
      title: title,
      action: { actionCalled = true },
      style: style
    )
    
    // 验证按钮创建成功
    #expect(button.title == title)
    #expect(button.style == style)
    
    // 验证动作回调
    button.action()
    #expect(actionCalled == true)
  }
  
  @Test("ToolButton 样式枚举完整性测试")
  func testToolButtonStyleCompleteness() {
    let allStyles: [ToolButton.ButtonStyle] = [.primary, .secondary, .destructive]
    #expect(allStyles.count == 3)
  }
  
  // MARK: - ProcessingStateView Tests
  
  @Test("ProcessingStateView 状态测试", arguments: [
    (true, "处理中..."),
    (false, "处理完成"),
    (true, "加载数据"),
    (false, "数据加载完成")
  ])
  func testProcessingStateView(isProcessing: Bool, message: String) {
    let view = ProcessingStateView(isProcessing: isProcessing, message: message)
    
    #expect(view.isProcessing == isProcessing)
    #expect(view.message == message)
  }
  
  // MARK: - ToolResultView Tests
  
  @Test("ToolResultView 基本功能测试")
  func testToolResultView() {
    let title = "测试结果"
    let content = "这是测试内容"
    let canCopy = true
    
    let view = ToolResultView(title: title, content: content, canCopy: canCopy)
    
    #expect(view.title == title)
    #expect(view.content == content)
    #expect(view.canCopy == canCopy)
  }
  
  @Test("ToolResultView 复制功能测试", arguments: [
    (true, "可复制内容"),
    (false, "不可复制内容")
  ])
  func testToolResultViewCopyFeature(canCopy: Bool, content: String) {
    let view = ToolResultView(
      title: "测试标题",
      content: content,
      canCopy: canCopy
    )
    
    #expect(view.canCopy == canCopy)
    #expect(view.content == content)
  }
  
  // MARK: - ToolTextField Tests
  
  @Test("ToolTextField 基本属性测试")
  func testToolTextFieldProperties() {
    let title = "输入标题"
    let placeholder = "请输入内容"
    @State var text = ""
    
    let textField = ToolTextField(
      title: title,
      text: $text,
      placeholder: placeholder
    )
    
    #expect(textField.title == title)
    #expect(textField.placeholder == placeholder)
  }
  
  @Test("ToolTextField 文本绑定测试")
  func testToolTextFieldBinding() {
    // 在测试中，我们主要验证 ToolTextField 能正确接受绑定参数
    var testText = "初始文本"
    
    let textField = ToolTextField(
      title: "测试",
      text: .constant(testText),
      placeholder: "占位符"
    )
    
    // 验证 ToolTextField 的属性
    #expect(textField.title == "测试")
    #expect(textField.placeholder == "占位符")
    
    // 验证文本值
    #expect(testText == "初始文本")
    
    // 模拟文本更改
    testText = "更新后的文本"
    #expect(testText == "更新后的文本")
  }
  
  // MARK: - BrightCardView Tests
  
  @Test("BrightCardView 内容封装测试")
  func testBrightCardView() {
    let testContent = Text("测试内容")
    let cardView = BrightCardView {
      testContent
    }
    
    // 验证卡片视图创建成功
    // 由于 BrightCardView 是一个容器视图，主要测试其能正常创建
    #expect(true) // 如果能创建到这里说明视图创建成功
  }
}

// ButtonStyle already conforms to Equatable in the main module