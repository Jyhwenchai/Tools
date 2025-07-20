//
//  ToolsApp.swift
//  Tools
//
//  Created by didong on 2025/7/17.
//

import SwiftUI
import SwiftData

@main
struct ToolsApp: App {
  // Lazy initialization to improve startup performance
  private lazy var securityService = SecurityService.shared
  private lazy var performanceMonitor = PerformanceMonitor.shared
  private lazy var errorLoggingService = ErrorLoggingService.shared
  
  // SwiftData model container
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
        .withErrorHandling()
        .withPerformanceMonitoring(identifier: "MainApp")
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
    // Defer heavy initialization to background queue to improve startup time
    Task.detached(priority: .background) {
      // Initialize error logging in background
      await self.errorLoggingService.initialize()
      
      // Start performance monitoring in background (DEBUG mode only)
      #if DEBUG
      await self.performanceMonitor.startPerformanceMonitoring()
      #endif
      
      print("✅ App background initialization completed")
    }
    
    // Only essential initialization on main thread
    print("🚀 App startup completed - background services initializing...")
  }
  
  // MARK: - Performance Optimization
  private func handlePerformanceOptimization() {
    print("🔧 Handling performance optimization request")
    
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
