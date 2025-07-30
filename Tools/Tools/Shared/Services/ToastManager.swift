import Foundation
import SwiftUI

// MARK: - Timer State Management

/// Represents the state of a toast's auto-dismiss timer
private struct TimerState {
    var timer: Timer
    let startTime: Date
    let originalDuration: TimeInterval
    var isPaused: Bool = false
    var pausedAt: Date?

    /// Calculate remaining time accounting for paused duration
    var remainingTime: TimeInterval {
        let now = Date()
        if isPaused, let pausedAt = pausedAt {
            let elapsedTime = startTime.distance(to: pausedAt)
            return max(0, originalDuration - elapsedTime)
        } else {
            let elapsedTime = startTime.distance(to: now)
            return max(0, originalDuration - elapsedTime)
        }
    }
}

// MARK: - ToastManager

@Observable
class ToastManager {
    // MARK: - Properties

    /// Array of currently active toasts
    var toasts: [ToastMessage] = []

    /// Dictionary to track active timer states for auto-dismiss functionality
    private var timerStates: [UUID: TimerState] = [:]

    /// Queue for managing rapid successive toast requests
    private var toastQueue: [ToastMessage] = []

    /// Maximum number of toasts to display simultaneously
    private let maxSimultaneousToasts: Int = 5

    /// Minimum time between processing queued toasts (prevents spam)
    private let queueProcessingInterval: TimeInterval = 0.1

    /// Timer for processing queued toasts
    private var queueProcessingTimer: Timer?

    /// Serial queue for thread-safe operations
    private let operationQueue = DispatchQueue(label: "com.tools.toastmanager", qos: .userInitiated)

    // MARK: - Public Methods

