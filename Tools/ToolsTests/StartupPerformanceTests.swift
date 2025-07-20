//
//  StartupPerformanceTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/20.
//

import XCTest
import SwiftUI
@testable import Tools

/// Tests for measuring and validating application startup performance
@MainActor
final class StartupPerformanceTests: XCTestCase {
  
  // MARK: - Service Initialization Performance Tests
  
  func testPerformanceMonitorInitializationTime() throws {
    measure {
      let _ = PerformanceMonitor.shared
    }
  }
  
  func testSecurityServiceInitializationTime() throws {
    measure {
      let _ = SecurityService.shared
    }
  }
  
  func testErrorLoggingServiceInitializationTime() throws {
    measure {
      let _ = ErrorLoggingService.shared
    }
  }
  
  func testAsyncOperationManagerInitializationTime() throws {
    measure {
      let _ = AsyncOperationManager.shared
    }
  }
  
  // MARK: - App Settings Performance Tests
  
  func testAppSettingsInitializationTime() throws {
    measure {
      let _ = AppSettings.shared
    }
  }
  
  func testAppSettingsThemeAccess() throws {
    let settings = AppSettings.shared
    
    measure {
      let _ = settings.theme
      let _ = settings.theme.colorScheme
    }
  }
  
  // MARK: - Navigation Manager Performance Tests
  
  func testNavigationManagerInitializationTime() throws {
    measure {
      let _ = NavigationManager()
    }
  }
  
  // MARK: - Model Container Performance Tests
  
  func testModelContainerCreationTime() throws {
    measure {
      let schema = Schema([
        ClipboardItem.self
      ])
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      
      do {
        let _ = try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
        XCTFail("Failed to create ModelContainer: \(error)")
      }
    }
  }
  
  // MARK: - Service Lazy Loading Tests
  
  func testServicesAreLazilyInitialized() async throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Create app instance (this should be fast due to lazy loading)
    let app = ToolsApp()
    
    let initTime = CFAbsoluteTimeGetCurrent() - startTime
    
    // App initialization should be very fast (< 0.1 seconds)
    XCTAssertLessThan(initTime, 0.1, "App initialization took too long: \(initTime) seconds")
  }
  
  // MARK: - Background Initialization Tests
  
  func testBackgroundInitializationDoesNotBlockStartup() async throws {
    let expectation = XCTestExpectation(description: "Background initialization completes")
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Simulate the background initialization process
    Task.detached(priority: .background) {
      // Simulate error logging service initialization
      await ErrorLoggingService.shared.initialize()
      
      #if DEBUG
      // Simulate performance monitor startup
      PerformanceMonitor.shared.startPerformanceMonitoring()
      #endif
      
      expectation.fulfill()
    }
    
    // Main thread should not be blocked
    let mainThreadTime = CFAbsoluteTimeGetCurrent() - startTime
    XCTAssertLessThan(mainThreadTime, 0.05, "Main thread was blocked for too long: \(mainThreadTime) seconds")
    
    await fulfillment(of: [expectation], timeout: 5.0)
  }
  
  // MARK: - Memory Usage Tests
  
  func testStartupMemoryUsage() throws {
    let initialMemory = getCurrentMemoryUsage()
    
    // Initialize core services
    let _ = AppSettings.shared
    let _ = NavigationManager()
    let _ = PerformanceMonitor.shared
    let _ = SecurityService.shared
    let _ = ErrorLoggingService.shared
    let _ = AsyncOperationManager.shared
    
    let finalMemory = getCurrentMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory
    
    // Memory increase should be reasonable (< 50MB)
    XCTAssertLessThan(memoryIncrease, 50.0, "Startup memory usage too high: \(memoryIncrease)MB")
  }
  
  // MARK: - Performance Regression Tests
  
  func testStartupPerformanceRegression() throws {
    let iterations = 10
    var times: [Double] = []
    
    for _ in 0..<iterations {
      let startTime = CFAbsoluteTimeGetCurrent()
      
      // Simulate app startup sequence
      let _ = AppSettings.shared
      let _ = NavigationManager()
      let _ = PerformanceMonitor.shared
      let _ = SecurityService.shared
      let _ = ErrorLoggingService.shared
      let _ = AsyncOperationManager.shared
      
      let endTime = CFAbsoluteTimeGetCurrent()
      times.append(endTime - startTime)
    }
    
    let averageTime = times.reduce(0, +) / Double(times.count)
    let maxTime = times.max() ?? 0
    
    print("📊 Startup Performance Metrics:")
    print("   Average time: \(String(format: "%.4f", averageTime))s")
    print("   Maximum time: \(String(format: "%.4f", maxTime))s")
    print("   All times: \(times.map { String(format: "%.4f", $0) }.joined(separator: ", "))s")
    
    // Average startup time should be under 0.05 seconds
    XCTAssertLessThan(averageTime, 0.05, "Average startup time too slow: \(averageTime)s")
    
    // Maximum startup time should be under 0.1 seconds
    XCTAssertLessThan(maxTime, 0.1, "Maximum startup time too slow: \(maxTime)s")
  }
  
  // MARK: - Permission-Related Startup Tests
  
  func testNoPermissionChecksOnStartup() async throws {
    // This test ensures that no permission-related code runs during startup
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Initialize services that previously had permission checks
    let _ = PerformanceMonitor.shared
    let _ = SecurityService.shared
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let initTime = endTime - startTime
    
    // Should be very fast since no permission checks are performed
    XCTAssertLessThan(initTime, 0.01, "Service initialization with permission checks took too long: \(initTime)s")
  }
  
  func testClipboardServiceLazyPermissionHandling() throws {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Creating clipboard service should not trigger permission requests
    let _ = ClipboardService()
    
    let endTime = CFAbsoluteTimeGetCurrent()
    let initTime = endTime - startTime
    
    // Should be very fast since permissions are handled lazily
    XCTAssertLessThan(initTime, 0.01, "ClipboardService initialization took too long: \(initTime)s")
  }
  
  // MARK: - Concurrent Initialization Tests
  
  func testConcurrentServiceInitialization() async throws {
    let expectation = XCTestExpectation(description: "All services initialize concurrently")
    expectation.expectedFulfillmentCount = 5
    
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Initialize services concurrently
    Task.detached {
      let _ = PerformanceMonitor.shared
      expectation.fulfill()
    }
    
    Task.detached {
      let _ = SecurityService.shared
      expectation.fulfill()
    }
    
    Task.detached {
      let _ = ErrorLoggingService.shared
      expectation.fulfill()
    }
    
    Task.detached {
      let _ = AsyncOperationManager.shared
      expectation.fulfill()
    }
    
    Task.detached {
      let _ = AppSettings.shared
      expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 2.0)
    
    let totalTime = CFAbsoluteTimeGetCurrent() - startTime
    
    // Concurrent initialization should be faster than sequential
    XCTAssertLessThan(totalTime, 0.5, "Concurrent initialization took too long: \(totalTime)s")
  }
  
  // MARK: - Helper Methods
  
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
}

