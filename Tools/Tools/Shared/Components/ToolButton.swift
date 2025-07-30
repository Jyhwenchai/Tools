//
//  ToolButton.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

struct ToolButton: View {
  let title: String
  let action: () -> Void
  let style: ButtonStyle

  enum ButtonStyle {
    case primary
    case secondary
    case destructive
  }

  var body: some View {
    switch style {
    case .primary:
      Button(action: action) {
        Text(title)
          .font(.callout)
          .fontWeight(.medium)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .buttonStyle(.borderedProminent)
      .accessibilityLabel(title)
      .accessibilityAddTraits(.isButton)
      .accessibilityHint("主要操作按钮")
      .focusable(true)
    case .secondary:
      Button(action: action) {
        Text(title)
          .font(.callout)
          .fontWeight(.medium)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .buttonStyle(.bordered)
      .accessibilityLabel(title)
      .accessibilityAddTraits(.isButton)
      .accessibilityHint("次要操作按钮")
      .focusable(true)
    case .destructive:
      Button(action: action) {
        Text(title)
          .font(.callout)
          .fontWeight(.medium)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .buttonStyle(.bordered)
      .foregroundStyle(.red)
      .accessibilityLabel(title)
      .accessibilityAddTraits(.isButton)
      .accessibilityHint("危险操作按钮，请谨慎使用")
      .focusable(true)
    }
  }
}
