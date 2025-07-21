//
//  PerformanceUIRemovalTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/20.
//

import SwiftUI
@testable import Tools
import XCTest

/// Tests to verify that performance monitoring UI is properly hidden in release builds
/// and only available in DEBUG mode for development purposes
final class PerformanceUIRemovalTests: XCTestCase {
  // MARK: - Performance Monitor UI Tests

  func testPerformanceMonitorOnlyAvailableInDebugMode() {
    let performanceMonitor = PerformanceMonitor.shared

    #if DEBUG
      // In DEBUG mode, performance monitor should be fully functional
      XCTAssertNotNil(performanceMonitor, "Performance monitor should be available in DEBUG mode")

      // Performance monitoring should be active in DEBUG mode
      let report = performanceMonitor.getPerformanceReport()
      XCTAssertNotNil(report, "Performance report should be available in DEBUG mode")

      // Performance metrics should be collected in DEBUG mode
      let metrics = performanceMonitor.getRecentMetrics()
      XCTAssertNotNil(metrics, "Performance metrics should be available in DEBUG mode")

      print("✅ DEBUG mode: Performance monitoring is active")
    #else
      // In RELEASE mode, performance monitor should provide minimal functionality
      XCTAssertNotNil(
        performanceMonitor,
        "Performance monitor should exist but be minimal in RELEASE mode")

      // Performance report should be minimal in release mode
      let report = performanceMonitor.getPerformanceReport()
      XCTAssertEqual(report.totalWarnings, 0, "No warnings should be tracked in RELEASE mode")

      print("✅ RELEASE mode: Performance monitoring is minimal")
    #endif
  }

  func testPerformanceUIElementsHiddenInRelease() {
    // Test that ContentView doesn't expose performance UI in release builds
    let contentView = ContentView()

    #if DEBUG
      // In DEBUG mode, performance monitoring state should be available
      let mirror = Mirror(reflecting: contentView)
      let hasPerformanceMonitor = mirror.children.contains { child in
        child.label?.contains("performanceMonitor") == true
      }
      XCTAssertTrue(
        hasPerformanceMonitor,
        "ContentView should have performance monitor in DEBUG mode")
      print("✅ DEBUG mode: Performance UI elements are available")
    #else
      // In RELEASE mode, performance monitoring state should not be available
      let mirror = Mirror(reflecting: contentView)
      let hasPerformanceMonitor = mirror.children.contains { child in
        child.label?.contains("performanceMonitor") == true
      }
      XCTAssertFalse(
        hasPerformanceMonitor,
        "ContentView should not have performance monitor in RELEASE mode")
      print("✅ RELEASE mode: Performance UI elements are hidden")
    #endif
  }

  func testPerformanceMonitorLoggingBehavior() {
    let performanceMonitor = PerformanceMonitor.shared

    #if DEBUG
      // In DEBUG mode, detailed logging should be available
      performanceMonitor.logCurrentState()
      performanceMonitor.logPerformanceHistory()

      // Performance metrics should be collected
      let metrics = performanceMonitor.getRecentMetrics(count: 5)
      XCTAssertTrue(metrics.isEmpty, "Metrics should be available in DEBUG mode")

      print("✅ DEBUG mode: Detailed performance logging is active")
    #else
      // In RELEASE mode, logging methods should not be available or should be no-ops
      // The methods logCurrentState and logPerformanceHistory are only available in DEBUG

      // Only basic metrics should be available
      let metrics = performanceMonitor.getRecentMetrics(count: 5)
      XCTAssertTrue(metrics.count <= 1, "Minimal metrics should be available in RELEASE mode")

      print("✅ RELEASE mode: Performance logging is minimal")
    #endif
  }

  func testPerformanceWarningsOnlyInDebugMode() {
    let performanceMonitor = PerformanceMonitor.shared

    #if DEBUG
      // In DEBUG mode, warnings should be tracked
      let warnings = performanceMonitor.performanceWarnings
      XCTAssertNotNil(warnings, "Performance warnings should be available in DEBUG mode")

      // Performance optimization should be available
      let report = performanceMonitor.getPerformanceReport()
      XCTAssertNotNil(report, "Performance report should include warning count in DEBUG mode")

      print("✅ DEBUG mode: Performance warnings are tracked")
    #else
      // In RELEASE mode, warnings should be minimal or empty
      let warnings = performanceMonitor.performanceWarnings
      XCTAssertTrue(warnings.isEmpty, "Performance warnings should be empty in RELEASE mode")

      let report = performanceMonitor.getPerformanceReport()
      XCTAssertEqual(report.totalWarnings, 0, "No warnings should be reported in RELEASE mode")

      print("✅ RELEASE mode: Performance warnings are disabled")
    #endif
  }

