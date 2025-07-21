//
//  EnhancedDropZone.swift
//  Tools
//
//  Created by Kiro on 2025/7/20.
//

import SwiftUI
import UniformTypeIdentifiers

/// Enhanced drop zone component with improved visual feedback and file validation
struct EnhancedDropZone: View {
  let title: String
  let subtitle: String
  let supportedTypes: [UTType]
  let maxFileSize: Int64
  let onFilesDropped: ([URL]) -> Void
  let onButtonTapped: () -> Void

  @State private var isDragOver = false
  @State private var dragFeedback: DragFeedback = .none
  @State private var showingFileTypeError = false
  @State private var fileTypeErrorMessage = ""

  enum DragFeedback {
    case none
    case valid
    case invalid
    case tooLarge
    case hovering

    var color: Color {
      switch self {
      case .none: .secondary
      case .valid: .green
      case .invalid: .orange
      case .tooLarge: .red
      case .hovering: .blue
      }
    }

    var message: String {
      switch self {
      case .none: ""
      case .valid: "✓ 释放以添加文件"
      case .invalid: "⚠️ 不支持的文件格式"
      case .tooLarge: "❌ 文件过大"
      case .hovering: "📁 检查文件格式中..."
      }
    }

    var icon: String {
      switch self {
      case .none: "doc.badge.plus"
      case .valid: "checkmark.circle.fill"
      case .invalid: "exclamationmark.triangle.fill"
      case .tooLarge: "exclamationmark.octagon.fill"
      case .hovering: "magnifyingglass"
      }
    }
  }

  init(
    title: String,
    subtitle: String,
    supportedTypes: [UTType],
    maxFileSize: Int64 = 100 * 1024 * 1024, // 100MB default
    onFilesDropped: @escaping ([URL]) -> Void,
    onButtonTapped: @escaping () -> Void) {
    self.title = title
    self.subtitle = subtitle
    self.supportedTypes = supportedTypes
    self.maxFileSize = maxFileSize
    self.onFilesDropped = onFilesDropped
    self.onButtonTapped = onButtonTapped
  }

  var body: some View {
    BrightCardView {
      VStack(spacing: 20) {
        // Animated icon with enhanced feedback
        ZStack {
          Circle()
            .fill(dragFeedback.color.opacity(0.15))
            .frame(width: 90, height: 90)
            .scaleEffect(isDragOver ? 1.2 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragOver)

          // Pulsing effect for drag over
          if isDragOver {
            Circle()
              .stroke(dragFeedback.color, lineWidth: 2)
              .frame(width: 90, height: 90)
              .scaleEffect(isDragOver ? 1.3 : 1.0)
              .opacity(isDragOver ? 0.3 : 0)
              .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isDragOver)
          }

          Image(systemName: iconName)
            .font(.system(size: 36, weight: .medium))
            .foregroundColor(dragFeedback.color)
            .scaleEffect(isDragOver ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragFeedback)
        }

        // Enhanced text content with better feedback
        VStack(spacing: 8) {
          Text(isDragOver ? dragFeedback.message : title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(isDragOver ? dragFeedback.color : .primary)
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.2), value: isDragOver)

          if !isDragOver {
            Text(subtitle)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
          } else if dragFeedback == .hovering {
            Text("正在验证文件格式...")
              .font(.caption)
              .foregroundColor(.secondary)
              .transition(.opacity)
          }
        }

        // Enhanced action buttons
        if !isDragOver {
          HStack(spacing: 12) {
            ToolButton(
              title: "选择文件",
              action: onButtonTapped,
              style: .primary)

            // Quick help button
            Button(action: {
              // This could show a popover with file operation tips
            }) {
              HStack(spacing: 4) {
                Image(systemName: "questionmark.circle")
                Text("帮助")
              }
              .font(.caption)
              .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
          }
          .transition(.scale.combined(with: .opacity))
        }

        // Enhanced supported formats info with better visual hierarchy
        if !isDragOver {
          supportedFormatsView
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
      .frame(maxWidth: .infinity, minHeight: 220)
      .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isDragOver)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(
          dragFeedback.color,
          style: StrokeStyle(
            lineWidth: isDragOver ? 3 : 0,
            dash: isDragOver ? [8] : []))
        .animation(.easeInOut(duration: 0.2), value: isDragOver))
    .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
      handleDrop(providers)
    }
    .onChange(of: isDragOver) { _, newValue in
      if !newValue {
        dragFeedback = .none
      }
    }
    .alert("文件格式错误", isPresented: $showingFileTypeError) {
      Button("确定") {
        showingFileTypeError = false
      }
    } message: {
      Text(fileTypeErrorMessage)
    }
  }

  // MARK: - Computed Properties

  private var iconName: String {
    if isDragOver {
      return dragFeedback.icon
    }

    // Default icons based on supported types
    if supportedTypes.contains(.image) {
      return "photo.on.rectangle.angled"
    } else if supportedTypes.contains(.json) {
      return "doc.text"
    } else {
      return "doc.badge.plus"
    }
  }

  private var supportedFormatsView: some View {
    VStack(spacing: 8) {
      HStack(spacing: 4) {
        Image(systemName: "info.circle")
          .font(.caption2)
          .foregroundColor(.accentColor)
        Text("支持的格式")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
      }

      Text(formatSupportedTypes())
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(6)

      // File size limit info
      Text("单个文件最大 \(ByteCountFormatter.string(fromByteCount: maxFileSize, countStyle: .file))")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
  }

  // MARK: - Helper Methods

  private func formatSupportedTypes() -> String {
    let extensions = supportedTypes.compactMap { type in
      type.preferredFilenameExtension?.uppercased()
    }

    if extensions.count <= 5 {
      return extensions.joined(separator: ", ")
    } else {
      let first = extensions.prefix(4).joined(separator: ", ")
      return "\(first) 等 \(extensions.count) 种格式"
    }
  }

  private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
    var validFiles: [URL] = []
    var hasInvalidFiles = false
    var hasTooLargeFiles = false

    let group = DispatchGroup()

    for provider in providers {
      if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        group.enter()
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
          defer { group.leave() }

          guard let url else { return }

          // Check file size
          if let fileSize = try? FileManager.default
            .attributesOfItem(atPath: url.path)[.size] as? Int64,
            fileSize > maxFileSize {
            hasTooLargeFiles = true
            return
          }

          // Check file type
          let fileExtension = url.pathExtension.lowercased()
          let isSupported = supportedTypes.contains { type in
            type.preferredFilenameExtension?.lowercased() == fileExtension ||
              type.tags[.filenameExtension]?.contains(fileExtension) == true
          }

          if isSupported {
            validFiles.append(url)
          } else {
            hasInvalidFiles = true
          }
        }
      }
    }

    // Show hovering feedback immediately
    if isDragOver {
      dragFeedback = .hovering
    }

    group.notify(queue: .main) {
      // Update drag feedback during drag
      if isDragOver {
        if hasTooLargeFiles {
          dragFeedback = .tooLarge
        } else if hasInvalidFiles, validFiles.isEmpty {
          dragFeedback = .invalid
        } else if !validFiles.isEmpty {
          dragFeedback = .valid
        } else {
          dragFeedback = .invalid
        }
      }

      // Handle the drop when drag ends
      if !isDragOver, !validFiles.isEmpty {
        onFilesDropped(validFiles)
      }

      // Show enhanced error messages if needed
      if !isDragOver {
        if hasTooLargeFiles {
          fileTypeErrorMessage = "某些文件超过了 \(ByteCountFormatter.string(fromByteCount: maxFileSize, countStyle: .file)) 的大小限制。\n\n建议：\n• 压缩文件后重试\n• 选择较小的文件\n• 分批处理大文件"
          showingFileTypeError = true
        } else if hasInvalidFiles, validFiles.isEmpty {
          fileTypeErrorMessage = "不支持的文件格式。\n\n支持的格式：\(formatSupportedTypes())\n\n提示：\n• 检查文件扩展名是否正确\n• 尝试转换文件格式\n• 确认文件未损坏"
          showingFileTypeError = true
        }
      }
    }

    return !providers.isEmpty
  }
}

