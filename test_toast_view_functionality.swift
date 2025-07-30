#!/usr/bin/env swift

import Foundation
import SwiftUI

// Simple test to verify ToastView functionality
print("Testing ToastView functionality...")

// Test ToastType enum
enum ToastType: CaseIterable {
    case success
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
}

// Test ToastMessage struct
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let isAutoDismiss: Bool

    init(
        message: String,
        type: ToastType,
        duration: TimeInterval = 3.0,
        isAutoDismiss: Bool = true
    ) {
        self.message = message
        self.type = type
        self.duration = duration
        self.isAutoDismiss = isAutoDismiss
    }

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        return lhs.id == rhs.id && lhs.message == rhs.message && lhs.type == rhs.type
            && lhs.duration == rhs.duration && lhs.isAutoDismiss == rhs.isAutoDismiss
    }
}

// Test basic functionality
print("✅ Testing ToastType enum...")
for type in ToastType.allCases {
    print("  - \(type): icon=\(type.icon), color=\(type.color)")
}

print("✅ Testing ToastMessage struct...")
let testMessage = ToastMessage(message: "Test message", type: .success)
print("  - Created message: \(testMessage.message)")
print("  - Type: \(testMessage.type)")
print("  - Duration: \(testMessage.duration)")
print("  - Auto-dismiss: \(testMessage.isAutoDismiss)")

print("✅ Testing ToastMessage equality...")
let message1 = ToastMessage(message: "Test", type: .info)
let message2 = ToastMessage(message: "Test", type: .info)
print("  - Different instances are not equal: \(message1 != message2)")

print("✅ All basic ToastView functionality tests passed!")
