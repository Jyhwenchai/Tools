# 设计文档

## 概述

macOS 工具应用将采用 SwiftUI 框架构建，提供现代化的用户界面和流畅的用户体验。应用采用模块化架构设计，每个工具功能作为独立模块，便于维护和扩展。应用将遵循 macOS 设计规范，提供原生的 macOS 体验。

## 架构设计

### 整体架构

应用采用 MV (Model-View) 架构模式，使用 Observable 宏进行数据流管理：

```
┌─────────────────┐    ┌─────────────────┐
│      View       │◄──►│     Model       │
│   (SwiftUI)     │    │  (@Observable)  │
└─────────────────┘    └─────────────────┘
```

### 模块结构

```
Tools/
├── App/
│   ├── ToolsApp.swift          # 应用入口
│   └── ContentView.swift       # 主界面
├── Core/
│   ├── Navigation/             # 导航管理
│   ├── Storage/               # 数据存储
│   └── Extensions/            # 扩展工具
├── Features/
│   ├── Encryption/            # 加密解密模块
│   ├── JSON/                  # JSON处理模块
│   ├── ImageProcessing/       # 图片处理模块
│   ├── QRCode/               # 二维码模块
│   ├── TimeConverter/        # 时间转换模块
│   └── Clipboard/            # 粘贴板模块
├── Shared/
│   ├── Components/           # 共享UI组件
│   ├── Models/              # 数据模型
│   └── Utils/               # 工具类
└── Resources/
    └── Assets.xcassets      # 资源文件
```

## 组件和接口设计

### 主界面设计

主界面采用侧边栏 + 内容区域的布局：

```swift
struct ContentView: View {
  @State private var navigationManager = NavigationManager()
  
  var body: some View {
    NavigationSplitView {
      SidebarView(selection: $navigationManager.selectedTool)
    } detail: {
      ToolDetailView(tool: navigationManager.selectedTool)
    }
  }
}
```

### 核心接口定义

#### 工具协议
```swift
protocol ToolProtocol {
  var id: String { get }
  var name: String { get }
  var icon: String { get }
  var description: String { get }
}

protocol ProcessableToolProtocol: ToolProtocol {
  associatedtype Input
  associatedtype Output
  
  func process(_ input: Input) async throws -> Output
}
```

#### 导航管理器
```swift
@Observable
class NavigationManager {
  var selectedTool: ToolType = .encryption
  
  enum ToolType: String, CaseIterable {
    case encryption = "加密解密"
    case json = "JSON工具"
    case imageProcessing = "图片处理"
    case qrCode = "二维码"
    case timeConverter = "时间转换"
    case clipboard = "粘贴板"
  }
}
```

### 各模块详细设计

#### 1. 加密解密模块

```swift
// 模型
enum EncryptionAlgorithm: String, CaseIterable {
  case md5 = "MD5"
  case sha1 = "SHA1"
  case sha256 = "SHA256"
  case base64 = "Base64"
  case aes = "AES"
}

struct EncryptionResult {
  let algorithm: EncryptionAlgorithm
  let input: String
  let output: String
  let isEncryption: Bool
}

// View with Observable
struct EncryptionView: View {
  @State private var inputText: String = ""
  @State private var outputText: String = ""
  @State private var selectedAlgorithm: EncryptionAlgorithm = .md5
  @State private var isEncrypting: Bool = true
  
  var body: some View {
    VStack {
      // UI implementation
    }
  }
  
  private func processText() async {
    // 加密/解密逻辑
  }
}
```

#### 2. JSON处理模块

```swift
// 模型
enum JSONOperation {
  case format
  case minify
  case validate
  case generateModel(language: ProgrammingLanguage)
}

enum ProgrammingLanguage: String, CaseIterable {
  case swift = "Swift"
  case java = "Java"
  case python = "Python"
  case typescript = "TypeScript"
}

// View with Observable
struct JSONView: View {
  @State private var inputJSON: String = ""
  @State private var outputText: String = ""
  @State private var isValidJSON: Bool = false
  @State private var selectedLanguage: ProgrammingLanguage = .swift
  
  var body: some View {
    VStack {
      // UI implementation
    }
  }
  
  private func formatJSON() { }
  private func minifyJSON() { }
  private func validateJSON() -> Bool { }
  private func generateModel() { }
}
```

