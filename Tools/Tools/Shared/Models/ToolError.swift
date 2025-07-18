//
//  ToolError.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import Foundation

enum ToolError: LocalizedError {
  case invalidInput(String)
  case processingFailed(String)
  case fileAccessDenied
  case networkError(Error)
  case unsupportedFormat

  var errorDescription: String? {
    switch self {
    case let .invalidInput(message):
      return "输入无效: \(message)"
    case let .processingFailed(message):
      return "处理失败: \(message)"
    case .fileAccessDenied:
      return "文件访问被拒绝"
    case let .networkError(error):
      return "网络错误: \(error.localizedDescription)"
    case .unsupportedFormat:
      return "不支持的格式"
    }
  }
}
