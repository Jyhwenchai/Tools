import Foundation
import SwiftUI

// MARK: - ToastType Enum

enum ToastType: CaseIterable {
    case success
    case error
    case warning
    case info

    /// SF Symbol icon name for each toast type
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

    /// Theme color for each toast type - adaptive for dark/light mode
    var color: Color {
        switch self {
        case .success:
            return Color(NSColor.systemGreen)
        case .error:
            return Color(NSColor.systemRed)
        case .warning:
            return Color(NSColor.systemOrange)
        case .info:
            return Color(NSColor.systemBlue)
        }
    }

    /// Background tint color for each toast type - subtle adaptive color
    var backgroundTintColor: Color {
        switch self {
        case .success:
            return Color(NSColor.systemGreen).opacity(0.1)
        case .error:
            return Color(NSColor.systemRed).opacity(0.1)
        case .warning:
            return Color(NSColor.systemOrange).opacity(0.1)
        case .info:
            return Color(NSColor.systemBlue).opacity(0.1)
        }
    }

    /// Border color for each toast type - adaptive with proper contrast
    var borderColor: Color {
        switch self {
        case .success:
            return Color(NSColor.systemGreen).opacity(0.3)
        case .error:
            return Color(NSColor.systemRed).opacity(0.3)
        case .warning:
            return Color(NSColor.systemOrange).opacity(0.3)
        case .info:
            return Color(NSColor.systemBlue).opacity(0.3)
        }
    }
}

// MARK: - ToastMessage Model

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

    // MARK: - Equatable Conformance

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        return lhs.id == rhs.id && lhs.message == rhs.message && lhs.type == rhs.type
            && lhs.duration == rhs.duration && lhs.isAutoDismiss == rhs.isAutoDismiss
    }
}
