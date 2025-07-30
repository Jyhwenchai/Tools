import XCTest

@testable import Tools

final class ToastManagerTests: XCTestCase {
    var toastManager: ToastManager!

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    override func tearDown() {
        toastManager = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testShowToast() {
        // Given
        let message = "Test message"
        let type = ToastType.success
        let duration: TimeInterval = 2.0

        // When
        toastManager.show(message, type: type, duration: duration)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)

        let toast = toastManager.toasts.first!
        XCTAssertEqual(toast.message, message)
        XCTAssertEqual(toast.type, type)
        XCTAssertEqual(toast.duration, duration)
        XCTAssertTrue(toast.isAutoDismiss)
    }

    func testShowMultipleToasts() {
        // Given
        let messages = ["Message 1", "Message 2", "Message 3"]

        // When
        for message in messages {
            toastManager.show(message, type: .info)
        }

        // Then
        XCTAssertEqual(toastManager.toasts.count, 3)

        for (index, toast) in toastManager.toasts.enumerated() {
            XCTAssertEqual(toast.message, messages[index])
            XCTAssertEqual(toast.type, .info)
        }
    }

    func testShowToastWithDefaultDuration() {
        // When
        toastManager.show("Test", type: .success)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first!.duration, 3.0)
    }

    func testShowToastWithZeroDurationDisablesAutoDismiss() {
        // When
        toastManager.show("Test", type: .success, duration: 0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertFalse(toastManager.toasts.first!.isAutoDismiss)
    }

    // MARK: - Dismiss Functionality Tests

    func testDismissSpecificToast() {
        // Given
        toastManager.show("Message 1", type: .success)
        toastManager.show("Message 2", type: .error)
        toastManager.show("Message 3", type: .warning)

        let toastToDismiss = toastManager.toasts[1]  // Middle toast

        // When
        toastManager.dismiss(toastToDismiss)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 2)
        XCTAssertFalse(toastManager.toasts.contains { $0.id == toastToDismiss.id })
        XCTAssertEqual(toastManager.toasts[0].message, "Message 1")
        XCTAssertEqual(toastManager.toasts[1].message, "Message 3")
    }

    func testDismissNonExistentToast() {
        // Given
        toastManager.show("Existing message", type: .success)
        let nonExistentToast = ToastMessage(message: "Non-existent", type: .error)

        // When
        toastManager.dismiss(nonExistentToast)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first!.message, "Existing message")
    }

    func testDismissAll() {
        // Given
        toastManager.show("Message 1", type: .success)
        toastManager.show("Message 2", type: .error)
        toastManager.show("Message 3", type: .warning)

        // When
        toastManager.dismissAll()

        // Then
        XCTAssertEqual(toastManager.toasts.count, 0)
    }

    func testDismissAllWithEmptyArray() {
        // When
        toastManager.dismissAll()

        // Then
        XCTAssertEqual(toastManager.toasts.count, 0)
    }

    // MARK: - Auto-Dismiss Timer Tests

    func testAutoDismissAfterDuration() {
        let expectation = XCTestExpectation(description: "Toast should auto-dismiss")

        // Given
        let shortDuration: TimeInterval = 0.1

        // When
        toastManager.show("Test message", type: .success, duration: shortDuration)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)

        // Wait for auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + shortDuration + 0.05) {
            XCTAssertEqual(self.toastManager.toasts.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testMultipleToastsAutoDismissIndependently() {
        let expectation1 = XCTestExpectation(description: "First toast should auto-dismiss")
        let expectation2 = XCTestExpectation(description: "Second toast should auto-dismiss")

        // Given
        let shortDuration: TimeInterval = 0.1
        let longerDuration: TimeInterval = 0.2

        // When
        toastManager.show("First message", type: .success, duration: shortDuration)
        toastManager.show("Second message", type: .error, duration: longerDuration)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 2)

        // Check first toast dismisses
        DispatchQueue.main.asyncAfter(deadline: .now() + shortDuration + 0.05) {
            XCTAssertEqual(self.toastManager.toasts.count, 1)
            XCTAssertEqual(self.toastManager.toasts.first!.message, "Second message")
            expectation1.fulfill()
        }

        // Check second toast dismisses
        DispatchQueue.main.asyncAfter(deadline: .now() + longerDuration + 0.05) {
            XCTAssertEqual(self.toastManager.toasts.count, 0)
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    func testManualDismissCancelsTimer() {
        let expectation = XCTestExpectation(
            description: "Toast should not auto-dismiss after manual dismiss")

        // Given
        let duration: TimeInterval = 0.2

        // When
        toastManager.show("Test message", type: .success, duration: duration)
        let toast = toastManager.toasts.first!

        // Manually dismiss before auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.toastManager.dismiss(toast)
            XCTAssertEqual(self.toastManager.toasts.count, 0)
        }

        // Verify it doesn't get dismissed again by timer
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            XCTAssertEqual(self.toastManager.toasts.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Pause/Resume Timer Tests

    func testPauseAutoDismiss() {
        // Given
        toastManager.show("Test message", type: .success, duration: 1.0)
        let toast = toastManager.toasts.first!

        // When
        toastManager.pauseAutoDismiss(for: toast)

        // Then - Toast should still be present after original duration
        let expectation = XCTestExpectation(description: "Toast should remain after pause")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertEqual(self.toastManager.toasts.count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testResumeAutoDismiss() {
        let expectation = XCTestExpectation(description: "Toast should dismiss after resume")

        // Given
        toastManager.show("Test message", type: .success, duration: 1.0)
        let toast = toastManager.toasts.first!

        // When
        toastManager.pauseAutoDismiss(for: toast)

        // Resume with short remaining time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.toastManager.resumeAutoDismiss(for: toast, remainingTime: 0.1)
        }

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            XCTAssertEqual(self.toastManager.toasts.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testResumeAutoDismissWithZeroTimeDoesNothing() {
        // Given
        toastManager.show("Test message", type: .success, duration: 1.0)
        let toast = toastManager.toasts.first!

        // When
        toastManager.pauseAutoDismiss(for: toast)
        toastManager.resumeAutoDismiss(for: toast, remainingTime: 0)

        // Then - Toast should remain
        let expectation = XCTestExpectation(
            description: "Toast should remain with zero remaining time")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.toastManager.toasts.count, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Edge Cases

    func testDismissAllCancelsAllTimers() {
        let expectation = XCTestExpectation(description: "No toasts should remain after dismissAll")

        // Given
        toastManager.show("Message 1", type: .success, duration: 0.2)
        toastManager.show("Message 2", type: .error, duration: 0.3)
        toastManager.show("Message 3", type: .warning, duration: 0.4)

        // When
        toastManager.dismissAll()

        // Then - No toasts should auto-dismiss after their original durations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.toastManager.toasts.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testToastTypesAndProperties() {
        // Test all toast types
        let testCases: [(ToastType, String)] = [
            (.success, "Success message"),
            (.error, "Error message"),
            (.warning, "Warning message"),
            (.info, "Info message"),
        ]

        for (type, message) in testCases {
            toastManager.show(message, type: type)
        }

        XCTAssertEqual(toastManager.toasts.count, 4)

        for (index, (expectedType, expectedMessage)) in testCases.enumerated() {
            let toast = toastManager.toasts[index]
            XCTAssertEqual(toast.type, expectedType)
            XCTAssertEqual(toast.message, expectedMessage)
            XCTAssertEqual(toast.duration, 3.0)  // Default duration
            XCTAssertTrue(toast.isAutoDismiss)
        }
    }

    // MARK: - Enhanced Timer Management Tests

    func testRemainingTimeCalculation() {
        // Given
        let duration: TimeInterval = 1.0
        toastManager.show("Test message", type: .success, duration: duration)
        let toast = toastManager.toasts.first!

        // When - Check remaining time immediately
        let remainingTime = toastManager.getRemainingTime(for: toast)

        // Then
        XCTAssertNotNil(remainingTime)
        XCTAssertGreaterThan(remainingTime!, 0.9)  // Should be close to full duration
        XCTAssertLessThanOrEqual(remainingTime!, duration)
    }

    func testTimerPauseState() {
        // Given
        toastManager.show("Test message", type: .success, duration: 1.0)
        let toast = toastManager.toasts.first!

        // When - Initially not paused
        XCTAssertFalse(toastManager.isTimerPaused(for: toast))

        // Pause the timer
        toastManager.pauseAutoDismiss(for: toast)

        // Then
        XCTAssertTrue(toastManager.isTimerPaused(for: toast))
    }

    func testPauseAndResumeWithRemainingTime() {
        let expectation = XCTestExpectation(
            description: "Toast should dismiss after pause/resume cycle")

        // Given
        let duration: TimeInterval = 0.3
        toastManager.show("Test message", type: .success, duration: duration)
        let toast = toastManager.toasts.first!

        // When - Pause after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.toastManager.pauseAutoDismiss(for: toast)
            XCTAssertTrue(self.toastManager.isTimerPaused(for: toast))

            // Resume after another delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.toastManager.resumeAutoDismiss(for: toast)
                XCTAssertFalse(self.toastManager.isTimerPaused(for: toast))
            }
        }

        // Then - Should dismiss after total duration accounting for pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(self.toastManager.toasts.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Queue Management Tests

    func testQueueStatus() {
        // Given - Empty state
        let initialStatus = toastManager.queueStatus
        XCTAssertEqual(initialStatus.queuedCount, 0)
        XCTAssertEqual(initialStatus.displayedCount, 0)
        XCTAssertEqual(initialStatus.maxCapacity, 5)

        // When - Add some toasts
        for i in 1...3 {
            toastManager.show("Message \(i)", type: .info)
        }

        let statusAfterAdding = toastManager.queueStatus
        XCTAssertEqual(statusAfterAdding.displayedCount, 3)
        XCTAssertEqual(statusAfterAdding.queuedCount, 0)
    }

    func testQueueManagementWithMaxCapacity() {
        let expectation = XCTestExpectation(description: "Queue should process excess toasts")

        // Given - Add more toasts than max capacity (5)
        for i in 1...7 {
            toastManager.show("Message \(i)", type: .info, duration: 0.1)
        }

        // Then - Should have 5 displayed and 2 queued
        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount, 5)
        XCTAssertEqual(status.queuedCount, 2)

        // Wait for some toasts to dismiss and queue to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let finalStatus = self.toastManager.queueStatus
            XCTAssertLessThan(finalStatus.displayedCount, 5)  // Some should have dismissed
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testClearQueue() {
        // Given - Add toasts beyond capacity
        for i in 1...8 {
            toastManager.show("Message \(i)", type: .info)
        }

        let statusBefore = toastManager.queueStatus
        XCTAssertEqual(statusBefore.displayedCount, 5)
        XCTAssertEqual(statusBefore.queuedCount, 3)

        // When
        toastManager.clearQueue()

        // Then
        let statusAfter = toastManager.queueStatus
        XCTAssertEqual(statusAfter.displayedCount, 5)  // Displayed toasts remain
        XCTAssertEqual(statusAfter.queuedCount, 0)  // Queue cleared
    }

    func testBatchToastHandling() {
        // Given
        let messages = ["Batch 1", "Batch 2", "Batch 3", "Batch 4", "Batch 5", "Batch 6"]

        // When
        toastManager.showBatch(messages, type: .success, duration: 0.2)

        // Then - Should display max capacity and queue the rest
        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount, 5)
        XCTAssertEqual(status.queuedCount, 1)
    }

    func testRapidSuccessiveRequests() {
        let expectation = XCTestExpectation(
            description: "Rapid requests should be handled gracefully")

        // Given - Simulate rapid clicking/requests
        for i in 1...10 {
            DispatchQueue.global(qos: .userInitiated).async {
                self.toastManager.show("Rapid \(i)", type: .info, duration: 0.1)
            }
        }

        // Then - Should handle all requests without crashing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let status = self.toastManager.queueStatus
            XCTAssertEqual(status.displayedCount + status.queuedCount, 10)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Edge Cases and Error Handling

    func testResumeExpiredTimer() {
        let expectation = XCTestExpectation(
            description: "Expired timer should dismiss immediately on resume")

        // Given
        toastManager.show("Test message", type: .success, duration: 0.1)
        let toast = toastManager.toasts.first!

        // When - Pause and wait longer than duration
        toastManager.pauseAutoDismiss(for: toast)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Resume after duration has passed
            self.toastManager.resumeAutoDismiss(for: toast)

            // Then - Should dismiss immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                XCTAssertEqual(self.toastManager.toasts.count, 0)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testPauseNonExistentToast() {
        // Given
        let nonExistentToast = ToastMessage(message: "Non-existent", type: .error)

        // When - Should not crash
        toastManager.pauseAutoDismiss(for: nonExistentToast)
        toastManager.resumeAutoDismiss(for: nonExistentToast)

        // Then - Should handle gracefully
        XCTAssertEqual(toastManager.toasts.count, 0)
        XCTAssertNil(toastManager.getRemainingTime(for: nonExistentToast))
        XCTAssertFalse(toastManager.isTimerPaused(for: nonExistentToast))
    }

    func testMemoryManagementOnDeinit() {
        // Given
        var manager: ToastManager? = ToastManager()

        // Add some toasts with timers
        manager?.show("Test 1", type: .success, duration: 10.0)
        manager?.show("Test 2", type: .error, duration: 10.0)

        let status = manager?.queueStatus
        XCTAssertEqual(status?.displayedCount, 2)

        // When - Deallocate manager
        manager = nil

        // Then - Should not crash and properly clean up
        // This test mainly ensures deinit doesn't crash
        XCTAssertNil(manager)
    }
}
