//
//  BrightCardView.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

struct BrightCardView<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .padding(16)
      .background(Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(
        color: Color.black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1))
  }
}
