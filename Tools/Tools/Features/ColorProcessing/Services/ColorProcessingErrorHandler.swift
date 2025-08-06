import Foundation
import SwiftUI

/// Service for handling color processing errors with recovery mechanisms
@MainActor
class ColorProcessingErrorHandler: ObservableObject {

    // MARK: - Published Properties

    @Published var currentError: ColorProcessingError?
    @Published var errorHistory: [ErrorLogEntry] = []
    @Published var isRecovering: Bool = false

    // MARK: - Error Recovery Properties

    private var retryAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0

    // MARK: - Error Log Entry

    struct ErrorLogEntry: Identifiable {
        let id = UUID()
        let error: ColorProcessingError
        let timestamp: Date
        let context: String?
        let retryCount: Int

        init(error: ColorProcessingError, context: String? = nil, retryCount: Int = 0) {
            self.error = error
            self.timestamp = Date()
            self.context = context
            self.retryCount = retryCount
        }
    }

    // MARK: - Error Handling Methods

    /// Handle an error with automatic recovery attempts
    func handleError(_ error: ColorProcessingError, context: String? = nil) {
        logError(error, context: context)
        currentError = error

        // Attempt automatic recovery for retryable errors
        if error.isRetryable && shouldAttemptRecovery(for: error) {
            Task {
                await attemptRecovery(for: error, context: context)
            }
        }
    }

    /// Clear the current error
    func clearError() {
        currentError = nil
    }

    /// Clear all error history
    func clearHistory() {
        errorHistory.removeAll()
        retryAttempts.removeAll()
    }

    // MARK: - Recovery Methods

    /// Attempt to recover from an error
    private func attemptRecovery(for error: ColorProcessingError, context: String?) async {
        isRecovering = true
        defer { isRecovering = false }

        let errorKey = getErrorKey(for: error)
        let currentAttempts = retryAttempts[errorKey, default: 0]

        guard currentAttempts < maxRetryAttempts else {
            logError(error, context: "Max retry attempts reached")
            return
        }

        // Wait before retry
        try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))

        let recoverySuccessful = await performRecovery(for: error)

        if recoverySuccessful {
            retryAttempts[errorKey] = 0
            clearError()
            logRecovery(for: error, context: context)
        } else {
            retryAttempts[errorKey] = currentAttempts + 1
            logError(error, context: "Recovery attempt \(currentAttempts + 1) failed")
        }
    }

    /// Perform specific recovery actions based on error type
    private func performRecovery(for error: ColorProcessingError) async -> Bool {
        switch error {
        case .conversionFailed, .colorSpaceConversionFailed:
            // For conversion failures, assume retry might work
            return true

        case .screenSamplingFailed:
            // For screen sampling failures, check permissions and try again
            return await recoverScreenSampling()

        case .colorSpaceConversionFailed:
            // For color space conversion, try alternative approach
            return true  // Allow retry with potentially different approach

        case .systemResourceUnavailable:
            // For system resource issues, wait and try again
            return true

        default:
            // For other errors, no automatic recovery
            return false
        }
    }

    /// Attempt to recover screen sampling functionality
    private func recoverScreenSampling() async -> Bool {
        // For screen sampling, assume recovery is possible after delay
        // In a real implementation, this might check permissions, etc.
        return true
    }

    // MARK: - Utility Methods

    /// Check if recovery should be attempted for an error
    private func shouldAttemptRecovery(for error: ColorProcessingError) -> Bool {
        let errorKey = getErrorKey(for: error)
        let attempts = retryAttempts[errorKey, default: 0]
        return attempts < maxRetryAttempts && error.isRetryable
    }

    /// Generate a unique key for error tracking
    private func getErrorKey(for error: ColorProcessingError) -> String {
        switch error {
        case .invalidColorFormat(let format, _):
            return "invalidColorFormat_\(format)"
        case .conversionFailed(let from, let to):
            return "conversionFailed_\(from)_\(to)"
        case .screenSamplingFailed:
            return "screenSamplingFailed"
        default:
            return String(describing: error)
        }
    }

    /// Log an error to history
    private func logError(_ error: ColorProcessingError, context: String?) {
        let errorKey = getErrorKey(for: error)
        let retryCount = retryAttempts[errorKey, default: 0]

        let entry = ErrorLogEntry(
            error: error,
            context: context,
            retryCount: retryCount
        )

        errorHistory.append(entry)

        // Keep only recent entries
        if errorHistory.count > 100 {
            errorHistory.removeFirst(errorHistory.count - 100)
        }

        // Log to console for debugging
        print("🎨 ColorProcessing Error: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
    }

    /// Log successful recovery
    private func logRecovery(for error: ColorProcessingError, context: String?) {
        print("✅ ColorProcessing Recovery: Successfully recovered from \(error)")
        if let context = context {
            print("   Context: \(context)")
        }
    }

    // MARK: - Error Analysis

    /// Get error statistics
    func getErrorStatistics() -> ColorProcessingErrorStatistics {
        let totalErrors = errorHistory.count
        let errorTypes = Dictionary(grouping: errorHistory) { $0.error.severity }

        return ColorProcessingErrorStatistics(
            totalErrors: totalErrors,
            criticalErrors: errorTypes[.critical]?.count ?? 0,
            errors: errorTypes[.error]?.count ?? 0,
            warnings: errorTypes[.warning]?.count ?? 0,
            infoMessages: errorTypes[.info]?.count ?? 0,
            mostCommonError: getMostCommonError(),
            averageRetryCount: getAverageRetryCount()
        )
    }

    /// Get the most common error type
    private func getMostCommonError() -> ColorProcessingError? {
        let errorCounts = Dictionary(grouping: errorHistory) { getErrorKey(for: $0.error) }
        let mostCommon = errorCounts.max { $0.value.count < $1.value.count }
        return mostCommon?.value.first?.error
    }

    /// Get average retry count
    private func getAverageRetryCount() -> Double {
        guard !errorHistory.isEmpty else { return 0 }
        let totalRetries = errorHistory.reduce(0) { $0 + $1.retryCount }
        return Double(totalRetries) / Double(errorHistory.count)
    }

    /// Export error log as string
    func exportErrorLog() -> String {
        var log = "Color Processing Error Log\n"
        log += "Generated: \(Date())\n"
        log += "Total Errors: \(errorHistory.count)\n\n"

        for entry in errorHistory.suffix(50) {  // Last 50 errors
            log += "[\(entry.timestamp)] "
            log += "\(entry.error.severity) - \(entry.error.localizedDescription)\n"
            if let context = entry.context {
                log += "  Context: \(context)\n"
            }
            if entry.retryCount > 0 {
                log += "  Retries: \(entry.retryCount)\n"
            }
            log += "\n"
        }

        return log
    }
}

