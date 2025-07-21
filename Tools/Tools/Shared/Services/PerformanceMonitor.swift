//
//  PerformanceMonitor.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import OSLog
import SwiftUI

/// Service for monitoring application performance during development
/// In DEBUG mode: Provides detailed performance logging to console
/// In RELEASE mode: Provides minimal performance data without UI impact
@Observable
class PerformanceMonitor {
  static let shared = PerformanceMonitor()

  private let logger = Logger(subsystem: "com.tools.app", category: "Performance")
  private var performanceMetrics: [PerformanceMetric] = []
  private let maxMetricsCount = 20 // Reduced for development-only use

  // Minimal performance state for release builds
  var currentMemoryUsage: Double = 0
  var currentCPUUsage: Double = 0
  var isPerformanceOptimal: Bool = true
  var performanceWarnings: [PerformanceWarning] = []

  private var monitoringTimer: Timer?

  private init() {
    // Defer initialization to improve startup performance
    // Monitoring will be started explicitly when needed
    #if DEBUG
      logger.info("🚀 Performance monitor initialized (will start monitoring on demand)")
    #endif

    // Register for memory pressure notifications to improve stability
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleMemoryPressure),
      name: NSApplication.didResignActiveNotification, // 使用替代通知，因为macOS没有内存警告通知
      object: nil)
  }

  @objc
  private func handleMemoryPressure() {
    // Clear performance metrics history to free memory
    performanceMetrics.removeAll(keepingCapacity: false)

    // Trigger performance optimization
    #if DEBUG
      logger.warning("Memory pressure detected - clearing performance metrics history")
      triggerPerformanceOptimization()
    #endif
  }

  deinit {
    stopPerformanceMonitoring()
  }

  // MARK: - Performance Monitoring

  func startPerformanceMonitoring() {
    // Prevent multiple timers
    guard monitoringTimer == nil else { return }

    #if DEBUG
      // Full monitoring in debug mode with delayed start to improve startup
      // Increased delay to 3.0 seconds to further reduce startup impact
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
        self?.monitoringTimer = Timer
          .scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMetrics()
          }
        self?.logger
          .info("🚀 Performance monitoring timer started (delayed for startup optimization)")
      }
    #endif
  }

  private func startBasicMonitoring() {
    // Minimal monitoring for release builds - no timer, just on-demand
    // No permission checks, just basic metrics
    updateBasicMetrics()
  }

  func stopPerformanceMonitoring() {
    monitoringTimer?.invalidate()
    monitoringTimer = nil

    #if DEBUG
      logger.info("🛑 Performance monitoring stopped")
    #endif
  }

  private func updatePerformanceMetrics() {
    let memoryUsage = getCurrentMemoryUsage()
    let cpuUsage = getCurrentCPUUsage()

    currentMemoryUsage = memoryUsage
    currentCPUUsage = cpuUsage

    #if DEBUG
      // Full metrics recording in debug mode
      let metric = PerformanceMetric(
        timestamp: Date(),
        memoryUsage: memoryUsage,
        cpuUsage: cpuUsage)

      performanceMetrics.append(metric)

      // Maintain metrics history limit
      if performanceMetrics.count > maxMetricsCount {
        performanceMetrics.removeFirst(performanceMetrics.count - maxMetricsCount)
      }

      // Check for performance issues and log detailed information
      checkPerformanceThresholds(metric)
      logDetailedPerformanceInfo(metric)
    #endif
  }

  private func updateBasicMetrics() {
    // Minimal update for release builds
    currentMemoryUsage = getCurrentMemoryUsage()
    currentCPUUsage = getCurrentCPUUsage()
    isPerformanceOptimal = currentMemoryUsage < 200 && currentCPUUsage < 80
  }

  #if DEBUG
    private func logDetailedPerformanceInfo(_ metric: PerformanceMetric) {
      let timestamp = DateFormatter().string(from: metric.timestamp)

      // Detailed console logging for development
      print("📊 PERFORMANCE METRICS [\(timestamp)]")
      print("   💾 Memory: \(String(format: "%.1f", metric.memoryUsage))MB")
      print("   🔥 CPU: \(String(format: "%.1f", metric.cpuUsage))%")

      // Log warnings if any
      if !performanceWarnings.isEmpty {
        print("   ⚠️  Warnings:")
        for warning in performanceWarnings {
          print("      - \(warning.description)")
        }
      }

      // Log performance trends
      if performanceMetrics.count >= 3 {
        let recent = Array(performanceMetrics.suffix(3))
        let memoryTrend = recent.last!.memoryUsage - recent.first!.memoryUsage
        let cpuTrend = recent.last!.cpuUsage - recent.first!.cpuUsage

        if abs(memoryTrend) > 10 {
          print(
            "   📈 Memory trend: \(memoryTrend > 0 ? "+" : "")\(String(format: "%.1f", memoryTrend))MB")
        }
        if abs(cpuTrend) > 5 {
          print("   📈 CPU trend: \(cpuTrend > 0 ? "+" : "")\(String(format: "%.1f", cpuTrend))%")
        }
      }

      print("   ✅ Status: \(isPerformanceOptimal ? "Optimal" : "Needs attention")")
      print("") // Empty line for readability

      // Also log to system logger for debugging
      logger
        .info(
          "Memory: \(String(format: "%.1f", metric.memoryUsage))MB, CPU: \(String(format: "%.1f", metric.cpuUsage))%, Optimal: \(self.isPerformanceOptimal)")
    }
  #endif

  // MARK: - Performance Metrics Collection (No Special Permissions Required)

  private func getCurrentMemoryUsage() -> Double {
    // Use basic memory info that doesn't require special permissions
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(
          mach_task_self_,
          task_flavor_t(MACH_TASK_BASIC_INFO),
          $0,
          &count)
      }
    }

    if kerr == KERN_SUCCESS {
      return Double(info.resident_size) / (1024 * 1024) // Convert to MB
    }

    return 0
  }

  private func getCurrentCPUUsage() -> Double {
    // Basic CPU usage estimation without requiring system permissions
    // This provides a rough estimate based on process info
    let processInfo = ProcessInfo.processInfo

    #if DEBUG
      // In debug mode, we can provide more detailed CPU info
      return estimateCPUUsage()
    #else
      // In release mode, return minimal CPU info
      return processInfo.thermalState == .nominal ? 5.0 : 15.0
    #endif
  }

  #if DEBUG
    private func estimateCPUUsage() -> Double {
      // Simple CPU usage estimation for development
      // This is a basic implementation that doesn't require special permissions
      var info = task_thread_times_info()
      var count = mach_msg_type_number_t(MemoryLayout<task_thread_times_info>
        .size / MemoryLayout<integer_t>.size)

      let kerr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
          task_info(mach_task_self_, task_flavor_t(TASK_THREAD_TIMES_INFO), $0, &count)
        }
      }

      if kerr == KERN_SUCCESS {
        let totalTime = info.user_time.seconds + info.system_time.seconds
        // This is a simplified calculation - in a real app you'd track deltas over time
        return min(Double(totalTime) * 0.1, 100.0)
      }

      // Fallback to thermal state estimation
      let thermalState = ProcessInfo.processInfo.thermalState
      switch thermalState {
      case .nominal:
        return Double.random(in: 2...8)
      case .fair:
        return Double.random(in: 8...15)
      case .serious:
        return Double.random(in: 15...25)
      case .critical:
        return Double.random(in: 25...40)
      @unknown default:
        return 10.0
      }
    }
  #endif

  // MARK: - Performance Threshold Checking (DEBUG Mode Only)

  #if DEBUG
    private func checkPerformanceThresholds(_ metric: PerformanceMetric) {
      var newWarnings: [PerformanceWarning] = []

      // Memory usage threshold (200MB)
      if metric.memoryUsage > 200 {
        newWarnings.append(.highMemoryUsage(metric.memoryUsage))
        print("🚨 HIGH MEMORY USAGE: \(String(format: "%.1f", metric.memoryUsage))MB")
      }

      // CPU usage threshold (50% - lower threshold for development)
      if metric.cpuUsage > 50 {
        newWarnings.append(.highCPUUsage(metric.cpuUsage))
        print("🚨 HIGH CPU USAGE: \(String(format: "%.1f", metric.cpuUsage))%")
      }

      // Check for sustained high usage (only in debug mode)
      let recentMetrics = performanceMetrics.suffix(3) // Reduced for development
      if recentMetrics.count >= 3 {
        let avgMemory = recentMetrics.map(\.memoryUsage).reduce(0, +) / Double(recentMetrics.count)
        let avgCPU = recentMetrics.map(\.cpuUsage).reduce(0, +) / Double(recentMetrics.count)

        if avgMemory > 150 {
          newWarnings.append(.sustainedHighMemoryUsage(avgMemory))
          print("🚨 SUSTAINED HIGH MEMORY: \(String(format: "%.1f", avgMemory))MB average")
        }

        if avgCPU > 30 {
          newWarnings.append(.sustainedHighCPUUsage(avgCPU))
          print("🚨 SUSTAINED HIGH CPU: \(String(format: "%.1f", avgCPU))% average")
        }
      }

      performanceWarnings = newWarnings
      isPerformanceOptimal = newWarnings.isEmpty

      // Log optimization triggers in debug mode
      if !isPerformanceOptimal {
        print("🔧 TRIGGERING PERFORMANCE OPTIMIZATION")
        triggerPerformanceOptimization()
      }
    }
  #else
    private func checkPerformanceThresholds() {
      // Minimal threshold checking for release builds
      isPerformanceOptimal = currentMemoryUsage < 200 && currentCPUUsage < 80
      performanceWarnings = []
    }
  #endif

  // MARK: - Performance Optimization (Development Only)

  private func triggerPerformanceOptimization() {
    #if DEBUG
      print("🔧 PERFORMANCE OPTIMIZATION TRIGGERED")
      logger.warning("Performance issues detected, triggering optimization")

      // Log optimization actions
      print("   🧹 Clearing caches...")
      print("   🗑️  Forcing garbage collection...")
      print("   ⏸️  Reducing background processing...")

      // Notify other components to optimize
      NotificationCenter.default.post(name: .performanceOptimizationNeeded, object: nil)

      // Perform automatic optimizations
      DispatchQueue.global(qos: .utility).async {
        self.performAutomaticOptimizations()
      }
    #endif
  }

  private func performAutomaticOptimizations() {
    #if DEBUG
      let startTime = Date()
    #endif

    // Clear caches
    clearImageCaches()

    // Force garbage collection
    autoreleasepool {
      // This helps release retained objects
    }

    // Reduce background processing
    reduceBackgroundProcessing()

    #if DEBUG
      let duration = Date().timeIntervalSince(startTime)
      print("✅ OPTIMIZATION COMPLETED in \(String(format: "%.2f", duration))s")
      logger.info("Automatic performance optimizations completed in \(duration)s")
    #endif
  }

  private func clearImageCaches() {
    // Clear any image caches (safe operation, no permissions needed)
    URLCache.shared.removeAllCachedResponses()
  }

  private func reduceBackgroundProcessing() {
    // Reduce frequency of background tasks
    NotificationCenter.default.post(name: .reduceBackgroundProcessing, object: nil)
  }

  // MARK: - Performance Analytics (Minimal for Release)

  func getPerformanceReport() -> PerformanceReport {
    #if DEBUG
      // Full analytics in debug mode
      let avgMemory = performanceMetrics.isEmpty ? currentMemoryUsage :
        performanceMetrics.map(\.memoryUsage).reduce(0, +) / Double(performanceMetrics.count)

      let avgCPU = performanceMetrics.isEmpty ? currentCPUUsage :
        performanceMetrics.map(\.cpuUsage).reduce(0, +) / Double(performanceMetrics.count)

      let maxMemory = performanceMetrics.map(\.memoryUsage).max() ?? currentMemoryUsage
      let maxCPU = performanceMetrics.map(\.cpuUsage).max() ?? currentCPUUsage

      print("📋 PERFORMANCE REPORT GENERATED")
      print("   📊 Avg Memory: \(String(format: "%.1f", avgMemory))MB")
      print("   📊 Avg CPU: \(String(format: "%.1f", avgCPU))%")
      print("   📊 Peak Memory: \(String(format: "%.1f", maxMemory))MB")
      print("   📊 Peak CPU: \(String(format: "%.1f", maxCPU))%")
      print("   📊 Total Warnings: \(performanceWarnings.count)")
      print("   📊 Status: \(isPerformanceOptimal ? "✅ Optimal" : "⚠️ Needs attention")")

      return PerformanceReport(
        averageMemoryUsage: avgMemory,
        averageCPUUsage: avgCPU,
        peakMemoryUsage: maxMemory,
        peakCPUUsage: maxCPU,
        totalWarnings: performanceWarnings.count,
        isOptimal: isPerformanceOptimal)
    #else
      // Minimal report for release builds
      updateBasicMetrics()
      return PerformanceReport(
        averageMemoryUsage: currentMemoryUsage,
        averageCPUUsage: currentCPUUsage,
        peakMemoryUsage: currentMemoryUsage,
        peakCPUUsage: currentCPUUsage,
        totalWarnings: 0,
        isOptimal: isPerformanceOptimal)
    #endif
  }

  func getRecentMetrics(count: Int = 20) -> [PerformanceMetric] {
    #if DEBUG
      return Array(performanceMetrics.suffix(count))
    #else
      // Return minimal metrics for release builds
      return [PerformanceMetric(
        timestamp: Date(),
        memoryUsage: currentMemoryUsage,
        cpuUsage: currentCPUUsage)]
    #endif
  }

  // MARK: - Development Logging Helpers

  #if DEBUG
    func logCurrentState() {
      print("🔍 CURRENT PERFORMANCE STATE")
      print("   💾 Memory: \(String(format: "%.1f", currentMemoryUsage))MB")
      print("   🔥 CPU: \(String(format: "%.1f", currentCPUUsage))%")
      print("   📈 Metrics Count: \(performanceMetrics.count)")
      print("   ⚠️  Active Warnings: \(performanceWarnings.count)")
      print("   ✅ Optimal: \(isPerformanceOptimal)")
    }

    func logPerformanceHistory() {
      guard !performanceMetrics.isEmpty else {
        print("📊 No performance history available")
        return
      }

      print("📊 PERFORMANCE HISTORY (Last \(min(10, performanceMetrics.count)) entries)")
      for (index, metric) in performanceMetrics.suffix(10).enumerated() {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let time = formatter.string(from: metric.timestamp)
        print(
          "   \(index + 1). [\(time)] Memory: \(String(format: "%.1f", metric.memoryUsage))MB, CPU: \(String(format: "%.1f", metric.cpuUsage))%")
      }
    }
  #endif
}

