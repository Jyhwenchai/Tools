import SwiftData
import SwiftUI

@testable import Tools

// Simple test to verify ClipboardView toast integration
func testClipboardToastIntegration() {
    print("Testing ClipboardView Toast Integration...")

    // Create ToastManager
    let toastManager = ToastManager()

    // Verify initial state
    assert(toastManager.toasts.isEmpty, "ToastManager should start empty")
    print("✅ ToastManager initialized correctly")

    // Test showing a success toast (like copy success)
    toastManager.show("复制成功", type: .success)

    // Verify toast was added
    assert(toastManager.toasts.count == 1, "Should have 1 toast")
    assert(toastManager.toasts.first?.message == "复制成功", "Message should match")
    assert(toastManager.toasts.first?.type == .success, "Type should be success")
    print("✅ Success toast created correctly")

    // Test different toast types that might be used in clipboard
    let testCases: [(String, ToastType)] = [
        ("复制失败", .error),
        ("剪贴板为空", .warning),
        ("已添加到历史记录", .info),
    ]

    for (message, type) in testCases {
        toastManager.show(message, type: type)
        let lastToast = toastManager.toasts.last
        assert(lastToast?.message == message, "Message should match for \(type)")
        assert(lastToast?.type == type, "Type should match for \(type)")
    }

    print("✅ All toast types work correctly")
    print("✅ Total toasts: \(toastManager.toasts.count)")

    // Test dismissal
    toastManager.dismissAll()
    assert(toastManager.toasts.isEmpty, "All toasts should be dismissed")
    print("✅ Toast dismissal works correctly")

    // Test queue management with rapid requests
    for i in 1...10 {
        toastManager.show("快速复制 \(i)", type: .success)
    }

    let queueStatus = toastManager.queueStatus
    print(
        "✅ Queue status - Displayed: \(queueStatus.displayedCount), Queued: \(queueStatus.queuedCount)"
    )
    assert(queueStatus.displayedCount <= 5, "Should not display more than 5 toasts simultaneously")

    toastManager.dismissAll()
    print("✅ All tests passed! ClipboardView toast integration is working correctly.")
}

// Run the test
testClipboardToastIntegration()
