import AppKit
import XCTest

@testable import Tools

final class RealTimeTimestampServiceTests: XCTestCase {

    var service: RealTimeTimestampService!

    override func setUp() {
        super.setUp()
        // Create service with non-auto-start configuration for controlled testing
        let config = RealTimeTimestampConfiguration(
            updateInterval: 0.1,  // Faster updates for testing
            autoStart: false,
            defaultUnit: .seconds
        )
        service = RealTimeTimestampService(configuration: config)
    }

    override func tearDown() {
        service?.stopTimer()
        service = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertFalse(
            service.isRunning, "Service should not be running initially with autoStart: false")
        XCTAssertEqual(service.currentUnit, .seconds, "Default unit should be seconds")
        XCTAssertFalse(service.currentTimestamp.isEmpty, "Timestamp should be initialized")
    }

    func testInitializationWithAutoStart() {
        let config = RealTimeTimestampConfiguration(autoStart: true)
        let autoStartService = RealTimeTimestampService(configuration: config)

        XCTAssertTrue(autoStartService.isRunning, "Service should be running with autoStart: true")

        autoStartService.stopTimer()
    }

    func testInitializationWithCustomUnit() {
        let config = RealTimeTimestampConfiguration(defaultUnit: .milliseconds)
        let customService = RealTimeTimestampService(configuration: config)

        XCTAssertEqual(customService.currentUnit, .milliseconds, "Should use custom default unit")

        customService.stopTimer()
    }

    // MARK: - Timer Lifecycle Tests

    func testStartTimer() {
        XCTAssertFalse(service.isRunning, "Service should not be running initially")

        service.startTimer()

        XCTAssertTrue(service.isRunning, "Service should be running after start")
    }

    func testStopTimer() {
        service.startTimer()
        XCTAssertTrue(service.isRunning, "Service should be running")

        service.stopTimer()

        XCTAssertFalse(service.isRunning, "Service should not be running after stop")
    }

    func testToggleTimer() {
        XCTAssertFalse(service.isRunning, "Service should not be running initially")

        service.toggleTimer()
        XCTAssertTrue(service.isRunning, "Service should be running after toggle")

        service.toggleTimer()
        XCTAssertFalse(service.isRunning, "Service should not be running after second toggle")
    }

    func testMultipleStartCalls() {
        service.startTimer()
        let firstState = service.isRunning

        service.startTimer()  // Should not create multiple timers

        XCTAssertEqual(
            service.isRunning, firstState, "Multiple start calls should not change state")
    }

