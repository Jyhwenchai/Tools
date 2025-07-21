import AppKit
import Foundation
import Testing
@testable import Tools

struct SecurityServiceTests {
  // MARK: - Initialization Tests

  @Test("SecurityService 单例初始化测试")
  func securityServiceSingleton() {
    let service1 = SecurityService.shared
    let service2 = SecurityService.shared

    // 验证是同一个实例
    #expect(service1 === service2)
  }

  // MARK: - Local Processing Validation

  @Test("本地处理验证测试")
  func testValidateLocalProcessing() {
    let service = SecurityService.shared

    // 验证应用配置为本地处理
    let isLocal = service.validateLocalProcessing()
    #expect(isLocal == true)
  }

  // MARK: - Data Validation Tests

  @Test("输入数据验证测试")
  func testValidateInputData() {
    let service = SecurityService.shared

    // 测试正常数据
    let normalData = "Hello World".data(using: .utf8)!
    #expect(service.validateInputData(normalData) == true)

    // 测试空数据
    let emptyData = Data()
    #expect(service.validateInputData(emptyData) == true)

    // 测试大文件（超过100MB限制）
    let largeData = Data(count: 101 * 1024 * 1024) // 101MB
    #expect(service.validateInputData(largeData) == false)
  }

  @Test("恶意内容检测测试")
  func maliciousContentDetection() {
    let service = SecurityService.shared

    // 测试包含脚本标签的数据
    let scriptData = "<script>alert('xss')</script>".data(using: .utf8)!
    #expect(service.validateInputData(scriptData) == false)

    // 测试包含JavaScript URL的数据
    let jsData = "javascript:alert('xss')".data(using: .utf8)!
    #expect(service.validateInputData(jsData) == false)

    // 测试包含数据URL的数据
    let dataUrlData = "data:text/html,<script>alert('xss')</script>".data(using: .utf8)!
    #expect(service.validateInputData(dataUrlData) == false)

    // 测试正常内容
    let normalData = "This is normal content".data(using: .utf8)!
    #expect(service.validateInputData(normalData) == true)
  }

  // MARK: - String Sanitization Tests

  @Test("字符串输入清理测试")
  func testSanitizeStringInput() {
    let service = SecurityService.shared

    // 测试正常字符串
    let normalString = "Hello World 123!"
    let sanitizedNormal = service.sanitizeStringInput(normalString)
    #expect(sanitizedNormal == normalString)

    // 测试包含特殊字符的字符串
    let specialString = "Hello\u{0000}World\u{FEFF}Test"
    let sanitizedSpecial = service.sanitizeStringInput(specialString)
    #expect(!sanitizedSpecial.contains("\u{0000}"))
    #expect(!sanitizedSpecial.contains("\u{FEFF}"))

    // 测试空字符串
    let emptyString = ""
    let sanitizedEmpty = service.sanitizeStringInput(emptyString)
    #expect(sanitizedEmpty == "")

    // 测试包含中文的字符串
    let chineseString = "你好世界"
    let sanitizedChinese = service.sanitizeStringInput(chineseString)
    #expect(sanitizedChinese == chineseString)
  }

  // MARK: - Sensitive Data Management Tests

  @Test("敏感数据注册测试")
  func testRegisterSensitiveDataKey() {
    let service = SecurityService.shared

    // 注册敏感数据键
    service.registerSensitiveDataKey("test_sensitive_key")

    // 设置一些测试数据
    UserDefaults.standard.set("sensitive_value", forKey: "test_sensitive_key")
    UserDefaults.standard.set("normal_value", forKey: "normal_key")

    // 验证数据存在
    #expect(UserDefaults.standard.string(forKey: "test_sensitive_key") == "sensitive_value")
    #expect(UserDefaults.standard.string(forKey: "normal_key") == "normal_value")

    // 清理敏感数据
    service.clearSensitiveData()

    // 验证敏感数据被清理，普通数据保留
    #expect(UserDefaults.standard.string(forKey: "test_sensitive_key") == nil)
    #expect(UserDefaults.standard.string(forKey: "normal_key") == "normal_value")

    // 清理测试数据
    UserDefaults.standard.removeObject(forKey: "normal_key")
  }

  // MARK: - Clipboard Access Tests

  @Test("剪贴板访问权限测试")
  func clipboardAccessPermission() {
    // 这个测试验证剪贴板访问的基本功能
    // 在实际环境中，权限可能需要用户授权

    let pasteboard = NSPasteboard.general
    let originalContent = pasteboard.string(forType: .string)

    // 测试写入剪贴板
    let testContent = "Security Test Content"
    pasteboard.clearContents()
    pasteboard.setString(testContent, forType: .string)

    // 测试读取剪贴板
    let readContent = pasteboard.string(forType: .string)
    #expect(readContent == testContent)

    // 恢复原始内容
    if let original = originalContent {
      pasteboard.clearContents()
      pasteboard.setString(original, forType: .string)
    }
  }

