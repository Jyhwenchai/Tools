//
//  JSONModelsTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
@testable import Tools

struct JSONModelsTests {
  
  // MARK: - JSONOperation Tests
  
  @Test("JSONOperation 枚举值测试", arguments: [
    (JSONOperation.format, "格式化", "格式化JSON，使其更易读"),
    (JSONOperation.minify, "压缩", "压缩JSON，移除空格和换行"),
    (JSONOperation.validate, "验证", "验证JSON格式是否正确"),
    (JSONOperation.generateModel, "生成代码", "根据JSON生成模型代码")
  ])
  func testJSONOperationValues(
    operation: JSONOperation,
    expectedRawValue: String,
    expectedDescription: String
  ) {
    #expect(operation.rawValue == expectedRawValue)
    #expect(operation.id == expectedRawValue)
    #expect(operation.description == expectedDescription)
  }
  
  @Test("JSONOperation 枚举完整性测试")
  func testJSONOperationCompleteness() {
    let allCases = JSONOperation.allCases
    #expect(allCases.count == 4)
    
    let expectedOperations: [JSONOperation] = [.format, .minify, .validate, .generateModel]
    for expectedOperation in expectedOperations {
      #expect(allCases.contains(expectedOperation))
    }
  }
  
  // MARK: - ProgrammingLanguage Tests
  
  @Test("ProgrammingLanguage 枚举值测试", arguments: [
    (ProgrammingLanguage.swift, "Swift", ".swift"),
    (ProgrammingLanguage.java, "Java", ".java"),
    (ProgrammingLanguage.python, "Python", ".py"),
    (ProgrammingLanguage.typescript, "TypeScript", ".ts")
  ])
  func testProgrammingLanguageValues(
    language: ProgrammingLanguage,
    expectedRawValue: String,
    expectedExtension: String
  ) {
    #expect(language.rawValue == expectedRawValue)
    #expect(language.id == expectedRawValue)
    #expect(language.fileExtension == expectedExtension)
  }
  
  @Test("ProgrammingLanguage 枚举完整性测试")
  func testProgrammingLanguageCompleteness() {
    let allCases = ProgrammingLanguage.allCases
    #expect(allCases.count == 4)
    
    let expectedLanguages: [ProgrammingLanguage] = [.swift, .java, .python, .typescript]
    for expectedLanguage in expectedLanguages {
      #expect(allCases.contains(expectedLanguage))
    }
  }
  
  // MARK: - JSONProcessingResult Tests
  
  @Test("JSONProcessingResult 成功结果测试")
  func testJSONProcessingResultSuccess() {
    let input = "{\"name\": \"John\"}"
    let output = """
    {
      "name" : "John"
    }
    """
    
    let result = JSONProcessingResult(
      operation: .format,
      input: input,
      output: output
    )
    
    #expect(result.operation == .format)
    #expect(result.input == input)
    #expect(result.output == output)
    #expect(result.isValid == true)
    #expect(result.errorMessage == nil)
    #expect(result.timestamp <= Date())
  }
  
  @Test("JSONProcessingResult 失败结果测试")
  func testJSONProcessingResultFailure() {
    let input = "{\"name\": \"John\",}"
    let output = ""
    let errorMessage = "JSON格式错误：多余的逗号"
    
    let result = JSONProcessingResult(
      operation: .validate,
      input: input,
      output: output,
      isValid: false,
      errorMessage: errorMessage
    )
    
    #expect(result.operation == .validate)
    #expect(result.input == input)
    #expect(result.output == output)
    #expect(result.isValid == false)
    #expect(result.errorMessage == errorMessage)
    #expect(result.timestamp <= Date())
  }
  
  @Test("JSONProcessingResult 时间戳测试")
  func testJSONProcessingResultTimestamp() {
    let beforeCreation = Date()
    
    let result = JSONProcessingResult(
      operation: .minify,
      input: "{}",
      output: "{}"
    )
    
    let afterCreation = Date()
    
    #expect(result.timestamp >= beforeCreation)
    #expect(result.timestamp <= afterCreation)
  }
  
  @Test("JSONProcessingResult 不同操作类型测试", arguments: [
    JSONOperation.format,
    JSONOperation.minify,
    JSONOperation.validate,
    JSONOperation.generateModel
  ])
  func testJSONProcessingResultDifferentOperations(operation: JSONOperation) {
    let result = JSONProcessingResult(
      operation: operation,
      input: "test input",
      output: "test output"
    )
    
    #expect(result.operation == operation)
    #expect(result.input == "test input")
    #expect(result.output == "test output")
    #expect(result.isValid == true)
    #expect(result.errorMessage == nil)
  }
  
  @Test("JSONProcessingResult 边界情况测试")
  func testJSONProcessingResultEdgeCases() {
    // 空输入测试
    let emptyResult = JSONProcessingResult(
      operation: .validate,
      input: "",
      output: "",
      isValid: false,
      errorMessage: "输入为空"
    )
    
    #expect(emptyResult.input.isEmpty)
    #expect(emptyResult.output.isEmpty)
    #expect(emptyResult.isValid == false)
    #expect(emptyResult.errorMessage == "输入为空")
    
    // 长输入测试
    let longInput = String(repeating: "a", count: 10000)
    let longResult = JSONProcessingResult(
      operation: .format,
      input: longInput,
      output: longInput
    )
    
    #expect(longResult.input.count == 10000)
    #expect(longResult.output.count == 10000)
    #expect(longResult.isValid == true)
  }
}