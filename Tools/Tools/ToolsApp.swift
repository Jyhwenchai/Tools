//
//  ToolsApp.swift
//  Tools
//
//  Created by didong on 2025/7/17.
//

import SwiftData
import SwiftUI

@main
struct ToolsApp: App {
  // SwiftData model container - optimized for faster startup
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      ClipboardItem.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(sharedModelContainer)
        .preferredColorScheme(AppSettings.shared.theme.colorScheme)
        .task {
          await initializeAppLazily()
        }
        .onReceive(NotificationCenter.default.publisher(for: .performanceOptimizationNeeded)) { _ in
          handlePerformanceOptimization()
        }
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }

  // MARK: - App Initialization (Optimized for Startup Performance)

  private func initializeAppLazily() async {
    // Defer all non-essential initialization to background queue
    Task.detached(priority: .background) {
      // Initialize error logging in background only when needed
      #if DEBUG
        await ErrorLoggingService.shared.initialize()
        PerformanceMonitor.shared.startPerformanceMonitoring()
        print("✅ Debug services initialized")
      #endif

      // Initialize security service with delay to avoid impacting startup
      DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 2.0) {
        _ = SecurityService.shared
      }

      print("✅ App background initialization completed")
    }

    print("🚀 App startup completed")
  }

  // MARK: - Performance Optimization

  private func handlePerformanceOptimization() {
    // Cancel non-essential operations
    AsyncOperationManager.shared.cancelAllOperations()

    // Clear caches
    URLCache.shared.removeAllCachedResponses()

    // Force memory cleanup
    DispatchQueue.global(qos: .utility).async {
      autoreleasepool {
        // Memory cleanup
      }
    }
  }
}