#### 3. 图片处理模块

```swift
// 模型
struct ImageProcessingOptions {
  var compressionQuality: Double = 0.8
  var targetSize: CGSize?
  var cropRect: CGRect?
  var watermarkText: String?
  var watermarkOpacity: Double = 0.5
}

enum ImageFormat: String, CaseIterable {
  case png = "PNG"
  case jpeg = "JPEG"
  case gif = "GIF"
  case webp = "WebP"
}

// View with Observable
struct ImageProcessingView: View {
  @State private var selectedImage: NSImage?
  @State private var processedImage: NSImage?
  @State private var processingOptions = ImageProcessingOptions()
  
  var body: some View {
    VStack {
      // UI implementation
    }
  }
  
  private func compressImage() async { }
  private func resizeImage() async { }
  private func cropImage() async { }
  private func addWatermark() async { }
  private func convertFormat(to format: ImageFormat) async { }
}
```

#### 4. 二维码模块

```swift
// 模型
struct QRCodeOptions {
  var size: CGSize = CGSize(width: 200, height: 200)
  var correctionLevel: QRCodeCorrectionLevel = .medium
  var foregroundColor: Color = .black
  var backgroundColor: Color = .white
}

enum QRCodeCorrectionLevel: String, CaseIterable {
  case low = "L"
  case medium = "M"
  case quartile = "Q"
  case high = "H"
}

// View with Observable
struct QRCodeView: View {
  @State private var inputText: String = ""
  @State private var generatedQRCode: NSImage?
  @State private var scannedText: String = ""
  @State private var options = QRCodeOptions()
  
  var body: some View {
    VStack {
      // UI implementation
    }
  }
  
  private func generateQRCode() { }
  private func scanQRCode(from image: NSImage) { }
}
```

#### 5. 时间转换模块

```swift
// 模型
enum TimeFormat {
  case timestamp
  case iso8601
  case custom(String)
}

struct TimeConversionResult {
  let originalValue: String
  let convertedValue: String
  let sourceFormat: TimeFormat
  let targetFormat: TimeFormat
}

// View with Observable
struct TimeConverterView: View {
  @State private var inputTime: String = ""
  @State private var outputTime: String = ""
  @State private var selectedTimeZone: TimeZone = .current
  @State private var sourceFormat: TimeFormat = .timestamp
  @State private var targetFormat: TimeFormat = .iso8601
  
  var body: some View {
    VStack {
      // UI implementation
    }
  }
  
  private func convertTime() { }
}
```

#### 6. 粘贴板模块

```swift
// 模型
struct ClipboardItem: Identifiable, Codable {
  let id = UUID()
  let content: String
  let timestamp: Date
  let type: ClipboardItemType
}

enum ClipboardItemType: String, Codable, CaseIterable {
  case text = "文本"
  case url = "链接"
  case code = "代码"
}

// View with Observable
struct ClipboardView: View {
  @State private var clipboardHistory: [ClipboardItem] = []
  @State private var searchText: String = ""
  
  private let maxHistoryCount = 100
  
  var body: some View {
    VStack {
      // UI implementation
    }
  }
  
  private func addToHistory(_ content: String) { }
  private func removeItem(_ item: ClipboardItem) { }
  private func clearHistory() { }
  private func copyToClipboard(_ content: String) { }
}
```

## 数据模型

### 核心数据模型

```swift
// 应用设置
struct AppSettings: Codable {
  var theme: AppTheme = .system
  var maxClipboardHistory: Int = 100
  var autoSaveResults: Bool = true
  var defaultImageQuality: Double = 0.8
}

enum AppTheme: String, CaseIterable, Codable {
  case light = "浅色"
  case dark = "深色"
  case system = "跟随系统"
}

// 工具使用统计
struct ToolUsageStats: Codable {
  var toolType: String
  var usageCount: Int
  var lastUsed: Date
}
```

## 错误处理

### 错误类型定义

