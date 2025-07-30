# Toast 通知系统设计文档

## 概述

Toast 通知系统是一个为 macOS 应用程序设计的现代化、无障碍的通知组件系统。它提供了优雅的用户反馈机制，支持多种通知类型、自动消失、悬停暂停、手势操作等功能，并完全符合 macOS 设计规范和无障碍标准。

## 系统架构

### 核心组件

```
Toast系统
├── ToastModels.swift          # 数据模型和类型定义
├── ToastManager.swift         # 核心管理服务
├── ToastView.swift           # 单个通知视图组件
├── ToastContainer.swift      # 通知容器和布局管理
└── ToastModifier.swift       # SwiftUI 视图修饰器
```

### 架构模式

- **MVVM 架构**: 清晰的数据流和职责分离
- **Observable 模式**: 使用 `@Observable` 实现响应式状态管理
- **组合模式**: 通过 SwiftUI 修饰器实现灵活的集成
- **策略模式**: 支持不同类型的通知样式和行为

## 详细设计

### 1. 数据模型 (ToastModels.swift)

#### ToastType 枚举

定义了四种通知类型，每种都有对应的图标、颜色和语义：

```swift
enum ToastType: CaseIterable {
    case success    // 成功 - 绿色，勾选图标
    case error      // 错误 - 红色，感叹号图标
    case warning    // 警告 - 橙色，三角警告图标
    case info       // 信息 - 蓝色，信息图标
}
```

**设计特点**：

- 使用 SF Symbols 图标系统
- 支持深色/浅色模式自适应
- 提供背景色调、边框色等完整的视觉主题

#### ToastMessage 结构体

通知消息的核心数据模型：

```swift
struct ToastMessage: Identifiable, Equatable {
    let id: UUID                    // 唯一标识符
    let message: String             // 通知内容
    let type: ToastType            // 通知类型
    let duration: TimeInterval     // 显示时长
    let isAutoDismiss: Bool        // 是否自动消失
}
```

### 2. 核心管理器 (ToastManager.swift)

`ToastManager` 是整个系统的核心，负责通知的生命周期管理。

#### 主要功能

**通知显示管理**：

- 支持同时显示最多 5 个通知
- 超出限制的通知进入队列等待
- 智能队列处理，防止通知堆积

**定时器管理**：

- 每个通知独立的自动消失定时器
- 支持暂停/恢复定时器（悬停时暂停）
- 精确的剩余时间计算

**线程安全**：

- 使用串行队列确保操作原子性
- 主线程更新 UI，后台处理业务逻辑

**无障碍支持**：

- 自动语音播报通知内容
- 提供详细的无障碍描述
- 支持键盘导航和屏幕阅读器

#### 核心方法

```swift
// 显示通知
func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0)

// 批量显示通知
func showBatch(_ messages: [String], type: ToastType, duration: TimeInterval = 3.0)

// 暂停/恢复自动消失
func pauseAutoDismiss(for toast: ToastMessage)
func resumeAutoDismiss(for toast: ToastMessage)

// 手动关闭
func dismiss(_ toast: ToastMessage)
func dismissAll()
```

### 3. 通知视图 (ToastView.swift)

单个通知的视觉呈现组件，具有丰富的交互功能。

#### 视觉设计

**现代化外观**：

- 圆角矩形设计 (12pt 圆角)
- 毛玻璃背景效果 (macOS 12+)
- 动态阴影和悬停效果
- 自适应深色/浅色模式

**布局结构**：

```
[图标] [消息文本]           [关闭按钮]
 20pt   多行文本，最多3行    悬停时显示
```

#### 交互功能

**鼠标交互**：

- 悬停时暂停自动消失
- 悬停时显示关闭按钮
- 点击关闭通知

**键盘操作**：

- `Escape` 键关闭
- `Space/Enter` 键关闭
- `Tab` 键导航

**手势支持**：

- 向上滑动关闭
- 拖拽反馈

#### 动画系统

**入场动画**：

- 从上方滑入 (-30pt)
- 缩放效果 (0.9 → 1.0)
- 透明度渐变 (0 → 1)
- 弹性动画效果

**悬停动画**：

- 轻微放大 (1.03x)
- 阴影增强
- 关闭按钮淡入

**退场动画**：

- 向上滑出
- 缩放缩小 (0.85x)
- 透明度消失

### 4. 容器管理 (ToastContainer.swift)

负责多个通知的布局、定位和堆叠效果。

#### 布局系统

**定位策略**：

