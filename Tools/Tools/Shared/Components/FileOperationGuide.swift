//
//  FileOperationGuide.swift
//  Tools
//
//  Created by Kiro on 2025/7/20.
//

import SwiftUI
import UniformTypeIdentifiers

/// Component that provides helpful guidance for file operations
struct FileOperationGuide: View {
  let operationType: OperationType
  @State private var showingGuide = false
  
  enum OperationType {
    case dragDrop
    case fileSelection
    case fileSaving
    case batchProcessing
    case troubleshooting
    
    var title: String {
      switch self {
      case .dragDrop: return "拖拽文件操作指南"
      case .fileSelection: return "文件选择指南"
      case .fileSaving: return "文件保存指南"
      case .batchProcessing: return "批量处理指南"
      case .troubleshooting: return "常见问题解决"
      }
    }
    
    var icon: String {
      switch self {
      case .dragDrop: return "hand.draw"
      case .fileSelection: return "folder"
      case .fileSaving: return "square.and.arrow.down"
      case .batchProcessing: return "square.stack.3d.up"
      case .troubleshooting: return "wrench.and.screwdriver"
      }
    }
    
    var tips: [String] {
      switch self {
      case .dragDrop:
        return [
          "直接从访达拖拽文件到应用窗口的拖拽区域",
          "支持同时拖拽多个文件进行批量处理",
          "拖拽时会实时显示文件格式验证提示",
          "不支持的文件格式会被自动过滤并提示",
          "拖拽过程中会显示彩色反馈：绿色表示可用，橙色表示格式错误",
          "支持从不同文件夹同时拖拽多个文件"
        ]
      case .fileSelection:
        return [
          "点击\"选择文件\"按钮打开系统原生文件选择器",
          "使用 ⌘+A 可以选择文件夹中的所有支持文件",
          "按住 ⌘ 键点击可以选择多个不连续的文件",
          "按住 ⇧ 键点击可以选择连续的文件范围",
          "使用空格键可以快速预览选中的文件",
          "文件选择器会自动过滤只显示支持的文件格式"
        ]
      case .fileSaving:
        return [
          "处理完成后点击保存按钮选择保存位置",
          "默认保存位置为桌面，便于快速查找",
          "可以在保存对话框中修改文件名和格式",
          "支持创建新文件夹来组织处理后的文件",
          "批量保存时可以选择统一的保存文件夹",
          "保存时会显示进度和成功提示"
        ]
      case .batchProcessing:
        return [
          "一次可以处理多个文件，大幅提高工作效率",
          "所有文件将使用相同的处理设置和参数",
          "处理过程中会显示实时进度和当前状态",
          "可以随时点击取消按钮停止正在进行的批量处理",
          "建议单次处理文件数量不超过50个以确保性能",
          "大文件批量处理时请确保有足够的存储空间"
        ]
      case .troubleshooting:
        return [
          "文件无法拖拽：检查文件格式是否受支持",
          "文件过大：压缩文件或分批处理",
          "处理失败：检查文件是否损坏或被其他程序占用",
          "保存失败：确认目标文件夹有写入权限",
          "应用卡顿：减少同时处理的文件数量",
          "格式不支持：查看支持格式列表或转换文件格式"
        ]
      }
    }
  }
  
