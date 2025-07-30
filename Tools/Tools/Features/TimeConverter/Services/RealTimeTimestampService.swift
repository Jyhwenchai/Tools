import AppKit
import Foundation

// MARK: - Real-Time Timestamp Service

@Observable
class RealTimeTimestampService {
    // MARK: - Properties

    private(set) var state: RealTimeTimestampState
    private var timer: Timer?
    private let configuration: RealTimeTimestampConfiguration

    // MARK: - Initialization

    init(configuration: RealTimeTimestampConfiguration = .default) {
        self.configuration = configuration
        self.state = RealTimeTimestampState(
            unit: configuration.defaultUnit,
            isRunning: false
        )

        // Auto-start if configured
        if configuration.autoStart {
            startTimer()
        } else {
            updateTimestamp()
        }
    }

    deinit {
        stopTimer()
    }

    // MARK: - Timer Management

    func startTimer() {
        guard timer == nil else { return }

        state.isRunning = true
        updateTimestamp()

        timer = Timer.scheduledTimer(withTimeInterval: configuration.updateInterval, repeats: true)
        { [weak self] _ in
            self?.updateTimestamp()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        state.isRunning = false
    }

    func toggleTimer() {
        if state.isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    // MARK: - Unit Management

    func toggleUnit() {
        state.unit = state.unit == .seconds ? .milliseconds : .seconds
        updateTimestamp()
    }

    func setUnit(_ unit: TimestampUnit) {
        state.unit = unit
        updateTimestamp()
    }

    // MARK: - Clipboard Operations

    @discardableResult
    func copyToClipboard() -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let success = pasteboard.setString(state.timestamp, forType: .string)

        if !success {
            // Handle clipboard error if needed
            print("Failed to copy timestamp to clipboard")
        }

        return success
    }

    // MARK: - Timestamp Operations

    private func updateTimestamp() {
        let currentTime = Date().timeIntervalSince1970
        state.timestamp = state.unit.formatFunction(currentTime)
        state.lastUpdate = Date()
    }

    func getCurrentTimestamp(for unit: TimestampUnit) -> String {
        let currentTime = Date().timeIntervalSince1970
        return unit.formatFunction(currentTime)
    }

    func getFormattedTimestamp(for date: Date, unit: TimestampUnit) -> String {
        let timestamp = date.timeIntervalSince1970
        return unit.formatFunction(timestamp)
    }

    // MARK: - State Access

    var currentTimestamp: String {
        state.timestamp
    }

    var isRunning: Bool {
        state.isRunning
    }

    var currentUnit: TimestampUnit {
        state.unit
    }

    var lastUpdate: Date {
        state.lastUpdate
    }

    // MARK: - Validation

    func validateTimestamp(_ timestamp: String, for unit: TimestampUnit) -> Bool {
        switch unit {
        case .seconds:
            guard let value = Int(timestamp) else { return false }
            return value >= 0 && value <= 4_102_444_800  // Jan 1, 2100

        case .milliseconds:
            guard let value = Int64(timestamp) else { return false }
            return value >= 0 && value <= 4_102_444_800_000  // Jan 1, 2100 in milliseconds
        }
    }

    // MARK: - Utility Methods

    func reset() {
        stopTimer()
        state = RealTimeTimestampState(
            unit: configuration.defaultUnit,
            isRunning: false
        )
        updateTimestamp()
    }

    func pause() {
        if state.isRunning {
            stopTimer()
        }
    }

    func resume() {
        if !state.isRunning {
            startTimer()
        }
    }
}
