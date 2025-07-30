# Toast Notification System - Code Examples

This document provides comprehensive code examples for integrating and using the Toast notification system in various scenarios.

## Table of Contents

- [Basic Usage Examples](#basic-usage-examples)
- [Feature Integration Examples](#feature-integration-examples)
- [Advanced Patterns](#advanced-patterns)
- [Error Handling Examples](#error-handling-examples)
- [Accessibility Examples](#accessibility-examples)
- [Testing Examples](#testing-examples)

## Basic Usage Examples

### Simple Toast Display

```swift
import SwiftUI

struct BasicToastExample: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        VStack(spacing: 20) {
            // Success toast
            Button("Show Success") {
                toastManager.show("操作成功完成！", type: .success)
            }
            .buttonStyle(.borderedProminent)

            // Error toast
            Button("Show Error") {
                toastManager.show("发生错误，请重试", type: .error)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            // Warning toast
            Button("Show Warning") {
                toastManager.show("请注意：磁盘空间不足", type: .warning)
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            // Info toast
            Button("Show Info") {
                toastManager.show("新版本可用", type: .info)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding()
    }
}
```

### Custom Duration Examples

```swift
struct DurationExamples: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        VStack(spacing: 16) {
            // Quick confirmation (2 seconds)
            Button("Quick Success") {
                toastManager.show("已复制", type: .success, duration: 2.0)
            }

            // Standard duration (3 seconds - default)
            Button("Standard Info") {
                toastManager.show("处理完成", type: .info)
            }

            // Important message (5 seconds)
            Button("Important Warning") {
                toastManager.show("请保存您的工作", type: .warning, duration: 5.0)
            }

            // Critical error (8 seconds)
            Button("Critical Error") {
                toastManager.show("数据库连接失败，请联系管理员", type: .error, duration: 8.0)
            }

            // Manual dismiss only
            Button("Manual Dismiss") {
                toastManager.show("请确认操作", type: .warning, duration: 0)
            }

            // Dismiss all button
            Button("Dismiss All") {
                toastManager.dismissAll()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

## Feature Integration Examples

### File Operations Integration

```swift
import SwiftUI
import UniformTypeIdentifiers

struct FileOperationExample: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Save File") {
                saveFile()
            }
            .disabled(isProcessing)

            Button("Load File") {
                loadFile()
            }
            .disabled(isProcessing)

            Button("Export Data") {
                exportData()
            }
            .disabled(isProcessing)
        }
        .padding()
    }

    private func saveFile() {
        isProcessing = true

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "document.txt"

        savePanel.begin { response in
            defer { isProcessing = false }

            if response == .OK, let url = savePanel.url {
                do {
                    try "Sample content".write(to: url, atomically: true, encoding: .utf8)
                    toastManager.show("文件保存到 \(url.lastPathComponent)", type: .success)
                } catch {
                    toastManager.show("保存失败: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }

    private func loadFile() {
        isProcessing = true

        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.plainText]
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            defer { isProcessing = false }

            if response == .OK, let url = openPanel.url {
                do {
                    let content = try String(contentsOf: url)
                    toastManager.show("文件 \(url.lastPathComponent) 加载成功", type: .success)
                    // Process content...
                } catch {
                    toastManager.show("加载失败: \(error.localizedDescription)", type: .error)
                }
            }
        }
    }

    private func exportData() {
        isProcessing = true
        toastManager.show("正在导出数据...", type: .info, duration: 0)

        // Simulate async export
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            DispatchQueue.main.async {
                isProcessing = false
                toastManager.dismissAll() // Clear "exporting" toast
                toastManager.show("数据导出完成", type: .success)
            }
        }
    }
}
```

### Network Operations Integration

```swift
import SwiftUI
import Foundation

struct NetworkOperationExample: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var isLoading = false
    @State private var data: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Network Operation Example")
                .font(.title2)

            Button("Fetch Data") {
                fetchData()
            }
            .disabled(isLoading)

            Button("Upload Data") {
                uploadData()
            }
            .disabled(isLoading)

            if !data.isEmpty {
                Text("Data: \(data)")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }

    private func fetchData() {
        isLoading = true
        toastManager.show("正在获取数据...", type: .info, duration: 0)

        Task {
            do {
                // Simulate network request
                try await Task.sleep(nanoseconds: 2_000_000_000)

                // Simulate random success/failure
                if Bool.random() {
                    let fetchedData = "Sample data from server"
                    await MainActor.run {
                        self.data = fetchedData
                        toastManager.dismissAll()
                        toastManager.show("数据获取成功", type: .success)
                        isLoading = false
                    }
                } else {
                    throw NetworkError.serverError
                }
            } catch {
                await MainActor.run {
                    toastManager.dismissAll()
                    toastManager.show("网络请求失败: \(error.localizedDescription)", type: .error, duration: 5.0)
                    isLoading = false
                }
            }
        }
    }

    private func uploadData() {
        guard !data.isEmpty else {
            toastManager.show("没有数据可上传", type: .warning)
            return
        }

        isLoading = true
        toastManager.show("正在上传数据...", type: .info, duration: 0)

        Task {
            do {
                // Simulate upload with progress
                for i in 1...3 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    await MainActor.run {
                        toastManager.dismissAll()
                        toastManager.show("上传进度: \(i * 33)%", type: .info, duration: 0)
                    }
                }

                await MainActor.run {
                    toastManager.dismissAll()
                    toastManager.show("数据上传完成", type: .success)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    toastManager.dismissAll()
                    toastManager.show("上传失败: \(error.localizedDescription)", type: .error)
                    isLoading = false
                }
            }
        }
    }
}

enum NetworkError: LocalizedError {
    case serverError
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .serverError:
            return "服务器错误"
        case .connectionFailed:
            return "连接失败"
        }
    }
}
```

### Form Validation Integration

```swift
import SwiftUI

