import Testing
@testable import Tools

struct AppSettingsTests {
  
  // MARK: - AppTheme Tests
  
  @Test("AppTheme 颜色方案映射测试")
  func testAppThemeColorScheme() {
    #expect(AppTheme.light.colorScheme == .light)
    #expect(AppTheme.dark.colorScheme == .dark)
    #expect(AppTheme.system.colorScheme == nil)
  }
  
  @Test("AppTheme 系统图标测试")
  func testAppThemeSystemImages() {
    #expect(AppTheme.light.systemImage == "sun.max")
    #expect(AppTheme.dark.systemImage == "moon")
    #expect(AppTheme.system.systemImage == "circle.lefthalf.filled")
  }
  
  @Test("AppTheme 原始值测试")
  func testAppThemeRawValues() {
    #expect(AppTheme.light.rawValue == "浅色")
    #expect(AppTheme.dark.rawValue == "深色")
    #expect(AppTheme.system.rawValue == "跟随系统")
  }
  
  // MARK: - AppSettings Tests
  
  @Test("AppSettings 默认值测试")
  func testAppSettingsDefaults() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    #expect(settings.theme == AppTheme.system)
    #expect(settings.maxClipboardHistory == 100)
    #expect(settings.autoSaveResults == true)
    #expect(settings.defaultImageQuality == 0.8)
    #expect(settings.showProcessingAnimations == true)
    #expect(settings.autoCopyResults == false)
    #expect(settings.confirmDestructiveActions == true)
  }
  
  @Test("AppSettings 重置为默认值测试")
  func testResetToDefaults() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    // 修改设置
    settings.theme = AppTheme.dark
    settings.maxClipboardHistory = 200
    settings.autoSaveResults = false
    settings.defaultImageQuality = 0.5
    settings.showProcessingAnimations = false
    settings.autoCopyResults = true
    settings.confirmDestructiveActions = false
    
    // 重置为默认值
    settings.resetToDefaults()
    
    // 验证重置结果
    #expect(settings.theme == AppTheme.system)
    #expect(settings.maxClipboardHistory == 100)
    #expect(settings.autoSaveResults == true)
    #expect(settings.defaultImageQuality == 0.8)
    #expect(settings.showProcessingAnimations == true)
    #expect(settings.autoCopyResults == false)
    #expect(settings.confirmDestructiveActions == true)
  }
  
  @Test("AppSettings 导出设置测试")
  func testExportSettings() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    settings.theme = AppTheme.dark
    settings.maxClipboardHistory = 150
    settings.autoSaveResults = false
    settings.defaultImageQuality = 0.6
    settings.showProcessingAnimations = false
    settings.autoCopyResults = true
    settings.confirmDestructiveActions = false
    
    let exported = settings.exportSettings()
    
    #expect(exported["theme"] as? String == "深色")
    #expect(exported["maxClipboardHistory"] as? Int == 150)
    #expect(exported["autoSaveResults"] as? Bool == false)
    #expect(exported["defaultImageQuality"] as? Double == 0.6)
    #expect(exported["showProcessingAnimations"] as? Bool == false)
    #expect(exported["autoCopyResults"] as? Bool == true)
    #expect(exported["confirmDestructiveActions"] as? Bool == false)
  }
  
  @Test("AppSettings 导入设置测试")
  func testImportSettings() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    let importData: [String: Any] = [
      "theme": "浅色",
      "maxClipboardHistory": 250,
      "autoSaveResults": false,
      "defaultImageQuality": 0.9,
      "showProcessingAnimations": false,
      "autoCopyResults": true,
      "confirmDestructiveActions": false
    ]
    
    settings.importSettings(from: importData)
    
    #expect(settings.theme == AppTheme.light)
    #expect(settings.maxClipboardHistory == 250)
    #expect(settings.autoSaveResults == false)
    #expect(settings.defaultImageQuality == 0.9)
    #expect(settings.showProcessingAnimations == false)
    #expect(settings.autoCopyResults == true)
    #expect(settings.confirmDestructiveActions == false)
  }
  
  @Test("AppSettings 导入无效数据测试")
  func testImportInvalidSettings() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    let originalTheme = settings.theme
    let originalMaxHistory = settings.maxClipboardHistory
    let originalImageQuality = settings.defaultImageQuality
    
    let invalidData: [String: Any] = [
      "theme": "无效主题",
      "maxClipboardHistory": -50, // 应该被限制在10-1000范围内
      "defaultImageQuality": 2.0, // 应该被限制在0.1-1.0范围内
      "invalidKey": "invalidValue"
    ]
    
    settings.importSettings(from: invalidData)
    
    // 无效的主题应该保持原值
    #expect(settings.theme == originalTheme)
    
    // 无效的历史记录数量应该被限制
    #expect(settings.maxClipboardHistory >= 10)
    #expect(settings.maxClipboardHistory <= 1000)
    
    // 无效的图片质量应该被限制
    #expect(settings.defaultImageQuality >= 0.1)
    #expect(settings.defaultImageQuality <= 1.0)
  }
  
  @Test("AppSettings 边界值测试")
  func testSettingsBoundaryValues() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    // 测试粘贴板历史记录边界值
    let boundaryData1: [String: Any] = [
      "maxClipboardHistory": 5 // 小于最小值10
    ]
    settings.importSettings(from: boundaryData1)
    #expect(settings.maxClipboardHistory == 10)
    
    let boundaryData2: [String: Any] = [
      "maxClipboardHistory": 1500 // 大于最大值1000
    ]
    settings.importSettings(from: boundaryData2)
    #expect(settings.maxClipboardHistory == 1000)
    
    // 测试图片质量边界值
    let boundaryData3: [String: Any] = [
      "defaultImageQuality": 0.05 // 小于最小值0.1
    ]
    settings.importSettings(from: boundaryData3)
    #expect(settings.defaultImageQuality == 0.1)
    
    let boundaryData4: [String: Any] = [
      "defaultImageQuality": 1.5 // 大于最大值1.0
    ]
    settings.importSettings(from: boundaryData4)
    #expect(settings.defaultImageQuality == 1.0)
  }
  
  @Test("AppSettings 单例模式测试")
  func testSingletonPattern() {
    let settings1 = AppSettings.shared
    let settings2 = AppSettings.shared
    
    // 验证是同一个实例
    #expect(settings1 === settings2)
    
    // 修改一个实例的值，另一个实例也应该改变
    settings1.theme = .dark
    #expect(settings2.theme == .dark)
  }
  
  @Test("AppSettings 完整导入导出循环测试")
  func testCompleteImportExportCycle() {
    let settings = AppSettings.shared
    settings.clearAllSettings()
    
    // 设置一些特定值
    settings.theme = AppTheme.light
    settings.maxClipboardHistory = 75
    settings.autoSaveResults = false
    settings.defaultImageQuality = 0.7
    settings.showProcessingAnimations = false
    settings.autoCopyResults = true
    settings.confirmDestructiveActions = false
    
    // 导出设置
    let exportedData = settings.exportSettings()
    
    // 重置设置然后导入
    settings.resetToDefaults()
    settings.importSettings(from: exportedData)
    
    // 验证所有值都正确导入
    #expect(settings.theme == AppTheme.light)
    #expect(settings.maxClipboardHistory == 75)
    #expect(settings.autoSaveResults == false)
    #expect(settings.defaultImageQuality == 0.7)
    #expect(settings.showProcessingAnimations == false)
    #expect(settings.autoCopyResults == true)
    #expect(settings.confirmDestructiveActions == false)
  }
}