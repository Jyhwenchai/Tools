import SwiftData
import SwiftUI

struct ClipboardStatsView: View {
  let service: ClipboardService

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("统计信息")
        .font(.headline)

      // Total count
      StatRow(
        icon: "doc.on.clipboard",
        title: "总记录数",
        value: "\(service.totalItemsCount)",
        color: .blue)

      // Items by type
      let itemsByType = service.itemsByType
      ForEach(ClipboardItemType.allCases, id: \.self) { type in
        let count = itemsByType[type] ?? 0
        StatRow(
          icon: type.icon,
          title: type.rawValue,
          value: "\(count)",
          color: colorForType(type))
      }

      // Date range
      if let oldest = service.oldestItem,
         let newest = service.newestItem {
        Divider()

        VStack(alignment: .leading, spacing: 8) {
          Text("时间范围")
            .font(.subheadline)
            .fontWeight(.medium)

          HStack {
            Text("最早:")
            Spacer()
            Text(oldest.formattedTimestamp)
              .foregroundColor(.secondary)
          }
          .font(.caption)

          HStack {
            Text("最新:")
            Spacer()
            Text(newest.formattedTimestamp)
              .foregroundColor(.secondary)
          }
          .font(.caption)
        }
      }

      // Monitoring status
      Divider()

      HStack {
        Image(systemName: service.isMonitoring ? "checkmark.circle.fill" : "pause.circle.fill")
          .foregroundColor(service.isMonitoring ? .green : .orange)

        Text(service.isMonitoring ? "正在监控" : "已暂停监控")
          .font(.caption)
          .fontWeight(.medium)

        Spacer()
      }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
  }

  private func colorForType(_ type: ClipboardItemType) -> Color {
    switch type {
    case .text:
      .blue
    case .url:
      .green
    case .code:
      .purple
    }
  }
}

struct StatRow: View {
  let icon: String
  let title: String
  let value: String
  let color: Color

  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(color)
        .frame(width: 16)

      Text(title)
        .font(.caption)

      Spacer()

      Text(value)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(color)
    }
  }
}

// MARK: - Preview
struct ClipboardStatsViewPreview: PreviewProvider {
  static var previews: some View {
    let schema = Schema([ClipboardItem.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let context = ModelContext(container)

    let service = ClipboardService(modelContext: context)

    // Add sample data
    let sampleItems = [
      ClipboardItem(content: "Hello World"),
      ClipboardItem(content: "Another text"),
      ClipboardItem(content: "https://www.apple.com"),
      ClipboardItem(content: "https://developer.apple.com"),
      ClipboardItem(content: "func test() { return true }")
    ]

    for item in sampleItems {
      service.addToHistory(item)
    }

    return ClipboardStatsView(service: service)
      .frame(width: 250)
      .padding()
  }
}
