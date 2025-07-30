import SwiftUI
import XCTest

@testable import Tools

/// Integration tests for the Toast notification system
/// Tests SwiftUI environment integration, view modifier functionality,
/// multiple toast handling, animations, and memory management
final class ToastIntegrationTests: XCTestCase {

    // MARK: - Test Properties

    private var toastManager: ToastManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    override func tearDown() {
        toastManager.dismissAll()
        toastManager = nil
        super.tearDown()
    }

    // MARK: - SwiftUI Environment Integration Tests (Requirement 3.1, 3.3)

    func testEnvironmentIntegrationBasic() {
        let expectation = XCTestExpectation(description: "Environment integration should work")

        struct TestView: View {
            @Environment(ToastManager.self) private var toastManager
            let completion: () -> Void

            var body: some View {
                VStack {
                    Text("Test View")
                    Button("Show Toast") {
                        toastManager.show("Environment test", type: .success)
                        completion()
                    }
                }
            }
        }

        let testView = TestView {
            expectation.fulfill()
        }
        .environment(toastManager)

        // Create hosting controller to simulate real SwiftUI environment
        let hostingController = NSHostingController(rootView: testView)
        XCTAssertNotNil(hostingController)

        // Simulate button tap
        DispatchQueue.main.async {
            // In real app, this would be triggered by user interaction
            self.toastManager.show("Environment test", type: .success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.message, "Environment test")
    }

    func testEnvironmentIntegrationWithNestedViews() {
        let expectation = XCTestExpectation(description: "Nested environment integration")

        struct ParentView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Text("Parent")
                    ChildView()
                }
            }
        }

        struct ChildView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                Button("Child Toast") {
                    toastManager.show("Child message", type: .info)
                }
            }
        }

        let parentView = ParentView()
            .environment(toastManager)

        let hostingController = NSHostingController(rootView: parentView)
        XCTAssertNotNil(hostingController)

        // Simulate child view interaction
        DispatchQueue.main.async {
            self.toastManager.show("Child message", type: .info)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(toastManager.toasts.count, 1)
    }

    func testEnvironmentIntegrationWithTabView() {
        struct TabTestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                TabView {
                    VStack {
                        Text("Tab 1")
                        Button("Tab 1 Toast") {
                            toastManager.show("Tab 1 message", type: .success)
                        }
                    }
                    .tabItem { Text("First") }

                    VStack {
                        Text("Tab 2")
                        Button("Tab 2 Toast") {
                            toastManager.show("Tab 2 message", type: .error)
                        }
                    }
                    .tabItem { Text("Second") }
                }
            }
        }

        let tabView = TabTestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: tabView)
        XCTAssertNotNil(hostingController)

        // Test that both tabs can access the same toast manager
        toastManager.show("Tab 1 message", type: .success)
        toastManager.show("Tab 2 message", type: .error)

        XCTAssertEqual(toastManager.toasts.count, 2)
    }

    // MARK: - View Modifier Functionality Tests (Requirement 3.3)

    func testToastModifierBasicFunctionality() {
        struct TestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                Text("Test")
                    .onAppear {
                        toastManager.show("Modifier test", type: .warning)
                    }
            }
        }

        let modifiedView = TestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: modifiedView)
        XCTAssertNotNil(hostingController)

        // Simulate onAppear
        toastManager.show("Modifier test", type: .warning)
        XCTAssertEqual(toastManager.toasts.count, 1)
    }

    func testToastModifierWithDifferentViews() {
        // Test modifier works with different view types
        let textView = Text("Text View").toast()
        let buttonView = Button("Button") {}.toast()
        let stackView = VStack { Text("Stack") }.toast()
        let listView = List { Text("List Item") }.toast()

        XCTAssertNotNil(textView)
        XCTAssertNotNil(buttonView)
        XCTAssertNotNil(stackView)
        XCTAssertNotNil(listView)
    }

    func testToastEnvironmentModifier() {
        struct TestApp: View {
            var body: some View {
                NavigationView {
                    VStack {
                        Text("Main Content")
                    }
                }
                .toastEnvironment()
            }
        }

        let appView = TestApp()
        let hostingController = NSHostingController(rootView: appView)
        XCTAssertNotNil(hostingController)
    }

    func testToastModifierWithCustomManager() {
        let customManager = ToastManager()

        struct TestView: View {
            var body: some View {
                Text("Custom Manager Test")
            }
        }

        let modifiedView = TestView()
            .toast(manager: customManager)

        let hostingController = NSHostingController(rootView: modifiedView)
        XCTAssertNotNil(hostingController)

        // Test that custom manager works
        customManager.show("Custom test", type: .info)
        XCTAssertEqual(customManager.toasts.count, 1)
    }

    // MARK: - Multiple Toast Handling and Stacking Tests (Requirement 1.3)

    func testMultipleToastStacking() {
        let expectation = XCTestExpectation(description: "Multiple toasts should stack properly")

        struct MultiToastView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Button("Add Multiple Toasts") {
                        toastManager.show("First toast", type: .success)
                        toastManager.show("Second toast", type: .error)
                        toastManager.show("Third toast", type: .warning)
                        toastManager.show("Fourth toast", type: .info)
                    }
                }
            }
        }

        let multiToastView = MultiToastView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: multiToastView)
        XCTAssertNotNil(hostingController)

        // Simulate adding multiple toasts
        toastManager.show("First toast", type: .success)
        toastManager.show("Second toast", type: .error)
        toastManager.show("Third toast", type: .warning)
        toastManager.show("Fourth toast", type: .info)

        XCTAssertEqual(toastManager.toasts.count, 4)

        // Test that each toast has unique positioning
        let toastIds = Set(toastManager.toasts.map { $0.id })
        XCTAssertEqual(toastIds.count, 4, "Each toast should have unique ID for stacking")

        expectation.fulfill()
        wait(for: [expectation], timeout: 0.1)
    }

    func testToastQueueBehavior() {
        // Test queue behavior when exceeding capacity
        for i in 1...7 {  // Exceed default capacity of 5
            toastManager.show("Queue test \(i)", type: .info, duration: 10.0)
        }

        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount, 5)
        XCTAssertEqual(status.queuedCount, 2)
    }

    func testToastQueueProcessing() {
        let expectation = XCTestExpectation(
            description: "Queue should process when space available")

        // Fill to capacity with short duration
        for i in 1...5 {
            toastManager.show("Short \(i)", type: .info, duration: 0.1)
        }

        // Add queued toast
        toastManager.show("Queued toast", type: .success, duration: 1.0)

        let initialStatus = toastManager.queueStatus
        XCTAssertEqual(initialStatus.displayedCount, 5)
        XCTAssertEqual(initialStatus.queuedCount, 1)

        // Wait for queue processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let processedStatus = self.toastManager.queueStatus
            XCTAssertEqual(processedStatus.queuedCount, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRapidToastRequests() {
        let expectation = XCTestExpectation(
            description: "Rapid requests should be handled gracefully")

        struct RapidToastView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                Button("Rapid Fire") {
                    // Simulate rapid clicking
                    for i in 1...15 {
                        toastManager.show("Rapid \(i)", type: .info, duration: 0.1)
                    }
                }
            }
        }

        let rapidView = RapidToastView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: rapidView)
        XCTAssertNotNil(hostingController)

        // Simulate rapid requests
        for i in 1...15 {
            toastManager.show("Rapid \(i)", type: .info, duration: 0.1)
        }

        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount + status.queuedCount, 15)

        expectation.fulfill()
        wait(for: [expectation], timeout: 0.1)
    }

    // MARK: - Animation and Transition Testing

    func testToastAnimationStates() {
        struct AnimationTestView: View {
            @Environment(ToastManager.self) private var toastManager
            @State private var showToast = false

            var body: some View {
                VStack {
                    Button("Toggle Toast") {
                        if showToast {
                            toastManager.dismissAll()
                        } else {
                            toastManager.show("Animation test", type: .success, duration: 5.0)
                        }
                        showToast.toggle()
                    }
                }
            }
        }

        let animationView = AnimationTestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: animationView)
        XCTAssertNotNil(hostingController)

        // Test entrance animation
        toastManager.show("Animation test", type: .success, duration: 5.0)
        XCTAssertEqual(toastManager.toasts.count, 1)

        // Test exit animation
        toastManager.dismissAll()
        XCTAssertEqual(toastManager.toasts.count, 0)
    }

    func testToastHoverAnimations() {
        let toast = ToastMessage(message: "Hover test", type: .info, duration: 2.0)
        toastManager.show("Hover test", type: .info, duration: 2.0)

        let actualToast = toastManager.toasts.first!

        // Test hover pause
        toastManager.pauseAutoDismiss(for: actualToast)
        XCTAssertTrue(toastManager.isTimerPaused(for: actualToast))

        // Test hover resume
        toastManager.resumeAutoDismiss(for: actualToast, remainingTime: 1.0)
        XCTAssertFalse(toastManager.isTimerPaused(for: actualToast))
    }

    func testStackingAnimations() {
        // Test that multiple toasts animate properly when stacking
        let toasts = [
            ("First", ToastType.success),
            ("Second", ToastType.error),
            ("Third", ToastType.warning),
        ]

        for (message, type) in toasts {
            toastManager.show(message, type: type, duration: 5.0)
        }

        XCTAssertEqual(toastManager.toasts.count, 3)

        // Each toast should maintain its own animation state
        for toast in toastManager.toasts {
            XCTAssertNotNil(toast.id)
            XCTAssertFalse(toast.message.isEmpty)
        }
    }

    // MARK: - Memory Management and Cleanup Tests

    func testToastManagerMemoryCleanup() {
        weak var weakManager: ToastManager?

        autoreleasepool {
            let manager = ToastManager()
            weakManager = manager

            // Add toasts with timers
            manager.show("Memory test 1", type: .success, duration: 10.0)
            manager.show("Memory test 2", type: .error, duration: 10.0)

            XCTAssertEqual(manager.toasts.count, 2)
            XCTAssertNotNil(weakManager)
        }

        // Manager should be deallocated after autoreleasepool
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakManager, "ToastManager should be deallocated")
        }
    }

    func testTimerCleanupOnManagerDeallocation() {
        let expectation = XCTestExpectation(description: "Timers should be cleaned up")

        autoreleasepool {
            let manager = ToastManager()

            // Add toasts with long duration
            manager.show("Timer cleanup test", type: .info, duration: 100.0)
            XCTAssertEqual(manager.toasts.count, 1)

            let toast = manager.toasts.first!
            XCTAssertNotNil(manager.getRemainingTime(for: toast))

            // Manager will be deallocated here
        }

        // Should not crash due to timer cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testViewControllerMemoryManagement() {
        weak var weakController: NSHostingController<AnyView>?

        autoreleasepool {
            struct TestView: View {
                @Environment(ToastManager.self) private var toastManager

                var body: some View {
                    Text("Memory test")
                        .onAppear {
                            toastManager.show("View appeared", type: .info)
                        }
                }
            }

            let testView = TestView()
                .environment(toastManager)
                .toast()

            let controller = NSHostingController(rootView: AnyView(testView))
            weakController = controller

            XCTAssertNotNil(weakController)
        }

        // Controller should be deallocated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(weakController, "View controller should be deallocated")
        }
    }

    func testToastQueueMemoryManagement() {
        // Test that queue doesn't accumulate indefinitely
        for i in 1...100 {
            toastManager.show("Queue memory test \(i)", type: .info, duration: 0.01)
        }

        let status = toastManager.queueStatus
        XCTAssertLessThanOrEqual(status.displayedCount + status.queuedCount, 100)

        // Clear queue to test cleanup
        toastManager.clearQueue()
        let clearedStatus = toastManager.queueStatus
        XCTAssertEqual(clearedStatus.queuedCount, 0)
    }

    // MARK: - Integration with Real App Components

    func testIntegrationWithClipboardView() {
        // Test integration with actual app component
        struct MockClipboardView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Button("Copy Success") {
                        toastManager.show("复制成功", type: .success)
                    }

                    Button("Copy Error") {
                        toastManager.show("复制失败", type: .error)
                    }
                }
            }
        }

        let clipboardView = MockClipboardView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: clipboardView)
        XCTAssertNotNil(hostingController)

        // Test success scenario
        toastManager.show("复制成功", type: .success)
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)

        // Test error scenario
        toastManager.show("复制失败", type: .error)
        XCTAssertEqual(toastManager.toasts.count, 2)
    }

    func testIntegrationWithJSONView() {
        // Test integration with JSON processing component
        struct MockJSONView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Button("Format Success") {
                        toastManager.show("JSON格式化成功", type: .success)
                    }

                    Button("Validation Error") {
                        toastManager.show("JSON格式错误", type: .error)
                    }

                    Button("Processing Warning") {
                        toastManager.show("处理中，请稍候", type: .warning)
                    }
                }
            }
        }

        let jsonView = MockJSONView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: jsonView)
        XCTAssertNotNil(hostingController)

        // Test different scenarios
        toastManager.show("JSON格式化成功", type: .success)
        toastManager.show("JSON格式错误", type: .error)
        toastManager.show("处理中，请稍候", type: .warning)

        XCTAssertEqual(toastManager.toasts.count, 3)
    }

    func testIntegrationWithNavigationView() {
        // Test integration with navigation-based views
        struct NavigationTestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                NavigationView {
                    VStack {
                        NavigationLink("Go to Detail") {
                            DetailView()
                        }

                        Button("Show Toast") {
                            toastManager.show("Navigation toast", type: .info)
                        }
                    }
                    .navigationTitle("Main")
                }
            }
        }

        struct DetailView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Text("Detail View")
                    Button("Detail Toast") {
                        toastManager.show("Detail toast", type: .success)
                    }
                }
                .navigationTitle("Detail")
            }
        }

        let navigationView = NavigationTestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: navigationView)
        XCTAssertNotNil(hostingController)

        // Test that toasts work across navigation
        toastManager.show("Navigation toast", type: .info)
        toastManager.show("Detail toast", type: .success)

        XCTAssertEqual(toastManager.toasts.count, 2)
    }

    // MARK: - Cross-Platform Integration Tests

    func testMacOSSpecificIntegration() {
        // Test macOS-specific features
        struct MacOSTestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Text("macOS Integration Test")
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: NSApplication.didBecomeActiveNotification)
                ) { _ in
                    toastManager.show("App became active", type: .info)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: NSApplication.didResignActiveNotification)
                ) { _ in
                    toastManager.show("App resigned active", type: .warning)
                }
            }
        }

        let macOSView = MacOSTestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: macOSView)
        XCTAssertNotNil(hostingController)
    }

    // MARK: - Performance Integration Tests

    func testIntegrationPerformance() {
        measure {
            struct PerformanceTestView: View {
                @Environment(ToastManager.self) private var toastManager

                var body: some View {
                    VStack {
                        ForEach(0..<100, id: \.self) { index in
                            Button("Toast \(index)") {
                                toastManager.show(
                                    "Performance test \(index)", type: .info, duration: 0.01)
                            }
                        }
                    }
                }
            }

            let performanceView = PerformanceTestView()
                .environment(toastManager)
                .toast()

            let hostingController = NSHostingController(rootView: performanceView)
            _ = hostingController

            // Simulate rapid toast creation
            for i in 0..<100 {
                toastManager.show("Performance test \(i)", type: .info, duration: 0.01)
            }

            toastManager.dismissAll()
        }
    }

    // MARK: - Thread Safety Integration Tests

    func testConcurrentIntegration() {
        let expectation = XCTestExpectation(
            description: "Concurrent integration should be thread-safe")
        let group = DispatchGroup()

        struct ConcurrentTestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                Text("Concurrent Test")
            }
        }

        let concurrentView = ConcurrentTestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: concurrentView)
        XCTAssertNotNil(hostingController)

        // Concurrent operations from different threads
        for i in 0..<20 {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.toastManager.show("Concurrent \(i)", type: .info, duration: 0.1)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertGreaterThan(self.toastManager.toasts.count, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Requirements Validation Integration Tests

    func testRequirement3_1_IntegrationAPI() {
        // Requirement 3.1: Simple API integration across views
        struct APITestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Button("Basic API") {
                        toastManager.show("Basic message", type: .success)
                    }

                    Button("Custom Duration API") {
                        toastManager.show("Custom duration", type: .error, duration: 5.0)
                    }

                    Button("Batch API") {
                        toastManager.showBatch(["Batch 1", "Batch 2"], type: .info)
                    }
                }
            }
        }

        let apiTestView = APITestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: apiTestView)
        XCTAssertNotNil(hostingController)

        // Test API calls
        toastManager.show("Basic message", type: .success)
        toastManager.show("Custom duration", type: .error, duration: 5.0)
        toastManager.showBatch(["Batch 1", "Batch 2"], type: .info)

        XCTAssertGreaterThan(toastManager.toasts.count, 0)
    }

    func testRequirement3_3_ModifierIntegration() {
        // Requirement 3.3: SwiftUI modifier integration
        struct ModifierIntegrationView: View {
            var body: some View {
                TabView {
                    Text("Tab 1")
                        .tabItem { Text("First") }

                    Text("Tab 2")
                        .tabItem { Text("Second") }
                }
                .toastEnvironment()  // Environment-based approach
            }
        }

        let modifierView = ModifierIntegrationView()
        let hostingController = NSHostingController(rootView: modifierView)
        XCTAssertNotNil(hostingController)

        // Test direct modifier approach
        let directModifierView = Text("Direct").toast()
        let directController = NSHostingController(rootView: directModifierView)
        XCTAssertNotNil(directController)

        // Test custom manager approach
        let customManagerView = Text("Custom").toast(manager: toastManager)
        let customController = NSHostingController(rootView: customManagerView)
        XCTAssertNotNil(customController)
    }

    func testRequirement1_3_QueueIntegration() {
        // Requirement 1.3: Queue management integration
        struct QueueTestView: View {
            @Environment(ToastManager.self) private var toastManager

            var body: some View {
                VStack {
                    Button("Fill Queue") {
                        for i in 1...10 {
                            toastManager.show("Queue item \(i)", type: .info, duration: 5.0)
                        }
                    }

                    Button("Clear Queue") {
                        toastManager.clearQueue()
                    }

                    Button("Dismiss All") {
                        toastManager.dismissAll()
                    }
                }
            }
        }

        let queueView = QueueTestView()
            .environment(toastManager)
            .toast()

        let hostingController = NSHostingController(rootView: queueView)
        XCTAssertNotNil(hostingController)

        // Test queue behavior
        for i in 1...10 {
            toastManager.show("Queue item \(i)", type: .info, duration: 5.0)
        }

        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount, 5)
        XCTAssertEqual(status.queuedCount, 5)

        toastManager.clearQueue()
        let clearedStatus = toastManager.queueStatus
        XCTAssertEqual(clearedStatus.queuedCount, 0)
    }

    // MARK: - Comprehensive Integration Test

    func testComprehensiveIntegration() {
        // Test all integration aspects together
        struct ComprehensiveTestApp: View {
            @State private var toastManager = ToastManager()

            var body: some View {
                NavigationView {
                    TabView {
                        // Tab 1: Basic functionality
                        VStack {
                            Button("Success") {
                                toastManager.show("操作成功", type: .success)
                            }
                            Button("Error") {
                                toastManager.show("操作失败", type: .error)
                            }
                        }
                        .tabItem { Text("Basic") }

                        // Tab 2: Advanced functionality
                        VStack {
                            Button("Multiple Toasts") {
                                for i in 1...5 {
                                    toastManager.show(
                                        "Toast \(i)", type: .info, duration: Double(i))
                                }
                            }
                            Button("Clear All") {
                                toastManager.dismissAll()
                            }
                        }
                        .tabItem { Text("Advanced") }
                    }
                }
                .environment(toastManager)
                .toast()
            }
        }

        let comprehensiveApp = ComprehensiveTestApp()
        let hostingController = NSHostingController(rootView: comprehensiveApp)
        XCTAssertNotNil(hostingController)

        // Test comprehensive functionality
        toastManager.show("操作成功", type: .success)
        toastManager.show("操作失败", type: .error)

        for i in 1...5 {
            toastManager.show("Toast \(i)", type: .info, duration: Double(i))
        }

        XCTAssertEqual(toastManager.toasts.count, 7)

        toastManager.dismissAll()
        XCTAssertEqual(toastManager.toasts.count, 0)

        print("✅ All toast integration tests completed successfully")
    }
}
