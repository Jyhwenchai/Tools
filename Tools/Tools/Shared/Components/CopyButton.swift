//
//  CopyButton.swift
//  Tools
//
//  Created by didong on 2025/7/24.
//

import SwiftUI

struct CopyButton: View {
  @State private var showCopySuccess = false
  let content: String
  var body: some View {
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
        Image(
          systemName: showCopySuccess ? "checkmark.circle.fill" : "doc.on.doc"
        )
        .font(.caption)
        Text(showCopySuccess ? "已复制" : "复制")
          .font(.caption)
      }
    }
    .buttonStyle(.borderless)
    .foregroundColor(showCopySuccess ? .green : .blue)
    .animation(.easeInOut(duration: 0.2), value: showCopySuccess)
    .accessibilityLabel(showCopySuccess ? "已复制到剪贴板" : "复制到剪贴板")
    .accessibilityHint("将内容复制到系统剪贴板")
    .accessibilityAddTraits(.isButton)
    .focusable(true)
    .keyboardShortcut("c", modifiers: .command)
  }
}

#Preview {
  CopyButton(content: "hello")
    .frame(width: 160, height: 130)
}