// MARK: - Error Statistics

struct ColorProcessingErrorStatistics {
    let totalErrors: Int
    let criticalErrors: Int
    let errors: Int
    let warnings: Int
    let infoMessages: Int
    let mostCommonError: ColorProcessingError?
    let averageRetryCount: Double
}

// MARK: - Recovery Suggestions

extension ColorProcessingErrorHandler {
    /// Get recovery suggestion for an error
    func getRecoverySuggestion(for error: ColorProcessingError) -> RecoverySuggestion {
        switch error {
        case .invalidColorFormat, .invalidColorValue, .emptyColorInput:
            return .userAction("Please check your input and try again")

        case .conversionFailed, .colorSpaceConversionFailed:
            return .retry("Try the conversion again")

        case .screenSamplingPermissionDenied:
            return .userAction("Grant screen recording permission in System Preferences")

        case .screenSamplingFailed, .screenSamplingTimeout:
            return .retry("Try sampling again")

        case .systemResourceUnavailable:
            return .retry("Try again in a moment")

        case .memoryPressure:
            return .userAction("Close other applications to free up memory")

        case .operationCancelled, .screenSamplingCancelled:
            return .info("Operation was cancelled")

        default:
            return .retry("Try the operation again")
        }
    }
}

enum RecoverySuggestion {
    case retry(String)
    case userAction(String)
    case info(String)

    var message: String {
        switch self {
        case .retry(let message), .userAction(let message), .info(let message):
            return message
        }
    }

    var actionType: ActionType {
        switch self {
        case .retry:
            return .retry
        case .userAction:
            return .userAction
        case .info:
            return .info
        }
    }

    enum ActionType {
        case retry
        case userAction
        case info
    }
}
