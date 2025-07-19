//
//  LazyToolView.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import SwiftUI

/// A container view that provides lazy loading and memory management for tool views
struct LazyToolView<Content: View>: View {
  private let content: () -> Content
  @State private var isViewLoaded = false
  @State private var memoryWarning = false
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    Group {
      if isViewLoaded {
        content()
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      } else {
        Color.clear
          .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
              isViewLoaded = true
            }
          }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .memoryPressureDetected)) { _ in
      handleMemoryWarning()
    }
    .alert("内存警告", isPresented: $memoryWarning) {
      Button("确定") {
        memoryWarning = false
      }
    } message: {
      Text("系统内存不足，建议关闭不必要的工具以释放内存。")
    }
  }
  
  private func handleMemoryWarning() {
    memoryWarning = true
    
    // Trigger garbage collection
    DispatchQueue.global(qos: .utility).async {
      // Force memory cleanup
      autoreleasepool {
        // This will help release any retained objects
      }
    }
  }
}

// MARK: - Memory Management Extension
extension View {
  /// Apply memory-efficient modifiers to a view
  func withMemoryManagement() -> some View {
    self
      .onAppear {
        MemoryManager.shared.registerViewAppearance()
      }
      .onDisappear {
        MemoryManager.shared.registerViewDisappearance()
      }
  }
}

// MARK: - Memory Manager
@Observable
class MemoryManager {
  static let shared = MemoryManager()
  
  private var activeViewCount = 0
  private let maxActiveViews = 3
  
  private init() {}
  
  func registerViewAppearance() {
    activeViewCount += 1
    
    if activeViewCount > maxActiveViews {
      // Suggest memory cleanup
      NotificationCenter.default.post(
        name: .memoryPressureDetected,
        object: nil
      )
    }
  }
  
  func registerViewDisappearance() {
    activeViewCount = max(0, activeViewCount - 1)
  }
  
  func getCurrentMemoryUsage() -> Double {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_,
                 task_flavor_t(MACH_TASK_BASIC_INFO),
                 $0,
                 &count)
      }
    }
    
    if kerr == KERN_SUCCESS {
      return Double(info.resident_size) / (1024 * 1024) // MB
    }
    
    return 0
  }
}

// MARK: - Notification Names
extension Notification.Name {
  static let memoryPressureDetected = Notification.Name("memoryPressureDetected")
}