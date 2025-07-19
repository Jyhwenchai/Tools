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
  private let securityService = SecurityService.shared
  private let performanceMonitor = PerformanceMonitor.shared
  private let errorLoggingService = ErrorLoggingService.shared
  
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
          await initializeApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .performanceOptimizationNeeded)) { _ in
          handlePerformanceOptimization()
        }
    }
    .windowResizability(.contentSize)
    .windowToolbarStyle(.unified)
  }
  
  // MARK: - App Initialization
  private func initializeApp() async {
    // Initialize error logging
    errorLoggingService.initialize()
    
    // Request permissions
    let permissionsGranted = await securityService.requestRequiredPermissions()
    if !permissionsGranted {
      errorLoggingService.logError(
        .permissionDenied("系统权限"),
        context: "App启动"
      )
    }
    
    // Start performance monitoring
    performanceMonitor.startPerformanceMonitoring()
    
    print("✅ App initialized successfully")
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
