//
//  ContentView.swift
//  Tools
//
//  Created by didong on 2025/7/17.
//

import SwiftUI

struct ContentView: View {
//  @State private var navigationManager = NavigationManager()
//  @State private var settings = AppSettings.shared
//  @State private var isInitialized = false
//  @State private var stabilityMonitor = ApplicationStabilityMonitor.shared
//
//  #if DEBUG
//    @State private var performanceMonitor: PerformanceMonitor?
//    @State private var showPerformanceAlert = false
//  #endif

  var body: some View {
    NavigationSplitView {
//      SidebarView(selection: $navigationManager.selectedTool)
//        .navigationSplitViewColumnWidth(240)
    } detail: {
//      ToolDetailView(tool: navigationManager.selectedTool)
//        .navigationSplitViewColumnWidth(min: 600, ideal: 800)
    }
//    .navigationSplitViewStyle(.balanced)
//    .preferredColorScheme(settings.theme.colorScheme)
//    .task {
//      await initializeContentView()
//    }
//    .withStabilityMonitoring()
//    #if DEBUG
//      .overlay(alignment: .topTrailing) {
//        performanceIndicator
//      }
//      .alert("性能警告", isPresented: $showPerformanceAlert) {
//        Button("确定") {
//          showPerformanceAlert = false
//        }
//        Button("优化") {
//          optimizePerformance()
//          showPerformanceAlert = false
//        }
//      } message: {
//        Text(performanceWarningMessage)
//      }
//      .onChange(of: performanceMonitor?.performanceWarnings ?? []) { _, warnings in
//        if !warnings.isEmpty, !showPerformanceAlert {
//          showPerformanceAlert = true
//        }
//      }
//    #endif
  }

  // MARK: - Lazy Initialization

//  private func initializeContentView() async {
//    guard !isInitialized else { return }
//
//    // Initialize stability monitor
//    _ = stabilityMonitor.getStabilityReport()
//
//    // Delay performance monitor initialization to improve startup
//    #if DEBUG
//      await Task.detached(priority: .background) {
//        await MainActor.run {
//          performanceMonitor = PerformanceMonitor.shared
//        }
//      }.value
//    #endif
//
//    // Check for memory pressure
//    if stabilityMonitor.isMemoryPressureDetected {
//      // Trigger memory optimization
//      NotificationCenter.default.post(name: .applicationMemoryOptimizationNeeded, object: nil)
//    }
//
//    isInitialized = true
//  }
//
//  // MARK: - Performance Indicator (DEBUG Only)
//
//  #if DEBUG
//    @ViewBuilder
//    private var performanceIndicator: some View {
//      if let monitor = performanceMonitor, !monitor.isPerformanceOptimal {
//        HStack(spacing: 8) {
//          Image(systemName: "exclamationmark.triangle.fill")
//            .foregroundColor(.orange)
//
//          Text("性能")
//            .font(.caption)
//            .fontWeight(.medium)
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//        .background(.regularMaterial)
//        .cornerRadius(8)
//        .padding()
//        .onTapGesture {
//          showPerformanceAlert = true
//        }
//      }
//    }
//
//    private var performanceWarningMessage: String {
//      guard let monitor = performanceMonitor else {
//        return "性能监控初始化中..."
//      }
//
//      let warnings = monitor.performanceWarnings
//      if warnings.isEmpty {
//        return "应用性能正常"
//      }
//
//      return warnings.map(\.description).joined(separator: "\n")
//    }
//
//    private func optimizePerformance() {
//      NotificationCenter.default.post(name: .performanceOptimizationNeeded, object: nil)
//    }
//  #endif
}

struct SidebarView: View {
  @Binding
  var selection: NavigationManager.ToolType

  var body: some View {
    List(NavigationManager.ToolType.allCases, id: \.self, selection: $selection) { tool in
      NavigationLink(value: tool) {
        HStack(spacing: 12) {
          Image(systemName: tool.icon)
            .frame(width: 20, height: 20)
            .foregroundStyle(.secondary)

          Text(tool.name)
            .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 4)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("工具")
  }
}

struct ToolDetailView: View {
  let tool: NavigationManager.ToolType
  @State private var isLoading = true
  @State private var loadingProgress: Double = 0.0

  var body: some View {
    VStack(spacing: 0) {
      if isLoading {
        loadingView
      } else {
        toolContentView
      }
    }
    .task {
      await loadToolView()
    }
  }

  // MARK: - Loading View

  private var loadingView: some View {
    VStack(spacing: 20) {
      Image(systemName: tool.icon)
        .font(.system(size: 48))
        .foregroundStyle(.secondary)
        .scaleEffect(isLoading ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)

      VStack(spacing: 12) {
        Text("正在加载 \(tool.name)...")
          .font(.headline)
          .foregroundStyle(.primary)

        ProgressView(value: loadingProgress, total: 1.0)
          .progressViewStyle(.linear)
          .frame(width: 200)

        Text("\(Int(loadingProgress * 100))%")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(NSColor.textBackgroundColor))
  }

  // MARK: - Tool Content View (Lazy Loaded)

  @ViewBuilder
  private var toolContentView: some View {
    switch tool {
    case .encryption:
      LazyToolView {
        EncryptionView()
      }
    case .json:
      LazyToolView {
        JSONView()
      }
    case .imageProcessing:
      LazyToolView {
        ImageProcessingView()
      }
    case .qrCode:
      LazyToolView {
        QRCodeView()
      }
    case .timeConverter:
      LazyToolView {
        TimeConverterView()
      }
    case .clipboard:
      LazyToolView {
        ClipboardManagerView()
      }
    case .settings:
      LazyToolView {
        SettingsView()
      }
    }
  }

  // MARK: - Loading Logic

  private func loadToolView() async {
    // Simulate progressive loading with realistic steps
    let loadingSteps = [
      ("初始化组件", 0.2),
      ("加载资源", 0.4),
      ("准备界面", 0.6),
      ("应用设置", 0.8),
      ("完成加载", 1.0)
    ]

    for (_, progress) in loadingSteps {
      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.3)) {
          loadingProgress = progress
        }
      }

      // Realistic loading delay based on tool complexity
      let delay = getLoadingDelay(for: tool)
      try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    await MainActor.run {
      withAnimation(.easeInOut(duration: 0.5)) {
        isLoading = false
      }
    }
  }

  private func getLoadingDelay(for tool: NavigationManager.ToolType) -> Double {
    // Reduced loading delays for better startup performance
    switch tool {
    case .clipboard:
      0.08 // Reduced from 0.15
    case .imageProcessing:
      0.06 // Reduced from 0.12
    case .settings:
      0.02 // Reduced from 0.05
    default:
      0.04 // Reduced from 0.08
    }
  }
}

struct PlaceholderView: View {
  let tool: NavigationManager.ToolType

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // Header
      VStack(alignment: .leading, spacing: 8) {
        Text(tool.name)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(tool.description)
          .font(.callout)
          .foregroundStyle(.secondary)
      }

      // Tool content placeholder
      BrightCardView {
        VStack {
          Image(systemName: tool.icon)
            .font(.system(size: 48))
            .foregroundStyle(.secondary)

          Text("功能开发中...")
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
      }

      Spacer()
    }
    .padding(24)
    .navigationTitle(tool.name)
  }
}

#Preview {
  ContentView()
}
