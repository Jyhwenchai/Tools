#!/usr/bin/env swift

import Foundation

// Simple test to verify ToastManager functionality
class SimpleToastManagerTest {
    func runTests() {
        print("Testing ToastManager basic functionality...")

        // Test 1: Basic initialization
        let toastManager = ToastManager()
        assert(toastManager.toasts.isEmpty, "Initial toasts array should be empty")
        print("✓ Test 1 passed: Initial state")

        // Test 2: Show toast
        toastManager.show("Test message", type: .success, duration: 1.0)
        assert(toastManager.toasts.count == 1, "Should have 1 toast after showing")
        assert(toastManager.toasts.first?.message == "Test message", "Message should match")
        assert(toastManager.toasts.first?.type == .success, "Type should match")
        print("✓ Test 2 passed: Show toast")

        // Test 3: Show multiple toasts
        toastManager.show("Second message", type: .error)
        toastManager.show("Third message", type: .warning)
        assert(toastManager.toasts.count == 3, "Should have 3 toasts")
        print("✓ Test 3 passed: Multiple toasts")

        // Test 4: Dismiss specific toast
        let toastToDismiss = toastManager.toasts[1]
        toastManager.dismiss(toastToDismiss)
        assert(toastManager.toasts.count == 2, "Should have 2 toasts after dismissing one")
        print("✓ Test 4 passed: Dismiss specific toast")

        // Test 5: Dismiss all toasts
        toastManager.dismissAll()
        assert(toastManager.toasts.isEmpty, "Should have no toasts after dismissing all")
        print("✓ Test 5 passed: Dismiss all toasts")

        print("All tests passed! ✅")
    }
}

// Note: This is a simplified test that doesn't test timer functionality
// since that requires a proper test environment with async support
let test = SimpleToastManagerTest()
test.runTests()
