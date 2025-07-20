//
//  AsyncOperationManager.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import SwiftUI

/// Manager for handling async operations with proper cancellation and progress tracking
@Observable
class AsyncOperationManager {
  static let shared = AsyncOperationManager()
  
  private var activeOperations: [String: AsyncOperation] = [:]
  private let operationQueue = OperationQueue()
  
  var isAnyOperationRunning: Bool {
    !activeOperations.isEmpty
  }
  
  var activeOperationCount: Int {
    activeOperations.count
  }
  
  private init() {
    // Defer operation queue configuration to improve startup performance
    configureOperationQueue()
  }
  
  private func configureOperationQueue() {
    operationQueue.maxConcurrentOperationCount = 3 // Limit concurrent operations
    operationQueue.qualityOfService = .userInitiated
  }
  
  // MARK: - Operation Management
  
  /// Execute an async operation with progress tracking and cancellation support
  @discardableResult
  func execute<T>(
    id: String = UUID().uuidString,
    operation: @escaping (@escaping (Double) -> Void, @escaping () -> Bool) async throws -> T,
    onProgress: ((Double) -> Void)? = nil,
    onCompletion: ((Result<T, Error>) -> Void)? = nil
  ) -> AsyncOperation {
    
    // Cancel existing operation with same ID
    cancelOperation(id: id)
    
    let asyncOp = AsyncOperation(id: id)
    activeOperations[id] = asyncOp
    
    Task {
      do {
        let result = try await operation(
          { progress in
            Task { @MainActor in
              asyncOp.progress = progress
              onProgress?(progress)
            }
          },
          {
            asyncOp.isCancelled
          }
        )
        
        await MainActor.run {
          asyncOp.isCompleted = true
          activeOperations.removeValue(forKey: id)
          onCompletion?(.success(result))
        }
      } catch {
        await MainActor.run {
          asyncOp.isCompleted = true
          asyncOp.error = error
          activeOperations.removeValue(forKey: id)
          onCompletion?(.failure(error))
        }
      }
    }
    
    return asyncOp
  }
  
  /// Execute a simple async operation without progress tracking
  @discardableResult
  func executeSimple<T>(
    id: String = UUID().uuidString,
    operation: @escaping () async throws -> T,
    onCompletion: ((Result<T, Error>) -> Void)? = nil
  ) -> AsyncOperation {
    
    return execute(id: id) { _, isCancelled in
      guard !isCancelled() else {
        throw CancellationError()
      }
      return try await operation()
    } onCompletion: { result in
      onCompletion?(result)
    }
  }
  
  /// Execute an operation with automatic retry
  @discardableResult
  func executeWithRetry<T>(
    id: String = UUID().uuidString,
    maxRetries: Int = 3,
    retryDelay: TimeInterval = 1.0,
    operation: @escaping (@escaping (Double) -> Void, @escaping () -> Bool) async throws -> T,
    onProgress: ((Double) -> Void)? = nil,
    onCompletion: ((Result<T, Error>) -> Void)? = nil
  ) -> AsyncOperation {
    
    return execute(id: id) { progressCallback, isCancelled in
      var lastError: Error?
      
      for attempt in 0..<maxRetries {
        guard !isCancelled() else {
          throw CancellationError()
        }
        
        do {
          let result = try await operation(progressCallback, isCancelled)
          return result
        } catch {
          lastError = error
          
          if attempt < maxRetries - 1 {
            // Wait before retry
            try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
          }
        }
      }
      
      throw lastError ?? ToolError.unknown("All retry attempts failed")
    } onProgress: { progress in
      onProgress?(progress)
    } onCompletion: { result in
      onCompletion?(result)
    }
  }
  
  // MARK: - Operation Control
  
  func cancelOperation(id: String) {
    if let operation = activeOperations[id] {
      operation.cancel()
      activeOperations.removeValue(forKey: id)
    }
  }
  
  func cancelAllOperations() {
    for operation in activeOperations.values {
      operation.cancel()
    }
    activeOperations.removeAll()
  }
  
