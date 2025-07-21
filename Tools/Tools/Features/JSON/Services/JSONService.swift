//
//  JSONService.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import Foundation

class JSONService {
  static let shared = JSONService()

  private init() {}

  // MARK: - Public Methods

  func formatJSON(_ jsonString: String) throws -> String {
    guard !jsonString.isEmpty else {
      throw ToolError.invalidInput("JSON字符串不能为空")
    }

    guard let data = jsonString.data(using: .utf8) else {
      throw ToolError.processingFailed("字符串编码失败")
    }

    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      let formattedData = try JSONSerialization.data(
        withJSONObject: jsonObject,
        options: [.prettyPrinted, .sortedKeys])

      guard let formattedString = String(data: formattedData, encoding: .utf8) else {
        throw ToolError.processingFailed("格式化结果转换失败")
      }

      return formattedString
    } catch let error as NSError {
      throw ToolError.invalidInput("JSON格式错误: \(error.localizedDescription)")
    }
  }

  func minifyJSON(_ jsonString: String) throws -> String {
    guard !jsonString.isEmpty else {
      throw ToolError.invalidInput("JSON字符串不能为空")
    }

    guard let data = jsonString.data(using: .utf8) else {
      throw ToolError.processingFailed("字符串编码失败")
    }

    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      let minifiedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])

      guard let minifiedString = String(data: minifiedData, encoding: .utf8) else {
        throw ToolError.processingFailed("压缩结果转换失败")
      }

      return minifiedString
    } catch let error as NSError {
      throw ToolError.invalidInput("JSON格式错误: \(error.localizedDescription)")
    }
  }

  func validateJSON(_ jsonString: String) -> (isValid: Bool, errorMessage: String?) {
    guard !jsonString.isEmpty else {
      return (false, "JSON字符串不能为空")
    }

    guard let data = jsonString.data(using: .utf8) else {
      return (false, "字符串编码失败")
    }

    do {
      _ = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
      return (true, nil)
    } catch let error as NSError {
      return (false, "JSON格式错误: \(error.localizedDescription)")
    }
  }

  func generateModelCode(
    _ jsonString: String,
    language: ProgrammingLanguage,
    className: String = "Model") throws -> String {
    guard !jsonString.isEmpty else {
      throw ToolError.invalidInput("JSON字符串不能为空")
    }

    guard let data = jsonString.data(using: .utf8) else {
      throw ToolError.processingFailed("字符串编码失败")
    }

    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

      switch language {
      case .swift:
        return try generateSwiftModel(from: jsonObject, className: className)
      case .java:
        return try generateJavaModel(from: jsonObject, className: className)
      case .python:
        return try generatePythonModel(from: jsonObject, className: className)
      case .typescript:
        return try generateTypeScriptModel(from: jsonObject, className: className)
      }
    } catch let error as NSError {
      throw ToolError.invalidInput("JSON格式错误: \(error.localizedDescription)")
    }
  }

  func extractJSONPaths(_ jsonString: String) throws -> [String] {
    guard !jsonString.isEmpty else {
      throw ToolError.invalidInput("JSON字符串不能为空")
    }

    guard let data = jsonString.data(using: .utf8) else {
      throw ToolError.processingFailed("字符串编码失败")
    }

    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      var paths: [String] = []
      extractPaths(from: jsonObject, currentPath: "$", paths: &paths)
      return paths.sorted()
    } catch let error as NSError {
      throw ToolError.invalidInput("JSON格式错误: \(error.localizedDescription)")
    }
  }
}

// MARK: - Private Code Generation Methods

private extension JSONService {
  func generateSwiftModel(from jsonObject: Any, className: String) throws -> String {
    guard let dictionary = jsonObject as? [String: Any] else {
      throw ToolError.processingFailed("JSON必须是对象类型才能生成模型")
    }

    var code = "import Foundation\n\n"
    code += "struct \(className): Codable {\n"

    for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
      let propertyName = key.camelCased
      let propertyType = swiftType(for: value)
      code += "  let \(propertyName): \(propertyType)\n"
    }

