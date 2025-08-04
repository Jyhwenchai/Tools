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
        isRecovering = false
    }

    /// Manually retry an operation
    func retryOperation(
        with error: ColorProcessingError, operation: @escaping () async throws -> Void
    ) async {
        guard error.isRetryable else { return }

        isRecovering = true

        do {
            // Add delay before retry
            try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))

            // Attempt the operation
            try await operation()

            // Success - clear error and reset retry count
            clearError()
            resetRetryCount(for: error)

        } catch {
            // Handle retry failure
            if let colorError = error as? ColorProcessingError {
                incrementRetryCount(for: colorError)
            }

            if let colorError = error as? ColorProcessingError {
                handleError(colorError, context: "Retry attempt failed")
            } else {
                handleError(.unknown(error.localizedDescription), context: "Retry attempt failed")
            }
        }

        isRecovering = false
    }

    // MARK: - Private Recovery Methods

    private func shouldAttemptRecovery(for error: ColorProcessingError) -> Bool {
        let errorKey = errorKey(for: error)
        let attempts = retryAttempts[errorKey, default: 0]
        return attempts < maxRetryAttempts
    }

    private func attemptRecovery(for error: ColorProcessingError, context: String?) async {
        guard shouldAttemptRecovery(for: error) else { return }

        isRecovering = true
        incrementRetryCount(for: error)

        // Add delay before recovery attempt
        try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))

        let recovered = await performRecovery(for: error)

        if recovered {
            clearError()
            resetRetryCount(for: error)
        } else {
            // Recovery failed, log it
            logError(
                error, context: "Recovery attempt failed", retryCount: getRetryCount(for: error))
        }

        isRecovering = false
    }

    private func performRecovery(for error: ColorProcessingError) async -> Bool {
        switch error {
        case .systemResourceUnavailable:
            // Wait and check if resource becomes available
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            return true  // Assume resource might be available now

        case .operationTimeout:
            // For timeout errors, just return true to allow retry
            return true

        case .screenSamplingFailed:
            // For screen sampling failures, check permissions and try again
            return await recoverScreenSampling()

        case .paletteOperationFailed:
            // For palette operations, try to reinitialize
            return await recoverPaletteOperation()

        case .colorSpaceConversionFailed:
            // For color space conversion, try alternative approach
            return true  // Allow retry with potentially different approach

        default:
            return false  // No automatic recovery available
        }
    }

    private func recoverScreenSampling() async -> Bool {
        // Check if screen capture permission is available
        let hasPermission = CGPreflightScreenCaptureAccess()
        return hasPermission
    }

    private func recoverPaletteOperation() async -> Bool {
        // For palette operations, assume recovery is possible
        // In a real implementation, this might check database connectivity, etc.
        return true
    }

    // MARK: - Retry Count Management

    private func errorKey(for error: ColorProcessingError) -> String {
        // Create a unique key for each error type to track retry attempts
        switch error {
        case .invalidColorFormat(let format, _):
            return "invalidColorFormat_\(format)"
        case .conversionFailed(let from, let to):
            return "conversionFailed_\(from.rawValue)_\(to.rawValue)"
        case .screenSamplingFailed:
            return "screenSamplingFailed"
        case .paletteOperationFailed(let operation):
            return "paletteOperationFailed_\(operation)"
        default:
            return String(describing: error)
        }
    }

    private func incrementRetryCount(for error: ColorProcessingError) {
        let key = errorKey(for: error)
        retryAttempts[key, default: 0] += 1
    }

    private func getRetryCount(for error: ColorProcessingError) -> Int {
        let key = errorKey(for: error)
        return retryAttempts[key, default: 0]
    }

    private func resetRetryCount(for error: ColorProcessingError) {
        let key = errorKey(for: error)
        retryAttempts.removeValue(forKey: key)
    }

    // MARK: - Error Logging

    private func logError(_ error: ColorProcessingError, context: String?, retryCount: Int = 0) {
        let entry = ErrorLogEntry(error: error, context: context, retryCount: retryCount)
        errorHistory.append(entry)

        // Keep only last 50 error entries
        if errorHistory.count > 50 {
            errorHistory.removeFirst(errorHistory.count - 50)
        }

        // Print to console for debugging
        print("🎨 ColorProcessing Error: \(error.localizedDescription ?? "Unknown error")")
        if let context = context {
            print("   Context: \(context)")
        }
        print("   Timestamp: \(entry.timestamp)")
        print("   Retryable: \(error.isRetryable)")
        print("   Severity: \(error.severity)")
        if retryCount > 0 {
            print("   Retry Count: \(retryCount)")
        }
    }

    // MARK: - Error Statistics

    var errorStats: ErrorStatistics {
        let totalErrors = errorHistory.count
        let errorsByType = Dictionary(grouping: errorHistory, by: { $0.error })
        let errorsBySeverity = Dictionary(grouping: errorHistory, by: { $0.error.severity })

        return ErrorStatistics(
            totalErrors: totalErrors,
            errorsByType: errorsByType.mapValues { $0.count },
            errorsBySeverity: errorsBySeverity.mapValues { $0.count },
            recentErrors: Array(errorHistory.suffix(10))
        )
    }

    struct ErrorStatistics {
        let totalErrors: Int
        let errorsByType: [ColorProcessingError: Int]
        let errorsBySeverity: [ErrorSeverity: Int]
        let recentErrors: [ErrorLogEntry]
    }

    // MARK: - Error History Management

    func clearErrorHistory() {
        errorHistory.removeAll()
        retryAttempts.removeAll()
    }

    func exportErrorLog() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        var log = "Color Processing Error Log\n"
        log += "Generated: \(formatter.string(from: Date()))\n"
        log += "Total Errors: \(errorHistory.count)\n\n"

        for entry in errorHistory {
            log += "[\(formatter.string(from: entry.timestamp))] "
            log += "\(entry.error.severity) - \(entry.error.localizedDescription ?? "Unknown")\n"

            if let context = entry.context {
                log += "  Context: \(context)\n"
            }

            if entry.retryCount > 0 {
                log += "  Retry Count: \(entry.retryCount)\n"
            }

            if let suggestion = entry.error.recoverySuggestion {
                log += "  Suggestion: \(suggestion)\n"
            }

            log += "\n"
        }

        return log
    }
}

