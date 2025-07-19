//
//  AsyncOperationManagerTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
@testable import Tools

struct AsyncOperationManagerTests {
  
  @Test("AsyncOperationManager 单例测试")
  func testSingletonInstance() {
    let manager1 = AsyncOperationManager.shared
    let manager2 = AsyncOperationManager.shared
    
    #expect(manager1 === manager2)
  }
  
  @Test("AsyncOperation 基本属性测试")
  func testAsyncOperationBasicProperties() {
    let operation = AsyncOperation(id: "test-operation")
    
    #expect(operation.id == "test-operation")
    #expect(operation.progress == 0.0)
    #expect(operation.isCompleted == false)
    #expect(operation.isCancelled == false)
    #expect(operation.error == nil)
    #expect(operation.isRunning == true)
    #expect(operation.duration >= 0)
  }
  
  @Test("AsyncOperation 取消功能测试")
  func testAsyncOperationCancellation() {
    let operation = AsyncOperation(id: "cancel-test")
    
    #expect(operation.isCancelled == false)
    #expect(operation.isRunning == true)
    
    operation.cancel()
    
    #expect(operation.isCancelled == true)
    #expect(operation.isRunning == false)
  }
  
  @Test("简单异步操作执行测试")
  func testSimpleAsyncOperationExecution() async throws {
    let manager = AsyncOperationManager.shared
    let expectation = AsyncExpectation()
    
    let operation = manager.executeSimple(id: "simple-test") {
      return "测试结果"
    } onCompletion: { result in
      switch result {
      case .success(let value):
        #expect(value == "测试结果")
        expectation.fulfill()
      case .failure:
        #expect(Bool(false), "操作不应该失败")
      }
    }
    
    #expect(operation.id == "simple-test")
    await expectation.wait()
  }
  
  @Test("异步操作错误处理测试")
  func testAsyncOperationErrorHandling() async throws {
    let manager = AsyncOperationManager.shared
    let expectation = AsyncExpectation()
    
    manager.executeSimple(id: "error-test") {
      throw ToolError.invalidInput("测试错误")
    } onCompletion: { result in
      switch result {
      case .success:
        #expect(Bool(false), "操作应该失败")
      case .failure(let error):
        if let toolError = error as? ToolError {
          switch toolError {
          case .invalidInput(let message):
            #expect(message == "测试错误")
          default:
            #expect(Bool(false), "错误类型不匹配")
          }
        }
        expectation.fulfill()
      }
    }
    
    await expectation.wait()
  }
  
  @Test("带进度的异步操作测试")
  func testAsyncOperationWithProgress() async throws {
    let manager = AsyncOperationManager.shared
    let expectation = AsyncExpectation()
    var progressValues: [Double] = []
    
    manager.execute(id: "progress-test") { progressCallback, isCancelled in
      for i in 0...10 {
        guard !isCancelled() else {
          throw CancellationError()
        }
        
        let progress = Double(i) / 10.0
        progressCallback(progress)
        
        // 模拟工作
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
      }
      return "完成"
    } onProgress: { progress in
      progressValues.append(progress)
    } onCompletion: { result in
      switch result {
      case .success(let value):
        #expect(value == "完成")
        expectation.fulfill()
      case .failure:
        #expect(Bool(false), "操作不应该失败")
      }
    }
    
    await expectation.wait()
    #expect(progressValues.count > 0)
    #expect(progressValues.last == 1.0)
  }
  
  @Test("操作取消测试")
  func testOperationCancellation() async throws {
    let manager = AsyncOperationManager.shared
    let expectation = AsyncExpectation()
    
    let operation = manager.execute(id: "cancel-operation-test") { _, isCancelled in
      for i in 0...100 {
        guard !isCancelled() else {
          throw CancellationError()
        }
        try await Task.sleep(nanoseconds: 10_000_000)
      }
      return "不应该完成"
    } onCompletion: { result in
      switch result {
      case .success:
        #expect(Bool(false), "操作应该被取消")
      case .failure(let error):
        #expect(error is CancellationError)
        expectation.fulfill()
      }
    }
    
    // 短暂延迟后取消操作
    try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    manager.cancelOperation(id: "cancel-operation-test")
    
    await expectation.wait()
  }
  
  @Test("重试机制测试")
  func testRetryMechanism() async throws {
    let manager = AsyncOperationManager.shared
    let expectation = AsyncExpectation()
    var attemptCount = 0
    
    manager.executeWithRetry(
      id: "retry-test",
      maxRetries: 3,
      retryDelay: 0.1
    ) { _, _ in
      attemptCount += 1
      if attemptCount < 3 {
        throw ToolError.processingFailed("尝试 \(attemptCount)")
      }
      return "第三次成功"
    } onCompletion: { result in
      switch result {
      case .success(let value):
        #expect(value == "第三次成功")
        #expect(attemptCount == 3)
        expectation.fulfill()
      case .failure:
        #expect(Bool(false), "重试应该成功")
      }
    }
    
    await expectation.wait()
  }
  
  @Test("批量操作测试")
  func testBatchOperations() async throws {
    let manager = AsyncOperationManager.shared
    let expectation = AsyncExpectation()
    
    let operations = [
      ("op1", { return "结果1" }),
      ("op2", { return "结果2" }),
      ("op3", { return "结果3" })
    ]
    
    manager.executeBatch(operations: operations) { result in
      switch result {
      case .success(let results):
        #expect(results.count == 3)
        #expect(results[0] == "结果1")
        #expect(results[1] == "结果2")
        #expect(results[2] == "结果3")
        expectation.fulfill()
      case .failure:
        #expect(Bool(false), "批量操作不应该失败")
      }
    }
    
    await expectation.wait()
  }
  
  @Test("操作管理功能测试")
  func testOperationManagement() async throws {
    let manager = AsyncOperationManager.shared
    
    // 清空所有操作
    manager.cancelAllOperations()
    #expect(manager.activeOperationCount == 0)
    #expect(manager.isAnyOperationRunning == false)
    
    // 添加操作
    let operation = manager.executeSimple(id: "management-test") {
      try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
      return "完成"
    }
    
    #expect(manager.activeOperationCount == 1)
    #expect(manager.isAnyOperationRunning == true)
    
    let retrievedOperation = manager.getOperation(id: "management-test")
    #expect(retrievedOperation?.id == operation.id)
    
    let allOperations = manager.getAllOperations()
    #expect(allOperations.count == 1)
    
    // 等待操作完成
    try await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
    
    #expect(manager.activeOperationCount == 0)
    #expect(manager.isAnyOperationRunning == false)
  }
}

// MARK: - Test Helper

class AsyncExpectation {
  private var isFulfilled = false
  private let semaphore = DispatchSemaphore(value: 0)
  
  func fulfill() {
    guard !isFulfilled else { return }
    isFulfilled = true
    semaphore.signal()
  }
  
  func wait() async {
    await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        self.semaphore.wait()
        continuation.resume()
      }
    }
  }
}