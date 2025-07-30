import SwiftUI

// MARK: - ToastContainer

struct ToastContainer: View {
    // MARK: - Properties

    @Environment(ToastManager.self) private var toastManager
    @State private var windowSize: CGSize = .zero
    @State private var safeAreaInsets: EdgeInsets = EdgeInsets()

    // MARK: - Layout Constants

    private let maxToasts: Int = 5  // Maximum number of toasts to show
    private let toastSpacing: CGFloat = 12  // Space between stacked toasts
    private let horizontalMargin: CGFloat = 20  // Minimum margin from window edges
    private let minimumTopPadding: CGFloat = 20  // Minimum space from top
    private let toolbarHeight: CGFloat = 52  // Standard macOS toolbar height
    private let titleBarHeight: CGFloat = 28  // Standard macOS title bar height

    // MARK: - Computed Properties

    /// Calculate safe top padding that respects window chrome and safe areas
    private var safeTopPadding: CGFloat {
        let basePadding = safeAreaInsets.top + titleBarHeight + toolbarHeight + minimumTopPadding

        // Ensure minimum padding even if safe area is not detected
        return max(basePadding, 80)
    }

    /// Calculate maximum width for toasts based on window size
    private var maxToastWidth: CGFloat {
        let availableWidth = windowSize.width - (horizontalMargin * 2)
        return min(max(availableWidth, 300), 500)  // Between 300-500 points
    }

    /// Calculate container height to prevent toasts from going off-screen
    private var containerHeight: CGFloat {
        let bottomSafeArea = safeAreaInsets.bottom + 20  // Extra bottom margin
        return windowSize.height - safeTopPadding - bottomSafeArea
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Toast stack container
                LazyVStack(spacing: toastSpacing) {
                    ForEach(
                        Array(toastManager.toasts.prefix(maxToasts).enumerated()), id: \.element.id
                    ) { index, toast in
                        ToastView(toast: toast) {
                            toastManager.dismiss(toast)
                        }
                        .frame(maxWidth: maxToastWidth)
                        .transition(toastTransition(for: index))
                        .zIndex(Double(maxToasts - index))
                        .scaleEffect(stackingScale(for: index))
                        .offset(y: stackingOffset(for: index))
                        .opacity(stackingOpacity(for: index))
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("通知 \(index + 1) / \(toastManager.toasts.count)")
                        .accessibilityHint("在通知堆栈中的位置，使用 Tab 键导航到下一个通知")
                        .accessibilityAddTraits(index == 0 ? [.isSelected] : [])
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("通知区域")
                .accessibilityHint(toastManager.accessibilityDescription)
                .accessibilityAction(named: "关闭所有通知") {
                    toastManager.dismissAll()
                    announceContainerAction("所有通知已关闭")
                }
                .accessibilityAction(named: "暂停所有自动关闭") {
                    pauseAllAutoDismiss()
                    announceContainerAction("所有通知的自动关闭已暂停")
                }
                .accessibilityAction(named: "恢复所有自动关闭") {
                    resumeAllAutoDismiss()
                    announceContainerAction("所有通知的自动关闭已恢复")
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, horizontalMargin)

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: containerHeight,
                alignment: .top
            )
            .padding(.top, safeTopPadding)
            .clipped()  // Prevent toasts from appearing outside safe bounds
            .allowsHitTesting(true)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1),
                value: toastManager.toasts.map { $0.id }
            )
            .onAppear {
                updateLayoutMetrics(geometry)
            }
            .onChange(of: geometry.size) { _, newSize in
                updateLayoutMetrics(geometry)
            }
        }
    }

    // MARK: - Layout Helper Methods

    /// Update layout metrics when window size or geometry changes
    private func updateLayoutMetrics(_ geometry: GeometryProxy) {
        windowSize = geometry.size
        safeAreaInsets = geometry.safeAreaInsets
    }

    /// Create appropriate transition animation for toast at given index
    private func toastTransition(for index: Int) -> AnyTransition {
        let insertionTransition = AnyTransition.asymmetric(
            insertion: .move(edge: .top)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.85, anchor: .top)),
            removal: .opacity
                .combined(with: .scale(scale: 0.75, anchor: .top))
                .combined(with: .move(edge: .top))
        )

        return insertionTransition
    }

    // MARK: - Stacking Animation Helpers

    /// Calculate scale effect for stacked toasts to create depth perception
    private func stackingScale(for index: Int) -> CGFloat {
        guard index > 0 else { return 1.0 }

        let maxScale: CGFloat = 1.0
        let minScale: CGFloat = 0.94
        let scaleDecrement = (maxScale - minScale) / CGFloat(maxToasts - 1)
        let scale = max(minScale, maxScale - (CGFloat(index) * scaleDecrement))

        return scale
    }

    /// Calculate vertical offset for stacked toasts
    private func stackingOffset(for index: Int) -> CGFloat {
        guard index > 0 else { return 0 }

        // Create progressive stacking with diminishing returns
        let baseOffset: CGFloat = 4.0
        let progressiveMultiplier = 1.0 + (CGFloat(index) * 0.3)
        let offset = CGFloat(index) * baseOffset * progressiveMultiplier

        // Ensure stacking doesn't exceed container bounds
        let maxOffset = containerHeight * 0.1  // Max 10% of container height
        return min(offset, maxOffset)
    }

    /// Calculate opacity for stacked toasts to show hierarchy
    private func stackingOpacity(for index: Int) -> Double {
        guard index > 0 else { return 1.0 }

        let maxOpacity: Double = 1.0
        let minOpacity: Double = 0.7
        let opacityDecrement = (maxOpacity - minOpacity) / Double(maxToasts - 1)
        let opacity = max(minOpacity, maxOpacity - (Double(index) * opacityDecrement))

        return opacity
    }

    // MARK: - Accessibility Helper Methods

    /// Announce container-level accessibility actions
    /// - Parameter message: The message to announce
    private func announceContainerAction(_ message: String) {
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

    /// Pause auto-dismiss for all toasts
    private func pauseAllAutoDismiss() {
        for toast in toastManager.toasts
        where toast.isAutoDismiss && !toastManager.isTimerPaused(for: toast) {
            toastManager.pauseAutoDismiss(for: toast)
        }
    }

    /// Resume auto-dismiss for all toasts
    private func resumeAllAutoDismiss() {
        for toast in toastManager.toasts
        where toast.isAutoDismiss && toastManager.isTimerPaused(for: toast) {
            toastManager.resumeAutoDismiss(for: toast)
        }
    }
}

