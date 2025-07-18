//
//  ProcessingStateView.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

struct ProcessingStateView: View {
  let isProcessing: Bool
  let message: String

  var body: some View {
    HStack(spacing: 8) {
      if isProcessing {
        ProgressView()
          .scaleEffect(0.8)
      }

      Text(message)
        .font(.callout)
        .foregroundStyle(isProcessing ? .secondary : .primary)
    }
    .animation(.easeInOut(duration: 0.2), value: isProcessing)
  }
}
