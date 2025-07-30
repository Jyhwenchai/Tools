import Foundation

// MARK: - Batch Conversion Service

@Observable
class BatchConversionService {
    // MARK: - Properties

    private let timeConverterService: TimeConverterService
    private var processingTask: Task<Void, Never>?

    var processingState: BatchProcessingState = .idle
    var lastResults: [BatchConversionResult] = []
    var lastSummary: BatchConversionSummary?

    // MARK: - Configuration

    private let maxBatchSize = 1000
    private let processingDelay: TimeInterval = 0.001  // Small delay to allow UI updates

    // MARK: - Initialization

    init(timeConverterService: TimeConverterService = TimeConverterService()) {
        self.timeConverterService = timeConverterService
    }

    // MARK: - Main Batch Processing

    func processBatchConversion(items: [BatchConversionItem]) async -> [BatchConversionResult] {
        guard !items.isEmpty else {
            processingState = .completed(summary: BatchConversionSummary(results: []))
            return []
        }

        // Limit batch size for performance
        let limitedItems = Array(items.prefix(maxBatchSize))

        processingState = .processing(current: 0, total: limitedItems.count)

        var results: [BatchConversionResult] = []

        for (index, item) in limitedItems.enumerated() {
            // Check for cancellation
            if Task.isCancelled {
                processingState = .cancelled
                return results
            }

            let startTime = CFAbsoluteTimeGetCurrent()
            let result = await processItem(item)
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime

            // Update result with processing time
            let timedResult = BatchConversionResult(
                itemId: result.itemId,
                input: result.input,
                output: result.output,
                error: result.error,
                success: result.success,
                processingTime: processingTime,
                timestamp: result.timestamp,
                date: result.date
            )

            results.append(timedResult)

            // Update progress
            processingState = .processing(current: index + 1, total: limitedItems.count)

            // Small delay to allow UI updates
            if processingDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
            }
        }

        lastResults = results
        let summary = BatchConversionSummary(results: results)
        lastSummary = summary
        processingState = .completed(summary: summary)

