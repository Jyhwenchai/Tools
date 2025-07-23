//
//  EncryptionModels.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import Foundation

// MARK: - Extensible Algorithm Protocol

protocol CryptographicAlgorithm: Equatable, Hashable {
  var identifier: String { get }
  var displayName: String { get }
  var description: String { get }
  var category: AlgorithmCategory { get }
  var supportsDecryption: Bool { get }
  var requiresKey: Bool { get }
  var keyRequirements: KeyRequirements? { get }
  
  func encrypt(_ data: String, key: String?) throws -> String
  func decrypt(_ data: String, key: String?) throws -> String
  func validate(input: String, key: String?) throws
}

// MARK: - Default Implementations for Protocol Conformance

extension CryptographicAlgorithm {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }
}

enum AlgorithmCategory: String, CaseIterable {
  case hash = "哈希算法"
  case symmetric = "对称加密"
  case encoding = "编码算法"
  
  var icon: String {
    switch self {
    case .hash: "number.square"
    case .symmetric: "lock.shield"
    case .encoding: "textformat"
    }
  }
}

struct KeyRequirements {
  let minLength: Int
  let maxLength: Int?
  let allowedCharacters: CharacterSet?
  let strengthRequirement: KeyStrength
}

enum KeyStrength: String, CaseIterable {
  case none = "无要求"
  case low = "低"
  case medium = "中等"
  case high = "高"
}

// MARK: - Legacy Enum for Compatibility

enum EncryptionAlgorithm: String, CaseIterable, Identifiable {
  case md5 = "MD5"
  case sha1 = "SHA1"
  case sha256 = "SHA256"
  case base64 = "Base64"
  case aes = "AES"

  var id: String { rawValue }

  var supportsDecryption: Bool {
    switch self {
    case .md5, .sha1, .sha256:
      false // 哈希算法是单向的
    case .base64, .aes:
      true
    }
  }

  var description: String {
    switch self {
    case .md5:
      "MD5 哈希算法"
    case .sha1:
      "SHA1 哈希算法"
    case .sha256:
      "SHA256 哈希算法"
    case .base64:
      "Base64 编码/解码"
    case .aes:
      "AES 对称加密"
    }
  }
  
  var category: AlgorithmCategory {
    switch self {
    case .md5, .sha1, .sha256:
      .hash
    case .base64:
      .encoding
    case .aes:
      .symmetric
    }
  }
}

struct EncryptionResult {
  let algorithm: EncryptionAlgorithm
  let input: String
  let output: String
  let isEncryption: Bool
  let timestamp: Date

  init(algorithm: EncryptionAlgorithm, input: String, output: String, isEncryption: Bool) {
    self.algorithm = algorithm
    self.input = input
    self.output = output
    self.isEncryption = isEncryption
    timestamp = Date()
  }
}

// MARK: - Algorithm Registry

@Observable
class AlgorithmRegistry {
  static let shared = AlgorithmRegistry()
  
  private(set) var availableAlgorithms: [any CryptographicAlgorithm] = []
  
  private init() {
    registerDefaultAlgorithms()
  }
  
  func register(_ algorithm: any CryptographicAlgorithm) {
    if !availableAlgorithms.contains(where: { $0.identifier == algorithm.identifier }) {
      availableAlgorithms.append(algorithm)
    }
  }
  
  func unregister(identifier: String) {
    availableAlgorithms.removeAll { $0.identifier == identifier }
  }
  
  func algorithm(for identifier: String) -> (any CryptographicAlgorithm)? {
    availableAlgorithms.first { $0.identifier == identifier }
  }
  
  func algorithms(in category: AlgorithmCategory) -> [any CryptographicAlgorithm] {
    availableAlgorithms.filter { $0.category == category }
  }
  
  private func registerDefaultAlgorithms() {
    // Register built-in algorithms
    register(MD5Algorithm())
    register(SHA1Algorithm())
    register(SHA256Algorithm())
    register(Base64Algorithm())
    register(AESAlgorithm())
  }
}

// MARK: - Built-in Algorithm Implementations

struct MD5Algorithm: CryptographicAlgorithm {
  let identifier = "md5"
  let displayName = "MD5"
  let description = "MD5 哈希算法"
  let category: AlgorithmCategory = .hash
  let supportsDecryption = false
  let requiresKey = false
  let keyRequirements: KeyRequirements? = nil
  
  func encrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.encrypt(data, using: .md5, key: key)
  }
  
  func decrypt(_ data: String, key: String?) throws -> String {
    throw ToolError.processingFailed("MD5 是单向哈希算法，不支持解密")
  }
  
  func validate(input: String, key: String?) throws {
    guard !input.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }
  }
}

struct SHA1Algorithm: CryptographicAlgorithm {
  let identifier = "sha1"
  let displayName = "SHA1"
  let description = "SHA1 哈希算法"
  let category: AlgorithmCategory = .hash
  let supportsDecryption = false
  let requiresKey = false
  let keyRequirements: KeyRequirements? = nil
  
  func encrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.encrypt(data, using: .sha1, key: key)
  }
  
  func decrypt(_ data: String, key: String?) throws -> String {
    throw ToolError.processingFailed("SHA1 是单向哈希算法，不支持解密")
  }
  
  func validate(input: String, key: String?) throws {
    guard !input.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }
  }
}

struct SHA256Algorithm: CryptographicAlgorithm {
  let identifier = "sha256"
  let displayName = "SHA256"
  let description = "SHA256 哈希算法"
  let category: AlgorithmCategory = .hash
  let supportsDecryption = false
  let requiresKey = false
  let keyRequirements: KeyRequirements? = nil
  
  func encrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.encrypt(data, using: .sha256, key: key)
  }
  
  func decrypt(_ data: String, key: String?) throws -> String {
    throw ToolError.processingFailed("SHA256 是单向哈希算法，不支持解密")
  }
  
  func validate(input: String, key: String?) throws {
    guard !input.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }
  }
}

struct Base64Algorithm: CryptographicAlgorithm {
  let identifier = "base64"
  let displayName = "Base64"
  let description = "Base64 编码/解码"
  let category: AlgorithmCategory = .encoding
  let supportsDecryption = true
  let requiresKey = false
  let keyRequirements: KeyRequirements? = nil
  
  func encrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.encrypt(data, using: .base64, key: key)
  }
  
  func decrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.decrypt(data, using: .base64, key: key)
  }
  
  func validate(input: String, key: String?) throws {
    guard !input.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }
  }
}

struct AESAlgorithm: CryptographicAlgorithm {
  let identifier = "aes"
  let displayName = "AES"
  let description = "AES 对称加密"
  let category: AlgorithmCategory = .symmetric
  let supportsDecryption = true
  let requiresKey = true
  let keyRequirements: KeyRequirements? = KeyRequirements(
    minLength: 8,
    maxLength: nil,
    allowedCharacters: nil,
    strengthRequirement: .medium
  )
  
  func encrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.encrypt(data, using: .aes, key: key)
  }
  
  func decrypt(_ data: String, key: String?) throws -> String {
    try EncryptionService.shared.decrypt(data, using: .aes, key: key)
  }
  
  func validate(input: String, key: String?) throws {
    guard !input.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }
    
    guard let key, !key.isEmpty else {
      throw ToolError.invalidInput("AES加密需要提供密钥")
    }
    
    if let requirements = keyRequirements {
      guard key.count >= requirements.minLength else {
        throw ToolError.invalidInput("密钥长度至少需要 \(requirements.minLength) 个字符")
      }
    }
  }
}