struct FormValidationExample: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("User Registration")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                TextField("用户名", text: $username)
                    .textFieldStyle(.roundedBorder)

                TextField("邮箱", text: $email)
                    .textFieldStyle(.roundedBorder)

                SecureField("密码", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("确认密码", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
            }

            Button("注册") {
                validateAndSubmit()
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.isEmpty || email.isEmpty || password.isEmpty)
        }
        .padding()
        .frame(width: 300)
    }

    private func validateAndSubmit() {
        let validationErrors = validateForm()

        if !validationErrors.isEmpty {
            // Show all validation errors as batch
            toastManager.showBatch(validationErrors, type: .error, duration: 5.0)
            return
        }

        // If validation passes, simulate registration
        toastManager.show("正在注册...", type: .info, duration: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            toastManager.dismissAll()
            toastManager.show("注册成功！", type: .success)
            clearForm()
        }
    }

    private func validateForm() -> [String] {
        var errors: [String] = []

        // Username validation
        if username.count < 3 {
            errors.append("用户名至少需要3个字符")
        }

        if username.count > 20 {
            errors.append("用户名不能超过20个字符")
        }

        // Email validation
        if !isValidEmail(email) {
            errors.append("请输入有效的邮箱地址")
        }

        // Password validation
        if password.count < 8 {
            errors.append("密码至少需要8个字符")
        }

        if !password.contains(where: { $0.isNumber }) {
            errors.append("密码必须包含至少一个数字")
        }

        if !password.contains(where: { $0.isUppercase }) {
            errors.append("密码必须包含至少一个大写字母")
        }

        // Confirm password validation
        if password != confirmPassword {
            errors.append("两次输入的密码不一致")
        }

        return errors
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func clearForm() {
        username = ""
        email = ""
        password = ""
        confirmPassword = ""
    }
}
```

## Advanced Patterns

### Service Layer Integration

```swift
import Foundation

// MARK: - Service Protocol
protocol DataServiceProtocol {
    func saveData(_ data: Data) async throws
    func loadData() async throws -> Data
    func deleteData() async throws
}

// MARK: - Service Implementation with Toast Integration
class DataService: DataServiceProtocol {
    private let toastManager: ToastManager
    private let storage: DataStorage

    init(toastManager: ToastManager, storage: DataStorage = FileDataStorage()) {
        self.toastManager = toastManager
        self.storage = storage
    }

