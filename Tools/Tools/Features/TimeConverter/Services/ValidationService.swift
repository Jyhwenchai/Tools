//
//  ValidationService.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import Foundation

// MARK: - Enhanced Validation Service

@Observable
class ValidationService {

    // MARK: - Properties

    private let timeService = TimeConverterService()
    private var validationCache: [String: InputValidationState] = [:]
    private let cacheQueue = DispatchQueue(label: "validation.cache", attributes: .concurrent)

    // MARK: - Real-time Input Validation

    func validateInput(
        _ input: String,
        context: ValidationContext,
        config: RealTimeValidationConfig = .default
    ) -> InputValidationState {

        // Check cache first
        let cacheKey =
            "\(input)_\(context.format.rawValue)_\(context.customFormat ?? "")_\(context.timeZone.identifier)"

        if let cached = getCachedValidation(for: cacheKey) {
            return cached
        }

        let result = performValidation(input, context: context, config: config)
        setCachedValidation(result, for: cacheKey)

        return result
    }

    private func performValidation(
        _ input: String,
        context: ValidationContext,
        config: RealTimeValidationConfig
    ) -> InputValidationState {

        // Handle empty input
        if input.isEmpty {
            if context.allowEmpty {
                return .valid
            } else {
                return .invalid(
                    message: "输入不能为空",
                    suggestions: getSuggestionsForFormat(context.format),
                    level: .error
                )
            }
        }

        // Sanitize input
        let sanitizedInput = timeService.sanitizeInput(input)
        if sanitizedInput != input && config.showWarnings {
            return .warning(
                message: "输入包含特殊字符，已自动清理",
                suggestions: ["使用清理后的值: \(sanitizedInput)"]
            )
        }

        // Format-specific validation
        switch context.format {
        case .timestamp:
            return validateTimestamp(sanitizedInput, context: context, config: config)
        case .iso8601:
            return validateISO8601(sanitizedInput, context: context, config: config)
        case .rfc2822:
            return validateRFC2822(sanitizedInput, context: context, config: config)
        case .custom:
            return validateCustomFormat(sanitizedInput, context: context, config: config)
        }
    }

    // MARK: - Format-specific Validation

    private func validateTimestamp(
        _ input: String,
        context: ValidationContext,
        config: RealTimeValidationConfig
    ) -> InputValidationState {

        // Check if it's a valid number
        guard let timestamp = Double(input) else {
            return .invalid(
                message: "时间戳必须是数字",
                suggestions: [
                    "输入整数时间戳，如: 1640995200",
                    "输入毫秒时间戳，如: 1640995200000",
                    "使用当前时间戳按钮获取示例",
                ],
                level: .error
            )
        }

        // Check for reasonable range
        let adjustedTimestamp = timestamp > 1_000_000_000_000 ? timestamp / 1000 : timestamp

        if adjustedTimestamp < 0 {
            return .invalid(
                message: "时间戳不能为负数",
                suggestions: ["输入正数时间戳"],
                level: .error
            )
        }

        if adjustedTimestamp > 4_102_444_800 {  // Year 2100
            return .invalid(
                message: "时间戳超出合理范围（2100年后）",
                suggestions: [
                    "检查是否为毫秒时间戳",
                    "确认时间戳格式正确",
                ],
                level: .error
            )
        }

        // Check for potential millisecond timestamp
        if timestamp > 1_000_000_000_000 && config.showWarnings {
            return .warning(
                message: "检测到毫秒时间戳",
                suggestions: ["确认时间戳单位是否正确"]
            )
        }

        // Check for very old timestamps
        if adjustedTimestamp < 946_684_800 && config.showWarnings {  // Year 2000
            return .warning(
                message: "时间戳对应2000年之前的日期",
                suggestions: ["确认时间戳是否正确"]
            )
        }

        return .valid
    }

    private func validateISO8601(
        _ input: String,
        context: ValidationContext,
        config: RealTimeValidationConfig
    ) -> InputValidationState {

        // Basic format check
        if !input.contains("T") && !input.contains(" ") {
            return .invalid(
                message: "ISO 8601格式需要包含日期和时间分隔符",
                suggestions: [
                    "使用T分隔日期和时间: 2024-01-01T12:00:00Z",
                    "或使用空格: 2024-01-01 12:00:00",
                ],
                level: .error
            )
        }

        // Check for timezone indicator
        if !input.hasSuffix("Z") && !input.contains("+")
            && !input.suffix(from: input.index(input.startIndex, offsetBy: min(10, input.count)))
                .contains("-")
        {
            if config.showWarnings {
                return .warning(
                    message: "缺少时区信息",
                    suggestions: [
                        "添加Z表示UTC时间: \(input)Z",
                        "添加时区偏移: \(input)+08:00",
                    ]
                )
            }
        }

        // Try to parse
        if !timeService.validateDateString(input, format: .iso8601) {
            return .invalid(
                message: "ISO 8601格式无效",
                suggestions: [
                    "标准格式: 2024-01-01T12:00:00Z",
                    "带毫秒: 2024-01-01T12:00:00.000Z",
                    "带时区: 2024-01-01T12:00:00+08:00",
                ],
                level: .error
            )
        }

        return .valid
    }

