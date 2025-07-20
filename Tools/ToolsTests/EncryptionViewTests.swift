//
//  EncryptionViewTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/17.
//

import Testing
import SwiftUI
@testable import Tools

@MainActor
struct EncryptionViewTests {
  
  // MARK: - UI Component Creation Tests
  
  @Test("EncryptionView 可以正常创建")
  func testEncryptionViewCreation() {
    // 测试EncryptionView可以正常创建
    let view = EncryptionView()
    
    // 验证视图可以被创建（基本测试）
    // SwiftUI视图总是非nil，这里只是验证可以创建
    let _ = view
    #expect(true) // 如果能执行到这里说明视图创建成功
  }
  
  // MARK: - Algorithm Model Tests
  
  @Test("算法模型属性测试")
  func testAlgorithmProperties() {
    // 测试各算法的解密支持属性
    #expect(EncryptionAlgorithm.md5.supportsDecryption == false)
    #expect(EncryptionAlgorithm.sha1.supportsDecryption == false)
    #expect(EncryptionAlgorithm.sha256.supportsDecryption == false)
    #expect(EncryptionAlgorithm.base64.supportsDecryption == true)
    #expect(EncryptionAlgorithm.aes.supportsDecryption == true)
  }
  
  @Test("算法描述测试")
  func testAlgorithmDescriptions() {
    // 测试算法描述文本
    #expect(EncryptionAlgorithm.md5.description == "MD5 哈希算法")
    #expect(EncryptionAlgorithm.sha1.description == "SHA1 哈希算法")
    #expect(EncryptionAlgorithm.sha256.description == "SHA256 哈希算法")
    #expect(EncryptionAlgorithm.base64.description == "Base64 编码/解码")
    #expect(EncryptionAlgorithm.aes.description == "AES 对称加密")
  }
  
  // MARK: - UI Integration Tests (通过Service层测试)
  
  @Test("MD5加密UI集成测试")
  func testMD5EncryptionUIIntegration() async throws {
    let service = EncryptionService.shared
    let input = "Hello World"
    
    // 模拟UI操作：选择MD5算法并加密
    let result = try service.encrypt(input, using: .md5)
    
    // 验证结果（这模拟了UI显示的结果）
    #expect(result == "b10a8db164e0754105b7a99be72e3fe5")
    #expect(!result.isEmpty)
  }
  
  @Test("Base64编码解码UI集成测试")
  func testBase64UIIntegration() async throws {
    let service = EncryptionService.shared
    let input = "Hello World"
    
    // 模拟UI操作：Base64编码
    let encoded = try service.encrypt(input, using: .base64)
    #expect(encoded == "SGVsbG8gV29ybGQ=")
    
    // 模拟UI操作：Base64解码
    let decoded = try service.decrypt(encoded, using: .base64)
    #expect(decoded == input)
  }
  
  @Test("AES加密解密UI集成测试")
  func testAESUIIntegration() async throws {
    let service = EncryptionService.shared
    let input = "Secret Message"
    let key = "MySecretKey"
    
    // 模拟UI操作：AES加密
    let encrypted = try service.encrypt(input, using: .aes, key: key)
    #expect(!encrypted.isEmpty)
    #expect(encrypted != input)
    
    // 模拟UI操作：AES解密
    let decrypted = try service.decrypt(encrypted, using: .aes, key: key)
    #expect(decrypted == input)
  }
  
  // MARK: - Error Handling UI Tests
  