// MARK: - Convenience Initializers

extension EnhancedDropZone {
  /// Create a drop zone for images
  static func forImages(
    onFilesDropped: @escaping ([URL]) -> Void,
    onButtonTapped: @escaping () -> Void) -> EnhancedDropZone {
    EnhancedDropZone(
      title: "拖拽图片到此处或点击选择",
      subtitle: "支持批量处理多种图片格式",
      supportedTypes: [.png, .jpeg, .gif, .tiff, .bmp, .heic, .webP],
      onFilesDropped: onFilesDropped,
      onButtonTapped: onButtonTapped)
  }

  /// Create a drop zone for JSON files
  static func forJSON(
    onFilesDropped: @escaping ([URL]) -> Void,
    onButtonTapped: @escaping () -> Void) -> EnhancedDropZone {
    EnhancedDropZone(
      title: "拖拽JSON文件到此处或点击选择",
      subtitle: "支持 .json 格式文件",
      supportedTypes: [.json],
      maxFileSize: 10 * 1024 * 1024, // 10MB for JSON
      onFilesDropped: onFilesDropped,
      onButtonTapped: onButtonTapped)
  }

  /// Create a drop zone for any files
  static func forAnyFiles(
    title: String,
    subtitle: String,
    supportedTypes: [UTType],
    onFilesDropped: @escaping ([URL]) -> Void,
    onButtonTapped: @escaping () -> Void) -> EnhancedDropZone {
    EnhancedDropZone(
      title: title,
      subtitle: subtitle,
      supportedTypes: supportedTypes,
      onFilesDropped: onFilesDropped,
      onButtonTapped: onButtonTapped)
  }
}

#Preview {
  VStack(spacing: 20) {
    EnhancedDropZone.forImages(
      onFilesDropped: { urls in
        print("Dropped images: \(urls)")
      },
      onButtonTapped: {
        print("Button tapped")
      })

    EnhancedDropZone.forJSON(
      onFilesDropped: { urls in
        print("Dropped JSON: \(urls)")
      },
      onButtonTapped: {
        print("JSON button tapped")
      })
  }
  .padding()
  .frame(width: 500, height: 600)
}
