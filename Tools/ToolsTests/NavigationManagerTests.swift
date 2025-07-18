//
//  NavigationManagerTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/17.
//

import Testing

@testable import Tools

struct NavigationManagerTests {

    @Test("导航管理器初始化测试")
    func testNavigationManagerInitialization() {
        let manager = NavigationManager()
        #expect(manager.selectedTool == .encryption)
    }

    @Test("导航状态切换测试")
    func testNavigationStateChanges() {
        let manager = NavigationManager()

        // 测试切换到JSON工具
        manager.selectedTool = .json
        #expect(manager.selectedTool == .json)

        // 测试切换到图片处理工具
        manager.selectedTool = .imageProcessing
        #expect(manager.selectedTool == .imageProcessing)

        // 测试切换到二维码工具
        manager.selectedTool = .qrCode
        #expect(manager.selectedTool == .qrCode)
    }

    @Test(
        "工具类型属性测试",
        arguments: [
            (NavigationManager.ToolType.encryption, "lock.shield", "加密解密", "文本加密解密工具"),
            (NavigationManager.ToolType.json, "doc.text", "JSON工具", "JSON格式化和处理"),
            (NavigationManager.ToolType.imageProcessing, "photo", "图片处理", "图片压缩和处理"),
            (NavigationManager.ToolType.qrCode, "qrcode", "二维码", "二维码生成和识别"),
            (NavigationManager.ToolType.timeConverter, "clock", "时间转换", "时间格式转换"),
            (NavigationManager.ToolType.clipboard, "doc.on.clipboard", "粘贴板", "粘贴板历史管理"),
        ])
    func testToolTypeProperties(
        toolType: NavigationManager.ToolType,
        expectedIcon: String,
        expectedName: String,
        expectedDescription: String
    ) {
        #expect(toolType.icon == expectedIcon)
        #expect(toolType.name == expectedName)
        #expect(toolType.description == expectedDescription)
        #expect(toolType.id == expectedName)
    }

    @Test("工具类型枚举完整性测试")
    func testToolTypeEnumCompleteness() {
        let allCases = NavigationManager.ToolType.allCases
        #expect(allCases.count == 6)

        let expectedTools: [NavigationManager.ToolType] = [
            .encryption, .json, .imageProcessing, .qrCode, .timeConverter, .clipboard,
        ]

        for expectedTool in expectedTools {
            #expect(allCases.contains(expectedTool))
        }
    }
}
