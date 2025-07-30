//
//  TimeConverterView.swift
//  Tools
//
//  Created by Kiro on 2025/7/18.
//

import AppKit
import SwiftUI

struct TimeConverterView: View {
  // Tab selection state
  @State private var selectedTab: ConversionTab = .single

  // State preservation for tab switching
  @State private var singleConversionState = SingleConversionState()
  @State private var batchConversionState = BatchConversionState()

  // Toast manager for notifications
  @Environment(ToastManager.self) private var toastManager

  // Animation and performance state
  @State private var isViewAppearing = false
  @State private var contentOpacity: Double = 0.0

  // Memory management
  @State private var viewLifecycleManager = ViewLifecycleManager()

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        // Real-time timestamp display at the top
        realTimeTimestampSection
          .opacity(contentOpacity)
          .animation(.easeInOut(duration: 0.4).delay(0.1), value: contentOpacity)

        // Tab interface
        tabInterface
          .opacity(contentOpacity)
          .animation(.easeInOut(duration: 0.4).delay(0.2), value: contentOpacity)

        // Tab content
        tabContent
          .opacity(contentOpacity)
          .animation(.easeInOut(duration: 0.4).delay(0.3), value: contentOpacity)
      }
      .padding(24)
    }
    .navigationTitle("时间转换")
    .environment(\.toastManager, toastManager)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("时间转换工具")
    .accessibilityHint("提供实时时间戳显示、单个转换和批量转换功能")
    .onAppear {
      handleViewAppear()
    }
    .onDisappear {
      handleViewDisappear()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
    ) { _ in
      handleAppWillEnterForeground()
    }
    .onReceive(
      NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
    ) { _ in
      handleAppDidEnterBackground()
    }
  }

  // MARK: - Real-Time Timestamp Section

  private var realTimeTimestampSection: some View {
    VStack(spacing: 16) {
      RealTimeTimestampView()
        .environment(\.toastManager, toastManager)
    }
    .padding(.bottom, 24)
  }

  // MARK: - Tab Interface

  private var tabInterface: some View {
    HStack(spacing: 4) {
      ForEach(ConversionTab.allCases) { tab in
        Button(action: {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            selectedTab = tab
          }

          // Provide haptic feedback
          NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
          )

          // Announce tab change for accessibility
          announceTabChange(to: tab)
        }) {
          HStack(spacing: 6) {
            Image(systemName: tab.iconName)
              .font(.system(size: 14, weight: .medium))
              .symbolEffect(.bounce, value: selectedTab == tab)

            Text(tab.displayName)
              .font(.system(size: 14, weight: .medium))
          }
          .foregroundColor(selectedTab == tab ? .white : .primary)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(selectedTab == tab ? Color.accentColor : Color(.controlBackgroundColor))
              .animation(.easeInOut(duration: 0.2), value: selectedTab)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(
                selectedTab == tab ? Color.clear : Color(.separatorColor).opacity(0.3),
                lineWidth: 1
              )
              .animation(.easeInOut(duration: 0.2), value: selectedTab)
          )
          .scaleEffect(selectedTab == tab ? 1.02 : 1.0)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(tab.displayName)标签")
        .accessibilityHint("切换到\(tab.displayName)模式")
        .accessibilityAddTraits(selectedTab == tab ? [.isSelected, .isButton] : [.isButton])
        .accessibilityValue(selectedTab == tab ? "已选中" : "未选中")
      }
    }
    .padding(.bottom, 24)
  }

  // MARK: - Tab Content

  private var tabContent: some View {
    Group {
      switch selectedTab {
      case .single:
        SingleConversionView()
          .environment(toastManager)
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95)),
              removal: .move(edge: .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 1.05))
            ))

      case .batch:
        BatchConversionView()
          .environment(toastManager)
          .transition(
            .asymmetric(
              insertion: .move(edge: .trailing)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95)),
              removal: .move(edge: .leading)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 1.05))
            ))
      }
    }
    .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: selectedTab)
    .clipped()  // Prevent content overflow during transitions
  }

  // MARK: - Lifecycle Management

  private func handleViewAppear() {
    isViewAppearing = true

    // Animate content appearance
    withAnimation(.easeInOut(duration: 0.6)) {
      contentOpacity = 1.0
    }

    // Initialize view lifecycle manager
    viewLifecycleManager.viewDidAppear()

    // Show welcome toast for first-time users
    if !UserDefaults.standard.bool(forKey: "timeConverterWelcomeShown") {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        toastManager.show(
          "欢迎使用时间转换工具！支持实时时间戳、单个转换和批量转换",
          type: .info,
          duration: 4.0
        )
        UserDefaults.standard.set(true, forKey: "timeConverterWelcomeShown")
      }
    }
  }

  private func handleViewDisappear() {
    isViewAppearing = false
    contentOpacity = 0.0
    viewLifecycleManager.viewDidDisappear()
  }

  private func handleAppWillEnterForeground() {
    if isViewAppearing {
      viewLifecycleManager.appWillEnterForeground()
    }
  }

  private func handleAppDidEnterBackground() {
    if isViewAppearing {
      viewLifecycleManager.appDidEnterBackground()
    }
  }

  // MARK: - Accessibility Support

  private func announceTabChange(to tab: ConversionTab) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      NSAccessibility.post(
        element: NSApp.mainWindow as Any,
        notification: .announcementRequested,
        userInfo: [
          NSAccessibility.NotificationUserInfoKey.announcement: "已切换到\(tab.displayName)模式",
          NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.medium
            .rawValue,
        ]
      )
    }
  }

  // MARK: - Keyboard Handling

  private func handleEnterKeyPress() {
    // Trigger conversion in the active tab
    switch selectedTab {
    case .single:
      // Post notification for single conversion
      NotificationCenter.default.post(
        name: .timeConverterTriggerConversion,
        object: nil,
        userInfo: ["tab": "single"]
      )
    case .batch:
      // Post notification for batch conversion
      NotificationCenter.default.post(
        name: .timeConverterTriggerConversion,
        object: nil,
        userInfo: ["tab": "batch"]
      )
    }
  }

  private func handleCopyKeyPress() {
    // Trigger copy in the active tab
    switch selectedTab {
    case .single:
      NotificationCenter.default.post(
        name: .timeConverterTriggerCopy,
        object: nil,
        userInfo: ["tab": "single"]
      )
    case .batch:
      NotificationCenter.default.post(
        name: .timeConverterTriggerCopy,
        object: nil,
        userInfo: ["tab": "batch"]
      )
    }
  }
}

