import SwiftUI

// MARK: - ToastView

struct ToastView: View {
    // MARK: - Properties

    let toast: ToastMessage
    let onDismiss: () -> Void

    @Environment(ToastManager.self) private var toastManager
    @State private var isHovered = false
    @State private var startTime = Date()
    @State private var pausedTime: Date?
    @State private var isVisible = false
    @State private var dragOffset: CGSize = .zero
    @State private var isExiting = false
    @AccessibilityFocusState private var isAccessibilityFocused: Bool

    // MARK: - Constants

    private let cornerRadius: CGFloat = 12
    private let shadowRadius: CGFloat = 8
    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 12
    private let iconSize: CGFloat = 20
    private let spacing: CGFloat = 12
    private let maxWidth: CGFloat = 400
    private let minHeight: CGFloat = 48

    // Animation constants
    private let entranceOffset: CGFloat = -30
    private let hoverScaleEffect: CGFloat = 1.03
    private let exitScaleEffect: CGFloat = 0.85

    // MARK: - Body

    var body: some View {
        styledToast
            .onAppear {
                startTime = Date()
                announceToast()

                // Entrance animation with slight delay for natural feel
                withAnimation(entranceAnimation.delay(0.05)) {
                    isVisible = true
                }
            }
    }

    private var styledToast: some View {
        animatedToast
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
                handleHoverStateChange(hovering)
            }
            .onTapGesture {
                dismissWithAnimation()
            }
            .onKeyPress { keyPress in
                switch keyPress.key {
                case .escape:
                    dismissWithAnimation()
                    announceAccessibilityAction("通知已通过 Escape 键关闭")
                    return .handled
                case .space, .return:
                    dismissWithAnimation()
                    announceAccessibilityAction("通知已关闭")
                    return .handled
                case .tab:
                    // Allow tab navigation to pass through
                    return .ignored
                case .upArrow, .downArrow:
                    // Allow arrow key navigation between toasts
                    return .ignored
                default:
                    return .ignored
                }
            }
            .focusable(true)
            .accessibilityFocused($isAccessibilityFocused)
            .gesture(dragGesture)
    }

    private var animatedToast: some View {
        baseToast
            .animation(entranceAnimation, value: isVisible)
            .animation(exitAnimation, value: isExiting)
            .animation(hoverAnimation, value: isHovered)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
    }

    private var baseToast: some View {
        accessibleToast
            .scaleEffect(toastScale)
            .opacity(toastOpacity)
            .offset(y: toastYOffset)
            .offset(dragOffset)
    }

    private var accessibleToast: some View {
        visualToast
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityValue(accessibilityValue ?? "")
            .accessibilityAddTraits(accessibilityTraits)
            .accessibilityAction(named: "关闭通知") {
                dismissWithAnimation()
                announceAccessibilityAction("通知已关闭")
            }
            .accessibilityAction(named: "暂停自动关闭") {
                if toast.isAutoDismiss && !toastManager.isTimerPaused(for: toast) {
                    toastManager.pauseAutoDismiss(for: toast)
                    announceAccessibilityAction("已暂停自动关闭")
                }
            }
            .accessibilityAction(named: "恢复自动关闭") {
                if toast.isAutoDismiss && toastManager.isTimerPaused(for: toast) {
                    toastManager.resumeAutoDismiss(for: toast)
                    announceAccessibilityAction("已恢复自动关闭")
                }
            }
            .accessibilityAction(named: "重复消息") {
                announceAccessibilityAction(accessibilityLabel)
            }
            .accessibilityRespondsToUserInteraction()
            .accessibilityInputLabels([
                "关闭", "关闭通知", "取消", "dismiss", "close",
                "暂停", "pause", "停止", "stop",
                "恢复", "resume", "继续", "continue",
            ])
    }

    private var visualToast: some View {
        toastContent
            .background(toastBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: adaptiveShadowColor,
                radius: isHovered ? shadowRadius + 2 : shadowRadius,
                x: 0,
                y: isHovered ? 6 : 4
            )
    }

    // MARK: - Content Views

    @ViewBuilder
    private var toastContent: some View {
        HStack(spacing: spacing) {
            // Toast icon
            Image(systemName: toast.type.icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(toast.type.color)
                .accessibilityHidden(true)

            // Toast message
            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(adaptiveTextColor)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 0)

            // Close button (visible on hover)
            if isHovered {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(adaptiveSecondaryTextColor)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Dismiss notification")
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: maxWidth, minHeight: minHeight)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Allow slight vertical drag for dismissal
                if abs(value.translation.height) > abs(value.translation.width) {
                    dragOffset = CGSize(width: 0, height: value.translation.height * 0.3)
                }
            }
            .onEnded { value in
                if value.translation.height < -50 {
                    // Swipe up to dismiss
                    dismissWithAnimation()
                } else {
                    // Reset position with spring animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Animation Properties

    private var toastScale: CGFloat {
        if isExiting {
            return exitScaleEffect
        } else if isHovered {
            return hoverScaleEffect
        } else if isVisible {
            return 1.0
        } else {
            return 0.9
        }
    }

    private var toastOpacity: Double {
        if isExiting {
            return 0.0
        } else if isVisible {
            return 1.0
        } else {
            return 0.0
        }
    }

    private var toastYOffset: CGFloat {
        if isExiting {
            return entranceOffset * 0.5  // Slight upward movement on exit
        } else if isVisible {
            return 0
        } else {
            return entranceOffset  // Start from above
        }
    }

    // MARK: - Animation Definitions

    private var entranceAnimation: Animation {
        .spring(
            response: 0.7,
            dampingFraction: 0.75,
            blendDuration: 0.1
        )
    }

    private var exitAnimation: Animation {
        .easeInOut(duration: 0.4)
    }

    private var hoverAnimation: Animation {
        .easeInOut(duration: 0.25)
    }

    // MARK: - Background View

    @ViewBuilder
    private var toastBackground: some View {
        if #available(macOS 12.0, *) {
            // Use modern blur effect with vibrancy for macOS 12+
            ZStack {
                // Base background with adaptive tint
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(toast.type.backgroundTintColor)

                // Adaptive blur effect based on appearance
                VisualEffectView(
                    material: adaptiveBlurMaterial,
                    blendingMode: .behindWindow
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

                // Subtle border for better definition
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(toast.type.borderColor, lineWidth: 0.5)
            }
        } else {
            // Fallback for older macOS versions with adaptive colors
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(adaptiveFallbackBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(toast.type.borderColor, lineWidth: 1)
                )
        }
    }

    /// Adaptive blur material that works well in both light and dark modes
    @available(macOS 12.0, *)
    private var adaptiveBlurMaterial: NSVisualEffectView.Material {
        // Use different materials based on system appearance for optimal contrast
        return .hudWindow
    }

    /// Adaptive fallback background for older macOS versions
    private var adaptiveFallbackBackground: Color {
        // Use semantic colors that adapt to appearance mode
        return Color(NSColor.controlBackgroundColor)
            .opacity(0.95)
    }

    /// Adaptive text color that ensures proper contrast in both modes
    private var adaptiveTextColor: Color {
        return Color(NSColor.labelColor)
    }

    /// Adaptive secondary text color for close button
    private var adaptiveSecondaryTextColor: Color {
        return Color(NSColor.secondaryLabelColor)
    }

    /// Adaptive shadow color that works in both light and dark modes
    private var adaptiveShadowColor: Color {
        // In dark mode, use lighter shadows; in light mode, use darker shadows
        return Color(NSColor.shadowColor).opacity(isHovered ? 0.25 : 0.15)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let typeDescription: String
        switch toast.type {
        case .success:
            typeDescription = "成功"
        case .error:
            typeDescription = "错误"
        case .warning:
            typeDescription = "警告"
        case .info:
            typeDescription = "信息"
        }
        return "\(typeDescription): \(toast.message)"
    }

    private var accessibilityHint: String {
        if toast.isAutoDismiss {
            return "轻点可关闭通知，将在 \(Int(toast.duration)) 秒后自动消失"
        } else {
            return "轻点可关闭通知"
        }
    }

    private var accessibilityValue: String? {
        if toast.isAutoDismiss {
            if toastManager.isTimerPaused(for: toast) {
                return "已暂停自动关闭"
            } else if let remainingTime = toastManager.getRemainingTime(for: toast) {
                return "剩余 \(Int(remainingTime)) 秒自动关闭"
            }
        }
        return nil
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]

        switch toast.type {
        case .error:
            _ = traits.insert(.causesPageTurn)
            _ = traits.insert(.playsSound)
        case .success:
            _ = traits.insert(.updatesFrequently)
        case .warning:
            _ = traits.insert(.causesPageTurn)
            _ = traits.insert(.playsSound)
        case .info:
            _ = traits.insert(.isStaticText)
            _ = traits.insert(.updatesFrequently)
        }

        // Add focus trait if this toast is currently focused
        if isAccessibilityFocused {
            _ = traits.insert(.allowsDirectInteraction)
        }

        return traits
    }

    // MARK: - Helper Methods

    private func dismissWithAnimation() {
        withAnimation(exitAnimation) {
            isExiting = true
        }

        // Call onDismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }

    private func handleHoverStateChange(_ isHovering: Bool) {
        guard toast.isAutoDismiss else { return }

        if isHovering {
            // Pause auto-dismiss when hovering
            pausedTime = Date()
            toastManager.pauseAutoDismiss(for: toast)
        } else {
            // Resume auto-dismiss when hover ends
            toastManager.resumeAutoDismiss(for: toast)
            pausedTime = nil
        }
    }

    private func announceToast() {
        // Announce toast to VoiceOver users with appropriate priority and sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let priority: NSAccessibilityPriorityLevel
            let shouldPlaySound: Bool

            switch toast.type {
            case .error:
                priority = .high
                shouldPlaySound = true
            case .warning:
                priority = .medium
                shouldPlaySound = true
            case .success:
                priority = .medium
                shouldPlaySound = false
            case .info:
                priority = .low
                shouldPlaySound = false
            }

            let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
                .announcement: accessibilityLabel,
                .priority: priority.rawValue,
            ]

            // Add sound cue for important notifications
            if shouldPlaySound {
                // Use system sound for important notifications
                NSSound.beep()
            }

            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: userInfo
            )

            // Also post a layout changed notification for screen readers
            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .layoutChanged
            )

            // Set accessibility focus to the toast for keyboard navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAccessibilityFocused = true
            }
        }
    }

    /// Announce accessibility actions to VoiceOver users
    /// - Parameter message: The message to announce
    private func announceAccessibilityAction(_ message: String) {
        DispatchQueue.main.async {
            let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.medium.rawValue,
            ]

            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: userInfo
            )
        }
    }
}

// MARK: - Visual Effect View

@available(macOS 12.0, *)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Preview

#if DEBUG
    struct ToastView_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 16) {
                ToastView(
                    toast: ToastMessage(
                        message: "Operation completed successfully!", type: .success),
                    onDismiss: {}
                )

                ToastView(
                    toast: ToastMessage(
                        message: "An error occurred while processing your request", type: .error),
                    onDismiss: {}
                )

                ToastView(
                    toast: ToastMessage(
                        message: "Please check your input before continuing", type: .warning),
                    onDismiss: {}
                )

                ToastView(
                    toast: ToastMessage(message: "This is an informational message", type: .info),
                    onDismiss: {}
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .previewLayout(.sizeThatFits)
        }
    }
#endif
