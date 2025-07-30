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
      .padding(20)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.controlBackgroundColor))
          .shadow(
            color: Color.black.opacity(0.04),
            radius: 6,
            x: 0,
            y: 2
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.separatorColor).opacity(0.2), lineWidth: 0.5)
      )
  }
}
