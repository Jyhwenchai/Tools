# 权限优化设计文档

## 概述

本设计文档旨在解决 macOS 工具应用中权限弹窗过于频繁的问题。通过重新设计权限请求策略、实现权限状态缓存、提供功能降级方案等方式，显著改善用户体验。

## 架构设计

### 权限移除架构

```
┌─────────────────────────────────────────────────────────────┐
│                 Permission-Free Design                       │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  Drag & Drop    │  │  File Dialogs   │  │  Clipboard      │ │
│  │  File Import    │  │  (Native)       │  │  (One-time)     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│              Remove Performance Monitoring                   │
├─────────────────────────────────────────────────────────────┤
│                    Minimal Code Impact                       │
└─────────────────────────────────────────────────────────────┘
```

### 简化模块结构

```
Tools/
├── Shared/
│   ├── Services/
│   │   ├── FileAccessService.swift          # 简化文件访问服务
│   │   └── ClipboardService.swift           # 粘贴板服务（一次性权限）
│   └── Extensions/
│       └── View+FileHandling.swift          # 文件处理扩展
├── Features/
│   ├── ImageProcessing/
│   │   └── Views/
│   │       └── DragDropImageView.swift      # 拖拽导入界面
│   └── Clipboard/
│       └── Services/
│           └── SimpleClipboardService.swift # 简化粘贴板服务
└── Core/
    └── Utils/
        └── FileDialogUtils.swift            # 文件对话框工具
```

## 组件和接口设计

### 简化文件访问服务

```swift
@Observable
class FileAccessService {
  // 完全移除权限检查，只使用系统原生对话框和拖拽
  func importFile() async -> URL? {
    // 使用系统原生文件选择对话框，无需权限
    return await showFileDialog()
  }
  
  func exportFile(data: Data, suggestedName: String) async -> Bool {
    // 使用系统原生保存对话框，无需权限
    return await showSaveDialog(data: data, suggestedName: suggestedName)
  }
  
  // 处理拖拽导入
  func handleDraggedFiles(_ urls: [URL]) -> [URL] {
    return urls.filter { $0.isFileURL }
  }
}
```

### 一次性粘贴板权限处理

```swift
@Observable
class ClipboardService {
  @AppStorage("clipboardPermissionGranted") private var permissionGranted = false
  @AppStorage("clipboardPermissionAsked") private var permissionAsked = false
  
  private var isEnabled: Bool {
    return permissionGranted
  }
  
  // 一次性权限请求
  func requestPermissionIfNeeded() async {
    guard !permissionAsked else { return }
    
    permissionAsked = true
    let granted = await requestClipboardAccess()
    permissionGranted = granted
  }
  
  // 简化的粘贴板操作
  func addToHistory(_ content: String) {
    guard isEnabled else { return }
    // 添加到历史记录
  }
  
  func getHistory() -> [ClipboardItem] {
    guard isEnabled else { return [] }
    // 返回历史记录
  }
}
```

### 保留开发期间性能监控

```swift
@Observable
class PerformanceMonitorService {
  private var isDebugMode: Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
  }
  
  // 只在开发模式下进行性能监控，不请求权限
  func logPerformanceMetrics() {
    guard isDebugMode else { return }
    
    // 使用不需要权限的方式获取基本性能信息
    let memoryUsage = getBasicMemoryInfo()
    let cpuUsage = getBasicCPUInfo()
    
    print("🔍 Performance - Memory: \(memoryUsage)MB, CPU: \(cpuUsage)%")
  }
  
  // 获取基本内存信息（不需要特殊权限）
  private func getBasicMemoryInfo() -> Double {
    let info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    
    if kerr == KERN_SUCCESS {
      return Double(info.resident_size) / 1024.0 / 1024.0
    }
    return 0
  }
  
  // 获取基本CPU信息（不需要特殊权限）
  private func getBasicCPUInfo() -> Double {
    // 使用基本的CPU使用率获取方法
    // 这里可以实现简单的CPU使用率计算
    return 0.0 // 占位符
  }
}

// 移除用户界面的性能监控显示
struct PerformanceView: View {
  var body: some View {
    // 在发布版本中隐藏性能监控UI
    #if DEBUG
    VStack {
      Text("开发模式 - 性能监控")
        .font(.caption)
        .foregroundColor(.secondary)
      Text("查看控制台日志获取性能信息")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
    #else
    EmptyView()
    #endif
  }
}
```

### 拖拽导入界面