  var body: some View {
    HStack(spacing: 8) {
      Button(action: {
        showingGuide.toggle()
      }) {
        HStack(spacing: 6) {
          Image(systemName: operationType.icon)
            .font(.caption)
          Text("操作指南")
            .font(.caption)
            .fontWeight(.medium)
        }
        .foregroundColor(.accentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(6)
      }
      .buttonStyle(.plain)
      .popover(isPresented: $showingGuide, arrowEdge: .bottom) {
        guideContent
      }
    }
  }
  
  private var guideContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Enhanced header with visual appeal
        HStack(spacing: 12) {
          ZStack {
            Circle()
              .fill(Color.accentColor.opacity(0.1))
              .frame(width: 40, height: 40)
            
            Image(systemName: operationType.icon)
              .font(.title2)
              .foregroundColor(.accentColor)
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text(operationType.title)
              .font(.headline)
              .fontWeight(.semibold)
            
            Text("详细操作说明")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        
        Divider()
        
        // Enhanced tips with better visual hierarchy
        VStack(alignment: .leading, spacing: 12) {
          ForEach(Array(operationType.tips.enumerated()), id: \.offset) { index, tip in
            HStack(alignment: .top, spacing: 12) {
              ZStack {
                Circle()
                  .fill(Color.accentColor.opacity(0.1))
                  .frame(width: 24, height: 24)
                
                Text("\(index + 1)")
                  .font(.caption)
                  .fontWeight(.bold)
                  .foregroundColor(.accentColor)
              }
              
              Text(tip)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
            }
          }
        }
        
        // Enhanced shortcuts section for file selection
        if operationType == .fileSelection {
          Divider()
          
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
              Image(systemName: "keyboard")
                .font(.caption)
                .foregroundColor(.accentColor)
              Text("键盘快捷键")
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
              shortcutRow("⌘ + A", "全选文件夹中的所有文件")
              shortcutRow("⌘ + 点击", "选择多个不连续的文件")
              shortcutRow("⇧ + 点击", "选择连续范围内的文件")
              shortcutRow("空格键", "快速预览选中的文件")
              shortcutRow("↑↓ 方向键", "浏览文件列表")
            }
          }
        }
        
        // Enhanced performance tips for batch processing
        if operationType == .batchProcessing {
          Divider()
          
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
              Image(systemName: "speedometer")
                .font(.caption)
                .foregroundColor(.orange)
              Text("性能优化建议")
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
              performanceTip("📊", "建议单次处理文件数量不超过50个")
              performanceTip("💾", "大文件处理时请确保有足够的存储空间")
              performanceTip("⚡", "处理过程中避免同时运行其他重型应用")
              performanceTip("🔄", "可以随时取消处理并重新开始")
            }
          }
        }
        
        // Troubleshooting section for troubleshooting type
        if operationType == .troubleshooting {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
              Image(systemName: "lightbulb")
                .font(.caption)
                .foregroundColor(.yellow)
              Text("解决方案")
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            
            Text("遇到问题时，请按照以上步骤逐一检查。如果问题仍然存在，请重启应用后重试。")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 6)
              .background(Color.yellow.opacity(0.1))
              .cornerRadius(6)
          }
        }
      }
      .padding()
    }
    .frame(width: 320)
    .frame(maxHeight: 400)
  }
  
  private func shortcutRow(_ shortcut: String, _ description: String) -> some View {
    HStack(spacing: 12) {
      Text(shortcut)
        .font(.caption)
        .fontWeight(.semibold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(6)
        .frame(minWidth: 80, alignment: .center)
      
      Text(description)
        .font(.caption)
        .foregroundColor(.primary)
      
      Spacer()
    }
  }
  
  private func performanceTip(_ icon: String, _ description: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text(icon)
        .font(.caption)
      
      Text(description)
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

/// Quick access guide buttons for common operations
struct FileOperationQuickGuide: View {
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "info.circle.fill")
          .font(.caption)
          .foregroundColor(.accentColor)
        
        Text("文件操作帮助")
          .font(.subheadline)
          .fontWeight(.semibold)
        
        Spacer()
      }
      
      HStack(spacing: 12) {
        FileOperationGuide(operationType: .dragDrop)
        FileOperationGuide(operationType: .fileSelection)
        FileOperationGuide(operationType: .fileSaving)
        FileOperationGuide(operationType: .batchProcessing)
        FileOperationGuide(operationType: .troubleshooting)
      }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    .cornerRadius(12)
  }
}

/// Contextual file operation help for specific features
struct ContextualFileOperationHelp: View {
  let supportedTypes: [UTType]
  let maxFileSize: Int64
  let allowsMultiple: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "lightbulb")
          .font(.caption)
          .foregroundColor(.yellow)
        
        Text("操作提示")
          .font(.subheadline)
          .fontWeight(.semibold)
      }
      
      VStack(alignment: .leading, spacing: 8) {
        if allowsMultiple {
          helpTip("📁", "支持同时处理多个文件，提高工作效率")
        }
        
        helpTip("🎯", "支持格式：\(formatTypes())")
        helpTip("📏", "文件大小限制：\(ByteCountFormatter.string(fromByteCount: maxFileSize, countStyle: .file))")
        helpTip("🚀", "拖拽文件到区域或点击按钮选择文件")
      }
    }
    .padding()
    .background(Color.yellow.opacity(0.05))
    .cornerRadius(8)
  }
  
  private func helpTip(_ icon: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text(icon)
        .font(.caption)
      
      Text(text)
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
  
  private func formatTypes() -> String {
    let extensions = supportedTypes.compactMap { type in
      type.preferredFilenameExtension?.uppercased()
    }
    
    if extensions.count <= 3 {
      return extensions.joined(separator: ", ")
    } else {
      let first = extensions.prefix(3).joined(separator: ", ")
      return "\(first) 等 \(extensions.count) 种"
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    FileOperationGuide(operationType: .dragDrop)
    FileOperationGuide(operationType: .fileSelection)
    FileOperationGuide(operationType: .fileSaving)
    FileOperationGuide(operationType: .batchProcessing)
    
    Divider()
    
    FileOperationQuickGuide()
  }
  .padding()
  .frame(width: 400, height: 500)
}