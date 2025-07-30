import SwiftUI

// MARK: - Toast View Modifier

/// A comprehensive SwiftUI view modifier that adds toast notification support to any view
/// with proper environment integration, z-index layering, and overlay management
struct ToastModifier: ViewModifier {
    // MARK: - Properties

    @Environment(ToastManager.self) private var toastManager
    @State private var windowFrame: CGRect = .zero
    @State private var isWindowActive: Bool = true

    // MARK: - Layout Constants

    private let overlayZIndex: Double = 1000  // High z-index for proper layering
    private let containerZIndex: Double = 999

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(
                toastOverlay
                    .zIndex(overlayZIndex)
                    .allowsHitTesting(false)  // Allow touches to pass through to content
            )
            .onReceive(
                NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification)
            ) { _ in
                isWindowActive = true
            }
            .onReceive(
                NotificationCenter.default.publisher(for: NSWindow.didResignMainNotification)
            ) { _ in
                isWindowActive = false
            }
    }

    // MARK: - Toast Overlay

    @ViewBuilder
    private var toastOverlay: some View {
        if !toastManager.toasts.isEmpty && isWindowActive {
            GeometryReader { geometry in
                ToastContainer()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(containerZIndex)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("通知覆盖层")
                    .accessibilityHint("包含应用程序通知")
                    .onAppear {
                        windowFrame = geometry.frame(in: .global)
                        // Announce that toast overlay appeared
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            NSAccessibility.post(
                                element: NSApp.mainWindow as Any,
                                notification: .layoutChanged
                            )
                        }
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        windowFrame = newFrame
                    }
                    .onChange(of: toastManager.toasts.count) { oldCount, newCount in
                        // Announce when toast count changes
                        if newCount > oldCount {
                            // New toast added
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                NSAccessibility.post(
                                    element: NSApp.mainWindow as Any,
                                    notification: .layoutChanged
                                )
                            }
                        } else if newCount < oldCount {
                            // Toast removed
                            if newCount == 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NSAccessibility.post(
                                        element: NSApp.mainWindow as Any,
                                        notification: .layoutChanged
                                    )
                                }
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Enhanced Toast Environment Modifier

/// A more advanced modifier that provides full environment setup and management
struct ToastEnvironmentModifier: ViewModifier {
    // MARK: - Properties

    @State private var toastManager = ToastManager()

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .environment(toastManager)
            .modifier(ToastModifier())
    }
}

// MARK: - View Extensions

extension View {
    /// Adds toast notification support to any view with proper positioning and layout
    /// This modifier assumes ToastManager is already available in the environment
    func toast() -> some View {
        self.modifier(ToastModifier())
    }

    /// Adds toast notification support with full environment setup
    /// Use this modifier at the root level of your app or major view hierarchies
    func toastEnvironment() -> some View {
        self.modifier(ToastEnvironmentModifier())
    }

    /// Convenience method to add toast support with a custom ToastManager
    /// - Parameter manager: The ToastManager instance to use
    func toast(manager: ToastManager) -> some View {
        self
            .environment(manager)
            .modifier(ToastModifier())
    }
}

// MARK: - Toast Integration Helper

/// A helper view that can be used to integrate toast functionality into existing view hierarchies
/// without modifying the original views
struct ToastIntegrationWrapper<Content: View>: View {
    // MARK: - Properties

    let content: Content
    let toastManager: ToastManager

    // MARK: - Initializer

    init(toastManager: ToastManager = ToastManager(), @ViewBuilder content: () -> Content) {
        self.toastManager = toastManager
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .environment(toastManager)
            .modifier(ToastModifier())
    }
}

// MARK: - Window-Level Toast Support

/// Extension to support window-level toast management for complex applications
extension View {
    /// Adds toast support that works across multiple windows and view hierarchies
    /// This is useful for applications with complex navigation or multiple windows
    func globalToast() -> some View {
        self.modifier(GlobalToastModifier())
    }
}

/// A modifier that provides global toast support across window boundaries
struct GlobalToastModifier: ViewModifier {
    // MARK: - Properties

    @State private var toastManager = ToastManager()
    @State private var windowObserver: NSObjectProtocol?

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .environment(toastManager)
            .modifier(ToastModifier())
            .onAppear {
                setupWindowObserver()
            }
            .onDisappear {
                cleanupWindowObserver()
            }
    }

    // MARK: - Window Observer Management

    private func setupWindowObserver() {
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Dismiss all toasts when window closes
            toastManager.dismissAll()
        }
    }

    private func cleanupWindowObserver() {
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
            windowObserver = nil
        }
    }
}

// MARK: - Preview Support

#if DEBUG
    struct ToastModifier_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 20) {
                Text("Toast Modifier Integration Test")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 12) {
                    ToastTestButton(message: "Success toast!", type: .success)
                    ToastTestButton(message: "Error occurred", type: .error)
                    ToastTestButton(message: "Warning message", type: .warning)
                    ToastTestButton(message: "Info notification", type: .info)
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 400, minHeight: 300)
            .toastEnvironment()  // Using the environment modifier
        }
    }

    struct ToastTestButton: View {
        let message: String
        let type: ToastType

        @Environment(ToastManager.self) private var toastManager

        var body: some View {
            Button(message) {
                toastManager.show(message, type: type)
            }
            .buttonStyle(.borderedProminent)
        }
    }
#endif
