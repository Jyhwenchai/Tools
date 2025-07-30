//
//  TimestampToDateView.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI

struct TimestampToDateView: View {
    @State private var timestampInput: String = ""
    @State private var convertedDate: String = ""
    @State private var selectedTimeZone: TimeZone = .current
    @State private var includeMilliseconds: Bool = false
    @State private var validationState: InputValidationState = .valid
    @State private var currentError: ToolError?
    @State private var enhancedError: EnhancedErrorInfo?
    @State private var isProcessing: Bool = false
    @State private var timezoneValidation: TimezoneValidationResult = .valid

    @Environment(ToastManager.self) private var toastManager

    private let timeService = TimeConverterService()
    private let validationService = ValidationService()
    private let validationConfig = RealTimeValidationConfig.default

    var body: some View {
        BrightCardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("时间戳转日期时间")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("当前时间戳") {
                        loadCurrentTimestamp()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.blue)
                }

                // Timestamp Input with Enhanced Validation
                ValidatedTextField(
                    title: "时间戳",
                    text: $timestampInput,
                    placeholder: "输入Unix时间戳 (例如: 1640995200)",
                    validationState: validationState,
                    onValidationChange: { newValue in
                        validateInputRealTime(newValue)
                    }
                )
                .accessibilityLabel("时间戳输入框")
                .accessibilityHint("输入要转换的Unix时间戳")

                // Timezone Selection with Validation
                VStack(alignment: .leading, spacing: 8) {
                    Text("目标时区")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    TimeZonePicker(selection: $selectedTimeZone)

                    // Timezone validation feedback
                    if !timezoneValidation.isValid || timezoneValidation.hasRecommendations {
                        ValidationFeedbackView(
                            validationState: timezoneValidation.isValid
                                ? .warning(
                                    message: timezoneValidation.recommendations.first ?? "",
                                    suggestions: Array(
                                        timezoneValidation.recommendations.dropFirst())
                                )
                                : .invalid(
                                    message: timezoneValidation.compatibilityIssues.first ?? "",
                                    suggestions: timezoneValidation.recommendations
                                )
                        )
                    }
                }

                // Options
                HStack {
                    Toggle("包含毫秒", isOn: $includeMilliseconds)
                        .font(.callout)
                        .toggleStyle(.switch)
                        .accessibilityLabel("包含毫秒选项")
                        .accessibilityHint("是否在转换结果中包含毫秒精度")

                    Spacer()
                }

                // Convert Button
                HStack {
//                    ToolButton(
//                        title: "转换",
//                        action: performConversion,
//                        style: .primary
//                    )
//                    .disabled(timestampInput.isEmpty || !validationState.isValid || isProcessing)
//                    .accessibilityLabel("转换按钮")
//                    .accessibilityHint("将输入的时间戳转换为日期格式")
//                    .keyboardShortcut(.return, modifiers: [])

                    ToolButton(
                        title: "清空",
                        action: clearInput,
                        style: .secondary
                    )
                    .accessibilityLabel("清空按钮")
                    .accessibilityHint("清空所有输入和结果")

                    // Enhanced error display
                    if let enhancedError = enhancedError {
                        EnhancedErrorView(
                            errorInfo: enhancedError,
                            onRecoveryAction: handleRecoveryAction
                        )
                    }

                    Spacer()

                    ProcessingStateView(
                        isProcessing: isProcessing,
                        message: isProcessing ? "转换中..." : "就绪"
                    )
                }

