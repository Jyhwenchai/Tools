import Foundation

// 复制JSONService的相关代码来调试
class JSONService {
  static let shared = JSONService()
  
  private init() {}
  
  func validateJSON(_ jsonString: String) -> (isValid: Bool, errorMessage: String?) {
    guard !jsonString.isEmpty else {
      return (false, "JSON字符串不能为空")
    }
    
    guard let data = jsonString.data(using: .utf8) else {
      return (false, "字符串编码失败")
    }
    
    do {
      _ = try JSONSerialization.jsonObject(with: data, options: [])
      return (true, nil)
    } catch let error as NSError {
      return (false, "JSON格式错误: \(error.localizedDescription)")
    }
  }
  
  func generateModelCode(_ jsonString: String, language: ProgrammingLanguage, className: String = "Model") throws -> String {
    guard !jsonString.isEmpty else {
      throw ToolError.invalidInput("JSON字符串不能为空")
    }
    
    guard let data = jsonString.data(using: .utf8) else {
      throw ToolError.processingFailed("字符串编码失败")
    }
    
    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      
      switch language {
      case .typescript:
        return try generateTypeScriptModel(from: jsonObject, className: className)
      default:
        return ""
      }
    } catch let error as NSError {
      throw ToolError.invalidInput("JSON格式错误: \(error.localizedDescription)")
    }
  }
  
  private func generateTypeScriptModel(from jsonObject: Any, className: String) throws -> String {
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
  
  private func typeScriptType(for value: Any) -> String {
    switch value {
    case is String:
      return "string"
    case is Int, is Double, is Float:
      return "number"
    case is Bool:
      return "boolean"
    case is [Any]:
      return "any[]"
    case is [String: Any]:
      return "Record<string, any>"
    default:
      return "any"
    }
  }
}

enum ProgrammingLanguage {
  case typescript
}

enum ToolError: LocalizedError {
  case invalidInput(String)
  case processingFailed(String)
  
  var errorDescription: String? {
    switch self {
    case let .invalidInput(message):
      return "输入无效: \(message)"
    case let .processingFailed(message):
      return "处理失败: \(message)"
    }
  }
}

extension String {
  var camelCased: String {
    // If the string is already in camelCase, return as is
    if self.first?.isLowercase == true && self.contains(where: { $0.isUppercase }) {
      return self
    }
    
    let components = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
    let first = components.first?.lowercased() ?? ""
    let rest = components.dropFirst().map { $0.capitalized }
    return ([first] + rest).joined()
  }
}

// 测试代码
let service = JSONService.shared

// 测试JSON验证 - 无效JSON测试参数
let invalidTestCases = [
  #"{"name": "John", "age":}"#,
  #"{"name": "John" "age": 30}"#,
  "[1,2,3,]",
  #"{name: "John"}"#,
  "{'name': 'John'}",
  "undefined"
]

print("=== JSON Validation Invalid Tests ===")
for testCase in invalidTestCases {
  let result = service.validateJSON(testCase)
  print("Input: '\(testCase)' -> Valid: \(result.isValid), Error: \(result.errorMessage ?? "nil")")
  if result.isValid {
    print("❌ This should be INVALID but was marked as VALID!")
  }
}

// 测试TypeScript代码生成
print("\n=== TypeScript Code Generation Test ===")
let json = #"{"name":"John","age":30,"isActive":true}"#
do {
  let code = try service.generateModelCode(json, language: .typescript, className: "User")
  print("Generated TypeScript code:")
  print(code)
  
  // 检查期望的内容
  let expectedContents = [
    "export interface User",
    "name: string",
    "age: number", 
    "isActive: boolean"
  ]
  
  for expected in expectedContents {
    if code.contains(expected) {
      print("✓ Contains: \(expected)")
    } else {
      print("✗ Missing: \(expected)")
    }
  }
} catch {
  print("Error: \(error)")
}