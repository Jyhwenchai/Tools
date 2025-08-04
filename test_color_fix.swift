#!/usr/bin/env swift

import Foundation
import SwiftUI

// 测试颜色处理修复
func testColorProcessingFix() {
    print("测试颜色处理修复...")

    // 创建一个可能导致崩溃的系统颜色
    let systemColor = Color.accentColor
    let nsColor = NSColor(systemColor)

    // 测试修复后的颜色转换
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    // 使用修复后的方法：先转换颜色空间
    let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
    rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

    print("✅ 颜色转换成功！")
    print("RGB 值: R=\(red), G=\(green), B=\(blue), A=\(alpha)")

    // 测试其他系统颜色
    let colors = [
        Color.primary,
        Color.secondary,
        Color.blue,
        Color.red,
        Color.green,
    ]

    for (index, color) in colors.enumerated() {
        let nsColor = NSColor(color)
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        print(
            "颜色 \(index + 1): R=\(String(format: "%.2f", red)), G=\(String(format: "%.2f", green)), B=\(String(format: "%.2f", blue))"
        )
    }

    print("🎉 所有颜色处理测试通过！")
}

testColorProcessingFix()
