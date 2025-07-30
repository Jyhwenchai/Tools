//
//  ValidationModels.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import Foundation

// MARK: - Input Validation State

struct InputValidationState {
    let isValid: Bool
    let errorMessage: String?
    let warningMessage: String?
    let suggestions: [String]
    let validationLevel: ValidationLevel

    init(
        isValid: Bool = true,
        errorMessage: String? = nil,
        warningMessage: String? = nil,
        suggestions: [String] = [],
        validationLevel: ValidationLevel = .none
    ) {
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.warningMessage = warningMessage
        self.suggestions = suggestions
        self.validationLevel = validationLevel
    }

    static let valid = InputValidationState()

    static func invalid(
        message: String,
        suggestions: [String] = [],
        level: ValidationLevel = .error
    ) -> InputValidationState {
        InputValidationState(
            isValid: false,
            errorMessage: message,
            suggestions: suggestions,
            validationLevel: level
        )
    }

    static func warning(
        message: String,
        suggestions: [String] = []
    ) -> InputValidationState {
        InputValidationState(
            isValid: true,
            warningMessage: message,
            suggestions: suggestions,
            validationLevel: .warning
        )
    }
}

// MARK: - Validation Level

enum ValidationLevel {
    case none
    case info
    case warning
    case error
    case critical

    var color: String {
        switch self {
        case .none, .info:
            return "blue"
        case .warning:
            return "orange"
        case .error:
            return "red"
        case .critical:
            return "purple"
        }
    }

    var systemImage: String {
        switch self {
        case .none:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Field Validation Result

struct FieldValidationResult {
    let fieldName: String
    let validationState: InputValidationState
    let timestamp: Date

    init(fieldName: String, validationState: InputValidationState) {
        self.fieldName = fieldName
        self.validationState = validationState
        self.timestamp = Date()
    }

    var isValid: Bool {
        validationState.isValid
    }

    var hasWarning: Bool {
        validationState.warningMessage != nil
    }

    var hasError: Bool {
        validationState.errorMessage != nil
    }
}

// MARK: - Real-time Validation Configuration

struct RealTimeValidationConfig {
    let enabled: Bool
    let debounceInterval: TimeInterval
    let showWarnings: Bool
    let showSuggestions: Bool
    let highlightErrors: Bool

    init(
        enabled: Bool = true,
        debounceInterval: TimeInterval = 0.3,
        showWarnings: Bool = true,
        showSuggestions: Bool = true,
        highlightErrors: Bool = true
    ) {
        self.enabled = enabled
        self.debounceInterval = debounceInterval
        self.showWarnings = showWarnings
        self.showSuggestions = showSuggestions
        self.highlightErrors = highlightErrors
    }

    static let `default` = RealTimeValidationConfig()
    static let disabled = RealTimeValidationConfig(enabled: false)
}

// MARK: - Validation Context

struct ValidationContext {
    let format: TimeFormat
    let customFormat: String?
    let timeZone: TimeZone
    let allowEmpty: Bool
    let strictMode: Bool

    init(
        format: TimeFormat,
        customFormat: String? = nil,
        timeZone: TimeZone = .current,
        allowEmpty: Bool = false,
        strictMode: Bool = false
    ) {
        self.format = format
        self.customFormat = customFormat
        self.timeZone = timeZone
        self.allowEmpty = allowEmpty
        self.strictMode = strictMode
    }
}

// MARK: - Enhanced Error Information

struct EnhancedErrorInfo {
    let originalError: TimeConverterError
    let context: ValidationContext?
    let inputValue: String
    let suggestions: [String]
    let recoveryActions: [RecoveryAction]
    let relatedErrors: [TimeConverterError]

    init(
        originalError: TimeConverterError,
        context: ValidationContext? = nil,
        inputValue: String = "",
        suggestions: [String] = [],
        recoveryActions: [RecoveryAction] = [],
        relatedErrors: [TimeConverterError] = []
    ) {
        self.originalError = originalError
        self.context = context
        self.inputValue = inputValue
        self.suggestions = suggestions
        self.recoveryActions = recoveryActions
        self.relatedErrors = relatedErrors
    }
}

// MARK: - Recovery Action

struct RecoveryAction {
    let title: String
    let description: String
    let action: () -> Void
    let isDestructive: Bool

    init(
        title: String,
        description: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.isDestructive = isDestructive
        self.action = action
    }
}

// MARK: - Timezone Validation Result

struct TimezoneValidationResult {
    let isValid: Bool
    let sourceTimezoneValid: Bool
    let targetTimezoneValid: Bool
    let compatibilityIssues: [String]
    let recommendations: [String]

    init(
        isValid: Bool = true,
        sourceTimezoneValid: Bool = true,
        targetTimezoneValid: Bool = true,
        compatibilityIssues: [String] = [],
        recommendations: [String] = []
    ) {
        self.isValid = isValid
        self.sourceTimezoneValid = sourceTimezoneValid
        self.targetTimezoneValid = targetTimezoneValid
        self.compatibilityIssues = compatibilityIssues
        self.recommendations = recommendations
    }

    static let valid = TimezoneValidationResult()

    var hasIssues: Bool {
        !compatibilityIssues.isEmpty
    }

    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }
}
