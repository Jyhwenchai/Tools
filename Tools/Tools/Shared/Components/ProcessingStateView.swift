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
  let progress: Double?
  let showCancelButton: Bool
  let onCancel: (() -> Void)?

  @State private var animationRotation: Double = 0
  @State private var pulseScale: Double = 1.0

  init(
    isProcessing: Bool,
    message: String = "处理中...",
    progress: Double? = nil,
    showCancelButton: Bool = false,
    onCancel: (() -> Void)? = nil) {
    self.isProcessing = isProcessing
    self.message = message
    self.progress = progress
    self.showCancelButton = showCancelButton
    self.onCancel = onCancel
  }

  var body: some View {
    if isProcessing {
      VStack(spacing: 20) {
        // Progress Indicator
        progressIndicator

        // Message
        Text(message)
          .font(.callout)
          .fontWeight(.medium)
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)

        // Progress Details
        if let progress {
          progressDetails(progress)
        }

        // Cancel Button
        if showCancelButton, let onCancel {
          Button("取消", action: onCancel)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
      }
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.regularMaterial)
          .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6))
      .scaleEffect(pulseScale)
      .onAppear {
        startAnimations()
      }
      .onDisappear {
        stopAnimations()
      }
    }
  }

  // MARK: - Progress Indicator

  @ViewBuilder
  private var progressIndicator: some View {
    if let progress {
      // Determinate progress
      ZStack {
        Circle()
          .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
          .frame(width: 60, height: 60)

        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            Color.accentColor,
            style: StrokeStyle(lineWidth: 4, lineCap: .round))
          .frame(width: 60, height: 60)
          .rotationEffect(.degrees(-90))
          .animation(.easeInOut(duration: 0.5), value: progress)

        Text("\(Int(progress * 100))%")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.accentColor)
      }
    } else {
      // Indeterminate progress
      ZStack {
        Circle()
          .stroke(Color.secondary.opacity(0.3), lineWidth: 4)
          .frame(width: 60, height: 60)

        Circle()
          .trim(from: 0, to: 0.3)
          .stroke(
            Color.accentColor,
            style: StrokeStyle(lineWidth: 4, lineCap: .round))
          .frame(width: 60, height: 60)
          .rotationEffect(.degrees(animationRotation))
      }
    }
  }

  // MARK: - Progress Details

  @ViewBuilder
  private func progressDetails(_ progress: Double) -> some View {
    VStack(spacing: 8) {
      // Progress Bar
      ProgressView(value: progress, total: 1.0)
        .progressViewStyle(.linear)
        .frame(width: 200)
        .tint(.accentColor)

      // Time Estimation
      if progress > 0.1 {
        let estimatedTimeRemaining = estimateTimeRemaining(progress: progress)
        if estimatedTimeRemaining > 0 {
          Text("预计剩余时间: \(formatTime(estimatedTimeRemaining))")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
  }

  // MARK: - Animation Control

  private func startAnimations() {
    // Rotation animation for indeterminate progress
    if progress == nil {
      withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
        animationRotation = 360
      }
    }

    // Pulse animation
    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
      pulseScale = 1.02
    }
  }

  private func stopAnimations() {
    animationRotation = 0
    pulseScale = 1.0
  }

  // MARK: - Time Estimation

  private func estimateTimeRemaining(progress: Double) -> TimeInterval {
    // Simple time estimation based on progress
    // In a real app, you'd track actual processing time
    let totalEstimatedTime: TimeInterval = 10.0 // seconds
    let remainingProgress = 1.0 - progress
    return totalEstimatedTime * remainingProgress
  }

  private func formatTime(_ seconds: TimeInterval) -> String {
    if seconds < 60 {
      return String(format: "%.0f秒", seconds)
    } else {
      let minutes = Int(seconds / 60)
      let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
      return "\(minutes)分\(remainingSeconds)秒"
    }
  }
}

// MARK: - Convenience Initializers

extension ProcessingStateView {
  /// Create a simple processing view with just a message
  static func simple(isProcessing: Bool, message: String = "处理中...") -> ProcessingStateView {
    ProcessingStateView(isProcessing: isProcessing, message: message)
  }

  /// Create a processing view with progress
  static func withProgress(
    isProcessing: Bool,
    message: String = "处理中...",
    progress: Double) -> ProcessingStateView {
    ProcessingStateView(isProcessing: isProcessing, message: message, progress: progress)
  }

  /// Create a cancellable processing view
  static func cancellable(
    isProcessing: Bool,
    message: String = "处理中...",
    onCancel: @escaping () -> Void) -> ProcessingStateView {
    ProcessingStateView(
      isProcessing: isProcessing,
      message: message,
      showCancelButton: true,
      onCancel: onCancel)
  }
}

// MARK: - Compact Processing View for Inline Use

struct CompactProcessingView: View {
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

#Preview {
  VStack(spacing: 30) {
    ProcessingStateView.simple(isProcessing: true)

    ProcessingStateView.withProgress(
      isProcessing: true,
      message: "正在处理图片...",
      progress: 0.65)

    ProcessingStateView.cancellable(
      isProcessing: true,
      message: "正在上传文件...") {
      print("Cancelled")
    }

    CompactProcessingView(isProcessing: true, message: "处理中...")
  }
  .padding()
  .frame(width: 400, height: 600)
}