```swift
struct DragDropImageView: View {
  @State private var draggedImage: NSImage?
  @State private var isTargeted = false
  
  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(isTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
      .overlay(
        VStack {
          Image(systemName: "photo.badge.plus")
            .font(.system(size: 48))
            .foregroundColor(.secondary)
          
          Text("拖拽图片到此处")
            .font(.headline)
            .foregroundColor(.secondary)
          
          Text("或点击选择文件")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      )
      .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
        handleDrop(providers)
      }
      .onTapGesture {
        showFileDialog()
      }
  }
  
  private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
    // 处理拖拽导入，无需权限
    for provider in providers {
      provider.loadItem(forTypeIdentifier: "public.file-url") { item, error in
        if let data = item as? Data,
           let url = URL(dataRepresentation: data, relativeTo: nil) {
          loadImage(from: url)
        }
      }
    }
    return true
  }
  
  private func showFileDialog() {
    // 使用系统原生文件选择对话框，无需权限
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    
    if panel.runModal() == .OK,
       let url = panel.url {
      loadImage(from: url)
    }
  }
}
```

### 文件对话框工具

```swift
struct FileDialogUtils {
  static func showOpenDialog(allowedTypes: [UTType]) async -> URL? {
    return await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = false
        
        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }
  
  static func showSaveDialog(suggestedName: String, allowedTypes: [UTType]) async -> URL? {
    return await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = allowedTypes
        panel.nameFieldStringValue = suggestedName
        
        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }
}

## 数据模型

### 简化配置

```swift
struct AppConfiguration {
  // 粘贴板权限状态存储键
  static let clipboardPermissionKey = "clipboardPermissionGranted"
  static let clipboardAskedKey = "clipboardPermissionAsked"
  
  // 文件类型支持
  static let supportedImageTypes: [UTType] = [.png, .jpeg, .gif, .tiff, .bmp]
  static let supportedExportTypes: [UTType] = [.png, .jpeg]
}
```

### 简化粘贴板模型

```swift
struct ClipboardItem: Identifiable, Codable {
  let id = UUID()
  let content: String
  let timestamp: Date
  let type: ClipboardItemType
  
  enum ClipboardItemType: String, Codable, CaseIterable {
    case text = "文本"
    case url = "链接"
    case code = "代码"
  }
}

// 移除复杂的权限状态模型
// 只保留必要的数据结构

## 错误处理

### 简化错误处理

```swift
enum FileAccessError: LocalizedError {
  case fileNotFound
  case unsupportedFormat
  case saveFailed
  
  var errorDescription: String? {
    switch self {
    case .fileNotFound:
      return "文件未找到"
    case .unsupportedFormat:
      return "不支持的文件格式"
    case .saveFailed:
      return "文件保存失败"
    }
  }
}

// 移除所有权限相关的错误处理
// 简化错误类型，只保留核心功能相关的错误

## 实施策略

### 权限请求优化策略

1. **延迟请求**: 只在用户真正使用相关功能时才请求权限
2. **批量请求**: 将相关权限合并在一次用户交互中请求
3. **缓存状态**: 缓存权限状态，避免重复检查
4. **优雅降级**: 权限被拒绝时提供替代方案

### 用户体验优化

1. **清晰说明**: 在请求权限前说明用途和影响
2. **可选功能**: 将非核心功能的权限设为可选
3. **替代方案**: 为权限受限的功能提供替代操作方式
4. **统一管理**: 提供统一的权限管理界面

### 性能优化

1. **异步处理**: 权限检查和请求都在后台线程进行
2. **缓存机制**: 避免频繁的系统权限状态查询
3. **资源清理**: 及时清理不需要的权限监听和缓存
4. **条件加载**: 只在需要时加载权限相关的服务

## 测试策略

### 权限测试场景

1. **权限状态测试**: 测试各种权限状态下的应用行为
2. **降级功能测试**: 测试权限被拒绝时的替代方案
3. **缓存机制测试**: 测试权限状态缓存的有效性
4. **用户体验测试**: 测试权限请求的用户交互流程

### 测试用例示例

```swift
struct PermissionManagerTests {
  
  @Test("权限状态缓存测试")
  func testPermissionStateCache() async {
    let manager = PermissionManager()
    
    // 首次检查应该查询系统状态
    let initialState = manager.checkPermissionStatus(.fileAccess)
    
    // 第二次检查应该使用缓存
    let cachedState = manager.checkPermissionStatus(.fileAccess)
    
    #expect(initialState == cachedState)
  }
  
  @Test("权限拒绝后的降级处理")
  func testGracefulDegradation() async {
    let service = FileAccessService(permissionManager: PermissionManager())
    
    // 模拟权限被拒绝的情况
    let result = await service.accessFile()
    
    // 应该返回替代方案
    #expect(result == .requiresDragAndDrop)
  }
}
```