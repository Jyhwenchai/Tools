//
//  ToolError.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import Foundation

enum ToolError: LocalizedError, Equatable {
  // Input/Output errors
  case invalidInput(String)
  case emptyInput
  case invalidFormat(String)
  case unsupportedFormat

  // Processing errors
  case processingFailed(String)
  case operationCancelled
  case timeout

  // File system errors
  case fileNotFound(String)
  case fileTooLarge(Int64)
  case diskSpaceFull

  // Network errors
  case networkError(Error)
  case noInternetConnection

  // Encryption errors
  case encryptionFailed(String)
  case decryptionFailed(String)
  case invalidKey

  // JSON errors
  case jsonParsingError(String)
  case jsonGenerationError(String)

  // Image processing errors
  case imageLoadingFailed
  case imageProcessingFailed(String)
  case unsupportedImageFormat

  // QR Code errors
  case qrCodeGenerationFailed
  case qrCodeScanningFailed

  // Time conversion errors
  case invalidTimeFormat(String)
  case timeConversionFailed(String)

  // Clipboard errors
  case clipboardAccessFailed
  case clipboardDataCorrupted

  // System errors
  case systemResourceUnavailable
  case unknown(String)

  var errorDescription: String? {
    switch self {
    // Input/Output errors
    case let .invalidInput(message):
      "输入无效: \(message)"
    case .emptyInput:
      "输入不能为空"
    case let .invalidFormat(format):
      "格式无效: \(format)"
    case .unsupportedFormat:
      "不支持的格式"
    // Processing errors
    case let .processingFailed(message):
      "处理失败: \(message)"
    case .operationCancelled:
      "操作已取消"
    case .timeout:
      "操作超时"
    // File system errors
    case let .fileNotFound(filename):
      "文件未找到: \(filename)"
    case let .fileTooLarge(size):
      "文件过大: \(ByteCountFormatter().string(fromByteCount: size))"
    case .diskSpaceFull:
      "磁盘空间不足"
    // Network errors
    case let .networkError(error):
      "网络错误: \(error.localizedDescription)"
    case .noInternetConnection:
      "无网络连接"
    // Encryption errors
    case let .encryptionFailed(message):
      "加密失败: \(message)"
    case let .decryptionFailed(message):
      "解密失败: \(message)"
    case .invalidKey:
      "密钥无效"
    // JSON errors
    case let .jsonParsingError(message):
      "JSON解析错误: \(message)"
    case let .jsonGenerationError(message):
      "JSON生成错误: \(message)"
    // Image processing errors
    case .imageLoadingFailed:
      "图片加载失败"
    case let .imageProcessingFailed(message):
      "图片处理失败: \(message)"
    case .unsupportedImageFormat:
      "不支持的图片格式"
    // QR Code errors
    case .qrCodeGenerationFailed:
      "二维码生成失败"
    case .qrCodeScanningFailed:
      "二维码识别失败"
    // Time conversion errors
    case let .invalidTimeFormat(format):
      "时间格式无效: \(format)"
    case let .timeConversionFailed(message):
      "时间转换失败: \(message)"
    // Clipboard errors
    case .clipboardAccessFailed:
      "粘贴板访问失败"
    case .clipboardDataCorrupted:
      "粘贴板数据损坏"
    // System errors
    case .systemResourceUnavailable:
      "系统资源不可用"
    case let .unknown(message):
      "未知错误: \(message)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .emptyInput:
      "请输入有效内容后重试"
    case .invalidInput, .invalidFormat:
      "请检查输入格式是否正确"
    case .fileTooLarge:
      "请选择较小的文件"
    case .diskSpaceFull:
      "请清理磁盘空间后重试"
    case .noInternetConnection:
      "请检查网络连接"
    case .timeout:
      "请稍后重试"
    case .operationCancelled:
      "操作已被用户取消"
    default:
      "请重试或联系技术支持"
    }
  }

  var isRetryable: Bool {
    switch self {
    case .timeout, .networkError, .noInternetConnection, .systemResourceUnavailable:
      true
    case .processingFailed, .encryptionFailed, .decryptionFailed:
      true
    case .imageProcessingFailed, .qrCodeGenerationFailed, .timeConversionFailed:
      true
    case .clipboardAccessFailed:
      true
    default:
      false
    }
  }

  static func == (lhs: ToolError, rhs: ToolError) -> Bool {
    switch (lhs, rhs) {
    case let (.invalidInput(a), .invalidInput(b)):
      a == b
    case (.emptyInput, .emptyInput):
      true
    case let (.invalidFormat(a), .invalidFormat(b)):
      a == b
    case (.unsupportedFormat, .unsupportedFormat):
      true
    case let (.processingFailed(a), .processingFailed(b)):
      a == b
    case (.operationCancelled, .operationCancelled):
      true
    case (.timeout, .timeout):
      true
    case let (.fileNotFound(a), .fileNotFound(b)):
      a == b
    case let (.fileTooLarge(a), .fileTooLarge(b)):
      a == b
    case (.diskSpaceFull, .diskSpaceFull):
      true
    case (.noInternetConnection, .noInternetConnection):
      true
    case let (.encryptionFailed(a), .encryptionFailed(b)):
      a == b
    case let (.decryptionFailed(a), .decryptionFailed(b)):
      a == b
    case (.invalidKey, .invalidKey):
      true
    case let (.jsonParsingError(a), .jsonParsingError(b)):
      a == b
    case let (.jsonGenerationError(a), .jsonGenerationError(b)):
      a == b
    case (.imageLoadingFailed, .imageLoadingFailed):
      true
    case let (.imageProcessingFailed(a), .imageProcessingFailed(b)):
      a == b
    case (.unsupportedImageFormat, .unsupportedImageFormat):
      true
    case (.qrCodeGenerationFailed, .qrCodeGenerationFailed):
      true
    case (.qrCodeScanningFailed, .qrCodeScanningFailed):
      true
    case let (.invalidTimeFormat(a), .invalidTimeFormat(b)):
      a == b
    case let (.timeConversionFailed(a), .timeConversionFailed(b)):
      a == b
    case (.clipboardAccessFailed, .clipboardAccessFailed):
      true
    case (.clipboardDataCorrupted, .clipboardDataCorrupted):
      true
    case (.systemResourceUnavailable, .systemResourceUnavailable):
      true
    case let (.unknown(a), .unknown(b)):
      a == b
    default:
      false
    }
  }
}
