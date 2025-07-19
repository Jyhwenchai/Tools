import SwiftUI
import SwiftData

struct ClipboardView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var clipboardService: ClipboardService?
  @State private var searchText = ""
  @State private var selectedType: ClipboardItemType? = nil
  @State private var showingClearAlert = false
  @State private var filteredItems: [ClipboardItem] = []
  
  var body: some View {
    VStack(spacing: 0) {
      // Header
      headerView
      
      // Search and Filter Bar
      searchAndFilterBar
      
      // Content
      if let service = clipboardService {
        if filteredItems.isEmpty {
          emptyStateView
        } else {
          clipboardListView(service: service)
        }
      } else {
        ProgressView("初始化中...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .onAppear {
      setupClipboardService()
    }
    .onDisappear {
      clipboardService?.stopMonitoring()
    }
    .alert("清空历史记录", isPresented: $showingClearAlert) {
      Button("取消", role: .cancel) { }
      Button("清空", role: .destructive) {
        clipboardService?.clearHistory()
        updateFilteredItems()
      }
    } message: {
      Text("确定要清空所有粘贴板历史记录吗？此操作无法撤销。")
    }
  }
  
  // MARK: - Header View
  private var headerView: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("粘贴板管理")
          .font(.title2)
          .fontWeight(.semibold)
        
        if let service = clipboardService {
          Text("共 \(service.totalItemsCount) 条记录")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
      
      HStack(spacing: 12) {
        // Monitoring Toggle
        if let service = clipboardService {
          Button(action: {
            if service.isMonitoring {
              service.stopMonitoring()
            } else {
              service.startMonitoring()
            }
          }) {
            HStack(spacing: 6) {
              Image(systemName: service.isMonitoring ? "pause.circle.fill" : "play.circle.fill")
              Text(service.isMonitoring ? "暂停监控" : "开始监控")
            }
            .font(.caption)
            .foregroundColor(service.isMonitoring ? .orange : .green)
          }
          .buttonStyle(.plain)
        }
        
        // Clear All Button
        Button(action: {
          showingClearAlert = true
        }) {
          HStack(spacing: 6) {
            Image(systemName: "trash")
            Text("清空")
          }
          .font(.caption)
          .foregroundColor(.red)
        }
        .buttonStyle(.plain)
        .disabled(filteredItems.isEmpty)
      }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
  }
  
  // MARK: - Search and Filter Bar
  private var searchAndFilterBar: some View {
    HStack(spacing: 12) {
      // Search Field
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.secondary)
        
        TextField("搜索内容...", text: $searchText)
          .textFieldStyle(.plain)
          .onChange(of: searchText) { _, _ in
            updateFilteredItems()
          }
        
        if !searchText.isEmpty {
          Button(action: {
            searchText = ""
          }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(Color(NSColor.textBackgroundColor))
      .cornerRadius(6)
      
      // Type Filter
      Menu {
        Button("全部类型") {
          selectedType = nil
          updateFilteredItems()
        }
        
        Divider()
        
        ForEach(ClipboardItemType.allCases, id: \.self) { type in
          Button(action: {
            selectedType = selectedType == type ? nil : type
            updateFilteredItems()
          }) {
            HStack {
              Image(systemName: type.icon)
              Text(type.rawValue)
              if selectedType == type {
                Spacer()
                Image(systemName: "checkmark")
              }
            }
          }
        }
      } label: {
        HStack(spacing: 6) {
          Image(systemName: selectedType?.icon ?? "line.3.horizontal.decrease.circle")
          Text(selectedType?.rawValue ?? "类型")
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(selectedType != nil ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
      }
      .menuStyle(.borderlessButton)
    }
    .padding(.horizontal)
    .padding(.bottom, 8)
    .background(Color(NSColor.controlBackgroundColor))
  }
  
  // MARK: - Empty State View
  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "doc.on.clipboard")
        .font(.system(size: 48))
        .foregroundColor(.secondary)
      
      VStack(spacing: 8) {
        Text("暂无粘贴板记录")
          .font(.headline)
        
        if searchText.isEmpty && selectedType == nil {
          Text("开始监控后，复制的内容将自动保存到这里")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        } else {
          Text("没有找到匹配的记录")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      if let service = clipboardService, !service.isMonitoring && searchText.isEmpty && selectedType == nil {
        Button("开始监控") {
          service.startMonitoring()
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(NSColor.textBackgroundColor))
  }
  
  // MARK: - Clipboard List View
  private func clipboardListView(service: ClipboardService) -> some View {
    ScrollView {
      LazyVStack(spacing: 8) {
        ForEach(filteredItems) { item in
          ClipboardItemRow(
            item: item,
            onCopy: {
              service.copyToClipboard(item.content)
            },
            onDelete: {
              service.removeItem(item)
              updateFilteredItems()
            }
          )
        }
      }
      .padding()
    }
    .background(Color(NSColor.textBackgroundColor))
  }
  
  // MARK: - Helper Methods
  private func setupClipboardService() {
    clipboardService = ClipboardService(modelContext: modelContext)
    clipboardService?.startMonitoring()
    updateFilteredItems()
  }
  
  private func updateFilteredItems() {
    guard let service = clipboardService else { return }
    
    var items = service.clipboardHistory
    
    // Apply search filter
    if !searchText.isEmpty {
      items = service.searchItems(query: searchText)
    }
    
    // Apply type filter
    if let type = selectedType {
      items = items.filter { $0.type == type }
    }
    
    filteredItems = items
  }
}

// MARK: - Preview
#Preview {
  let schema = Schema([ClipboardItem.self])
  let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: schema, configurations: [configuration])
  let context = ModelContext(container)
  
  // Add sample data
  let sampleItems = [
    ClipboardItem(content: "Hello World"),
    ClipboardItem(content: "https://www.apple.com"),
    ClipboardItem(content: "func test() { return true }")
  ]
  
  for item in sampleItems {
    context.insert(item)
  }
  
  return ClipboardView()
    .modelContainer(container)
    .frame(width: 800, height: 600)
}