// MARK: - Startup Performance Benchmark

/// Benchmark class for measuring startup performance improvements
class StartupPerformanceBenchmark {
  
  static func measureStartupTime() -> Double {
    let startTime = CFAbsoluteTimeGetCurrent()
    
    // Simulate full app startup
    let _ = AppSettings.shared
    let _ = NavigationManager()
    let _ = PerformanceMonitor.shared
    let _ = SecurityService.shared
    let _ = ErrorLoggingService.shared
    let _ = AsyncOperationManager.shared
    
    return CFAbsoluteTimeGetCurrent() - startTime
  }
  
  static func runBenchmark(iterations: Int = 100) -> StartupBenchmarkResult {
    var times: [Double] = []
    
    for _ in 0..<iterations {
      times.append(measureStartupTime())
    }
    
    let average = times.reduce(0, +) / Double(times.count)
    let min = times.min() ?? 0
    let max = times.max() ?? 0
    let median = times.sorted()[times.count / 2]
    
    return StartupBenchmarkResult(
      iterations: iterations,
      averageTime: average,
      minTime: min,
      maxTime: max,
      medianTime: median,
      allTimes: times
    )
  }
}

struct StartupBenchmarkResult {
  let iterations: Int
  let averageTime: Double
  let minTime: Double
  let maxTime: Double
  let medianTime: Double
  let allTimes: [Double]
  
  func printReport() {
    print("🚀 STARTUP PERFORMANCE BENCHMARK REPORT")
    print("   Iterations: \(iterations)")
    print("   Average: \(String(format: "%.4f", averageTime))s")
    print("   Minimum: \(String(format: "%.4f", minTime))s")
    print("   Maximum: \(String(format: "%.4f", maxTime))s")
    print("   Median: \(String(format: "%.4f", medianTime))s")
    print("   Standard Deviation: \(String(format: "%.4f", standardDeviation))s")
    print("   Performance Grade: \(performanceGrade)")
  }
  
  private var standardDeviation: Double {
    let variance = allTimes.map { pow($0 - averageTime, 2) }.reduce(0, +) / Double(allTimes.count)
    return sqrt(variance)
  }
  
  private var performanceGrade: String {
    switch averageTime {
    case 0..<0.01:
      return "🟢 Excellent (< 10ms)"
    case 0.01..<0.05:
      return "🟡 Good (10-50ms)"
    case 0.05..<0.1:
      return "🟠 Fair (50-100ms)"
    default:
      return "🔴 Poor (> 100ms)"
    }
  }
}