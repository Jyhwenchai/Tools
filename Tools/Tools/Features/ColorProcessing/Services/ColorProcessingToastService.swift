import Foundation
import SwiftUI

/// Service for managing toast notifications in color processing operations
@MainActor
class ColorProcessingToastService: ObservableObject {

    // MARK: - Dependencies

    private let toastManager: ToastManager
    private let errorHandler: ColorProcessingErrorHandler

    // MARK: - Published Properties

    @Published var isShowingProgressToast: Bool = false
    @Published var progressMessage: String = ""

    // MARK: - Private Properties

    private var progressToastId: UUID?
    private var operationStartTime: Date?

    // MARK: - Initialization

    init(toastManager: ToastManager, errorHandler: ColorProcessingErrorHandler) {
        self.toastManager = toastManager
        self.errorHandler = errorHandler
    }

    // MARK: - Success Notifications

    /// Show success toast for color copied to clipboard
    func showColorCopied(format: ColorFormat, value: String) {
        let message = "Copied \(format.rawValue): \(value)"
        toastManager.show(message, type: .success, duration: 2.0)
    }

    /// Show success toast for color saved to palette
    func showColorSaved(name: String) {
        let message = "Color '\(name)' saved to palette"
        toastManager.show(message, type: .success, duration: 2.5)
    }

    /// Show success toast for color sampled from screen
    func showColorSampled(color: ColorRepresentation) {
        let message = "Color sampled: \(color.hexString)"
        toastManager.show(message, type: .success, duration: 2.0)
    }

    /// Show success toast for color conversion
    func showColorConverted(from: ColorFormat, to: ColorFormat) {
        let message = "Converted from \(from.rawValue) to \(to.rawValue)"
        toastManager.show(message, type: .success, duration: 1.5)
    }

    /// Show success toast for palette operations
    func showPaletteOperationSuccess(_ operation: String, details: String? = nil) {
        var message = "Palette \(operation) successful"
        if let details = details {
            message += ": \(details)"
        }
        toastManager.show(message, type: .success, duration: 2.5)
    }

    /// Show success toast for palette import
    func showPaletteImported(count: Int) {
        let message = "Imported \(count) color\(count == 1 ? "" : "s") to palette"
        toastManager.show(message, type: .success, duration: 3.0)
    }

    /// Show success toast for palette export
    func showPaletteExported(count: Int, format: String) {
        let message = "Exported \(count) color\(count == 1 ? "" : "s") to \(format)"
        toastManager.show(message, type: .success, duration: 3.0)
    }

    // MARK: - Error Notifications

    /// Show error toast for color processing errors
    func showError(_ error: ColorProcessingError) {
        let message = error.localizedDescription ?? "Unknown error occurred"
        let duration: TimeInterval = error.isRetryable ? 4.0 : 3.0

        toastManager.show(message, type: .error, duration: duration)
    }

    /// Show error toast with custom message
    func showError(message: String, isRetryable: Bool = false) {
        let duration: TimeInterval = isRetryable ? 4.0 : 3.0
        toastManager.show(message, type: .error, duration: duration)
    }

    /// Show warning toast for non-critical issues
    func showWarning(_ message: String) {
        toastManager.show(message, type: .warning, duration: 3.0)
    }

    /// Show warning for precision loss in color conversion
    func showPrecisionLossWarning(from: ColorFormat, to: ColorFormat) {
        let message = "Precision loss may occur converting from \(from.rawValue) to \(to.rawValue)"
        toastManager.show(message, type: .warning, duration: 3.5)
    }

    /// Show warning for duplicate color in palette
    func showDuplicateColorWarning(name: String) {
        let message = "Color '\(name)' already exists in palette"
        toastManager.show(message, type: .warning, duration: 3.0)
    }

    // MARK: - Info Notifications

    /// Show info toast for general information
    func showInfo(_ message: String) {
        toastManager.show(message, type: .info, duration: 2.5)
    }

    /// Show info toast for screen sampling instructions
    func showScreenSamplingInstructions() {
        let message = "Click anywhere on screen to sample color. Press ESC to cancel."
        toastManager.show(message, type: .info, duration: 5.0)
    }

    /// Show info toast for permission requirements
    func showPermissionInfo() {
        let message = "Screen recording permission required for color sampling"
        toastManager.show(message, type: .info, duration: 4.0)
    }

    // MARK: - Progress Notifications

    /// Start showing progress toast for long-running operations
    func startProgressToast(message: String) {
        progressMessage = message
        isShowingProgressToast = true
        operationStartTime = Date()

        // Create a persistent toast for progress
        progressToastId = UUID()
        toastManager.show(message, type: .info, duration: 0)  // Duration 0 = manual dismiss
    }

    /// Update progress toast message
    func updateProgressToast(message: String) {
        guard isShowingProgressToast else { return }

        progressMessage = message

        // Dismiss current progress toast and show updated one
        if let progressId = progressToastId {
            // Find and dismiss the current progress toast
            if let currentToast = toastManager.toasts.first(where: { $0.id == progressId }) {
                toastManager.dismiss(currentToast)
            }
        }

        // Show updated progress toast
        progressToastId = UUID()
        toastManager.show(message, type: .info, duration: 0)
    }

    /// Complete progress toast with success
    func completeProgressToast(successMessage: String? = nil) {
        guard isShowingProgressToast else { return }

        // Dismiss progress toast
        dismissProgressToast()

        // Show success message if provided
        if let successMessage = successMessage {
            toastManager.show(successMessage, type: .success, duration: 2.0)
        }

        // Log operation duration
        if let startTime = operationStartTime {
            let duration = Date().timeIntervalSince(startTime)
            print("🎨 Color processing operation completed in \(String(format: "%.2f", duration))s")
        }
    }

