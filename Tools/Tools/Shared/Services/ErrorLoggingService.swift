//
//  ErrorLoggingService.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import OSLog
import SwiftUI

/// Service for logging and managing application errors
@Observable
class ErrorLoggingService {
  static let shared = ErrorLoggingService()

  private let logger = Logger(subsystem: "com.tools.app", category: "ErrorLogging")
  private var errorHistory: [ErrorLogEntry] = []
  private let maxHistoryCount = 500

  private init() {}

  struct ErrorLogEntry: Identifiable, Codable {
    let id: UUID
    let error: String
    let errorType: String
    let timestamp: Date
    let context: String?
    let isRetryable: Bool
    let stackTrace: String?

    init(error: ToolError, context: String? = nil, stackTrace: String? = nil) {
      id = UUID()
      self.error = error.localizedDescription
      errorType = String(describing: error)
      timestamp = Date()
      self.context = context
      isRetryable = error.isRetryable
      self.stackTrace = stackTrace
    }
  }

  /// Log an error with optional context
  func logError(
    _ error: ToolError,
    context: String? = nil,
    file: String = #file,
    function: String = #function,
    line: Int = #line) {
    let stackTrace = "\(file):\(function):\(line)"
    let entry = ErrorLogEntry(error: error, context: context, stackTrace: stackTrace)

    // Add to history
    errorHistory.append(entry)

    // Maintain history size limit
    if errorHistory.count > maxHistoryCount {
      errorHistory.removeFirst(errorHistory.count - maxHistoryCount)
    }

    // Log to system logger
    logger.error("🚨 \(error.localizedDescription, privacy: .public)")
    if let context {
      logger.info("Context: \(context, privacy: .public)")
    }
    logger.info("Location: \(stackTrace, privacy: .public)")
    logger.info("Retryable: \(error.isRetryable ? "Yes" : "No", privacy: .public)")

    // Save to persistent storage
    saveToPersistentStorage()
  }

  /// Get error history
  func getErrorHistory() -> [ErrorLogEntry] {
    errorHistory
  }

  /// Clear error history
  func clearErrorHistory() {
    errorHistory.removeAll()
    saveToPersistentStorage()
    logger.info("Error history cleared")
  }

  /// Get errors by type
  func getErrors(ofType type: String) -> [ErrorLogEntry] {
    errorHistory.filter { $0.errorType.contains(type) }
  }

  /// Get recent errors (last 24 hours)
  func getRecentErrors() -> [ErrorLogEntry] {
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    return errorHistory.filter { $0.timestamp >= yesterday }
  }

  /// Get error statistics
  func getErrorStatistics() -> ErrorStatistics {
    let total = errorHistory.count
    let retryable = errorHistory.filter(\.isRetryable).count
    let recent = getRecentErrors().count

    var errorTypeCounts: [String: Int] = [:]
    for entry in errorHistory {
      let type = entry.errorType.components(separatedBy: "(").first ?? entry.errorType
      errorTypeCounts[type, default: 0] += 1
    }

    return ErrorStatistics(
      totalErrors: total,
      retryableErrors: retryable,
      recentErrors: recent,
      errorTypeCounts: errorTypeCounts)
  }

  // MARK: - Persistent Storage

  private var storageURL: URL {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first!
    return documentsPath.appendingPathComponent("error_log.json")
  }

  private func saveToPersistentStorage() {
    do {
      let data = try JSONEncoder().encode(errorHistory)
      try data.write(to: storageURL)
    } catch {
      logger.error("Failed to save error log: \(error.localizedDescription, privacy: .public)")
    }
  }

  private func loadFromPersistentStorage() {
    do {
      let data = try Data(contentsOf: storageURL)
      errorHistory = try JSONDecoder().decode([ErrorLogEntry].self, from: data)
    } catch {
      // File doesn't exist or is corrupted, start fresh
      errorHistory = []
    }
  }

  /// Initialize the service (call on app startup) - optimized for startup performance
  func initialize() async {
    // Load from persistent storage in background to avoid blocking startup
    // No need to wait for completion - fully asynchronous
    Task.detached(priority: .utility) {
      await self.loadFromPersistentStorageAsync()
      await MainActor.run {
        self.logger
          .info(
            "ErrorLoggingService initialized with \(self.errorHistory.count) historical entries")
      }
    }

    // Set up automatic error log cleanup to prevent excessive memory usage
    setupAutomaticCleanup()
  }

  private func setupAutomaticCleanup() {
    // Schedule periodic cleanup of old error logs
    // This runs once a day to prevent error log from growing too large
    Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
      self?.cleanupOldErrors()
    }
  }

  private func cleanupOldErrors() {
    // Keep only last 30 days of errors
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

    let oldErrors = errorHistory.filter { $0.timestamp < thirtyDaysAgo }
    for oldError in oldErrors {
      if let index = errorHistory.firstIndex(where: { $0.id == oldError.id }) {
        errorHistory.remove(at: index)
      }
    }

    // Save changes
    saveToPersistentStorage()

    logger.info("Cleaned up \(oldErrors.count) old error logs")
  }

  private func loadFromPersistentStorageAsync() async {
    do {
      let data = try Data(contentsOf: storageURL)
      let history = try JSONDecoder().decode([ErrorLogEntry].self, from: data)
      await MainActor.run {
        self.errorHistory = history
      }
    } catch {
      // File doesn't exist or is corrupted, start fresh
      await MainActor.run {
        self.errorHistory = []
      }
    }
  }
}

// MARK: - Error Statistics

struct ErrorStatistics {
  let totalErrors: Int
  let retryableErrors: Int
  let recentErrors: Int
  let errorTypeCounts: [String: Int]

  var mostCommonErrorType: String? {
    errorTypeCounts.max(by: { $0.value < $1.value })?.key
  }

  var retryablePercentage: Double {
    guard totalErrors > 0 else { return 0 }
    return Double(retryableErrors) / Double(totalErrors) * 100
  }
}

// MARK: - Global Error Handler Extension

extension View {
  /// Apply global error handling to a view
  func withErrorHandling() -> some View {
    onAppear {
      // Initialize error logging service if needed
      Task {
        await ErrorLoggingService.shared.initialize()
      }
    }
  }
}
