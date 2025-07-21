import SwiftUI

/// Enhanced clipboard item row with syntax highlighting support
/// This version is ready for Highlightr integration when the package is added
struct EnhancedClipboardItemRow: View {
  let item: ClipboardItem
  let onCopy: () -> Void
  let onDelete: () -> Void

  @State private var isHovered = false
  @State private var showingFullContent = false
  @State private var highlightedCode: AttributedString?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header with type and timestamp
      headerView

      // Content with syntax highlighting
      contentView

      // Action buttons for long content
      if item.content.count > 100 {
        expandButton
      }
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
      contextMenuItems
    }
    .task {
      if item.type == .code {
        await loadHighlightedCode()
      }
    }
  }

  // MARK: - Header View

  private var headerView: some View {
    HStack {
      // Type badge
      HStack(spacing: 6) {
        Image(systemName: item.type.icon)
          .foregroundColor(typeColor)
        Text(item.type.rawValue)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(typeColor)

        // Language badge for code
        if item.type == .code, let language = detectCodeLanguage(item.content) {
          Text(language.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(typeColor)
            .cornerRadius(3)
        }
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(typeColor.opacity(0.1))
      .cornerRadius(4)

      Spacer()

      // Timestamp
      Text(item.formattedTimestamp)
        .font(.caption)
        .foregroundColor(.secondary)

      // Action buttons (shown on hover)
      if isHovered {
        actionButtons
      }
    }
  }

  // MARK: - Action Buttons

  private var actionButtons: some View {
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

  // MARK: - Content View

  @ViewBuilder
  private var contentView: some View {
    let displayContent = showingFullContent ? item.content : item.preview

    switch item.type {
    case .text:
      textContentView(displayContent)
    case .url:
      urlContentView(displayContent)
    case .code:
      codeContentView(displayContent)
    }
  }

  private func textContentView(_ content: String) -> some View {
    Text(content)
      .font(.system(.body, design: .default))
      .textSelection(.enabled)
      .lineLimit(showingFullContent ? nil : 3)
  }

  private func urlContentView(_ content: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      if let url = URL(string: item.content) {
        Link(destination: url) {
          HStack(spacing: 6) {
            Image(systemName: "link")
              .font(.caption)
            Text(content)
              .font(.system(.body, design: .monospaced))
              .foregroundColor(.accentColor)
              .underline()
          }
        }
        .buttonStyle(.plain)
      } else {
        Text(content)
          .font(.system(.body, design: .monospaced))
      }
    }
    .textSelection(.enabled)
  }

  private func codeContentView(_ content: String) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      VStack(alignment: .leading, spacing: 0) {
        // Use highlighted code if available, otherwise fallback to plain text
        if let highlightedCode {
          Text(highlightedCode)
            .textSelection(.enabled)
        } else {
          // Fallback to enhanced plain text display
          if content.contains("\n"), showingFullContent {
            codeWithLineNumbers(content)
          } else {
            Text(content)
              .font(.system(.body, design: .monospaced))
              .textSelection(.enabled)
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(NSColor.textBackgroundColor))
      .cornerRadius(6)
    }
    .frame(maxHeight: showingFullContent ? .infinity : 120)
  }

  // MARK: - Line Numbers View

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

  // MARK: - Expand Button

  private var expandButton: some View {
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

  // MARK: - Context Menu

  @ViewBuilder
  private var contextMenuItems: some View {
    Button("复制", action: onCopy)
    Button("删除", role: .destructive, action: onDelete)
    Divider()
    Button(showingFullContent ? "收起" : "展开全部") {
      showingFullContent.toggle()
    }

    if item.type == .url, let url = URL(string: item.content) {
      Divider()
      Button("在浏览器中打开") {
        NSWorkspace.shared.open(url)
      }
    }
  }

  // MARK: - Syntax Highlighting

  private func loadHighlightedCode() async {
    // This function is ready for Highlightr integration
    // When Highlightr package is added, implement syntax highlighting here

    /*
     Example implementation with Highlightr:

     guard let highlightr = Highlightr() else { return }

     let language = detectCodeLanguage(item.content) ?? "plaintext"

     if let highlighted = highlightr.highlight(item.content, as: language) {
       await MainActor.run {
         self.highlightedCode = AttributedString(highlighted)
       }
     }
     */
  }

  // MARK: - Language Detection

  private func detectCodeLanguage(_ content: String) -> String? {
    let lowercaseContent = content.lowercased()

    // Swift
    if lowercaseContent.contains("func ") || lowercaseContent.contains("var ") ||
      lowercaseContent.contains("let ") || lowercaseContent.contains("import foundation") ||
      lowercaseContent.contains("@") {
      return "swift"
    }

    // JavaScript/TypeScript
    if lowercaseContent.contains("function ") || lowercaseContent.contains("const ") ||
      lowercaseContent.contains("=>") || lowercaseContent.contains("console.log") ||
      lowercaseContent.contains("require(") {
      return "javascript"
    }

    // Python
    if lowercaseContent.contains("def ") || lowercaseContent.contains("import ") ||
      lowercaseContent.contains("print(") || lowercaseContent.contains("class ") ||
      lowercaseContent.contains("from ") {
      return "python"
    }

    // Java
    if lowercaseContent.contains("public class") || lowercaseContent
      .contains("public static void") ||
      lowercaseContent.contains("system.out.println") || lowercaseContent.contains("package ") {
      return "java"
    }

    // HTML
    if lowercaseContent.contains("<html") || lowercaseContent.contains("<!doctype") ||
      lowercaseContent.contains("<div") || lowercaseContent.contains("<body") {
      return "html"
    }

    // CSS
    if lowercaseContent.contains("{") && lowercaseContent.contains("}") &&
      (lowercaseContent.contains(":") && lowercaseContent.contains(";")) &&
      !lowercaseContent.contains("func") {
      return "css"
    }

    // JSON
    if (lowercaseContent.hasPrefix("{") && lowercaseContent.hasSuffix("}")) ||
      (lowercaseContent.hasPrefix("[") && lowercaseContent.hasSuffix("]")) {
      return "json"
    }

    // SQL
    if lowercaseContent.contains("select ") || lowercaseContent.contains("from ") ||
      lowercaseContent.contains("where ") || lowercaseContent.contains("insert into") {
      return "sql"
    }

    // Shell/Bash
    if lowercaseContent.hasPrefix("#!/") || lowercaseContent.contains("echo ") ||
      lowercaseContent.contains("export ") || lowercaseContent.contains("cd ") {
      return "bash"
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
    EnhancedClipboardItemRow(
      item: ClipboardItem(content: "Hello World! This is a simple text content."),
      onCopy: {},
      onDelete: {})

    EnhancedClipboardItemRow(
      item: ClipboardItem(content: "https://www.apple.com/swift"),
      onCopy: {},
      onDelete: {})

    EnhancedClipboardItemRow(
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