        return results
    }

    // MARK: - Async Batch Processing with Cancellation

    func startBatchProcessing(items: [BatchConversionItem]) {
        cancelProcessing()

        processingTask = Task {
            _ = await processBatchConversion(items: items)
        }
    }

    func cancelProcessing() {
        processingTask?.cancel()
        processingTask = nil
        if processingState.isProcessing {
            processingState = .cancelled
        }
    }

    // MARK: - Input Validation

    func validateBatchInput(_ input: String, format: TimeFormat, customFormat: String = "")
        -> [String]
    {
        let lines = input.components(separatedBy: .newlines)
        return lines.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    func validateBatchItems(_ inputs: [String], format: TimeFormat, customFormat: String = "")
        -> BatchInputValidationResult
    {
        let validator: (String) -> String? = { input in
            switch format {
            case .timestamp:
                return self.timeConverterService.validateTimestamp(input)
                    ? nil : "Invalid timestamp format"
            case .iso8601, .rfc2822:
                return self.timeConverterService.validateDateString(
                    input, format: format, customFormat: nil)
                    ? nil : "Invalid \(format.displayName) format"
            case .custom:
                return self.timeConverterService.validateDateString(
                    input, format: format, customFormat: customFormat)
                    ? nil : "Invalid custom format"
            }
        }

        return BatchInputValidationResult(inputs: inputs, validator: validator)
    }

    // MARK: - Export Functionality

    func exportResults(_ results: [BatchConversionResult], format: BatchExportFormat) -> String {
        switch format {
        case .csv:
            return exportToCSV(results)
        case .json:
            return exportToJSON(results)
        case .txt:
            return exportToText(results)
        }
    }

    // MARK: - Performance Analysis

    func analyzePerformance(results: [BatchConversionResult]) -> BatchPerformanceAnalysis {
        BatchPerformanceAnalysis(results: results)
    }

    // MARK: - Private Methods

    private func processItem(_ item: BatchConversionItem) async -> BatchConversionResult {
        let conversionResult = timeConverterService.convertTime(
            input: item.input,
            options: item.conversionOptions
        )

        if conversionResult.success {
            return .success(
                itemId: item.id,
                input: item.input,
                output: conversionResult.result,
                timestamp: conversionResult.timestamp,
                date: conversionResult.date
            )
        } else {
            return .failure(
                itemId: item.id,
                input: item.input,
                error: conversionResult.error ?? "Unknown error"
            )
        }
    }

    private func exportToCSV(_ results: [BatchConversionResult]) -> String {
        var csv = "Input,Output,Success,Error,Processing Time (ms)\n"

        for result in results {
            let input = escapeCSVField(result.input)
            let output = escapeCSVField(result.output ?? "")
            let success = result.success ? "true" : "false"
            let error = escapeCSVField(result.error ?? "")
            let processingTime = String(format: "%.3f", result.processingTime * 1000)

            csv += "\(input),\(output),\(success),\(error),\(processingTime)\n"
        }

        return csv
    }

    private func exportToJSON(_ results: [BatchConversionResult]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let exportData = results.map { result in
            [
                "id": result.id.uuidString,
                "itemId": result.itemId.uuidString,
                "input": result.input,
                "output": result.output ?? NSNull(),
                "error": result.error ?? NSNull(),
                "success": result.success,
                "processingTime": result.processingTime,
                "timestamp": result.timestamp ?? NSNull(),
                "date": result.date?.iso8601String ?? NSNull(),
            ] as [String: Any]
        }

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    private func exportToText(_ results: [BatchConversionResult]) -> String {
        var text = "Batch Conversion Results\n"
        text += "========================\n\n"

        for (index, result) in results.enumerated() {
            text += "Item \(index + 1):\n"
            text += "  Input: \(result.input)\n"

            if result.success {
                text += "  Output: \(result.output ?? "N/A")\n"
                text += "  Status: Success\n"
            } else {
                text += "  Error: \(result.error ?? "Unknown error")\n"
                text += "  Status: Failed\n"
            }

            text +=
                "  Processing Time: \(String(format: "%.3f", result.processingTime * 1000)) ms\n"
            text += "\n"
        }

        // Add summary
        let summary = BatchConversionSummary(results: results)
        text += "Summary:\n"
        text += "========\n"
        text += "Total Items: \(summary.totalItems)\n"
        text += "Successful: \(summary.successfulItems)\n"
        text += "Failed: \(summary.failedItems)\n"
        text += "Success Rate: \(String(format: "%.1f", summary.successRate * 100))%\n"
        text +=
            "Total Processing Time: \(String(format: "%.3f", summary.totalProcessingTime * 1000)) ms\n"
        text +=
            "Average Processing Time: \(String(format: "%.3f", summary.averageProcessingTime * 1000)) ms\n"

        return text
    }

    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}

// MARK: - Batch Performance Analysis

struct BatchPerformanceAnalysis {
    let totalItems: Int
    let averageProcessingTime: TimeInterval
    let minProcessingTime: TimeInterval
    let maxProcessingTime: TimeInterval
    let standardDeviation: TimeInterval
    let itemsPerSecond: Double

    init(results: [BatchConversionResult]) {
        self.totalItems = results.count

        let processingTimes = results.map { $0.processingTime }

        if !processingTimes.isEmpty {
            let avgTime = processingTimes.reduce(0, +) / Double(processingTimes.count)
            self.averageProcessingTime = avgTime
            self.minProcessingTime = processingTimes.min() ?? 0
            self.maxProcessingTime = processingTimes.max() ?? 0

            // Calculate standard deviation
            let variance =
                processingTimes.reduce(0) { sum, time in
                    let diff = time - avgTime
                    return sum + (diff * diff)
                } / Double(processingTimes.count)
            self.standardDeviation = sqrt(variance)

            self.itemsPerSecond = avgTime > 0 ? 1.0 / avgTime : 0
        } else {
            self.averageProcessingTime = 0
            self.minProcessingTime = 0
            self.maxProcessingTime = 0
            self.standardDeviation = 0
            self.itemsPerSecond = 0
        }
    }
}

// MARK: - Date Extension for ISO8601

extension Date {
    fileprivate var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
