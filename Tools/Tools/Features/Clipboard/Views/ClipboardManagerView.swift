import SwiftUI
import SwiftData

struct ClipboardManagerView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var clipboardService: ClipboardService?
  @State private var selectedSidebarItem: SidebarItem = .history
  
  enum SidebarItem: String, CaseIterable {
    case history = "历史记录"
    case stats = "统计信息"
    
    var icon: String {
      switch self {
      case .history:
        return "clock.arrow.circlepath"
      case .stats:
        return "chart.bar"
      }
    }
  }
  
  var body: some View {
    NavigationSplitView {
      // Sidebar
      sidebarView
    } detail: {
      // Main content
      if let service = clipboardService {
        switch selectedSidebarItem {
        case .history:
          ClipboardView()
            .navigationTitle("剪贴板历史")
        case .stats:
          ClipboardStatsView(service: service)
            .navigationTitle("使用统计")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      } else {
        ProgressView("初始化剪贴板服务...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .navigationSplitViewStyle(.balanced)
    .onAppear {
      setupClipboardService()
    }
    .onDisappear {
      clipboardService?.stopMonitoring()
    }
  }
  
  // MARK: - Sidebar View
  private var sidebarView: some View {
    List(SidebarItem.allCases, id: \.self, selection: $selectedSidebarItem) { item in
      NavigationLink(value: item) {
        HStack(spacing: 12) {
          Image(systemName: item.icon)
            .foregroundColor(.accentColor)
            .frame(width: 20)
          
          Text(item.rawValue)
            .font(.body)
        }
        .padding(.vertical, 4)
      }
    }
    .navigationTitle("剪贴板管理")
    .listStyle(.sidebar)
    .frame(minWidth: 200)
  }
  
  // MARK: - Helper Methods
  private func setupClipboardService() {
    clipboardService = ClipboardService(modelContext: modelContext)
  }
}

// MARK: - Preview
#Preview {
  let schema = Schema([ClipboardItem.self])
  let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: schema, configurations: [configuration])
  
  return ClipboardManagerView()
    .modelContainer(container)
    .frame(width: 1000, height: 700)
}