// MARK: - Error Recovery Strategies

extension ColorProcessingErrorHandler {

    /// Get specific recovery strategy for an error
    func getRecoveryStrategy(for error: ColorProcessingError) -> RecoveryStrategy {
        switch error {
        case .invalidColorFormat, .invalidColorValue, .emptyColorInput:
            return .userInput("Please correct the input and try again")

        case .screenSamplingPermissionDenied:
            return .systemSettings(
                "Open System Preferences > Privacy & Security > Screen Recording")

        case .conversionFailed, .colorSpaceConversionFailed:
            return .retry("Try the conversion again")

        case .screenSamplingFailed, .screenSamplingTimeout:
            return .retry("Try sampling again")

        case .paletteOperationFailed:
            return .retry("Try the palette operation again")

        case .paletteStorageFull:
            return .userAction("Delete some colors to make space")

        case .memoryPressure:
            return .systemAction("Close other applications to free memory")

        case .operationCancelled, .screenSamplingCancelled:
            return .none("Operation was cancelled by user")

        default:
            return .retry("Try the operation again")
        }
    }

    enum RecoveryStrategy {
        case none(String)
        case retry(String)
        case userInput(String)
        case userAction(String)
        case systemSettings(String)
        case systemAction(String)

        var description: String {
            switch self {
            case .none(let message), .retry(let message), .userInput(let message),
                .userAction(let message), .systemSettings(let message), .systemAction(let message):
                return message
            }
        }

        var actionType: String {
            switch self {
            case .none:
                return "No Action"
            case .retry:
                return "Retry"
            case .userInput:
                return "Fix Input"
            case .userAction:
                return "User Action"
            case .systemSettings:
                return "System Settings"
            case .systemAction:
                return "System Action"
            }
        }
    }
}