    func saveData(_ data: Data) async throws {
        do {
            try await storage.save(data)
            await MainActor.run {
                toastManager.show("数据保存成功", type: .success)
            }
        } catch {
            await MainActor.run {
                toastManager.show("保存失败: \(error.localizedDescription)", type: .error)
            }
            throw error
        }
    }

    func loadData() async throws -> Data {
        do {
            let data = try await storage.load()
            await MainActor.run {
                toastManager.show("数据加载完成", type: .success, duration: 2.0)
            }
            return data
        } catch {
            await MainActor.run {
                toastManager.show("加载失败: \(error.localizedDescription)", type: .error)
            }
            throw error
        }
    }

    func deleteData() async throws {
        // Show confirmation toast first
        await MainActor.run {
            toastManager.show("确认删除数据？", type: .warning, duration: 0)
        }

        // Wait for user confirmation (in real app, this would be handled differently)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        do {
            try await storage.delete()
            await MainActor.run {
                toastManager.dismissAll() // Clear confirmation toast
                toastManager.show("数据已删除", type: .success)
            }
        } catch {
            await MainActor.run {
                toastManager.dismissAll()
                toastManager.show("删除失败: \(error.localizedDescription)", type: .error)
            }
            throw error
        }
    }
}

// MARK: - Storage Protocol and Implementation
protocol DataStorage {
    func save(_ data: Data) async throws
    func load() async throws -> Data
    func delete() async throws
}

