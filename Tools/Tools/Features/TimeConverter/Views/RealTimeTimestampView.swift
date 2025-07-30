import SwiftUI

// MARK: - Real-Time Timestamp View

struct RealTimeTimestampView: View {
    // MARK: - Properties

    @State private var service: RealTimeTimestampService
    @Environment(\.toastManager) private var toastManager

    // MARK: - Initialization

    init(configuration: RealTimeTimestampConfiguration = .default) {
        self._service = State(initialValue: RealTimeTimestampService(configuration: configuration))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Header with enhanced styling
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16, weight: .medium))
                        .symbolEffect(.pulse, options: .repeating, value: service.isRunning)

                    Text("当前时间戳")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Status indicator
                Circle()
                    .fill(service.isRunning ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(service.isRunning ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.3), value: service.isRunning)
                    .accessibilityLabel(service.isRunning ? "运行中" : "已暂停")
            }

            // Timestamp Display with enhanced animations
            timestampDisplaySection

            // Controls with improved layout
            controlButtonsSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
        )
        .onAppear {
            handleViewAppear()
        }
        .onDisappear {
            handleViewDisappear()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("实时时间戳显示")
        .accessibilityHint("显示当前Unix时间戳，可以切换单位和复制到剪贴板")
        .onReceive(NotificationCenter.default.publisher(for: .timeConverterTriggerCopy)) {
            notification in
            if let userInfo = notification.userInfo,
                let tab = userInfo["tab"] as? String,
                tab == "realtime" || tab == "single"
            {
                copyTimestamp()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeConverterRefreshAfterBackground))
        { _ in
            handleBackgroundRefresh()
        }
    }

    // MARK: - Timestamp Display Section

    private var timestampDisplaySection: some View {
        VStack(spacing: 8) {
            // Large timestamp display with enhanced styling
            Text(service.currentTimestamp)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .contentTransition(.numericText(countsDown: false))
                .animation(.easeInOut(duration: 0.2), value: service.currentTimestamp)
                .accessibilityLabel("当前时间戳")
                .accessibilityValue(service.currentTimestamp)
                .accessibilityHint("当前Unix时间戳值，会自动更新")
                .accessibilityAddTraits(.updatesFrequently)

            // Unit display with transition
            Text(service.currentUnit.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: service.currentUnit)
                .accessibilityLabel("时间戳单位")
                .accessibilityValue(service.currentUnit.displayName)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                )
        )
    }

    // MARK: - Control Buttons Section

    private var controlButtonsSection: some View {
        HStack(spacing: 12) {
            // Unit Toggle Button
            Button(action: {
                service.toggleUnit()
                announceUnitChange()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 14, weight: .medium))
                    Text("切换单位")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("切换时间戳单位")
            .accessibilityHint("在秒和毫秒之间切换显示单位")
            .accessibilityAddTraits(.isButton)
            .accessibilityValue("当前单位: \(service.currentUnit.displayName)")
            .focusable(true)

            // Copy Button
            Button(action: {
                copyTimestamp()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .medium))
                    Text("复制")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("复制时间戳")
            .accessibilityHint("将当前时间戳复制到剪贴板")
            .accessibilityAddTraits(.isButton)
            .focusable(true)
            .keyboardShortcut("c", modifiers: .command)

            // Timer Toggle Button
            Button(action: {
                service.toggleTimer()
                announceTimerStateChange()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: service.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text(service.isRunning ? "停止" : "开始")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(service.isRunning ? "停止时间戳更新" : "开始时间戳更新")
            .accessibilityHint(service.isRunning ? "暂停实时时间戳更新" : "开始实时时间戳更新")
            .accessibilityAddTraits(.isButton)
            .accessibilityValue(service.isRunning ? "运行中" : "已停止")
            .focusable(true)
        }
    }

    // MARK: - Actions

    private func copyTimestamp() {
        let success = service.copyToClipboard()

        if success {
            toastManager.show(
                "时间戳已复制到剪贴板",
                type: .success,
                duration: 2.0
            )

            // Accessibility announcement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSAccessibility.post(
                    element: NSApp.mainWindow as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        NSAccessibility.NotificationUserInfoKey.announcement:
                            "时间戳 \(service.currentTimestamp) 已复制到剪贴板",
                        NSAccessibility.NotificationUserInfoKey.priority:
                            NSAccessibilityPriorityLevel.medium.rawValue,
                    ]
                )
            }
        } else {
            toastManager.show(
                "复制失败，请重试",
                type: .error,
                duration: 3.0
            )
        }
    }

    private func announceUnitChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: [
                    NSAccessibility.NotificationUserInfoKey.announcement:
                        "时间戳单位已切换到\(service.currentUnit.displayName)",
                    NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel
                        .medium.rawValue,
                ]
            )
        }
    }

    private func announceTimerStateChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let message = service.isRunning ? "时间戳更新已开始" : "时间戳更新已停止"
            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: [
                    NSAccessibility.NotificationUserInfoKey.announcement: message,
                    NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel
                        .medium.rawValue,
                ]
            )
        }
    }

    // MARK: - Lifecycle Management

    private func handleViewAppear() {
        // Start timer with a slight delay to ensure smooth appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !service.isRunning {
                service.startTimer()
            }
        }
    }

    private func handleViewDisappear() {
        // Stop timer to conserve resources
        service.stopTimer()
    }

    private func handleBackgroundRefresh() {
        // Refresh timestamp when app returns from background
        if service.isRunning {
            service.stopTimer()
            service.startTimer()
        }

        toastManager.show(
            "时间戳已刷新",
            type: .info,
            duration: 1.5
        )
    }
}

// MARK: - Environment Key for Toast Manager

private struct ToastManagerKey: EnvironmentKey {
    static let defaultValue = ToastManager()
}

extension EnvironmentValues {
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

// MARK: - Preview

#Preview {
    RealTimeTimestampView()
        .frame(width: 400)
        .padding()
        .environment(\.toastManager, ToastManager())
}