- 顶部居中显示
- 考虑 macOS 标题栏和工具栏
- 响应式边距和安全区域
- 防止超出屏幕边界

**堆叠效果**：

- 最新通知在最上层
- 后续通知逐渐缩小 (0.94x)
- 透明度递减 (0.7 最小)
- 垂直偏移创建深度感

**响应式设计**：

- 窗口大小变化时自动调整
- 通知宽度自适应 (300-500pt)
- 动态计算容器高度

#### 性能优化

- 使用 `LazyVStack` 延迟加载
- 限制同时显示数量
- 高效的动画和过渡效果

### 5. 集成修饰器 (ToastModifier.swift)

提供便捷的 SwiftUI 集成方式。

#### 使用方式

```swift
// 基础集成
ContentView()
    .toast()

// 完整环境集成
ContentView()
    .toastEnvironment()

// 自定义管理器
ContentView()
    .toast(manager: customToastManager)
```

#### 高级功能

**全局支持**：

- 跨窗口通知管理
- 窗口生命周期监听
- 自动清理机制

**环境管理**：

- 自动注入 ToastManager
- 正确的 z-index 层级
- 触摸事件穿透

## 使用指南

### 基本使用

1. **添加 Toast 支持**：

```swift
struct ContentView: View {
    var body: some View {
        YourMainView()
            .toastEnvironment()  // 在根视图添加
    }
}
```

2. **显示通知**：

```swift
struct SomeView: View {
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        Button("显示成功通知") {
            toastManager.show("操作成功完成！", type: .success)
        }
    }
}
```

### 高级用法

**批量通知**：

```swift
let messages = ["文件1已保存", "文件2已保存", "文件3已保存"]
toastManager.showBatch(messages, type: .success, duration: 2.0)
```

**手动控制**：

```swift
// 显示不自动消失的通知
toastManager.show("需要用户确认", type: .warning, duration: 0)

// 手动关闭所有通知
toastManager.dismissAll()
```

**定时器控制**：

```swift
// 暂停特定通知的自动消失
toastManager.pauseAutoDismiss(for: toast)

// 恢复自动消失
toastManager.resumeAutoDismiss(for: toast)
```

### 无障碍最佳实践

1. **语音播报**：系统自动为重要通知播报内容
2. **键盘导航**：支持 Tab 键在通知间导航
3. **屏幕阅读器**：提供详细的状态描述
4. **优先级管理**：错误和警告通知具有更高优先级

## 技术特性

### 性能优化

- **内存管理**：自动清理过期定时器和状态
- **动画优化**：使用硬件加速的 Core Animation
- **响应式更新**：仅在必要时重新渲染
- **队列管理**：防止通知堆积影响性能

### 兼容性

- **系统要求**：macOS 15.5+
- **SwiftUI 版本**：支持最新 SwiftUI 特性
- **向后兼容**：为旧版本提供降级方案
- **深色模式**：完全支持系统外观切换

### 安全性

- **沙盒兼容**：符合 macOS 沙盒限制
- **内存安全**：使用 Swift 内存管理
- **线程安全**：防止并发访问问题

## 测试覆盖

系统包含全面的测试套件：

- **单元测试**：ToastManager 核心逻辑
- **UI 测试**：视图渲染和交互
- **集成测试**：组件间协作
- **无障碍测试**：辅助功能验证
- **性能测试**：内存和 CPU 使用

## 未来扩展

### 计划功能

1. **自定义主题**：支持用户自定义颜色和样式
2. **声音提示**：为不同类型通知添加音效
3. **持久化**：重要通知的本地存储
4. **网络集成**：远程通知支持
5. **插件系统**：第三方扩展接口

### 架构改进

1. **模块化**：进一步拆分独立模块
2. **配置系统**：运行时配置管理
3. **国际化**：多语言支持
4. **分析统计**：使用情况分析

## 总结

Toast 通知系统是一个功能完整、设计精良的 macOS 通知解决方案。它不仅提供了优秀的用户体验，还充分考虑了无障碍性、性能和可维护性。通过模块化的架构设计，系统具有良好的扩展性和复用性，能够满足各种应用场景的需求。

系统的核心优势：

- **用户友好**：直观的视觉设计和流畅的动画
- **无障碍**：完整的辅助功能支持
- **高性能**：优化的渲染和内存管理
- **易集成**：简单的 API 和灵活的配置
- **可扩展**：模块化架构支持功能扩展

这个 Toast 系统为应用程序提供了专业级的通知功能，提升了整体的用户体验和产品质量。
