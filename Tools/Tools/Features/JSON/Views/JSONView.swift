//
//  JSONView.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI
import UniformTypeIdentifiers

struct JSONView: View {
  @State private var inputJSON: String = ""
  @State private var outputText: String = ""
  @State private var formattedJSON: String = ""
  @State private var selectedLanguage: ProgrammingLanguage = .swift
  @State private var className: String = "Model"
  @State private var isValidJSON: Bool = true
  @State private var validationMessage: String = ""
  @State private var isProcessing: Bool = false
  @State private var currentError: ToolError?
  @State private var showingJSONPath: Bool = false
  @State private var extractedPaths: [String] = []
  @State private var selectedOperation: JSONOperation = .format
  @State private var lastOperation: JSONOperation = .format

  private let jsonService = JSONService.shared

  var body: some View {
    VStack(spacing: 0) {
      // 顶部工具栏
      toolbarView

      Divider()

      // 主要内容区域 - 左右分栏布局
      HSplitView {
        // 左侧 - JSON输入区域
        inputSection
          .frame(minWidth: 400)

        // 右侧 - 输出区域
        outputSection
          .frame(minWidth: 400)
      }
    }
    .navigationTitle("JSON工具")
    .errorAlert($currentError)
    .onChange(of: inputJSON) { _, newValue in
      validateJSONInput(newValue)
    }
  }

  // 顶部工具栏
  private var toolbarView: some View {
    BrightCardView {
      VStack(spacing: 16) {
        // 第一行：操作按钮
        HStack(spacing: 12) {
          ToolButton(
            title: "格式化",
            action: { performOperation(.format) },
            style: .primary
          )
          .disabled(inputJSON.isEmpty || !isValidJSON || isProcessing)

          ToolButton(
            title: "压缩",
            action: { performOperation(.minify) },
            style: .secondary
          )
          .disabled(inputJSON.isEmpty || !isValidJSON || isProcessing)

          ToolButton(
            title: "验证",
            action: { performOperation(.validate) },
            style: .secondary
          )
          .disabled(inputJSON.isEmpty || isProcessing)

          ToolButton(
            title: "生成代码",
            action: { performOperation(.generateModel) },
            style: .secondary
          )
          .disabled(inputJSON.isEmpty || !isValidJSON || isProcessing || className.isEmpty)

          ToolButton(
            title: "提取路径",
            action: extractJSONPaths,
            style: .secondary
          )
          .disabled(inputJSON.isEmpty || !isValidJSON || isProcessing)

          Spacer()

          // 处理状态
          ProcessingStateView(
            isProcessing: isProcessing,
            message: isProcessing ? "处理中..." : "就绪")
        }

        // 第二行：配置选项
        HStack(spacing: 16) {
          // 编程语言选择
          HStack(spacing: 8) {
            Text("编程语言:")
              .font(.callout)
              .foregroundStyle(.secondary)

            Picker("语言", selection: $selectedLanguage) {
              ForEach(ProgrammingLanguage.allCases) { language in
                Text(language.rawValue).tag(language)
              }
            }
            .pickerStyle(.menu)
            .frame(width: 100)
          }

          // 类名输入
          HStack(spacing: 8) {
            Text("类名:")
              .font(.callout)
              .foregroundStyle(.secondary)

            TextField("类名", text: $className)
              .textFieldStyle(.roundedBorder)
              .frame(width: 120)
          }

          Spacer()

          // 示例JSON和清空按钮
          HStack(spacing: 8) {
            Button("示例JSON") {
              loadSampleJSON()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.blue)

            Button("清空") {
              clearAll()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.red)
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  // 左侧输入区域
  private var inputSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // 标题和状态
      HStack {
        Text("JSON输入")
          .font(.headline)
          .foregroundStyle(.primary)

        Spacer()

        // 实时验证状态
        HStack(spacing: 4) {
          Image(systemName: isValidJSON ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(isValidJSON ? .green : .red)

          Text(isValidJSON ? "格式正确" : validationMessage)
            .font(.caption)
            .foregroundStyle(isValidJSON ? .green : .red)
        }
      }

      // 输入区域
      if inputJSON.isEmpty {
        EnhancedDropZone.forJSON(
          onFilesDropped: { urls in
            loadJSONFromFile(urls.first)
          },
          onButtonTapped: {
            Task {
              await openFileDialog()
            }
          })
      } else {
        VStack(alignment: .leading, spacing: 8) {
          ToolTextField(
            title: "",
            text: $inputJSON,
            placeholder: "输入或粘贴JSON内容...",
            minHeight: 200,
            maxHeight: 600)

          // 统计信息
          if !inputJSON.isEmpty {
            HStack(spacing: 12) {
              Text("字符数: \(inputJSON.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

              Text("行数: \(inputJSON.components(separatedBy: .newlines).count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

              Spacer()
            }
          }
        }
      }

      Spacer()
    }
    .padding(16)
  }

  // 右侧输出区域
  private var outputSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("输出结果")
        .font(.headline)
        .foregroundStyle(.primary)

      if outputText.isEmpty && formattedJSON.isEmpty {
        // 空状态
        VStack(spacing: 16) {
          Spacer()

          Image(systemName: "doc.text")
            .font(.system(size: 48))
            .foregroundStyle(.secondary.opacity(0.5))

          Text("处理结果将在这里显示")
            .font(.title3)
            .foregroundStyle(.secondary)

          Text("选择左侧的JSON内容，然后点击上方的操作按钮")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          Spacer()
        }
        .frame(maxWidth: .infinity)
      } else {
        // 根据操作类型选择显示方式
        if (lastOperation == .format || lastOperation == .minify) && !formattedJSON.isEmpty {
          // 使用JSONWebView显示格式化的JSON
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text(lastOperation == .format ? "格式化结果" : "压缩结果")
                .font(.subheadline)
                .foregroundStyle(.secondary)
              
              Spacer()
              
              Button("复制JSON") {
                copyToClipboard(formattedJSON)
              }
              .buttonStyle(.borderless)
              .font(.caption)
              .foregroundStyle(.blue)
            }
            
            JSONWebView(jsonString: formattedJSON)
              .frame(minHeight: 300)
              .background(Color(NSColor.controlBackgroundColor))
              .cornerRadius(8)
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
              )
          }
        } else if lastOperation == .validate && !formattedJSON.isEmpty && !outputText.isEmpty {
          // 验证成功或路径提取时显示JSONWebView和信息
          VStack(alignment: .leading, spacing: 16) {
            // 信息显示
            ToolResultView(
              title: extractedPaths.isEmpty ? "验证结果" : "路径提取结果",
              content: outputText,
              canCopy: true)
            
            // JSON预览
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text("JSON预览")
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("复制JSON") {
                  copyToClipboard(formattedJSON)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.blue)
              }
              
              JSONWebView(jsonString: formattedJSON)
                .frame(minHeight: 250)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                  RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
          }
        } else if !outputText.isEmpty {
          // 使用文本显示其他操作结果
          ToolResultView(
            title: getResultTitle(),
            content: outputText,
            canCopy: true)
        }
      }

      Spacer()
    }
    .padding(16)
  }
  
