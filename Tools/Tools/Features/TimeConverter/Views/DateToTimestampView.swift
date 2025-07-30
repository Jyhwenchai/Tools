//
//  DateToTimestampView.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI

struct DateToTimestampView: View {
    @State private var dateInput: String = ""
    @State private var convertedTimestamp: String = ""
    @State private var selectedTimeZone: TimeZone = .current
    @State private var timestampUnit: TimestampUnit = .seconds
    @State private var validationState: InputValidationState = .valid
    @State private var currentError: ToolError?
    @State private var enhancedError: EnhancedErrorInfo?
    @State private var isProcessing: Bool = false
    @State private var selectedDateFormat: TimeFormat = .iso8601
    @State private var customFormat: String = "yyyy-MM-dd HH:mm:ss"
    @State private var timezoneValidation: TimezoneValidationResult = .valid
    @State private var customFormatValidation: InputValidationState = .valid

    @Environment(ToastManager.self) private var toastManager

    private let timeService = TimeConverterService()
    private let validationService = ValidationService()
    private let validationConfig = RealTimeValidationConfig.default

    var body: some View {
        BrightCardView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("日期时间转时间戳")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Button("当前时间") {
                        loadCurrentDateTime()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.blue)
                }

                // Date Format Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("日期格式")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(TimeFormat.allCases.filter { $0 != .timestamp }) { format in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedDateFormat = format
                                    }
                                }) {
                                    Text(format.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(
                                            selectedDateFormat == format ? .white : .primary
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(
                                                    selectedDateFormat == format
                                                        ? Color.accentColor
                                                        : Color(.controlBackgroundColor)
                                                )
                                                .animation(
                                                    .easeInOut(duration: 0.2),
                                                    value: selectedDateFormat)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(
                                                    selectedDateFormat == format
                                                        ? Color.clear
                                                        : Color(.separatorColor).opacity(0.3),
                                                    lineWidth: 1
                                                )
                                                .animation(
                                                    .easeInOut(duration: 0.2),
                                                    value: selectedDateFormat)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel(format.displayName)
                                .accessibilityHint("选择\(format.displayName)格式")
                                .accessibilityAddTraits(
                                    selectedDateFormat == format
                                        ? [.isSelected, .isButton] : [.isButton])
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("日期格式选择器")
                    .accessibilityValue(selectedDateFormat.displayName)
                }

                // Custom Format Input with Validation (only shown when custom format is selected)
                if selectedDateFormat == .custom {
                    ValidatedTextField(
                        title: "自定义格式",
                        text: $customFormat,
                        placeholder: "例如: yyyy-MM-dd HH:mm:ss",
                        validationState: customFormatValidation,
                        onValidationChange: { newValue in
                            validateCustomFormat(newValue)
                        }
                    )
                    .accessibilityLabel("自定义日期格式输入框")
                    .accessibilityHint("输入自定义的日期时间格式模式")

                    Text("常用格式: yyyy-MM-dd HH:mm:ss, MM/dd/yyyy HH:mm, dd.MM.yyyy HH:mm:ss")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Date Input with Enhanced Validation
                ValidatedTextField(
                    title: "日期时间",
                    text: $dateInput,
                    placeholder: getPlaceholderText(),
                    validationState: validationState,
                    onValidationChange: { newValue in
                        validateInputRealTime(newValue)
                    }
                )
                .accessibilityLabel("日期时间输入框")
                .accessibilityHint("输入要转换的日期时间")

                // Timezone Selection with Validation
                VStack(alignment: .leading, spacing: 8) {
                    Text("源时区")
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

                // Timestamp Unit Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("时间戳单位")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        ForEach(TimestampUnit.allCases) { unit in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    timestampUnit = unit
                                }
                            }) {
                                Text(unit.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(timestampUnit == unit ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                timestampUnit == unit
                                                    ? Color.accentColor
                                                    : Color(.controlBackgroundColor)
                                            )
                                            .animation(
                                                .easeInOut(duration: 0.2), value: timestampUnit)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                timestampUnit == unit
                                                    ? Color.clear
                                                    : Color(.separatorColor).opacity(0.3),
                                                lineWidth: 1
                                            )
                                            .animation(
                                                .easeInOut(duration: 0.2), value: timestampUnit)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel(unit.displayName)
                            .accessibilityHint("选择\(unit.displayName)单位")
                            .accessibilityAddTraits(
                                timestampUnit == unit ? [.isSelected, .isButton] : [.isButton])
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("时间戳单位选择器")
                    .accessibilityValue(timestampUnit.displayName)
                }

                // Convert Button
                HStack {
//                    ToolButton(
//                        title: "转换",
//                        action: performConversion,
//                        style: .primary
//                    )
//                    .disabled(dateInput.isEmpty || !validationState.isValid || isProcessing)
//                    .accessibilityLabel("转换按钮")
//                    .accessibilityHint("将输入的日期转换为时间戳")
//                    .keyboardShortcut(.return, modifiers: [])

                    ToolButton(
                        title: "清空",
                        action: clearInput,
                        style: .secondary
                    )
                    .accessibilityLabel("清空按钮")
                    .accessibilityHint("清空所有输入和结果")

                    Spacer()

                    ProcessingStateView(
                        isProcessing: isProcessing,
                        message: isProcessing ? "转换中..." : "就绪"
                    )
                }

                // Enhanced error display
                if let enhancedError = enhancedError {
                    EnhancedErrorView(
                        errorInfo: enhancedError,
                        onRecoveryAction: handleRecoveryAction
                    )
                }

                // Result Display
                if !convertedTimestamp.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("转换结果")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        ToolResultView(
                            title: "",
                            content: convertedTimestamp,
                            canCopy: true
                        )
                    }
                }
            }
        }
        .errorAlert($currentError)
        .onChange(of: selectedDateFormat) { _, _ in
            validateInputRealTime(dateInput)
        }
        .onChange(of: selectedTimeZone) { _, _ in
            validateInputRealTime(dateInput)
        }
        .onChange(of: timestampUnit) { _, _ in
            if validationState.isValid && !dateInput.isEmpty {
                performRealTimeConversion()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("日期转时间戳转换器")
        .accessibilityHint("输入日期时间转换为Unix时间戳")
        .onReceive(NotificationCenter.default.publisher(for: .dateToTimestampTriggerConversion)) {
            _ in
            if !dateInput.isEmpty && validationState.isValid {
                performConversion()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dateToTimestampTriggerCopy)) { _ in
            if !convertedTimestamp.isEmpty {
                copyResult()
            }
        }
    }

    // MARK: - Private Methods

    private func getPlaceholderText() -> String {
        switch selectedDateFormat {
        case .iso8601:
            return "例如: 2024-01-01T12:00:00Z"
        case .rfc2822:
            return "例如: Mon, 01 Jan 2024 12:00:00 GMT"
        case .custom:
            return "根据自定义格式输入日期"
        case .timestamp:
            return "时间戳"
        }
    }

    private func validateInputRealTime(_ input: String) {
        let context = ValidationContext(
            format: selectedDateFormat,
            customFormat: selectedDateFormat == .custom ? customFormat : nil,
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
            source: selectedTimeZone,
            target: .current
        )

        // Trigger real-time conversion if valid
        if validationState.isValid && !input.isEmpty {
            performRealTimeConversion()
        } else {
            convertedTimestamp = ""
        }
    }

    private func validateCustomFormat(_ format: String) {
        let context = ValidationContext(
            format: .custom,
            customFormat: format,
            timeZone: selectedTimeZone
        )

        customFormatValidation = validationService.validateInput(
            format,
            context: context,
            config: validationConfig
        )

        // Re-validate date input if custom format changed
        if selectedDateFormat == .custom {
            validateInputRealTime(dateInput)
        }
    }

    private func performRealTimeConversion() {
        guard !dateInput.isEmpty && validationState.isValid else {
            convertedTimestamp = ""
            return
        }

        let options = TimeConversionOptions(
            sourceFormat: selectedDateFormat,
            targetFormat: .timestamp,
            sourceTimeZone: selectedTimeZone,
            targetTimeZone: .current,
            customFormat: selectedDateFormat == .custom ? customFormat : "yyyy-MM-dd HH:mm:ss",
            includeMilliseconds: timestampUnit == .milliseconds,
            enableRealTimeConversion: true,
            validateInput: true
        )

        let result = timeService.convertTime(input: dateInput, options: options)

        if result.success {
            convertedTimestamp = result.result
            currentError = nil
            enhancedError = nil
        } else {
            convertedTimestamp = ""
            // Don't show errors during real-time conversion to avoid frequent error messages
        }
    }

    private func performConversion() {
        Task {
            await convertDateTime()
        }
    }

    @MainActor
    private func convertDateTime() async {
        isProcessing = true
        currentError = nil
        enhancedError = nil

        let options = TimeConversionOptions(
            sourceFormat: selectedDateFormat,
            targetFormat: .timestamp,
            sourceTimeZone: selectedTimeZone,
            targetTimeZone: .current,
            customFormat: selectedDateFormat == .custom ? customFormat : "yyyy-MM-dd HH:mm:ss",
            includeMilliseconds: timestampUnit == .milliseconds,
            validateInput: true
        )

        let result = timeService.convertTime(input: dateInput, options: options)

        if result.success {
            convertedTimestamp = result.result

            // Show success toast notification
            toastManager.show(
                "日期转换成功",
                type: .success,
                duration: 2.0
            )
        } else {
            convertedTimestamp = ""

            // Generate enhanced error information
            let context = ValidationContext(
                format: selectedDateFormat,
                customFormat: selectedDateFormat == .custom ? customFormat : nil,
                timeZone: selectedTimeZone
            )

            if let errorMessage = result.error,
                let timeConverterError = parseTimeConverterError(from: errorMessage)
            {
                enhancedError = validationService.generateEnhancedError(
                    from: timeConverterError,
                    context: context,
                    inputValue: dateInput
                )

                // Show error toast notification
                toastManager.show(
                    "日期转换失败: \(errorMessage)",
                    type: .error,
                    duration: 4.0
                )
            } else {
                currentError = ToolError.processingFailed(result.error ?? "日期转换失败")

                // Show generic error toast
                toastManager.show(
                    "日期转换失败，请检查输入格式",
                    type: .error,
                    duration: 3.0
                )
            }
        }

        isProcessing = false
    }

    private func loadCurrentDateTime() {
        let currentTime = timeService.getCurrentTime(
            format: selectedDateFormat,
            timeZone: selectedTimeZone,
            customFormat: selectedDateFormat == .custom ? customFormat : "yyyy-MM-dd HH:mm:ss",
            includeMilliseconds: false
        )
        dateInput = currentTime
    }

    private func clearInput() {
        dateInput = ""
        convertedTimestamp = ""
        selectedTimeZone = .current
        timestampUnit = .seconds
        selectedDateFormat = .iso8601
        customFormat = "yyyy-MM-dd HH:mm:ss"
        validationState = .valid
        customFormatValidation = .valid
        timezoneValidation = .valid
        currentError = nil
        enhancedError = nil
    }

    private func handleRecoveryAction(_ action: RecoveryAction) {
        action.action()
    }

    private func parseTimeConverterError(from message: String) -> TimeConverterError? {
        // Parse error message to determine TimeConverterError type
        if message.contains("Invalid date format") {
            return .invalidDateFormat(dateInput)
        } else if message.contains("custom format") {
            return .customFormatInvalid(customFormat)
        } else if message.contains("timezone") {
            return .timezoneConversionFailed
        } else if message.contains("empty") {
            return .inputEmpty
        } else {
            return .outputGenerationFailed
        }
    }

    private func copyResult() {
        guard !convertedTimestamp.isEmpty else {
            toastManager.show("没有可复制的转换结果", type: .warning, duration: 2.0)
            return
        }

        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.setString(convertedTimestamp, forType: .string)

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
                        .announcement: "转换结果已复制到剪贴板: \(convertedTimestamp)",
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
    DateToTimestampView()
        .padding()
}