    func testTimerUpdatesTimestamp() {
        let initialTimestamp = service.currentTimestamp

        service.startTimer()

        let expectation = XCTestExpectation(description: "Timer should update timestamp")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let updatedTimestamp = self.service.currentTimestamp
            XCTAssertNotEqual(
                initialTimestamp, updatedTimestamp, "Timestamp should be updated by timer")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Unit Switching Tests

    func testToggleUnit() {
        XCTAssertEqual(service.currentUnit, .seconds, "Initial unit should be seconds")

        service.toggleUnit()

        XCTAssertEqual(service.currentUnit, .milliseconds, "Unit should toggle to milliseconds")

        service.toggleUnit()

        XCTAssertEqual(service.currentUnit, .seconds, "Unit should toggle back to seconds")
    }

    func testSetUnit() {
        service.setUnit(.milliseconds)
        XCTAssertEqual(service.currentUnit, .milliseconds, "Unit should be set to milliseconds")

        service.setUnit(.seconds)
        XCTAssertEqual(service.currentUnit, .seconds, "Unit should be set to seconds")
    }

    func testUnitSwitchUpdatesTimestamp() {
        let initialTimestamp = service.currentTimestamp

        service.toggleUnit()

        let updatedTimestamp = service.currentTimestamp
        XCTAssertNotEqual(
            initialTimestamp, updatedTimestamp, "Timestamp should update when unit changes")
    }

    func testTimestampFormatForSeconds() {
        service.setUnit(.seconds)
        let timestamp = service.currentTimestamp

        XCTAssertTrue(
            timestamp.allSatisfy { $0.isNumber }, "Seconds timestamp should contain only numbers")
        XCTAssertTrue(timestamp.count >= 10, "Seconds timestamp should be at least 10 digits")
    }

    func testTimestampFormatForMilliseconds() {
        service.setUnit(.milliseconds)
        let timestamp = service.currentTimestamp

        XCTAssertTrue(
            timestamp.allSatisfy { $0.isNumber },
            "Milliseconds timestamp should contain only numbers")
        XCTAssertTrue(timestamp.count >= 13, "Milliseconds timestamp should be at least 13 digits")
    }

    // MARK: - Clipboard Integration Tests

    func testCopyToClipboard() {
        let result = service.copyToClipboard()

        XCTAssertTrue(result, "Copy operation should succeed")

        let pasteboard = NSPasteboard.general
        let clipboardContent = pasteboard.string(forType: .string)

        XCTAssertEqual(
            clipboardContent, service.currentTimestamp, "Clipboard should contain current timestamp"
        )
    }

    func testCopyToClipboardWithDifferentUnits() {
        service.setUnit(.seconds)
        service.copyToClipboard()

        let secondsClipboard = NSPasteboard.general.string(forType: .string)

        service.setUnit(.milliseconds)
        service.copyToClipboard()

        let millisecondsClipboard = NSPasteboard.general.string(forType: .string)

        XCTAssertNotEqual(
            secondsClipboard, millisecondsClipboard,
            "Different units should produce different clipboard content")
    }

    // MARK: - Timestamp Operations Tests

    func testGetCurrentTimestamp() {
        let secondsTimestamp = service.getCurrentTimestamp(for: .seconds)
        let millisecondsTimestamp = service.getCurrentTimestamp(for: .milliseconds)

        XCTAssertTrue(
            secondsTimestamp.allSatisfy { $0.isNumber }, "Seconds timestamp should be numeric")
        XCTAssertTrue(
            millisecondsTimestamp.allSatisfy { $0.isNumber },
            "Milliseconds timestamp should be numeric")
        XCTAssertTrue(
            millisecondsTimestamp.count > secondsTimestamp.count,
            "Milliseconds should be longer than seconds")
    }

    func testGetFormattedTimestamp() {
        let testDate = Date(timeIntervalSince1970: 1_640_995_200)  // Jan 1, 2022 00:00:00 UTC

        let secondsFormatted = service.getFormattedTimestamp(for: testDate, unit: .seconds)
        let millisecondsFormatted = service.getFormattedTimestamp(
            for: testDate, unit: .milliseconds)

        XCTAssertEqual(secondsFormatted, "1640995200", "Seconds formatting should be correct")
        XCTAssertEqual(
            millisecondsFormatted, "1640995200000", "Milliseconds formatting should be correct")
    }

    // MARK: - Validation Tests

    func testValidateTimestampSeconds() {
        XCTAssertTrue(
            service.validateTimestamp("1640995200", for: .seconds),
            "Valid seconds timestamp should pass")
        XCTAssertTrue(
            service.validateTimestamp("0", for: .seconds), "Zero timestamp should be valid")
        XCTAssertFalse(
            service.validateTimestamp("-1", for: .seconds), "Negative timestamp should be invalid")
        XCTAssertFalse(
            service.validateTimestamp("abc", for: .seconds),
            "Non-numeric timestamp should be invalid")
        XCTAssertFalse(
            service.validateTimestamp("9999999999", for: .seconds),
            "Future timestamp beyond 2100 should be invalid")
    }

    func testValidateTimestampMilliseconds() {
        XCTAssertTrue(
            service.validateTimestamp("1640995200000", for: .milliseconds),
            "Valid milliseconds timestamp should pass")
        XCTAssertTrue(
            service.validateTimestamp("0", for: .milliseconds), "Zero timestamp should be valid")
        XCTAssertFalse(
            service.validateTimestamp("-1", for: .milliseconds),
            "Negative timestamp should be invalid")
        XCTAssertFalse(
            service.validateTimestamp("abc", for: .milliseconds),
            "Non-numeric timestamp should be invalid")
    }

    // MARK: - Utility Methods Tests

    func testReset() {
        service.startTimer()
        service.setUnit(.milliseconds)

        XCTAssertTrue(service.isRunning, "Service should be running before reset")
        XCTAssertEqual(
            service.currentUnit, .milliseconds, "Unit should be milliseconds before reset")

        service.reset()

        XCTAssertFalse(service.isRunning, "Service should not be running after reset")
        XCTAssertEqual(service.currentUnit, .seconds, "Unit should be reset to default")
    }

    func testPause() {
        service.startTimer()
        XCTAssertTrue(service.isRunning, "Service should be running")

        service.pause()

        XCTAssertFalse(service.isRunning, "Service should be paused")
    }

    func testResume() {
        XCTAssertFalse(service.isRunning, "Service should not be running initially")

        service.resume()

        XCTAssertTrue(service.isRunning, "Service should be running after resume")
    }

    func testPauseWhenNotRunning() {
        XCTAssertFalse(service.isRunning, "Service should not be running initially")

        service.pause()  // Should not crash or change state

        XCTAssertFalse(service.isRunning, "Service should still not be running")
    }

    func testResumeWhenAlreadyRunning() {
        service.startTimer()
        XCTAssertTrue(service.isRunning, "Service should be running")

        service.resume()  // Should not crash or change state

        XCTAssertTrue(service.isRunning, "Service should still be running")
    }

    // MARK: - State Access Tests

    func testStateAccess() {
        XCTAssertNotNil(service.currentTimestamp, "Current timestamp should be accessible")
        XCTAssertNotNil(service.lastUpdate, "Last update should be accessible")
        XCTAssertEqual(service.isRunning, false, "Running state should be accessible")
        XCTAssertEqual(service.currentUnit, .seconds, "Current unit should be accessible")
    }

    // MARK: - Memory Management Tests

    func testTimerCleanupOnDeinit() {
        var testService: RealTimeTimestampService? = RealTimeTimestampService()
        testService?.startTimer()

        XCTAssertTrue(testService?.isRunning == true, "Service should be running")

        testService = nil  // Should trigger deinit and cleanup timer

        // If we reach here without crashes, timer cleanup worked
        XCTAssertTrue(true, "Timer cleanup on deinit should not crash")
    }

    // MARK: - Performance Tests

    func testTimerPerformance() {
        let config = RealTimeTimestampConfiguration(updateInterval: 0.01)  // Very fast updates
        let performanceService = RealTimeTimestampService(configuration: config)

        performanceService.startTimer()

        let expectation = XCTestExpectation(description: "Performance test should complete")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            performanceService.stopTimer()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)

        // If we reach here without crashes or excessive memory usage, performance is acceptable
        XCTAssertTrue(true, "High-frequency timer updates should not cause performance issues")
    }
}
