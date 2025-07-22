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
  @State private var selectedLanguage: ProgrammingLanguage = .swift
  @State private var className: String = "Model"
  @State private var isValidJSON: Bool = true
  @State private var validationMessage: String = ""
  @State private var isProcessing: Bool = false
  @State private var currentError: ToolError?
  @State private var showingJSONPath: Bool = false
  @State private var extractedPaths: [String] = []
  @State private var selectedOperation: JSONOperation = .format

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

      if outputText.isEmpty {
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
        ToolResultView(
          title: "处理结果",
          content: outputText,
          canCopy: true)
      }

      Spacer()
    }
    .padding(16)
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

    do {
      let result: String

      switch operation {
      case .format:
        result = try jsonService.formatJSON(inputJSON)
      case .minify:
        result = try jsonService.minifyJSON(inputJSON)
      case .validate:
        let validation = jsonService.validateJSON(inputJSON)
        result = validation.isValid ? "JSON格式正确" : "JSON格式错误: \(validation.errorMessage ?? "")"
      case .generateModel:
        result = try jsonService.generateModelCode(
          inputJSON,
          language: selectedLanguage,
          className: className)
      }

      outputText = result
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

    do {
      let paths = try jsonService.extractJSONPaths(inputJSON)
      outputText = paths.joined(separator: "\n")
    } catch let error as ToolError {
      currentError = error
    } catch {
      currentError = ToolError.processingFailed(error.localizedDescription)
    }

    isProcessing = false
  }

  private func loadSampleJSON() {
    inputJSON = """
      {
        "user": {
          "id": 12345,
          "name": "张三",
          "email": "zhangsan@example.com",
          "isActive": true,
          "profile": {
            "age": 28,
            "city": "北京",
            "skills": ["Swift", "iOS", "macOS"],
            "experience": 5.5
          },
          "preferences": {
            "theme": "dark",
            "notifications": {
              "email": true,
              "push": false,
              "sms": true
            }
          }
        },
        "metadata": {
          "createdAt": "2025-01-15T10:30:00Z",
          "updatedAt": "2025-01-18T14:45:30Z",
          "version": "1.2.0"
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
    className = "Model"
    isValidJSON = true
    validationMessage = ""
    extractedPaths = []
  }
}

#Preview {
  JSONView()
}
