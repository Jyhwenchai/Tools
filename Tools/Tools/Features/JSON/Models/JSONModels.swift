//
//  JSONModels.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import Foundation

enum JSONOperation: String, CaseIterable, Identifiable {
  case format = "格式化"
  case minify = "压缩"
  case validate = "验证"
  case generateModel = "生成代码"

  var id: String { rawValue }

  var description: String {
    switch self {
    case .format:
      "格式化JSON，使其更易读"
    case .minify:
      "压缩JSON，移除空格和换行"
    case .validate:
      "验证JSON格式是否正确"
    case .generateModel:
      "根据JSON生成模型代码"
    }
  }
}

enum ProgrammingLanguage: String, CaseIterable, Identifiable {
  case swift = "Swift"
  case java = "Java"
  case python = "Python"
  case typescript = "TypeScript"

  var id: String { rawValue }

  var fileExtension: String {
    switch self {
    case .swift:
      ".swift"
    case .java:
      ".java"
    case .python:
      ".py"
    case .typescript:
      ".ts"
    }
  }
}

struct JSONProcessingResult {
  let operation: JSONOperation
  let input: String
  let output: String
  let isValid: Bool
  let errorMessage: String?
  let timestamp: Date

  init(
    operation: JSONOperation,
    input: String,
    output: String,
    isValid: Bool = true,
    errorMessage: String? = nil) {
    self.operation = operation
    self.input = input
    self.output = output
    self.isValid = isValid
    self.errorMessage = errorMessage
    timestamp = Date()
  }
}
