# JSON WebView 增强功能总结

## 概述

我们成功为 JSON 工具添加了原生的展开、收起和搜索功能，通过在 JSON 输出结果下方添加控制工具栏来实现对 WebView 中 JSON 编辑器的控制。

## 实现的功能

### 1. 原生控制工具栏

在 `JSONWebView` 中添加了一个控制工具栏，包含以下功能：

#### 展开/收起控制
- **展开按钮**: 使用 `chevron.down.circle` SF Symbol，点击展开所有 JSON 节点
- **收起按钮**: 使用 `chevron.up.circle` SF Symbol，点击收起所有 JSON 节点

#### 搜索功能
- **搜索按钮**: 使用 `magnifyingglass` SF Symbol，点击激活搜索模式
- **搜索输入框**: 实时搜索 JSON 内容，支持高亮显示匹配结果
- **清除搜索**: 使用 `xmark.circle.fill` SF Symbol，清除搜索内容并退出搜索模式

### 2. JavaScript 接口扩展

在 `jsonviewer.html` 中添加了以下 JavaScript 函数：

```javascript
// 展开/收起功能
window.expandAll()      // 展开所有节点
window.collapseAll()    // 收起所有节点
window.toggleExpand(path) // 切换指定路径节点的展开状态

// 搜索功能
window.searchJSON(query)  // 搜索指定内容
window.clearSearch()      // 清除搜索

// 数据获取
window.getCurrentJSON()   // 获取当前 JSON 数据
```

### 3. 通知系统

实现了基于 `NotificationCenter` 的通信机制：

```swift
// 通知名称定义
extension Notification.Name {
  static let jsonExpandAll = Notification.Name("jsonExpandAll")
  static let jsonCollapseAll = Notification.Name("jsonCollapseAll")
  static let jsonSearch = Notification.Name("jsonSearch")
  static let jsonClearSearch = Notification.Name("jsonClearSearch")
}
```

### 4. WebView 协调器增强

在 `_PlatformWebView.Coordinator` 中添加了：
- 通知观察者设置
- JavaScript 函数调用
- 错误处理机制
- 自动清理功能

## 设计特点

### 1. 适配性设计
- **主题适配**: 自动适配系统的明暗主题
- **SF Symbols**: 使用系统原生图标，保持一致的视觉体验
- **响应式布局**: 工具栏自适应不同屏幕尺寸

### 2. 用户体验
- **直观操作**: 清晰的图标和文字标签
- **实时反馈**: 搜索结果实时高亮显示
- **状态管理**: 搜索模式的进入和退出状态清晰

### 3. 技术架构
- **松耦合设计**: 通过通知系统实现 SwiftUI 和 WebView 的解耦
- **错误处理**: 完善的 JavaScript 执行错误处理
- **内存管理**: 自动清理通知观察者，避免内存泄漏

## 文件修改清单

### 新增文件
- `Tools/ToolsTests/JSONWebViewTests.swift` - 测试文件

### 修改文件
- `Tools/Tools/Features/JSON/Views/JSONWebView.swift` - 主要实现文件
- `Tools/Tools/Resources/jsonviewer.html` - JavaScript 接口扩展

## 使用方式

### 从 Swift 代码调用
```swift
// 展开所有节点
webView.evaluateJavaScript("expandAll()")

// 搜索内容
webView.evaluateJavaScript("searchJSON('your search term')")

// 收起所有节点
webView.evaluateJavaScript("collapseAll()")
```

### 用户界面操作
1. 在 JSON 工具中输入或加载 JSON 数据
2. 在输出区域的 JSON 预览上方可以看到控制工具栏
3. 点击相应按钮进行展开、收起或搜索操作

## 技术优势

1. **原生体验**: 使用 SwiftUI 和 SF Symbols 提供原生 macOS 体验
2. **高性能**: 基于成熟的 JSONEditor 库，性能优异
3. **可扩展**: 通过通知系统可以轻松添加更多控制功能
4. **兼容性**: 支持 macOS 和 iOS 平台（通过条件编译）

## 未来扩展

可以考虑添加的功能：
- JSON 路径导航
- 节点编辑功能
- 导出功能
- 更多搜索选项（正则表达式、大小写敏感等）
- 键盘快捷键支持

## 总结

这次增强成功地为 JSON 工具添加了用户期待的原生控制功能，提升了用户体验，同时保持了代码的整洁性和可维护性。通过合理的架构设计，为未来的功能扩展奠定了良好的基础。