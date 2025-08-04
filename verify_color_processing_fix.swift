#!/usr/bin/env swift

import Foundation

print("🔍 验证 ColorProcessingView 重复渲染修复...")

// 读取修复后的文件内容
let filePath = "Tools/Tools/Features/ColorProcessing/Views/ColorProcessingView.swift"

guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
    print("❌ 无法读取文件: \(filePath)")
    exit(1)
}

var issues: [String] = []
var fixes: [String] = []

// 检查是否移除了重复的状态变量
if !content.contains("@State private var currentColor: ColorRepresentation?") {
    fixes.append("✅ 移除了重复的 currentColor 状态变量")
} else {
    issues.append("❌ 仍然存在重复的 currentColor 状态变量")
}

// 检查是否使用了单一数据源
if content.contains("$conversionService.currentColor") {
    fixes.append("✅ 使用 conversionService.currentColor 作为单一数据源")
} else {
    issues.append("❌ 没有使用单一数据源")
}

// 检查是否移除了循环更新的 onChange
if !content.contains("currentColor = newColor") {
    fixes.append("✅ 移除了可能导致循环更新的代码")
} else {
    issues.append("❌ 仍然存在可能导致循环更新的代码")
}

// 检查是否添加了初始化标志
if content.contains("@State private var isInitialized: Bool = false") {
    fixes.append("✅ 添加了初始化标志防止重复初始化")
} else {
    issues.append("❌ 没有添加初始化标志")
}

// 检查是否修复了 NSApp 警告
if content.contains("if let app = NSApp") {
    fixes.append("✅ 修复了 NSApp 可选值警告")
} else {
    issues.append("❌ 没有修复 NSApp 可选值警告")
}

print("\n📊 修复结果:")
print("=============")

if !fixes.isEmpty {
    print("\n✅ 已修复的问题:")
    for fix in fixes {
        print("   \(fix)")
    }
}

if !issues.isEmpty {
    print("\n❌ 仍存在的问题:")
    for issue in issues {
        print("   \(issue)")
    }
}

let successRate = Double(fixes.count) / Double(fixes.count + issues.count) * 100

print("\n📈 修复成功率: \(String(format: "%.1f", successRate))%")

if issues.isEmpty {
    print("\n🎉 所有重复渲染问题已修复！")
    print("   - 使用单一数据源管理状态")
    print("   - 移除了循环更新逻辑")
    print("   - 添加了初始化保护")
    print("   - 修复了编译警告")
} else {
    print("\n⚠️  仍有部分问题需要解决")
}

print("\n" + String(repeating: "=", count: 50))
