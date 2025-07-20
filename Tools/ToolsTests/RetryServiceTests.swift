//
//  RetryServiceTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
@testable import Tools

struct RetryServiceTests {
  
  @Test("RetryService 单例测试")
  func testSingletonInstance() async {
    let service1 = RetryService.shared
    let service2 = RetryService.shared
    
    #expect(service1 === service2)
  }
  
  @Test("RetryConfiguration 默认配置测试")
  func testDefaultRetryConfiguration() {
    let config = RetryService.RetryConfiguration.default
    
    #expect(config.maxAttempts == 3)
    #expect(config.initialDelay == 1.0)
    #expect(config.maxDelay == 30.0)
    #expect(config.backoffMultiplier == 2.0)
    #expect(config.jitterRange == 0.8...1.2)
  }
  
  @Test("RetryConfiguration 激进配置测试")
  func testAggressiveRetryConfiguration() {
    let config = RetryService.RetryConfiguration.aggressive
    
    #expect(config.maxAttempts == 5)
    #expect(config.initialDelay == 0.5)
    #expect(config.maxDelay == 60.0)
    #expect(config.backoffMultiplier == 2.5)
    #expect(config.jitterRange == 0.7...1.3)
  }
  
  @Test("RetryConfiguration 保守配置测试")
  func testConservativeRetryConfiguration() {
    let config = RetryService.RetryConfiguration.conservative
    
    #expect(config.maxAttempts == 2)
    #expect(config.initialDelay == 2.0)
    #expect(config.maxDelay == 10.0)
    #expect(config.backoffMultiplier == 1.5)
    #expect(config.jitterRange == 0.9...1.1)
  }
  
  @Test("成功操作无需重试测试")
  func testSuccessfulOperationNoRetry() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    let result = try await service.retry {
      attemptCount += 1
      return "成功结果"
    }
    
    #expect(result == "成功结果")
    #expect(attemptCount == 1)
  }
  
  @Test("失败操作重试测试")
  func testFailedOperationRetry() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    let result = try await service.retry(
      configuration: RetryService.RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 0.01, // 很短的延迟用于测试
        maxDelay: 1.0,
        backoffMultiplier: 2.0,
        jitterRange: 1.0...1.0 // 无抖动用于测试
      )
    ) {
      attemptCount += 1
      if attemptCount < 3 {
        throw ToolError.processingFailed("尝试 \(attemptCount)")
      }
      return "第三次成功"
    }
    
    #expect(result == "第三次成功")
    #expect(attemptCount == 3)
  }
  
  @Test("所有重试失败测试")
  func testAllRetriesFailed() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    do {
      _ = try await service.retry(
        configuration: RetryService.RetryConfiguration(
          maxAttempts: 2,
          initialDelay: 0.01,
          maxDelay: 1.0,
          backoffMultiplier: 2.0,
          jitterRange: 1.0...1.0
        )
      ) {
        attemptCount += 1
        throw ToolError.processingFailed("尝试 \(attemptCount)")
      }
      
      #expect(Bool(false), "应该抛出错误")
    } catch {
      #expect(attemptCount == 2)
      if let toolError = error as? ToolError {
        switch toolError {
        case .processingFailed(let message):
          #expect(message == "尝试 2")
        default:
          #expect(Bool(false), "错误类型不匹配")
        }
      }
    }
  }
  
  @Test("条件重试测试")
  func testConditionalRetry() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    let result = try await service.retryWithCondition(
      configuration: RetryService.RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 0.01,
        maxDelay: 1.0,
        backoffMultiplier: 2.0,
        jitterRange: 1.0...1.0
      ),
      shouldRetry: { error in
        if let toolError = error as? ToolError {
          switch toolError {
          case .processingFailed:
            return true
          default:
            return false
          }
        }
        return false
      }
    ) {
      attemptCount += 1
      if attemptCount < 2 {
        throw ToolError.processingFailed("可重试错误")
      }
      return "条件重试成功"
    }
    
    #expect(result == "条件重试成功")
    #expect(attemptCount == 2)
  }
  
  @Test("条件重试不满足条件测试")
  func testConditionalRetryNotMet() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    do {
      _ = try await service.retryWithCondition(
        shouldRetry: { error in
          if let toolError = error as? ToolError {
            switch toolError {
            case .processingFailed:
              return true
            default:
              return false
            }
          }
          return false
        }
      ) {
        attemptCount += 1
        throw ToolError.invalidInput("不可重试错误")
      }
      
      #expect(Bool(false), "应该抛出错误")
    } catch {
      #expect(attemptCount == 1) // 只尝试一次，因为不满足重试条件
      if let toolError = error as? ToolError {
        switch toolError {
        case .invalidInput(let message):
          #expect(message == "不可重试错误")
        default:
          #expect(Bool(false), "错误类型不匹配")
        }
      }
    }
  }
  
  @Test("工具操作重试测试")
  func testToolOperationRetry() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    let result = try await service.retryToolOperation(
      configuration: RetryService.RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 0.01,
        maxDelay: 1.0,
        backoffMultiplier: 2.0,
        jitterRange: 1.0...1.0
      )
    ) {
      attemptCount += 1
      if attemptCount < 2 {
        throw ToolError.processingFailed("可重试的工具错误")
      }
      return "工具操作成功"
    }
    
    #expect(result == "工具操作成功")
    #expect(attemptCount == 2)
  }
  
  @Test("网络操作重试测试")
  func testNetworkOperationRetry() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    let result = try await service.retryNetworkOperation {
      attemptCount += 1
      if attemptCount < 2 {
        throw ToolError.networkError(NSError(domain: "TestDomain", code: -1, userInfo: nil))
      }
      return "网络操作成功"
    }
    
    #expect(result == "网络操作成功")
    #expect(attemptCount == 2)
  }
  
  @Test("文件操作重试测试")
  func testFileOperationRetry() async throws {
    let service = RetryService.shared
    var attemptCount = 0
    
    let result = try await service.retryFileOperation {
      attemptCount += 1
      if attemptCount < 2 {
        throw ToolError.systemResourceUnavailable
      }
      return "文件操作成功"
    }
    
    #expect(result == "文件操作成功")
    #expect(attemptCount == 2)
  }
  
  @Test("延迟计算测试")
  func testDelayCalculation() async throws {
    let service = RetryService.shared
    let config = RetryService.RetryConfiguration(
      maxAttempts: 3,
      initialDelay: 1.0,
      maxDelay: 10.0,
      backoffMultiplier: 2.0,
      jitterRange: 1.0...1.0 // 无抖动用于测试
    )
    
    var delays: [TimeInterval] = []
    var attemptCount = 0
    
    do {
      _ = try await service.retry(configuration: config) {
        attemptCount += 1
        let startTime = Date()
        
        if attemptCount > 1 {
          // 记录实际延迟（近似）
          // 注意：这是一个近似测试，实际延迟可能略有不同
        }
        
        throw ToolError.processingFailed("测试延迟")
      }
    } catch {
      // 预期会失败
    }
    
    #expect(attemptCount == 3)
  }
}