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
  @State private var selectedAlgorithm: EncryptionAlgorithm = .md5
  @State private var isEncrypting: Bool = true
  @State private var aesKey: String = ""
  @State private var isProcessing: Bool = false
  @State private var currentError: ToolError?

  private let encryptionService = EncryptionService.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // 算法选择和模式切换
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          Text("算法设置")
            .font(.headline)
            .foregroundStyle(.primary)

          // 算法选择器
          VStack(alignment: .leading, spacing: 8) {
            Text("加密算法")
              .font(.callout)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)

            Picker("算法", selection: $selectedAlgorithm) {
              ForEach(EncryptionAlgorithm.allCases) { algorithm in
                VStack(alignment: .leading) {
                  Text(algorithm.rawValue)
                    .font(.callout)
                  Text(algorithm.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .tag(algorithm)
              }
            }
            .pickerStyle(.menu)
          }

          // 加密/解密模式切换
          if selectedAlgorithm.supportsDecryption {
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

          // AES密钥输入
          if selectedAlgorithm == .aes {
            ToolTextField(
              title: "AES密钥",
              text: $aesKey,
              placeholder: "请输入加密密钥")
          }
        }
      }

      // 输入区域
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          Text("输入")
            .font(.headline)
            .foregroundStyle(.primary)

          ToolTextField(
            title: isEncrypting ? "待加密文本" : "待解密文本",
            text: $inputText,
            placeholder: isEncrypting ? "输入需要加密的文本..." : "输入需要解密的文本...")

          HStack {
            ToolButton(
              title: isEncrypting ? "加密" : "解密",
              action: processText,
              style: .primary)
              .disabled(inputText.isEmpty || isProcessing)

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
      }

      // 输出区域
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

      Spacer()
    }
    .padding(24)
    .navigationTitle("加密解密")
    .errorAlert($currentError)
    .onChange(of: selectedAlgorithm) { _, _ in
      // 切换算法时重置模式
      if !selectedAlgorithm.supportsDecryption {
        isEncrypting = true
      }
      outputText = ""
    }
    .onChange(of: isEncrypting) { _, _ in
      outputText = ""
    }
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
      let result: String = if isEncrypting {
        try encryptionService.encrypt(
          inputText,
          using: selectedAlgorithm,
          key: selectedAlgorithm == .aes ? aesKey : nil)
      } else {
        try encryptionService.decrypt(
          inputText,
          using: selectedAlgorithm,
          key: selectedAlgorithm == .aes ? aesKey : nil)
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
    aesKey = ""
  }
}

#Preview {
  EncryptionView()
}
