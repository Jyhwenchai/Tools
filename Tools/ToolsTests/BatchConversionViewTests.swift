import SwiftUI
import XCTest

@testable import Tools

@MainActor
final class BatchConversionViewTests: XCTestCase {

    // MARK: - Test Properties

    private var batchService: BatchConversionService!
    private var toastManager: ToastManager!

    override func setUp() {
        super.setUp()
        batchService = BatchConversionService()
        toastManager = ToastManager()
    }

    override func tearDown() {
        batchService = nil
        toastManager = nil
        super.tearDown()
    }

    // MARK: - Input Validation Tests

    func testInputValidation_ValidTimestamps() {
        let inputs = ["1640995200", "1641081600", "1641168000"]
        let inputString = inputs.joined(separator: "\n")

        let validatedInputs = batchService.validateBatchInput(inputString, format: .timestamp)
        let validationResult = batchService.validateBatchItems(validatedInputs, format: .timestamp)

        XCTAssertEqual(validationResult.validItems.count, 3)
        XCTAssertEqual(validationResult.invalidItems.count, 0)
        XCTAssertTrue(validationResult.hasValidItems)
        XCTAssertFalse(validationResult.hasInvalidItems)
    }

    func testInputValidation_MixedValidInvalid() {
        let inputs = ["1640995200", "invalid_timestamp", "1641081600", ""]
        let inputString = inputs.joined(separator: "\n")

        let validatedInputs = batchService.validateBatchInput(inputString, format: .timestamp)
        let validationResult = batchService.validateBatchItems(validatedInputs, format: .timestamp)

        XCTAssertEqual(validationResult.validItems.count, 2)
        XCTAssertEqual(validationResult.invalidItems.count, 1)
        XCTAssertTrue(validationResult.hasValidItems)
        XCTAssertTrue(validationResult.hasInvalidItems)
    }

    func testInputValidation_EmptyInput() {
        let inputString = ""

        let validatedInputs = batchService.validateBatchInput(inputString, format: .timestamp)
        let validationResult = batchService.validateBatchItems(validatedInputs, format: .timestamp)

        XCTAssertEqual(validationResult.validItems.count, 0)
        XCTAssertEqual(validationResult.invalidItems.count, 0)
        XCTAssertFalse(validationResult.hasValidItems)
        XCTAssertFalse(validationResult.hasInvalidItems)
    }

    func testInputValidation_WhitespaceHandling() {
        let inputString = "  1640995200  \n\n  1641081600  \n  \n"

        let validatedInputs = batchService.validateBatchInput(inputString, format: .timestamp)
        let validationResult = batchService.validateBatchItems(validatedInputs, format: .timestamp)

        XCTAssertEqual(validationResult.validItems.count, 2)
        XCTAssertEqual(validationResult.invalidItems.count, 0)
        XCTAssertTrue(validationResult.hasValidItems)
    }

    func testInputValidation_ISO8601Dates() {
        let inputs = [
            "2024-01-01T12:00:00Z",
            "2024-01-02T12:00:00Z",
            "invalid_date",
            "2024-01-03T12:00:00Z",
        ]
        let inputString = inputs.joined(separator: "\n")

        let validatedInputs = batchService.validateBatchInput(inputString, format: .iso8601)
        let validationResult = batchService.validateBatchItems(validatedInputs, format: .iso8601)

        XCTAssertEqual(validationResult.validItems.count, 3)
        XCTAssertEqual(validationResult.invalidItems.count, 1)
        XCTAssertTrue(validationResult.hasValidItems)
        XCTAssertTrue(validationResult.hasInvalidItems)
    }

    // MARK: - Batch Processing Tests

