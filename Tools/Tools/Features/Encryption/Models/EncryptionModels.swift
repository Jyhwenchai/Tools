//
//  EncryptionModels.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import Foundation

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
      return false // 哈希算法是单向的
    case .base64, .aes:
      return true
    }
  }
  
  var description: String {
    switch self {
    case .md5:
      return "MD5 哈希算法"
    case .sha1:
      return "SHA1 哈希算法"
    case .sha256:
      return "SHA256 哈希算法"
    case .base64:
      return "Base64 编码/解码"
    case .aes:
      return "AES 对称加密"
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
    self.timestamp = Date()
  }
}