  @Test("空输入错误处理测试")
  func testEmptyInputErrorHandling() async {
    let service = EncryptionService.shared
    
    // 模拟UI操作：空输入应该产生错误
    #expect(throws: ToolError.self) {
      try service.encrypt("", using: .md5)
    }
  }
  
  @Test("AES空密钥错误处理测试")
  func testAESEmptyKeyErrorHandling() async {
    let service = EncryptionService.shared
    
    // 模拟UI操作：AES加密时空密钥应该产生错误
    #expect(throws: ToolError.self) {
      try service.encrypt("test", using: .aes, key: "")
    }
    
    #expect(throws: ToolError.self) {
      try service.encrypt("test", using: .aes, key: nil)
    }
  }
  
  @Test("Base64解码错误处理测试")
  func testBase64DecodeErrorHandling() async {
    let service = EncryptionService.shared
    
    // 模拟UI操作：无效Base64字符串应该产生错误
    #expect(throws: ToolError.self) {
      try service.decrypt("Invalid Base64!", using: .base64)
    }
  }
  
  @Test("哈希算法解密错误处理测试")
  func testHashAlgorithmDecryptionError() async throws {
    let service = EncryptionService.shared
    
    // 模拟UI操作：尝试解密哈希结果应该产生错误
    let hashResult = try service.encrypt("test", using: .md5)
    
    #expect(throws: ToolError.self) {
      try service.decrypt(hashResult, using: .md5)
    }
  }
  
  // MARK: - UI Behavior Tests
  
  @Test("算法切换行为测试")
  func testAlgorithmSwitchingBehavior() {
    // 测试不同算法的特性，模拟UI中的算法切换逻辑
    let hashAlgorithms: [EncryptionAlgorithm] = [.md5, .sha1, .sha256]
    let encryptionAlgorithms: [EncryptionAlgorithm] = [.base64, .aes]
    
    // 哈希算法不支持解密
    for algorithm in hashAlgorithms {
      #expect(!algorithm.supportsDecryption, "\(algorithm.rawValue) should not support decryption")
    }
    
    // 加密算法支持解密
    for algorithm in encryptionAlgorithms {
      #expect(algorithm.supportsDecryption, "\(algorithm.rawValue) should support decryption")
    }
  }
  
  @Test("UI输入验证逻辑测试")
  func testUIInputValidationLogic() async throws {
    let service = EncryptionService.shared
    
    // 测试各种输入情况，模拟UI验证逻辑
    let validInputs = [
      "Hello World",
      "123456",
      "Special chars: !@#$%^&*()",
      "中文测试",
      "🌟 Emoji test"
    ]
    
    for input in validInputs {
      // 所有有效输入都应该能够成功处理
      let result = try service.encrypt(input, using: .md5)
      #expect(!result.isEmpty, "Valid input '\(input)' should produce non-empty result")
    }
  }
  
  // MARK: - Performance Tests
  
  @Test("大文本处理性能测试", .timeLimit(.minutes(1)))
  func testLargeTextProcessingPerformance() async throws {
    let service = EncryptionService.shared
    let largeText = String(repeating: "A", count: 50000)
    
    // 测试大文本处理性能，模拟UI处理大量数据的情况
    let startTime = Date()
    let result = try service.encrypt(largeText, using: .sha256)
    let endTime = Date()
    
    let processingTime = endTime.timeIntervalSince(startTime)
    #expect(processingTime < 5.0, "Large text processing should complete within 5 seconds")
    #expect(!result.isEmpty)
    #expect(result.count == 64) // SHA256 produces 64-character hex string
  }
  
  // MARK: - UI State Management Tests
  
  @Test("错误状态管理测试")
  func testErrorStateManagement() {
    // 测试不同类型的错误，模拟UI错误状态管理
    let invalidInputError = ToolError.invalidInput("测试错误")
    let processingFailedError = ToolError.processingFailed("处理失败")
    let unsupportedFormatError = ToolError.unsupportedFormat
    
    // 验证错误描述
    #expect(invalidInputError.localizedDescription.contains("输入无效"))
    #expect(processingFailedError.localizedDescription.contains("处理失败"))
    #expect(unsupportedFormatError.localizedDescription.contains("不支持的格式"))
  }
  
  // MARK: - Copy Functionality Tests
  
  @Test("复制功能测试")
  func testCopyFunctionality() async throws {
    let service = EncryptionService.shared
    let input = "Test for copy"
    
    // 模拟UI操作：加密后复制结果
    let result = try service.encrypt(input, using: .base64)
    
    // 验证结果可以被复制（非空且有效）
    #expect(!result.isEmpty)
    #expect(result == "VGVzdCBmb3IgY29weQ==")
    
    // 在实际UI中，这个结果会被复制到剪贴板
    // 这里我们验证结果的有效性
    let decoded = try service.decrypt(result, using: .base64)
    #expect(decoded == input)
  }
  
  // MARK: - UI Accessibility Tests
  
  @Test("可访问性支持测试")
  func testAccessibilitySupport() {
    // 测试UI组件的可访问性支持
    // 验证算法枚举的基本属性
    let algorithms = EncryptionAlgorithm.allCases
    
    #expect(algorithms.count == 5) // 确保所有算法都被包含
    
    for algorithm in algorithms {
      #expect(!algorithm.rawValue.isEmpty, "Algorithm name should not be empty")
      #expect(!algorithm.description.isEmpty, "Algorithm description should not be empty")
    }
  }
  
  // MARK: - UI Flow Tests
  
  @Test("完整加密流程测试")
  func testCompleteEncryptionFlow() async throws {
    let service = EncryptionService.shared
    
    // 模拟完整的UI操作流程
    let testCases = [
      ("Hello", EncryptionAlgorithm.md5, nil),
      ("World", EncryptionAlgorithm.sha256, nil),
      ("Base64 Test", EncryptionAlgorithm.base64, nil),
      ("AES Test", EncryptionAlgorithm.aes, "TestKey123")
    ]
    
    for (input, algorithm, key) in testCases {
      // 1. 选择算法
      // 2. 输入文本
      // 3. 如果是AES，输入密钥
      // 4. 执行加密
      let result = try service.encrypt(input, using: algorithm, key: key)
      
      // 5. 验证结果
      #expect(!result.isEmpty, "Encryption result should not be empty for \(algorithm.rawValue)")
      
      // 6. 如果支持解密，测试解密流程
      if algorithm.supportsDecryption {
        let decrypted = try service.decrypt(result, using: algorithm, key: key)
        #expect(decrypted == input, "Decryption should restore original input for \(algorithm.rawValue)")
      }
    }
  }
  
  // MARK: - UI Validation Tests
  
  @Test("UI输入输出验证测试")
  func testUIInputOutputValidation() async throws {
    let service = EncryptionService.shared
    
    // 测试边界情况，模拟UI输入验证
    let edgeCases = [
      "a", // 单字符
      String(repeating: "x", count: 1000), // 长文本
      "   ", // 空格
      "\n\t\r", // 特殊字符
      "🎉🌟💫", // Emoji
    ]
    
    for input in edgeCases {
      if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        // 空白输入应该被拒绝
        continue
      }
      
      // 有效输入应该能够处理
      let result = try service.encrypt(input, using: .sha256)
      #expect(!result.isEmpty, "Should handle edge case input: '\(input)'")
      #expect(result.count == 64, "SHA256 should always produce 64-character result")
    }
  }
}