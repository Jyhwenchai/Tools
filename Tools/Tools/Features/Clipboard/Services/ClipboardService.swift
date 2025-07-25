import AppKit
import Foundation
import Observation
import SwiftData

@Observable
class ClipboardService {
  // MARK: - Properties

  private var pasteboard = NSPasteboard.general
  private let maxHistoryCount: Int
  private var modelContext: ModelContext
  private let securityService = SecurityService.shared
  
  // Monitoring properties
  private var monitoringTimer: Timer?
  private var lastChangeCount: Int = 0
  private var isMonitoring = false

  // Observable properties
  var clipboardHistory: [ClipboardItem] = []

  // MARK: - Initialization

  init(modelContext: ModelContext, maxHistoryCount: Int = 100) {
    self.modelContext = modelContext
    self.maxHistoryCount = maxHistoryCount
    self.lastChangeCount = pasteboard.changeCount
    loadHistoryFromStorage()
    setupSecurityNotifications()
    startMonitoring()
  }

  deinit {
    stopMonitoring()
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Security Integration

  private func setupSecurityNotifications() {
    NotificationCenter.default.addObserver(
      forName: .clearSensitiveData,
      object: nil,
      queue: .main) { [weak self] _ in
      self?.clearSensitiveClipboardData()
    }
  }

  private func clearSensitiveClipboardData() {
    // Clear clipboard history if it contains sensitive data
    clearHistory()
  }

  // MARK: - Clipboard Monitoring
  
  func startMonitoring() {
    guard !isMonitoring else { return }
    
    isMonitoring = true
    monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.checkClipboardChanges()
    }
  }
  
  func stopMonitoring() {
    isMonitoring = false
    monitoringTimer?.invalidate()
    monitoringTimer = nil
  }
  
  private func checkClipboardChanges() {
    let currentChangeCount = pasteboard.changeCount
    
    // Check if clipboard content has changed
    if currentChangeCount != lastChangeCount {
      lastChangeCount = currentChangeCount
      
      // Get current clipboard content
      if let content = pasteboard.string(forType: .string),
         !content.isEmpty,
         !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        
        // Check if this content is different from the most recent item
        if let lastItem = clipboardHistory.first,
           lastItem.content == content {
          return // Same content, no need to add
        }
        
        // Add new content to history
        addContentManually(content)
      }
    }
  }

  // MARK: - Manual Content Operations

  func addContentManually(_ content: String) {
    guard !content.isEmpty,
          !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return
    }

    // Sanitize content for security
    let sanitizedContent = securityService.sanitizeStringInput(content)

    // Check if this content is already the most recent item
    if let lastItem = clipboardHistory.first,
       lastItem.content == sanitizedContent {
      return
    }

    let newItem = ClipboardItem(content: sanitizedContent)
    addToHistory(newItem)
  }

  func pasteFromSystemClipboard() {
    if let content = pasteboard.string(forType: .string) {
      addContentManually(content)
    }
  }

  // MARK: - History Management

  func addToHistory(_ item: ClipboardItem) {
    // Remove duplicate if exists
    removeDuplicateContent(item.content)

    // Insert to SwiftData
    modelContext.insert(item)

    // Add to beginning of array
    clipboardHistory.insert(item, at: 0)

    // Limit history size
    if clipboardHistory.count > maxHistoryCount {
      let itemsToRemove = Array(clipboardHistory.dropFirst(maxHistoryCount))
      for oldItem in itemsToRemove {
        modelContext.delete(oldItem)
      }
      clipboardHistory = Array(clipboardHistory.prefix(maxHistoryCount))
    }

    // Save changes
    saveContext()
  }

  func removeItem(_ item: ClipboardItem) {
    clipboardHistory.removeAll { $0.id == item.id }
    modelContext.delete(item)
    saveContext()
  }

  func clearHistory() {
    // Delete all items from SwiftData
    for item in clipboardHistory {
      modelContext.delete(item)
    }
    clipboardHistory.removeAll()
    saveContext()
  }

  func copyToClipboard(_ content: String) {
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
  }

  // MARK: - Search and Filter

  func searchItems(query: String) -> [ClipboardItem] {
    guard !query.isEmpty else { return clipboardHistory }

    let lowercaseQuery = query.lowercased()
    return clipboardHistory.filter { item in
      item.content.lowercased().contains(lowercaseQuery)
    }
  }

  func filterItems(by type: ClipboardItemType) -> [ClipboardItem] {
    clipboardHistory.filter { $0.type == type }
  }

  func filterItems(from startDate: Date, to endDate: Date) -> [ClipboardItem] {
    clipboardHistory.filter { item in
      item.timestamp >= startDate && item.timestamp <= endDate
    }
  }

  // MARK: - SwiftData Operations

  private func loadHistoryFromStorage() {
    do {
      let descriptor = FetchDescriptor<ClipboardItem>(
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
      let items = try modelContext.fetch(descriptor)
      clipboardHistory = Array(items.prefix(maxHistoryCount))
    } catch {
      print("Failed to load clipboard history: \(error)")
    }
  }

  private func removeDuplicateContent(_ content: String) {
    let duplicates = clipboardHistory.filter { $0.content == content }
    for duplicate in duplicates {
      clipboardHistory.removeAll { $0.id == duplicate.id }
      modelContext.delete(duplicate)
    }
  }

  private func saveContext() {
    do {
      try modelContext.save()
    } catch {
      print("Failed to save context: \(error)")
    }
  }

  private func cleanupOldEntries() {
    if clipboardHistory.count > maxHistoryCount {
      let itemsToRemove = Array(clipboardHistory.dropFirst(maxHistoryCount))
      for item in itemsToRemove {
        modelContext.delete(item)
      }
      clipboardHistory = Array(clipboardHistory.prefix(maxHistoryCount))
      saveContext()
    }
  }
}

// MARK: - Statistics

extension ClipboardService {
  var totalItemsCount: Int {
    clipboardHistory.count
  }

  var itemsByType: [ClipboardItemType: Int] {
    var counts: [ClipboardItemType: Int] = [:]
    for item in clipboardHistory {
      counts[item.type, default: 0] += 1
    }
    return counts
  }

  var oldestItem: ClipboardItem? {
    clipboardHistory.min(by: { $0.timestamp < $1.timestamp })
  }

  var newestItem: ClipboardItem? {
    clipboardHistory.max(by: { $0.timestamp < $1.timestamp })
  }
}