                // Result Display
                if !convertedDate.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("转换结果")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        ToolResultView(
                            title: "",
                            content: convertedDate,
                            canCopy: true
                        )
                    }
                }
            }
        }
        .errorAlert($currentError)
        .onChange(of: selectedTimeZone) { _, _ in
            validateInputRealTime(timestampInput)
        }
        .onChange(of: includeMilliseconds) { _, _ in
            if validationState.isValid && !timestampInput.isEmpty {
                performRealTimeConversion()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("时间戳转日期转换器")
        .accessibilityHint("输入Unix时间戳转换为可读日期格式")
        .onReceive(NotificationCenter.default.publisher(for: .timestampToDateTriggerConversion)) {
            _ in
            if !timestampInput.isEmpty && validationState.isValid {
                performConversion()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .timestampToDateTriggerCopy)) { _ in
            if !convertedDate.isEmpty {
                copyResult()
            }
        }
    }

    // MARK: - Private Methods

    private func validateInputRealTime(_ input: String) {
        let context = ValidationContext(
            format: .timestamp,
            timeZone: selectedTimeZone,
            allowEmpty: true
        )

        validationState = validationService.validateInput(
            input,
            context: context,
            config: validationConfig
        )

        // Validate timezone compatibility
        timezoneValidation = validationService.validateTimezoneCompatibility(
            source: .current,
            target: selectedTimeZone
        )

        // Trigger real-time conversion if valid
        if validationState.isValid && !input.isEmpty {
            performRealTimeConversion()
        } else {
            convertedDate = ""
        }
    }

    private func performRealTimeConversion() {
        guard !timestampInput.isEmpty && validationState.isValid else {
            convertedDate = ""
            return
        }

        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: .current,
            targetTimeZone: selectedTimeZone,
            includeMilliseconds: includeMilliseconds,
            enableRealTimeConversion: true,
            validateInput: true
        )

        let result = timeService.convertTime(input: timestampInput, options: options)

        if result.success {
            convertedDate = result.result
            currentError = nil
            enhancedError = nil
        } else {
            convertedDate = ""
            // Don't show errors during real-time conversion to avoid frequent error messages
        }
    }

    private func performConversion() {
        Task {
            await convertTimestamp()
        }
    }

    @MainActor
    private func convertTimestamp() async {
        isProcessing = true
        currentError = nil
        enhancedError = nil

        let options = TimeConversionOptions(
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: .current,
            targetTimeZone: selectedTimeZone,
            includeMilliseconds: includeMilliseconds,
            validateInput: true
        )

        let result = timeService.convertTime(input: timestampInput, options: options)

        if result.success {
            convertedDate = result.result

            // Show success toast notification
            toastManager.show(
                "时间戳转换成功",
                type: .success,
                duration: 2.0
            )
        } else {
            convertedDate = ""

            // Generate enhanced error information
            let context = ValidationContext(
                format: .timestamp,
                timeZone: selectedTimeZone
            )

            if let errorMessage = result.error,
                let timeConverterError = parseTimeConverterError(from: errorMessage)
            {
                enhancedError = validationService.generateEnhancedError(
                    from: timeConverterError,
                    context: context,
                    inputValue: timestampInput
                )

                // Show error toast notification
                toastManager.show(
                    "时间戳转换失败: \(errorMessage)",
                    type: .error,
                    duration: 4.0
                )
            } else {
                currentError = ToolError.processingFailed(result.error ?? "时间戳转换失败")

                // Show generic error toast
                toastManager.show(
                    "时间戳转换失败，请检查输入格式",
                    type: .error,
                    duration: 3.0
                )
            }
        }

        isProcessing = false
    }

    private func loadCurrentTimestamp() {
        let timestamp = timeService.getCurrentTimestamp(includeMilliseconds: includeMilliseconds)
        timestampInput = timestamp
    }

    private func clearInput() {
        timestampInput = ""
        convertedDate = ""
        selectedTimeZone = .current
        includeMilliseconds = false
        validationState = .valid
        timezoneValidation = .valid
        currentError = nil
        enhancedError = nil
    }

    private func handleRecoveryAction(_ action: RecoveryAction) {
        action.action()
    }

    private func parseTimeConverterError(from message: String) -> TimeConverterError? {
        // Parse error message to determine TimeConverterError type
        if message.contains("Invalid timestamp") {
            return .invalidTimestamp(timestampInput)
        } else if message.contains("timezone") {
            return .timezoneConversionFailed
        } else if message.contains("empty") {
            return .inputEmpty
        } else {
            return .outputGenerationFailed
        }
    }

    private func copyResult() {
        guard !convertedDate.isEmpty else {
            toastManager.show("没有可复制的转换结果", type: .warning, duration: 2.0)
            return
        }

        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.setString(convertedDate, forType: .string)

        if success {
            // Show success toast notification
            toastManager.show(
                "转换结果已复制到剪贴板",
                type: .success,
                duration: 2.0
            )

            // Announce to screen reader
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSAccessibility.post(
                    element: NSApp.mainWindow as Any,
                    notification: .announcementRequested,
                    userInfo: [
                        .announcement: "转换结果已复制到剪贴板: \(convertedDate)",
                        .priority: NSAccessibilityPriorityLevel.medium.rawValue,
                    ]
                )
            }
        } else {
            // Show error toast notification
            toastManager.show(
                "复制失败，请重试",
                type: .error,
                duration: 3.0
            )
        }
    }
}

#Preview {
    TimestampToDateView()
        .padding()
}
