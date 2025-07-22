//
//  EncryptionService.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import CommonCrypto
import CryptoKit
import Foundation

class EncryptionService {
  static let shared = EncryptionService()

  private init() {}

  // MARK: - Public Methods

  func encrypt(
    _ text: String,
    using algorithm: EncryptionAlgorithm,
    key: String? = nil) throws -> String {
    guard !text.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }

    switch algorithm {
    case .md5:
      return try hashMD5(text)
    case .sha1:
      return try hashSHA1(text)
    case .sha256:
      return try hashSHA256(text)
    case .base64:
      return try encodeBase64(text)
    case .aes:
      guard let key, !key.isEmpty else {
        throw ToolError.invalidInput("AES加密需要提供密钥")
      }
      return try encryptAES(text, key: key)
    }
  }

  func decrypt(
    _ text: String,
    using algorithm: EncryptionAlgorithm,
    key: String? = nil) throws -> String {
    guard !text.isEmpty else {
      throw ToolError.invalidInput("输入文本不能为空")
    }

    guard algorithm.supportsDecryption else {
      throw ToolError.processingFailed("\(algorithm.rawValue) 是单向哈希算法，不支持解密")
    }

    switch algorithm {
    case .base64:
      return try decodeBase64(text)
    case .aes:
      guard let key, !key.isEmpty else {
        throw ToolError.invalidInput("AES解密需要提供密钥")
      }
      return try decryptAES(text, key: key)
    default:
      throw ToolError.processingFailed("不支持的解密算法")
    }
  }
}

// MARK: - Private Helper Methods

private extension EncryptionService {
  func textToData(_ text: String) throws -> Data {
    guard let data = text.data(using: .utf8) else {
      throw ToolError.processingFailed("文本编码失败")
    }
    return data
  }
}

// MARK: - Private Hash Methods

private extension EncryptionService {
  func hashMD5(_ text: String) throws -> String {
    let data = try textToData(text)
    let digest = Insecure.MD5.hash(data: data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
  }

  func hashSHA1(_ text: String) throws -> String {
    let data = try textToData(text)
    let digest = Insecure.SHA1.hash(data: data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
  }

  func hashSHA256(_ text: String) throws -> String {
    let data = try textToData(text)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
  }
}

// MARK: - Private Base64 Methods

private extension EncryptionService {
  func encodeBase64(_ text: String) throws -> String {
    let data = try textToData(text)
    return data.base64EncodedString()
  }

  func decodeBase64(_ text: String) throws -> String {
    guard let data = Data(base64Encoded: text) else {
      throw ToolError.invalidInput("无效的Base64编码")
    }

    guard let result = String(data: data, encoding: .utf8) else {
      throw ToolError.processingFailed("Base64解码失败")
    }

    return result
  }
}

// MARK: - Private AES Methods

private extension EncryptionService {
  func encryptAES(_ text: String, key: String) throws -> String {
    let textData = try textToData(text)

    // 从提供的密钥字符串创建256位密钥
    let keyData = try createAESKey(from: key)

    // 生成随机IV
    let iv = AES.GCM.Nonce()

    do {
      let sealedBox = try AES.GCM.seal(textData, using: SymmetricKey(data: keyData), nonce: iv)

      // 组合 IV + 加密数据 + 标签
      var result = Data()
      result.append(contentsOf: iv.withUnsafeBytes { Data($0) })
      result.append(sealedBox.ciphertext)
      result.append(sealedBox.tag)

      return result.base64EncodedString()
    } catch {
      throw ToolError.processingFailed("AES加密失败: \(error.localizedDescription)")
    }
  }

  func decryptAES(_ text: String, key: String) throws -> String {
    guard let encryptedData = Data(base64Encoded: text) else {
      throw ToolError.invalidInput("无效的加密数据格式")
    }

    guard encryptedData.count >= 28 else { // 12 (IV) + 16 (tag) 最小长度
      throw ToolError.invalidInput("加密数据长度不足")
    }

    let keyData = try createAESKey(from: key)

    do {
      // 提取IV（前12字节）
      let ivData = encryptedData.prefix(12)
      let iv = try AES.GCM.Nonce(data: ivData)
      
      // 提取标签（后16字节）
      let tag = encryptedData.suffix(16)

      // 提取密文（中间部分）
      let ciphertext = encryptedData.dropFirst(12).dropLast(16)

      let sealedBox = try AES.GCM.SealedBox(nonce: iv, ciphertext: ciphertext, tag: tag)
      let decryptedData = try AES.GCM.open(sealedBox, using: SymmetricKey(data: keyData))

      guard let result = String(data: decryptedData, encoding: .utf8) else {
        throw ToolError.processingFailed("解密数据无法转换为文本")
      }

      return result
    } catch {
      throw ToolError.processingFailed("AES解密失败: \(error.localizedDescription)")
    }
  }

  private func createAESKey(from keyString: String) throws -> Data {
    let keyData = try textToData(keyString)
    // 使用SHA256创建256位密钥
    let digest = SHA256.hash(data: keyData)
    return Data(digest)
  }
}
