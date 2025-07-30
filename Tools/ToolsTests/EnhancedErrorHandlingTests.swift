//
//  EnhancedErrorHandlingTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI
import XCTest

@testable import Tools

final class EnhancedErrorHandlingTests: XCTestCase {

    // MARK: - Validation Models Tests

    func testInputValidationStateCreation() {
        // Test valid state
        let validState = InputValidationState.valid
        XCTAssertTrue(validState.isValid)
        XCTAssertNil(validState.errorMessage)
        XCTAssertNil(validState.warningMessage)
        XCTAssertTrue(validState.suggestions.isEmpty)
        XCTAssertEqual(validState.validationLevel, .none)

        // Test invalid state
        let invalidState = InputValidationState.invalid(
            message: "Test error",
            suggestions: ["Suggestion 1", "Suggestion 2"],
            level: .error
        )
        XCTAssertFalse(invalidState.isValid)
        XCTAssertEqual(invalidState.errorMessage, "Test error")
        XCTAssertNil(invalidState.warningMessage)
        XCTAssertEqual(invalidState.suggestions.count, 2)
        XCTAssertEqual(invalidState.validationLevel, .error)

        // Test warning state
        let warningState = InputValidationState.warning(
            message: "Test warning",
            suggestions: ["Warning suggestion"]
        )
        XCTAssertTrue(warningState.isValid)
        XCTAssertNil(warningState.errorMessage)
        XCTAssertEqual(warningState.warningMessage, "Test warning")
        XCTAssertEqual(warningState.suggestions.count, 1)
        XCTAssertEqual(warningState.validationLevel, .warning)
    }

    func testValidationLevelProperties() {
        let levels: [ValidationLevel] = [.none, .info, .warning, .error, .critical]

        for level in levels {
            XCTAssertFalse(level.color.isEmpty, "Validation level should have color")
            XCTAssertFalse(level.systemImage.isEmpty, "Validation level should have system image")
        }

        // Test specific values
        XCTAssertEqual(ValidationLevel.error.color, "red")
        XCTAssertEqual(ValidationLevel.warning.color, "orange")
        XCTAssertEqual(ValidationLevel.error.systemImage, "xmark.circle.fill")
        XCTAssertEqual(ValidationLevel.warning.systemImage, "exclamationmark.triangle.fill")
    }

    func testFieldValidationResult() {
        let validationState = InputValidationState.invalid(message: "Test error")
        let fieldResult = FieldValidationResult(
            fieldName: "testField", validationState: validationState)

        XCTAssertEqual(fieldResult.fieldName, "testField")
        XCTAssertFalse(fieldResult.isValid)
        XCTAssertTrue(fieldResult.hasError)
        XCTAssertFalse(fieldResult.hasWarning)
        XCTAssertNotNil(fieldResult.timestamp)
    }

    func testRealTimeValidationConfig() {
        // Test default config
        let defaultConfig = RealTimeValidationConfig.default
        XCTAssertTrue(defaultConfig.enabled)
        XCTAssertEqual(defaultConfig.debounceInterval, 0.3)
        XCTAssertTrue(defaultConfig.showWarnings)
        XCTAssertTrue(defaultConfig.showSuggestions)
        XCTAssertTrue(defaultConfig.highlightErrors)

        // Test disabled config
        let disabledConfig = RealTimeValidationConfig.disabled
        XCTAssertFalse(disabledConfig.enabled)

        // Test custom config
        let customConfig = RealTimeValidationConfig(
            enabled: true,
            debounceInterval: 0.5,
            showWarnings: false,
            showSuggestions: false,
            highlightErrors: false
        )
        XCTAssertTrue(customConfig.enabled)
        XCTAssertEqual(customConfig.debounceInterval, 0.5)
        XCTAssertFalse(customConfig.showWarnings)
        XCTAssertFalse(customConfig.showSuggestions)
        XCTAssertFalse(customConfig.highlightErrors)
    }

    func testValidationContext() {
        let timeZone = TimeZone(identifier: "UTC")!
        let context = ValidationContext(
            format: .timestamp,
            customFormat: "yyyy-MM-dd",
            timeZone: timeZone,
            allowEmpty: true,
            strictMode: true
        )

        XCTAssertEqual(context.format, .timestamp)
        XCTAssertEqual(context.customFormat, "yyyy-MM-dd")
        XCTAssertEqual(context.timeZone.identifier, "UTC")
        XCTAssertTrue(context.allowEmpty)
        XCTAssertTrue(context.strictMode)
    }

    func testEnhancedErrorInfo() {
        let originalError = TimeConverterError.invalidTimestamp("abc")
        let context = ValidationContext(format: .timestamp)
        let suggestions = ["Use valid timestamp", "Try current timestamp"]
        let recoveryAction = RecoveryAction(
            title: "Reset",
            description: "Reset to default"
        ) {}

        let errorInfo = EnhancedErrorInfo(
            originalError: originalError,
            context: context,
            inputValue: "abc",
            suggestions: suggestions,
            recoveryActions: [recoveryAction],
            relatedErrors: []
        )

        XCTAssertEqual(errorInfo.originalError, originalError)
        XCTAssertNotNil(errorInfo.context)
        XCTAssertEqual(errorInfo.inputValue, "abc")
        XCTAssertEqual(errorInfo.suggestions.count, 2)
        XCTAssertEqual(errorInfo.recoveryActions.count, 1)
        XCTAssertTrue(errorInfo.relatedErrors.isEmpty)
    }

