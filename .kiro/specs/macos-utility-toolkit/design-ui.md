# UI设计规范文档

## 概述

本文档定义了 macOS 工具应用的UI设计规范，确保整个应用具有一致的视觉风格和用户体验。所有UI组件的设计和实现都应严格遵循本规范。

## 设计原则

### 1. 清晰明亮风格
- **高对比度设计**: 确保文字与背景有足够的对比度，提升可读性
- **明亮通透**: 使用大量留白空间，避免界面拥挤
- **清晰层次**: 通过颜色深浅、字体大小建立清晰的信息层次
- **圆角设计**: 适度使用圆角元素，营造现代感
- **微妙阴影**: 使用轻微的阴影效果增强层次感
- **双模式支持**: 完美适配浅色和深色模式，保持一致的视觉体验

### 2. 原生体验优先
- 遵循 macOS Human Interface Guidelines
- 使用系统原生控件和交互模式
- 保持与系统设计语言的一致性

### 3. 简洁明了
- 界面布局清晰，信息层次分明
- 避免不必要的装饰元素
- 突出核心功能，减少认知负担

### 4. 高效操作
- 常用功能易于访问
- 支持键盘快捷键
- 提供快速操作路径

## 布局规范

### 主界面布局

```swift
struct ContentView: View {
  @State private var selectedTool: NavigationManager.ToolType = .encryption
  
  var body: some View {
    NavigationSplitView {
      // 侧边栏：宽度 240pt
      SidebarView(selection: $selectedTool)
        .navigationSplitViewColumnWidth(240)
    } detail: {
      // 主内容区域：最小宽度 600pt
      ToolDetailView(tool: selectedTool)
        .navigationSplitViewColumnWidth(min: 600, ideal: 800)
    }
    .navigationSplitViewStyle(.balanced)
  }
}
```

### 侧边栏设计

```swift
struct SidebarView: View {
  @Binding var selection: NavigationManager.ToolType
  
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
```

## 颜色规范

### 系统颜色使用

```swift
// 主要颜色
.primary           // 主要文本颜色
.secondary         // 次要文本颜色
.tertiary          // 第三级文本颜色

// 背景颜色
.background        // 主背景色
.secondaryBackground // 次要背景色
.tertiaryBackground  // 第三级背景色

// 强调色
.accentColor       // 系统强调色
.blue             // 链接和按钮
.green            // 成功状态
.red              // 错误状态
.orange           // 警告状态
```

### 清晰明亮风格颜色方案

#### 浅色模式（明亮风格）
```swift
extension Color {
  // 主背景 - 纯白色，营造清晰明亮感
  static let lightModeBackground = Color.white
  
  // 次要背景 - 极浅灰色，保持层次感
  static let lightModeSecondaryBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
  
  // 卡片背景 - 带微妙阴影的白色
  static let lightModeCardBackground = Color.white
  
  // 边框颜色 - 浅灰色，清晰但不突兀
  static let lightModeBorder = Color(red: 0.9, green: 0.9, blue: 0.9)
  
  // 文本颜色 - 深色，确保高对比度
  static let lightModePrimaryText = Color(red: 0.1, green: 0.1, blue: 0.1)
  static let lightModeSecondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
}
```

#### 深色模式
```swift
extension Color {
  // 主背景 - 深色但不过黑，保持舒适感
  static let darkModeBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
  
  // 次要背景 - 稍浅的深色
  static let darkModeSecondaryBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
  
  // 卡片背景 - 中等深色
  static let darkModeCardBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
  
  // 边框颜色 - 中等灰色
  static let darkModeBorder = Color(red: 0.3, green: 0.3, blue: 0.3)
  
  // 文本颜色 - 浅色，确保可读性
  static let darkModePrimaryText = Color(red: 0.95, green: 0.95, blue: 0.95)
  static let darkModeSecondaryText = Color(red: 0.7, green: 0.7, blue: 0.7)
}
```

### 自适应颜色系统

```swift
extension Color {
  // 自适应背景色
  static let adaptiveBackground = Color(.systemBackground)
  static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)
  static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)
  
  // 自适应文本色
  static let adaptivePrimaryText = Color(.label)
  static let adaptiveSecondaryText = Color(.secondaryLabel)
  static let adaptiveTertiaryText = Color(.tertiaryLabel)
  
  // 自适应边框色
  static let adaptiveBorder = Color(.separator)
  static let adaptiveOpaqueBorder = Color(.opaqueSeparator)
  
  // 工具专用颜色
  static let toolBackground = Color(.controlBackgroundColor)
  static let toolBorder = Color(.separatorColor)
  static let toolText = Color(.labelColor)
  static let toolSecondaryText = Color(.secondaryLabelColor)
}
```

