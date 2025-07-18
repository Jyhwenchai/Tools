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

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
          .font(.callout)
          .fontWeight(.medium)
          .foregroundStyle(.primary)

        Spacer()

        if canCopy {
          Button("复制") {
            NSPasteboard.general.setString(content, forType: .string)
          }
          .buttonStyle(.borderless)
          .font(.caption)
        }
      }

      ScrollView {
        Text(content)
          .font(.system(.body, design: .monospaced))
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(minHeight: 100, maxHeight: 300)
      .background(Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(.separatorColor), lineWidth: 1))
    }
  }
}