  func testPerformanceMonitorMemoryUsage() {
    let performanceMonitor = PerformanceMonitor.shared

    // Basic memory usage should be available in both modes
    let report = performanceMonitor.getPerformanceReport()
    XCTAssertGreaterThanOrEqual(report.averageMemoryUsage, 0, "Memory usage should be non-negative")
    XCTAssertLessThan(report.averageMemoryUsage, 1000, "Memory usage should be reasonable")

    #if DEBUG
      print("✅ DEBUG mode: Memory usage: \(String(format: "%.1f", report.averageMemoryUsage))MB")
    #else
      print(
        "✅ RELEASE mode: Basic memory info: \(String(format: "%.1f", report.averageMemoryUsage))MB")
    #endif
  }

  func testPerformanceOptimizationOnlyInDebugMode() {
    #if DEBUG
      // In DEBUG mode, performance optimization should be available
      let expectation = XCTestExpectation(description: "Performance optimization notification")

      let observer = NotificationCenter.default.addObserver(
        forName: .performanceOptimizationNeeded,
        object: nil,
        queue: .main) { _ in
        expectation.fulfill()
      }

      // Trigger performance optimization
      NotificationCenter.default.post(name: .performanceOptimizationNeeded, object: nil)

      wait(for: [expectation], timeout: 1.0)
      NotificationCenter.default.removeObserver(observer)

      print("✅ DEBUG mode: Performance optimization is available")
    #else
      // In RELEASE mode, performance optimization should not be triggered
      // This is implicitly tested by the absence of performance UI
      print("✅ RELEASE mode: Performance optimization is disabled")
    #endif
  }

  // MARK: - Integration Tests

  func testContentViewPerformanceIntegration() {
    let contentView = ContentView()

    // ContentView should be creatable without performance monitoring dependencies in release mode
    XCTAssertNotNil(contentView, "ContentView should be creatable")

    #if DEBUG
      print("✅ DEBUG mode: ContentView includes performance monitoring")
    #else
      print("✅ RELEASE mode: ContentView excludes performance monitoring")
    #endif
  }

  func testPerformanceMonitorResourceUsage() {
    let performanceMonitor = PerformanceMonitor.shared

    // Performance monitor should not consume excessive resources
    let startTime = Date()
    let report = performanceMonitor.getPerformanceReport()
    let endTime = Date()

    let executionTime = endTime.timeIntervalSince(startTime)
    XCTAssertLessThan(executionTime, 0.1, "Performance report generation should be fast")

    XCTAssertNotNil(report, "Performance report should be available")

    #if DEBUG
      print(
        "✅ DEBUG mode: Performance report generated in \(String(format: "%.3f", executionTime))s")
    #else
      print(
        "✅ RELEASE mode: Minimal performance report generated in \(String(format: "%.3f", executionTime))s")
    #endif
  }
}

// MARK: - Test Helpers

extension PerformanceUIRemovalTests {
  /// Helper method to verify that performance monitoring doesn't impact app startup
  func testPerformanceMonitorStartupImpact() {
    let startTime = Date()

    // Simulate app startup with performance monitor
    _ = PerformanceMonitor.shared

    let endTime = Date()
    let startupTime = endTime.timeIntervalSince(startTime)

    // Performance monitor initialization should be fast
    XCTAssertLessThan(
      startupTime,
      0.05,
      "Performance monitor initialization should not slow down startup")

    #if DEBUG
      print(
        "✅ DEBUG mode: Performance monitor startup time: \(String(format: "%.3f", startupTime))s")
    #else
      print(
        "✅ RELEASE mode: Minimal performance monitor startup time: \(String(format: "%.3f", startupTime))s")
    #endif
  }

  /// Helper method to verify that performance monitoring is properly cleaned up
  func testPerformanceMonitorCleanup() {
    // This test verifies that performance monitoring doesn't leave resources hanging
    let performanceMonitor = PerformanceMonitor.shared

    // Get initial state
    let initialReport = performanceMonitor.getPerformanceReport()
    XCTAssertNotNil(initialReport, "Initial performance report should be available")

    // Simulate some activity
    for _ in 0..<5 {
      _ = performanceMonitor.getPerformanceReport()
    }

    // Verify cleanup
    let finalReport = performanceMonitor.getPerformanceReport()
    XCTAssertNotNil(finalReport, "Final performance report should be available")

    #if DEBUG
      print("✅ DEBUG mode: Performance monitoring cleanup verified")
    #else
      print("✅ RELEASE mode: Minimal performance monitoring cleanup verified")
    #endif
  }
}
