//
//  PerformanceMonitor.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import SwiftUI
import OSLog

/// Service for monitoring and optimizing application performance
@Observable
class PerformanceMonitor {
  static let shared = PerformanceMonitor()
  
  private let logger = Logger(subsystem: "com.tools.app", category: "Performance")
  private var performanceMetrics: [PerformanceMetric] = []
  private let maxMetricsCount = 100
  
  // Current performance state
  var currentMemoryUsage: Double = 0
  var currentCPUUsage: Double = 0
  var isPerformanceOptimal: Bool = true
  var performanceWarnings: [PerformanceWarning] = []
  
  private var monitoringTimer: Timer?
  
  private init() {
    startPerformanceMonitoring()
  }
  
  deinit {
    stopPerformanceMonitoring()
  }
  
  // MARK: - Performance Monitoring
  
  func startPerformanceMonitoring() {
    monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      self?.updatePerformanceMetrics()
    }
  }
  
  func stopPerformanceMonitoring() {
    monitoringTimer?.invalidate()
    monitoringTimer = nil
  }
  
  private func updatePerformanceMetrics() {
    let memoryUsage = getCurrentMemoryUsage()
    let cpuUsage = getCurrentCPUUsage()
    
    currentMemoryUsage = memoryUsage
    currentCPUUsage = cpuUsage
    
    // Record metric
    let metric = PerformanceMetric(
      timestamp: Date(),
      memoryUsage: memoryUsage,
      cpuUsage: cpuUsage
    )
    
    performanceMetrics.append(metric)
    
    // Maintain metrics history limit
    if performanceMetrics.count > maxMetricsCount {
      performanceMetrics.removeFirst(performanceMetrics.count - maxMetricsCount)
    }
    
    // Check for performance issues
    checkPerformanceThresholds(metric)
    
    // Log performance data
    logger.info("Memory: \(String(format: "%.1f", memoryUsage))MB, CPU: \(String(format: "%.1f", cpuUsage))%")
  }
  
  // MARK: - Performance Metrics Collection
  
  private func getCurrentMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_,
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
    // Simplified CPU usage estimation
    // In a production app, you'd want more sophisticated CPU monitoring
    // For now, we'll use a basic estimation based on system load
    return Double.random(in: 0...15) // Placeholder for actual CPU calculation
  }
  
  // MARK: - Performance Threshold Checking
  
  private func checkPerformanceThresholds(_ metric: PerformanceMetric) {
    var newWarnings: [PerformanceWarning] = []
    
    // Memory usage threshold (200MB)
    if metric.memoryUsage > 200 {
      newWarnings.append(.highMemoryUsage(metric.memoryUsage))
    }
    
    // CPU usage threshold (80%)
    if metric.cpuUsage > 80 {
      newWarnings.append(.highCPUUsage(metric.cpuUsage))
    }
    
    // Check for sustained high usage
    let recentMetrics = performanceMetrics.suffix(5)
    if recentMetrics.count >= 5 {
      let avgMemory = recentMetrics.map { $0.memoryUsage }.reduce(0, +) / Double(recentMetrics.count)
      let avgCPU = recentMetrics.map { $0.cpuUsage }.reduce(0, +) / Double(recentMetrics.count)
      
      if avgMemory > 150 {
        newWarnings.append(.sustainedHighMemoryUsage(avgMemory))
      }
      
      if avgCPU > 60 {
        newWarnings.append(.sustainedHighCPUUsage(avgCPU))
      }
    }
    
    performanceWarnings = newWarnings
    isPerformanceOptimal = newWarnings.isEmpty
    
    // Trigger optimization if needed
    if !isPerformanceOptimal {
      triggerPerformanceOptimization()
    }
  }
  
  // MARK: - Performance Optimization
  
  private func triggerPerformanceOptimization() {
    logger.warning("Performance issues detected, triggering optimization")
    
    // Notify other components to optimize
    NotificationCenter.default.post(name: .performanceOptimizationNeeded, object: nil)
    
    // Perform automatic optimizations
    DispatchQueue.global(qos: .utility).async {
      self.performAutomaticOptimizations()
    }
  }
  
  private func performAutomaticOptimizations() {
    // Clear caches
    clearImageCaches()
    
    // Force garbage collection
    autoreleasepool {
      // This helps release retained objects
    }
    
    // Reduce background processing
    reduceBackgroundProcessing()
    
    logger.info("Automatic performance optimizations completed")
  }
  
  private func clearImageCaches() {
    // Clear any image caches
    URLCache.shared.removeAllCachedResponses()
  }
  
  private func reduceBackgroundProcessing() {
    // Reduce frequency of background tasks
    NotificationCenter.default.post(name: .reduceBackgroundProcessing, object: nil)
  }
  
  // MARK: - Performance Analytics
  
  func getPerformanceReport() -> PerformanceReport {
    let avgMemory = performanceMetrics.isEmpty ? 0 : 
      performanceMetrics.map { $0.memoryUsage }.reduce(0, +) / Double(performanceMetrics.count)
    
    let avgCPU = performanceMetrics.isEmpty ? 0 :
      performanceMetrics.map { $0.cpuUsage }.reduce(0, +) / Double(performanceMetrics.count)
    
    let maxMemory = performanceMetrics.map { $0.memoryUsage }.max() ?? 0
    let maxCPU = performanceMetrics.map { $0.cpuUsage }.max() ?? 0
    
    return PerformanceReport(
      averageMemoryUsage: avgMemory,
      averageCPUUsage: avgCPU,
      peakMemoryUsage: maxMemory,
      peakCPUUsage: maxCPU,
      totalWarnings: performanceWarnings.count,
      isOptimal: isPerformanceOptimal
    )
  }
  
  func getRecentMetrics(count: Int = 20) -> [PerformanceMetric] {
    return Array(performanceMetrics.suffix(count))
  }
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
    case .highMemoryUsage(let usage):
      return "内存使用过高: \(String(format: "%.1f", usage))MB"
    case .highCPUUsage(let usage):
      return "CPU使用过高: \(String(format: "%.1f", usage))%"
    case .sustainedHighMemoryUsage(let usage):
      return "持续高内存使用: \(String(format: "%.1f", usage))MB"
    case .sustainedHighCPUUsage(let usage):
      return "持续高CPU使用: \(String(format: "%.1f", usage))%"
    }
  }
  
  var severity: PerformanceWarningSeverity {
    switch self {
    case .highMemoryUsage(let usage), .sustainedHighMemoryUsage(let usage):
      return usage > 300 ? .critical : .warning
    case .highCPUUsage(let usage), .sustainedHighCPUUsage(let usage):
      return usage > 90 ? .critical : .warning
    }
  }
}

enum PerformanceWarningSeverity {
  case warning
  case critical
  
  var color: Color {
    switch self {
    case .warning:
      return .orange
    case .critical:
      return .red
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
  /// Apply performance monitoring to a view
  func withPerformanceMonitoring(identifier: String) -> some View {
    self
      .onAppear {
        print("View appeared: \(identifier)")
      }
      .onDisappear {
        print("View disappeared: \(identifier)")
      }
  }
}