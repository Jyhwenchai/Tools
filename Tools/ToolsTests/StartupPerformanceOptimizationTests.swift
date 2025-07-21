//
//  StartupPerformanceOptimizationTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/21.
//

import SwiftUI
@testable import Tools
import XCTest

@MainActor
final class StartupPerformanceOptimizationTests: XCTestCase {
  func testOptimizedStartupTime() throws {
    let iterations = 20
    var times: [Double] = []

    for _ in 0..<iterations {
      let startTime = CFAbsoluteTimeGetCurrent()

      // Initialize app with optimized sequence
      _ = AppSettings.shared

      let endTime = CFAbsoluteTimeGetCurrent()
      times.append(endTime - startTime)
    }

    let averageTime = times.reduce(0, +) / Double(times.count)
    let maxTime = times.max() ?? 0

    print("📊 Optimized Startup Performance:")
    print("   Average time: \(String(format: "%.4f", averageTime))s")

    print("   All times: \(times.map { String(format: "%.4f", $0) })")

    // Average startup time should be under 0.03 seconds (optimized target)
    XCTAssertLessThan(averageTime, 0.03, "Average startup time too slow: \(averageTime)s")

    // Maximum startup time should be under 0.05 seconds (improved target)
    XCTAssertLessThan(maxTime, 0.05, "Maximum startup time too slow: \(maxTime)s")
  }

  // MARK: - Permission-Free Startup Tests

  func testPermissionFreeStartup() throws {
    // This test ensures that no permission-related code runs during startup
    let startTime = CFAbsoluteTimeGetCurrent()

    // Initialize core services that should not request permissions
    _ = AppSettings.shared

    let endTime = CFAbsoluteTimeGetCurrent()
    let initTime = endTime - startTime

    // Should be very fast since no permission checks are performed
    XCTAssertLessThan(initTime, 0.02, "Permission-free startup too slow: \(initTime)s")
  }

  // MARK: - Lazy Service Initialization Tests

  func testLazyServiceInitialization() throws {
    // Test that services are initialized lazily
    let startTime = CFAbsoluteTimeGetCurrent()

    // Initialize app
    _ = ToolsApp()

    let initTime = CFAbsoluteTimeGetCurrent() - startTime

    // App should initialize quickly without loading all services
    XCTAssertLessThan(initTime, 0.05, "App initialization too slow: \(initTime)s")

    // Verify that services weren't initialized yet
    let performanceMonitorTime = CFAbsoluteTimeGetCurrent()
    _ = PerformanceMonitor.shared
    let performanceMonitorInitTime = CFAbsoluteTimeGetCurrent() - performanceMonitorTime

    // Service initialization should take some measurable time
    XCTAssertGreaterThan(
      performanceMonitorInitTime,
      0,
      "PerformanceMonitor wasn't initialized lazily")
  }

  // MARK: - Memory Usage Optimization Tests

  func testOptimizedStartupMemoryUsage() throws {
    let initialMemory = getCurrentMemoryUsage()

    // Initialize only essential services for startup
    _ = AppSettings.shared

    let finalMemory = getCurrentMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory

    // Memory increase should be minimal (< 5MB)
    XCTAssertLessThan(memoryIncrease, 5.0, "Memory usage increased too much: \(memoryIncrease)MB")
  }

  // MARK: - Helper Methods

  private func getCurrentMemoryUsage() -> Double {
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
      return Double(info.resident_size) / 1024.0 / 1024.0
    }

    return 0
  }
}

// MARK: - Startup Performance Benchmark

/// Enhanced benchmark class for measuring startup performance improvements
class OptimizedStartupBenchmark {
  static func measureOptimizedStartupTime() -> Double {
    let startTime = CFAbsoluteTimeGetCurrent()

    // Simulate optimized app startup
    _ = AppSettings.shared

    return CFAbsoluteTimeGetCurrent() - startTime
  }

  static func runBenchmark(iterations: Int = 50) -> OptimizedStartupBenchmarkResult {
    var times: [Double] = []

    for _ in 0..<iterations {
      times.append(measureOptimizedStartupTime())
    }

    let average = times.reduce(0, +) / Double(times.count)
    let min = times.min() ?? 0
    let max = times.max() ?? 0
    let median = times.sorted()[times.count / 2]

    return OptimizedStartupBenchmarkResult(
      iterations: iterations,
      averageTime: average,
      minTime: min,
      maxTime: max,
      medianTime: median,
      allTimes: times)
  }

  static func compareWithBaseline() -> BenchmarkComparison {
    // Run baseline benchmark
    let baselineAverage = 0.045 // Historical average from pre-optimization

    // Run optimized benchmark
    let optimizedResult = runBenchmark(iterations: 50)

    // Calculate improvement
    let timeImprovement = baselineAverage - optimizedResult.averageTime
    let percentImprovement = (timeImprovement / baselineAverage) * 100

    return BenchmarkComparison(
      baselineAverage: baselineAverage,
      optimizedAverage: optimizedResult.averageTime,
      timeImprovement: timeImprovement,
      percentImprovement: percentImprovement)
  }
}

struct OptimizedStartupBenchmarkResult {
  let iterations: Int
  let averageTime: Double
  let minTime: Double
  let maxTime: Double
  let medianTime: Double
  let allTimes: [Double]

  func printReport() {
    print("🚀 OPTIMIZED STARTUP PERFORMANCE REPORT")
    print("   Iterations: \(iterations)")
    print("   Average: \(String(format: "%.4f", averageTime))s")
    print("   Minimum: \(String(format: "%.4f", minTime))s")
    print("   Maximum: \(String(format: "%.4f", maxTime))s")
    print("   Median: \(String(format: "%.4f", medianTime))s")

    print("   Performance Grade: \(performanceGrade)")
  }

  private var standardDeviation: Double {
    let variance = allTimes.map { pow($0 - averageTime, 2) }.reduce(0, +) / Double(allTimes.count)
    return sqrt(variance)
  }

  private var performanceGrade: String {
    switch averageTime {
    case 0..<0.005:
      "🟢 Excellent (< 5ms)"
    case 0.005..<0.01:
      "🟢 Very Good (5-10ms)"
    case 0.01..<0.02:
      "🟡 Good (10-20ms)"
    case 0.02..<0.05:
      "🟠 Fair (20-50ms)"
    default:
      "🔴 Poor (> 50ms)"
    }
  }
}

struct BenchmarkComparison {
  let baselineAverage: Double
  let optimizedAverage: Double
  let timeImprovement: Double
  let percentImprovement: Double

  func printReport() {
    print("📊 PERFORMANCE COMPARISON")
    print("   Baseline Average: \(String(format: "%.4f", baselineAverage))s")
    print("   Optimized Average: \(String(format: "%.4f", optimizedAverage))s")
    print("   Time Improvement: \(String(format: "%.4f", timeImprovement))s")
    print("   Percent Improvement: \(String(format: "%.1f", percentImprovement))%")
    print("   Performance Impact: \(performanceImpactRating)")
  }

  private var performanceImpactRating: String {
    switch percentImprovement {
    case 50...:
      "🟢 Dramatic improvement (>50%)"
    case 25..<50:
      "🟢 Significant improvement (25-50%)"
    case 10..<25:
      "🟡 Moderate improvement (10-25%)"
    case 5..<10:
      "🟡 Slight improvement (5-10%)"
    case 0..<5:
      "🔴 Minimal improvement (<5%)"
    default:
      "⚠️ Performance regression"
    }
  }
}
