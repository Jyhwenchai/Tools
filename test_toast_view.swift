#!/usr/bin/env swift

import Foundation
import SwiftUI

// Simple test to verify ToastView compiles and initializes correctly
struct TestToastView {
    static func runTests() {
        print("Testing ToastView implementation...")

        // Test 1: Basic initialization
        let successToast = ToastMessage(message: "Success!", type: .success)
        let errorToast = ToastMessage(message: "Error occurred", type: .error)
        let warningToast = ToastMessage(message: "Warning", type: .warning)
        let infoToast = ToastMessage(message: "Information", type: .info)

        print("✓ ToastMessage creation successful")

        // Test 2: ToastView initialization
        let successView = ToastView(toast: successToast) { print("Success dismissed") }
        let errorView = ToastView(toast: errorToast) { print("Error dismissed") }
        let warningView = ToastView(toast: warningToast) { print("Warning dismissed") }
        let infoView = ToastView(toast: infoToast) { print("Info dismissed") }

        print("✓ ToastView creation successful")

        // Test 3: Toast type properties
        assert(ToastType.success.icon == "checkmark.circle.fill")
        assert(ToastType.error.icon == "exclamationmark.circle.fill")
        assert(ToastType.warning.icon == "exclamationmark.triangle.fill")
        assert(ToastType.info.icon == "info.circle.fill")

        print("✓ ToastType icons correct")

        // Test 4: Toast message properties
        assert(successToast.type == .success)
        assert(successToast.message == "Success!")
        assert(successToast.isAutoDismiss == true)
        assert(successToast.duration == 3.0)

        print("✓ ToastMessage properties correct")

        // Test 5: Custom duration and auto-dismiss
        let customToast = ToastMessage(
            message: "Custom toast",
            type: .info,
            duration: 5.0,
            isAutoDismiss: false
        )

        assert(customToast.duration == 5.0)
        assert(customToast.isAutoDismiss == false)

        print("✓ Custom toast properties correct")

        print("All ToastView tests passed! ✅")
    }
}

// Run the tests
TestToastView.runTests()
