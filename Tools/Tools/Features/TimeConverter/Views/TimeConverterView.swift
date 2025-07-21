//
//  TimeConverterView.swift
//  Tools
//
//  Created by Kiro on 2025/7/18.
//

import SwiftUI

struct TimeConverterView: View {
  @State private var inputTime: String = ""
  @State private var outputTime: String = ""
  @State private var sourceFormat: TimeFormat = .timestamp
  @State private var targetFormat: TimeFormat = .iso8601
  @State private var sourceTimeZone: TimeZone = .current
  @State private var targetTimeZone: TimeZone = .current
  @State private var customFormat: String = "yyyy-MM-dd HH:mm:ss"
  @State private var includeMilliseconds: Bool = false
  @State private var isProcessing: Bool = false
  @State private var currentError: ToolError?
  @State private var validationMessage: String = ""
  @State private var isValidInput: Bool = true
  @State private var showCurrentTime: Bool = false

  private let timeService = TimeConverterService()

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // 输入区域
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Text("时间输入")
              .font(.headline)
              .foregroundStyle(.primary)

            Spacer()

            Button("当前时间") {
              loadCurrentTime()
            }
            .buttonStyle(.borderless)
            .font(.caption)
            .foregroundStyle(.blue)
          }

          ToolTextField(
            title: "时间内容",
            text: $inputTime,
            placeholder: "输入时间内容，或点击'当前时间'加载当前时间戳...")

          // 源格式选择
          VStack(alignment: .leading, spacing: 8) {
            Text("源格式")
              .font(.callout)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)

            Picker("源格式", selection: $sourceFormat) {
              ForEach(TimeFormat.allCases) { format in
                VStack(alignment: .leading) {
                  Text(format.displayName)
                  Text(format.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .tag(format)
              }
            }
            .pickerStyle(.menu)
          }

          // 自定义格式输入（仅在选择自定义格式时显示）
          if sourceFormat == .custom {
            ToolTextField(
              title: "自定义格式",
              text: $customFormat,
              placeholder: "例如: yyyy-MM-dd HH:mm:ss")
          }

          // 源时区选择
          VStack(alignment: .leading, spacing: 8) {
            Text("源时区")
              .font(.callout)
              .fontWeight(.semibold)
              .foregroundStyle(.primary)

            TimeZonePicker(selection: $sourceTimeZone)
          }

          // 输入验证状态
          if !inputTime.isEmpty {
            HStack(spacing: 4) {
              Image(systemName: isValidInput ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isValidInput ? .green : .red)

              Text(isValidInput ? "格式正确" : validationMessage)
                .font(.caption)
                .foregroundStyle(isValidInput ? .green : .red)
            }
            .animation(.easeInOut(duration: 0.2), value: isValidInput)
          }
        }
      }

      // 转换设置区域
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          Text("转换设置")
            .font(.headline)
            .foregroundStyle(.primary)

          HStack(spacing: 24) {
            // 目标格式选择
            VStack(alignment: .leading, spacing: 8) {
              Text("目标格式")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

              Picker("目标格式", selection: $targetFormat) {
                ForEach(TimeFormat.allCases) { format in
                  VStack(alignment: .leading) {
                    Text(format.displayName)
                    Text(format.description)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                  .tag(format)
                }
              }
              .pickerStyle(.menu)
            }

            // 目标时区选择
            VStack(alignment: .leading, spacing: 8) {
              Text("目标时区")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

              TimeZonePicker(selection: $targetTimeZone)
            }
          }

          // 自定义目标格式输入（仅在选择自定义格式时显示）
          if targetFormat == .custom {
            ToolTextField(
              title: "目标自定义格式",
              text: $customFormat,
              placeholder: "例如: yyyy-MM-dd HH:mm:ss")
          }

          // 选项
          HStack {
            Toggle("包含毫秒", isOn: $includeMilliseconds)
              .font(.callout)

            Spacer()
          }

          // 操作按钮
          HStack(spacing: 12) {
            ToolButton(
              title: "转换",
              action: convertTime,
              style: .primary)
              .disabled(inputTime.isEmpty || !isValidInput || isProcessing)

            ToolButton(
              title: "交换格式",
              action: swapFormats,
              style: .secondary)

            ToolButton(
              title: "清空",
              action: clearAll,
              style: .secondary)

            Spacer()

            ProcessingStateView(
              isProcessing: isProcessing,
              message: isProcessing ? "转换中..." : "就绪")
          }
        }
      }

      // 输出区域
      if !outputTime.isEmpty {
        BrightCardView {
          VStack(alignment: .leading, spacing: 16) {
            Text("转换结果")
              .font(.headline)
              .foregroundStyle(.primary)

            ToolResultView(
              title: "转换后的时间",
              content: outputTime,
              canCopy: true)
          }
        }
      }

      // 格式示例区域
      BrightCardView {
        VStack(alignment: .leading, spacing: 16) {
          Text("格式示例")
            .font(.headline)
            .foregroundStyle(.primary)

          FormatExamplesView(timeService: timeService)
        }
      }

      Spacer()
    }
    .padding(24)
    .navigationTitle("时间转换")
    .errorAlert($currentError)
    .onChange(of: inputTime) { _, newValue in
      validateInput(newValue)
      if isValidInput, !newValue.isEmpty {
        performRealTimeConversion()
      } else {
        outputTime = ""
      }
    }
    .onChange(of: sourceFormat) { _, _ in
      validateInput(inputTime)
      if isValidInput, !inputTime.isEmpty {
        performRealTimeConversion()
      }
    }
    .onChange(of: targetFormat) { _, _ in
      if isValidInput, !inputTime.isEmpty {
        performRealTimeConversion()
      }
    }
    .onChange(of: sourceTimeZone) { _, _ in
      if isValidInput, !inputTime.isEmpty {
        performRealTimeConversion()
      }
    }
    .onChange(of: targetTimeZone) { _, _ in
      if isValidInput, !inputTime.isEmpty {
        performRealTimeConversion()
      }
    }
    .onChange(of: customFormat) { _, _ in
      if sourceFormat == .custom || targetFormat == .custom {
        validateInput(inputTime)
        if isValidInput, !inputTime.isEmpty {
          performRealTimeConversion()
        }
      }
    }
    .onChange(of: includeMilliseconds) { _, _ in
      if isValidInput, !inputTime.isEmpty {
        performRealTimeConversion()
      }
    }
  }

  private func validateInput(_ input: String) {
    guard !input.isEmpty else {
      isValidInput = true
      validationMessage = ""
      return
    }

    let format = sourceFormat == .custom ? customFormat : ""

    // 特殊处理时间戳验证
    if sourceFormat == .timestamp {
      isValidInput = timeService.validateTimestamp(input)
      if !isValidInput {
        validationMessage = "时间戳格式无效，请输入有效的Unix时间戳"
      } else {
        validationMessage = ""
      }
    } else {
      isValidInput = timeService.validateDateString(
        input,
        format: sourceFormat,
        customFormat: format)
      if !isValidInput {
        switch sourceFormat {
        case .iso8601:
          validationMessage = "ISO 8601格式无效，例如: 2022-01-01T12:00:00Z"
        case .rfc2822:
          validationMessage = "RFC 2822格式无效，例如: Mon, 01 Jan 2022 12:00:00 GMT"
        case .custom:
          validationMessage = "自定义格式无效，请检查格式字符串和输入内容"
        default:
          validationMessage = "输入格式不匹配所选格式"
        }
      } else {
        validationMessage = ""
      }
    }
  }

  private func performRealTimeConversion() {
    guard !inputTime.isEmpty, isValidInput else {
      outputTime = ""
      return
    }

    let options = TimeConversionOptions(
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
      sourceTimeZone: sourceTimeZone,
      targetTimeZone: targetTimeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds)

    let result = timeService.convertTime(input: inputTime, options: options)

    if result.success {
      outputTime = result.result
      currentError = nil
    } else {
      outputTime = ""
      // 不在实时转换中显示错误，避免过于频繁的错误提示
    }
  }

  private func convertTime() {
    Task {
      await performConversion()
    }
  }

  @MainActor
  private func performConversion() async {
    isProcessing = true
    currentError = nil

    let options = TimeConversionOptions(
      sourceFormat: sourceFormat,
      targetFormat: targetFormat,
      sourceTimeZone: sourceTimeZone,
      targetTimeZone: targetTimeZone,
      customFormat: customFormat,
      includeMilliseconds: includeMilliseconds)

    let result = timeService.convertTime(input: inputTime, options: options)

    if result.success {
      outputTime = result.result
    } else {
      outputTime = ""
      currentError = ToolError.processingFailed(result.error ?? "转换失败")
    }

    isProcessing = false
  }

  private func swapFormats() {
    let tempFormat = sourceFormat
    let tempTimeZone = sourceTimeZone

    sourceFormat = targetFormat
    sourceTimeZone = targetTimeZone
    targetFormat = tempFormat
    targetTimeZone = tempTimeZone

    // 如果有输出结果，将其作为新的输入
    if !outputTime.isEmpty {
      inputTime = outputTime
      outputTime = ""
    }
  }

  private func loadCurrentTime() {
    let timestamp = timeService.getCurrentTimestamp(includeMilliseconds: includeMilliseconds)
    inputTime = timestamp
    sourceFormat = .timestamp
  }

  private func clearAll() {
    inputTime = ""
    outputTime = ""
    sourceFormat = .timestamp
    targetFormat = .iso8601
    sourceTimeZone = .current
    targetTimeZone = .current
    customFormat = "yyyy-MM-dd HH:mm:ss"
    includeMilliseconds = false
    isValidInput = true
    validationMessage = ""
  }
}

// MARK: - Time Zone Picker

struct TimeZonePicker: View {
  @Binding var selection: TimeZone

  var body: some View {
    Picker("时区", selection: $selection) {
      ForEach(TimeZoneInfo.commonTimeZones, id: \.identifier) { timeZoneInfo in
        VStack(alignment: .leading) {
          Text(timeZoneInfo.displayName)
          Text(timeZoneInfo.offsetString)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .tag(TimeZone(identifier: timeZoneInfo.identifier) ?? .current)
      }
    }
    .pickerStyle(.menu)
  }
}

// MARK: - Format Examples View

struct FormatExamplesView: View {
  let timeService: TimeConverterService

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(TimeFormat.allCases) { format in
        VStack(alignment: .leading, spacing: 4) {
          Text(format.displayName)
            .font(.callout)
            .fontWeight(.medium)
            .foregroundStyle(.primary)

          Text(format.description)
            .font(.caption)
            .foregroundStyle(.secondary)

          Text(timeService.getCurrentTime(format: format, includeMilliseconds: false))
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.bottom, 8)
      }
    }
  }
}

#Preview {
  TimeConverterView()
}