class FileDataStorage: DataStorage {
    private let fileURL: URL

    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documentsPath.appendingPathComponent("app_data.json")
    }

    func save(_ data: Data) async throws {
        try data.write(to: fileURL)
    }

    func load() async throws -> Data {
        return try Data(contentsOf: fileURL)
    }

    func delete() async throws {
        try FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - View Model Integration
@Observable
class DataViewModel {
    private let dataService: DataServiceProtocol
    var isLoading = false
    var currentData: String = ""

    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    func saveCurrentData() {
        guard !currentData.isEmpty else { return }

        isLoading = true
        Task {
            do {
                let data = currentData.data(using: .utf8) ?? Data()
                try await dataService.saveData(data)
            } catch {
                // Error handling is done in service layer
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    func loadData() {
        isLoading = true
        Task {
            do {
                let data = try await dataService.loadData()
                let string = String(data: data, encoding: .utf8) ?? ""

                await MainActor.run {
                    currentData = string
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
```

### Custom Toast Manager

```swift
import SwiftUI

// MARK: - Extended Toast Manager with App-Specific Features
class AppToastManager: ToastManager {

    // MARK: - App-Specific Toast Methods

    func showFileOperationSuccess(filename: String, operation: FileOperation) {
        let message: String
        switch operation {
        case .save:
            message = "文件 '\(filename)' 保存成功"
        case .load:
            message = "文件 '\(filename)' 加载完成"
        case .delete:
            message = "文件 '\(filename)' 已删除"
        case .export:
            message = "文件 '\(filename)' 导出完成"
        }

        show(message, type: .success, duration: 3.0)
    }

    func showNetworkError(_ error: NetworkError, retryAction: (() -> Void)? = nil) {
        let message: String
        let duration: TimeInterval

        switch error {
        case .connectionTimeout:
            message = "连接超时，请检查网络连接"
            duration = 5.0
        case .serverError(let code):
            message = "服务器错误 (\(code))，请稍后重试"
            duration = 6.0
        case .noInternet:
            message = "无网络连接，请检查网络设置"
            duration = 8.0
        case .invalidResponse:
            message = "服务器响应无效"
            duration = 4.0
        }

        show(message, type: .error, duration: duration)

        // Auto-retry for certain errors
        if case .connectionTimeout = error, let retry = retryAction {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                retry()
            }
        }
    }

    func showValidationErrors(_ errors: [ValidationError]) {
        let messages = errors.map { error in
            switch error {
            case .required(let field):
                return "\(field) 为必填项"
            case .invalidFormat(let field):
                return "\(field) 格式不正确"
            case .tooShort(let field, let minLength):
                return "\(field) 至少需要 \(minLength) 个字符"
            case .tooLong(let field, let maxLength):
                return "\(field) 不能超过 \(maxLength) 个字符"
            }
        }

        showBatch(messages, type: .error, duration: 6.0)
    }

    func showProgressUpdate(_ progress: Progress) {
        let percentage = Int(progress.fractionCompleted * 100)
        let message = "\(progress.localizedDescription) (\(percentage)%)"

        // Dismiss previous progress toasts
        dismissAll()
        show(message, type: .info, duration: 0)
    }

    func showTip(_ tip: AppTip) {
        let message: String
        let duration: TimeInterval

        switch tip {
        case .keyboardShortcut(let shortcut, let action):
            message = "提示：使用 \(shortcut) \(action)"
            duration = 5.0
        case .featureHighlight(let feature):
            message = "新功能：\(feature)"
            duration = 6.0
        case .performanceTip(let tip):
            message = "性能提示：\(tip)"
            duration = 4.0
        }

        show(message, type: .info, duration: duration)
    }
}

// MARK: - Supporting Types

enum FileOperation {
    case save, load, delete, export
}

enum NetworkError: LocalizedError {
    case connectionTimeout
    case serverError(Int)
    case noInternet
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .connectionTimeout:
            return "Connection timeout"
        case .serverError(let code):
            return "Server error \(code)"
        case .noInternet:
            return "No internet connection"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}

enum ValidationError {
    case required(String)
    case invalidFormat(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
}

enum AppTip {
    case keyboardShortcut(String, String)
    case featureHighlight(String)
    case performanceTip(String)
}
```

## Error Handling Examples

### Comprehensive Error Handling

```swift
import SwiftUI

struct ErrorHandlingExample: View {
    @Environment(ToastManager.self) private var toastManager
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 20) {
            Button("Simulate Various Errors") {
                simulateRandomError()
            }
            .disabled(isProcessing)

            Button("Test Error Recovery") {
                testErrorRecovery()
            }
            .disabled(isProcessing)

            Button("Batch Error Handling") {
                testBatchErrors()
            }
            .disabled(isProcessing)
        }
        .padding()
    }

    private func simulateRandomError() {
        isProcessing = true

        let errors: [AppError] = [
            .networkError(.connectionTimeout),
            .fileError(.notFound("document.txt")),
            .validationError(.invalidEmail),
            .systemError(.insufficientMemory),
            .userError(.cancelled)
        ]

        let randomError = errors.randomElement()!

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            handleError(randomError)
            isProcessing = false
        }
    }

    private func testErrorRecovery() {
        isProcessing = true

        // Simulate operation that might fail and recover
        attemptOperationWithRetry(maxRetries: 3) { attempt in
            // Simulate failure on first two attempts
            if attempt < 3 {
                throw AppError.networkError(.connectionTimeout)
            }
            return "操作成功"
        }
    }

    private func testBatchErrors() {
        let errors = [
            "用户名不能为空",
            "密码长度不足",
            "邮箱格式错误",
            "手机号码无效"
        ]

        toastManager.showBatch(errors, type: .error, duration: 6.0)
    }

    private func handleError(_ error: AppError) {
        switch error {
        case .networkError(let networkError):
            handleNetworkError(networkError)
        case .fileError(let fileError):
            handleFileError(fileError)
        case .validationError(let validationError):
            handleValidationError(validationError)
        case .systemError(let systemError):
            handleSystemError(systemError)
        case .userError(let userError):
            handleUserError(userError)
        }
    }

    private func handleNetworkError(_ error: NetworkError) {
        switch error {
        case .connectionTimeout:
            toastManager.show("连接超时，正在重试...", type: .warning, duration: 3.0)
            // Auto-retry logic here
        case .serverError(let code):
            toastManager.show("服务器错误 (\(code))，请稍后重试", type: .error, duration: 5.0)
        case .noInternet:
            toastManager.show("无网络连接，请检查网络设置", type: .error, duration: 8.0)
        case .invalidResponse:
            toastManager.show("数据格式错误，请联系技术支持", type: .error, duration: 6.0)
        }
    }

    private func handleFileError(_ error: FileError) {
        switch error {
        case .notFound(let filename):
            toastManager.show("文件 '\(filename)' 不存在", type: .error)
        case .permissionDenied:
            toastManager.show("没有文件访问权限", type: .error, duration: 5.0)
        case .diskFull:
            toastManager.show("磁盘空间不足，请清理后重试", type: .warning, duration: 8.0)
        case .corruptedFile:
            toastManager.show("文件已损坏，无法打开", type: .error, duration: 5.0)
        }
    }

    private func handleValidationError(_ error: ValidationError) {
        switch error {
        case .required(let field):
            toastManager.show("\(field) 为必填项", type: .warning)
        case .invalidFormat(let field):
            toastManager.show("\(field) 格式不正确", type: .warning)
        case .tooShort(let field, let minLength):
            toastManager.show("\(field) 至少需要 \(minLength) 个字符", type: .warning)
        case .tooLong(let field, let maxLength):
            toastManager.show("\(field) 不能超过 \(maxLength) 个字符", type: .warning)
        }
    }

    private func handleSystemError(_ error: SystemError) {
        switch error {
        case .insufficientMemory:
            toastManager.show("内存不足，请关闭其他应用", type: .error, duration: 8.0)
        case .diskError:
            toastManager.show("磁盘错误，请检查硬件", type: .error, duration: 10.0)
        case .permissionError:
            toastManager.show("权限不足，请以管理员身份运行", type: .error, duration: 6.0)
        }
    }

    private func handleUserError(_ error: UserError) {
        switch error {
        case .cancelled:
            toastManager.show("操作已取消", type: .info, duration: 2.0)
        case .invalidInput:
            toastManager.show("输入无效，请检查后重试", type: .warning)
        }
    }

    private func attemptOperationWithRetry<T>(
        maxRetries: Int,
        operation: @escaping (Int) throws -> T
    ) {
        func attempt(_ currentAttempt: Int) {
            do {
                let result = try operation(currentAttempt)
                toastManager.show("操作成功", type: .success)
                isProcessing = false
            } catch {
                if currentAttempt < maxRetries {
                    toastManager.show("重试中... (\(currentAttempt)/\(maxRetries))", type: .info, duration: 2.0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        attempt(currentAttempt + 1)
                    }
                } else {
                    toastManager.show("操作失败，已达到最大重试次数", type: .error, duration: 5.0)
                    isProcessing = false
                }
            }
        }

        attempt(1)
    }
}

// MARK: - Error Types

enum AppError: Error {
    case networkError(NetworkError)
    case fileError(FileError)
    case validationError(ValidationError)
    case systemError(SystemError)
    case userError(UserError)
}

enum FileError: Error {
    case notFound(String)
    case permissionDenied
    case diskFull
    case corruptedFile
}

enum SystemError: Error {
    case insufficientMemory
    case diskError
    case permissionError
}

enum UserError: Error {
    case cancelled
    case invalidInput
}
```

## Accessibility Examples

### VoiceOver Integration

```swift
import SwiftUI

struct AccessibilityExample: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Accessibility Toast Examples")
                .font(.title2)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                Button("High Priority Error") {
                    // High priority with sound
                    toastManager.show("严重错误：数据可能丢失", type: .error, duration: 10.0)
                }
                .accessibilityHint("显示高优先级错误通知")

                Button("Medium Priority Warning") {
                    toastManager.show("警告：磁盘空间不足", type: .warning, duration: 6.0)
                }
                .accessibilityHint("显示中等优先级警告通知")

                Button("Low Priority Info") {
                    toastManager.show("提示：新功能可用", type: .info, duration: 4.0)
                }
                .accessibilityHint("显示低优先级信息通知")

                Button("Success Confirmation") {
                    toastManager.show("操作完成", type: .success, duration: 3.0)
                }
                .accessibilityHint("显示成功确认通知")
            }

            Divider()

            VStack(spacing: 12) {
                Text("Toast Status")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text(toastManager.accessibilityDescription)
                    .accessibilityLabel("当前通知状态")
                    .accessibilityValue(toastManager.accessibilityDescription)

                Button("Get Detailed Status") {
                    let detailed = toastManager.detailedAccessibilityDescription
                    announceToAccessibility(detailed)
                }
                .accessibilityHint("获取详细的通知状态信息")

                Button("Dismiss All Toasts") {
                    toastManager.dismissAll()
                    announceToAccessibility("所有通知已清除")
                }
                .accessibilityHint("清除所有当前显示的通知")
            }
        }
        .padding()
    }

    private func announceToAccessibility(_ message: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.medium.rawValue
            ]

            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: userInfo
            )
        }
    }
}

