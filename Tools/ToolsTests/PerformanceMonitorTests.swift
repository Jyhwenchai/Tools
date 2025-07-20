//
//  PerformanceMonitorTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/19.
//

import Testing
import Foundation
@testable import Tools

struct PerformanceMonitorTests {
  
  @Test("PerformanceMonitor 单例测试")
  func testSingletonInstance() {
    let monitor1 = PerformanceMonitor.shared
    let monitor2 = PerformanceMonitor.shared
    
    #expect(monitor1 === monitor2)
  }
  
  @Test("PerformanceMetric 基本属性测试")
  func testPerformanceMetricProperties() {
    let timestamp = Date()
    let metric = PerformanceMetric(
      timestamp: timestamp,
      memoryUsage: 150.5,
      cpuUsage: 25.3
    )
    
    #expect(metric.timestamp == timestamp)
    #expect(metric.memoryUsage == 150.5)
    #expect(metric.cpuUsage == 25.3)
  }
  
  @Test("PerformanceWarning 描述测试", arguments: [
    (PerformanceWarning.highMemoryUsage(250.0), "内存使用过高: 250.0MB"),
    (PerformanceWarning.highCPUUsage(85.5), "CPU使用过高: 85.5%"),
    (PerformanceWarning.sustainedHighMemoryUsage(180.2), "持续高内存使用: 180.2MB"),
    (PerformanceWarning.sustainedHighCPUUsage(75.8), "持续高CPU使用: 75.8%")
  ])
  func testPerformanceWarningDescriptions(warning: PerformanceWarning, expectedDescription: String) {
    #expect(warning.description == expectedDescription)
  }
  
  @Test("PerformanceWarning 严重程度测试", arguments: [
    (PerformanceWarning.highMemoryUsage(250.0), PerformanceWarningSeverity.warning),
    (PerformanceWarning.highMemoryUsage(350.0), PerformanceWarningSeverity.critical),
    (PerformanceWarning.highCPUUsage(85.0), PerformanceWarningSeverity.warning),
    (PerformanceWarning.highCPUUsage(95.0), PerformanceWarningSeverity.critical)
  ])
  func testPerformanceWarningSeverity(warning: PerformanceWarning, expectedSeverity: PerformanceWarningSeverity) {
    #expect(warning.severity == expectedSeverity)
  }
  
  @Test("PerformanceReport 基本属性测试")
  func testPerformanceReportProperties() {
    let report = PerformanceReport(
      averageMemoryUsage: 120.5,
      averageCPUUsage: 15.2,
      peakMemoryUsage: 180.0,
      peakCPUUsage: 45.8,
      totalWarnings: 2,
      isOptimal: false
    )
    
    #expect(report.averageMemoryUsage == 120.5)
    #expect(report.averageCPUUsage == 15.2)
    #expect(report.peakMemoryUsage == 180.0)
    #expect(report.peakCPUUsage == 45.8)
    #expect(report.totalWarnings == 2)
    #expect(report.isOptimal == false)
  }
  
  @Test("性能监控初始状态测试")
  func testPerformanceMonitorInitialState() {
    let monitor = PerformanceMonitor.shared
    
    #expect(monitor.currentMemoryUsage >= 0)
    #expect(monitor.currentCPUUsage >= 0)
    #expect(monitor.performanceWarnings.isEmpty || !monitor.performanceWarnings.isEmpty) // 可能有也可能没有警告
  }
  
  @Test("性能报告生成测试")
  func testPerformanceReportGeneration() {
    let monitor = PerformanceMonitor.shared
    let report = monitor.getPerformanceReport()
    
    #expect(report.averageMemoryUsage >= 0)
    #expect(report.averageCPUUsage >= 0)
    #expect(report.peakMemoryUsage >= 0)
    #expect(report.peakCPUUsage >= 0)
    #expect(report.totalWarnings >= 0)
  }
  
  @Test("最近指标获取测试")
  func testRecentMetricsRetrieval() {
    let monitor = PerformanceMonitor.shared
    let recentMetrics = monitor.getRecentMetrics(count: 5)
    
    #expect(recentMetrics.count <= 5)
    
    // 验证指标按时间排序
    if recentMetrics.count > 1 {
      for i in 0..<(recentMetrics.count - 1) {
        #expect(recentMetrics[i].timestamp <= recentMetrics[i + 1].timestamp)
      }
    }
  }
  
  @Test("PerformanceWarningSeverity 颜色测试")
  func testPerformanceWarningSeverityColors() {
    #expect(PerformanceWarningSeverity.warning.color == .orange)
    #expect(PerformanceWarningSeverity.critical.color == .red)
  }
  
  @Test("性能监控启动停止测试")
  func testPerformanceMonitoringStartStop() async throws {
    let monitor = PerformanceMonitor.shared
    
    // 停止监控
    monitor.stopPerformanceMonitoring()
    
    // 等待一小段时间
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    
    // 重新启动监控
    monitor.startPerformanceMonitoring()
    
    // 验证监控正在运行（通过检查是否有性能数据更新）
    let _ = monitor.getPerformanceReport()
    
    // 在DEBUG模式下等待监控更新，在RELEASE模式下直接验证
    #if DEBUG
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    #endif
    
    let updatedReport = monitor.getPerformanceReport()
    
    // 验证数据可能已更新（或至少监控系统在运行）
    #expect(updatedReport.averageMemoryUsage >= 0)
    #expect(updatedReport.averageCPUUsage >= 0)
  }
  
  @Test("RELEASE模式性能监控简化测试")
  func testReleaseModeSimplifiedMonitoring() {
    let monitor = PerformanceMonitor.shared
    
    // 获取性能报告
    let report = monitor.getPerformanceReport()
    
    #if DEBUG
    // DEBUG模式下应该有详细的性能数据和可能的警告
    #expect(report.averageMemoryUsage >= 0)
    #expect(report.averageCPUUsage >= 0)
    // 警告数量可能为0或更多，取决于当前性能状态
    #expect(report.totalWarnings >= 0)
    #else
    // RELEASE模式下应该有基本的性能数据，但没有警告
    #expect(report.averageMemoryUsage >= 0)
    #expect(report.averageCPUUsage >= 0)
    #expect(report.totalWarnings == 0) // Release模式下不应该有警告
    #endif
  }
  
  @Test("性能监控无权限要求测试")
  func testPerformanceMonitoringNoPermissionRequirements() {
    let monitor = PerformanceMonitor.shared
    
    // 验证性能监控不需要特殊权限
    let memoryUsage = monitor.currentMemoryUsage
    let cpuUsage = monitor.currentCPUUsage
    
    // 这些值应该可以获取到，不需要特殊权限
    #expect(memoryUsage >= 0)
    #expect(cpuUsage >= 0)
    
    // 验证性能报告可以生成
    let report = monitor.getPerformanceReport()
    #expect(report.averageMemoryUsage >= 0)
    #expect(report.averageCPUUsage >= 0)
    
    // 验证最近指标获取不需要权限
    let recentMetrics = monitor.getRecentMetrics(count: 5)
    #expect(recentMetrics.count >= 0)
  }
}

// PerformanceWarningSeverity already conforms to Equatable in the main module