    /// Display a new toast notification
    /// - Parameters:
    ///   - message: The message to display
    ///   - type: The type of toast (success, error, warning, info)
    ///   - duration: How long the toast should be displayed (default: 3.0 seconds)
    ///   - announceImmediately: Whether to announce to accessibility services immediately
    func show(
        _ message: String, type: ToastType, duration: TimeInterval = 3.0,
        announceImmediately: Bool = true
    ) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }

            let toast = ToastMessage(
                message: message,
                type: type,
                duration: duration,
                isAutoDismiss: duration > 0
            )

            DispatchQueue.main.async {
                self.processToastRequest(toast, announceImmediately: announceImmediately)
            }
        }
    }

    /// Process a toast request, handling queue management and display logic
    /// - Parameters:
    ///   - toast: The toast to process
    ///   - announceImmediately: Whether to announce immediately
    private func processToastRequest(_ toast: ToastMessage, announceImmediately: Bool) {
        // Check if we can display immediately or need to queue
        if toasts.count < maxSimultaneousToasts {
            displayToast(toast, announceImmediately: announceImmediately)
        } else {
            // Add to queue and start processing if needed
            toastQueue.append(toast)
            startQueueProcessing()
        }
    }

    /// Display a toast immediately
    /// - Parameters:
    ///   - toast: The toast to display
    ///   - announceImmediately: Whether to announce immediately
    private func displayToast(_ toast: ToastMessage, announceImmediately: Bool) {
        // Add toast to the array
        toasts.append(toast)

        // Schedule auto-dismiss if enabled
        if toast.isAutoDismiss {
            scheduleAutoDismiss(for: toast)
        }

        // Announce immediately for accessibility if requested
        if announceImmediately {
            announceToastForAccessibility(toast)
        }
    }

    /// Start processing the toast queue
    private func startQueueProcessing() {
        guard queueProcessingTimer == nil else { return }

        queueProcessingTimer = Timer.scheduledTimer(
            withTimeInterval: queueProcessingInterval, repeats: true
        ) { [weak self] _ in
            self?.processQueue()
        }
    }

    /// Process queued toasts when space becomes available
    private func processQueue() {
        guard !toastQueue.isEmpty, toasts.count < maxSimultaneousToasts else {
            // Stop queue processing if queue is empty or no space available
            if toastQueue.isEmpty {
                stopQueueProcessing()
            }
            return
        }

        let toast = toastQueue.removeFirst()
        displayToast(toast, announceImmediately: true)
    }

    /// Stop queue processing timer
    private func stopQueueProcessing() {
        queueProcessingTimer?.invalidate()
        queueProcessingTimer = nil
    }

    /// Dismiss a specific toast
    /// - Parameter toast: The toast message to dismiss
    func dismiss(_ toast: ToastMessage) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.performDismiss(toast)
            }
        }
    }

    /// Perform the actual dismissal on the main queue
    /// - Parameter toast: The toast to dismiss
    private func performDismiss(_ toast: ToastMessage) {
        // Cancel any active timer for this toast
        if let timerState = timerStates[toast.id] {
            timerState.timer.invalidate()
            timerStates.removeValue(forKey: toast.id)
        }

        // Remove toast from array
        toasts.removeAll { $0.id == toast.id }

        // Process queue if space became available
        if !toastQueue.isEmpty {
            startQueueProcessing()
        }
    }

    /// Dismiss all currently displayed toasts
    func dismissAll() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.performDismissAll()
            }
        }
    }

    /// Perform dismissal of all toasts on the main queue
    private func performDismissAll() {
        // Cancel all active timers
        for timerState in timerStates.values {
            timerState.timer.invalidate()
        }
        timerStates.removeAll()

        // Clear all toasts and queue
        toasts.removeAll()
        toastQueue.removeAll()

        // Stop queue processing
        stopQueueProcessing()
    }

    // MARK: - Private Methods

    /// Schedule automatic dismissal for a toast
    /// - Parameter toast: The toast to schedule for dismissal
    private func scheduleAutoDismiss(for toast: ToastMessage) {
        let startTime = Date()
        let timer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) {
            [weak self] _ in
            self?.operationQueue.async {
                DispatchQueue.main.async {
                    self?.performDismiss(toast)
                }
            }
        }

        let timerState = TimerState(
            timer: timer,
            startTime: startTime,
            originalDuration: toast.duration
        )

        timerStates[toast.id] = timerState
    }

    // MARK: - Timer Management

    /// Pause auto-dismiss timer for a specific toast (used for hover functionality)
    /// - Parameter toast: The toast to pause auto-dismiss for
    func pauseAutoDismiss(for toast: ToastMessage) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard var timerState = self.timerStates[toast.id], !timerState.isPaused else {
                    return
                }

                // Invalidate current timer
                timerState.timer.invalidate()

                // Mark as paused and record pause time
                timerState.isPaused = true
                timerState.pausedAt = Date()

                // Update timer state
                self.timerStates[toast.id] = timerState
            }
        }
    }

    /// Resume auto-dismiss timer for a specific toast (used when hover ends)
    /// - Parameter toast: The toast to resume auto-dismiss for
    /// - Parameter remainingTime: Optional remaining time override
    func resumeAutoDismiss(for toast: ToastMessage, remainingTime: TimeInterval? = nil) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard var timerState = self.timerStates[toast.id], timerState.isPaused else {
                    return
                }
                guard toast.isAutoDismiss else { return }

                // Calculate remaining time
                let timeToUse = remainingTime ?? timerState.remainingTime
                guard timeToUse > 0 else {
                    // Time expired, dismiss immediately
                    self.performDismiss(toast)
                    return
                }

                // Create new timer with remaining time
                let newTimer = Timer.scheduledTimer(withTimeInterval: timeToUse, repeats: false) {
                    [weak self] _ in
                    self?.operationQueue.async {
                        DispatchQueue.main.async {
                            self?.performDismiss(toast)
                        }
                    }
                }

                // Update timer state
                timerState.timer = newTimer
                timerState.isPaused = false
                timerState.pausedAt = nil

                self.timerStates[toast.id] = timerState
            }
        }
    }

    /// Get remaining time for a toast's auto-dismiss timer
    /// - Parameter toast: The toast to check
    /// - Returns: Remaining time in seconds, or nil if not auto-dismissing
    func getRemainingTime(for toast: ToastMessage) -> TimeInterval? {
        guard let timerState = timerStates[toast.id] else { return nil }
        return timerState.remainingTime
    }

    /// Check if a toast's timer is currently paused
    /// - Parameter toast: The toast to check
    /// - Returns: True if paused, false otherwise
    func isTimerPaused(for toast: ToastMessage) -> Bool {
        return timerStates[toast.id]?.isPaused ?? false
    }

    // MARK: - Accessibility Support

    /// Announce toast to accessibility services
    /// - Parameter toast: The toast to announce
    private func announceToastForAccessibility(_ toast: ToastMessage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let typeDescription: String
            let priority: NSAccessibilityPriorityLevel
            switch toast.type {
            case .success:
                typeDescription = "成功"
                priority = .medium
            case .error:
                typeDescription = "错误"
                priority = .high
            case .warning:
                typeDescription = "警告"
                priority = .medium
            case .info:
                typeDescription = "信息"
                priority = .low
            }

            let announcement = "\(typeDescription): \(toast.message)"

            let userInfo: [NSAccessibility.NotificationUserInfoKey: Any] = [
                .announcement: announcement,
                .priority: priority.rawValue,
            ]

            // Note: announcementRequestedShouldPlaySound is not available in macOS
            // Sound will be handled by the system based on priority level

            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: userInfo
            )
        }
    }

    /// Get accessibility description for current toast state
    var accessibilityDescription: String {
        if toasts.isEmpty {
            return "无通知"
        } else if toasts.count == 1 {
            let toast = toasts[0]
            let typeDescription: String
            switch toast.type {
            case .success: typeDescription = "成功"
            case .error: typeDescription = "错误"
            case .warning: typeDescription = "警告"
            case .info: typeDescription = "信息"
            }
            let autoDismissInfo =
                toast.isAutoDismiss ? "，将在 \(Int(toast.duration)) 秒后自动关闭" : "，需要手动关闭"
            return "1个通知: \(typeDescription) - \(toast.message)\(autoDismissInfo)"
        } else {
            let autoDismissCount = toasts.filter { $0.isAutoDismiss }.count
            let manualCount = toasts.count - autoDismissCount
            var description = "\(toasts.count)个通知"
            if autoDismissCount > 0 && manualCount > 0 {
                description += "（\(autoDismissCount)个自动关闭，\(manualCount)个手动关闭）"
            } else if autoDismissCount > 0 {
                description += "（全部自动关闭）"
            } else {
                description += "（全部需要手动关闭）"
            }
            return description
        }
    }

    /// Get detailed accessibility summary for screen readers
    var detailedAccessibilityDescription: String {
        if toasts.isEmpty {
            return "通知区域为空"
        }

        var descriptions: [String] = []
        for (index, toast) in toasts.enumerated() {
            let typeDescription: String
            switch toast.type {
            case .success: typeDescription = "成功"
            case .error: typeDescription = "错误"
            case .warning: typeDescription = "警告"
            case .info: typeDescription = "信息"
            }
            let position = "第 \(index + 1) 个"
            let autoDismissInfo = toast.isAutoDismiss ? "自动关闭" : "手动关闭"
            descriptions.append(
                "\(position)\(typeDescription)通知：\(toast.message)，\(autoDismissInfo)")
        }

        return descriptions.joined(separator: "。")
    }

    // MARK: - Queue Management

    /// Get current queue status
    var queueStatus: (queuedCount: Int, displayedCount: Int, maxCapacity: Int) {
        return (
            queuedCount: toastQueue.count, displayedCount: toasts.count,
            maxCapacity: maxSimultaneousToasts
        )
    }

    /// Clear the toast queue without affecting displayed toasts
    func clearQueue() {
        operationQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.toastQueue.removeAll()
                self?.stopQueueProcessing()
            }
        }
    }

    /// Handle rapid successive toast requests gracefully
    /// - Parameters:
    ///   - messages: Array of messages to show
    ///   - type: Toast type for all messages
    ///   - duration: Duration for all toasts
    func showBatch(_ messages: [String], type: ToastType, duration: TimeInterval = 3.0) {
        guard !messages.isEmpty else { return }

        operationQueue.async { [weak self] in
            guard let self = self else { return }

            let toasts = messages.map { message in
                ToastMessage(
                    message: message,
                    type: type,
                    duration: duration,
                    isAutoDismiss: duration > 0
                )
            }

            DispatchQueue.main.async {
                // Process first toast immediately if possible
                if let firstToast = toasts.first, self.toasts.count < self.maxSimultaneousToasts {
                    self.displayToast(firstToast, announceImmediately: true)

                    // Add remaining toasts to queue
                    if toasts.count > 1 {
                        self.toastQueue.append(contentsOf: Array(toasts.dropFirst()))
                        self.startQueueProcessing()
                    }
                } else {
                    // Add all toasts to queue
                    self.toastQueue.append(contentsOf: toasts)
                    self.startQueueProcessing()
                }
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        // Clean up all timers when manager is deallocated
        for timerState in timerStates.values {
            timerState.timer.invalidate()
        }
        timerStates.removeAll()

        // Clean up queue processing timer
        queueProcessingTimer?.invalidate()
        queueProcessingTimer = nil

        // Clear queues
        toastQueue.removeAll()
        toasts.removeAll()
    }
}