// MARK: - Accessibility-Aware Toast Manager Extension

extension ToastManager {
    /// Show toast with accessibility considerations
    func showAccessible(
        _ message: String,
        type: ToastType,
        duration: TimeInterval = 3.0,
        priority: NSAccessibilityPriorityLevel = .medium
    ) {
        // Adjust duration for VoiceOver users
        let adjustedDuration: TimeInterval
        if NSWorkspace.shared.isVoiceOverEnabled {
            // Give VoiceOver users more time to hear the message
            adjustedDuration = max(duration, 5.0)
        } else {
            adjustedDuration = duration
        }

        show(message, type: type, duration: adjustedDuration, announceImmediately: true)
    }

    /// Show toast with custom accessibility announcement
    func showWithCustomAnnouncement(
        _ message: String,
        type: ToastType,
        accessibilityMessage: String? = nil,
        duration: TimeInterval = 3.0
    ) {
        show(message, type: type, duration: duration, announceImmediately: false)

        // Custom accessibility announcement
        let announcementMessage = accessibilityMessage ?? message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let priority: NSAccessibilityPriorityLevel
            switch type {
            case .error: priority = .high
            case .warning: priority = .medium
            case .success: priority = .medium
            case .info: priority = .low
            }

            let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
                .announcement: announcementMessage,
                .priority: priority.rawValue
            ]

            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: userInfo
            )
        }
    }
}
```

## Testing Examples

### Unit Tests

```swift
import XCTest
@testable import Tools

