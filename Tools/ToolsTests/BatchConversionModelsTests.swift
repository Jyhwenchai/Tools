import XCTest

@testable import Tools

final class BatchConversionModelsTests: XCTestCase {

    // MARK: - BatchConversionItem Tests

    func testBatchConversionItemInitialization() {
        let item = BatchConversionItem(
            input: "1640995200",
            sourceFormat: .timestamp,
            targetFormat: .iso8601,
            sourceTimeZone: .current,
            targetTimeZone: TimeZone(identifier: "UTC")!,
            customFormat: "yyyy-MM-dd",
            includeMilliseconds: true
        )

        XCTAssertEqual(item.input, "1640995200")
        XCTAssertEqual(item.sourceFormat, .timestamp)
        XCTAssertEqual(item.targetFormat, .iso8601)
        XCTAssertEqual(item.sourceTimeZone, .current)
        XCTAssertEqual(item.targetTimeZone, TimeZone(identifier: "UTC")!)
        XCTAssertEqual(item.customFormat, "yyyy-MM-dd")
        XCTAssertTrue(item.includeMilliseconds)
        XCTAssertNotNil(item.id)
    }

    func testBatchConversionItemDefaultValues() {
        let item = BatchConversionItem(input: "test")

        XCTAssertEqual(item.input, "test")
        XCTAssertEqual(item.sourceFormat, .timestamp)
        XCTAssertEqual(item.targetFormat, .iso8601)
        XCTAssertEqual(item.sourceTimeZone, .current)
        XCTAssertEqual(item.targetTimeZone, .current)
        XCTAssertEqual(item.customFormat, "yyyy-MM-dd HH:mm:ss")
        XCTAssertFalse(item.includeMilliseconds)
    }

    func testBatchConversionItemFromOptions() {
        let options = TimeConversionOptions(
            sourceFormat: .iso8601,
            targetFormat: .rfc2822,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "America/New_York")!,
            customFormat: "dd/MM/yyyy",
            includeMilliseconds: true
        )

        let item = BatchConversionItem(input: "test_input", options: options)

