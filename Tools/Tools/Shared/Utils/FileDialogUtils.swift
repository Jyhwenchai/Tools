//
//  FileDialogUtils.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

/// Utility class for handling file dialogs without requiring folder access permissions
enum FileDialogUtils {
  /// Show a file open dialog for selecting files
  /// - Parameter allowedTypes: Array of UTType values for allowed file types
  /// - Returns: Selected file URL or nil if cancelled
  static func showOpenDialog(allowedTypes: [UTType]) async -> URL? {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }

  /// Show a file open dialog for selecting multiple files
  /// - Parameter allowedTypes: Array of UTType values for allowed file types
  /// - Returns: Array of selected file URLs
  static func showMultipleOpenDialog(allowedTypes: [UTType]) async -> [URL] {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.urls : [])
      }
    }
  }

  /// Show a file save dialog
  /// - Parameters:
  ///   - suggestedName: Suggested filename
  ///   - allowedTypes: Array of UTType values for allowed file types
  /// - Returns: Selected save URL or nil if cancelled
  static func showSaveDialog(suggestedName: String, allowedTypes: [UTType]) async -> URL? {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = allowedTypes
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }

  /// Show a directory selection dialog
  /// - Returns: Selected directory URL or nil if cancelled
  static func showDirectoryDialog() async -> URL? {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }

  /// Show an enhanced directory selection dialog with custom message
  /// - Parameter message: Custom message to display in the dialog
  /// - Returns: Selected directory URL or nil if cancelled
  static func showDirectoryDialog(message: String) async -> URL? {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = message
        panel.prompt = "选择文件夹"

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }

  /// Show an enhanced save dialog with better user guidance
  /// - Parameters:
  ///   - suggestedName: Suggested filename
  ///   - allowedTypes: Array of UTType values for allowed file types
  ///   - message: Custom message to display in the dialog
  ///   - title: Custom title for the dialog
  /// - Returns: Selected save URL or nil if cancelled
  static func showEnhancedSaveDialog(
    suggestedName: String,
    allowedTypes: [UTType],
    message: String? = nil,
    title: String? = nil) async -> URL? {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSSavePanel()
        panel.allowedContentTypes = allowedTypes
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true

        // Enhanced user guidance
        panel.title = title ?? "保存文件"

        if let message {
          panel.message = message
        } else {
          let typeNames = allowedTypes.compactMap { $0.preferredFilenameExtension?.uppercased() }
            .joined(separator: ", ")
          panel.message = "选择保存位置和文件格式：\(typeNames)\n\n提示：可以创建新文件夹来组织文件，默认保存到桌面便于查找"
        }

        panel.prompt = "保存"

        // Set default directory to Desktop for better UX
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)
          .first {
          panel.directoryURL = desktopURL
        }

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.url : nil)
      }
    }
  }

  /// Show an enhanced open dialog with better file filtering and user guidance
  /// - Parameters:
  ///   - allowedTypes: Array of UTType values for allowed file types
  ///   - message: Custom message to display in the dialog
  ///   - allowMultiple: Whether to allow multiple file selection
  ///   - title: Custom title for the dialog
  /// - Returns: Array of selected file URLs
  static func showEnhancedOpenDialog(
    allowedTypes: [UTType],
    message: String? = nil,
    allowMultiple: Bool = false,
    title: String? = nil) async -> [URL] {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = allowedTypes
        panel.allowsMultipleSelection = allowMultiple
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        // Enhanced user guidance
        if let title {
          panel.title = title
        } else {
          panel.title = allowMultiple ? "选择文件" : "选择文件"
        }

        if let message {
          panel.message = message
        } else {
          let typeNames = allowedTypes.compactMap { $0.preferredFilenameExtension?.uppercased() }
            .joined(separator: ", ")
          panel.message = "选择支持的文件格式：\(typeNames)\n\n提示：使用 ⌘+A 全选，⌘+点击 多选，⇧+点击 范围选择"
        }

        panel.prompt = allowMultiple ? "选择文件" : "选择"

        // Set default directory based on file type
        let defaultDirectory: FileManager.SearchPathDirectory = if allowedTypes.contains(.image) {
          .picturesDirectory
        } else if allowedTypes.contains(.json) || allowedTypes.contains(.plainText) {
          .documentDirectory
        } else {
          .desktopDirectory
        }

        if let defaultURL = FileManager.default.urls(for: defaultDirectory, in: .userDomainMask)
          .first {
          panel.directoryURL = defaultURL
        }

        let result = panel.runModal()
        continuation.resume(returning: result == .OK ? panel.urls : [])
      }
    }
  }

  /// Validate file size before processing
  /// - Parameters:
  ///   - url: File URL to check
  ///   - maxSize: Maximum allowed size in bytes
  /// - Returns: True if file size is acceptable
  static func validateFileSize(_ url: URL, maxSize: Int64) -> Bool {
    guard let fileSize = try? FileManager.default
      .attributesOfItem(atPath: url.path)[.size] as? Int64
    else {
      return false
    }
    return fileSize <= maxSize
  }

  /// Get human-readable file size
  /// - Parameter url: File URL
  /// - Returns: Formatted file size string
  static func getFileSize(_ url: URL) -> String {
    guard let fileSize = try? FileManager.default
      .attributesOfItem(atPath: url.path)[.size] as? Int64
    else {
      return "未知大小"
    }
    return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
  }

  /// Check if file type is supported
  /// - Parameters:
  ///   - url: File URL to check
  ///   - supportedTypes: Array of supported UTTypes
  /// - Returns: True if file type is supported
  static func isFileTypeSupported(_ url: URL, supportedTypes: [UTType]) -> Bool {
    let fileExtension = url.pathExtension.lowercased()
    return supportedTypes.contains { type in
      type.preferredFilenameExtension?.lowercased() == fileExtension ||
        type.tags[.filenameExtension]?.contains(fileExtension) == true
    }
  }

  /// Show a user-friendly file operation tutorial
  /// - Parameter operationType: Type of operation to show tutorial for
  static func showFileOperationTutorial(for operationType: String) {
    let alert = NSAlert()
    alert.messageText = "文件操作指南"

    switch operationType {
    case "drag_drop":
      alert.informativeText = """
      拖拽文件操作：

      1. 从访达中选择要处理的文件
      2. 直接拖拽到应用的拖拽区域
      3. 拖拽时会显示实时反馈
      4. 绿色表示文件可用，橙色表示格式不支持
      5. 支持同时拖拽多个文件

      提示：这种方式最快捷，无需打开文件选择器
      """
    case "file_selection":
      alert.informativeText = """
      文件选择操作：

      1. 点击"选择文件"按钮
      2. 在文件选择器中浏览文件
      3. 使用键盘快捷键提高效率：
         • ⌘+A：全选
         • ⌘+点击：多选
         • ⇧+点击：范围选择
         • 空格键：预览
      4. 点击"选择"确认

      提示：文件选择器会自动过滤支持的格式
      """
    case "file_saving":
      alert.informativeText = """
      文件保存操作：

      1. 处理完成后点击保存按钮
      2. 选择保存位置（默认桌面）
      3. 修改文件名（可选）
      4. 选择文件格式（如果支持多种）
      5. 可以创建新文件夹组织文件
      6. 点击"保存"完成

      提示：保存到桌面便于快速查找
      """
    default:
      alert.informativeText = "选择具体的操作类型查看详细指南"
    }

    alert.addButton(withTitle: "了解")
    alert.runModal()
  }

  /// Validate multiple files and provide detailed feedback
  /// - Parameters:
  ///   - urls: Array of file URLs to validate
  ///   - supportedTypes: Array of supported UTTypes
  ///   - maxFileSize: Maximum allowed file size in bytes
  /// - Returns: Validation result with details
  static func validateFiles(
    _ urls: [URL],
    supportedTypes: [UTType],
    maxFileSize: Int64) -> FileValidationResult {
    var validFiles: [URL] = []
    var invalidFiles: [URL] = []
    var oversizedFiles: [URL] = []

    for url in urls {
      // Check file type
      guard isFileTypeSupported(url, supportedTypes: supportedTypes) else {
        invalidFiles.append(url)
        continue
      }

      // Check file size
      guard validateFileSize(url, maxSize: maxFileSize) else {
        oversizedFiles.append(url)
        continue
      }

      validFiles.append(url)
    }

    return FileValidationResult(
      validFiles: validFiles,
      invalidFiles: invalidFiles,
      oversizedFiles: oversizedFiles,
      supportedTypes: supportedTypes,
      maxFileSize: maxFileSize)
  }

  /// Get detailed file information for user display
  /// - Parameter url: File URL
  /// - Returns: Formatted file information string
  static func getDetailedFileInfo(_ url: URL) -> String {
    let fileName = url.lastPathComponent
    let fileSize = getFileSize(url)
    let fileType = url.pathExtension.uppercased()

    var info = "文件名：\(fileName)\n"
    info += "大小：\(fileSize)\n"
    info += "格式：\(fileType)"

    // Add modification date
    if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
       let modificationDate = attributes[.modificationDate] as? Date {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .short
      info += "\n修改时间：\(formatter.string(from: modificationDate))"
    }

    return info
  }
}

