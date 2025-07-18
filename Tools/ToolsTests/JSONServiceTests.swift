//
//  JSONServiceTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/17.
//

import Testing
@testable import Tools

struct JSONServiceTests {
  
  // MARK: - JSON Formatting Tests
  
  @Test("JSON格式化 - 基本功能测试")
  func testJSONFormatting() throws {
    let service = JSONService.shared
    let input = #"{"name":"John","age":30,"city":"New York"}"#
    
    let formatted = try service.formatJSON(input)
    
    // 验证格式化后的JSON包含正确的缩进和换行
    #expect(formatted.contains("\"name\" : \"John\""))
    #expect(formatted.contains("\"age\" : 30"))
    #expect(formatted.contains("\"city\" : \"New York\""))
    #expect(formatted.contains("\n"))
  }
  
  @Test("JSON格式化 - 嵌套对象测试")
  func testJSONFormattingWithNestedObjects() throws {
    let service = JSONService.shared
    let input = #"{"user":{"name":"John","details":{"age":30,"active":true}}}"#
    
    let formatted = try service.formatJSON(input)
    
    #expect(formatted.contains("\"user\" : {"))
    #expect(formatted.contains("\"details\" : {"))
    #expect(formatted.contains("\"active\" : true"))
  }
  
  @Test("JSON格式化 - 数组测试")
  func testJSONFormattingWithArrays() throws {
    let service = JSONService.shared
    let input = #"{"items":[1,2,3],"names":["Alice","Bob"]}"#
    
    let formatted = try service.formatJSON(input)
    
    #expect(formatted.contains("\"items\" : ["))
    #expect(formatted.contains("\"names\" : ["))
    #expect(formatted.contains("\"Alice\""))
    #expect(formatted.contains("\"Bob\""))
  }
  
