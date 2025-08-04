import SwiftUI

// MARK: - Error Display Components

/// Error alert modifier for color processing errors
struct ColorProcessingErrorAlert: ViewModifier {
    @Binding var error: ColorProcessingError?
    let onRetry: (() async -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                "Color Processing Error",
                isPresented: .constant(error != nil),
                presenting: error
            ) { colorError in
                // Primary dismiss button
                Button("OK") {
                    error = nil
                }

                // Retry button for retryable errors
                if colorError.isRetryable, let onRetry = onRetry {
                    Button("Retry") {
                        error = nil
                        Task {
                            await onRetry()
                        }
                    }
                }

                // System settings button for permission errors
                if case .screenSamplingPermissionDenied = colorError {
                    Button("Open Settings") {
                        error = nil
                        openSystemPreferences()
                    }
                }

            } message: { colorError in
                VStack(alignment: .leading, spacing: 8) {
                    Text(colorError.localizedDescription ?? "Unknown error occurred")

                    if let suggestion = colorError.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }

    private func openSystemPreferences() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}

/// Inline error display view for color processing
struct ColorProcessingErrorView: View {
    let error: ColorProcessingError
    let onRetry: (() async -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Error icon
            Image(systemName: error.severity.icon)
                .foregroundColor(error.severity.color)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                // Error message
                Text(error.localizedDescription ?? "Unknown error")
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Recovery suggestion
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                // Retry button for retryable errors
                if error.isRetryable, let onRetry = onRetry {
                    Button("Retry") {
                        Task {
                            await onRetry()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Dismiss button
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(error.severity.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(error.severity.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

/// Compact error badge for minimal error display
struct ColorProcessingErrorBadge: View {
    let error: ColorProcessingError
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: error.severity.icon)
                    .font(.caption)

                Text("Error")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(error.severity.color.opacity(0.2))
            )
            .foregroundColor(error.severity.color)
        }
        .buttonStyle(.plain)
    }
}

/// Error recovery view with detailed recovery options
struct ColorProcessingErrorRecoveryView: View {
    let error: ColorProcessingError
    let errorHandler: ColorProcessingErrorHandler
    let onRecovery: (() async -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Error header
            HStack {
                Image(systemName: error.severity.icon)
                    .foregroundColor(error.severity.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Error Occurred")
                        .font(.headline)

                    Text(error.localizedDescription ?? "Unknown error")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Recovery strategy
            let strategy = errorHandler.getRecoveryStrategy(for: error)

            VStack(alignment: .leading, spacing: 8) {
                Text("Recovery Options")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.orange)

                    Text(strategy.description)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            // Action buttons
            HStack(spacing: 12) {
                if error.isRetryable, let onRecovery = onRecovery {
                    Button("Try Again") {
                        Task {
                            await onRecovery()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if case .screenSamplingPermissionDenied = error {
                    Button("Open Settings") {
                        openSystemPreferences()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Dismiss") {
                    errorHandler.clearError()
                }
                .buttonStyle(.bordered)
            }

            // Error details (expandable)
            if errorHandler.errorHistory.count > 1 {
                DisclosureGroup("Error Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(errorHandler.errorHistory.suffix(3)) { entry in
                            HStack {
                                Image(systemName: entry.error.severity.icon)
                                    .foregroundColor(entry.error.severity.color)
                                    .font(.caption)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.error.localizedDescription ?? "Unknown")
                                        .font(.caption)

                                    Text(entry.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if entry.retryCount > 0 {
                                    Text("Retry \(entry.retryCount)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.secondary.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 2)
        )
    }

    private func openSystemPreferences() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply color processing error alert
    func colorProcessingErrorAlert(
        _ error: Binding<ColorProcessingError?>,
        onRetry: (() async -> Void)? = nil
    ) -> some View {
        modifier(ColorProcessingErrorAlert(error: error, onRetry: onRetry))
    }

    /// Apply color processing error overlay
    func colorProcessingErrorOverlay(
        error: ColorProcessingError?,
        onRetry: (() async -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .top) {
            if let error = error {
                ColorProcessingErrorView(
                    error: error,
                    onRetry: onRetry,
                    onDismiss: onDismiss
                )
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Error State Management View

/// Centralized error state management for color processing views
struct ColorProcessingErrorStateView<Content: View>: View {
    @StateObject private var errorHandler = ColorProcessingErrorHandler()
    let content: (ColorProcessingErrorHandler) -> Content

    var body: some View {
        content(errorHandler)
            .colorProcessingErrorOverlay(
                error: errorHandler.currentError,
                onRetry: {
                    if let error = errorHandler.currentError {
                        await errorHandler.retryOperation(with: error) {
                            // This would be implemented by the specific view
                            // that uses this error state management
                        }
                    }
                },
                onDismiss: {
                    errorHandler.clearError()
                }
            )
    }
}

// MARK: - Error Testing View (Debug Only)

#if DEBUG
    struct ColorProcessingErrorTestView: View {
        @StateObject private var errorHandler = ColorProcessingErrorHandler()
        @State private var selectedError: ColorProcessingError?

        private let testErrors: [ColorProcessingError] = [
            .invalidColorFormat(format: "RGB", input: "invalid"),
            .conversionFailed(from: .rgb, to: .hex),
            .screenSamplingPermissionDenied,
            .screenSamplingFailed(reason: "Display not found"),
            .paletteOperationFailed(operation: "save"),
            .memoryPressure,
            .operationTimeout,
        ]

        var body: some View {
            VStack(spacing: 20) {
                Text("Color Processing Error Testing")
                    .font(.title2)
                    .fontWeight(.bold)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12
                ) {
                    ForEach(testErrors, id: \.localizedDescription) { error in
                        Button(error.localizedDescription ?? "Unknown") {
                            errorHandler.handleError(error, context: "Test error")
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }

                if let error = errorHandler.currentError {
                    ColorProcessingErrorRecoveryView(
                        error: error,
                        errorHandler: errorHandler,
                        onRecovery: {
                            // Simulate recovery
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                    )
                }

                Spacer()
            }
            .padding()
        }
    }

    #Preview {
        ColorProcessingErrorTestView()
    }
#endif
