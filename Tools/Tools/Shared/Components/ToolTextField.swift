//
//  ToolTextField.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

struct ToolTextField: View {
  let title: String
  @Binding
  var text: String
  let placeholder: String
  let minHeight: CGFloat
  let maxHeight: CGFloat
  let fixedHeight: CGFloat?

  init(
    title: String,
    text: Binding<String>,
    placeholder: String,
    minHeight: CGFloat = 100,
    maxHeight: CGFloat = 300,
    fixedHeight: CGFloat? = nil
  ) {
    self.title = title
    self._text = text
    self.placeholder = placeholder
    self.minHeight = minHeight
    self.maxHeight = maxHeight
    self.fixedHeight = fixedHeight
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !title.isEmpty {
        Text(title)
          .font(.callout)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .accessibilityLabel("输入框标题: \(title)")
      }

      ScrollView {
        TextField(placeholder, text: $text, axis: .vertical)
          .textFieldStyle(BrightTextFieldStyle())
          .lineLimit(nil)
          .accessibilityLabel(title.isEmpty ? "文本输入框" : title)
          .accessibilityHint(placeholder)
          .focusable(true)
      }
      .frame(
        minHeight: fixedHeight ?? minHeight,
        maxHeight: fixedHeight ?? maxHeight
      )
      .background(Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(.separatorColor), lineWidth: 1.5)
      )
      .shadow(
        color: Color.black.opacity(0.03),
        radius: 2,
        x: 0,
        y: 1)
    }
    .accessibilityElement(children: .contain)
  }
}

struct BrightTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(8)
      .background(Color.clear)
  }
}
