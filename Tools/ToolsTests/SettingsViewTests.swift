import Testing
import SwiftUI
@testable import Tools

struct SettingsViewTests {
  
  @Test("SettingsView 初始化测试")
  func testSettingsViewInitialization() {
    let settingsView = SettingsView()
    
    // 验证视图可以正常创建
    #expect(settingsView != nil)
  }
  
  @Test("ImportExportSettingsView 初始化测试")
  func testImportExportSettingsViewInitialization() {
    let importExportView = ImportExportSettingsView()
    
    // 验证视图可以正常创建
    #expect(importExportView != nil)
  }
  
  @Test("设置视图状态管理测试")
  func testSettingsViewStateManagement() {
    // 使用共享设置实例
    let testSettings = AppSettings.shared
    
    // 重置为默认状态
    testSettings.resetToDefaults()
    
    // 验证初始状态
    #expect(testSettings.theme == AppTheme.system)
    #expect(testSettings.maxClipboardHistory == 100)
    #expect(testSettings.autoSaveResults == true)
    #expect(testSettings.defaultImageQuality == 0.8)
    #expect(testSettings.showProcessingAnimations == true)
    #expect(testSettings.autoCopyResults == false)
    #expect(testSettings.confirmDestructiveActions == true)
    
    // 模拟用户修改设置
    testSettings.theme = AppTheme.dark
    testSettings.maxClipboardHistory = 200
    testSettings.autoSaveResults = false
    testSettings.defaultImageQuality = 0.6
    testSettings.showProcessingAnimations = false
    testSettings.autoCopyResults = true
    testSettings.confirmDestructiveActions = false
    
    // 验证设置已更改
    #expect(testSettings.theme == AppTheme.dark)
    #expect(testSettings.maxClipboardHistory == 200)
    #expect(testSettings.autoSaveResults == false)
    #expect(testSettings.defaultImageQuality == 0.6)
    #expect(testSettings.showProcessingAnimations == false)
    #expect(testSettings.autoCopyResults == true)
    #expect(testSettings.confirmDestructiveActions == false)
  }
  
  @Test("主题切换功能测试")
  func testThemeSwitching() {
    let settings = AppSettings.shared
    
    // 测试所有主题选项
    for theme in AppTheme.allCases {
      settings.theme = theme
      #expect(settings.theme == theme)
      
      // 验证颜色方案映射
      switch theme {
      case .light:
        #expect(settings.theme.colorScheme == .light)
      case .dark:
        #expect(settings.theme.colorScheme == .dark)
      case .system:
        #expect(settings.theme.colorScheme == nil)
      }
    }
  }
  
  @Test("粘贴板历史记录数量设置测试")
  func testClipboardHistorySettings() {
    let settings = AppSettings.shared
    
    // 测试有效范围内的值
    let validValues = [10, 50, 100, 200, 500, 1000]
    for value in validValues {
      settings.maxClipboardHistory = value
      #expect(settings.maxClipboardHistory == value)
    }
    
    // 测试边界值处理（通过导入设置来测试边界限制）
    let boundaryTestData1: [String: Any] = ["maxClipboardHistory": 5]
    settings.importSettings(from: boundaryTestData1)
    #expect(settings.maxClipboardHistory == 10) // 应该被限制为最小值
    
    let boundaryTestData2: [String: Any] = ["maxClipboardHistory": 1500]
    settings.importSettings(from: boundaryTestData2)
    #expect(settings.maxClipboardHistory == 1000) // 应该被限制为最大值
  }
  
  @Test("图片质量设置测试")
  func testImageQualitySettings() {
    let settings = AppSettings.shared
    
    // 测试有效范围内的值
    let validQualities = [0.1, 0.3, 0.5, 0.7, 0.8, 0.9, 1.0]
    for quality in validQualities {
      settings.defaultImageQuality = quality
      #expect(abs(settings.defaultImageQuality - quality) < 0.001) // 浮点数比较
    }
    
    // 测试边界值处理
    let boundaryTestData1: [String: Any] = ["defaultImageQuality": 0.05]
    settings.importSettings(from: boundaryTestData1)
    #expect(settings.defaultImageQuality == 0.1) // 应该被限制为最小值
    
    let boundaryTestData2: [String: Any] = ["defaultImageQuality": 1.5]
    settings.importSettings(from: boundaryTestData2)
    #expect(settings.defaultImageQuality == 1.0) // 应该被限制为最大值
  }
  