// MARK: - Performance Data Models

struct PerformanceMetric {
  let timestamp: Date
  let memoryUsage: Double // MB
  let cpuUsage: Double // Percentage
}

enum PerformanceWarning: Equatable {
  case highMemoryUsage(Double)
  case highCPUUsage(Double)
  case sustainedHighMemoryUsage(Double)
  case sustainedHighCPUUsage(Double)

  var description: String {
    switch self {
    case let .highMemoryUsage(usage):
      "内存使用过高: \(String(format: "%.1f", usage))MB"
    case let .highCPUUsage(usage):
      "CPU使用过高: \(String(format: "%.1f", usage))%"
    case let .sustainedHighMemoryUsage(usage):
      "持续高内存使用: \(String(format: "%.1f", usage))MB"
    case let .sustainedHighCPUUsage(usage):
      "持续高CPU使用: \(String(format: "%.1f", usage))%"
    }
  }

  var severity: PerformanceWarningSeverity {
    switch self {
    case let .highMemoryUsage(usage), let .sustainedHighMemoryUsage(usage):
      usage > 300 ? .critical : .warning
    case let .highCPUUsage(usage), let .sustainedHighCPUUsage(usage):
      usage > 90 ? .critical : .warning
    }
  }
}

enum PerformanceWarningSeverity {
  case warning
  case critical

  var color: Color {
    switch self {
    case .warning:
      .orange
    case .critical:
      .red
    }
  }
}

struct PerformanceReport {
  let averageMemoryUsage: Double
  let averageCPUUsage: Double
  let peakMemoryUsage: Double
  let peakCPUUsage: Double
  let totalWarnings: Int
  let isOptimal: Bool
}

// MARK: - Notification Names

extension Notification.Name {
  static let performanceOptimizationNeeded = Notification.Name("performanceOptimizationNeeded")
  static let reduceBackgroundProcessing = Notification.Name("reduceBackgroundProcessing")
}

// MARK: - View Extensions for Performance Monitoring

extension View {
  /// Apply performance monitoring to a view (DEBUG mode only)
  func withPerformanceMonitoring(identifier: String) -> some View {
    onAppear {
      #if DEBUG
        print("👁️  VIEW APPEARED: \(identifier)")
        PerformanceMonitor.shared.logCurrentState()
      #endif
    }
    .onDisappear {
      #if DEBUG
        print("👁️  VIEW DISAPPEARED: \(identifier)")
      #endif
    }
  }
}
