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

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      TextField(placeholder, text: $text, axis: .vertical)
        .textFieldStyle(BrightTextFieldStyle())
        .lineLimit(1...10)
    }
  }
}

struct BrightTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(8)
      .background(Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(.separatorColor), lineWidth: 1.5))
      .shadow(
        color: Color.black.opacity(0.03),
        radius: 2,
        x: 0,
        y: 1)
  }
}
