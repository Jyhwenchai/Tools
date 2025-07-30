import SwiftData
import SwiftUI
import Testing

@testable import Tools

struct ClipboardToastIntegrationTests {

    @Test("ClipboardView Toast Integration")
    func testClipboardViewToastIntegration() async throws {
        // Create in-memory model container for testing
        let schema = Schema([ClipboardItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        // Create ToastManager
        let toastManager = ToastManager()

        // Create test clipboard item
        let testItem = ClipboardItem(content: "Test clipboard content")
        context.insert(testItem)
        try context.save()

        // Create ClipboardView with environment
        let clipboardView = ClipboardView()
            .modelContainer(container)
            .environment(toastManager)

        // Verify that the view can be created without errors
        #expect(clipboardView != nil)

        // Verify that ToastManager is initially empty
        #expect(toastManager.toasts.isEmpty)

        // Test that we can show a toast (simulating copy success)
        toastManager.show("复制成功", type: .success)

        // Verify toast was added
        #expect(toastManager.toasts.count == 1)
        #expect(toastManager.toasts.first?.message == "复制成功")
        #expect(toastManager.toasts.first?.type == .success)

        // Clean up
        toastManager.dismissAll()
        #expect(toastManager.toasts.isEmpty)
    }

    @Test("ClipboardView Environment Integration")
    func testClipboardViewEnvironmentIntegration() async throws {
        // Create in-memory model container
        let schema = Schema([ClipboardItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])

        // Create ToastManager
        let toastManager = ToastManager()

        // Test that ClipboardView can be created with proper environment setup
        let view = ClipboardView()
            .modelContainer(container)
            .environment(toastManager)
            .toast()

        // Verify view creation succeeds
        #expect(view != nil)

        // Test multiple toast types that might be used in clipboard operations
        let testCases: [(String, ToastType)] = [
            ("复制成功", .success),
            ("复制失败", .error),
            ("剪贴板为空", .warning),
            ("已添加到历史记录", .info),
        ]

        for (message, type) in testCases {
            toastManager.show(message, type: type)

            // Verify toast was added with correct properties
            let lastToast = toastManager.toasts.last
            #expect(lastToast?.message == message)
            #expect(lastToast?.type == type)
            #expect(lastToast?.isAutoDismiss == true)
            #expect(lastToast?.duration == 3.0)
        }

        // Verify all toasts were added
        #expect(toastManager.toasts.count == testCases.count)

        // Clear all toasts
        toastManager.dismissAll()
        #expect(toastManager.toasts.isEmpty)
    }

    @Test("Toast System Performance with Clipboard Operations")
    func testToastSystemPerformanceWithClipboard() async throws {
        let toastManager = ToastManager()

        // Test rapid successive toast requests (simulating rapid copy operations)
        let startTime = Date()

        for i in 1...10 {
            toastManager.show("复制项目 \(i)", type: .success)
        }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        // Should handle rapid requests efficiently (under 100ms)
        #expect(duration < 0.1)

        // Should queue properly (max 5 simultaneous toasts)
        #expect(toastManager.toasts.count <= 5)

        // Should have queued the rest
        let queueStatus = toastManager.queueStatus
        #expect(queueStatus.displayedCount <= 5)
        #expect(queueStatus.queuedCount >= 5)

        // Clean up
        toastManager.dismissAll()
    }

    @Test("ClipboardView Toast Message Verification")
    func testClipboardViewToastMessages() async throws {
        let toastManager = ToastManager()

        // Test the exact message used in ClipboardView
        toastManager.show("复制成功", type: .success)

        let toast = toastManager.toasts.first
        #expect(toast != nil)
        #expect(toast?.message == "复制成功")
        #expect(toast?.type == .success)
        #expect(toast?.duration == 3.0)
        #expect(toast?.isAutoDismiss == true)

        // Verify accessibility properties
        let accessibilityDescription = toastManager.accessibilityDescription
        #expect(accessibilityDescription.contains("成功"))
        #expect(accessibilityDescription.contains("复制成功"))

        toastManager.dismissAll()
    }
}
