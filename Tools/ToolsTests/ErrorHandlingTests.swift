//
//  ErrorHandlingTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
@testable import Tools

struct ErrorHandlingTests {
  
  // MARK: - ToolError Tests
  
  @Test("ToolError 本地化描述测试")
  func testToolErrorLocalizedDescription() {
    let invalidInputError = ToolError.invalidInput("测试消息")
    #expect(invalidInputError.localizedDescription == "输入无效: 测试消息")
    
    let emptyInputError = ToolError.emptyInput
    #expect(emptyInputError.localizedDescription == "输入不能为空")
    
    let fileNotFoundError = ToolError.fileNotFound("test.txt")
    #expect(fileNotFoundError.localizedDescription == "文件未找到: test.txt")
  }
  
  @Test("ToolError 恢复建议测试")
  func testToolErrorRecoverySuggestion() {
    let emptyInputError = ToolError.emptyInput
    #expect(emptyInputError.recoverySuggestion == "请输入有效内容后重试")
    
    let timeoutError = ToolError.timeout
    #expect(timeoutError.recoverySuggestion == "请稍后重试")
    
    let fileNotFoundError = ToolError.fileNotFound("test.txt")
    #expect(fileNotFoundError.recoverySuggestion == "请检查文件路径是否正确")
  }
  
  @Test("ToolError 重试能力测试")
  func testToolErrorRetryability() {
    // Retryable errors
    #expect(ToolError.timeout.isRetryable == true)
    #expect(ToolError.networkError(NSError(domain: "test", code: 1)).isRetryable == true)
    #expect(ToolError.processingFailed("test").isRetryable == true)
    #expect(ToolError.clipboardAccessFailed.isRetryable == true)
    
    // Non-retryable errors
    #expect(ToolError.emptyInput.isRetryable == false)
    #expect(ToolError.invalidInput("test").isRetryable == false)
    #expect(ToolError.unsupportedFormat.isRetryable == false)
    #expect(ToolError.fileNotFound("test").isRetryable == false)
  }
  
  @Test("ToolError 相等性测试")
  func testToolErrorEquality() {
    let error1 = ToolError.invalidInput("test")
    let error2 = ToolError.invalidInput("test")
    let error3 = ToolError.invalidInput("different")
    
    #expect(error1 == error2)
    #expect(error1 != error3)
    
    let emptyError1 = ToolError.emptyInput
    let emptyError2 = ToolError.emptyInput
    #expect(emptyError1 == emptyError2)
  }
  
  // MARK: - ErrorLoggingService Tests
  
  @Test("错误日志记录测试")
  func testErrorLogging() async {
    let service = ErrorLoggingService.shared
    service.clearErrorHistory()
    
    let testError = ToolError.invalidInput("测试错误")
    service.logError(testError, context: "单元测试")
    
    let history = service.getErrorHistory()
    #expect(history.count == 1)
    #expect(history.first?.error == testError.localizedDescription)
    #expect(history.first?.context == "单元测试")
    #expect(history.first?.isRetryable == testError.isRetryable)
  }
  
  @Test("错误历史管理测试")
  func testErrorHistoryManagement() {
    let service = ErrorLoggingService.shared
    service.clearErrorHistory()
    
    // Add multiple errors
    for i in 1...5 {
      service.logError(.invalidInput("错误 \(i)"))
    }
    
    let history = service.getErrorHistory()
    #expect(history.count == 5)
    
    // Clear history
    service.clearErrorHistory()
    #expect(service.getErrorHistory().isEmpty)
  }
  
  @Test("错误类型过滤测试")
  func testErrorTypeFiltering() {
    let service = ErrorLoggingService.shared
    service.clearErrorHistory()
    
    service.logError(.invalidInput("输入错误"))
    service.logError(.processingFailed("处理错误"))
    service.logError(.invalidInput("另一个输入错误"))
    
    let inputErrors = service.getErrors(ofType: "invalidInput")
    #expect(inputErrors.count == 2)
    
    let processingErrors = service.getErrors(ofType: "processingFailed")
    #expect(processingErrors.count == 1)
  }
  
  @Test("错误统计测试")
  func testErrorStatistics() {
    let service = ErrorLoggingService.shared
    service.clearErrorHistory()
    
    // Add various types of errors
    service.logError(.timeout) // retryable
    service.logError(.invalidInput("test")) // not retryable
    service.logError(.networkError(NSError(domain: "test", code: 1))) // retryable
    service.logError(.emptyInput) // not retryable
    
    let stats = service.getErrorStatistics()
    #expect(stats.totalErrors == 4)
    #expect(stats.retryableErrors == 2)
    #expect(stats.retryablePercentage == 50.0)
  }
  
