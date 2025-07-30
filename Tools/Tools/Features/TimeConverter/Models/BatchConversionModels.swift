import Foundation

// MARK: - Batch Conversion Item

struct BatchConversionItem: Identifiable, Hashable {
    let id: UUID
    var input: String
    var sourceFormat: TimeFormat
    var targetFormat: TimeFormat
    var sourceTimeZone: TimeZone
    var targetTimeZone: TimeZone
    var customFormat: String
    var includeMilliseconds: Bool

    init(
        input: String,
        sourceFormat: TimeFormat = .timestamp,
        targetFormat: TimeFormat = .iso8601,
        sourceTimeZone: TimeZone = .current,
        targetTimeZone: TimeZone = .current,
        customFormat: String = "yyyy-MM-dd HH:mm:ss",
        includeMilliseconds: Bool = false
    ) {
        self.id = UUID()
        self.input = input
        self.sourceFormat = sourceFormat
        self.targetFormat = targetFormat
        self.sourceTimeZone = sourceTimeZone
        self.targetTimeZone = targetTimeZone
        self.customFormat = customFormat
        self.includeMilliseconds = includeMilliseconds
    }

    // Create from TimeConversionOptions
    init(input: String, options: TimeConversionOptions) {
        self.id = UUID()
        self.input = input
        self.sourceFormat = options.sourceFormat
        self.targetFormat = options.targetFormat
        self.sourceTimeZone = options.sourceTimeZone
        self.targetTimeZone = options.targetTimeZone
        self.customFormat = options.customFormat
        self.includeMilliseconds = options.includeMilliseconds
    }

    // Convert to TimeConversionOptions
    var conversionOptions: TimeConversionOptions {
        TimeConversionOptions(
            sourceFormat: sourceFormat,
            targetFormat: targetFormat,
            sourceTimeZone: sourceTimeZone,
            targetTimeZone: targetTimeZone,
            customFormat: customFormat,
            includeMilliseconds: includeMilliseconds
        )
    }
}

// MARK: - Batch Conversion Result

struct BatchConversionResult: Identifiable, Hashable {
    let id: UUID
    let itemId: UUID
    let input: String
    let output: String?
    let error: String?
    let success: Bool
    let processingTime: TimeInterval
    let timestamp: TimeInterval?
    let date: Date?

    init(
        itemId: UUID,
        input: String,
        output: String? = nil,
        error: String? = nil,
        success: Bool,
        processingTime: TimeInterval = 0,
        timestamp: TimeInterval? = nil,
        date: Date? = nil
    ) {
        self.id = UUID()
        self.itemId = itemId
        self.input = input
        self.output = output
        self.error = error
        self.success = success
        self.processingTime = processingTime
        self.timestamp = timestamp
        self.date = date
    }

    // Create success result
    static func success(
        itemId: UUID,
        input: String,
        output: String,
        processingTime: TimeInterval = 0,
        timestamp: TimeInterval? = nil,
        date: Date? = nil
    ) -> BatchConversionResult {
        BatchConversionResult(
            itemId: itemId,
            input: input,
            output: output,
            success: true,
            processingTime: processingTime,
            timestamp: timestamp,
            date: date
        )
    }

    // Create failure result
    static func failure(
        itemId: UUID,
        input: String,
        error: String,
        processingTime: TimeInterval = 0
    ) -> BatchConversionResult {
        BatchConversionResult(
            itemId: itemId,
            input: input,
            error: error,
            success: false,
            processingTime: processingTime
        )
    }
}

// MARK: - Batch Conversion Summary

struct BatchConversionSummary: Equatable {
    let totalItems: Int
    let successfulItems: Int
    let failedItems: Int
    let totalProcessingTime: TimeInterval
    let averageProcessingTime: TimeInterval
    let errors: [String]

    init(results: [BatchConversionResult]) {
        self.totalItems = results.count
        self.successfulItems = results.filter { $0.success }.count
        self.failedItems = results.filter { !$0.success }.count
        self.totalProcessingTime = results.reduce(0) { $0 + $1.processingTime }
        self.averageProcessingTime = totalItems > 0 ? totalProcessingTime / Double(totalItems) : 0
        self.errors = results.compactMap { $0.error }.filter { !$0.isEmpty }
    }

    var successRate: Double {
        totalItems > 0 ? Double(successfulItems) / Double(totalItems) : 0
    }

    var hasErrors: Bool {
        failedItems > 0
    }
}

// MARK: - Batch Processing State

enum BatchProcessingState: Equatable {
    case idle
    case processing(current: Int, total: Int)
    case completed(summary: BatchConversionSummary)
    case cancelled

    var isProcessing: Bool {
        if case .processing = self {
            return true
        }
        return false
    }

    var progress: Double {
        if case .processing(let current, let total) = self {
            return total > 0 ? Double(current) / Double(total) : 0
        }
        return 0
    }

    static func == (lhs: BatchProcessingState, rhs: BatchProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.cancelled, .cancelled):
            return true
        case (.processing(let lhsCurrent, let lhsTotal), .processing(let rhsCurrent, let rhsTotal)):
            return lhsCurrent == rhsCurrent && lhsTotal == rhsTotal
        case (.completed(let lhsSummary), .completed(let rhsSummary)):
            return lhsSummary == rhsSummary
        default:
            return false
        }
    }
}

// MARK: - Batch Export Format

enum BatchExportFormat: String, CaseIterable, Identifiable {
    case csv = "csv"
    case json = "json"
    case txt = "txt"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .csv:
            return "CSV"
        case .json:
            return "JSON"
        case .txt:
            return "Text"
        }
    }

    var fileExtension: String {
        return rawValue
    }

    var mimeType: String {
        switch self {
        case .csv:
            return "text/csv"
        case .json:
            return "application/json"
        case .txt:
            return "text/plain"
        }
    }
}

// MARK: - Batch Input Validation Result

struct BatchInputValidationResult {
    let validItems: [String]
    let invalidItems: [(input: String, error: String)]
    let totalItems: Int

    init(inputs: [String], validator: (String) -> String?) {
        var valid: [String] = []
        var invalid: [(String, String)] = []

        for input in inputs {
            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue  // Skip empty lines
            }

            if let error = validator(trimmed) {
                invalid.append((trimmed, error))
            } else {
                valid.append(trimmed)
            }
        }

        self.validItems = valid
        self.invalidItems = invalid
        self.totalItems = inputs.count
    }

    var hasValidItems: Bool {
        !validItems.isEmpty
    }

    var hasInvalidItems: Bool {
        !invalidItems.isEmpty
    }

    var validationRate: Double {
        totalItems > 0 ? Double(validItems.count) / Double(totalItems) : 0
    }
}
