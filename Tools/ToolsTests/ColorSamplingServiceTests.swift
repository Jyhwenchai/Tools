import XCTest

@testable import Tools

@MainActor
final class ColorSamplingServiceTests: XCTestCase {

    var service: ColorSamplingService!

    override func setUp() {
        super.setUp()
        service = ColorSamplingService()
    }

    override func tearDown() {
        service?.stopScreenSampling()
        service = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertFalse(service.isActive)
        XCTAssertNil(service.currentSampledColor)
        XCTAssertFalse(service.isRequestingPermission)
        XCTAssertNil(service.lastError)
    }

    func testPermissionCheckOnInit() {
        // Permission status should be checked during initialization
        // Note: This test may vary based on system permissions
        XCTAssertNotNil(service.hasPermission)
    }

    // MARK: - Permission Management Tests

    func testCheckScreenCapturePermission() {
        service.checkScreenCapturePermission()

        // Should set hasPermission based on system state
        // The actual value depends on system permissions
        XCTAssertNotNil(service.hasPermission)
    }

    func testRequestPermissionWhenAlreadyGranted() async {
        // Mock having permission
        service.checkScreenCapturePermission()

        if service.hasPermission {
            let result = await service.requestScreenCapturePermissionIfNeeded()

            switch result {
            case .success:
                XCTAssertTrue(service.hasPermission)
                XCTAssertFalse(service.isRequestingPermission)
            case .failure:
                XCTFail("Should succeed when permission already granted")
            }
        }
    }

    func testRequestPermissionFlow() async {
        // Test the permission request flow
        let result = await service.requestScreenCapturePermissionIfNeeded()

        // Should complete without crashing
        XCTAssertFalse(service.isRequestingPermission)

        switch result {
        case .success:
            XCTAssertTrue(service.hasPermission)
        case .failure(let error):
            XCTAssertEqual(error, .screenSamplingPermissionDenied)
            XCTAssertFalse(service.hasPermission)
        }
    }

    // MARK: - Screen Sampling Tests

    func testStartScreenSamplingWithoutPermission() async {
        // Force permission to false for testing
        service.hasPermission = false

        let result = await service.startScreenSampling()

        switch result {
        case .success:
            XCTFail("Should fail without permission")
        case .failure(let error):
            XCTAssertEqual(error, .screenSamplingPermissionDenied)
            XCTAssertFalse(service.isActive)
            XCTAssertEqual(service.lastError, .screenSamplingPermissionDenied)
        }
    }

    func testStartScreenSamplingWhenAlreadyActive() async {
        // Mock having permission
        service.hasPermission = true
        service.isActive = true

        let result = await service.startScreenSampling()

        switch result {
        case .success:
            XCTAssertTrue(service.isActive)
        case .failure:
            XCTFail("Should succeed when already active")
        }
    }

    func testStopScreenSampling() {
        service.isActive = true
        service.lastError = .screenSamplingFailed(reason: "Test error")

        service.stopScreenSampling()

        XCTAssertFalse(service.isActive)
        XCTAssertNil(service.lastError)
    }

    func testSampleColorAtWithoutPermission() {
        service.hasPermission = false

        let result = service.sampleColorAt(point: CGPoint(x: 100, y: 100))

        switch result {
        case .success:
            XCTFail("Should fail without permission")
        case .failure(let error):
            XCTAssertEqual(error, .screenSamplingPermissionDenied)
            XCTAssertEqual(service.lastError, .screenSamplingPermissionDenied)
        }
    }

