import Foundation

// MARK: - Timestamp Unit Enumeration

enum TimestampUnit: String, CaseIterable, Identifiable {
    case seconds
    case milliseconds

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seconds:
            return "秒"
        case .milliseconds:
            return "毫秒"
        }
    }

    var formatFunction: (TimeInterval) -> String {
        switch self {
        case .seconds:
            return { timestamp in String(Int(timestamp)) }
        case .milliseconds:
            return { timestamp in String(Int(timestamp * 1000)) }
        }
    }

    var buttonText: String {
        switch self {
        case .seconds:
            return "切换到毫秒"
        case .milliseconds:
            return "切换到秒"
        }
    }
}

// MARK: - Real-Time Timestamp State

struct RealTimeTimestampState {
    var timestamp: String
    var isRunning: Bool
    var unit: TimestampUnit
    var lastUpdate: Date

    init(
        timestamp: String = "",
        unit: TimestampUnit = .seconds,
        isRunning: Bool = false,
        lastUpdate: Date = Date()
    ) {
        self.timestamp = timestamp
        self.isRunning = isRunning
        self.unit = unit
        self.lastUpdate = lastUpdate
    }

    // Helper computed properties
    var toggleButtonText: String {
        isRunning ? "停止" : "开始"
    }

    var unitButtonText: String {
        unit.buttonText
    }

    var displayText: String {
        "\(timestamp) \(unit.displayName)"
    }
}

// MARK: - Real-Time Timestamp Configuration

struct RealTimeTimestampConfiguration {
    let updateInterval: TimeInterval
    let autoStart: Bool
    let defaultUnit: TimestampUnit

    init(
        updateInterval: TimeInterval = 1.0,
        autoStart: Bool = true,
        defaultUnit: TimestampUnit = .seconds
    ) {
        self.updateInterval = updateInterval
        self.autoStart = autoStart
        self.defaultUnit = defaultUnit
    }

    static let `default` = RealTimeTimestampConfiguration()
}

// MARK: - Real-Time Timestamp Error

enum RealTimeTimestampError: LocalizedError {
    case timerCreationFailed
    case clipboardAccessFailed
    case invalidTimestamp

    var errorDescription: String? {
        switch self {
        case .timerCreationFailed:
            return "无法创建定时器"
        case .clipboardAccessFailed:
            return "无法访问剪贴板"
        case .invalidTimestamp:
            return "时间戳格式无效"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .timerCreationFailed:
            return "请重新启动应用程序"
        case .clipboardAccessFailed:
            return "请检查应用程序权限"
        case .invalidTimestamp:
            return "请检查时间戳格式"
        }
    }
}
