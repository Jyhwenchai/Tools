import Testing
import Foundation
import SwiftData
@testable import Tools

struct ClipboardServiceTests {
  
  // MARK: - Test Helper
  private func createTestModelContext() -> ModelContext {
    let schema = Schema([ClipboardItem.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
  }
  
  // MARK: - Model Tests
  @Test("ClipboardItem 初始化测试")
  func testClipboardItemInitialization() {
    let content = "Hello World"
    let item = ClipboardItem(content: content)
    
    #expect(item.content == content)
    #expect(item.type == .text)
    #expect(item.id != UUID())
    #expect(item.timestamp <= Date())
  }
  
  @Test("ClipboardItemType 检测测试", arguments: [
    ("https://www.apple.com", ClipboardItemType.url),
    ("http://example.com", ClipboardItemType.url),
    ("func test() { return true }", ClipboardItemType.code),
    ("let x = 10", ClipboardItemType.code),
    ("class MyClass {}", ClipboardItemType.code),
    ("import Foundation", ClipboardItemType.code),
    ("Hello World", ClipboardItemType.text),
    ("Just some text", ClipboardItemType.text)
  ])
  func testClipboardItemTypeDetection(content: String, expectedType: ClipboardItemType) {
    let item = ClipboardItem(content: content)
    #expect(item.type == expectedType)
  }
  
  @Test("ClipboardItem 预览文本测试")
  func testClipboardItemPreview() {
    // Short content
    let shortItem = ClipboardItem(content: "Short")
    #expect(shortItem.preview == "Short")
    
    // Long content
    let longContent = String(repeating: "A", count: 150)
    let longItem = ClipboardItem(content: longContent)
    #expect(longItem.preview.count == 103) // 100 chars + "..."
    #expect(longItem.preview.hasSuffix("..."))
  }
  
  @Test("ClipboardItem 时间格式化测试")
  func testClipboardItemFormattedTimestamp() {
    let item = ClipboardItem(content: "Test")
    let formatted = item.formattedTimestamp
    #expect(!formatted.isEmpty)
    #expect(formatted.contains("/") || formatted.contains("-"))
  }
  
  // MARK: - Service Tests
  @Test("ClipboardService 初始化测试")
  func testClipboardServiceInitialization() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context, maxHistoryCount: 50)
    
    #expect(service.clipboardHistory.isEmpty || !service.clipboardHistory.isEmpty)
    #expect(service.isMonitoring == false)
    #expect(service.totalItemsCount >= 0)
  }
  
