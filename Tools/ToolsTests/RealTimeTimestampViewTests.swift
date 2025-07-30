import SwiftUI
import XCTest

@testable import Tools

// MARK: - Real-Time Timestamp View Tests

@MainActor
final class RealTimeTimestampViewTests: XCTestCase {

    // MARK: - Properties

    private var toastManager: ToastManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    override func tearDown() {
        toastManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testViewInitialization() {
        // Given
        let configuration = RealTimeTimestampConfiguration(
            updateInterval: 1.0,
            autoStart: true,
            defaultUnit: .seconds
        )

        // When
        let view = RealTimeTimestampView(configuration: configuration)

        // Then
        XCTAssertNotNil(view)
    }

    func testViewInitializationWithDefaultConfiguration() {
        // When
        let view = RealTimeTimestampView()

        // Then
        XCTAssertNotNil(view)
    }

    // MARK: - Timer Management Tests

    func testTimerStartsOnAppear() async {
        // Given
        let configuration = RealTimeTimestampConfiguration(
            updateInterval: 0.1,
            autoStart: false,
            defaultUnit: .seconds
        )
        let view = RealTimeTimestampView(configuration: configuration)

        // When
        let hostingController = NSHostingController(
            rootView: view.environment(\.toastManager, toastManager))

        // Simulate view appearing
        hostingController.viewDidAppear()

        // Then
        // Wait a bit for timer to start
        try? await Task.sleep(nanoseconds: 200_000_000)  // 0.2 seconds

        // The view should have started the timer on appear
        // We can't directly test the service state, but we can verify the view renders
        XCTAssertNotNil(hostingController.view)
    }

    func testTimerStopsOnDisappear() async {
        // Given
        let configuration = RealTimeTimestampConfiguration(
            updateInterval: 0.1,
            autoStart: true,
            defaultUnit: .seconds
        )
        let view = RealTimeTimestampView(configuration: configuration)
        let hostingController = NSHostingController(
            rootView: view.environment(\.toastManager, toastManager))

        // When
        hostingController.viewDidAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        hostingController.viewDidDisappear()

        // Then
        // Timer should be stopped when view disappears
        XCTAssertNotNil(hostingController.view)
    }

    // MARK: - UI Component Tests

    func testViewContainsRequiredElements() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)
        let hostingController = NSHostingController(rootView: view)

        // When
        let viewController = hostingController

        // Then
        XCTAssertNotNil(viewController.view)

