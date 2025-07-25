import SwiftUI

struct ClipboardItemRow: View {
  let item: ClipboardItem
  let onCopy: () -> Void
  let onDelete: () -> Void
  
  @State private var isHovered = false
  
  var body: some View {
    HStack(spacing: 12) {
      // Type Icon
      Image(systemName: item.type.icon)
        .font(.title3)
        .foregroundColor(iconColor)
        .frame(width: 24, height: 24)
      
      // Content
      VStack(alignment: .leading, spacing: 4) {
        Text(item.preview)
          .font(.body)
          .lineLimit(3)
          .multilineTextAlignment(.leading)
        
        HStack {
          Text(item.type.rawValue)
            .font(.caption)
            .foregroundColor(.secondary)
          
          Spacer()
          
          Text(item.formattedTimestamp)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
      
      // Action Buttons (shown on hover)
      if isHovered {
        HStack(spacing: 8) {
          Button(action: onCopy) {
            Image(systemName: "doc.on.doc")
              .font(.caption)
          }
          .buttonStyle(.plain)
          .help("复制到剪贴板")
          
          Button(action: onDelete) {
            Image(systemName: "trash")
              .font(.caption)
              .foregroundColor(.red)
          }
          .buttonStyle(.plain)
          .help("删除")
        }
        .transition(.opacity)
      }
    }
    .padding(12)
    .background(backgroundColor)
    .cornerRadius(8)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
  }
  
  private var iconColor: Color {
    switch item.type {
    case .text:
      return .blue
    case .url:
      return .green
    case .code:
      return .orange
    }
  }
  
  private var backgroundColor: Color {
    if isHovered {
      return Color(NSColor.selectedControlColor).opacity(0.1)
    }
    return Color(NSColor.controlBackgroundColor)
  }
}

// MARK: - Preview

struct ClipboardItemRowPreview: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 8) {
      ClipboardItemRow(
        item: ClipboardItem(content: "Hello World, this is a sample text content"),
        onCopy: {},
        onDelete: {}
      )
      
      ClipboardItemRow(
        item: ClipboardItem(content: "https://www.apple.com"),
        onCopy: {},
        onDelete: {}
      )
      
      ClipboardItemRow(
        item: ClipboardItem(content: "func test() { return true }"),
        onCopy: {},
        onDelete: {}
      )
    }
    .padding()
    .frame(width: 400)
  }
}