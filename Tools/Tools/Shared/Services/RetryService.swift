//
//  RetryService.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import SwiftUI

/// Service for handling retry logic with exponential backoff
actor RetryService {
  static let shared = RetryService()

  private init() {}

  struct RetryConfiguration {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    let jitterRange: ClosedRange<Double>

    static let `default` = RetryConfiguration(
      maxAttempts: 3,
      initialDelay: 1.0,
      maxDelay: 30.0,
      backoffMultiplier: 2.0,
      jitterRange: 0.8...1.2)

    static let aggressive = RetryConfiguration(
      maxAttempts: 5,
      initialDelay: 0.5,
      maxDelay: 60.0,
      backoffMultiplier: 2.5,
      jitterRange: 0.7...1.3)

    static let conservative = RetryConfiguration(
      maxAttempts: 2,
      initialDelay: 2.0,
      maxDelay: 10.0,
      backoffMultiplier: 1.5,
      jitterRange: 0.9...1.1)
  }

  /// Retry an async operation with exponential backoff
  func retry<T>(
    configuration: RetryConfiguration = .default,
    operation: @escaping () async throws -> T) async throws -> T {
    var lastError: Error?

    for attempt in 1...configuration.maxAttempts {
      do {
        let result = try await operation()

        // Log successful retry if it wasn't the first attempt
        if attempt > 1 {
          ErrorLoggingService.shared.logError(
            .unknown("Operation succeeded after \(attempt) attempts"),
            context: "RetryService")
        }

        return result
      } catch {
        lastError = error

        // Log the retry attempt
        let toolError = error as? ToolError ?? .unknown(error.localizedDescription)
        ErrorLoggingService.shared.logError(
          toolError,
          context: "RetryService - Attempt \(attempt)/\(configuration.maxAttempts)")

        // Don't wait after the last attempt
        if attempt < configuration.maxAttempts {
          let delay = calculateDelay(
            attempt: attempt,
            configuration: configuration)

          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
      }
    }

    // All attempts failed, throw the last error
    throw lastError ?? ToolError.unknown("Retry operation failed")
  }

  /// Retry an operation with a condition check
  func retryWithCondition<T>(
    configuration: RetryConfiguration = .default,
    shouldRetry: @escaping (Error) -> Bool,
    operation: @escaping () async throws -> T) async throws -> T {
    var lastError: Error?

    for attempt in 1...configuration.maxAttempts {
      do {
        return try await operation()
      } catch {
        lastError = error

        // Check if we should retry this error
        guard shouldRetry(error) else {
          throw error
        }

        // Log the retry attempt
        let toolError = error as? ToolError ?? .unknown(error.localizedDescription)
        ErrorLoggingService.shared.logError(
          toolError,
          context: "ConditionalRetry - Attempt \(attempt)/\(configuration.maxAttempts)")

        // Don't wait after the last attempt
        if attempt < configuration.maxAttempts {
          let delay = calculateDelay(
            attempt: attempt,
            configuration: configuration)

          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
      }
    }

    throw lastError ?? ToolError.unknown("Conditional retry operation failed")
  }

  /// Calculate delay with exponential backoff and jitter
  private func calculateDelay(
    attempt: Int,
    configuration: RetryConfiguration) -> TimeInterval {
    let exponentialDelay = configuration.initialDelay * pow(
      configuration.backoffMultiplier,
      Double(attempt - 1))
    let cappedDelay = min(exponentialDelay, configuration.maxDelay)

    // Add jitter to prevent thundering herd
    let jitter = Double.random(in: configuration.jitterRange)
    return cappedDelay * jitter
  }
}

// MARK: - Convenience Extensions

extension RetryService {
  /// Retry specifically for ToolError types
  func retryToolOperation<T>(
    configuration: RetryConfiguration = .default,
    operation: @escaping () async throws -> T) async throws -> T {
    try await retryWithCondition(
      configuration: configuration,
      shouldRetry: { error in
        if let toolError = error as? ToolError {
          return toolError.isRetryable
        }
        return false
      },
      operation: operation)
  }

  /// Retry network operations
  func retryNetworkOperation<T>(
    operation: @escaping () async throws -> T) async throws -> T {
    try await retryWithCondition(
      configuration: .aggressive,
      shouldRetry: { error in
        if let toolError = error as? ToolError {
          switch toolError {
          case .networkError, .noInternetConnection, .timeout:
            return true
          default:
            return false
          }
        }
        return false
      },
      operation: operation)
  }

  /// Retry file operations
  func retryFileOperation<T>(
    operation: @escaping () async throws -> T) async throws -> T {
    try await retryWithCondition(
      configuration: .conservative,
      shouldRetry: { error in
        if let toolError = error as? ToolError {
          switch toolError {
          case .systemResourceUnavailable:
            return true
          default:
            return false
          }
        }
        return false
      },
      operation: operation)
  }
}

// MARK: - View Extension for Retry Operations

extension View {
  /// Execute an operation with retry capability
  func withRetry<T>(
    configuration: RetryService.RetryConfiguration = .default,
    operation: @escaping () async throws -> T,
    onSuccess: @escaping (T) -> Void,
    onError: @escaping (ToolError) -> Void) -> some View {
    task {
      do {
        let result = try await RetryService.shared.retry(
          configuration: configuration,
          operation: operation)
        await MainActor.run {
          onSuccess(result)
        }
      } catch {
        let toolError = error as? ToolError ?? .unknown(error.localizedDescription)
        await MainActor.run {
          onError(toolError)
        }
      }
    }
  }
}
