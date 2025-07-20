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
      return "输入无效: \(message)"
    case .emptyInput:
      return "输入不能为空"
    case let .invalidFormat(format):
      return "格式无效: \(format)"
    case .unsupportedFormat:
      return "不支持的格式"
      
    // Processing errors
    case let .processingFailed(message):
      return "处理失败: \(message)"
    case .operationCancelled:
      return "操作已取消"
    case .timeout:
      return "操作超时"
      
    // File system errors
    case let .fileNotFound(filename):
      return "文件未找到: \(filename)"
    case let .fileTooLarge(size):
      return "文件过大: \(ByteCountFormatter().string(fromByteCount: size))"
    case .diskSpaceFull:
      return "磁盘空间不足"
      
    // Network errors
    case let .networkError(error):
      return "网络错误: \(error.localizedDescription)"
    case .noInternetConnection:
      return "无网络连接"
      
    // Encryption errors
    case let .encryptionFailed(message):
      return "加密失败: \(message)"
    case let .decryptionFailed(message):
      return "解密失败: \(message)"
    case .invalidKey:
      return "密钥无效"
      
    // JSON errors
    case let .jsonParsingError(message):
      return "JSON解析错误: \(message)"
    case let .jsonGenerationError(message):
      return "JSON生成错误: \(message)"
      
    // Image processing errors
    case .imageLoadingFailed:
      return "图片加载失败"
    case let .imageProcessingFailed(message):
      return "图片处理失败: \(message)"
    case .unsupportedImageFormat:
      return "不支持的图片格式"
      
    // QR Code errors
    case .qrCodeGenerationFailed:
      return "二维码生成失败"
    case .qrCodeScanningFailed:
      return "二维码识别失败"
      
    // Time conversion errors
    case let .invalidTimeFormat(format):
      return "时间格式无效: \(format)"
    case let .timeConversionFailed(message):
      return "时间转换失败: \(message)"
      
    // Clipboard errors
    case .clipboardAccessFailed:
      return "粘贴板访问失败"
    case .clipboardDataCorrupted:
      return "粘贴板数据损坏"
      
    // System errors
    case .systemResourceUnavailable:
      return "系统资源不可用"
    case let .unknown(message):
      return "未知错误: \(message)"
    }
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .emptyInput:
      return "请输入有效内容后重试"
    case .invalidInput, .invalidFormat:
      return "请检查输入格式是否正确"
    case .fileTooLarge:
      return "请选择较小的文件"
    case .diskSpaceFull:
      return "请清理磁盘空间后重试"
    case .noInternetConnection:
      return "请检查网络连接"
    case .timeout:
      return "请稍后重试"
    case .operationCancelled:
      return "操作已被用户取消"
    default:
      return "请重试或联系技术支持"
    }
  }
  
  var isRetryable: Bool {
    switch self {
    case .timeout, .networkError, .noInternetConnection, .systemResourceUnavailable:
      return true
    case .processingFailed, .encryptionFailed, .decryptionFailed:
      return true
    case .imageProcessingFailed, .qrCodeGenerationFailed, .timeConversionFailed:
      return true
    case .clipboardAccessFailed:
      return true
    default:
      return false
    }
  }
  
  static func == (lhs: ToolError, rhs: ToolError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidInput(let a), .invalidInput(let b)):
      return a == b
    case (.emptyInput, .emptyInput):
      return true
    case (.invalidFormat(let a), .invalidFormat(let b)):
      return a == b
    case (.unsupportedFormat, .unsupportedFormat):
      return true
    case (.processingFailed(let a), .processingFailed(let b)):
      return a == b
    case (.operationCancelled, .operationCancelled):
      return true
    case (.timeout, .timeout):
      return true
    case (.fileNotFound(let a), .fileNotFound(let b)):
      return a == b
    case (.fileTooLarge(let a), .fileTooLarge(let b)):
      return a == b
    case (.diskSpaceFull, .diskSpaceFull):
      return true
    case (.noInternetConnection, .noInternetConnection):
      return true
    case (.encryptionFailed(let a), .encryptionFailed(let b)):
      return a == b
    case (.decryptionFailed(let a), .decryptionFailed(let b)):
      return a == b
    case (.invalidKey, .invalidKey):
      return true
    case (.jsonParsingError(let a), .jsonParsingError(let b)):
      return a == b
    case (.jsonGenerationError(let a), .jsonGenerationError(let b)):
      return a == b
    case (.imageLoadingFailed, .imageLoadingFailed):
      return true
    case (.imageProcessingFailed(let a), .imageProcessingFailed(let b)):
      return a == b
    case (.unsupportedImageFormat, .unsupportedImageFormat):
      return true
    case (.qrCodeGenerationFailed, .qrCodeGenerationFailed):
      return true
    case (.qrCodeScanningFailed, .qrCodeScanningFailed):
      return true
    case (.invalidTimeFormat(let a), .invalidTimeFormat(let b)):
      return a == b
    case (.timeConversionFailed(let a), .timeConversionFailed(let b)):
      return a == b
    case (.clipboardAccessFailed, .clipboardAccessFailed):
      return true
    case (.clipboardDataCorrupted, .clipboardDataCorrupted):
      return true
    case (.systemResourceUnavailable, .systemResourceUnavailable):
      return true
    case (.unknown(let a), .unknown(let b)):
      return a == b
    default:
      return false
    }
  }
}
