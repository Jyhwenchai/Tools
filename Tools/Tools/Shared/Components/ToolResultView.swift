//
//  ToolResultView.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import AppKit
import SwiftUI

struct ToolResultView: View {
  let title: String
  let content: String
  let canCopy: Bool

  @State private var showCopySuccess = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        if !title.isEmpty {
          Text(title)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .accessibilityLabel("结果标题: \(title)")
        }

        Spacer()

        if canCopy {
          Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(content, forType: .string)
            showCopySuccess = true

            // Announce to screen reader
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: [
                  .announcement: "内容已复制到剪贴板",
                  .priority: NSAccessibilityPriorityLevel.medium.rawValue,
                ]
              )
            }

            // 2秒后隐藏成功提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              showCopySuccess = false
            }
          }) {
            HStack(spacing: 4) {
              Image(systemName: showCopySuccess ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.caption)
              Text(showCopySuccess ? "已复制" : "复制")
                .font(.caption)
            }
          }
          .buttonStyle(.borderless)
          .foregroundColor(showCopySuccess ? .green : .blue)
          .animation(.easeInOut(duration: 0.2), value: showCopySuccess)
          .accessibilityLabel(showCopySuccess ? "已复制到剪贴板" : "复制到剪贴板")
          .accessibilityHint("将结果内容复制到系统剪贴板")
          .accessibilityAddTraits(.isButton)
          .focusable(true)
          .keyboardShortcut("c", modifiers: .command)
        }
      }

      ScrollView {
        Text(content)
          .font(.system(.body, design: .monospaced))
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .accessibilityLabel("结果内容")
          .accessibilityValue(content)
          .accessibilityHint("处理结果，可以选择和复制")
      }
      .frame(minHeight: 100, maxHeight: .infinity)
      .background(Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(.separatorColor), lineWidth: 1))
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(title.isEmpty ? "处理结果" : title)
  }
}
