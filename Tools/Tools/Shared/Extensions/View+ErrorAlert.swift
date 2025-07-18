//
//  View+ErrorAlert.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

extension View {
  func errorAlert(_ error: Binding<ToolError?>) -> some View {
    self.alert(
      "错误",
      isPresented: .constant(error.wrappedValue != nil),
      presenting: error.wrappedValue
    ) { _ in
      Button("确定") {
        error.wrappedValue = nil
      }
    } message: { toolError in
      Text(toolError.localizedDescription)
    }
  }
}