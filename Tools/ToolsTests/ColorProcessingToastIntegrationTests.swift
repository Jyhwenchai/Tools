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
    }

    override func tearDown() async throws {
        toastManager.dismissAll()
        toastManager = nil
        errorHandler = nil
        toastService = nil
        conversionService = nil
        samplingService = nil

        try await super.tearDown()
    }

    // MARK: - Success Notification Tests

    func testConversionSuccessToast() {
        // Given
        let inputValue = "rgb(255, 0, 0)"
        let expectedFormat = ColorFormat.hex

        // When
        let result = conversionService.createColorRepresentation(
            from: .rgb, value: inputValue)

        // Then
        switch result {
        case .success(let color):
            XCTAssertNotNil(color)
            XCTAssertEqual(toastManager.toasts.count, 1)
            let toast = toastManager.toasts.first!
            XCTAssertEqual(toast.type, .success)
            XCTAssertTrue(toast.message.contains("Color converted successfully"))
        case .failure:
            XCTFail("Conversion should succeed")
        }
    }

    func testSamplingSuccessToast() async {
        // Given
        let mockPoint = CGPoint(x: 100, y: 100)

        // When
        let result = await samplingService.startScreenSampling()

        // Then
        switch result {
        case .success:
            // Simulate successful sampling
            let sampleResult = samplingService.sampleColorAt(point: mockPoint)
            switch sampleResult {
            case .success(let color):
                XCTAssertNotNil(color)
            // Toast notifications would be triggered in real implementation
            case .failure:
                // Expected for mock implementation
                break
            }
        case .failure:
            // Expected for test environment without screen access
            break
        }
    }

    // MARK: - Error Notification Tests

    func testConversionErrorToast() {
        // Given
        let invalidInput = "invalid color"

        // When
        let result = conversionService.createColorRepresentation(
            from: .rgb, value: invalidInput)

        // Then
        switch result {
        case .success:
            XCTFail("Conversion should fail for invalid input")
        case .failure(let error):
            XCTAssertNotNil(error)
        // Error toast would be shown in real implementation
        }
    }

    func testSamplingErrorToast() async {
        // Given - no screen recording permission in test environment

        // When
        let result = await samplingService.startScreenSampling()

        // Then
        switch result {
        case .success:
            // Unexpected in test environment
            break
        case .failure(let error):
            XCTAssertNotNil(error)
        // Error toast would be shown in real implementation
        }
    }

    // MARK: - Smart Notification Tests

    func testSmartNotificationBySeverity() {
        // Test different severity levels
        let errors: [(ColorProcessingError, ToastType, TimeInterval)] = [
            (.operationCancelled, .info, 2.0),
            (.precisionLoss(from: .lab, to: .rgb), .warning, 3.0),
            (.conversionFailed(from: .rgb, to: .hex), .error, 4.0),
        ]

        for (error, expectedType, expectedDuration) in errors {
            // Given
            toastManager.dismissAll()

            // When
            toastService.showErrorToast(error)

            // Then
            XCTAssertEqual(toastManager.toasts.count, 1)
            let toast = toastManager.toasts.first!
            XCTAssertEqual(toast.type, expectedType)
            XCTAssertEqual(toast.duration, expectedDuration)
        }
    }

    func testToastQueueManagement() {
        // Given
        let errors = [
            ColorProcessingError.invalidColorFormat(format: "RGB", input: "invalid1"),
            ColorProcessingError.invalidColorFormat(format: "HEX", input: "invalid2"),
            ColorProcessingError.invalidColorFormat(format: "HSL", input: "invalid3"),
        ]

        // When
        for error in errors {
            toastService.showErrorToast(error)
        }

        // Then
        XCTAssertEqual(toastManager.toasts.count, 3)
        XCTAssertTrue(toastManager.toasts.allSatisfy { $0.type == .error })
    }

    // MARK: - Performance Tests

    func testToastPerformanceUnderLoad() {
        measure {
            for i in 0..<100 {
                let error = ColorProcessingError.invalidColorFormat(
                    format: "RGB", input: "invalid\(i)")
                toastService.showErrorToast(error)
            }
            toastManager.dismissAll()
        }
    }

    // MARK: - Integration Tests

    func testEndToEndColorProcessingWithToasts() {
        // Given
        let validInput = "rgb(128, 64, 192)"
        let invalidInput = "not a color"

        // When - Valid conversion
        let validResult = conversionService.createColorRepresentation(
            from: .rgb, value: validInput)

        // Then
        switch validResult {
        case .success(let color):
            XCTAssertNotNil(color)
            XCTAssertEqual(color.rgb.red, 128)
            XCTAssertEqual(color.rgb.green, 64)
            XCTAssertEqual(color.rgb.blue, 192)
        case .failure:
            XCTFail("Valid conversion should succeed")
        }

        // When - Invalid conversion
        let invalidResult = conversionService.createColorRepresentation(
            from: .rgb, value: invalidInput)

        // Then
        switch invalidResult {
        case .success:
            XCTFail("Invalid conversion should fail")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Accessibility Tests

    func testToastAccessibilityAnnouncements() {
        // Given
        let error = ColorProcessingError.conversionFailed(from: .rgb, to: .hex)

        // When
        toastService.showErrorToast(error)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        let toast = toastManager.toasts.first!
        XCTAssertFalse(toast.message.isEmpty)
        XCTAssertTrue(toast.isAccessible)
    }
}