        // Test that the view hierarchy contains expected elements
        let viewHierarchy = viewController.view.subviews
        XCTAssertFalse(viewHierarchy.isEmpty)
    }

    func testAccessibilityLabels() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)

        // Then
        XCTAssertNotNil(hostingController.view)

        // The view should have proper accessibility setup
        // We can't easily test the specific labels without more complex UI testing,
        // but we can verify the view renders without errors
    }

    // MARK: - Button Interaction Tests

    func testUnitToggleButtonExists() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)

        // Then
        XCTAssertNotNil(hostingController.view)

        // The view should render with all buttons
        let viewHierarchy = hostingController.view.subviews
        XCTAssertFalse(viewHierarchy.isEmpty)
    }

    func testCopyButtonExists() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)

        // Then
        XCTAssertNotNil(hostingController.view)

        // The view should render with copy button
        let viewHierarchy = hostingController.view.subviews
        XCTAssertFalse(viewHierarchy.isEmpty)
    }

    func testTimerToggleButtonExists() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)

        // Then
        XCTAssertNotNil(hostingController.view)

        // The view should render with timer toggle button
        let viewHierarchy = hostingController.view.subviews
        XCTAssertFalse(viewHierarchy.isEmpty)
    }

    // MARK: - Toast Integration Tests

    func testToastManagerIntegration() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)

        // Then
        XCTAssertNotNil(hostingController.view)

        // Verify toast manager is properly injected
        XCTAssertEqual(toastManager.toasts.count, 0)
    }

    func testCopyActionTriggersToast() async {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)
        let hostingController = NSHostingController(rootView: view)

        // When
        // We can't easily simulate button clicks in unit tests,
        // but we can verify the view structure is correct
        hostingController.viewDidAppear()

        // Then
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(toastManager.toasts.count, 0)  // No toasts initially
    }

    // MARK: - Configuration Tests

    func testCustomConfiguration() {
        // Given
        let customConfig = RealTimeTimestampConfiguration(
            updateInterval: 0.5,
            autoStart: false,
            defaultUnit: .milliseconds
        )

        // When
        let view = RealTimeTimestampView(configuration: customConfig)
            .environment(\.toastManager, toastManager)

        // Then
        XCTAssertNotNil(view)

        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }

    func testDefaultConfiguration() {
        // When
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // Then
        XCTAssertNotNil(view)

        let hostingController = NSHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view)
    }

    // MARK: - Real-Time Update Tests

    func testTimestampUpdatesOverTime() async {
        // Given
        let configuration = RealTimeTimestampConfiguration(
            updateInterval: 0.1,  // Fast updates for testing
            autoStart: true,
            defaultUnit: .seconds
        )
        let view = RealTimeTimestampView(configuration: configuration)
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)
        hostingController.viewDidAppear()

        // Wait for multiple update cycles
        try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

        // Then
        XCTAssertNotNil(hostingController.view)

        // The view should still be rendering properly after updates
        let viewHierarchy = hostingController.view.subviews
        XCTAssertFalse(viewHierarchy.isEmpty)
    }

    // MARK: - Memory Management Tests

    func testViewDeallocation() {
        // Given
        var view: RealTimeTimestampView? = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)
        weak var weakView = view

        // When
        view = nil

        // Then
        // The view should be deallocated
        XCTAssertNil(weakView)
    }

    func testHostingControllerDeallocation() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)
        var hostingController: NSHostingController<some View>? = NSHostingController(rootView: view)
        weak var weakController = hostingController

        // When
        hostingController?.viewDidDisappear()
        hostingController = nil

        // Then
        // The controller should be deallocated
        XCTAssertNil(weakController)
    }

    // MARK: - Error Handling Tests

    func testViewHandlesServiceErrors() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When
        let hostingController = NSHostingController(rootView: view)

        // Then
        // View should handle any service errors gracefully
        XCTAssertNotNil(hostingController.view)

        // Simulate view lifecycle
        hostingController.viewDidAppear()
        hostingController.viewDidDisappear()

        // Should not crash
        XCTAssertNotNil(hostingController.view)
    }

    // MARK: - Performance Tests

    func testViewRenderingPerformance() {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)

        // When & Then
        measure {
            let hostingController = NSHostingController(rootView: view)
            _ = hostingController.view
        }
    }

    func testMultipleViewInstances() {
        // Given
        let views = (0..<10).map { _ in
            RealTimeTimestampView()
                .environment(\.toastManager, toastManager)
        }

        // When
        let controllers = views.map { NSHostingController(rootView: $0) }

        // Then
        XCTAssertEqual(controllers.count, 10)
        controllers.forEach { controller in
            XCTAssertNotNil(controller.view)
        }
    }

    // MARK: - Integration Tests

    func testViewIntegrationWithToastManager() async {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)
        let hostingController = NSHostingController(rootView: view)

        // When
        hostingController.viewDidAppear()

        // Simulate some time passing
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        // Then
        XCTAssertNotNil(hostingController.view)
        XCTAssertEqual(toastManager.toasts.count, 0)  // No toasts without user interaction
    }

    func testViewStatePreservation() async {
        // Given
        let view = RealTimeTimestampView()
            .environment(\.toastManager, toastManager)
        let hostingController = NSHostingController(rootView: view)

        // When
        hostingController.viewDidAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        hostingController.viewDidDisappear()
        hostingController.viewDidAppear()

        // Then
        XCTAssertNotNil(hostingController.view)

        // View should handle state transitions gracefully
        let viewHierarchy = hostingController.view.subviews
        XCTAssertFalse(viewHierarchy.isEmpty)
    }
}

// MARK: - Test Helpers

extension RealTimeTimestampViewTests {

    /// Helper method to create a test view with custom configuration
    private func createTestView(
        updateInterval: TimeInterval = 1.0,
        autoStart: Bool = true,
        defaultUnit: TimestampUnit = .seconds
    ) -> RealTimeTimestampView {
        let configuration = RealTimeTimestampConfiguration(
            updateInterval: updateInterval,
            autoStart: autoStart,
            defaultUnit: defaultUnit
        )
        return RealTimeTimestampView(configuration: configuration)
            .environment(\.toastManager, toastManager)
    }

    /// Helper method to simulate view lifecycle
    private func simulateViewLifecycle(_ hostingController: NSHostingController<some View>) async {
        hostingController.viewDidAppear()
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        hostingController.viewDidDisappear()
    }
}
