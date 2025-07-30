# Toast Notification System Documentation

## Overview

The Toast notification system provides a universal, non-intrusive way to display temporary feedback messages across all features of the macOS Utility Toolkit. Built with SwiftUI and designed for macOS 15.5+, it offers consistent user feedback with native macOS design patterns, accessibility support, and seamless integration.

## Table of Contents

- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Integration Guide](#integration-guide)
- [Toast Types and Styling](#toast-types-and-styling)
- [Accessibility Features](#accessibility-features)
- [Advanced Usage](#advanced-usage)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Basic Setup

1. **Add ToastManager to your app environment** (typically in your main app file):

```swift
import SwiftUI

@main
struct ToolsApp: App {
    @State private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(toastManager)
                .toast() // Add toast overlay support
        }
    }
}
```

2. **Use toasts in any view**:

```swift
struct MyFeatureView: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        Button("Show Success Toast") {
            toastManager.show("操作成功完成！", type: .success)
        }
    }
}
```

### Alternative Setup (Environment + Modifier Combined)

For simpler setup, use the combined environment modifier:

```swift
struct ContentView: View {
    var body: some View {
        MainAppView()
            .toastEnvironment() // Sets up both environment and overlay
    }
}
```

## API Reference

### ToastManager

The main class for managing toast notifications.

#### Properties

```swift
@Observable
class ToastManager {
    /// Array of currently displayed toasts
    var toasts: [ToastMessage] { get }

    /// Current queue status (queued, displayed, max capacity)
    var queueStatus: (queuedCount: Int, displayedCount: Int, maxCapacity: Int) { get }

    /// Accessibility description for current toast state
    var accessibilityDescription: String { get }

    /// Detailed accessibility summary for screen readers
    var detailedAccessibilityDescription: String { get }
}
```

#### Methods

##### Basic Toast Display

```swift
/// Display a new toast notification
func show(
    _ message: String,
    type: ToastType,
    duration: TimeInterval = 3.0,
    announceImmediately: Bool = true
)
```

**Parameters:**

- `message`: The text to display in the toast
- `type`: Visual style (`.success`, `.error`, `.warning`, `.info`)
- `duration`: Auto-dismiss time in seconds (default: 3.0, set to 0 for manual dismiss only)
- `announceImmediately`: Whether to announce to accessibility services immediately

**Example:**

```swift
// Basic success toast
toastManager.show("文件保存成功", type: .success)

// Error toast with custom duration
toastManager.show("网络连接失败", type: .error, duration: 5.0)

// Manual dismiss only toast
toastManager.show("处理中...", type: .info, duration: 0)
```

##### Toast Management

```swift
/// Dismiss a specific toast
func dismiss(_ toast: ToastMessage)

/// Dismiss all currently displayed toasts
func dismissAll()

/// Clear the toast queue without affecting displayed toasts
func clearQueue()
```

**Example:**

```swift
// Dismiss all toasts when user navigates away
toastManager.dismissAll()

// Clear pending toasts but keep current ones
toastManager.clearQueue()
```

##### Timer Management

```swift
/// Pause auto-dismiss timer for a specific toast
func pauseAutoDismiss(for toast: ToastMessage)

/// Resume auto-dismiss timer for a specific toast
func resumeAutoDismiss(for toast: ToastMessage, remainingTime: TimeInterval? = nil)

/// Get remaining time for a toast's auto-dismiss timer
func getRemainingTime(for toast: ToastMessage) -> TimeInterval?

/// Check if a toast's timer is currently paused
func isTimerPaused(for toast: ToastMessage) -> Bool
```

##### Batch Operations

```swift
/// Display multiple toasts with the same type and duration
func showBatch(
    _ messages: [String],
    type: ToastType,
    duration: TimeInterval = 3.0
)
```

**Example:**

```swift
let validationErrors = [
    "用户名不能为空",
    "密码长度至少8位",
    "邮箱格式不正确"
]
toastManager.showBatch(validationErrors, type: .error, duration: 4.0)
```

### ToastMessage

The data model representing a toast notification.

```swift
struct ToastMessage: Identifiable, Equatable {
    let id: UUID
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let isAutoDismiss: Bool

    init(
        message: String,
        type: ToastType,
        duration: TimeInterval = 3.0,
        isAutoDismiss: Bool = true
    )
}
```

### ToastType

Enum defining the visual styles and behavior for different toast types.

```swift
enum ToastType: CaseIterable {
    case success    // Green theme with checkmark icon
    case error      // Red theme with exclamation icon
    case warning    // Orange theme with warning icon
    case info       // Blue theme with info icon

    var icon: String { get }                    // SF Symbol name
    var color: Color { get }                    // Primary color
    var backgroundTintColor: Color { get }      // Background tint
    var borderColor: Color { get }              // Border color
}
```

## Integration Guide

### Basic Integration

#### Step 1: Environment Setup

Choose one of these approaches:

**Option A: Manual Setup (Recommended for complex apps)**

```swift
@main
struct MyApp: App {
    @State private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(toastManager)
                .toast()
        }
    }
}
```

**Option B: Automatic Setup (Recommended for simple apps)**

```swift
struct ContentView: View {
    var body: some View {
        MainAppView()
            .toastEnvironment()
    }
}
```

#### Step 2: Using Toasts in Views

```swift
struct FeatureView: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        VStack {
            Button("Save File") {
                saveFile { success in
                    if success {
                        toastManager.show("文件保存成功", type: .success)
                    } else {
                        toastManager.show("保存失败，请重试", type: .error)
                    }
                }
            }
        }
    }

    private func saveFile(completion: @escaping (Bool) -> Void) {
        // Your save logic here
        completion(true)
    }
}
```

### Advanced Integration Patterns

#### Custom Toast Manager

For apps with specific requirements, you can subclass or extend ToastManager:

```swift
class CustomToastManager: ToastManager {
    func showNetworkError() {
        show("网络连接失败，请检查网络设置", type: .error, duration: 5.0)
    }

    func showSaveSuccess(filename: String) {
        show("文件 \(filename) 保存成功", type: .success)
    }
}
```

#### Multiple Window Support

For apps with multiple windows:

```swift
struct WindowView: View {
    var body: some View {
        ContentView()
            .globalToast() // Provides cross-window toast support
    }
}
```

#### Integration with Existing Alert Systems

Replace existing alert dialogs with toasts for better UX:

```swift
// Before: Using alert
@State private var showingAlert = false
@State private var alertMessage = ""

// After: Using toast
@Environment(ToastManager.self) private var toastManager

// Replace alert calls
// showingAlert = true
// alertMessage = "操作完成"
toastManager.show("操作完成", type: .success)
```

### Integration with Async Operations

```swift
struct AsyncOperationView: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var isLoading = false

    var body: some View {
        Button("Process Data") {
            processDataAsync()
        }
        .disabled(isLoading)
    }

    private func processDataAsync() {
        isLoading = true
        toastManager.show("处理中...", type: .info, duration: 0) // Manual dismiss

        Task {
            do {
                try await performLongRunningTask()
                await MainActor.run {
                    toastManager.dismissAll() // Clear "processing" toast
                    toastManager.show("处理完成", type: .success)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    toastManager.dismissAll()
                    toastManager.show("处理失败: \(error.localizedDescription)", type: .error)
                    isLoading = false
                }
            }
        }
    }

    private func performLongRunningTask() async throws {
        // Simulate async work
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
```

## Toast Types and Styling

### Visual Design

All toast types follow macOS design guidelines with adaptive colors for light/dark mode:

#### Success Toast (`.success`)

- **Color**: System Green
- **Icon**: `checkmark.circle.fill`
- **Use Cases**: Successful operations, confirmations, completions
- **Example**: "文件保存成功", "复制到剪贴板", "设置已更新"

#### Error Toast (`.error`)

- **Color**: System Red
- **Icon**: `exclamationmark.circle.fill`
- **Use Cases**: Errors, failures, critical issues
- **Accessibility**: High priority, plays system sound
- **Example**: "网络连接失败", "文件格式不支持", "权限不足"

#### Warning Toast (`.warning`)

- **Color**: System Orange
- **Icon**: `exclamationmark.triangle.fill`
- **Use Cases**: Warnings, cautions, non-critical issues
- **Example**: "文件可能损坏", "存储空间不足", "建议重启应用"

#### Info Toast (`.info`)

- **Color**: System Blue
- **Icon**: `info.circle.fill`
- **Use Cases**: Information, tips, status updates
- **Example**: "新版本可用", "正在同步数据", "快捷键提示"

### Customization Examples

```swift
// Different durations for different importance levels
toastManager.show("重要错误信息", type: .error, duration: 8.0)
toastManager.show("一般提示信息", type: .info, duration: 2.0)

// Manual dismiss for critical information
toastManager.show("请确认操作", type: .warning, duration: 0)

// Batch notifications for validation
let errors = validateForm()
if !errors.isEmpty {
    toastManager.showBatch(errors, type: .error, duration: 5.0)
}
```

### Visual Behavior

- **Positioning**: Top-center of the window, respecting safe areas
- **Animation**: Smooth slide-in from top with spring animation
- **Stacking**: Multiple toasts stack vertically with proper spacing
- **Hover Effects**: Pause auto-dismiss on hover, subtle scale effect
- **Dismissal**: Fade out with scale animation, swipe up to dismiss

## Accessibility Features

The Toast system provides comprehensive accessibility support following macOS guidelines:

### VoiceOver Support

#### Automatic Announcements

```swift
// Toasts are automatically announced with appropriate priority
toastManager.show("文件保存成功", type: .success) // Medium priority
toastManager.show("发生错误", type: .error)       // High priority, with sound
```

#### Priority Levels

- **Error**: High priority with system sound
- **Warning**: Medium priority with system sound
- **Success**: Medium priority, no sound
- **Info**: Low priority, no sound

#### Accessibility Actions

Each toast provides multiple accessibility actions:

```swift
// Available VoiceOver actions:
// - "关闭通知" - Dismiss the toast
// - "暂停自动关闭" - Pause auto-dismiss timer
// - "恢复自动关闭" - Resume auto-dismiss timer
// - "重复消息" - Re-announce the message
```

### Keyboard Navigation

```swift
// Keyboard shortcuts available when toast is focused:
// - Escape: Dismiss toast
// - Space/Return: Dismiss toast
// - Tab: Navigate between toasts
// - Arrow keys: Navigate between toasts
```

### Accessibility Labels and Descriptions

```swift
// Toasts provide rich accessibility information:
let manager = ToastManager()

// Get current accessibility state
print(manager.accessibilityDescription)
// Output: "1个通知: 成功 - 文件保存成功，将在 3 秒后自动关闭"

print(manager.detailedAccessibilityDescription)
// Output: "第 1 个成功通知：文件保存成功，自动关闭"
```

### Accessibility Best Practices

#### 1. Use Appropriate Toast Types

```swift
// Good: Use error type for actual errors
toastManager.show("无法连接到服务器", type: .error)

// Bad: Using success type for errors
// toastManager.show("连接失败", type: .success) // Don't do this
```

#### 2. Provide Clear, Descriptive Messages

```swift
// Good: Specific and actionable
toastManager.show("JSON 格式验证失败，请检查第 15 行语法", type: .error)

// Bad: Vague and unhelpful
// toastManager.show("出错了", type: .error)
```

#### 3. Use Appropriate Durations

```swift
// Critical errors: Longer duration or manual dismiss
toastManager.show("数据可能丢失，请立即保存", type: .error, duration: 10.0)

// Success confirmations: Standard duration
toastManager.show("保存成功", type: .success) // 3.0 seconds default

// Status updates: Shorter duration
toastManager.show("正在处理...", type: .info, duration: 1.5)
```

### Testing Accessibility

```swift
// Test accessibility announcements
func testAccessibilityAnnouncement() {
    let manager = ToastManager()
    manager.show("测试消息", type: .success)

    // Verify accessibility description
    XCTAssertTrue(manager.accessibilityDescription.contains("成功"))
    XCTAssertTrue(manager.accessibilityDescription.contains("测试消息"))
}
```

## Advanced Usage

### Queue Management

The toast system automatically manages a queue for multiple simultaneous toasts:

```swift
// Maximum 5 toasts displayed simultaneously
// Additional toasts are queued and shown as space becomes available

// Check queue status
let status = toastManager.queueStatus
print("显示中: \(status.displayedCount), 队列中: \(status.queuedCount)")

// Clear queue without affecting displayed toasts
toastManager.clearQueue()
```

### Timer Management

Advanced timer control for interactive applications:

```swift
struct InteractiveToastExample: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var currentToast: ToastMessage?

    var body: some View {
        VStack {
            Button("Show Pausable Toast") {
                let toast = ToastMessage(
                    message: "可暂停的通知",
                    type: .info,
                    duration: 10.0
                )
                currentToast = toast
                toastManager.show(toast.message, type: toast.type, duration: toast.duration)
            }

            if let toast = currentToast {
                HStack {
                    Button("暂停") {
                        toastManager.pauseAutoDismiss(for: toast)
                    }
                    .disabled(toastManager.isTimerPaused(for: toast))

                    Button("恢复") {
                        toastManager.resumeAutoDismiss(for: toast)
                    }
                    .disabled(!toastManager.isTimerPaused(for: toast))

                    if let remaining = toastManager.getRemainingTime(for: toast) {
                        Text("剩余: \(Int(remaining))秒")
                            .font(.caption)
                    }
                }
            }
        }
    }
}
```

### Custom Integration Wrapper

For complex view hierarchies or third-party components:

```swift
struct CustomFeatureWrapper<Content: View>: View {
    let content: Content
    @State private var toastManager = ToastManager()

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ToastIntegrationWrapper(toastManager: toastManager) {
            content
                .onReceive(NotificationCenter.default.publisher(for: .customFeatureSuccess)) { _ in
                    toastManager.show("功能操作成功", type: .success)
                }
                .onReceive(NotificationCenter.default.publisher(for: .customFeatureError)) { notification in
                    if let error = notification.object as? Error {
                        toastManager.show("操作失败: \(error.localizedDescription)", type: .error)
                    }
                }
        }
    }
}

// Usage
CustomFeatureWrapper {
    ThirdPartyComponent()
}
```

### Performance Optimization

For high-frequency toast scenarios:

```swift
class OptimizedToastManager: ToastManager {
    private var lastToastTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.5

    override func show(
        _ message: String,
        type: ToastType,
        duration: TimeInterval = 3.0,
        announceImmediately: Bool = true
    ) {
        let now = Date()

        // Throttle rapid successive toasts
        guard now.timeIntervalSince(lastToastTime) >= minimumInterval else {
            return
        }

        lastToastTime = now
        super.show(message, type: type, duration: duration, announceImmediately: announceImmediately)
    }
}
```

## Best Practices

### 1. Message Content

#### ✅ Good Messages

```swift
// Specific and actionable
toastManager.show("文件 'document.pdf' 保存到桌面", type: .success)
toastManager.show("无法连接到服务器，请检查网络连接", type: .error)
toastManager.show("磁盘空间不足，建议清理临时文件", type: .warning)

// Localized and user-friendly
toastManager.show("复制到剪贴板", type: .success)
toastManager.show("格式转换完成", type: .success)
```

#### ❌ Avoid These Messages

```swift
// Too vague
// toastManager.show("错误", type: .error)
// toastManager.show("完成", type: .success)

// Too technical
// toastManager.show("HTTP 500 Internal Server Error", type: .error)
// toastManager.show("malloc() failed at line 247", type: .error)

// Too long
// toastManager.show("操作已完成，但是在处理过程中遇到了一些小问题，不过这些问题不会影响最终结果，您可以继续使用应用程序的其他功能", type: .success)
```

### 2. Toast Type Selection

```swift
// Use appropriate types for context
class ToastBestPractices {
    let toastManager: ToastManager

    init(toastManager: ToastManager) {
        self.toastManager = toastManager
    }

    // File operations
    func fileOperationSuccess(filename: String) {
        toastManager.show("文件 '\(filename)' 处理完成", type: .success)
    }

    func fileOperationError(_ error: Error) {
        toastManager.show("文件操作失败: \(error.localizedDescription)", type: .error)
    }

    // Network operations
    func networkWarning() {
        toastManager.show("网络连接不稳定，正在重试", type: .warning)
    }

    // User guidance
    func showTip() {
        toastManager.show("提示：使用 ⌘+V 快速粘贴", type: .info, duration: 5.0)
    }

    // Validation errors
    func showValidationErrors(_ errors: [String]) {
        toastManager.showBatch(errors, type: .error, duration: 6.0)
    }
}
```

### 3. Duration Guidelines

```swift
// Duration recommendations by content type
enum ToastDuration {
    static let quick: TimeInterval = 2.0        // Simple confirmations
    static let standard: TimeInterval = 3.0     // Default for most cases
    static let important: TimeInterval = 5.0    // Warnings, errors
    static let critical: TimeInterval = 8.0     // Critical errors
    static let manual: TimeInterval = 0         // Requires user action
}

// Examples
toastManager.show("复制成功", type: .success, duration: ToastDuration.quick)
toastManager.show("网络错误，请重试", type: .error, duration: ToastDuration.important)
toastManager.show("确认删除所有数据？", type: .warning, duration: ToastDuration.manual)
```

### 4. Integration Patterns

#### Service Layer Integration

```swift
class DataService {
    private let toastManager: ToastManager

    init(toastManager: ToastManager) {
        self.toastManager = toastManager
    }

    func saveData(_ data: Data) async throws {
        do {
            try await performSave(data)
            toastManager.show("数据保存成功", type: .success)
        } catch {
            toastManager.show("保存失败: \(error.localizedDescription)", type: .error)
            throw error
        }
    }

    private func performSave(_ data: Data) async throws {
        // Implementation
    }
}
```

#### View Model Integration

```swift
@Observable
class FeatureViewModel {
    private let toastManager: ToastManager
    var isLoading = false

    init(toastManager: ToastManager) {
        self.toastManager = toastManager
    }

    func performAction() {
        isLoading = true

        Task {
            do {
                try await someAsyncOperation()
                await MainActor.run {
                    isLoading = false
                    toastManager.show("操作完成", type: .success)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    toastManager.show("操作失败", type: .error)
                }
            }
        }
    }

    private func someAsyncOperation() async throws {
        // Implementation
    }
}
```

### 5. Testing Best Practices

```swift
class ToastManagerTests: XCTestCase {
    var toastManager: ToastManager!

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    func testBasicToastDisplay() {
        // Test basic functionality
        toastManager.show("Test message", type: .success)

        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.message, "Test message")
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
    }

    func testQueueManagement() {
        // Test queue behavior
        for i in 1...10 {
            toastManager.show("Message \(i)", type: .info)
        }

        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount, 5) // Max simultaneous
        XCTAssertEqual(status.queuedCount, 5)    // Remaining in queue
    }

    func testAccessibilityDescription() {
        toastManager.show("Test message", type: .success)

        let description = toastManager.accessibilityDescription
        XCTAssertTrue(description.contains("成功"))
        XCTAssertTrue(description.contains("Test message"))
    }
}
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Toasts Not Appearing

**Problem**: Toasts are not visible when calling `toastManager.show()`

**Solutions**:

```swift
// Check 1: Ensure ToastManager is in environment
struct ContentView: View {
    @State private var toastManager = ToastManager() // ✅ Create manager

    var body: some View {
        MainView()
            .environment(toastManager) // ✅ Add to environment
            .toast() // ✅ Add toast overlay
    }
}

// Check 2: Verify toast() modifier is applied
struct MyView: View {
    var body: some View {
        VStack {
            // Content
        }
        .toast() // ✅ Required for toast display
    }
}

// Check 3: Ensure you're on the main thread
func showToastFromBackground() {
    Task {
        // Background work...

        await MainActor.run {
            toastManager.show("完成", type: .success) // ✅ Main thread
        }
    }
}
```

#### 2. Environment Not Found Error

**Problem**: `Fatal error: No ToastManager found in environment`

**Solution**:

```swift
// Ensure ToastManager is provided before using
@main
struct App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .toastEnvironment() // ✅ Provides both environment and overlay
        }
    }
}

// Or manual setup:
struct RootView: View {
    @State private var toastManager = ToastManager()

    var body: some View {
        ContentView()
            .environment(toastManager) // ✅ Provide environment
            .toast() // ✅ Add overlay
    }
}
```

#### 3. Toasts Appearing Behind Other Views

**Problem**: Toasts are not visible due to z-index issues

**Solution**:

```swift
// Apply toast modifier at the highest level possible
struct WindowView: View {
    var body: some View {
        ZStack {
            MainContent()

            // Other overlays...
        }
        .toast() // ✅ Apply at top level for proper z-index
    }
}

// For complex layouts, use explicit z-index
struct ComplexView: View {
    var body: some View {
        ZStack {
            MainContent()
                .zIndex(0)

            SomeOverlay()
                .zIndex(100)
        }
        .toast() // ✅ Toast overlay will be at z-index 1000
    }
}
```

#### 4. Performance Issues with Many Toasts

**Problem**: App becomes slow when showing many toasts rapidly

**Solutions**:

```swift
// Solution 1: Use batch operations
let messages = ["错误1", "错误2", "错误3"]
toastManager.showBatch(messages, type: .error) // ✅ More efficient

// Solution 2: Throttle toast calls
class ThrottledToastManager {
    private let toastManager: ToastManager
    private var lastToastTime: Date = .distantPast
    private let minimumInterval: TimeInterval = 0.5

    init(toastManager: ToastManager) {
        self.toastManager = toastManager
    }

    func showThrottled(_ message: String, type: ToastType) {
        let now = Date()
        guard now.timeIntervalSince(lastToastTime) >= minimumInterval else {
            return
        }

        lastToastTime = now
        toastManager.show(message, type: type)
    }
}

// Solution 3: Clear queue when appropriate
func handleManyErrors(_ errors: [Error]) {
    toastManager.clearQueue() // Clear pending toasts
    toastManager.dismissAll() // Clear current toasts

    // Show summary instead of individual errors
    toastManager.show("发现 \(errors.count) 个错误", type: .error)
}
```

#### 5. Accessibility Issues

**Problem**: VoiceOver not announcing toasts properly

**Solutions**:

```swift
// Ensure proper announcement timing
func showImportantToast() {
    // Give VoiceOver time to process
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        toastManager.show("重要通知", type: .error, announceImmediately: true)
    }
}