// MARK: - Toast Container Integration
// Note: The toast() view modifier is now provided by ToastModifier.swift
// This ensures proper environment integration and z-index layering

// MARK: - Preview

#if DEBUG
    struct ToastContainer_Previews: PreviewProvider {
        static var previews: some View {
            @State var toastManager = ToastManager()

            VStack(spacing: 20) {
                Text("Toast Positioning & Layout System")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    Button("Show Success Toast") {
                        toastManager.show("Operation completed successfully!", type: .success)
                    }

                    Button("Show Error Toast") {
                        toastManager.show("An error occurred while processing", type: .error)
                    }

                    Button("Show Warning Toast") {
                        toastManager.show(
                            "Please check your input before continuing", type: .warning)
                    }

                    Button("Show Info Toast") {
                        toastManager.show("This is an informational message", type: .info)
                    }

                    Button("Test Stacking (5 Toasts)") {
                        for i in 1...5 {
                            let delay = Double(i - 1) * 0.3
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                let types: [ToastType] = [
                                    .success, .error, .warning, .info, .success,
                                ]
                                toastManager.show(
                                    "Toast #\(i) - Testing stacking behavior", type: types[i - 1])
                            }
                        }
                    }

                    Button("Test Long Message") {
                        toastManager.show(
                            "This is a very long toast message that should wrap properly and demonstrate responsive behavior when the window is resized",
                            type: .info)
                    }

                    Button("Clear All Toasts") {
                        toastManager.dismissAll()
                    }
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Text("Resize window to test responsive behavior")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(minWidth: 400, minHeight: 300)
            .environment(toastManager)
            .toast()
        }
    }
#endif