// MARK: - Conversion Tab Enumeration

enum ConversionTab: String, CaseIterable, Identifiable {
  case single = "single"
  case batch = "batch"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .single:
      return "单个转换"
    case .batch:
      return "批量转换"
    }
  }

  var iconName: String {
    switch self {
    case .single:
      return "arrow.left.arrow.right"
    case .batch:
      return "list.bullet"
    }
  }
}

// MARK: - Single Conversion View (moved to separate file)
// SingleConversionView is now implemented in SingleConversionView.swift

// MARK: - State Preservation Models

struct SingleConversionState {
  // State for preserving single conversion settings between tab switches
  var lastUsedTimezone: TimeZone = .current
  var lastUsedFormat: TimeFormat = .iso8601
  var includeMilliseconds: Bool = false
}

struct BatchConversionState {
  // State for preserving batch conversion settings between tab switches
  var lastSourceFormat: TimeFormat = .timestamp
  var lastTargetFormat: TimeFormat = .iso8601
  var lastInputText: String = ""
}

// MARK: - Time Zone Picker (moved to SingleConversionView.swift)
// TimeZonePicker is now implemented in SingleConversionView.swift

// MARK: - View Lifecycle Manager

@Observable
class ViewLifecycleManager {
  private var isActive = false
  private var backgroundTime: Date?

  func viewDidAppear() {
    isActive = true
    backgroundTime = nil
  }

  func viewDidDisappear() {
    isActive = false
  }

  func appWillEnterForeground() {
    if let backgroundTime = backgroundTime {
      let backgroundDuration = Date().timeIntervalSince(backgroundTime)

      // If app was in background for more than 30 seconds, show refresh notification
      if backgroundDuration > 30 {
        NotificationCenter.default.post(
          name: .timeConverterRefreshAfterBackground,
          object: nil,
          userInfo: ["backgroundDuration": backgroundDuration]
        )
      }
    }
    backgroundTime = nil
  }

  func appDidEnterBackground() {
    backgroundTime = Date()
  }
}

// MARK: - Performance Monitoring

struct PerformanceMetrics {
  static func measureRenderTime<T>(operation: () -> T) -> (result: T, duration: TimeInterval) {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = operation()
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    return (result, duration)
  }

  static func logSlowOperation(
    name: String, duration: TimeInterval, threshold: TimeInterval = 0.016
  ) {
    if duration > threshold {
      print("⚠️ Slow operation detected: \(name) took \(String(format: "%.3f", duration * 1000))ms")
    }
  }
}

// MARK: - Format Examples View

struct FormatExamplesView: View {
  let timeService: TimeConverterService

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(TimeFormat.allCases) { format in
        VStack(alignment: .leading, spacing: 4) {
          Text(format.displayName)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.primary)

          Text(format.description)
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(timeService.getCurrentTime(format: format, includeMilliseconds: false))
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.bottom, 8)
      }
    }
  }
}

#Preview {
  TimeConverterView()
    .environment(ToastManager())
}
