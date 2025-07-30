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
    Button(action: action) {
      Text(title)
        .font(.callout)
        .fontWeight(.medium)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColorForStyle)
        )
        .foregroundStyle(foregroundColorForStyle)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(borderColorForStyle, lineWidth: borderWidthForStyle)
        )
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
    .accessibilityHint(accessibilityHintForStyle)
  }

  private var backgroundColorForStyle: Color {
    switch style {
    case .primary:
      return .accentColor
    case .secondary:
      return Color(.controlBackgroundColor)
    case .destructive:
      return Color(.controlBackgroundColor)
    }
  }

  private var foregroundColorForStyle: Color {
    switch style {
    case .primary:
      return .white
    case .secondary:
      return .primary
    case .destructive:
      return .red
    }
  }

  private var borderColorForStyle: Color {
    switch style {
    case .primary:
      return .clear
    case .secondary:
      return Color(.separatorColor).opacity(0.6)
    case .destructive:
      return Color.red.opacity(0.3)
    }
  }

  private var borderWidthForStyle: CGFloat {
    switch style {
    case .primary:
      return 0
    case .secondary, .destructive:
      return 1
    }
  }

  private var accessibilityHintForStyle: String {
    switch style {
    case .primary:
      return "主要操作按钮"
    case .secondary:
      return "次要操作按钮"
    case .destructive:
      return "危险操作按钮，请谨慎使用"
    }
  }
}
