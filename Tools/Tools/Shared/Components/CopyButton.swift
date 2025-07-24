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
  }
}

#Preview {
  CopyButton(content: "hello")
    .frame(width: 160, height: 130)
}