class ToastManagerTests: XCTestCase {
    var toastManager: ToastManager!

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    override func tearDown() {
        toastManager = nil
        super.tearDown()
    }

    func testBasicToastDisplay() {
        // Test basic toast creation
        toastManager.show("Test message", type: .success)

        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.message, "Test message")
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.duration, 3.0)
        XCTAssertTrue(toastManager.toasts.first?.isAutoDismiss ?? false)
    }

    func testToastDismissal() {
        // Test individual toast dismissal
        toastManager.show("Test message", type: .info)
        let toast = toastManager.toasts.first!

        toastManager.dismiss(toast)

        XCTAssertEqual(toastManager.toasts.count, 0)
    }

    func testDismissAll() {
        // Test dismissing all toasts
        toastManager.show("Message 1", type: .success)
        toastManager.show("Message 2", type: .error)
        toastManager.show("Message 3", type: .warning)

        XCTAssertEqual(toastManager.toasts.count, 3)

        toastManager.dismissAll()

        XCTAssertEqual(toastManager.toasts.count, 0)
    }

    func testQueueManagement() {
        // Test queue behavior with maximum toasts
        for i in 1...10 {
            toastManager.show("Message \(i)", type: .info)
        }

        let status = toastManager.queueStatus
        XCTAssertEqual(status.displayedCount, 5) // Max simultaneous toasts
        XCTAssertEqual(status.queuedCount, 5)    // Remaining in queue
        XCTAssertEqual(status.maxCapacity, 5)
    }

    func testBatchToasts() {
        let messages = ["Error 1", "Error 2", "Error 3"]
        toastManager.showBatch(messages, type: .error, duration: 5.0)

        // Should display first toast immediately, queue the rest
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.queueStatus.queuedCount, 2)
    }

    func testTimerManagement() {
        let toast = ToastMessage(message: "Test", type: .info, duration: 5.0)
        toastManager.show(toast.message, type: toast.type, duration: toast.duration)

        let actualToast = toastManager.toasts.first!

        // Test pause
        toastManager.pauseAutoDismiss(for: actualToast)
        XCTAssertTrue(toastManager.isTimerPaused(for: actualToast))

        // Test resume
        toastManager.resumeAutoDismiss(for: actualToast)
        XCTAssertFalse(toastManager.isTimerPaused(for: actualToast))
    }

    func testAccessibilityDescription() {
        // Test empty state
        XCTAssertEqual(toastManager.accessibilityDescription, "无通知")

        // Test single toast
        toastManager.show("Success message", type: .success)
        let description = toastManager.accessibilityDescription
        XCTAssertTrue(description.contains("1个通知"))
        XCTAssertTrue(description.contains("成功"))
        XCTAssertTrue(description.contains("Success message"))

        // Test multiple toasts
        toastManager.show("Error message", type: .error)
        let multiDescription = toastManager.accessibilityDescription
        XCTAssertTrue(multiDescription.contains("2个通知"))
    }

    func testToastTypes() {
        // Test all toast types
        let types: [ToastType] = [.success, .error, .warning, .info]

        for type in types {
            toastManager.dismissAll()
            toastManager.show("Test \(type)", type: type)

            let toast = toastManager.toasts.first!
            XCTAssertEqual(toast.type, type)

            // Verify type properties
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertNotNil(type.color)
            XCTAssertNotNil(type.backgroundTintColor)
            XCTAssertNotNil(type.borderColor)
        }
    }

    func testCustomDuration() {
        // Test manual dismiss (duration = 0)
        toastManager.show("Manual dismiss", type: .warning, duration: 0)
        let toast = toastManager.toasts.first!

        XCTAssertEqual(toast.duration, 0)
        XCTAssertFalse(toast.isAutoDismiss)

        // Test custom duration
        toastManager.dismissAll()
        toastManager.show("Custom duration", type: .info, duration: 10.0)
        let customToast = toastManager.toasts.first!

        XCTAssertEqual(customToast.duration, 10.0)
        XCTAssertTrue(customToast.isAutoDismiss)
    }
}