        XCTAssertEqual(item.input, "test_input")
        XCTAssertEqual(item.sourceFormat, .iso8601)
        XCTAssertEqual(item.targetFormat, .rfc2822)
        XCTAssertEqual(item.sourceTimeZone, TimeZone(identifier: "UTC")!)
        XCTAssertEqual(item.targetTimeZone, TimeZone(identifier: "America/New_York")!)
        XCTAssertEqual(item.customFormat, "dd/MM/yyyy")
        XCTAssertTrue(item.includeMilliseconds)
    }

    func testBatchConversionItemConversionOptions() {
        let item = BatchConversionItem(
            input: "test",
            sourceFormat: .custom,
            targetFormat: .timestamp,
            sourceTimeZone: TimeZone(identifier: "UTC")!,
            targetTimeZone: TimeZone(identifier: "Asia/Tokyo")!,
            customFormat: "MM/dd/yyyy",
            includeMilliseconds: false
        )

        let options = item.conversionOptions

        XCTAssertEqual(options.sourceFormat, .custom)
        XCTAssertEqual(options.targetFormat, .timestamp)
        XCTAssertEqual(options.sourceTimeZone, TimeZone(identifier: "UTC")!)
        XCTAssertEqual(options.targetTimeZone, TimeZone(identifier: "Asia/Tokyo")!)
        XCTAssertEqual(options.customFormat, "MM/dd/yyyy")
        XCTAssertFalse(options.includeMilliseconds)
    }

    func testBatchConversionItemHashable() {
        let item1 = BatchConversionItem(input: "test")
        let item2 = BatchConversionItem(input: "test")

        // Different items should have different IDs and thus different hashes
        XCTAssertNotEqual(item1.id, item2.id)
        XCTAssertNotEqual(item1.hashValue, item2.hashValue)

        // Same item should be equal to itself
        XCTAssertEqual(item1, item1)
    }

    // MARK: - BatchConversionResult Tests

    func testBatchConversionResultInitialization() {
        let itemId = UUID()
        let result = BatchConversionResult(
            itemId: itemId,
            input: "1640995200",
            output: "2022-01-01T00:00:00Z",
            error: nil,
            success: true,
            processingTime: 0.001,
            timestamp: 1_640_995_200,
            date: Date(timeIntervalSince1970: 1_640_995_200)
        )

        XCTAssertEqual(result.itemId, itemId)
        XCTAssertEqual(result.input, "1640995200")
        XCTAssertEqual(result.output, "2022-01-01T00:00:00Z")
        XCTAssertNil(result.error)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.processingTime, 0.001)
        XCTAssertEqual(result.timestamp, 1_640_995_200)
        XCTAssertNotNil(result.date)
        XCTAssertNotNil(result.id)
    }

    func testBatchConversionResultSuccess() {
        let itemId = UUID()
        let result = BatchConversionResult.success(
            itemId: itemId,
            input: "test_input",
            output: "test_output",
            processingTime: 0.002,
            timestamp: 1_640_995_200,
            date: Date()
        )

        XCTAssertEqual(result.itemId, itemId)
        XCTAssertEqual(result.input, "test_input")
        XCTAssertEqual(result.output, "test_output")
        XCTAssertNil(result.error)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.processingTime, 0.002)
        XCTAssertEqual(result.timestamp, 1_640_995_200)
        XCTAssertNotNil(result.date)
    }

    func testBatchConversionResultFailure() {
        let itemId = UUID()
        let result = BatchConversionResult.failure(
            itemId: itemId,
            input: "invalid_input",
            error: "Invalid format",
            processingTime: 0.001
        )

        XCTAssertEqual(result.itemId, itemId)
        XCTAssertEqual(result.input, "invalid_input")
        XCTAssertNil(result.output)
        XCTAssertEqual(result.error, "Invalid format")
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.processingTime, 0.001)
        XCTAssertNil(result.timestamp)
        XCTAssertNil(result.date)
    }

    func testBatchConversionResultHashable() {
        let itemId = UUID()
        let result1 = BatchConversionResult.success(itemId: itemId, input: "test", output: "output")
        let result2 = BatchConversionResult.success(itemId: itemId, input: "test", output: "output")

        // Different results should have different IDs
        XCTAssertNotEqual(result1.id, result2.id)
        XCTAssertNotEqual(result1.hashValue, result2.hashValue)

        // Same result should be equal to itself
        XCTAssertEqual(result1, result1)
    }

    // MARK: - BatchConversionSummary Tests

    func testBatchConversionSummaryAllSuccess() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(), input: "1", output: "output1", processingTime: 0.001),
            BatchConversionResult.success(
                itemId: UUID(), input: "2", output: "output2", processingTime: 0.002),
            BatchConversionResult.success(
                itemId: UUID(), input: "3", output: "output3", processingTime: 0.003),
        ]

        let summary = BatchConversionSummary(results: results)

        XCTAssertEqual(summary.totalItems, 3)
        XCTAssertEqual(summary.successfulItems, 3)
        XCTAssertEqual(summary.failedItems, 0)
        XCTAssertEqual(summary.successRate, 1.0)
        XCTAssertFalse(summary.hasErrors)
        XCTAssertTrue(summary.errors.isEmpty)
        XCTAssertEqual(summary.totalProcessingTime, 0.006)
        XCTAssertEqual(summary.averageProcessingTime, 0.002)
    }

    func testBatchConversionSummaryAllFailure() {
        let results = [
            BatchConversionResult.failure(
                itemId: UUID(), input: "1", error: "Error 1", processingTime: 0.001),
            BatchConversionResult.failure(
                itemId: UUID(), input: "2", error: "Error 2", processingTime: 0.002),
            BatchConversionResult.failure(
                itemId: UUID(), input: "3", error: "Error 3", processingTime: 0.003),
        ]

        let summary = BatchConversionSummary(results: results)

        XCTAssertEqual(summary.totalItems, 3)
        XCTAssertEqual(summary.successfulItems, 0)
        XCTAssertEqual(summary.failedItems, 3)
        XCTAssertEqual(summary.successRate, 0.0)
        XCTAssertTrue(summary.hasErrors)
        XCTAssertEqual(summary.errors.count, 3)
        XCTAssertTrue(summary.errors.contains("Error 1"))
        XCTAssertTrue(summary.errors.contains("Error 2"))
        XCTAssertTrue(summary.errors.contains("Error 3"))
    }

    func testBatchConversionSummaryMixed() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(), input: "1", output: "output1", processingTime: 0.001),
            BatchConversionResult.failure(
                itemId: UUID(), input: "2", error: "Error 2", processingTime: 0.002),
            BatchConversionResult.success(
                itemId: UUID(), input: "3", output: "output3", processingTime: 0.003),
            BatchConversionResult.failure(
                itemId: UUID(), input: "4", error: "Error 4", processingTime: 0.004),
        ]

        let summary = BatchConversionSummary(results: results)

        XCTAssertEqual(summary.totalItems, 4)
        XCTAssertEqual(summary.successfulItems, 2)
        XCTAssertEqual(summary.failedItems, 2)
        XCTAssertEqual(summary.successRate, 0.5)
        XCTAssertTrue(summary.hasErrors)
        XCTAssertEqual(summary.errors.count, 2)
        XCTAssertEqual(summary.totalProcessingTime, 0.010)
        XCTAssertEqual(summary.averageProcessingTime, 0.0025)
    }

    func testBatchConversionSummaryEmpty() {
        let summary = BatchConversionSummary(results: [])

        XCTAssertEqual(summary.totalItems, 0)
        XCTAssertEqual(summary.successfulItems, 0)
        XCTAssertEqual(summary.failedItems, 0)
        XCTAssertEqual(summary.successRate, 0.0)
        XCTAssertFalse(summary.hasErrors)
        XCTAssertTrue(summary.errors.isEmpty)
        XCTAssertEqual(summary.totalProcessingTime, 0.0)
        XCTAssertEqual(summary.averageProcessingTime, 0.0)
    }

    // MARK: - BatchProcessingState Tests

    func testBatchProcessingStateIdle() {
        let state = BatchProcessingState.idle

        XCTAssertFalse(state.isProcessing)
        XCTAssertEqual(state.progress, 0.0)
    }

    func testBatchProcessingStateProcessing() {
        let state = BatchProcessingState.processing(current: 3, total: 10)

        XCTAssertTrue(state.isProcessing)
        XCTAssertEqual(state.progress, 0.3)
    }

    func testBatchProcessingStateProcessingZeroTotal() {
        let state = BatchProcessingState.processing(current: 5, total: 0)

        XCTAssertTrue(state.isProcessing)
        XCTAssertEqual(state.progress, 0.0)
    }

    func testBatchProcessingStateCompleted() {
        let results = [
            BatchConversionResult.success(itemId: UUID(), input: "test", output: "output")
        ]
        let summary = BatchConversionSummary(results: results)
        let state = BatchProcessingState.completed(summary: summary)

        XCTAssertFalse(state.isProcessing)
        XCTAssertEqual(state.progress, 0.0)
    }

    func testBatchProcessingStateCancelled() {
        let state = BatchProcessingState.cancelled

        XCTAssertFalse(state.isProcessing)
        XCTAssertEqual(state.progress, 0.0)
    }

    func testBatchProcessingStateEquality() {
        XCTAssertEqual(BatchProcessingState.idle, BatchProcessingState.idle)
        XCTAssertEqual(BatchProcessingState.cancelled, BatchProcessingState.cancelled)
        XCTAssertEqual(
            BatchProcessingState.processing(current: 5, total: 10),
            BatchProcessingState.processing(current: 5, total: 10)
        )

        XCTAssertNotEqual(BatchProcessingState.idle, BatchProcessingState.cancelled)
        XCTAssertNotEqual(
            BatchProcessingState.processing(current: 5, total: 10),
            BatchProcessingState.processing(current: 3, total: 10)
        )
    }

    // MARK: - BatchExportFormat Tests

    func testBatchExportFormatProperties() {
        XCTAssertEqual(BatchExportFormat.csv.displayName, "CSV")
        XCTAssertEqual(BatchExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(BatchExportFormat.csv.mimeType, "text/csv")

        XCTAssertEqual(BatchExportFormat.json.displayName, "JSON")
        XCTAssertEqual(BatchExportFormat.json.fileExtension, "json")
        XCTAssertEqual(BatchExportFormat.json.mimeType, "application/json")

        XCTAssertEqual(BatchExportFormat.txt.displayName, "Text")
        XCTAssertEqual(BatchExportFormat.txt.fileExtension, "txt")
        XCTAssertEqual(BatchExportFormat.txt.mimeType, "text/plain")
    }

    func testBatchExportFormatCaseIterable() {
        let allFormats = BatchExportFormat.allCases
        XCTAssertEqual(allFormats.count, 3)
        XCTAssertTrue(allFormats.contains(.csv))
        XCTAssertTrue(allFormats.contains(.json))
        XCTAssertTrue(allFormats.contains(.txt))
    }

    func testBatchExportFormatIdentifiable() {
        XCTAssertEqual(BatchExportFormat.csv.id, "csv")
        XCTAssertEqual(BatchExportFormat.json.id, "json")
        XCTAssertEqual(BatchExportFormat.txt.id, "txt")
    }

    // MARK: - BatchInputValidationResult Tests

    func testBatchInputValidationResultAllValid() {
        let inputs = ["1640995200", "1641081600", "1641168000"]
        let validator: (String) -> String? = { _ in nil }  // All valid

        let result = BatchInputValidationResult(inputs: inputs, validator: validator)

        XCTAssertEqual(result.validItems.count, 3)
        XCTAssertEqual(result.invalidItems.count, 0)
        XCTAssertEqual(result.totalItems, 3)
        XCTAssertTrue(result.hasValidItems)
        XCTAssertFalse(result.hasInvalidItems)
        XCTAssertEqual(result.validationRate, 1.0)
        XCTAssertEqual(result.validItems, inputs)
    }

    func testBatchInputValidationResultAllInvalid() {
        let inputs = ["invalid1", "invalid2", "invalid3"]
        let validator: (String) -> String? = { _ in "Invalid format" }  // All invalid

        let result = BatchInputValidationResult(inputs: inputs, validator: validator)

        XCTAssertEqual(result.validItems.count, 0)
        XCTAssertEqual(result.invalidItems.count, 3)
        XCTAssertEqual(result.totalItems, 3)
        XCTAssertFalse(result.hasValidItems)
        XCTAssertTrue(result.hasInvalidItems)
        XCTAssertEqual(result.validationRate, 0.0)

        for (index, invalidItem) in result.invalidItems.enumerated() {
            XCTAssertEqual(invalidItem.input, inputs[index])
            XCTAssertEqual(invalidItem.error, "Invalid format")
        }
    }

    func testBatchInputValidationResultMixed() {
        let inputs = ["1640995200", "invalid", "1641081600", "also_invalid"]
        let validator: (String) -> String? = { input in
            return input.contains("invalid") ? "Invalid format" : nil
        }

        let result = BatchInputValidationResult(inputs: inputs, validator: validator)

        XCTAssertEqual(result.validItems.count, 2)
        XCTAssertEqual(result.invalidItems.count, 2)
        XCTAssertEqual(result.totalItems, 4)
        XCTAssertTrue(result.hasValidItems)
        XCTAssertTrue(result.hasInvalidItems)
        XCTAssertEqual(result.validationRate, 0.5)

        XCTAssertEqual(result.validItems[0], "1640995200")
        XCTAssertEqual(result.validItems[1], "1641081600")
        XCTAssertEqual(result.invalidItems[0].input, "invalid")
        XCTAssertEqual(result.invalidItems[1].input, "also_invalid")
    }

    func testBatchInputValidationResultWithEmptyStrings() {
        let inputs = ["1640995200", "", "   ", "1641081600", "\n\t"]
        let validator: (String) -> String? = { _ in nil }  // All valid

        let result = BatchInputValidationResult(inputs: inputs, validator: validator)

        // Empty and whitespace-only strings should be skipped
        XCTAssertEqual(result.validItems.count, 2)
        XCTAssertEqual(result.invalidItems.count, 0)
        XCTAssertEqual(result.totalItems, 5)
        XCTAssertTrue(result.hasValidItems)
        XCTAssertFalse(result.hasInvalidItems)
        XCTAssertEqual(result.validationRate, 0.4)  // 2 valid out of 5 total

        XCTAssertEqual(result.validItems[0], "1640995200")
        XCTAssertEqual(result.validItems[1], "1641081600")
    }

    func testBatchInputValidationResultEmpty() {
        let inputs: [String] = []
        let validator: (String) -> String? = { _ in nil }

        let result = BatchInputValidationResult(inputs: inputs, validator: validator)

        XCTAssertEqual(result.validItems.count, 0)
        XCTAssertEqual(result.invalidItems.count, 0)
        XCTAssertEqual(result.totalItems, 0)
        XCTAssertFalse(result.hasValidItems)
        XCTAssertFalse(result.hasInvalidItems)
        XCTAssertEqual(result.validationRate, 0.0)
    }
}