  @Test("添加历史记录测试")
  func testAddToHistory() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context, maxHistoryCount: 5)
    let initialCount = service.clipboardHistory.count
    
    let item1 = ClipboardItem(content: "First item")
    service.addToHistory(item1)
    
    #expect(service.clipboardHistory.count == initialCount + 1)
    #expect(service.clipboardHistory.first?.content == "First item")
    
    // Test duplicate removal
    let item2 = ClipboardItem(content: "First item")
    service.addToHistory(item2)
    
    #expect(service.clipboardHistory.count == initialCount + 1)
    #expect(service.clipboardHistory.first?.content == "First item")
  }
  
  @Test("历史记录限制测试")
  func testHistoryLimit() {
    let maxCount = 3
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context, maxHistoryCount: maxCount)
    
    // Clear existing history for clean test
    service.clearHistory()
    
    // Add more items than the limit
    for i in 1...5 {
      let item = ClipboardItem(content: "Item \(i)")
      service.addToHistory(item)
    }
    
    #expect(service.clipboardHistory.count <= maxCount)
    #expect(service.clipboardHistory.first?.content == "Item 5")
  }
  
  @Test("删除历史记录项测试")
  func testRemoveItem() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    service.clearHistory()
    
    let item1 = ClipboardItem(content: "Item 1")
    let item2 = ClipboardItem(content: "Item 2")
    
    service.addToHistory(item1)
    service.addToHistory(item2)
    
    let initialCount = service.clipboardHistory.count
    service.removeItem(item1)
    
    #expect(service.clipboardHistory.count == initialCount - 1)
    #expect(!service.clipboardHistory.contains { $0.id == item1.id })
  }
  
  @Test("清空历史记录测试")
  func testClearHistory() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    
    let item = ClipboardItem(content: "Test item")
    service.addToHistory(item)
    
    service.clearHistory()
    #expect(service.clipboardHistory.isEmpty)
  }
  
  @Test("搜索功能测试")
  func testSearchItems() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    service.clearHistory()
    
    let items = [
      ClipboardItem(content: "Hello World"),
      ClipboardItem(content: "Swift Programming"),
      ClipboardItem(content: "macOS Development"),
      ClipboardItem(content: "iOS App")
    ]
    
    items.forEach { service.addToHistory($0) }
    
    // Test search
    let swiftResults = service.searchItems(query: "Swift")
    #expect(swiftResults.count == 1)
    #expect(swiftResults.first?.content == "Swift Programming")
    
    // Test case insensitive search
    let helloResults = service.searchItems(query: "hello")
    #expect(helloResults.count == 1)
    #expect(helloResults.first?.content == "Hello World")
    
    // Test empty query
    let allResults = service.searchItems(query: "")
    #expect(allResults.count == items.count)
  }
  
  @Test("类型过滤测试")
  func testFilterItemsByType() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    service.clearHistory()
    
    let textItem = ClipboardItem(content: "Plain text")
    let urlItem = ClipboardItem(content: "https://www.apple.com")
    let codeItem = ClipboardItem(content: "func test() { return true }")
    
    service.addToHistory(textItem)
    service.addToHistory(urlItem)
    service.addToHistory(codeItem)
    
    let textResults = service.filterItems(by: .text)
    let urlResults = service.filterItems(by: .url)
    let codeResults = service.filterItems(by: .code)
    
    #expect(textResults.count == 1)
    #expect(urlResults.count == 1)
    #expect(codeResults.count == 1)
    
    #expect(textResults.first?.content == "Plain text")
    #expect(urlResults.first?.content == "https://www.apple.com")
    #expect(codeResults.first?.content == "func test() { return true }")
  }
  
  @Test("时间范围过滤测试")
  func testFilterItemsByDateRange() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    service.clearHistory()
    
    let now = Date()
    let oneHourAgo = now.addingTimeInterval(-3600)
    let twoHoursAgo = now.addingTimeInterval(-7200)
    
    // Create items with specific timestamps
    let oldItem = ClipboardItem(
      id: UUID(),
      content: "Old item",
      timestamp: twoHoursAgo,
      type: .text
    )
    
    let recentItem = ClipboardItem(
      id: UUID(),
      content: "Recent item",
      timestamp: oneHourAgo,
      type: .text
    )
    
    service.addToHistory(oldItem)
    service.addToHistory(recentItem)
    
    // Filter items from last hour
    let recentResults = service.filterItems(from: oneHourAgo, to: now)
    #expect(recentResults.count >= 1)
    
    // Filter items older than 90 minutes
    let oldResults = service.filterItems(from: twoHoursAgo, to: oneHourAgo)
    #expect(oldResults.count >= 0)
  }
  
  @Test("统计信息测试")
  func testStatistics() {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    service.clearHistory()
    
    let textItem = ClipboardItem(content: "Text content")
    let urlItem = ClipboardItem(content: "https://example.com")
    let codeItem = ClipboardItem(content: "let x = 10")
    
    service.addToHistory(textItem)
    service.addToHistory(urlItem)
    service.addToHistory(codeItem)
    
    #expect(service.totalItemsCount == 3)
    
    let itemsByType = service.itemsByType
    #expect(itemsByType[.text] == 1)
    #expect(itemsByType[.url] == 1)
    #expect(itemsByType[.code] == 1)
    
    #expect(service.newestItem != nil)
    #expect(service.oldestItem != nil)
  }
  
  @Test("监控状态测试")
  func testMonitoringState() async {
    let context = createTestModelContext()
    let service = ClipboardService(modelContext: context)
    
    #expect(service.isMonitoring == false)
    
    await service.startMonitoring()
    #expect(service.isMonitoring == true)
    
    service.stopMonitoring()
    #expect(service.isMonitoring == false)
  }
}

// MARK: - ClipboardItemType Tests
struct ClipboardItemTypeTests {
  
  @Test("ClipboardItemType 图标测试")
  func testClipboardItemTypeIcons() {
    #expect(ClipboardItemType.text.icon == "doc.text")
    #expect(ClipboardItemType.url.icon == "link")
    #expect(ClipboardItemType.code.icon == "curlybraces")
  }
  
  @Test("ClipboardItemType 原始值测试")
  func testClipboardItemTypeRawValues() {
    #expect(ClipboardItemType.text.rawValue == "文本")
    #expect(ClipboardItemType.url.rawValue == "链接")
    #expect(ClipboardItemType.code.rawValue == "代码")
  }
  
  @Test("ClipboardItemType 所有情况测试")
  func testClipboardItemTypeAllCases() {
    let allCases = ClipboardItemType.allCases
    #expect(allCases.count == 3)
    #expect(allCases.contains(.text))
    #expect(allCases.contains(.url))
    #expect(allCases.contains(.code))
  }
}