    func testBatchProcessing_SuccessfulConversion() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641081600", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641168000", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.success })
        XCTAssertTrue(results.allSatisfy { $0.output != nil })
        XCTAssertTrue(results.allSatisfy { $0.error == nil })
    }

    func testBatchProcessing_MixedResults() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(input: "invalid", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641081600", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results.filter { $0.success }.count, 2)
        XCTAssertEqual(results.filter { !$0.success }.count, 1)

        let failedResult = results.first { !$0.success }
        XCTAssertNotNil(failedResult?.error)
        XCTAssertEqual(failedResult?.input, "invalid")
    }

    func testBatchProcessing_EmptyBatch() async {
        let results = await batchService.processBatchConversion(items: [])

        XCTAssertEqual(results.count, 0)
        XCTAssertEqual(
            batchService.processingState, .completed(summary: BatchConversionSummary(results: [])))
    }

    func testBatchProcessing_ProcessingStateUpdates() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641081600", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        // Start processing
        let processingTask = Task {
            await batchService.processBatchConversion(items: items)
        }

        // Check initial state
        XCTAssertEqual(batchService.processingState, .processing(current: 0, total: 2))

        // Wait for completion
        _ = await processingTask.value

        // Check final state
        if case .completed(let summary) = batchService.processingState {
            XCTAssertEqual(summary.totalItems, 2)
            XCTAssertEqual(summary.successfulItems, 2)
            XCTAssertEqual(summary.failedItems, 0)
        } else {
            XCTFail("Expected completed state")
        }
    }

    func testBatchProcessing_Cancellation() async {
        let items = Array(0..<100).map { index in
            BatchConversionItem(
                input: "\(1_640_995_200 + index)", sourceFormat: .timestamp, targetFormat: .iso8601)
        }

        // Start processing
        batchService.startBatchProcessing(items: items)

        // Cancel immediately
        batchService.cancelProcessing()

        // Wait a bit for cancellation to take effect
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        XCTAssertEqual(batchService.processingState, .cancelled)
    }

    // MARK: - Export Functionality Tests

    func testExportResults_CSV() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(),
                input: "1640995200",
                output: "2022-01-01T00:00:00Z",
                processingTime: 0.001
            ),
            BatchConversionResult.failure(
                itemId: UUID(),
                input: "invalid",
                error: "Invalid timestamp",
                processingTime: 0.001
            ),
        ]

        let csvContent = batchService.exportResults(results, format: .csv)

        XCTAssertTrue(csvContent.contains("Input,Output,Success,Error,Processing Time (ms)"))
        XCTAssertTrue(csvContent.contains("1640995200"))
        XCTAssertTrue(csvContent.contains("2022-01-01T00:00:00Z"))
        XCTAssertTrue(csvContent.contains("invalid"))
        XCTAssertTrue(csvContent.contains("Invalid timestamp"))
        XCTAssertTrue(csvContent.contains("true"))
        XCTAssertTrue(csvContent.contains("false"))
    }

    func testExportResults_JSON() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(),
                input: "1640995200",
                output: "2022-01-01T00:00:00Z",
                processingTime: 0.001
            )
        ]

        let jsonContent = batchService.exportResults(results, format: .json)

        XCTAssertTrue(jsonContent.contains("\"input\" : \"1640995200\""))
        XCTAssertTrue(jsonContent.contains("\"output\" : \"2022-01-01T00:00:00Z\""))
        XCTAssertTrue(jsonContent.contains("\"success\" : true"))
        XCTAssertTrue(jsonContent.contains("\"processingTime\""))
    }

    func testExportResults_Text() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(),
                input: "1640995200",
                output: "2022-01-01T00:00:00Z",
                processingTime: 0.001
            ),
            BatchConversionResult.failure(
                itemId: UUID(),
                input: "invalid",
                error: "Invalid timestamp",
                processingTime: 0.001
            ),
        ]

        let textContent = batchService.exportResults(results, format: .txt)

        XCTAssertTrue(textContent.contains("Batch Conversion Results"))
        XCTAssertTrue(textContent.contains("Item 1:"))
        XCTAssertTrue(textContent.contains("Input: 1640995200"))
        XCTAssertTrue(textContent.contains("Output: 2022-01-01T00:00:00Z"))
        XCTAssertTrue(textContent.contains("Status: Success"))
        XCTAssertTrue(textContent.contains("Item 2:"))
        XCTAssertTrue(textContent.contains("Input: invalid"))
        XCTAssertTrue(textContent.contains("Error: Invalid timestamp"))
        XCTAssertTrue(textContent.contains("Status: Failed"))
        XCTAssertTrue(textContent.contains("Summary:"))
        XCTAssertTrue(textContent.contains("Total Items: 2"))
        XCTAssertTrue(textContent.contains("Successful: 1"))
        XCTAssertTrue(textContent.contains("Failed: 1"))
    }

    // MARK: - Error Handling Tests

    func testErrorHandling_InvalidTimestamp() async {
        let items = [
            BatchConversionItem(
                input: "not_a_timestamp", sourceFormat: .timestamp, targetFormat: .iso8601)
        ]

        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].success)
        XCTAssertNotNil(results[0].error)
        XCTAssertNil(results[0].output)
    }

    func testErrorHandling_InvalidDateFormat() async {
        let items = [
            BatchConversionItem(
                input: "invalid_date", sourceFormat: .iso8601, targetFormat: .timestamp)
        ]

        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].success)
        XCTAssertNotNil(results[0].error)
        XCTAssertNil(results[0].output)
    }

    func testErrorHandling_CustomFormatError() async {
        let items = [
            BatchConversionItem(
                input: "2024-01-01",
                sourceFormat: .custom,
                targetFormat: .timestamp,
                customFormat: "invalid_format"
            )
        ]

        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 1)
        XCTAssertFalse(results[0].success)
        XCTAssertNotNil(results[0].error)
    }

    // MARK: - Performance Tests

    func testPerformance_LargeBatch() async {
        let items = Array(0..<1000).map { index in
            BatchConversionItem(
                input: "\(1_640_995_200 + index)",
                sourceFormat: .timestamp,
                targetFormat: .iso8601
            )
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let results = await batchService.processBatchConversion(items: items)
        let endTime = CFAbsoluteTimeGetCurrent()

        let processingTime = endTime - startTime

        XCTAssertEqual(results.count, 1000)
        XCTAssertTrue(results.allSatisfy { $0.success })
        XCTAssertLessThan(processingTime, 5.0)  // Should complete within 5 seconds

        // Check performance analysis
        let analysis = batchService.analyzePerformance(results: results)
        XCTAssertEqual(analysis.totalItems, 1000)
        XCTAssertGreaterThan(analysis.itemsPerSecond, 0)
        XCTAssertGreaterThan(analysis.averageProcessingTime, 0)
    }

    func testPerformance_ProcessingTimeTracking() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601)
        ]

        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 1)
        XCTAssertGreaterThan(results[0].processingTime, 0)
        XCTAssertLessThan(results[0].processingTime, 1.0)  // Should be very fast
    }

    // MARK: - UI State Tests

    func testBatchConversionSummary_Calculation() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(), input: "1", output: "success1", processingTime: 0.001),
            BatchConversionResult.success(
                itemId: UUID(), input: "2", output: "success2", processingTime: 0.002),
            BatchConversionResult.failure(
                itemId: UUID(), input: "3", error: "error1", processingTime: 0.003),
            BatchConversionResult.failure(
                itemId: UUID(), input: "4", error: "error2", processingTime: 0.004),
        ]

        let summary = BatchConversionSummary(results: results)

        XCTAssertEqual(summary.totalItems, 4)
        XCTAssertEqual(summary.successfulItems, 2)
        XCTAssertEqual(summary.failedItems, 2)
        XCTAssertEqual(summary.successRate, 0.5)
        XCTAssertEqual(summary.totalProcessingTime, 0.01)
        XCTAssertEqual(summary.averageProcessingTime, 0.0025)
        XCTAssertTrue(summary.hasErrors)
        XCTAssertEqual(summary.errors.count, 2)
        XCTAssertTrue(summary.errors.contains("error1"))
        XCTAssertTrue(summary.errors.contains("error2"))
    }

    func testBatchProcessingState_Equality() {
        let state1 = BatchProcessingState.processing(current: 5, total: 10)
        let state2 = BatchProcessingState.processing(current: 5, total: 10)
        let state3 = BatchProcessingState.processing(current: 3, total: 10)

        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
        XCTAssertEqual(BatchProcessingState.idle, BatchProcessingState.idle)
        XCTAssertEqual(BatchProcessingState.cancelled, BatchProcessingState.cancelled)
    }

    func testBatchProcessingState_Progress() {
        let processingState = BatchProcessingState.processing(current: 3, total: 10)
        XCTAssertEqual(processingState.progress, 0.3)
        XCTAssertTrue(processingState.isProcessing)

        let idleState = BatchProcessingState.idle
        XCTAssertEqual(idleState.progress, 0.0)
        XCTAssertFalse(idleState.isProcessing)
    }

    // MARK: - Integration Tests

    func testIntegration_CompleteWorkflow() async {
        // 1. Validate input
        let inputString = "1640995200\n1641081600\ninvalid_timestamp\n1641168000"
        let validatedInputs = batchService.validateBatchInput(inputString, format: .timestamp)
        let validationResult = batchService.validateBatchItems(validatedInputs, format: .timestamp)

        XCTAssertEqual(validationResult.validItems.count, 3)
        XCTAssertEqual(validationResult.invalidItems.count, 1)

        // 2. Create batch items
        let items = validationResult.validItems.map { input in
            BatchConversionItem(
                input: input,
                sourceFormat: .timestamp,
                targetFormat: .iso8601,
                sourceTimeZone: .current,
                targetTimeZone: TimeZone(identifier: "UTC") ?? .current
            )
        }

        // 3. Process batch
        let results = await batchService.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.success })

        // 4. Generate summary
        let summary = BatchConversionSummary(results: results)
        XCTAssertEqual(summary.totalItems, 3)
        XCTAssertEqual(summary.successfulItems, 3)
        XCTAssertEqual(summary.failedItems, 0)
        XCTAssertEqual(summary.successRate, 1.0)

        // 5. Export results
        let csvContent = batchService.exportResults(results, format: .csv)
        XCTAssertTrue(csvContent.contains("Input,Output,Success,Error,Processing Time (ms)"))
        XCTAssertTrue(csvContent.contains("1640995200"))
        XCTAssertTrue(csvContent.contains("1641081600"))
        XCTAssertTrue(csvContent.contains("1641168000"))
    }

    // MARK: - Accessibility Tests

    func testAccessibility_ValidationSummary() {
        let validationResult = BatchInputValidationResult(
            inputs: ["valid1", "invalid1", "valid2"],
            validator: { input in
                input.contains("invalid") ? "Invalid input" : nil
            }
        )

        XCTAssertEqual(validationResult.validItems.count, 2)
        XCTAssertEqual(validationResult.invalidItems.count, 1)
        XCTAssertTrue(validationResult.hasValidItems)
        XCTAssertTrue(validationResult.hasInvalidItems)
        XCTAssertEqual(validationResult.validationRate, 2.0 / 3.0)
    }

    func testAccessibility_ResultsDisplay() {
        let results = [
            BatchConversionResult.success(
                itemId: UUID(), input: "1640995200", output: "2022-01-01T00:00:00Z"),
            BatchConversionResult.failure(
                itemId: UUID(), input: "invalid", error: "Invalid timestamp"),
        ]

        // Test that results contain necessary information for accessibility
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results[0].success)
        XCTAssertFalse(results[1].success)
        XCTAssertNotNil(results[0].output)
        XCTAssertNotNil(results[1].error)
    }
}

// MARK: - Test Extensions

extension BatchConversionViewTests {

    /// Helper method to create test batch items
    private func createTestBatchItems(
        count: Int, sourceFormat: TimeFormat = .timestamp, targetFormat: TimeFormat = .iso8601
    ) -> [BatchConversionItem] {
        return Array(0..<count).map { index in
            BatchConversionItem(
                input: "\(1_640_995_200 + index)",
                sourceFormat: sourceFormat,
                targetFormat: targetFormat
            )
        }
    }

    /// Helper method to wait for processing state change
    private func waitForProcessingState(
        _ expectedState: BatchProcessingState, timeout: TimeInterval = 5.0
    ) async -> Bool {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if batchService.processingState == expectedState {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        }

        return false
    }
}