  func getOperation(id: String) -> AsyncOperation? {
    return activeOperations[id]
  }
  
  func getAllOperations() -> [AsyncOperation] {
    return Array(activeOperations.values)
  }
  
  // MARK: - Batch Operations
  
  /// Execute multiple operations concurrently
  func executeBatch<T>(
    operations: [(id: String, operation: () async throws -> T)],
    onProgress: ((Double) -> Void)? = nil,
    onCompletion: ((Result<[T], Error>) -> Void)? = nil
  ) {
    
    let batchId = "batch_\(UUID().uuidString)"
    var results: [T] = []
    var completedCount = 0
    let totalCount = operations.count
    
    Task {
      do {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
          for (index, (id, operation)) in operations.enumerated() {
            group.addTask {
              let result = try await operation()
              return (index, result)
            }
          }
          
          results = Array(repeating: nil as T?, count: totalCount) as! [T]
          
          for try await (index, result) in group {
            results[index] = result
            completedCount += 1
            
            let progress = Double(completedCount) / Double(totalCount)
            await MainActor.run {
              onProgress?(progress)
            }
          }
        }
        
        await MainActor.run {
          onCompletion?(.success(results))
        }
      } catch {
        await MainActor.run {
          onCompletion?(.failure(error))
        }
      }
    }
  }
}

// MARK: - AsyncOperation Class
@Observable
class AsyncOperation {
  let id: String
  var progress: Double = 0.0
  var isCompleted: Bool = false
  var isCancelled: Bool = false
  var error: Error?
  let startTime: Date
  
  init(id: String) {
    self.id = id
    self.startTime = Date()
  }
  
  func cancel() {
    isCancelled = true
  }
  
  var duration: TimeInterval {
    Date().timeIntervalSince(startTime)
  }
  
  var isRunning: Bool {
    !isCompleted && !isCancelled
  }
}

// MARK: - Cancellation Error
struct CancellationError: LocalizedError {
  var errorDescription: String? {
    return "操作已取消"
  }
}

// MARK: - View Extensions
extension View {
  /// Execute an async operation with loading state management
  func withAsyncOperation<T>(
    id: String = UUID().uuidString,
    operation: @escaping (@escaping (Double) -> Void, @escaping () -> Bool) async throws -> T,
    loadingMessage: String = "处理中...",
    onSuccess: @escaping (T) -> Void,
    onError: @escaping (Error) -> Void
  ) -> some View {
    self.modifier(
      AsyncOperationModifier(
        id: id,
        operation: operation,
        loadingMessage: loadingMessage,
        onSuccess: onSuccess,
        onError: onError
      )
    )
  }
}

// MARK: - Async Operation View Modifier
struct AsyncOperationModifier<T>: ViewModifier {
  let id: String
  let operation: (@escaping (Double) -> Void, @escaping () -> Bool) async throws -> T
  let loadingMessage: String
  let onSuccess: (T) -> Void
  let onError: (Error) -> Void
  
  @State private var isLoading = false
  @State private var progress: Double = 0.0
  @State private var currentOperation: AsyncOperation?
  
  func body(content: Content) -> some View {
    ZStack {
      content
        .disabled(isLoading)
      
      if isLoading {
        Color.black.opacity(0.3)
          .ignoresSafeArea()
        
        ProcessingStateView.withProgress(
          isProcessing: true,
          message: loadingMessage,
          progress: progress
        )
      }
    }
  }
  
  func executeOperation() {
    isLoading = true
    progress = 0.0
    
    currentOperation = AsyncOperationManager.shared.execute(
      id: id,
      operation: operation,
      onProgress: { newProgress in
        progress = newProgress
      },
      onCompletion: { result in
        isLoading = false
        currentOperation = nil
        
        switch result {
        case .success(let value):
          onSuccess(value)
        case .failure(let error):
          onError(error)
        }
      }
    )
  }
  
  func cancelOperation() {
    currentOperation?.cancel()
    isLoading = false
    currentOperation = nil
  }
}