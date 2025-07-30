//
//  ValidationFeedbackView.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI

// MARK: - Validation Feedback View

struct ValidationFeedbackView: View {
    let validationState: InputValidationState
    let showSuggestions: Bool
    @State private var isExpanded = false

    init(
        validationState: InputValidationState,
        showSuggestions: Bool = true
    ) {
        self.validationState = validationState
        self.showSuggestions = showSuggestions
    }

    var body: some View {
        if !validationState.isValid || validationState.warningMessage != nil {
            VStack(alignment: .leading, spacing: 8) {
                // Main validation message
                HStack(spacing: 6) {
                    Image(systemName: validationState.validationLevel.systemImage)
                        .foregroundStyle(colorForLevel(validationState.validationLevel))
                        .font(.caption)

                    Text(validationState.errorMessage ?? validationState.warningMessage ?? "")
                        .font(.caption)
                        .foregroundStyle(colorForLevel(validationState.validationLevel))

                    Spacer()

                    // Expand/collapse button for suggestions
                    if showSuggestions && !validationState.suggestions.isEmpty {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(isExpanded ? "隐藏建议" : "显示建议")
                    }
                }

                // Suggestions (expandable)
                if showSuggestions && isExpanded && !validationState.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("建议:")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        ForEach(Array(validationState.suggestions.enumerated()), id: \.offset) {
                            _, suggestion in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(suggestion)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .padding(.leading, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                backgroundColorForLevel(validationState.validationLevel)
                    .opacity(0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        colorForLevel(validationState.validationLevel).opacity(0.3),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("验证反馈")
            .accessibilityValue(
                validationState.errorMessage ?? validationState.warningMessage ?? "")
        }
    }

    private func colorForLevel(_ level: ValidationLevel) -> Color {
        switch level {
        case .none:
            return .green
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        }
    }

    private func backgroundColorForLevel(_ level: ValidationLevel) -> Color {
        colorForLevel(level)
    }
}

// MARK: - Enhanced Input Field with Validation

struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let validationState: InputValidationState
    let onValidationChange: ((String) -> Void)?

    @State private var isFocused = false
    @FocusState private var textFieldFocused: Bool

    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        validationState: InputValidationState = .valid,
        onValidationChange: ((String) -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.validationState = validationState
        self.onValidationChange = onValidationChange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            // Text field with validation styling
            TextField(placeholder, text: $text)
                .textFieldStyle(
                    ValidatedTextFieldStyle(
                        validationState: validationState,
                        isFocused: textFieldFocused
                    )
                )
                .focused($textFieldFocused)
                .onChange(of: text) { _, newValue in
                    onValidationChange?(newValue)
                }
                .accessibilityLabel(title.isEmpty ? "输入框" : title)
                .accessibilityHint(placeholder)
                .accessibilityValue(validationState.isValid ? "有效输入" : "无效输入")

            // Validation feedback
            ValidationFeedbackView(validationState: validationState)
        }
    }
}

// MARK: - Validated Text Field Style

struct ValidatedTextFieldStyle: TextFieldStyle {
    let validationState: InputValidationState
    let isFocused: Bool

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: isFocused ? 3 : 1,
                x: 0,
                y: 1
            )
    }

    private var borderColor: Color {
        if isFocused {
            return .blue
        } else if !validationState.isValid {
            return .red
        } else if validationState.warningMessage != nil {
            return .orange
        } else {
            return Color(.separatorColor)
        }
    }

    private var borderWidth: CGFloat {
        if isFocused || !validationState.isValid {
            return 2
        } else {
            return 1
        }
    }

    private var shadowColor: Color {
        if !validationState.isValid {
            return .red.opacity(0.2)
        } else if validationState.warningMessage != nil {
            return .orange.opacity(0.2)
        } else if isFocused {
            return .blue.opacity(0.2)
        } else {
            return .black.opacity(0.03)
        }
    }
}

// MARK: - Enhanced Error Display

struct EnhancedErrorView: View {
    let errorInfo: EnhancedErrorInfo
    let onRecoveryAction: ((RecoveryAction) -> Void)?
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main error message
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(errorInfo.originalError.localizedDescription)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let recoverySuggestion = errorInfo.originalError.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDetails.toggle()
                    }
                }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            // Detailed information (expandable)
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    // Input context
                    if !errorInfo.inputValue.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("输入值:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Text(errorInfo.inputValue)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .padding(6)
                                .background(Color(.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    // Suggestions
                    if !errorInfo.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("建议:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            ForEach(Array(errorInfo.suggestions.enumerated()), id: \.offset) {
                                _, suggestion in
                                HStack(alignment: .top, spacing: 4) {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    // Recovery actions
                    if !errorInfo.recoveryActions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("恢复操作:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            ForEach(Array(errorInfo.recoveryActions.enumerated()), id: \.offset) {
                                _, action in
                                Button(action: {
                                    onRecoveryAction?(action)
                                }) {
                                    HStack {
                                        Text(action.title)
                                            .font(.caption)

                                        Spacer()

                                        Text(action.description)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ValidationFeedbackView(
            validationState: .invalid(
                message: "时间戳格式无效",
                suggestions: [
                    "输入有效的Unix时间戳",
                    "使用当前时间戳按钮",
                    "检查是否为毫秒时间戳",
                ]
            )
        )

        ValidationFeedbackView(
            validationState: .warning(
                message: "检测到毫秒时间戳",
                suggestions: ["确认时间戳单位是否正确"]
            )
        )

        // Removed ValidatedTextField from preview to avoid @Previewable issue
    }
    .padding()
}