## 字体规范

### 字体层级

```swift
// 标题字体
.largeTitle        // 34pt - 页面主标题
.title             // 28pt - 区域标题
.title2            // 22pt - 子标题
.title3            // 20pt - 小标题

// 正文字体
.headline          // 17pt Bold - 重要信息
.body              // 17pt - 正文内容
.callout           // 16pt - 说明文字
.subheadline       // 15pt - 次要信息
.footnote          // 13pt - 辅助信息
.caption           // 12pt - 标签文字
.caption2          // 11pt - 最小文字
```

### 字体使用示例

```swift
struct ToolHeaderView: View {
  let title: String
  let description: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
      
      Text(description)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }
}
```

## 间距规范

### 标准间距值

```swift
enum Spacing {
  static let xs: CGFloat = 4      // 极小间距
  static let sm: CGFloat = 8      // 小间距
  static let md: CGFloat = 16     // 中等间距
  static let lg: CGFloat = 24     // 大间距
  static let xl: CGFloat = 32     // 极大间距
  static let xxl: CGFloat = 48    // 超大间距
}
```

### 间距使用规则

```swift
// 组件内部间距
.padding(.horizontal, Spacing.md)  // 水平内边距
.padding(.vertical, Spacing.sm)    // 垂直内边距

// 组件间距
VStack(spacing: Spacing.md) { }    // 垂直组件间距
HStack(spacing: Spacing.sm) { }    // 水平组件间距
```

## 清晰明亮风格特性

### 视觉特征
1. **高对比度**: 文字与背景之间保持高对比度，确保清晰可读
2. **充足留白**: 组件间使用充足的留白空间，避免拥挤感
3. **微妙阴影**: 使用轻微的阴影效果增加层次感，但不过度
4. **圆角设计**: 适度使用圆角，营造现代感和友好感
5. **清晰边界**: 使用清晰的边框线条区分不同区域

### 明亮风格实现

```swift
// 明亮风格卡片组件
struct BrightCardView<Content: View>: View {
  let content: Content
  
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  
  var body: some View {
    content
      .padding(Spacing.md)
      .background(Color.adaptiveBackground)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .shadow(
        color: Color.black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.adaptiveBorder.opacity(0.3), lineWidth: 1)
      )
  }
}
```

## 组件规范

### 输入框组件（明亮风格）

```swift
struct ToolTextField: View {
  let title: String
  @Binding var text: String
  let placeholder: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      Text(title)
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
      
      TextField(placeholder, text: $text, axis: .vertical)
        .textFieldStyle(BrightTextFieldStyle())
        .lineLimit(1...10)
    }
  }
}

// 明亮风格文本框样式
struct BrightTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(Spacing.sm)
      .background(Color.adaptiveBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.adaptiveBorder, lineWidth: 1.5)
      )
      .shadow(
        color: Color.black.opacity(0.03),
        radius: 2,
        x: 0,
        y: 1
      )
  }
}
```

### 按钮组件

```swift
struct ToolButton: View {
  let title: String
  let action: () -> Void
  let style: ButtonStyle
  
  enum ButtonStyle {
    case primary
    case secondary
    case destructive
  }
  
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.callout)
        .fontWeight(.medium)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
    .buttonStyle(buttonStyle)
  }
  
  private var buttonStyle: some PrimitiveButtonStyle {
    switch style {
    case .primary:
      return .borderedProminent
    case .secondary:
      return .bordered
    case .destructive:
      return .bordered
    }
  }
}
```

### 结果展示组件

```swift
struct ToolResultView: View {
  let title: String
  let content: String
  let canCopy: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      HStack {
        Text(title)
          .font(.callout)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
        
        Spacer()
        
        if canCopy {
          Button("复制") {
            NSPasteboard.general.setString(content, forType: .string)
          }
          .buttonStyle(.borderless)
          .font(.caption)
        }
      }
      
      ScrollView {
        Text(content)
          .font(.system(.body, design: .monospaced))
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(minHeight: 100, maxHeight: 300)
      .background(Color.toolBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.toolBorder, lineWidth: 1)
      )
    }
  }
}
```

## 交互规范

### 状态反馈

