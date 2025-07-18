//
//  JSONView.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

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
    VStack(alignment: .leading, spacing: 24) {
      // 输入区域
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Text("JSON输入")
              .font(.headline)
              .foregroundStyle(.primary)
            
            Spacer()
            
            Button("示例JSON") {
              loadSampleJSON()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.blue)
          }
          
          ToolTextField(
            title: "JSON内容",
            text: $inputJSON,
            placeholder: "输入或粘贴JSON内容，或点击'示例JSON'加载测试数据..."
          )
          
          // 实时验证状态和统计信息
          HStack {
            HStack(spacing: 4) {
              Image(systemName: isValidJSON ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isValidJSON ? .green : .red)
              
              Text(isValidJSON ? "JSON格式正确" : validationMessage)
                .font(.caption)
                .foregroundStyle(isValidJSON ? .green : .red)
            }
            
            Spacer()
            
            if !inputJSON.isEmpty {
              HStack(spacing: 12) {
                Text("字符数: \(inputJSON.count)")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                
                Text("行数: \(inputJSON.components(separatedBy: .newlines).count)")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .opacity(inputJSON.isEmpty ? 0 : 1)
          .animation(.easeInOut(duration: 0.2), value: isValidJSON)
        }
      }
      
      // 操作区域
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          Text("操作")
            .font(.headline)
            .foregroundStyle(.primary)
          
          // 代码生成设置
          HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
              Text("编程语言")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
              
              Picker("语言", selection: $selectedLanguage) {
                ForEach(ProgrammingLanguage.allCases) { language in
                  Text(language.rawValue).tag(language)
                }
              }
              .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 8) {
              Text("类名")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
              
              TextField("类名", text: $className)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
            }
          }
          
          // 操作按钮
          VStack(spacing: 12) {
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
              
              Spacer()
            }
            
            HStack(spacing: 12) {
              ToolButton(
                title: "提取路径",
                action: extractJSONPaths,
                style: .secondary
              )
              .disabled(inputJSON.isEmpty || !isValidJSON || isProcessing)
              
              ToolButton(
                title: "清空",
                action: clearAll,
                style: .secondary
              )
              
              Spacer()
              
              ProcessingStateView(
                isProcessing: isProcessing,
                message: isProcessing ? "处理中..." : "就绪"
              )
            }
          }
        }
      }
      
      // 输出区域
      if !outputText.isEmpty {
        BrightCardView {
          VStack(alignment: .leading, spacing: 16) {
            Text("输出")
              .font(.headline)
              .foregroundStyle(.primary)
            
            ToolResultView(
              title: "处理结果",
              content: outputText,
              canCopy: true
            )
          }
        }
      }
      
      Spacer()
    }
    .padding(24)
    .navigationTitle("JSON工具")
    .errorAlert($currentError)
    .onChange(of: inputJSON) { _, newValue in
      validateJSONInput(newValue)
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
        result = try jsonService.generateModelCode(inputJSON, language: selectedLanguage, className: className)
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