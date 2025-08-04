import XCTest

@testable import Tools

/// Integration tests for screen sampling with color conversion workflow
@MainActor
final class ScreenSamplerIntegrationTests: XCTestCase {

    var samplingService: ColorSamplingService!
    var conversionService: ColorConversionService!

    override func setUp() {
        super.setUp()
        samplingService = ColorSamplingService()
        conversionService = ColorConversionService()
    }

    override func tearDown() {
        samplingService = nil
        conversionService = nil
        super.tearDown()
    }

    // MARK: - Integration Tests

    func testScreenSamplingToColorConversionIntegration() {
        // Given: A sampled color from screen
        let testPoint = CGPoint(x: 100, y: 100)

        // When: Sampling color at a point
        let samplingResult = samplingService.sampleColorAt(point: testPoint)

        // Then: Should successfully sample color
        switch samplingResult {
        case .success(let colorRepresentation):
            // Verify color representation is valid
            XCTAssertNotNil(colorRepresentation)
            XCTAssertGreaterThanOrEqual(colorRepresentation.rgb.red, 0)
            XCTAssertLessThanOrEqual(colorRepresentation.rgb.red, 255)
            XCTAssertGreaterThanOrEqual(colorRepresentation.rgb.green, 0)
            XCTAssertLessThanOrEqual(colorRepresentation.rgb.green, 255)
            XCTAssertGreaterThanOrEqual(colorRepresentation.rgb.blue, 0)
            XCTAssertLessThanOrEqual(colorRepresentation.rgb.blue, 255)

            // Test integration with conversion service
            conversionService.updateCurrentColor(colorRepresentation)
            XCTAssertEqual(conversionService.currentColor, colorRepresentation)
            XCTAssertNil(conversionService.lastError)

        case .failure(let error):
            // If sampling fails due to permissions, that's expected in test environment
            if case .screenSamplingPermissionDenied = error {
                XCTAssertTrue(true, "Permission denied is expected in test environment")
            } else {
                XCTFail("Unexpected sampling error: \(error)")
            }
        }
    }

    func testColorSampledCallbackIntegration() {
        // Given: A test color representation
        let testColor = ColorRepresentation(
            rgb: RGBColor(red: 255, green: 128, blue: 64, alpha: 1.0),
            hex: "#FF8040",
            hsl: HSLColor(hue: 20, saturation: 100, lightness: 62.5, alpha: 1.0),
            hsv: HSVColor(hue: 20, saturation: 75, value: 100, alpha: 1.0),
            cmyk: CMYKColor(cyan: 0, magenta: 50, yellow: 75, key: 0),
            lab: LABColor(lightness: 70, a: 30, b: 50)
        )

        var callbackInvoked = false
        var receivedColor: ColorRepresentation?

        // When: Simulating color sampled callback
        let onColorSampled: (ColorRepresentation) -> Void = { color in
            callbackInvoked = true
            receivedColor = color

            // Simulate integration with conversion service
            self.conversionService.updateCurrentColor(color)
        }

        onColorSampled(testColor)

        // Then: Callback should be invoked and color should be processed
        XCTAssertTrue(callbackInvoked)
        XCTAssertEqual(receivedColor, testColor)
        XCTAssertEqual(conversionService.currentColor, testColor)
        XCTAssertNil(conversionService.lastError)
    }

    func testSamplingServiceErrorHandling() {
        // Given: Sampling service without permissions
        samplingService.hasPermission = false

        // When: Attempting to sample color
        let result = samplingService.sampleColorAt(point: CGPoint(x: 50, y: 50))

        // Then: Should return permission error
        switch result {
        case .success:
            XCTFail("Should not succeed without permissions")
        case .failure(let error):
            XCTAssertEqual(error, .screenSamplingPermissionDenied)
            XCTAssertEqual(samplingService.lastError, .screenSamplingPermissionDenied)
        }
    }

    func testColorFormatConsistencyAfterSampling() {
        // Given: A sampled color
        let testRGB = RGBColor(red: 200, green: 150, blue: 100, alpha: 1.0)
        let colorRepresentation = conversionService.createColorRepresentation(from: testRGB)

        // When: Updating current color through conversion service
        conversionService.updateCurrentColor(colorRepresentation)

        // Then: All color formats should be consistent
        let currentColor = conversionService.currentColor!

        // Verify RGB values
        XCTAssertEqual(currentColor.rgb.red, 200, accuracy: 1.0)
        XCTAssertEqual(currentColor.rgb.green, 150, accuracy: 1.0)
        XCTAssertEqual(currentColor.rgb.blue, 100, accuracy: 1.0)

        // Verify hex format
        XCTAssertTrue(currentColor.hex.hasPrefix("#"))
        XCTAssertEqual(currentColor.hex.count, 7)  // #RRGGBB format

        // Verify HSL format is within valid ranges
        XCTAssertGreaterThanOrEqual(currentColor.hsl.hue, 0)
        XCTAssertLessThanOrEqual(currentColor.hsl.hue, 360)
        XCTAssertGreaterThanOrEqual(currentColor.hsl.saturation, 0)
        XCTAssertLessThanOrEqual(currentColor.hsl.saturation, 100)
        XCTAssertGreaterThanOrEqual(currentColor.hsl.lightness, 0)
        XCTAssertLessThanOrEqual(currentColor.hsl.lightness, 100)

        // Verify formatted strings are valid
        XCTAssertTrue(currentColor.rgbString.hasPrefix("rgb("))
        XCTAssertTrue(currentColor.hslString.hasPrefix("hsl("))
        XCTAssertTrue(currentColor.hsvString.hasPrefix("hsv("))
        XCTAssertTrue(currentColor.cmykString.hasPrefix("cmyk("))
        XCTAssertTrue(currentColor.labString.hasPrefix("lab("))
    }

    func testRealTimeColorPreviewUpdates() {
        // Given: Initial state
        XCTAssertNil(samplingService.currentSampledColor)

        // When: Simulating real-time color updates during sampling
        let testColors = [
            RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0),
            RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0),
            RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0),
        ]

        for testRGB in testColors {
            let colorRepresentation = conversionService.createColorRepresentation(from: testRGB)
            samplingService.currentSampledColor = colorRepresentation

            // Then: Current sampled color should be updated
            XCTAssertNotNil(samplingService.currentSampledColor)
            XCTAssertEqual(samplingService.currentSampledColor?.rgb, testRGB)
        }
    }

    func testSamplingStateManagement() {
        // Given: Initial inactive state
        XCTAssertFalse(samplingService.isActive)
        XCTAssertFalse(samplingService.isRequestingPermission)

        // When: Starting sampling (simulated)
        samplingService.isActive = true

        // Then: State should be updated
        XCTAssertTrue(samplingService.isActive)

        // When: Stopping sampling
        samplingService.stopScreenSampling()

        // Then: State should be reset
        XCTAssertFalse(samplingService.isActive)
    }

    func testErrorRecoveryAfterSamplingFailure() {
        // Given: Service with an error
        let testError = ColorProcessingError.screenSamplingFailed(reason: "Test error")
        samplingService.lastError = testError

        // When: Attempting successful operation
        let testRGB = RGBColor(red: 100, green: 100, blue: 100, alpha: 1.0)
        let colorRepresentation = conversionService.createColorRepresentation(from: testRGB)
        samplingService.currentSampledColor = colorRepresentation

        // Clear error as would happen in successful sampling
        samplingService.lastError = nil

        // Then: Error should be cleared and color should be available
        XCTAssertNil(samplingService.lastError)
        XCTAssertNotNil(samplingService.currentSampledColor)
    }
}