    func testRecoveryAction() {
        var actionExecuted = false
        let action = RecoveryAction(
            title: "Test Action",
            description: "Test Description",
            isDestructive: true
        ) {
            actionExecuted = true
        }

        XCTAssertEqual(action.title, "Test Action")
        XCTAssertEqual(action.description, "Test Description")
        XCTAssertTrue(action.isDestructive)
        XCTAssertFalse(actionExecuted)

        action.action()
        XCTAssertTrue(actionExecuted)
    }

    func testTimezoneValidationResult() {
        // Test valid result
        let validResult = TimezoneValidationResult.valid
        XCTAssertTrue(validResult.isValid)
        XCTAssertTrue(validResult.sourceTimezoneValid)
        XCTAssertTrue(validResult.targetTimezoneValid)
        XCTAssertTrue(validResult.compatibilityIssues.isEmpty)
        XCTAssertTrue(validResult.recommendations.isEmpty)
        XCTAssertFalse(validResult.hasIssues)
        XCTAssertFalse(validResult.hasRecommendations)

        // Test invalid result
        let invalidResult = TimezoneValidationResult(
            isValid: false,
            sourceTimezoneValid: false,
            targetTimezoneValid: true,
            compatibilityIssues: ["Source timezone invalid"],
            recommendations: ["Select valid timezone"]
        )
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertFalse(invalidResult.sourceTimezoneValid)
        XCTAssertTrue(invalidResult.targetTimezoneValid)
        XCTAssertTrue(invalidResult.hasIssues)
        XCTAssertTrue(invalidResult.hasRecommendations)
        XCTAssertEqual(invalidResult.compatibilityIssues.count, 1)
        XCTAssertEqual(invalidResult.recommendations.count, 1)
    }

    // MARK: - TimeConverter Error Enhancement Tests

    func testTimeConverterErrorDescriptions() {
        let errors: [TimeConverterError] = [
            .invalidTimestamp("abc"),
            .invalidDateFormat("invalid"),
            .timezoneConversionFailed,
            .customFormatInvalid("bad format"),
            .inputEmpty,
            .outputGenerationFailed,
            .batchProcessingFailed(["error1", "error2"]),
            .realTimeServiceUnavailable,
            .realTimeTimerFailed,
            .batchInputValidationFailed("validation error"),
            .batchItemProcessingFailed("item", "error"),
            .historyStorageFailed,
            .presetLoadingFailed,
            .presetSavingFailed("preset"),
            .timezoneDataUnavailable("UTC"),
            .formatDetectionFailed("input"),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description: \(error)")
            XCTAssertNotNil(
                error.recoverySuggestion, "Error should have recovery suggestion: \(error)")
            XCTAssertNotNil(error.failureReason, "Error should have failure reason: \(error)")
        }
    }

    func testTimeConverterErrorEquality() {
        // Test equal errors
        let error1 = TimeConverterError.invalidTimestamp("abc")
        let error2 = TimeConverterError.invalidTimestamp("abc")
        XCTAssertEqual(error1, error2)

        // Test different errors
        let error3 = TimeConverterError.invalidTimestamp("def")
        XCTAssertNotEqual(error1, error3)

        let error4 = TimeConverterError.inputEmpty
        XCTAssertNotEqual(error1, error4)
    }

    // MARK: - Integration Tests

    func testValidationServiceIntegration() {
        let validationService = ValidationService()
        let context = ValidationContext(format: .timestamp)

        // Test valid input
        let validResult = validationService.validateInput("1640995200", context: context)
        XCTAssertTrue(validResult.isValid)

        // Test invalid input
        let invalidResult = validationService.validateInput("abc", context: context)
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNotNil(invalidResult.errorMessage)
        XCTAssertFalse(invalidResult.suggestions.isEmpty)
    }

    func testEnhancedErrorGeneration() {
        let validationService = ValidationService()
        let error = TimeConverterError.invalidTimestamp("abc")
        let context = ValidationContext(format: .timestamp)

        let enhancedError = validationService.generateEnhancedError(
            from: error,
            context: context,
            inputValue: "abc"
        )

        XCTAssertEqual(enhancedError.originalError, error)
        XCTAssertEqual(enhancedError.inputValue, "abc")
        XCTAssertNotNil(enhancedError.context)
        XCTAssertFalse(enhancedError.suggestions.isEmpty)
    }

    // MARK: - Performance Tests

    func testValidationStateCreationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = InputValidationState.invalid(
                    message: "Error \(i)",
                    suggestions: ["Suggestion \(i)"],
                    level: .error
                )
            }
        }
    }

    func testEnhancedErrorCreationPerformance() {
        let validationService = ValidationService()
        let error = TimeConverterError.invalidTimestamp("abc")
        let context = ValidationContext(format: .timestamp)

        measure {
            for i in 0..<100 {
                _ = validationService.generateEnhancedError(
                    from: error,
                    context: context,
                    inputValue: "abc\(i)"
                )
            }
        }
    }

    // MARK: - Edge Cases

    func testEmptyStringsHandling() {
        let validationState = InputValidationState.invalid(
            message: "",
            suggestions: [],
            level: .error
        )

        XCTAssertFalse(validationState.isValid)
        XCTAssertEqual(validationState.errorMessage, "")
        XCTAssertTrue(validationState.suggestions.isEmpty)
    }

    func testNilCustomFormatHandling() {
        let context = ValidationContext(
            format: .custom,
            customFormat: nil,
            timeZone: .current
        )

        XCTAssertNil(context.customFormat)
        XCTAssertEqual(context.format, .custom)
    }

    func testLargeNumberOfSuggestions() {
        let suggestions = Array(0..<100).map { "Suggestion \($0)" }
        let validationState = InputValidationState.invalid(
            message: "Error",
            suggestions: suggestions,
            level: .error
        )

        XCTAssertEqual(validationState.suggestions.count, 100)
        XCTAssertFalse(validationState.isValid)
    }
}