```swift
enum ToolError: LocalizedError {
  case invalidInput(String)
  case processingFailed(String)
  case fileAccessDenied
  case networkError(Error)
  case unsupportedFormat
  
  var errorDescription: String? {
    switch self {
    case .invalidInput(let message):
      return "输入无效: \(message)"
    case .processingFailed(let message):
      return "处理失败: \(message)"
    case .fileAccessDenied:
      return "文件访问被拒绝"
    case .networkError(let error):
      return "网络错误: \(error.localizedDescription)"
    case .unsupportedFormat:
      return "不支持的格式"
    }
  }
}
```

### 错误处理策略

1. **用户友好的错误提示**: 所有错误都会转换为用户可理解的中文提示
2. **错误恢复**: 提供重试机制和替代方案
3. **错误日志**: 记录详细的错误信息用于调试
4. **优雅降级**: 在部分功能失效时，其他功能仍可正常使用

## 代码规范

### 代码风格

项目采用以下代码规范：

1. **缩进**: 使用2个空格进行缩进，不使用Tab
2. **SwiftFormat**: 使用SwiftFormat进行代码格式化
3. **SwiftLint**: 使用SwiftLint进行代码质量检查
4. **命名规范**: 
   - 类型名使用PascalCase（如：`EncryptionView`）
   - 变量和函数名使用camelCase（如：`inputText`）
   - 常量使用camelCase（如：`maxHistoryCount`）
5. **文件组织**: 按功能模块组织文件结构
6. **注释**: 使用中文注释说明复杂逻辑

### 开发流程规范

1. **技术选型**: 开始实现每个功能前，优先考虑使用原生API实现，如果原生无法满足需求，再评估合适的第三方库
2. **测试驱动开发**: 每完成一个新的任务都必须编写对应的测试用例
3. **测试验证**: 编写测试用例后，必须运行测试确保所有测试通过
4. **编译验证**: 测试通过后，必须进行编译确保编译通过，无编译错误和警告
5. **任务完成确认**: 只有在测试通过且编译通过后，才能进行下一个任务
6. **代码审查**: 使用SwiftLint检查代码质量，确保符合规范
7. **增量开发**: 按模块逐步开发，每个模块完成后进行完整的测试验证

#### 严格的开发流程
每个任务的执行必须遵循以下严格顺序：
1. 实现功能代码
2. 编写对应的测试用例
3. 运行测试，确保所有测试通过
4. 编译项目，确保编译成功
5. 修复任何测试失败或编译错误
6. 重复步骤3-5直到测试和编译都通过
7. 才能开始下一个任务

这个流程确保了代码质量和项目稳定性，避免了技术债务的积累。

### 配置文件

```yaml
# .swiftformat
--indent 2
--tabwidth 2
--maxwidth 100
--wraparguments before-first
--wrapcollections before-first
--closingparen same-line
--commas inline
--trimwhitespace always
--insertlines always
--removelines always
```

```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - force_unwrapping
line_length: 100
identifier_name:
  min_length: 2
  max_length: 40
```

## 测试策略

### Swift Testing 框架

项目使用 Swift Testing 框架进行测试，提供现代化的测试体验：

```swift
import Testing
@testable import Tools

struct EncryptionServiceTests {
  
  @Test("MD5 哈希算法测试")
  func testMD5Hashing() async throws {
    let service = EncryptionService()
    let input = "Hello World"
    let result = try await service.hash(input, algorithm: .md5)
    #expect(result == "b10a8db164e0754105b7a99be72e3fe5")
  }
  
  @Test("Base64 编码解码测试", arguments: [
    ("Hello", "SGVsbG8="),
    ("World", "V29ybGQ="),
    ("Swift", "U3dpZnQ=")
  ])
  func testBase64Encoding(input: String, expected: String) throws {
    let service = EncryptionService()
    let encoded = try service.base64Encode(input)
    #expect(encoded == expected)
    
    let decoded = try service.base64Decode(encoded)
    #expect(decoded == input)
  }
}
```

### 单元测试

- **Service层测试**: 使用 `@Test` 注解测试核心业务逻辑
- **Model测试**: 测试数据模型的序列化和验证
- **算法测试**: 使用参数化测试验证加密、JSON处理等算法
- **Observable状态测试**: 测试状态变化和数据绑定

