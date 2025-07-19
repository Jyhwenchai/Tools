//
//  PerformanceTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
@testable import Tools

struct PerformanceTests {
  
  // MARK: - Basic Performance Tests
  
  @Test("大数据处理性能测试", .timeLimit(.minutes(1)))
  func testLargeDataProcessingPerformance() async throws {
    // 创建大文本数据 (1MB)
    let largeText = String(repeating: "A", count: 1024 * 1024)
    
    let startTime = Date()
    
    // 测试字符串处理性能
    let processedText = largeText.uppercased()
    
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)
    
    #expect(!processedText.isEmpty)
    #expect(processedText.count == largeText.count)
    #expect(processingTime < 5.0) // 应该在5秒内完成
    
    print("大数据处理时间: \(String(format: "%.3f", processingTime))秒")
  }
  
  @Test("大量数据创建性能测试", .timeLimit(.minutes(1)))
  func testBulkDataCreationPerformance() async throws {
    let itemCount = 10000
    let startTime = Date()
    
    var items: [String] = []
    for i in 0..<itemCount {
      items.append("项目 \(i)")
    }
    
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)
    
    #expect(items.count == itemCount)
    #expect(processingTime < 2.0) // 应该在2秒内完成
    
    print("创建\(itemCount)个项目时间: \(String(format: "%.3f", processingTime))秒")
  }
  
  // MARK: - Memory Usage Performance Tests
  
  @Test("内存使用性能测试")
  func testMemoryUsagePerformance() async throws {
    let performanceMonitor = PerformanceMonitor.shared
    
    let initialMemory = performanceMonitor.currentMemoryUsage
    
    // 执行内存密集型操作
    var largeArrays: [[String]] = []
    for i in 0..<100 {
      let largeArray = Array(repeating: "测试字符串 \(i)", count: 1000)
      largeArrays.append(largeArray)
    }
    
    // 等待内存监控更新
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    
    let peakMemory = performanceMonitor.currentMemoryUsage
    
    // 清理内存
    largeArrays.removeAll()
    
    // 等待垃圾回收
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    
    let finalMemory = performanceMonitor.currentMemoryUsage
    
    #expect(peakMemory >= initialMemory)
    #expect(finalMemory <= peakMemory)
    
    print("初始内存: \(String(format: "%.1f", initialMemory))MB")
    print("峰值内存: \(String(format: "%.1f", peakMemory))MB")
    print("最终内存: \(String(format: "%.1f", finalMemory))MB")
  }
  
  // MARK: - Concurrent Operations Performance Tests
  
  @Test("并发操作性能测试", .timeLimit(.minutes(1)))
  func testConcurrentOperationsPerformance() async throws {
    let asyncManager = AsyncOperationManager.shared
    
    let operationCount = 50
    let operations = (0..<operationCount).map { index in
      (id: "concurrent-op-\(index)", operation: {
        // 模拟计算密集型操作
        let result = (0..<1000).reduce(0) { sum, i in
          sum + i * index
        }
        return "结果: \(result)"
      })
    }
    
    let startTime = Date()
    
    let expectation = TestExpectation()
    var completedResults: [String] = []
    
    asyncManager.executeBatch(operations: operations, onCompletion: { result in
      switch result {
      case .success(let results):
        completedResults = results
        expectation.fulfill()
      case .failure(let error):
        print("批量操作失败: \(error)")
        expectation.fulfill()
      }
    })
    
    await expectation.wait()
    
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)
    
    #expect(completedResults.count == operationCount)
    #expect(processingTime < 10.0) // 应该在10秒内完成
    
    print("并发操作处理时间: \(String(format: "%.3f", processingTime))秒")
    print("平均每个操作时间: \(String(format: "%.3f", processingTime / Double(operationCount)))秒")
  }
  
  // MARK: - Data Structure Performance Tests
  
  @Test("数据结构性能测试", .timeLimit(.minutes(1)))
  func testDataStructurePerformance() async throws {
    // 创建大量粘贴板项目
    let itemCount = 1000
    let startTime = Date()
    
    var clipboardItems: [ClipboardItem] = []
    for i in 0..<itemCount {
      let item = ClipboardItem(
        content: "粘贴板项目 \(i) - " + String(repeating: "内容", count: 100),
        type: .text
      )
      clipboardItems.append(item)
    }
    
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)
    
    #expect(clipboardItems.count == itemCount)
    #expect(processingTime < 5.0) // 应该在5秒内完成
    
    // 测试搜索性能
    let searchStartTime = Date()
    let searchResults = clipboardItems.filter { $0.content.contains("项目 500") }
    let searchEndTime = Date()
    let searchTime = searchEndTime.timeIntervalSince(searchStartTime)
    
    #expect(!searchResults.isEmpty)
    #expect(searchTime < 1.0) // 搜索应该在1秒内完成
    
    print("创建\(itemCount)个粘贴板项目时间: \(String(format: "%.3f", processingTime))秒")
    print("搜索时间: \(String(format: "%.3f", searchTime))秒")
  }
  
  // MARK: - Error Handling Performance Tests
  
  @Test("错误处理性能测试", .timeLimit(.minutes(1)))
  func testErrorHandlingPerformance() async throws {
    let retryService = RetryService.shared
    
    let errorCount = 100
    let startTime = Date()
    
    var handledErrors: [ToolError] = []
    
    for i in 0..<errorCount {
      do {
        _ = try await retryService.retry(
          configuration: RetryService.RetryConfiguration(
            maxAttempts: 2,
            initialDelay: 0.001, // 很短的延迟
            maxDelay: 0.01,
            backoffMultiplier: 1.5,
            jitterRange: 1.0...1.0
          )
        ) {
          throw ToolError.processingFailed("测试错误 \(i)")
        }
      } catch {
        if let toolError = error as? ToolError {
          handledErrors.append(toolError)
        }
      }
    }
    
    let endTime = Date()
    let processingTime = endTime.timeIntervalSince(startTime)
    
    #expect(handledErrors.count == errorCount)
    #expect(processingTime < 3.0) // 应该在3秒内完成
    
    print("处理\(errorCount)个错误时间: \(String(format: "%.3f", processingTime))秒")
    print("平均每个错误处理时间: \(String(format: "%.3f", processingTime / Double(errorCount)))秒")
  }
  
  // MARK: - Overall System Performance Tests
  
  @Test("系统整体性能测试", .timeLimit(.minutes(1)))
  func testOverallSystemPerformance() async throws {
    let startTime = Date()
    
    // 模拟用户使用多个工具的场景
    let performanceMonitor = PerformanceMonitor.shared
    let asyncManager = AsyncOperationManager.shared
    
    // 1. 性能监控
    let report = performanceMonitor.getPerformanceReport()
    #expect(report.averageMemoryUsage >= 0)
    
    // 2. 异步操作管理
    #expect(asyncManager.activeOperationCount >= 0)
    
    // 3. 数据处理
    let testData = Array(0..<1000).map { "数据 \($0)" }
    let processedData = testData.filter { $0.contains("数据") }
    #expect(processedData.count == testData.count)
    
    let endTime = Date()
    let totalTime = endTime.timeIntervalSince(startTime)
    
    #expect(totalTime < 5.0) // 整体操作应该在5秒内完成
    
    print("系统整体性能测试时间: \(String(format: "%.3f", totalTime))秒")
  }
}

// MARK: - Performance Test Helper

class TestExpectation: @unchecked Sendable {
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