    private func validateRFC2822(
        _ input: String,
        context: ValidationContext,
        config: RealTimeValidationConfig
    ) -> InputValidationState {

        // Basic format check
        let components = input.components(separatedBy: " ")
        if components.count < 6 {
            return .invalid(
                message: "RFC 2822格式组件不完整",
                suggestions: [
                    "标准格式: Mon, 01 Jan 2024 12:00:00 GMT",
                    "包含: 星期, 日期, 月份, 年份, 时间, 时区",
                ],
                level: .error
            )
        }

        // Check for day name
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        if !dayNames.contains(components[0].replacingOccurrences(of: ",", with: "")) {
            return .invalid(
                message: "无效的星期名称",
                suggestions: dayNames.map { "使用 \($0)" },
                level: .error
            )
        }

        // Try to parse
        if !timeService.validateDateString(input, format: .rfc2822) {
            return .invalid(
                message: "RFC 2822格式无效",
                suggestions: [
                    "标准格式: Mon, 01 Jan 2024 12:00:00 GMT",
                    "检查日期组件是否有效",
                    "确认时区缩写正确",
                ],
                level: .error
            )
        }

        return .valid
    }

    private func validateCustomFormat(
        _ input: String,
        context: ValidationContext,
        config: RealTimeValidationConfig
    ) -> InputValidationState {

        guard let customFormat = context.customFormat, !customFormat.isEmpty else {
            return .invalid(
                message: "自定义格式不能为空",
                suggestions: [
                    "使用 yyyy-MM-dd HH:mm:ss",
                    "使用 MM/dd/yyyy HH:mm",
                    "使用 dd.MM.yyyy HH:mm:ss",
                ],
                level: .error
            )
        }

        // Validate format pattern
        let validationResult = validateFormatPattern(customFormat)
        if !validationResult.isValid {
            return .invalid(
                message: "自定义格式模式无效: \(validationResult.errorMessage ?? "")",
                suggestions: validationResult.suggestions,
                level: .error
            )
        }

        // Try to parse with custom format
        if !timeService.validateDateString(input, format: .custom, customFormat: customFormat) {
            return .invalid(
                message: "输入不匹配自定义格式 '\(customFormat)'",
                suggestions: [
                    "检查日期组件顺序",
                    "确认分隔符正确",
                    "验证日期值有效性",
                ],
                level: .error
            )
        }

        return .valid
    }

    // MARK: - Timezone Validation

    func validateTimezoneCompatibility(
        source: TimeZone,
        target: TimeZone,
        for date: Date = Date()
    ) -> TimezoneValidationResult {

        var issues: [String] = []
        var recommendations: [String] = []

        // Check if timezones are available
        let sourceValid = timeService.isTimezoneAvailable(source)
        let targetValid = timeService.isTimezoneAvailable(target)

        if !sourceValid {
            issues.append("源时区 '\(source.identifier)' 不可用")
        }

        if !targetValid {
            issues.append("目标时区 '\(target.identifier)' 不可用")
        }

        // Check compatibility
        if sourceValid && targetValid {
            if !timeService.validateTimezoneCompatibility(source: source, target: target, for: date)
            {
                issues.append("时区转换可能不准确")
                recommendations.append("检查历史日期的时区数据")
            }
        }

        // Check for same timezone
        if source.identifier == target.identifier {
            recommendations.append("源时区和目标时区相同，无需转换")
        }

        // Check for common timezone issues
        if source.identifier.contains("GMT") && target.identifier.contains("GMT") {
            recommendations.append("建议使用具体地区时区而非GMT偏移")
        }

        return TimezoneValidationResult(
            isValid: issues.isEmpty,
            sourceTimezoneValid: sourceValid,
            targetTimezoneValid: targetValid,
            compatibilityIssues: issues,
            recommendations: recommendations
        )
    }

    // MARK: - Enhanced Error Generation