```swift
struct JSONServiceTests {
  
  @Test("JSON 格式化测试")
  func testJSONFormatting() throws {
    let service = JSONService()
    let input = """{"name":"John","age":30}"""
    let formatted = try service.format(input)
    #expect(formatted.contains("  \"name\" : \"John\""))
  }
  
  @Test("JSON 验证测试", arguments: [
    ("""{"valid": true}""", true),
    ("""{"invalid": }""", false),
    ("""not json at all""", false)
  ])
  func testJSONValidation(json: String, isValid: Bool) {
    let service = JSONService()
    #expect(service.isValid(json) == isValid)
  }
}
```

### 集成测试

- **UI交互测试**: 使用 `@Test` 测试用户界面的交互流程
- **文件操作测试**: 测试图片导入导出功能
- **导航流程测试**: 测试不同工具间的切换

```swift
struct NavigationTests {
  
  @Test("导航状态切换测试")
  func testNavigationStateChanges() {
    let manager = NavigationManager()
    #expect(manager.selectedTool == .encryption)
    
    manager.selectedTool = .json
    #expect(manager.selectedTool == .json)
  }
}
```

### 性能测试

- **大文件处理**: 使用 `@Test(.timeLimit(.seconds(5)))` 测试性能
- **内存使用**: 监控应用的内存占用
- **响应时间**: 确保UI操作的响应速度

```swift
struct PerformanceTests {
  
  @Test("大文件加密性能测试", .timeLimit(.seconds(2)))
  func testLargeFileEncryption() async throws {
    let service = EncryptionService()
    let largeText = String(repeating: "A", count: 100000)
    let result = try await service.hash(largeText, algorithm: .sha256)
    #expect(!result.isEmpty)
  }
}
```

### 测试组织和标签

```swift
// 使用标签组织测试
@Test("加密算法测试", .tags(.encryption))
func testEncryption() { }

@Test("JSON处理测试", .tags(.json))
func testJSONProcessing() { }

// 自定义测试标签
extension Tag {
  @Tag static var encryption: Self
  @Tag static var json: Self
  @Tag static var ui: Self
  @Tag static var performance: Self
}
```

## 技术实现细节

### 技术选型策略

每个功能模块的技术选型遵循以下原则：

#### 原生API优先
1. **加密解密**: 优先使用系统原生的 `CryptoKit` 和 `CommonCrypto`
2. **JSON处理**: 使用原生的 `JSONSerialization` 和 `Codable`
3. **图片处理**: 优先使用 `Core Image` 和 `ImageIO`
4. **二维码**: 使用原生的 `Core Image` 生成，`Vision` 框架识别
5. **时间处理**: 使用原生的 `Foundation` 时间API
6. **粘贴板**: 使用原生的 `NSPasteboard`

#### 第三方库备选方案
当原生API无法满足需求时，考虑以下第三方库：

**加密解密模块**:
- 如需更多算法支持，考虑 `CryptoSwift`
- 对于特殊加密需求，评估 `OpenSSL` 封装库

**JSON处理模块**:
- 代码生成功能可能需要 `Sourcery` 或自定义模板引擎
- 复杂JSON操作可考虑 `SwiftyJSON`

**图片处理模块**:
- WebP格式支持可能需要 `libwebp`
- 高级图片处理可考虑 `GPUImage`

**二维码模块**:
- 如需更多自定义选项，可考虑 `QRCode` 库

### 依赖管理

- **Swift Package Manager**: 优先使用SPM管理依赖
- **最小化依赖**: 只在必要时引入第三方库
- **版本锁定**: 锁定依赖版本确保构建稳定性
- **定期更新**: 定期评估和更新依赖库版本

### 数据持久化

- **UserDefaults**: 存储应用设置和简单配置
- **Core Data**: 存储粘贴板历史和使用统计
- **文件系统**: 存储导出的文件和临时数据

### 性能优化

1. **异步处理**: 所有耗时操作都在后台线程执行
2. **内存管理**: 及时释放大对象，避免内存泄漏
3. **懒加载**: 按需加载工具模块和资源
4. **缓存策略**: 缓存常用的处理结果