  @Test("JSON格式化 - 空字符串错误")
  func testJSONFormattingEmptyString() {
    let service = JSONService.shared
    
    #expect(throws: ToolError.self) {
      try service.formatJSON("")
    }
  }
  
  @Test("JSON格式化 - 无效JSON错误")
  func testJSONFormattingInvalidJSON() {
    let service = JSONService.shared
    let invalidJSON = #"{"name": "John", "age":}"#
    
    #expect(throws: ToolError.self) {
      try service.formatJSON(invalidJSON)
    }
  }
  
  // MARK: - JSON Minification Tests
  
  @Test("JSON压缩 - 基本功能测试")
  func testJSONMinification() throws {
    let service = JSONService.shared
    let input = """
    {
      "name" : "John",
      "age" : 30,
      "city" : "New York"
    }
    """
    
    let minified = try service.minifyJSON(input)
    
    // 验证压缩后的JSON不包含多余的空格和换行
    #expect(!minified.contains("\n"))
    #expect(!minified.contains("  "))
    #expect(minified.contains("\"name\":\"John\""))
    #expect(minified.contains("\"age\":30"))
  }
  
  @Test("JSON压缩 - 复杂结构测试")
  func testJSONMinificationComplexStructure() throws {
    let service = JSONService.shared
    let input = """
    {
      "users": [
        {
          "name": "John",
          "details": {
            "age": 30,
            "active": true
          }
        }
      ]
    }
    """
    
    let minified = try service.minifyJSON(input)
    
    #expect(!minified.contains("\n"))
    #expect(!minified.contains("  "))
    #expect(minified.contains("\"users\":[{"))
    #expect(minified.contains("\"details\":{"))
  }
  
  @Test("JSON压缩 - 空字符串错误")
  func testJSONMinificationEmptyString() {
    let service = JSONService.shared
    
    #expect(throws: ToolError.self) {
      try service.minifyJSON("")
    }
  }
  
  @Test("JSON压缩 - 无效JSON错误")
  func testJSONMinificationInvalidJSON() {
    let service = JSONService.shared
    let invalidJSON = #"{"name": "John", "age":}"#
    
    #expect(throws: ToolError.self) {
      try service.minifyJSON(invalidJSON)
    }
  }
  
  // MARK: - JSON Validation Tests
  
  @Test("JSON验证 - 有效JSON测试", arguments: [
    #"{"name":"John","age":30}"#,
    "[1,2,3,4,5]",
    #"{"users":[{"name":"Alice"},{"name":"Bob"}]}"#,
    "true",
    "false",
    "null",
    "42",
    "\"hello world\""
  ])
  func testJSONValidationValid(json: String) {
    let service = JSONService.shared
    let result = service.validateJSON(json)
    
    #expect(result.isValid == true)
    #expect(result.errorMessage == nil)
  }
  
  @Test("JSON验证 - 无效JSON测试", arguments: [
    #"{"name": "John", "age":}"#,
    #"{"name": "John" "age": 30}"#,
    #"{name: "John"}"#,
    "{'name': 'John'}",
    "undefined"
  ])
  func testJSONValidationInvalid(json: String) {
    let service = JSONService.shared
    let result = service.validateJSON(json)
    
    #expect(result.isValid == false)
    #expect(result.errorMessage != nil)
  }
  
  @Test("JSON验证 - 空字符串测试")
  func testJSONValidationEmptyString() {
    let service = JSONService.shared
    let result = service.validateJSON("")
    
    #expect(result.isValid == false)
    #expect(result.errorMessage == "JSON字符串不能为空")
  }
  
  // MARK: - Code Generation Tests
  
  @Test("Swift代码生成测试")
  func testSwiftCodeGeneration() throws {
    let service = JSONService.shared
    let json = #"{"name":"John","age":30,"isActive":true}"#
    
    let code = try service.generateModelCode(json, language: .swift, className: "User")
    
    #expect(code.contains("struct User: Codable"))
    #expect(code.contains("let name: String"))
    #expect(code.contains("let age: Int"))
    #expect(code.contains("let isActive: Bool"))
    #expect(code.contains("import Foundation"))
  }
  
  @Test("Java代码生成测试")
  func testJavaCodeGeneration() throws {
    let service = JSONService.shared
    let json = #"{"name":"John","age":30,"isActive":true}"#
    
    let code = try service.generateModelCode(json, language: .java, className: "User")
    
    #expect(code.contains("public class User"))
    #expect(code.contains("private String name"))
    #expect(code.contains("private Integer age"))
    #expect(code.contains("private Boolean isActive"))
    #expect(code.contains("public String getName()"))
    #expect(code.contains("public void setName(String name)"))
  }
  
  @Test("Python代码生成测试")
  func testPythonCodeGeneration() throws {
    let service = JSONService.shared
    let json = #"{"name":"John","age":30,"isActive":true}"#
    
    let code = try service.generateModelCode(json, language: .python, className: "User")
    
    #expect(code.contains("@dataclass"))
    #expect(code.contains("class User:"))
    #expect(code.contains("name: str"))
    #expect(code.contains("age: int"))
    #expect(code.contains("is_active: bool"))
    #expect(code.contains("from dataclasses import dataclass"))
  }
  
  @Test("TypeScript代码生成测试")
  func testTypeScriptCodeGeneration() throws {
    let service = JSONService.shared
    let json = #"{"name":"John","age":30,"isActive":true}"#
    
    let code = try service.generateModelCode(json, language: .typescript, className: "User")
    
    #expect(code.contains("export interface User"))
    #expect(code.contains("name: string"))
    #expect(code.contains("age: number"))
    #expect(code.contains("isActive: boolean"))
  }
  
  @Test("代码生成 - 复杂对象测试")
  func testCodeGenerationComplexObject() throws {
    let service = JSONService.shared
    let json = """
    {
      "user": {
        "name": "John",
        "age": 30
      },
      "items": [1, 2, 3],
      "metadata": {
        "created": "2023-01-01",
        "updated": "2023-12-31"
      }
    }
    """
    
    let swiftCode = try service.generateModelCode(json, language: .swift, className: "Response")
    
    #expect(swiftCode.contains("struct Response: Codable"))
    #expect(swiftCode.contains("let user: [String: Any]"))
    #expect(swiftCode.contains("let items: [Any]"))
    #expect(swiftCode.contains("let metadata: [String: Any]"))
  }
  
  @Test("代码生成 - 空字符串错误")
  func testCodeGenerationEmptyString() {
    let service = JSONService.shared
    
    #expect(throws: ToolError.self) {
      try service.generateModelCode("", language: .swift)
    }
  }
  
  @Test("代码生成 - 无效JSON错误")
  func testCodeGenerationInvalidJSON() {
    let service = JSONService.shared
    let invalidJSON = #"{"name": "John", "age":}"#
    
    #expect(throws: ToolError.self) {
      try service.generateModelCode(invalidJSON, language: .swift)
    }
  }
  
  @Test("代码生成 - 非对象JSON错误")
  func testCodeGenerationNonObjectJSON() {
    let service = JSONService.shared
    let arrayJSON = "[1, 2, 3]"
    
    #expect(throws: ToolError.self) {
      try service.generateModelCode(arrayJSON, language: .swift)
    }
  }
  
  // MARK: - Edge Cases and Error Handling
  
  @Test("处理特殊字符的JSON")
  func testJSONWithSpecialCharacters() throws {
    let service = JSONService.shared
    let json = #"{"message":"Hello\nWorld\t!","emoji":"😀","unicode":"\\u0048\\u0065\\u006C\\u006C\\u006F"}"#
    
    let formatted = try service.formatJSON(json)
    let minified = try service.minifyJSON(json)
    let validation = service.validateJSON(json)
    
    #expect(formatted.contains("Hello\\nWorld\\t!"))
    #expect(minified.contains("😀"))
    #expect(validation.isValid == true)
  }
  
  @Test("处理大数字的JSON")
  func testJSONWithLargeNumbers() throws {
    let service = JSONService.shared
    let json = #"{"bigInt":9223372036854775807,"bigFloat":1.7976931348623157e+308}"#
    
    let formatted = try service.formatJSON(json)
    let validation = service.validateJSON(json)
    
    #expect(formatted.contains("9223372036854775807"))
    #expect(validation.isValid == true)
  }
  
  @Test("处理深度嵌套的JSON")
  func testDeeplyNestedJSON() throws {
    let service = JSONService.shared
    let json = #"{"level1":{"level2":{"level3":{"level4":{"value":"deep"}}}}}"#
    
    let formatted = try service.formatJSON(json)
    let minified = try service.minifyJSON(json)
    let validation = service.validateJSON(json)
    
    #expect(formatted.contains("\"level4\" : {"))
    #expect(minified.contains("\"level4\":{\"value\":\"deep\"}"))
    #expect(validation.isValid == true)
  }
}