// Check accessibility settings
func checkAccessibilitySupport() {
    if NSWorkspace.shared.isVoiceOverEnabled {
        // Adjust toast duration for VoiceOver users
        toastManager.show("消息", type: .info, duration: 5.0) // Longer duration
    } else {
        toastManager.show("消息", type: .info) // Standard duration
    }
}
```

#### 6. Memory Leaks

**Problem**: ToastManager not being deallocated

**Solutions**:

```swift
// Ensure proper cleanup in views
struct MyView: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        // Content
        .onDisappear {
            // Clean up if needed (usually automatic)
            toastManager.dismissAll()
        }
    }
}

// For custom managers, ensure proper deinit
class CustomToastManager: ToastManager {
    deinit {
        // Cleanup is handled by parent class
        print("CustomToastManager deallocated")
    }
}
```

### Debug Helpers

```swift
extension ToastManager {
    /// Debug helper to print current toast state
    func debugPrintState() {
        print("=== Toast Manager State ===")
        print("Active toasts: \(toasts.count)")
        print("Queue status: \(queueStatus)")
        print("Accessibility: \(accessibilityDescription)")

        for (index, toast) in toasts.enumerated() {
            print("Toast \(index + 1): \(toast.type) - \(toast.message)")
            if let remaining = getRemainingTime(for: toast) {
                print("  Remaining: \(remaining)s")
            }
            print("  Paused: \(isTimerPaused(for: toast))")
        }
        print("========================")
    }
}

// Usage in development
#if DEBUG
toastManager.debugPrintState()
#endif
```

### Performance Monitoring

```swift
class ToastPerformanceMonitor {
    private var toastCount = 0
    private var startTime = Date()

    func monitorToastManager(_ manager: ToastManager) {
        // Monitor toast creation rate
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let currentCount = manager.toasts.count
            if currentCount != self.toastCount {
                let rate = Double(currentCount - self.toastCount)
                print("Toast rate: \(rate) toasts/second")
                self.toastCount = currentCount
            }
        }
    }
}
```

---

## Summary

The Toast notification system provides a comprehensive, accessible, and performant solution for user feedback in macOS applications. By following this documentation and the provided best practices, you can create a consistent and user-friendly notification experience across your entire application.

For additional support or feature requests, refer to the test files in `Tools/ToolsTests/Toast*Tests.swift` for comprehensive usage examples and edge cases.