  private func getResultTitle() -> String {
    switch lastOperation {
    case .validate:
      return "验证结果"
    case .generateModel:
      return "生成的\(selectedLanguage.rawValue)代码"
    default:
      return "处理结果"
    }
  }

  private func validateJSONInput(_ jsonString: String) {
    guard !jsonString.isEmpty else {
      isValidJSON = true
      validationMessage = ""
      return
    }

    let result = jsonService.validateJSON(jsonString)
    isValidJSON = result.isValid
    validationMessage = result.errorMessage ?? ""
  }

  private func performOperation(_ operation: JSONOperation) {
    Task {
      await processJSON(operation)
    }
  }

  @MainActor
  private func processJSON(_ operation: JSONOperation) async {
    isProcessing = true
    outputText = ""
    formattedJSON = ""
    lastOperation = operation

    do {
      let result: String

      switch operation {
      case .format:
        result = try jsonService.formatJSON(inputJSON)
        formattedJSON = result
      case .minify:
        result = try jsonService.minifyJSON(inputJSON)
        formattedJSON = result
      case .validate:
        let validation = jsonService.validateJSON(inputJSON)
        if validation.isValid {
          // 对于有效的JSON，显示格式化版本和统计信息
          let formatted = try jsonService.formatJSON(inputJSON)
          formattedJSON = formatted
          
          // 计算统计信息
          let stats = calculateJSONStats(inputJSON)
          outputText = """
            ✅ JSON格式正确
            
            统计信息:
            • 字符数: \(stats.characterCount)
            • 行数: \(stats.lineCount)
            • 对象数: \(stats.objectCount)
            • 数组数: \(stats.arrayCount)
            • 字符串字段数: \(stats.stringCount)
            • 数字字段数: \(stats.numberCount)
            • 布尔字段数: \(stats.booleanCount)
            """
        } else {
          result = "❌ JSON格式错误: \(validation.errorMessage ?? "")"
          outputText = result
        }
      case .generateModel:
        result = try jsonService.generateModelCode(
          inputJSON,
          language: selectedLanguage,
          className: className)
        outputText = result
      }

    } catch let error as ToolError {
      currentError = error
    } catch {
      currentError = ToolError.processingFailed(error.localizedDescription)
    }

    isProcessing = false
  }

  private func extractJSONPaths() {
    Task {
      await extractPaths()
    }
  }