// MARK: - Integration Tests

class ToastIntegrationTests: XCTestCase {
    var toastManager: ToastManager!

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    func testRapidSuccessiveToasts() {
        // Test rapid toast creation doesn't crash
        let expectation = XCTestExpectation(description: "Rapid toasts handled")

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            toastManager.show("Message \(i)", type: .info)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Should handle rapid requests gracefully
            XCTAssertLessThanOrEqual(self.toastManager.toasts.count, 5)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testMemoryManagement() {
        // Test that dismissed toasts are properly cleaned up
        weak var weakToast: ToastMessage?

        autoreleasepool {
            toastManager.show("Memory test", type: .info)
            weakToast = toastManager.toasts.first
            toastManager.dismissAll()
        }

        // Toast should be deallocated after dismissal
        XCTAssertNil(weakToast)
    }

    func testQueueProcessing() {
        let expectation = XCTestExpectation(description: "Queue processed")

        // Fill queue beyond capacity
        for i in 1...8 {
            toastManager.show("Queued message \(i)", type: .info, duration: 1.0)
        }

        // Wait for auto-dismiss to process queue
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Queue should be processing
            let status = self.toastManager.queueStatus
            XCTAssertLessThan(status.queuedCount, 3) // Some should have been processed
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Mock Tests

class MockToastManagerTests: XCTestCase {

    func testMockToastManager() {
        let mockManager = MockToastManager()

        mockManager.show("Test message", type: .success)

        XCTAssertEqual(mockManager.showCallCount, 1)
        XCTAssertEqual(mockManager.lastMessage, "Test message")
        XCTAssertEqual(mockManager.lastType, .success)
    }
}

class MockToastManager: ToastManager {
    var showCallCount = 0
    var lastMessage: String?
    var lastType: ToastType?
    var lastDuration: TimeInterval?

    override func show(
        _ message: String,
        type: ToastType,
        duration: TimeInterval = 3.0,
        announceImmediately: Bool = true
    ) {
        showCallCount += 1
        lastMessage = message
        lastType = type
        lastDuration = duration

        // Don't call super to avoid actual toast display in tests
    }
}
```

This comprehensive code examples document provides practical implementations for various scenarios and use cases of the Toast notification system. Each example includes detailed comments and follows the established patterns and best practices.
