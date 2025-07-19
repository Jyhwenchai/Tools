import Foundation
import SwiftData

// MARK: - ClipboardItemType
enum ClipboardItemType: String, CaseIterable, Codable {
  case text = "文本"
  case url = "链接"
  case code = "代码"
  
  var icon: String {
    switch self {
    case .text:
      return "doc.text"
    case .url:
      return "link"
    case .code:
      return "curlybraces"
    }
  }
}

// MARK: - ClipboardItem
@Model
class ClipboardItem: Identifiable, Hashable {
  @Attribute(.unique) var id: UUID
  var content: String
  var timestamp: Date
  var typeRawValue: String
  
  var type: ClipboardItemType {
    get {
      return ClipboardItemType(rawValue: typeRawValue) ?? .text
    }
    set {
      typeRawValue = newValue.rawValue
    }
  }
  
  init(content: String, type: ClipboardItemType? = nil) {
    self.id = UUID()
    self.content = content
    self.timestamp = Date()
    let detectedType = type ?? Self.detectType(from: content)
    self.typeRawValue = detectedType.rawValue
  }
  
  init(id: UUID, content: String, timestamp: Date, type: ClipboardItemType) {
    self.id = id
    self.content = content
    self.timestamp = timestamp
    self.typeRawValue = type.rawValue
  }
  
  // MARK: - Type Detection
  private static func detectType(from content: String) -> ClipboardItemType {
    // Check if content is a URL
    if let url = URL(string: content.trimmingCharacters(in: .whitespacesAndNewlines)),
       url.scheme != nil {
      return .url
    }
    
    // Check if content looks like code (contains common programming patterns)
    let codePatterns = [
      "func ", "function ", "def ", "class ", "import ", "#include",
      "var ", "let ", "const ", "public ", "private ", "protected",
      "{", "}", "[", "]", "=>", "->", "&&", "||"
    ]
    
    let lowercaseContent = content.lowercased()
    let hasCodePattern = codePatterns.contains { pattern in
      lowercaseContent.contains(pattern.lowercased())
    }
    
    if hasCodePattern {
      return .code
    }
    
    return .text
  }
  
  // MARK: - Computed Properties
  var preview: String {
    let maxLength = 100
    if content.count <= maxLength {
      return content
    }
    return String(content.prefix(maxLength)) + "..."
  }
  
  var formattedTimestamp: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: timestamp)
  }
  
  // MARK: - Hashable
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
    return lhs.id == rhs.id
  }
}

