import SwiftUI

/// View for screen color sampling interface with controls and visual feedback
struct ScreenSamplerView: View {
    @ObservedObject var samplingService: ColorSamplingService
    let onColorSampled: (ColorRepresentation) -> Void

    @State private var showingPermissionAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var escKeyMonitor: Any?

    var body: some View {
        VStack(spacing: 16) {
            // Header section
            HStack {
                Image(systemName: "eyedropper")
                    .foregroundColor(.accentColor)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Screen Color Sampling")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Sample colors directly from your screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Sampling controls
            VStack(spacing: 12) {
                // Main sampling button
                ToolButton(
                    title: samplingService.isActive ? "Sampling Active..." : "Sample Screen Color",
                    action: handleSamplingButtonTap,
                    style: samplingService.isActive ? .secondary : .primary
                )
                .disabled(samplingService.isRequestingPermission)
                .accessibilityLabel(
                    samplingService.isActive ? "Stop screen sampling" : "Start screen sampling"
                )
                .accessibilityHint(
                    samplingService.isActive
                        ? "Tap to stop sampling colors from screen"
                        : "Tap to start sampling colors from screen"
                )
                .keyboardShortcut("s", modifiers: [.command])

                // Status and instructions
                if samplingService.isRequestingPermission {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Requesting screen recording permission...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if samplingService.isActive {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "hand.point.up.left")
                                .foregroundColor(.accentColor)
                            Text("Click anywhere on screen to sample color")
                                .font(.callout)
                                .foregroundColor(.primary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "Sampling active: Click anywhere on screen to sample color")

                        HStack {
                            Image(systemName: "escape")
                                .foregroundColor(.secondary)
                            Text("Press ESC to cancel sampling")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Press Escape key to cancel sampling")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                } else if !samplingService.hasPermission {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Screen recording permission required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Warning: Screen recording permission required for color sampling")
                }

                // Real-time color preview
                if let currentColor = samplingService.currentSampledColor {
                    ColorPreviewSection(color: currentColor)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
        )
        .onAppear {
            // Set up ESC key monitoring when view appears
            setupEscapeKeyMonitoring()
        }
        .onDisappear {
            // Clean up ESC key monitoring when view disappears
            cleanupEscapeKeyMonitoring()
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open System Preferences") {
                openSystemPreferences()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Screen recording permission is required for color sampling. Please grant permission in System Preferences > Privacy & Security > Screen Recording."
            )
        }
        .alert("Sampling Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: samplingService.lastError) { _, error in
            if let error = error {
                handleSamplingError(error)
            }
        }
        .onChange(of: samplingService.currentSampledColor) { _, color in
            if let color = color, samplingService.isActive {
                // Notify parent of sampled color
                onColorSampled(color)
                // Announce sampled color to VoiceOver
                announceSampledColor(color)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Screen color sampling controls")
        .accessibilityHint("Sample colors from anywhere on your screen")
    }

    // MARK: - Action Handlers

    private func handleSamplingButtonTap() {
        if samplingService.isActive {
            // Stop sampling
            samplingService.stopScreenSampling()
        } else {
            // Start sampling
            Task {
                let result = await samplingService.startScreenSampling()

                await MainActor.run {
                    switch result {
                    case .success:
                        // Sampling started successfully
                        break
                    case .failure(let error):
                        handleSamplingError(error)
                    }
                }
            }
        }
    }

    private func handleSamplingError(_ error: ColorProcessingError) {
        switch error {
        case .screenSamplingPermissionDenied:
            showingPermissionAlert = true
        case .screenSamplingFailed(let reason):
            errorMessage = "Sampling failed: \(reason)"
            showingErrorAlert = true
        default:
            errorMessage = error.localizedDescription
            showingErrorAlert = true
        }
    }

    // MARK: - ESC Key Monitoring

    private func setupEscapeKeyMonitoring() {
        // Set up global key monitoring for ESC key
        escKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 && samplingService.isActive {  // ESC key
                samplingService.stopScreenSampling()
            }
        }
    }

    private func cleanupEscapeKeyMonitoring() {
        if let monitor = escKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escKeyMonitor = nil
        }
    }

    private func openSystemPreferences() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        {
            NSWorkspace.shared.open(url)
        }
    }

    /// Announce sampled color to VoiceOver users
    private func announceSampledColor(_ color: ColorRepresentation) {
        let announcement =
            "Color sampled: \(color.hexString), RGB \(Int(color.rgb.red)), \(Int(color.rgb.green)), \(Int(color.rgb.blue))"
        NSAccessibility.post(
            element: NSApp, notification: .announcementRequested,
            userInfo: [
                .announcement: announcement
            ])
    }
}

// MARK: - Color Preview Section

private struct ColorPreviewSection: View {
    let color: ColorRepresentation

    var body: some View {
        VStack(spacing: 8) {
            Text("Live Preview")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Color swatch
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        Color(
                            red: color.rgb.red / 255.0,
                            green: color.rgb.green / 255.0,
                            blue: color.rgb.blue / 255.0,
                            opacity: color.rgb.alpha
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )

                // Color values
                VStack(alignment: .leading, spacing: 2) {
                    Text("RGB: \(color.rgbString)")
                        .font(.caption)
                        .foregroundColor(.primary)

                    Text("Hex: \(color.hexString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.quaternarySystemFill))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Color preview: \(color.rgbString)")
    }
}

// MARK: - Preview

#Preview {
    ScreenSamplerView(
        samplingService: ColorSamplingService(),
        onColorSampled: { color in
            print("Sampled color: \(color.rgbString)")
        }
    )
    .padding()
    .frame(width: 400)
}