  // MARK: - RetryService Tests
  
  @Test("重试服务基本功能测试")
  func testRetryServiceBasicFunctionality() async throws {
    let retryService = RetryService.shared
    var attemptCount = 0
    
    let result = try await retryService.retry(
      configuration: .init(
        maxAttempts: 3,
        initialDelay: 0.01,
        maxDelay: 0.1,
        backoffMultiplier: 2.0,
        jitterRange: 1.0...1.0
      )
    ) {
      attemptCount += 1
      if attemptCount < 3 {
        throw ToolError.timeout
      }
      return "成功"
    }
    
    #expect(result == "成功")
    #expect(attemptCount == 3)
  }
  
  @Test("重试服务条件重试测试")
  func testRetryServiceConditionalRetry() async throws {
    let retryService = RetryService.shared
    var attemptCount = 0
    
    do {
      _ = try await retryService.retryWithCondition(
        configuration: .init(
          maxAttempts: 2,
          initialDelay: 0.01,
          maxDelay: 0.1,
          backoffMultiplier: 2.0,
          jitterRange: 1.0...1.0
        ),
        shouldRetry: { error in
          // Only retry timeout errors
          return (error as? ToolError) == .timeout
        }
      ) {
        attemptCount += 1
        if attemptCount == 1 {
          throw ToolError.timeout // This should be retried
        } else {
          throw ToolError.emptyInput // This should not be retried
        }
      }
    } catch {
      // Should fail with emptyInput error after 2 attempts
      #expect((error as? ToolError) == .emptyInput)
      #expect(attemptCount == 2)
    }
  }
  
  @Test("重试服务工具操作测试")
  func testRetryServiceToolOperation() async throws {
    let retryService = RetryService.shared
    var attemptCount = 0
    
    let result = try await retryService.retryToolOperation(
      configuration: .init(
        maxAttempts: 2,
        initialDelay: 0.01,
        maxDelay: 0.1,
        backoffMultiplier: 2.0,
        jitterRange: 1.0...1.0
      )
    ) {
      attemptCount += 1
      if attemptCount == 1 {
        throw ToolError.processingFailed("临时失败") // retryable
      }
      return "成功"
    }
    
    #expect(result == "成功")
    #expect(attemptCount == 2)
  }
  
  @Test("重试服务非重试错误测试")
  func testRetryServiceNonRetryableError() async {
    let retryService = RetryService.shared
    var attemptCount = 0
    
    do {
      _ = try await retryService.retryToolOperation(
        configuration: .init(
          maxAttempts: 3,
          initialDelay: 0.01,
          maxDelay: 0.1,
          backoffMultiplier: 2.0,
          jitterRange: 1.0...1.0
        )
      ) {
        attemptCount += 1
        throw ToolError.emptyInput // not retryable
      }
    } catch {
      // Should fail immediately without retry
      #expect((error as? ToolError) == .emptyInput)
      #expect(attemptCount == 1)
    }
  }
  
  // MARK: - Integration Tests
  
  @Test("错误处理集成测试")
  func testErrorHandlingIntegration() async {
    let errorManager = ErrorManager()
    let testError = ToolError.processingFailed("集成测试错误")
    
    // Handle error
    errorManager.handleError(testError, context: "集成测试")
    
    // Check current error
    #expect(errorManager.currentError == testError)
    
    // Check error log
    let errorLog = errorManager.getErrorLog()
    #expect(errorLog.count == 1)
    #expect(errorLog.first?.error == testError)
    
    // Clear error
    errorManager.clearError()
    #expect(errorManager.currentError == nil)
  }
  
  @Test("文件大小格式化测试")
  func testFileSizeFormatting() {
    let largeFileError = ToolError.fileTooLarge(1024 * 1024 * 10) // 10MB
    let description = largeFileError.localizedDescription
    
    #expect(description.contains("文件过大"))
    #expect(description.contains("MB") || description.contains("字节"))
  }
  
  @Test("错误恢复建议完整性测试")
  func testErrorRecoverySuggestionCompleteness() {
    let errorsWithSuggestions: [ToolError] = [
      .emptyInput,
      .invalidInput("test"),
      .fileTooLarge(1000),
      .diskSpaceFull,
      .noInternetConnection,
      .timeout,
      .operationCancelled,
      .fileNotFound("test")
    ]
    
    for error in errorsWithSuggestions {
      #expect(error.recoverySuggestion != nil, "Error \(error) should have recovery suggestion")
    }
  }
}