  @MainActor
  private func extractPaths() async {
    isProcessing = true
    lastOperation = .validate // 用于路径提取显示

    do {
      let paths = try jsonService.extractJSONPaths(inputJSON)
      let formatted = try jsonService.formatJSON(inputJSON)
      formattedJSON = formatted
      
      outputText = """
        📍 提取的JSON路径 (共\(paths.count)个):
        
        \(paths.joined(separator: "\n"))
        """
      
      extractedPaths = paths
    } catch let error as ToolError {
      currentError = error
      formattedJSON = ""
      outputText = ""
    } catch {
      currentError = ToolError.processingFailed(error.localizedDescription)
      formattedJSON = ""
      outputText = ""
    }

    isProcessing = false
  }

  private func loadSampleJSON() {
    inputJSON = """
      {
        "application": {
          "name": "Tools",
          "version": "2.0.0",
          "platform": "macOS",
          "features": [
            {
              "id": "json-processor",
              "name": "JSON处理器",
              "description": "强大的JSON格式化、验证和代码生成工具",
              "enabled": true,
              "settings": {
                "autoFormat": true,
                "showLineNumbers": true,
                "theme": "dark"
              }
            },
            {
              "id": "encryption",
              "name": "加密工具",
              "description": "支持多种加密算法的安全工具",
              "enabled": true,
              "algorithms": ["AES", "RSA", "SHA256"]
            }
          ]
        },
        "user": {
          "id": 12345,
          "name": "开发者",
          "email": "developer@example.com",
          "isActive": true,
          "profile": {
            "age": 28,
            "city": "北京",
            "skills": ["Swift", "iOS", "macOS", "JSON"],
            "experience": 5.5,
            "projects": [
              {
                "name": "工具集",
                "status": "active",
                "technologies": ["SwiftUI", "WebKit"]
              }
            ]
          },
          "preferences": {
            "theme": "dark",
            "language": "zh-CN",
            "notifications": {
              "email": true,
              "push": false,
              "sms": true
            }
          }
        },
        "metadata": {
          "createdAt": "2025-01-15T10:30:00Z",
          "updatedAt": "2025-01-23T14:45:30Z",
          "version": "1.2.0",
          "buildNumber": 42
        }
      }
      """
  }

  private func loadJSONFromFile(_ url: URL?) {
    guard let url else { return }

    Task {
      do {
        // Validate file size (max 10MB for JSON)
        if !FileDialogUtils.validateFileSize(url, maxSize: 10 * 1024 * 1024) {
          await MainActor.run {
            currentError = .fileTooLarge(10 * 1024 * 1024)
          }
          return
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        await MainActor.run {
          inputJSON = content
        }
      } catch {
        await MainActor.run {
          currentError = .fileNotFound(url.lastPathComponent)
        }
      }
    }
  }

  private func openFileDialog() async {
    if let url = await FileDialogUtils.showEnhancedOpenDialog(
      allowedTypes: [.json, .plainText],
      message: "选择要处理的JSON文件",
      allowMultiple: false,
      title: "选择JSON文件"
    ).first {
      await MainActor.run {
        loadJSONFromFile(url)
      }
    }
  }

  private func clearAll() {
    inputJSON = ""
    outputText = ""
    formattedJSON = ""
    className = "Model"
    isValidJSON = true
    validationMessage = ""
    extractedPaths = []
    lastOperation = .format
  }
  
  private func copyToClipboard(_ text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(text, forType: .string)
  }
  
  private func calculateJSONStats(_ jsonString: String) -> JSONStats {
    var stats = JSONStats()
    stats.characterCount = jsonString.count
    stats.lineCount = jsonString.components(separatedBy: .newlines).count
    
    // Parse JSON to count elements
    if let data = jsonString.data(using: .utf8),
       let jsonObject = try? JSONSerialization.jsonObject(with: data) {
      countJSONElements(jsonObject, stats: &stats)
    }
    
    return stats
  }
  
  private func countJSONElements(_ object: Any, stats: inout JSONStats) {
    switch object {
    case let dict as [String: Any]:
      stats.objectCount += 1
      for (_, value) in dict {
        countJSONElements(value, stats: &stats)
      }
    case let array as [Any]:
      stats.arrayCount += 1
      for item in array {
        countJSONElements(item, stats: &stats)
      }
    case is String:
      stats.stringCount += 1
    case is NSNumber:
      // Check if it's a boolean first
      let number = object as! NSNumber
      if CFBooleanGetTypeID() == CFGetTypeID(number) {
        stats.booleanCount += 1
      } else {
        stats.numberCount += 1
      }
    case is Bool:
      stats.booleanCount += 1
    case is Int, is Double, is Float:
      stats.numberCount += 1
    default:
      break
    }
  }
}

struct JSONStats {
  var characterCount: Int = 0
  var lineCount: Int = 0
  var objectCount: Int = 0
  var arrayCount: Int = 0
  var stringCount: Int = 0
  var numberCount: Int = 0
  var booleanCount: Int = 0
}

#Preview {
  JSONView()
}