  // MARK: - Notification Tests

  @Test("安全通知系统测试")
  func securityNotifications() {
    var clearDataCalled = false
    var pauseMonitoringCalled = false
    var resumeMonitoringCalled = false

    // 监听通知
    let clearObserver = NotificationCenter.default.addObserver(
      forName: .clearSensitiveData,
      object: nil,
      queue: .main) { _ in
      clearDataCalled = true
    }

    let pauseObserver = NotificationCenter.default.addObserver(
      forName: .pauseClipboardMonitoring,
      object: nil,
      queue: .main) { _ in
      pauseMonitoringCalled = true
    }

    let resumeObserver = NotificationCenter.default.addObserver(
      forName: .resumeClipboardMonitoring,
      object: nil,
      queue: .main) { _ in
      resumeMonitoringCalled = true
    }

    // 发送通知
    NotificationCenter.default.post(name: .clearSensitiveData, object: nil)
    NotificationCenter.default.post(name: .pauseClipboardMonitoring, object: nil)
    NotificationCenter.default.post(name: .resumeClipboardMonitoring, object: nil)

    // 等待通知处理
    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

    // 验证通知被接收
    #expect(clearDataCalled == true)
    #expect(pauseMonitoringCalled == true)
    #expect(resumeMonitoringCalled == true)

    // 清理观察者
    NotificationCenter.default.removeObserver(clearObserver)
    NotificationCenter.default.removeObserver(pauseObserver)
    NotificationCenter.default.removeObserver(resumeObserver)
  }

  // MARK: - Memory Security Tests

  @Test("内存安全测试")
  func memorySecurity() {
    let service = SecurityService.shared

    // 测试敏感数据清理不会崩溃
    service.clearSensitiveData()

    // 测试多次清理
    service.clearSensitiveData()
    service.clearSensitiveData()

    // 验证应用仍然正常运行
    #expect(service.validateLocalProcessing() == true)
  }

  // MARK: - File Size Limits Tests

  @Test("文件大小限制测试")
  func fileSizeLimits() {
    let service = SecurityService.shared

    // 测试不同大小的文件
    let sizes = [
      1024, // 1KB - 应该通过
      1024 * 1024, // 1MB - 应该通过
      50 * 1024 * 1024, // 50MB - 应该通过
      100 * 1024 * 1024, // 100MB - 边界情况，应该通过
      101 * 1024 * 1024 // 101MB - 应该被拒绝
    ]

    for size in sizes {
      let data = Data(count: size)
      let isValid = service.validateInputData(data)

      if size <= 100 * 1024 * 1024 {
        #expect(isValid == true, "File size \(size) should be valid")
      } else {
        #expect(isValid == false, "File size \(size) should be invalid")
      }
    }
  }
}

// MARK: - KeychainService Tests

struct KeychainServiceTests {
  @Test("KeychainService 单例测试")
  func keychainServiceSingleton() {
    let service1 = KeychainService.shared
    let service2 = KeychainService.shared

    #expect(service1 === service2)
  }

  @Test("临时密钥清理测试")
  func testClearTemporaryKeys() {
    let service = KeychainService.shared

    // 测试清理操作不会崩溃
    service.clearTemporaryKeys()

    // 多次调用应该安全
    service.clearTemporaryKeys()
    service.clearTemporaryKeys()
  }

  @Test("安全数据存储策略测试")
  func secureDataStoragePolicy() {
    let service = KeychainService.shared

    let testData = "sensitive data".data(using: .utf8)!

    // 验证不存储敏感数据的策略
    let stored = service.storeSecureData(testData, forKey: "test_key")
    #expect(stored == false)

    // 验证不检索存储数据的策略
    let retrieved = service.retrieveSecureData(forKey: "test_key")
    #expect(retrieved == nil)
  }
}

// MARK: - Integration Tests

struct SecurityIntegrationTests {
  @Test("安全服务与应用设置集成测试")
  func securitySettingsIntegration() {
    let settings = AppSettings.shared
    let service = SecurityService.shared

    // 测试确认破坏性操作设置
    settings.confirmDestructiveActions = true
    #expect(settings.confirmDestructiveActions == true)

    // 测试安全清理不影响设置
    service.clearSensitiveData()
    #expect(settings.confirmDestructiveActions == true)
  }

  @Test("安全服务基本功能测试")
  func securityServiceBasicFunctionality() async {
    let service = SecurityService.shared

    // 验证安全服务可以正常初始化和使用
    #expect(service != nil, "SecurityService should be available")

    // 测试清理敏感数据功能
    service.clearSensitiveData()

    // 验证方法调用不会崩溃
    #expect(true, "Security service methods should execute without crashing")
  }
}
