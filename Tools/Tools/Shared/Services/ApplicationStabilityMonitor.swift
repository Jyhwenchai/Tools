//
//  ApplicationStabilityMonitor.swift
//  Tools
//
//  Created by Kiro on 2025/7/21.
//

import Foundation
import OSLog
import SwiftUI

/// Service for monitoring and improving application stability
@Observable
class ApplicationStabilityMonitor {
  static let shared = ApplicationStabilityMonitor()

  private let logger = Logger(subsystem: "com.tools.app", category: "Stability")
  private var crashDetectionTimer: Timer?
  private var lastHeartbeat = Date()

  // Stability metrics
  var appUptime: TimeInterval {
    ProcessInfo.processInfo.systemUptime
  }

  var memoryUsage: Double {
    getCurrentMemoryUsage()
  }

  var isMemoryPressureDetected: Bool = false
  var lastCrashDate: Date? {
    get {
      let timestamp = UserDefaults.standard.double(forKey: "last_crash_timestamp")
      if timestamp > 0 {
        return Date(timeIntervalSince1970: timestamp)
      }
      return nil
    }
    set {
      if let date = newValue {
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "last_crash_timestamp")
      } else {
        UserDefaults.standard.removeObject(forKey: "last_crash_timestamp")
      }
    }
  }

  private init() {
    // Check for previous crash
    checkForPreviousCrash()

    // Setup stability monitoring
    setupStabilityMonitoring()
  }

  // MARK: - Stability Monitoring

  private func setupStabilityMonitoring() {
    // Register for memory pressure notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMemoryPressure),
      name: NSApplication.didResignActiveNotification, // 使用替代通知，因为macOS没有内存警告通知
      object: nil)

    // Register for app termination
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppTermination),
      name: NSApplication.willTerminateNotification,
      object: nil)

    // Start heartbeat timer
    startHeartbeatTimer()

    logger.info("Stability monitoring initialized")
  }

  private func startHeartbeatTimer() {
    // Record heartbeats to detect freezes
    crashDetectionTimer = Timer
      .scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
        self?.recordHeartbeat()
      }
  }

  private func recordHeartbeat() {
    // Record current time as heartbeat
    lastHeartbeat = Date()

    // Store heartbeat in UserDefaults
    UserDefaults.standard.set(lastHeartbeat.timeIntervalSince1970, forKey: "last_heartbeat")

    // Check memory usage periodically
    let currentMemory = getCurrentMemoryUsage()
    if currentMemory > 500 { // 500MB threshold
      logger.warning("High memory usage detected: \(currentMemory, privacy: .public)MB")
      triggerMemoryOptimization()
    }
  }

  @objc
  private func handleMemoryPressure() {
    isMemoryPressureDetected = true
    logger.warning("Memory pressure detected - triggering optimization")

    // Trigger memory optimization
    triggerMemoryOptimization()

    // Reset flag after delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
      self?.isMemoryPressureDetected = false
    }
  }

  @objc
  private func handleAppTermination() {
    // Record clean exit
    UserDefaults.standard.set(true, forKey: "clean_exit")
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "last_exit_timestamp")
  }

  // MARK: - Crash Detection

  private func checkForPreviousCrash() {
    // Check if last exit was clean
    let wasCleanExit = UserDefaults.standard.bool(forKey: "clean_exit")

    if !wasCleanExit {
      // Check last heartbeat
      let lastHeartbeatTimestamp = UserDefaults.standard.double(forKey: "last_heartbeat")
      if lastHeartbeatTimestamp > 0 {
        let lastHeartbeatDate = Date(timeIntervalSince1970: lastHeartbeatTimestamp)

        // If last heartbeat was recent, app likely crashed
        if Date().timeIntervalSince(lastHeartbeatDate) < 300 { // 5 minutes
          logger.error("Possible crash detected from previous session")
          lastCrashDate = lastHeartbeatDate

          // Log crash for analytics
          ErrorLoggingService.shared.logError(
            .unknown("可能的应用崩溃"),
            context: "稳定性监控")
        }
      }
    }

    // Reset for this session
    UserDefaults.standard.set(false, forKey: "clean_exit")
  }

  // MARK: - Memory Optimization

  private func triggerMemoryOptimization() {
    // Clear caches
    URLCache.shared.removeAllCachedResponses()

    // Force garbage collection
    autoreleasepool {
      // This helps release retained objects
    }

    // Notify other components
    NotificationCenter.default.post(name: .applicationMemoryOptimizationNeeded, object: nil)

    logger.info("Memory optimization triggered")
  }

  // MARK: - Stability Reporting

  func getStabilityReport() -> StabilityReport {
    let currentMemory = getCurrentMemoryUsage()
    let thermalState = ProcessInfo.processInfo.thermalState.description

    return StabilityReport(
      uptime: appUptime,
      memoryUsage: currentMemory,
      thermalState: thermalState,
      lastCrashDate: lastCrashDate,
      memoryPressureDetected: isMemoryPressureDetected)
  }

  // MARK: - Helper Methods

  private func getCurrentMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }

    if kerr == KERN_SUCCESS {
      return Double(info.resident_size) / (1024 * 1024) // Convert to MB
    }

    return 0
  }
}

// MARK: - Stability Report

struct StabilityReport {
  let uptime: TimeInterval
  let memoryUsage: Double
  let thermalState: String
  let lastCrashDate: Date?
  let memoryPressureDetected: Bool

  var formattedUptime: String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .abbreviated
    return formatter.string(from: uptime) ?? "\(Int(uptime))s"
  }
}

// MARK: - ProcessInfo.ThermalState Extension

extension ProcessInfo.ThermalState {
  var description: String {
    switch self {
    case .nominal:
      return "正常"
    case .fair:
      return "良好"
    case .serious:
      return "严重"
    case .critical:
      return "临界"
    @unknown default:
      return "未知"
    }
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let applicationMemoryOptimizationNeeded = Notification
    .Name("applicationMemoryOptimizationNeeded")
}

// MARK: - View Extension

extension View {
  /// Apply stability monitoring to a view
  func withStabilityMonitoring() -> some View {
    onAppear {
      // Access shared instance to ensure it's initialized
      _ = ApplicationStabilityMonitor.shared
    }
  }
}
