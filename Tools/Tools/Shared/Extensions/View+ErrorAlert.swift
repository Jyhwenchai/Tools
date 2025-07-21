//
//  View+ErrorAlert.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
  @Binding var error: ToolError?
  let onRetry: (() -> Void)?

  func body(content: Content) -> some View {
    content
      .alert(
        "错误",
        isPresented: .constant(error != nil),
        presenting: error) { toolError in
        // Primary action button
        Button("确定") {
          error = nil
        }

        // Retry button for retryable errors
        if toolError.isRetryable, let onRetry {
          Button("重试") {
            error = nil
            onRetry()
          }
        }
      } message: { toolError in
        VStack(alignment: .leading, spacing: 8) {
          Text(toolError.localizedDescription)

          if let suggestion = toolError.recoverySuggestion {
            Text(suggestion)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }
  }
}

// MARK: - Enhanced Error Alert Extension

extension View {
  /// Basic error alert without retry functionality
  func errorAlert(_ error: Binding<ToolError?>) -> some View {
    modifier(ErrorAlertModifier(error: error, onRetry: nil))
  }

  /// Enhanced error alert with retry functionality
  func errorAlert(_ error: Binding<ToolError?>, onRetry: @escaping () -> Void) -> some View {
    modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
  }
}

// MARK: - Error State Management

@Observable
class ErrorManager {
  var currentError: ToolError?
  private var errorLog: [ErrorLogEntry] = []

  struct ErrorLogEntry {
    let error: ToolError
    let timestamp: Date
    let context: String?

    init(error: ToolError, context: String? = nil) {
      self.error = error
      timestamp = Date()
      self.context = context
    }
  }

  func handleError(_ error: ToolError, context: String? = nil) {
    // Log the error
    logError(error, context: context)

    // Set current error for UI display
    currentError = error
  }

  func clearError() {
    currentError = nil
  }

  private func logError(_ error: ToolError, context: String?) {
    let entry = ErrorLogEntry(error: error, context: context)
    errorLog.append(entry)

    // Keep only last 100 error entries
    if errorLog.count > 100 {
      errorLog.removeFirst(errorLog.count - 100)
    }

    // Print to console for debugging
    print("🚨 Error logged: \(error.localizedDescription)")
    if let context {
      print("   Context: \(context)")
    }
    print("   Timestamp: \(entry.timestamp)")
    print("   Retryable: \(error.isRetryable)")
  }

  func getErrorLog() -> [ErrorLogEntry] {
    errorLog
  }

  func clearErrorLog() {
    errorLog.removeAll()
  }
}
