//
//  LongRunningStabilityTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/21.
//

import Foundation
import SwiftUI
import Testing
@testable import Tools

struct LongRunningStabilityTests {
  @Test("长时间运行稳定性测试", timeout: .seconds(30))
  func longRunningStability() async {
    // 初始化稳定性监控
    let stabilityMonitor = ApplicationStabilityMonitor.shared
    let initialReport = stabilityMonitor.getStabilityReport()

    print("初始内存使用: \(initialReport.memoryUsage)MB")

    // 执行多个并发操作
    await withTaskGroup(of: Void.self) { group in
      // 添加多个并发任务
      for index in 1...5 {
        group.addTask {
          await runStabilityTestOperations(iteration: i)
        }
      }
    }

    // 获取最终稳定性报告
    let finalReport = stabilityMonitor.getStabilityReport()
    print("最终内存使用: \(finalReport.memoryUsage)MB")

    // 验证应用在高负载下仍然稳定
    #expect(finalReport.memoryUsage < initialReport.memoryUsage + 200) // 内存增长不超过200MB
  }

  private func runStabilityTestOperations(iteration: Int) async {
    // 执行一系列操作来测试稳定性
    for subIndex in 1...20 {
      // 根据迭代选择不同的操作
      switch (iteration + j) % 5 {
      case 0:
        // 图像处理操作
        await testImageProcessing()
      case 1:
        // 加密操作
        await testEncryption()
      case 2:
        // JSON处理
        testJSONProcessing()
      case 3:
        // 时间转换
        testTimeConversion()
      case 4:
        // QR码生成
        await testQRCodeGeneration()
      default:
        break
      }

      // 短暂暂停，避免过度负载
      try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
  }

  // MARK: - 测试操作

  func testImageProcessing() async {
    let service = ImageProcessingService()

    // 创建测试图像
    let size = CGSize(width: 100, height: 100)
    let renderer = NSImage.Renderer(size: size)
    let image = renderer.image { context in
      NSColor.red.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }

    guard let imageData = image.tiffRepresentation else { return }

    // 执行图像处理操作
    _ = try? await service.resizeImage(
      imageData: imageData,
      targetSize: CGSize(width: 50, height: 50))
  }

  func testEncryption() async {
    let service = EncryptionService()
    let testData = "测试加密数据".data(using: .utf8)!

    // 加密
    guard let encryptedData = try? service.encryptData(testData, withPassword: "test") else {
      return
    }

    // 解密
    _ = try? service.decryptData(encryptedData, withPassword: "test")
  }

  func testJSONProcessing() {
    let service = JSONService()
    let testJSON = """
    {
      "name": "测试",
      "value": 123,
      "items": [1, 2, 3]
    }
    """

    // 格式化JSON
    _ = try? service.formatJSON(testJSON)

    // 压缩JSON
    _ = try? service.minifyJSON(testJSON)
  }

  func testTimeConversion() {
    let service = TimeConverterService()

    // 时间戳转换
    _ = service.convertTimestamp(1_626_912_000, from: .seconds, to: .milliseconds)

    // 日期格式转换
    _ = try? service.convertDateFormat(
      "2025-07-21",
      fromFormat: "yyyy-MM-dd",
      toFormat: "MM/dd/yyyy")
  }

  func testQRCodeGeneration() async {
    let service = QRCodeService()

    // 生成QR码
    _ = try? await service.generateQRCode(
      from: "https://example.com",
      size: CGSize(width: 200, height: 200),
      color: NSColor.black)
  }
}