    func generateEnhancedError(
        from error: TimeConverterError,
        context: ValidationContext?,
        inputValue: String
    ) -> EnhancedErrorInfo {

        let suggestions = generateSuggestions(for: error, context: context, inputValue: inputValue)
        let recoveryActions = generateRecoveryActions(for: error, context: context)
        let relatedErrors = findRelatedErrors(for: error)

        return EnhancedErrorInfo(
            originalError: error,
            context: context,
            inputValue: inputValue,
            suggestions: suggestions,
            recoveryActions: recoveryActions,
            relatedErrors: relatedErrors
        )
    }

    private func generateSuggestions(
        for error: TimeConverterError,
        context: ValidationContext?,
        inputValue: String
    ) -> [String] {

        switch error {
        case .invalidTimestamp:
            return [
                "输入有效的Unix时间戳（如：1640995200）",
                "使用当前时间戳按钮获取示例",
                "检查是否为毫秒时间戳（需要除以1000）",
            ]

        case .invalidDateFormat:
            guard let context = context else { return [] }
            return getSuggestionsForFormat(context.format)

        case .timezoneConversionFailed:
            return [
                "选择有效的源时区和目标时区",
                "检查日期是否在时区数据范围内",
                "尝试使用UTC作为中间时区",
            ]

        case .customFormatInvalid:
            return [
                "使用标准格式模式：yyyy-MM-dd HH:mm:ss",
                "检查格式字符是否正确",
                "参考Java SimpleDateFormat文档",
            ]

        default:
            return []
        }
    }

    private func generateRecoveryActions(
        for error: TimeConverterError,
        context: ValidationContext?
    ) -> [RecoveryAction] {

        var actions: [RecoveryAction] = []

        switch error {
        case .invalidTimestamp:
            actions.append(
                RecoveryAction(
                    title: "使用当前时间戳",
                    description: "填入当前Unix时间戳"
                ) {
                    // This would be implemented by the view
                })

        case .customFormatInvalid:
            actions.append(
                RecoveryAction(
                    title: "使用标准格式",
                    description: "重置为ISO 8601格式"
                ) {
                    // This would be implemented by the view
                })

        default:
            break
        }

        return actions
    }

    private func findRelatedErrors(for error: TimeConverterError) -> [TimeConverterError] {
        // Return related errors that might help user understand the issue
        switch error {
        case .invalidTimestamp:
            return [.invalidDateFormat(""), .customFormatInvalid("")]
        case .timezoneConversionFailed:
            return [.timezoneDataUnavailable("")]
        default:
            return []
        }
    }

    // MARK: - Helper Methods

    private func getSuggestionsForFormat(_ format: TimeFormat) -> [String] {
        switch format {
        case .timestamp:
            return [
                "输入Unix时间戳：1640995200",
                "毫秒时间戳：1640995200000",
                "使用当前时间戳按钮",
            ]
        case .iso8601:
            return [
                "标准格式：2024-01-01T12:00:00Z",
                "带毫秒：2024-01-01T12:00:00.000Z",
                "带时区：2024-01-01T12:00:00+08:00",
            ]
        case .rfc2822:
            return [
                "标准格式：Mon, 01 Jan 2024 12:00:00 GMT",
                "包含星期名称和时区",
            ]
        case .custom:
            return [
                "yyyy-MM-dd HH:mm:ss",
                "MM/dd/yyyy HH:mm",
                "dd.MM.yyyy HH:mm:ss",
            ]
        }
    }

    private func validateFormatPattern(_ pattern: String) -> InputValidationState {
        // Basic validation of date format pattern
        let validPatterns = ["y", "M", "d", "H", "h", "m", "s", "S", "a", "z", "Z"]
        let invalidChars = pattern.filter { char in
            !validPatterns.contains(String(char)) && !"-/.,:; ".contains(char)
        }

        if !invalidChars.isEmpty {
            return .invalid(
                message: "包含无效字符: \(String(invalidChars))",
                suggestions: [
                    "使用有效的格式字符：y(年) M(月) d(日) H(时) m(分) s(秒)",
                    "分隔符可以使用：- / . : 空格",
                ]
            )
        }

        return .valid
    }

    // MARK: - Cache Management

    private func getCachedValidation(for key: String) -> InputValidationState? {
        return cacheQueue.sync {
            validationCache[key]
        }
    }

    private func setCachedValidation(_ state: InputValidationState, for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.validationCache[key] = state

            // Limit cache size
            if self.validationCache.count > 100 {
                let keysToRemove = Array(self.validationCache.keys.prefix(20))
                keysToRemove.forEach { self.validationCache.removeValue(forKey: $0) }
            }
        }
    }

    func clearValidationCache() {
        cacheQueue.async(flags: .barrier) {
            self.validationCache.removeAll()
        }
    }
}
