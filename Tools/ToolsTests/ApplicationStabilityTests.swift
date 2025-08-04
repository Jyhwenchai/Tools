//
//  ApplicationStabilityTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/21.
//

import Foundation
import Testing

@testable import Tools

struct ApplicationStabilityTests {
  @Test("应用稳定性监控初始化")
  func stabilityMonitorInitialization() {
    let monitor = ApplicationStabilityMonitor.shared

    // 验证监控器已正确初始化
    let report = monitor.getStabilityReport()

    #expect(report.uptime > 0)
    #expect(report.memoryUsage > 0)
    #expect(!report.thermalState.isEmpty)
  }

  @Test("内存使用报告")
  func memoryUsageReporting() {
    let monitor = ApplicationStabilityMonitor.shared

    // 获取初始内存使用
    let initialReport = monitor.getStabilityReport()
    let initialMemory = initialReport.memoryUsage

    // 分配一些内存
    var data: [Data] = []
    for _ in 1...10 {
      data.append(Data(count: 1024 * 1024))  // 1MB each
    }

    // 获取更新后的内存使用
    let updatedReport = monitor.getStabilityReport()
    let updatedMemory = updatedReport.memoryUsage

    // 验证内存使用增加
    #expect(updatedMemory >= initialMemory)

    // 清理内存
    data.removeAll()
  }

  @Test("稳定性报告格式化")
  func stabilityReportFormatting() {
    let report = StabilityReport(
      uptime: 3665,  // 1h 1m 5s
      memoryUsage: 256.5,
      thermalState: "正常",
      lastCrashDate: nil,
      memoryPressureDetected: false)

    // 验证运行时间格式化
    #expect(report.formattedUptime.contains("h"))
    #expect(report.formattedUptime.contains("m"))
  }

  @Test("热状态描述")
  func thermalStateDescription() {
    #expect(ProcessInfo.ThermalState.nominal.description == "正常")
    #expect(ProcessInfo.ThermalState.fair.description == "良好")
    #expect(ProcessInfo.ThermalState.serious.description == "严重")
    #expect(ProcessInfo.ThermalState.critical.description == "临界")
  }

  @Test("崩溃检测")
  func crashDetection() {
    // 模拟未清理退出
    UserDefaults.standard.set(false, forKey: "clean_exit")

    // 设置最近的心跳时间
    let recentHeartbeat = Date().timeIntervalSince1970 - 60  // 1 minute ago
    UserDefaults.standard.set(recentHeartbeat, forKey: "last_heartbeat")

    // 使用共享实例检测崩溃
    let monitor = ApplicationStabilityMonitor.shared

    // 验证崩溃日期已设置
    #expect(monitor.lastCrashDate != nil)

    // 清理测试数据
    UserDefaults.standard.removeObject(forKey: "clean_exit")
    UserDefaults.standard.removeObject(forKey: "last_heartbeat")
    UserDefaults.standard.removeObject(forKey: "last_crash_timestamp")
  }
}
