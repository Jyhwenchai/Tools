import SwiftUI

struct ClipboardItemRow: View {
  let item: ClipboardItem
  let onCopy: () -> Void
  let onDelete: () -> Void

  @State private var isHovered = false
  @State private var showingFullContent = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with type and timestamp
      HStack {
        HStack(spacing: 6) {
          Image(systemName: item.type.icon)
            .foregroundColor(typeColor)
          Text(item.type.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(typeColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(typeColor.opacity(0.1))
        .cornerRadius(4)

        Spacer()

        Text(item.formattedTimestamp)
          .font(.caption)
          .foregroundColor(.secondary)

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
        }
      }

      // Content
      contentView
    }
    .padding(12)
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1))
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovered = hovering
      }
    }
    .contextMenu {
      Button("复制", action: onCopy)
      Button("删除", role: .destructive, action: onDelete)
      Divider()
      Button(showingFullContent ? "收起" : "展开全部") {
        showingFullContent.toggle()
      }
    }
  }

  // MARK: - Content View

  @ViewBuilder
  private var contentView: some View {
    let displayContent = showingFullContent ? item.content : item.preview

    switch item.type {
    case .text:
      Text(displayContent)
        .font(.system(.body, design: .default))
        .textSelection(.enabled)
        .lineLimit(showingFullContent ? nil : 3)

    case .url:
      VStack(alignment: .leading, spacing: 4) {
        if let url = URL(string: item.content) {
          Link(destination: url) {
            HStack(spacing: 6) {
              Image(systemName: "link")
                .font(.caption)
              Text(displayContent)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.accentColor)
                .underline()
            }
          }
          .buttonStyle(.plain)
        } else {
          Text(displayContent)
            .font(.system(.body, design: .monospaced))
        }
      }
      .textSelection(.enabled)

    case .code:
      codeContentView(displayContent)
    }

    // Expand/Collapse button for long content
    if item.content.count > 100 {
      Button(action: {
        withAnimation(.easeInOut(duration: 0.3)) {
          showingFullContent.toggle()
        }
      }) {
        HStack(spacing: 4) {
          Text(showingFullContent ? "收起" : "展开全部")
          Image(systemName: showingFullContent ? "chevron.up" : "chevron.down")
        }
        .font(.caption)
        .foregroundColor(.accentColor)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Code Content View

  @ViewBuilder
  private func codeContentView(_ content: String) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 0) {
        // Language detection hint
        if let language = detectCodeLanguage(content) {
          HStack {
            Text(language.uppercased())
              .font(.caption2)
              .fontWeight(.semibold)
              .foregroundColor(.secondary)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.secondary.opacity(0.1))
              .cornerRadius(3)
            Spacer()
          }
          .padding(.bottom, 4)
        }

        // Code content with line numbers for multi-line code
        if content.contains("\n"), showingFullContent {
          codeWithLineNumbers(content)
        } else {
          Text(content)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(NSColor.textBackgroundColor))
      .cornerRadius(6)
    }
    .frame(maxHeight: showingFullContent ? .infinity : 120)
  }

  @ViewBuilder
  private func codeWithLineNumbers(_ content: String) -> some View {
    let lines = content.components(separatedBy: .newlines)
    let maxLineNumber = lines.count
    let lineNumberWidth = String(maxLineNumber).count

    VStack(alignment: .leading, spacing: 2) {
      ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
        HStack(alignment: .top, spacing: 8) {
          // Line number
          Text("\(index + 1)")
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)
            .frame(width: CGFloat(lineNumberWidth * 8), alignment: .trailing)

          // Code line
          Text(line.isEmpty ? " " : line)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)

          Spacer()
        }
      }
    }
  }

  private func detectCodeLanguage(_ content: String) -> String? {
    let lowercaseContent = content.lowercased()

    // Swift
    if lowercaseContent.contains("func ") || lowercaseContent.contains("var ") ||
      lowercaseContent.contains("let ") || lowercaseContent.contains("import ") {
      return "swift"
    }

    // JavaScript/TypeScript
    if lowercaseContent.contains("function ") || lowercaseContent.contains("const ") ||
      lowercaseContent.contains("=>") || lowercaseContent.contains("console.log") {
      return "javascript"
    }

    // Python
    if lowercaseContent.contains("def ") || lowercaseContent.contains("import ") ||
      lowercaseContent.contains("print(") || lowercaseContent.contains("class ") {
      return "python"
    }

    // Java
    if lowercaseContent.contains("public class") || lowercaseContent
      .contains("public static void") ||
      lowercaseContent.contains("system.out.println") {
      return "java"
    }

    // HTML
    if lowercaseContent.contains("<html") || lowercaseContent.contains("<!doctype") ||
      lowercaseContent.contains("<div") || lowercaseContent.contains("<body") {
      return "html"
    }

    // CSS
    if lowercaseContent.contains("{") && lowercaseContent.contains("}") &&
      (lowercaseContent.contains(":") && lowercaseContent.contains(";")) {
      return "css"
    }

    // JSON
    if (lowercaseContent.hasPrefix("{") && lowercaseContent.hasSuffix("}")) ||
      (lowercaseContent.hasPrefix("[") && lowercaseContent.hasSuffix("]")) {
      return "json"
    }

    return nil
  }

  // MARK: - Computed Properties

  private var typeColor: Color {
    switch item.type {
    case .text:
      .blue
    case .url:
      .green
    case .code:
      .purple
    }
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 12) {
    ClipboardItemRow(
      item: ClipboardItem(content: "Hello World! This is a simple text content."),
      onCopy: {},
      onDelete: {})

    ClipboardItemRow(
      item: ClipboardItem(content: "https://www.apple.com/swift"),
      onCopy: {},
      onDelete: {})

    ClipboardItemRow(
      item: ClipboardItem(content: """
      func calculateSum(numbers: [Int]) -> Int {
          return numbers.reduce(0, +)
      }

      let result = calculateSum(numbers: [1, 2, 3, 4, 5])
      print("Sum: \\(result)")
      """),
      onCopy: {},
      onDelete: {})
  }
  .padding()
  .frame(width: 600)
}