    code += "}\n"
    return code
  }

  func generateJavaModel(from jsonObject: Any, className: String) throws -> String {
    guard let dictionary = jsonObject as? [String: Any] else {
      throw ToolError.processingFailed("JSON必须是对象类型才能生成模型")
    }

    var code = "public class \(className) {\n"

    for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
      let propertyName = key.camelCased
      let propertyType = javaType(for: value)
      code += "  private \(propertyType) \(propertyName);\n"
    }

    code += "\n  // Constructors, getters, and setters\n"
    code += "  public \(className)() {}\n\n"

    for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
      let propertyName = key.camelCased
      let propertyType = javaType(for: value)
      let capitalizedName = propertyName.capitalized

      code += "  public \(propertyType) get\(capitalizedName)() {\n"
      code += "    return \(propertyName);\n"
      code += "  }\n\n"

      code += "  public void set\(capitalizedName)(\(propertyType) \(propertyName)) {\n"
      code += "    this.\(propertyName) = \(propertyName);\n"
      code += "  }\n\n"
    }

    code += "}\n"
    return code
  }

  func generatePythonModel(from jsonObject: Any, className: String) throws -> String {
    guard let dictionary = jsonObject as? [String: Any] else {
      throw ToolError.processingFailed("JSON必须是对象类型才能生成模型")
    }

    var code = "from dataclasses import dataclass\nfrom typing import Optional, Any\n\n"
    code += "@dataclass\n"
    code += "class \(className):\n"

    for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
      let propertyName = key.snakeCased
      let propertyType = pythonType(for: value)
      code += "  \(propertyName): \(propertyType)\n"
    }

    return code
  }

  func generateTypeScriptModel(from jsonObject: Any, className: String) throws -> String {
    guard let dictionary = jsonObject as? [String: Any] else {
      throw ToolError.processingFailed("JSON必须是对象类型才能生成模型")
    }

    var code = "export interface \(className) {\n"

    for (key, value) in dictionary.sorted(by: { $0.key < $1.key }) {
      let propertyName = key.camelCased
      let propertyType = typeScriptType(for: value)
      code += "  \(propertyName): \(propertyType);\n"
    }

    code += "}\n"
    return code
  }

  // MARK: - Path Extraction Helpers

  func extractPaths(from object: Any, currentPath: String, paths: inout [String]) {
    paths.append(currentPath)

    if let dictionary = object as? [String: Any] {
      for (key, value) in dictionary {
        let newPath = "\(currentPath).\(key)"
        extractPaths(from: value, currentPath: newPath, paths: &paths)
      }
    } else if let array = object as? [Any] {
      for (index, value) in array.enumerated() {
        let newPath = "\(currentPath)[\(index)]"
        extractPaths(from: value, currentPath: newPath, paths: &paths)
      }
    }
  }

  // MARK: - Type Mapping Helpers

  func swiftType(for value: Any) -> String {
    switch value {
    case is String:
      "String"
    case let number as NSNumber:
      // Check if it's a boolean first (JSON booleans are parsed as NSNumber)
      if CFBooleanGetTypeID() == CFGetTypeID(number) {
        "Bool"
      } else {
        number.stringValue.contains(".") ? "Double" : "Int"
      }
    case is Bool:
      "Bool"
    case is Int:
      "Int"
    case is Double, is Float:
      "Double"
    case is [Any]:
      "[Any]"
    case is [String: Any]:
      "[String: Any]"
    default:
      "Any"
    }
  }

  func javaType(for value: Any) -> String {
    switch value {
    case is String:
      "String"
    case let number as NSNumber:
      // Check if it's a boolean first (JSON booleans are parsed as NSNumber)
      if CFBooleanGetTypeID() == CFGetTypeID(number) {
        "Boolean"
      } else {
        number.stringValue.contains(".") ? "Double" : "Integer"
      }
    case is Bool:
      "Boolean"
    case is Int:
      "Integer"
    case is Double, is Float:
      "Double"
    case is [Any]:
      "List<Object>"
    case is [String: Any]:
      "Map<String, Object>"
    default:
      "Object"
    }
  }

  func pythonType(for value: Any) -> String {
    switch value {
    case is String:
      "str"
    case let number as NSNumber:
      // Check if it's a boolean first (JSON booleans are parsed as NSNumber)
      if CFBooleanGetTypeID() == CFGetTypeID(number) {
        "bool"
      } else {
        number.stringValue.contains(".") ? "float" : "int"
      }
    case is Bool:
      "bool"
    case is Int:
      "int"
    case is Double, is Float:
      "float"
    case is [Any]:
      "list[Any]"
    case is [String: Any]:
      "dict[str, Any]"
    default:
      "Any"
    }
  }

  func typeScriptType(for value: Any) -> String {
    switch value {
    case is String:
      "string"
    case let number as NSNumber:
      // Check if it's a boolean first (JSON booleans are parsed as NSNumber)
      if CFBooleanGetTypeID() == CFGetTypeID(number) {
        "boolean"
      } else {
        "number"
      }
    case is Int, is Double, is Float:
      "number"
    case is Bool:
      "boolean"
    case is [Any]:
      "any[]"
    case is [String: Any]:
      "Record<string, any>"
    default:
      "any"
    }
  }
}

// MARK: - String Extensions

private extension String {
  var camelCased: String {
    // If the string is already in camelCase, return as is
    if self.first?.isLowercase == true, contains(where: \.isUppercase) {
      return self
    }

    let components = components(separatedBy: CharacterSet.alphanumerics.inverted)
    let first = components.first?.lowercased() ?? ""
    let rest = components.dropFirst().map(\.capitalized)
    return ([first] + rest).joined()
  }

  var snakeCased: String {
    replacingOccurrences(of: "([a-z0-9])([A-Z])", with: "$1_$2", options: .regularExpression)
      .lowercased()
  }
}