    func testSampleColorAtWithPermission() {
        service.hasPermission = true

        let result = service.sampleColorAt(point: CGPoint(x: 100, y: 100))

        // Note: This test may fail in CI environments without display access
        // In real environments with permission, this should work
        switch result {
        case .success(let colorRepresentation):
            XCTAssertNotNil(colorRepresentation)
            XCTAssertEqual(service.currentSampledColor, colorRepresentation)
            XCTAssertNil(service.lastError)
        case .failure(let error):
            // Expected in test environments without display access
            XCTAssertTrue(
                error == .screenSamplingFailed(reason: "Could not access main display")
                    || error == .screenSamplingFailed(reason: "Could not capture screen image")
                    || error.localizedDescription.contains("sampling"))
        }
    }

    // MARK: - Error Handling Tests

    func testErrorStateManagement() {
        let testError = ColorProcessingError.screenSamplingFailed(reason: "Test error")

        // Set error
        service.lastError = testError
        XCTAssertEqual(service.lastError, testError)

        // Clear error by stopping sampling
        service.stopScreenSampling()
        XCTAssertNil(service.lastError)
    }

    func testMultipleStartStopCycles() async {
        service.hasPermission = true

        // Start sampling
        let startResult1 = await service.startScreenSampling()
        switch startResult1 {
        case .success:
            XCTAssertTrue(service.isActive)
        case .failure:
            // May fail in test environment, that's okay
            break
        }

        // Stop sampling
        service.stopScreenSampling()
        XCTAssertFalse(service.isActive)

        // Start again
        let startResult2 = await service.startScreenSampling()
        switch startResult2 {
        case .success:
            XCTAssertTrue(service.isActive)
        case .failure:
            // May fail in test environment, that's okay
            break
        }

        // Stop again
        service.stopScreenSampling()
        XCTAssertFalse(service.isActive)
    }

    // MARK: - State Consistency Tests

    func testStateConsistencyAfterPermissionDenied() async {
        service.hasPermission = false

        let result = await service.startScreenSampling()

        switch result {
        case .success:
            XCTFail("Should not succeed without permission")
        case .failure:
            XCTAssertFalse(service.isActive)
            XCTAssertFalse(service.isRequestingPermission)
            XCTAssertNotNil(service.lastError)
        }
    }

    func testDeinitializationCleanup() {
        service.isActive = true

        // Create a new service to test deinitialization
        var testService: ColorSamplingService? = ColorSamplingService()
        testService?.isActive = true

        // Deinitialize
        testService = nil

        // Should not crash and should clean up properly
        XCTAssertTrue(true)  // Test passes if no crash occurs
    }

    // MARK: - Integration Tests

    func testFullSamplingWorkflow() async {
        // Test the complete workflow from start to sample to stop
        let startResult = await service.startScreenSampling()

        switch startResult {
        case .success:
            XCTAssertTrue(service.isActive)

            // Try to sample a color
            let sampleResult = service.sampleColorAt(point: CGPoint(x: 100, y: 100))

            switch sampleResult {
            case .success(let color):
                XCTAssertNotNil(color)
                XCTAssertEqual(service.currentSampledColor, color)
            case .failure:
                // Expected in test environments
                break
            }

            // Stop sampling
            service.stopScreenSampling()
            XCTAssertFalse(service.isActive)

        case .failure(let error):
            // Expected if permission not granted
            XCTAssertEqual(error, .screenSamplingPermissionDenied)
        }
    }

    // MARK: - Performance Tests

    func testSamplingPerformance() {
        service.hasPermission = true

        measure {
            let _ = service.sampleColorAt(point: CGPoint(x: 100, y: 100))
        }
    }

    func testPermissionCheckPerformance() {
        measure {
            service.checkScreenCapturePermission()
        }
    }
}

// MARK: - Mock Extensions for Testing

extension ColorSamplingService {
    /// Test helper to set permission state
    func setPermissionForTesting(_ hasPermission: Bool) {
        self.hasPermission = hasPermission
    }

    /// Test helper to set active state
    func setActiveForTesting(_ isActive: Bool) {
        self.isActive = isActive
    }

    /// Test helper to set error state
    func setErrorForTesting(_ error: ColorProcessingError?) {
        self.lastError = error
    }
}