    /// Cancel progress toast with optional error
    func cancelProgressToast(error: ColorProcessingError? = nil) {
        guard isShowingProgressToast else { return }

        // Dismiss progress toast
        dismissProgressToast()

        // Show error if provided
        if let error = error {
            showError(error)
        }
    }

    /// Dismiss progress toast
    private func dismissProgressToast() {
        isShowingProgressToast = false
        progressMessage = ""
        operationStartTime = nil

        if let progressId = progressToastId {
            // Find and dismiss the progress toast
            if let currentToast = toastManager.toasts.first(where: { $0.id == progressId }) {
                toastManager.dismiss(currentToast)
            }
            progressToastId = nil
        }
    }

    // MARK: - Batch Operations

    /// Show multiple success messages for batch operations
    func showBatchSuccess(messages: [String]) {
        toastManager.showBatch(messages, type: .success, duration: 2.0)
    }

    /// Show multiple error messages for batch operations
    func showBatchErrors(errors: [ColorProcessingError]) {
        let messages = errors.compactMap { $0.localizedDescription }
        toastManager.showBatch(messages, type: .error, duration: 3.0)
    }

    // MARK: - Context-Aware Notifications

    /// Show appropriate notification based on operation result
    func showOperationResult<T>(
        _ result: Result<T, ColorProcessingError>,
        successMessage: String,
        context: String? = nil
    ) {
        switch result {
        case .success:
            toastManager.show(successMessage, type: .success, duration: 2.0)
        case .failure(let error):
            showError(error)

            // Log error with context
            if let context = context {
                errorHandler.handleError(error, context: context)
            }
        }
    }

    /// Show notification for color validation result
    func showValidationResult(_ result: ValidationResult, format: ColorFormat) {
        switch result {
        case .valid:
            // Don't show success for validation - it's expected
            break
        case .invalid(let reason):
            let message = "Invalid \(format.rawValue) format: \(reason)"
            toastManager.show(message, type: .error, duration: 3.0)
        }
    }

    // MARK: - Smart Notifications

    /// Show smart notification that adapts based on error severity
    func showSmartNotification(for error: ColorProcessingError) {
        let message = error.localizedDescription ?? "Unknown error"

        switch error.severity {
        case .info:
            toastManager.show(message, type: .info, duration: 2.0)
        case .warning:
            toastManager.show(message, type: .warning, duration: 3.0)
        case .error:
            toastManager.show(message, type: .error, duration: 4.0)
        case .critical:
            toastManager.show(message, type: .error, duration: 6.0)
        }
    }

    /// Show recovery suggestion as info toast
    func showRecoveryHint(for error: ColorProcessingError) {
        guard let suggestion = error.recoverySuggestion else { return }

        let message = "💡 \(suggestion)"
        toastManager.show(message, type: .info, duration: 4.0)
    }

    // MARK: - Accessibility Support

    /// Get current toast status for accessibility
    var accessibilityStatus: String {
        return toastManager.accessibilityDescription
    }

    /// Announce important color processing events to accessibility services
    func announceForAccessibility(_ message: String, priority: AccessibilityPriority = .medium) {
        // This will be handled by the ToastManager's built-in accessibility support
        let toastType: ToastType
        switch priority {
        case .low:
            toastType = .info
        case .medium:
            toastType = .success
        case .high:
            toastType = .error
        }

        toastManager.show(message, type: toastType, duration: 0.1, announceImmediately: true)
    }

    enum AccessibilityPriority {
        case low, medium, high
    }

    // MARK: - Cleanup

    /// Clear all color processing related toasts
    func clearAllToasts() {
        dismissProgressToast()
        toastManager.dismissAll()
    }

    /// Clear only error toasts
    func clearErrorToasts() {
        let errorToasts = toastManager.toasts.filter { $0.type == .error }
        for toast in errorToasts {
            toastManager.dismiss(toast)
        }
    }
}

// MARK: - Convenience Extensions

extension ColorProcessingToastService {

    /// Show toast for clipboard operation result
    func showClipboardResult(_ result: Result<Void, Error>, format: ColorFormat, value: String) {
        switch result {
        case .success:
            showColorCopied(format: format, value: value)
        case .failure(let error):
            showError(message: "Failed to copy to clipboard: \(error.localizedDescription)")
        }
    }

    /// Show toast for file operation result
    func showFileOperationResult(_ result: Result<String, ColorProcessingError>, operation: String)
    {
        switch result {
        case .success(let details):
            showPaletteOperationSuccess(operation, details: details)
        case .failure(let error):
            showError(error)
        }
    }

    /// Show toast for sampling operation with timing
    func showSamplingResult(
        _ result: Result<ColorRepresentation, ColorProcessingError>,
        startTime: Date
    ) {
        let duration = Date().timeIntervalSince(startTime)

        switch result {
        case .success(let color):
            let message =
                "Color sampled in \(String(format: "%.1f", duration))s: \(color.hexString)"
            toastManager.show(message, type: .success, duration: 2.5)
        case .failure(let error):
            showError(error)
        }
    }
}

// MARK: - Toast Service Factory

extension ColorProcessingToastService {

    /// Create a toast service with shared dependencies
    static func create(with toastManager: ToastManager) -> ColorProcessingToastService {
        let errorHandler = ColorProcessingErrorHandler()
        return ColorProcessingToastService(toastManager: toastManager, errorHandler: errorHandler)
    }
}
