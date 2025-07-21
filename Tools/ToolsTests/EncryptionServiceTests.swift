//
//  EncryptionServiceTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/17.
//

import Testing
@testable import Tools

struct EncryptionServiceTests {
  // MARK: - MD5 Hash Tests

  @Test("MD5 哈希算法测试")
  func mD5Hashing() async throws {
    let service = EncryptionService.shared

    // 测试已知的MD5哈希值
    let testCases = [
      ("Hello World", "b10a8db164e0754105b7a99be72e3fe5"),
      ("The quick brown fox jumps over the lazy dog", "9e107d9d372bb6826bd81d3542a419d6")
    ]

    for (input, expected) in testCases {
      let result = try service.encrypt(input, using: .md5)
      #expect(result == expected, "MD5(\(input)) should be \(expected), got \(result)")
    }

    // 测试Swift的实际MD5值
    let swiftResult = try service.encrypt("Swift", using: .md5)
    #expect(!swiftResult.isEmpty, "MD5 result should not be empty")
    #expect(swiftResult.count == 32, "MD5 hash should be 32 characters long")
  }

  @Test("MD5 空输入测试")
  func mD5EmptyInput() async throws {
    let service = EncryptionService.shared

    #expect(throws: ToolError.self) {
      try service.encrypt("", using: .md5)
    }
  }

  // MARK: - SHA1 Hash Tests

  @Test("SHA1 哈希算法测试")
  func sHA1Hashing() async throws {
    let service = EncryptionService.shared

    let testCases = [
      ("Hello World", "0a4d55a8d778e5022fab701977c5d840bbc486d0"),
      ("The quick brown fox jumps over the lazy dog", "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
    ]

    for (input, expected) in testCases {
      let result = try service.encrypt(input, using: .sha1)
      #expect(result == expected, "SHA1(\(input)) should be \(expected), got \(result)")
    }
  }

  @Test("SHA1 结果长度测试")
  func sHA1Length() async throws {
    let service = EncryptionService.shared
    let result = try service.encrypt("Test", using: .sha1)
    #expect(result.count == 40, "SHA1 hash should be 40 characters long")
  }

  // MARK: - SHA256 Hash Tests

  @Test("SHA256 哈希算法测试")
  func sHA256Hashing() async throws {
    let service = EncryptionService.shared

    let testCases = [
      ("Hello World", "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"),
      (
        "The quick brown fox jumps over the lazy dog",
        "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
    ]

    for (input, expected) in testCases {
      let result = try service.encrypt(input, using: .sha256)
      #expect(result == expected, "SHA256(\(input)) should be \(expected), got \(result)")
    }
  }

  @Test("SHA256 结果长度测试")
  func sHA256Length() async throws {
    let service = EncryptionService.shared
    let result = try service.encrypt("Test", using: .sha256)
    #expect(result.count == 64, "SHA256 hash should be 64 characters long")
  }

  // MARK: - Base64 Encoding/Decoding Tests

  @Test("Base64 编码解码测试", arguments: [
    ("Hello", "SGVsbG8="),
    ("World", "V29ybGQ="),
    ("Swift", "U3dpZnQ="),
    ("The quick brown fox", "VGhlIHF1aWNrIGJyb3duIGZveA=="),
    ("", "")
  ])
  func base64Encoding(input: String, expected: String) throws {
    let service = EncryptionService.shared

    if input.isEmpty {
      #expect(throws: ToolError.self) {
        try service.encrypt(input, using: .base64)
      }
      return
    }

    let encoded = try service.encrypt(input, using: .base64)
    #expect(encoded == expected, "Base64(\(input)) should be \(expected), got \(encoded)")

    let decoded = try service.decrypt(encoded, using: .base64)
    #expect(decoded == input, "Base64 decode should return original input")
  }

  @Test("Base64 解码无效输入测试")
  func base64InvalidDecoding() async throws {
    let service = EncryptionService.shared

    let invalidInputs = [
      "Invalid Base64!",
      "SGVsbG8", // 缺少填充
      "12345"
    ]

    for invalidInput in invalidInputs {
      #expect(throws: ToolError.self) {
        try service.decrypt(invalidInput, using: .base64)
      }
    }
  }

  // MARK: - AES Encryption/Decryption Tests

  @Test("AES 加密解密测试")
  func aESEncryptionDecryption() async throws {
    let service = EncryptionService.shared
    let plaintext = "Hello, AES Encryption!"
    let key = "MySecretKey123"

    let encrypted = try service.encrypt(plaintext, using: .aes, key: key)
    #expect(!encrypted.isEmpty, "Encrypted text should not be empty")
    #expect(encrypted != plaintext, "Encrypted text should be different from plaintext")

    let decrypted = try service.decrypt(encrypted, using: .aes, key: key)
    #expect(decrypted == plaintext, "Decrypted text should match original plaintext")
  }

  @Test("AES 不同密钥测试")
  func aESDifferentKeys() async throws {
    let service = EncryptionService.shared
    let plaintext = "Secret Message"
    let key1 = "Key1"
    let key2 = "Key2"

    let encrypted1 = try service.encrypt(plaintext, using: .aes, key: key1)
    let encrypted2 = try service.encrypt(plaintext, using: .aes, key: key2)

    #expect(encrypted1 != encrypted2, "Different keys should produce different encrypted results")

    // 用错误的密钥解密应该失败
    #expect(throws: ToolError.self) {
      try service.decrypt(encrypted1, using: .aes, key: key2)
    }
  }

  @Test("AES 空密钥测试")
  func aESEmptyKey() async throws {
    let service = EncryptionService.shared
    let plaintext = "Test"

    #expect(throws: ToolError.self) {
      try service.encrypt(plaintext, using: .aes, key: "")
    }

    #expect(throws: ToolError.self) {
      try service.encrypt(plaintext, using: .aes, key: nil)
    }
  }

  @Test("AES 长文本测试")
  func aESLongText() async throws {
    let service = EncryptionService.shared
    let longText = String(repeating: "This is a long text for testing AES encryption. ", count: 100)
    let key = "LongTextTestKey"

    let encrypted = try service.encrypt(longText, using: .aes, key: key)
    let decrypted = try service.decrypt(encrypted, using: .aes, key: key)

    #expect(decrypted == longText, "Long text should be encrypted and decrypted correctly")
  }

  @Test("AES 特殊字符测试")
  func aESSpecialCharacters() async throws {
    let service = EncryptionService.shared
    let specialText = "Hello! 你好 🌟 @#$%^&*()_+-=[]{}|;':\",./<>?"
    let key = "SpecialCharKey"

    let encrypted = try service.encrypt(specialText, using: .aes, key: key)
    let decrypted = try service.decrypt(encrypted, using: .aes, key: key)

    #expect(decrypted == specialText, "Special characters should be handled correctly")
  }

  // MARK: - Hash Algorithm Decryption Tests

  @Test("哈希算法不支持解密测试")
  func hashAlgorithmsNoDecryption() async throws {
    let service = EncryptionService.shared
    let hashAlgorithms: [EncryptionAlgorithm] = [.md5, .sha1, .sha256]

    for algorithm in hashAlgorithms {
      let encrypted = try service.encrypt("test", using: algorithm)

      #expect(throws: ToolError.self) {
        try service.decrypt(encrypted, using: algorithm)
      }
    }
  }

  // MARK: - Empty Input Tests

  @Test("空输入测试")
  func emptyInputs() async throws {
    let service = EncryptionService.shared
    let algorithms: [EncryptionAlgorithm] = [.md5, .sha1, .sha256, .base64, .aes]

    for algorithm in algorithms {
      #expect(throws: ToolError.self) {
        if algorithm == .aes {
          try service.encrypt("", using: algorithm, key: "testkey")
        } else {
          try service.encrypt("", using: algorithm)
        }
      }
    }
  }

  // MARK: - Algorithm Support Tests

  @Test("算法支持解密属性测试")
  func algorithmDecryptionSupport() {
    #expect(EncryptionAlgorithm.md5.supportsDecryption == false)
    #expect(EncryptionAlgorithm.sha1.supportsDecryption == false)
    #expect(EncryptionAlgorithm.sha256.supportsDecryption == false)
    #expect(EncryptionAlgorithm.base64.supportsDecryption == true)
    #expect(EncryptionAlgorithm.aes.supportsDecryption == true)
  }

  // MARK: - Performance Tests

  @Test("大文件加密性能测试", .timeLimit(.minutes(1)))
  func largeFileEncryptionPerformance() async throws {
    let service = EncryptionService.shared
    let largeText = String(repeating: "A", count: 100_000)

    // 测试SHA256性能
    let sha256Result = try service.encrypt(largeText, using: .sha256)
    #expect(!sha256Result.isEmpty)

    // 测试AES性能
    let aesEncrypted = try service.encrypt(largeText, using: .aes, key: "PerformanceTestKey")
    let aesDecrypted = try service.decrypt(aesEncrypted, using: .aes, key: "PerformanceTestKey")
    #expect(aesDecrypted == largeText)
  }
}
