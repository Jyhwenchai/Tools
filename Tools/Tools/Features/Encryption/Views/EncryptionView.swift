//
//  EncryptionView.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

struct EncryptionView: View {
  @State private var inputText: String = ""
  @State private var outputText: String = ""
  @State private var selectedAlgorithmId: String = "md5"
  @State private var isEncrypting: Bool = true
  @State private var keyInput: String = ""
  @State private var isProcessing: Bool = false
  @State private var currentError: ToolError?
  @State private var selectedCategory: AlgorithmCategory = .hash

  private let algorithmRegistry = AlgorithmRegistry.shared
  
  private var selectedAlgorithm: any CryptographicAlgorithm {
    algorithmRegistry.algorithm(for: selectedAlgorithmId) ?? MD5Algorithm()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      algorithmSettingsCard
      inputCard
      outputCard
      Spacer()
    }
    .padding(24)
    .navigationTitle("加密解密")
    .errorAlert($currentError)
    .onChange(of: selectedCategory) { _, newCategory in
      handleCategoryChange(newCategory)
    }
    .onChange(of: selectedAlgorithmId) { _, _ in
      handleAlgorithmChange()
    }
    .onChange(of: isEncrypting) { _, _ in
      outputText = ""
    }
  }
  
  private var algorithmSettingsCard: some View {
    BrightCardView {
      VStack(alignment: .leading, spacing: 16) {
        Text("算法设置")
          .font(.headline)
          .foregroundStyle(.primary)

        categoryPicker
        algorithmPicker
        
        if selectedAlgorithm.supportsDecryption {
          modePicker
        }
        
        if selectedAlgorithm.requiresKey {
          keyInputField
        }
      }
    }
  }
  
  private var categoryPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("算法分类")
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      Picker("分类", selection: $selectedCategory) {
        ForEach(AlgorithmCategory.allCases, id: \.self) { category in
          HStack {
            Image(systemName: category.icon)
            Text(category.rawValue)
          }
          .tag(category)
        }
      }
      .pickerStyle(.segmented)
    }
  }
  
  private var algorithmPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("加密算法")
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      let availableAlgorithms = algorithmRegistry.algorithms(in: selectedCategory)
      Picker("算法", selection: $selectedAlgorithmId) {
        ForEach(availableAlgorithms, id: \.identifier) { algorithm in
          VStack(alignment: .leading) {
            Text(algorithm.displayName)
              .font(.callout)
            Text(algorithm.description)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .tag(algorithm.identifier)
        }
      }
      .pickerStyle(.menu)
    }
  }
  
  private var modePicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("操作模式")
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      Picker("模式", selection: $isEncrypting) {
        Text("加密").tag(true)
        Text("解密").tag(false)
      }
      .pickerStyle(.segmented)
    }
  }
  
  private var keyInputField: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("密钥")
          .font(.callout)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
        
        if let requirements = selectedAlgorithm.keyRequirements {
          Text("(最少\(requirements.minLength)位)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      TextField("请输入密钥", text: $keyInput)
        .textFieldStyle(BrightTextFieldStyle())
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color(.separatorColor), lineWidth: 1.5)
        )
    }
  }
  
  private var inputCard: some View {
    BrightCardView {
      VStack(alignment: .leading, spacing: 16) {
        Text("输入")
          .font(.headline)
          .foregroundStyle(.primary)

        inputTextArea
        actionButtons
      }
    }
  }
  
  private var inputTextArea: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(isEncrypting ? "待加密文本" : "待解密文本")
        .font(.callout)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
      
      ScrollView {
        TextField(
          isEncrypting ? "输入需要加密的文本..." : "输入需要解密的文本...",
          text: $inputText,
          axis: .vertical
        )
        .textFieldStyle(BrightTextFieldStyle())
        .lineLimit(5...15)
      }
      .frame(minHeight: 120, maxHeight: 300)
      .background(Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color(.separatorColor), lineWidth: 1.5)
      )
      .shadow(
        color: Color.black.opacity(0.03),
        radius: 2,
        x: 0,
        y: 1
      )
    }
  }
  
  private var actionButtons: some View {
    HStack {
      ToolButton(
        title: isEncrypting ? "加密" : "解密",
        action: processText,
        style: .primary)
        .disabled(inputText.isEmpty || isProcessing || (selectedAlgorithm.requiresKey && keyInput.isEmpty))

      ToolButton(
        title: "清空",
        action: clearAll,
        style: .secondary)

      Spacer()

      ProcessingStateView(
        isProcessing: isProcessing,
        message: isProcessing ? "处理中..." : "就绪")
    }
  }
  
  @ViewBuilder
  private var outputCard: some View {
    if !outputText.isEmpty {
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          Text("输出")
            .font(.headline)
            .foregroundStyle(.primary)

          ToolResultView(
            title: isEncrypting ? "加密结果" : "解密结果",
            content: outputText,
            canCopy: true)
        }
      }
    }
  }
  
  private func handleCategoryChange(_ newCategory: AlgorithmCategory) {
    let algorithms = algorithmRegistry.algorithms(in: newCategory)
    if let firstAlgorithm = algorithms.first {
      selectedAlgorithmId = firstAlgorithm.identifier
    }
    outputText = ""
    keyInput = ""
  }
  
  private func handleAlgorithmChange() {
    if !selectedAlgorithm.supportsDecryption {
      isEncrypting = true
    }
    outputText = ""
    keyInput = ""
  }

  private func processText() {
    Task {
      await performEncryption()
    }
  }

  @MainActor
  private func performEncryption() async {
    isProcessing = true
    outputText = ""

    do {
      // Validate input first
      try selectedAlgorithm.validate(input: inputText, key: selectedAlgorithm.requiresKey ? keyInput : nil)
      
      let key = selectedAlgorithm.requiresKey ? keyInput : nil
      let result: String
      if isEncrypting {
        result = try selectedAlgorithm.encrypt(inputText, key: key)
      } else {
        result = try selectedAlgorithm.decrypt(inputText, key: key)
      }

      outputText = result
    } catch let error as ToolError {
      currentError = error
    } catch {
      currentError = ToolError.processingFailed(error.localizedDescription)
    }

    isProcessing = false
  }

  private func clearAll() {
    inputText = ""
    outputText = ""
    keyInput = ""
  }
}

#Preview {
  EncryptionView()
}
