import XCTest

@testable import Tools

/// Integration tests for color processing toast notifications
@MainActor
final class ColorProcessingToastIntegrationTests: XCTestCase {

    // MARK: - Test Properties

    private var toastManager: ToastManager!
    private var errorHandler: ColorProcessingErrorHandler!
    private var toastService: ColorProcessingToastService!
    private var conversionService: ColorConversionService!
    private var samplingService: ColorSamplingService!
    private var paletteService: ColorPaletteService!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        toastManager = ToastManager()
        errorHandler = ColorProcessingErrorHandler()
        toastService = ColorProcessingToastService(
            toastManager: toastManager, errorHandler: errorHandler)

        conversionService = ColorConversionService()
        conversionService.setToastService(toastService)

        samplingService = ColorSamplingService()
        samplingService.setToastService(toastService)

        paletteService = ColorPaletteService()
        paletteService.setToastService(toastService)
    }

    override func tearDown() async throws {
        toastManager.dismissAll()
        toastManager = nil
        errorHandler = nil
        toastService = nil
        conversionService = nil
        samplingService = nil
        paletteService = nil

        try await super.tearDown()
    }

    // MARK: - Success Notification Tests

    func testColorCopiedToast() {
        // Given
        let format = ColorFormat.hex
        let value = "#FF0000"

        // When
        toastService.showColorCopied(format: format, value: value)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Copied Hex: #FF0000"))
        XCTAssertEqual(toast.duration, 2.0)
    }

    func testColorSavedToast() {
        // Given
        let colorName = "Red Color"

        // When
        toastService.showColorSaved(name: colorName)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Color 'Red Color' saved to palette"))
        XCTAssertEqual(toast.duration, 2.5)
    }

    func testColorSampledToast() {
        // Given
        let color = ColorRepresentation(
            rgb: RGBColor(red: 255, green: 0, blue: 0),
            hex: "#FF0000",
            hsl: HSLColor(hue: 0, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 0, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 0, magenta: 100, yellow: 100, key: 0),
            lab: LABColor(lightness: 53, a: 80, b: 67)
        )

        // When
        toastService.showColorSampled(color: color)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Color sampled: #FF0000"))
        XCTAssertEqual(toast.duration, 2.0)
    }

    func testColorConvertedToast() {
        // Given
        let fromFormat = ColorFormat.rgb
        let toFormat = ColorFormat.hex

        // When
        toastService.showColorConverted(from: fromFormat, to: toFormat)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Converted from RGB to Hex"))
        XCTAssertEqual(toast.duration, 1.5)
    }

    func testPaletteImportedToast() {
        // Given
        let count = 5

        // When
        toastService.showPaletteImported(count: count)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Imported 5 colors to palette"))
        XCTAssertEqual(toast.duration, 3.0)
    }

    func testPaletteExportedToast() {
        // Given
        let count = 10
        let format = "JSON"

        // When
        toastService.showPaletteExported(count: count, format: format)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Exported 10 colors to JSON"))
        XCTAssertEqual(toast.duration, 3.0)
    }

    // MARK: - Error Notification Tests

    func testErrorToastForInvalidColorFormat() {
        // Given
        let error = ColorProcessingError.invalidColorFormat(format: "RGB", input: "invalid")

        // When
        toastService.showError(error)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .error)
        XCTAssertTrue(toast.message.contains("Invalid RGB color format"))
        XCTAssertEqual(toast.duration, 3.0)  // Non-retryable error
    }

    func testErrorToastForRetryableError() {
        // Given
        let error = ColorProcessingError.screenSamplingFailed(reason: "Display not found")

        // When
        toastService.showError(error)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .error)
        XCTAssertTrue(toast.message.contains("Screen color sampling failed"))
        XCTAssertEqual(toast.duration, 4.0)  // Retryable error gets longer duration
    }

    func testWarningToast() {
        // Given
        let message = "Precision loss may occur"

        // When
        toastService.showWarning(message)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .warning)
        XCTAssertEqual(toast.message, message)
        XCTAssertEqual(toast.duration, 3.0)
    }

    func testPrecisionLossWarning() {
        // Given
        let fromFormat = ColorFormat.lab
        let toFormat = ColorFormat.rgb

        // When
        toastService.showPrecisionLossWarning(from: fromFormat, to: toFormat)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .warning)
        XCTAssertTrue(toast.message.contains("Precision loss may occur converting from LAB to RGB"))
        XCTAssertEqual(toast.duration, 3.5)
    }

    // MARK: - Progress Notification Tests

    func testProgressToastLifecycle() {
        // Given
        let initialMessage = "Starting operation..."
        let updateMessage = "Processing data..."
        let successMessage = "Operation completed successfully"

        // When - Start progress
        toastService.startProgressToast(message: initialMessage)

        // Then - Progress started
        XCTAssertTrue(toastService.isShowingProgressToast)
        XCTAssertEqual(toastService.progressMessage, initialMessage)
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .info)
        XCTAssertEqual(toastManager.toasts.first?.duration, 0)  // Manual dismiss

        // When - Update progress
        toastService.updateProgressToast(message: updateMessage)

        // Then - Progress updated
        XCTAssertTrue(toastService.isShowingProgressToast)
        XCTAssertEqual(toastService.progressMessage, updateMessage)

        // When - Complete progress
        toastService.completeProgressToast(successMessage: successMessage)

        // Then - Progress completed
        XCTAssertFalse(toastService.isShowingProgressToast)
        XCTAssertEqual(toastService.progressMessage, "")

        // Should have success toast
        let successToast = toastManager.toasts.first { $0.type == .success }
        XCTAssertNotNil(successToast)
        XCTAssertEqual(successToast?.message, successMessage)
    }

    func testProgressToastCancellation() {
        // Given
        let initialMessage = "Starting operation..."
        let error = ColorProcessingError.operationCancelled

        // When - Start and cancel progress
        toastService.startProgressToast(message: initialMessage)
        toastService.cancelProgressToast(error: error)

        // Then - Progress cancelled
        XCTAssertFalse(toastService.isShowingProgressToast)
        XCTAssertEqual(toastService.progressMessage, "")

        // Should have error toast
        let errorToast = toastManager.toasts.first { $0.type == .error }
        XCTAssertNotNil(errorToast)
        XCTAssertTrue(errorToast?.message.contains("Operation was cancelled") == true)
    }

    // MARK: - Service Integration Tests

    func testConversionServiceToastIntegration() {
        // Given
        let sourceFormat = ColorFormat.rgb
        let targetFormat = ColorFormat.hex
        let validInput = "rgb(255, 0, 0)"

        // When
        let result = conversionService.convertColorWithToast(
            from: sourceFormat,
            to: targetFormat,
            value: validInput
        )

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Converted from RGB to Hex"))
    }

    func testConversionServiceErrorToastIntegration() {
        // Given
        let sourceFormat = ColorFormat.rgb
        let targetFormat = ColorFormat.hex
        let invalidInput = "invalid color"

        // When
        let result = conversionService.convertColorWithToast(
            from: sourceFormat,
            to: targetFormat,
            value: invalidInput
        )

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .error)
        XCTAssertTrue(toast.message.contains("Invalid RGB color format"))
    }

    func testPaletteServiceToastIntegration() {
        // Given
        let color = ColorRepresentation(
            rgb: RGBColor(red: 255, green: 0, blue: 0),
            hex: "#FF0000",
            hsl: HSLColor(hue: 0, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 0, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 0, magenta: 100, yellow: 100, key: 0),
            lab: LABColor(lightness: 53, a: 80, b: 67)
        )
        let colorName = "Test Red"

        // When
        paletteService.addColorWithToast(color, name: colorName)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .success)
        XCTAssertTrue(toast.message.contains("Color 'Test Red' saved to palette"))
    }

    // MARK: - Smart Notification Tests

    func testSmartNotificationBySeverity() {
        // Test different severity levels
        let errors: [(ColorProcessingError, ToastType, TimeInterval)] = [
            (.operationCancelled, .info, 2.0),
            (.precisionLoss(from: .lab, to: .rgb), .warning, 3.0),
            (.conversionFailed(from: .rgb, to: .hex), .error, 4.0),
            (.paletteCorrupted, .error, 6.0),
        ]

        for (error, expectedType, expectedDuration) in errors {
            // Given
            toastManager.dismissAll()

            // When
            toastService.showSmartNotification(for: error)

            // Then
            XCTAssertEqual(toastManager.toasts.count, 1)
            let toast = toastManager.toasts.first!
            XCTAssertEqual(toast.type, expectedType)
            XCTAssertEqual(toast.duration, expectedDuration)
        }
    }

    func testRecoveryHintToast() {
        // Given
        let error = ColorProcessingError.screenSamplingPermissionDenied

        // When
        toastService.showRecoveryHint(for: error)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .info)
        XCTAssertTrue(toast.message.contains("💡"))
        XCTAssertTrue(toast.message.contains("Grant screen recording permission"))
        XCTAssertEqual(toast.duration, 4.0)
    }

    // MARK: - Batch Operation Tests

    func testBatchSuccessToasts() {
        // Given
        let messages = ["Color 1 saved", "Color 2 saved", "Color 3 saved"]

        // When
        toastService.showBatchSuccess(messages: messages)

        // Then
        // Should queue messages if exceeding max simultaneous toasts
        XCTAssertGreaterThanOrEqual(toastManager.toasts.count, 1)
        XCTAssertLessThanOrEqual(toastManager.toasts.count, 5)  // Max simultaneous

        // All toasts should be success type
        for toast in toastManager.toasts {
            XCTAssertEqual(toast.type, .success)
            XCTAssertEqual(toast.duration, 2.0)
        }
    }

    func testBatchErrorToasts() {
        // Given
        let errors = [
            ColorProcessingError.invalidColorFormat(format: "RGB", input: "invalid1"),
            ColorProcessingError.invalidColorFormat(format: "Hex", input: "invalid2"),
            ColorProcessingError.conversionFailed(from: .rgb, to: .hex),
        ]

        // When
        toastService.showBatchErrors(errors: errors)

        // Then
        XCTAssertGreaterThanOrEqual(toastManager.toasts.count, 1)
        XCTAssertLessThanOrEqual(toastManager.toasts.count, 5)

        // All toasts should be error type
        for toast in toastManager.toasts {
            XCTAssertEqual(toast.type, .error)
            XCTAssertEqual(toast.duration, 3.0)
        }
    }

    // MARK: - Cleanup Tests

    func testClearAllToasts() {
        // Given
        toastService.showColorSaved(name: "Test")
        toastService.showError(ColorProcessingError.operationCancelled)
        toastService.startProgressToast(message: "Processing...")

        // When
        toastService.clearAllToasts()

        // Then
        XCTAssertEqual(toastManager.toasts.count, 0)
        XCTAssertFalse(toastService.isShowingProgressToast)
    }

    func testClearErrorToasts() {
        // Given
        toastService.showColorSaved(name: "Test")  // Success toast
        toastService.showError(ColorProcessingError.operationCancelled)  // Error toast
        toastService.showWarning("Warning message")  // Warning toast

        // When
        toastService.clearErrorToasts()

        // Then
        let remainingToasts = toastManager.toasts
        XCTAssertEqual(remainingToasts.count, 2)  // Success and warning should remain
        XCTAssertFalse(remainingToasts.contains { $0.type == .error })
    }

    // MARK: - Accessibility Tests

    func testAccessibilityStatus() {
        // Given
        toastService.showColorSaved(name: "Test Color")

        // When
        let status = toastService.accessibilityStatus

        // Then
        XCTAssertFalse(status.isEmpty)
        XCTAssertTrue(status.contains("通知") || status.contains("notification"))
    }

    func testAccessibilityAnnouncement() {
        // Given
        let message = "Color sampling completed"

        // When
        toastService.announceForAccessibility(message, priority: .high)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.type, .error)  // High priority maps to error type
        XCTAssertEqual(toast.duration, 0.1)  // Very short duration for announcement
    }
}

// MARK: - Test Helpers

extension ColorProcessingToastIntegrationTests {

    /// Helper to wait for async toast operations
    private func waitForToastOperation() async {
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }

    /// Helper to create test color representation
    private func createTestColor() -> ColorRepresentation {
        return ColorRepresentation(
            rgb: RGBColor(red: 255, green: 0, blue: 0),
            hex: "#FF0000",
            hsl: HSLColor(hue: 0, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 0, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 0, magenta: 100, yellow: 100, key: 0),
            lab: LABColor(lightness: 53, a: 80, b: 67)
        )
    }
}

// MARK: - Result Extension for Testing

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    var isFailure: Bool {
        return !isSuccess
    }
}