/// Result of file validation with detailed information
struct FileValidationResult {
  let validFiles: [URL]
  let invalidFiles: [URL]
  let oversizedFiles: [URL]
  let supportedTypes: [UTType]
  let maxFileSize: Int64

  var isValid: Bool {
    !validFiles.isEmpty && invalidFiles.isEmpty && oversizedFiles.isEmpty
  }

  var hasIssues: Bool {
    !invalidFiles.isEmpty || !oversizedFiles.isEmpty
  }

  var summaryMessage: String {
    var message = ""

    if !validFiles.isEmpty {
      message += "✅ \(validFiles.count) 个文件可以处理\n"
    }

    if !invalidFiles.isEmpty {
      message += "⚠️ \(invalidFiles.count) 个文件格式不支持\n"
    }

    if !oversizedFiles.isEmpty {
      message += "❌ \(oversizedFiles.count) 个文件过大\n"
    }

    return message.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var detailedMessage: String {
    var message = summaryMessage + "\n\n"

    if !invalidFiles.isEmpty {
      let typeNames = supportedTypes.compactMap { $0.preferredFilenameExtension?.uppercased() }
        .joined(separator: ", ")
      message += "支持的格式：\(typeNames)\n"
    }

    if !oversizedFiles.isEmpty {
      message += "文件大小限制：\(ByteCountFormatter.string(fromByteCount: maxFileSize, countStyle: .file))\n"
    }

    return message.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