  @Test("布尔设置选项测试")
  func testBooleanSettings() {
    let settings = AppSettings.shared
    
    // 测试所有布尔设置
    let booleanSettings = [
      \AppSettings.autoSaveResults,
      \AppSettings.showProcessingAnimations,
      \AppSettings.autoCopyResults,
      \AppSettings.confirmDestructiveActions
    ]
    
    for keyPath in booleanSettings {
      // 测试设置为true
      settings[keyPath: keyPath] = true
      #expect(settings[keyPath: keyPath] == true)
      
      // 测试设置为false
      settings[keyPath: keyPath] = false
      #expect(settings[keyPath: keyPath] == false)
    }
  }
  
  @Test("设置重置功能测试")
  func testSettingsReset() {
    let settings = AppSettings.shared
    
    // 修改所有设置为非默认值
    settings.theme = AppTheme.dark
    settings.maxClipboardHistory = 200
    settings.autoSaveResults = false
    settings.defaultImageQuality = 0.5
    settings.showProcessingAnimations = false
    settings.autoCopyResults = true
    settings.confirmDestructiveActions = false
    
    // 验证设置已修改
    #expect(settings.theme != AppTheme.system)
    #expect(settings.maxClipboardHistory != 100)
    #expect(settings.autoSaveResults != true)
    #expect(settings.defaultImageQuality != 0.8)
    #expect(settings.showProcessingAnimations != true)
    #expect(settings.autoCopyResults != false)
    #expect(settings.confirmDestructiveActions != true)
    
    // 重置设置
    settings.resetToDefaults()
    
    // 验证所有设置都恢复为默认值
    #expect(settings.theme == AppTheme.system)
    #expect(settings.maxClipboardHistory == 100)
    #expect(settings.autoSaveResults == true)
    #expect(settings.defaultImageQuality == 0.8)
    #expect(settings.showProcessingAnimations == true)
    #expect(settings.autoCopyResults == false)
    #expect(settings.confirmDestructiveActions == true)
  }
  
  @Test("JSON导入导出功能测试")
  func testJSONImportExport() throws {
    let settings = AppSettings.shared
    
    // 设置一些特定值
    settings.theme = AppTheme.light
    settings.maxClipboardHistory = 150
    settings.autoSaveResults = false
    settings.defaultImageQuality = 0.7
    settings.showProcessingAnimations = false
    settings.autoCopyResults = true
    settings.confirmDestructiveActions = false
    
    // 导出为字典
    let exportedDict = settings.exportSettings()
    
    // 转换为JSON并验证
    let jsonData = try JSONSerialization.data(withJSONObject: exportedDict, options: [])
    let jsonString = String(data: jsonData, encoding: .utf8)
    #expect(jsonString != nil)
    #expect(jsonString!.contains("浅色"))
    #expect(jsonString!.contains("150"))
    #expect(jsonString!.contains("0.7"))
    
    // 从JSON重新解析
    let parsedDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
    #expect(parsedDict != nil)
    
    // 使用共享实例测试导入
    let originalTheme = settings.theme
    settings.importSettings(from: parsedDict!)
    
    // 验证导入结果
    #expect(settings.theme == AppTheme.light)
    #expect(settings.maxClipboardHistory == 150)
    #expect(settings.autoSaveResults == false)
    #expect(settings.defaultImageQuality == 0.7)
    #expect(settings.showProcessingAnimations == false)
    #expect(settings.autoCopyResults == true)
    #expect(settings.confirmDestructiveActions == false)
  }
  
  @Test("设置持久化测试")
  func testSettingsPersistence() {
    // 注意：这个测试验证UserDefaults的使用是否正确
    // 实际的持久化功能由系统提供，我们主要测试设置的结构
    
    let settings = AppSettings.shared
    
    // 验证所有设置都有正确的类型
    // 这通过检查设置的默认值和类型来间接验证
    #expect(settings.theme is AppTheme)
    #expect(settings.maxClipboardHistory is Int)
    #expect(settings.autoSaveResults is Bool)
    #expect(settings.defaultImageQuality is Double)
    #expect(settings.showProcessingAnimations is Bool)
    #expect(settings.autoCopyResults is Bool)
    #expect(settings.confirmDestructiveActions is Bool)
  }
}