```swift
struct ProcessingStateView: View {
  let isProcessing: Bool
  let message: String
  
  var body: some View {
    HStack(spacing: Spacing.sm) {
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
```

### 错误提示

```swift
struct ErrorAlertModifier: ViewModifier {
  @Binding var error: ToolError?
  
  func body(content: Content) -> some View {
    content
      .alert("错误", isPresented: .constant(error != nil)) {
        Button("确定") {
          error = nil
        }
      } message: {
        if let error = error {
          Text(error.localizedDescription)
        }
      }
  }
}

extension View {
  func errorAlert(_ error: Binding<ToolError?>) -> some View {
    modifier(ErrorAlertModifier(error: error))
  }
}
```

## 响应式设计

### 窗口尺寸适配

```swift
struct AdaptiveToolView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  
  var body: some View {
    Group {
      if horizontalSizeClass == .compact {
        // 紧凑布局（窗口较小时）
        VStack(spacing: Spacing.md) {
          inputSection
          outputSection
        }
      } else {
        // 常规布局（窗口较大时）
        HStack(spacing: Spacing.lg) {
          inputSection
          outputSection
        }
      }
    }
  }
  
  private var inputSection: some View {
    // 输入区域
    VStack { }
  }
  
  private var outputSection: some View {
    // 输出区域
    VStack { }
  }
}
```

## 动画规范

### 标准动画

```swift
// 淡入淡出
.opacity(isVisible ? 1 : 0)
.animation(.easeInOut(duration: 0.3), value: isVisible)

// 滑动效果
.offset(x: isShowing ? 0 : -100)
.animation(.spring(response: 0.5, dampingFraction: 0.8), value: isShowing)

// 缩放效果
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)
```

## 可访问性规范

### 语义标记

```swift
struct AccessibleToolView: View {
  var body: some View {
    VStack {
      Text("加密工具")
        .accessibilityAddTraits(.isHeader)
      
      TextField("输入文本", text: $inputText)
        .accessibilityLabel("待加密文本输入框")
        .accessibilityHint("输入需要加密的文本内容")
      
      Button("加密") { }
        .accessibilityLabel("执行加密")
        .accessibilityHint("对输入的文本进行加密处理")
    }
  }
}
```

## 性能优化

### 视图优化

```swift
// 使用 LazyVStack 处理大量数据
LazyVStack(spacing: Spacing.sm) {
  ForEach(items) { item in
    ItemView(item: item)
  }
}

// 避免不必要的重绘
struct OptimizedView: View {
  let staticData: String
  @State private var dynamicData: String = ""
  
  var body: some View {
    VStack {
      // 静态内容使用 equatable
      StaticContentView(data: staticData)
        .equatable()
      
      // 动态内容正常处理
      DynamicContentView(data: dynamicData)
    }
  }
}
```

## 代码组织规范

### 文件结构

```
Features/
├── Encryption/
│   ├── Views/
│   │   ├── EncryptionView.swift
│   │   └── Components/
│   │       ├── AlgorithmPicker.swift
│   │       └── ResultDisplay.swift
│   ├── Models/
│   │   └── EncryptionModels.swift
│   └── Utils/
│       └── EncryptionUtils.swift
```

### 视图组件命名

```swift
// 主视图：功能名 + View
struct EncryptionView: View { }

// 子组件：描述性名称 + View
struct AlgorithmPickerView: View { }
struct ResultDisplayView: View { }

// 工具组件：Tool + 功能名
struct ToolTextField: View { }
struct ToolButton: View { }
```

## 测试规范

### UI测试

```swift
struct EncryptionView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // 默认状态
      EncryptionView()
        .previewDisplayName("默认状态")
      
      // 深色模式
      EncryptionView()
        .preferredColorScheme(.dark)
        .previewDisplayName("深色模式")
      
      // 紧凑尺寸
      EncryptionView()
        .previewInterfaceOrientation(.portrait)
        .previewDisplayName("紧凑布局")
    }
  }
}
```

## 国际化规范

### 文本本地化

```swift
// 使用 LocalizedStringKey
Text("encryption.title")
Button("common.copy") { }

// 字符串插值
Text("result.processed_items_\(count)")
```

### 布局适配

```swift
// 支持从右到左的语言
HStack {
  leadingContent
  Spacer()
  trailingContent
}
.environment(\.layoutDirection, .rightToLeft) // 测试用
```

这个UI设计规范文档将确保整个应用的视觉一致性和用户体验质量。在实现每个功能模块时，都应该参考这个文档来保证设计的统一性。