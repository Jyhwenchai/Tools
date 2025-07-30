import XCTest

@testable import Tools

@MainActor
final class BatchConversionServiceTests: XCTestCase {

    var service: BatchConversionService!

    override func setUp() {
        super.setUp()
        service = BatchConversionService()
    }

    override func tearDown() {
        service.cancelProcessing()
        service = nil
        super.tearDown()
    }

    // MARK: - Basic Batch Processing Tests

    func testEmptyBatchProcessing() async {
        let results = await service.processBatchConversion(items: [])

        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(
            service.processingState, .completed(summary: BatchConversionSummary(results: [])))
    }

    func testSingleItemBatchProcessing() async {
        let item = BatchConversionItem(
            input: "1640995200",
            sourceFormat: .timestamp,
            targetFormat: .iso8601
        )

        let results = await service.processBatchConversion(items: [item])

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].success)
        XCTAssertNotNil(results[0].output)
        XCTAssertNil(results[0].error)
        XCTAssertEqual(results[0].itemId, item.id)
        XCTAssertEqual(results[0].input, item.input)
    }

    func testMultipleItemBatchProcessing() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641081600", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641168000", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        let results = await service.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.success })
        XCTAssertTrue(results.allSatisfy { $0.output != nil })
        XCTAssertTrue(results.allSatisfy { $0.error == nil })

        // Verify item IDs match
        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.itemId, items[index].id)
            XCTAssertEqual(result.input, items[index].input)
        }
    }

    // MARK: - Error Handling Tests

    func testBatchProcessingWithInvalidInput() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),  // Valid
            BatchConversionItem(
                input: "invalid_timestamp", sourceFormat: .timestamp, targetFormat: .iso8601),  // Invalid
            BatchConversionItem(
                input: "1641168000", sourceFormat: .timestamp, targetFormat: .iso8601),  // Valid
        ]

        let results = await service.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results[0].success)
        XCTAssertFalse(results[1].success)
        XCTAssertTrue(results[2].success)

        XCTAssertNotNil(results[0].output)
        XCTAssertNil(results[1].output)
        XCTAssertNotNil(results[2].output)

        XCTAssertNil(results[0].error)
        XCTAssertNotNil(results[1].error)
        XCTAssertNil(results[2].error)
    }

    func testBatchProcessingWithAllInvalidInputs() async {
        let items = [
            BatchConversionItem(
                input: "invalid1", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "invalid2", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "invalid3", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        let results = await service.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { !$0.success })
        XCTAssertTrue(results.allSatisfy { $0.output == nil })
        XCTAssertTrue(results.allSatisfy { $0.error != nil })
    }

    // MARK: - Processing State Tests

    func testProcessingStateUpdates() async {
        let items = Array(1...5).map { i in
            BatchConversionItem(
                input: "\(1_640_995_200 + i * 86400)", sourceFormat: .timestamp,
                targetFormat: .iso8601)
        }

        XCTAssertEqual(service.processingState, .idle)

        let task = Task {
            await service.processBatchConversion(items: items)
        }

        // Wait a bit for processing to start
        try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

        // Should be processing
        XCTAssertTrue(service.processingState.isProcessing)

        await task.value

        // Should be completed
        if case .completed(let summary) = service.processingState {
            XCTAssertEqual(summary.totalItems, 5)
            XCTAssertEqual(summary.successfulItems, 5)
            XCTAssertEqual(summary.failedItems, 0)
        } else {
            XCTFail("Expected completed state")
        }
    }

    func testProcessingCancellation() async {
        let items = Array(1...100).map { i in
            BatchConversionItem(
                input: "\(1_640_995_200 + i * 86400)", sourceFormat: .timestamp,
                targetFormat: .iso8601)
        }

        let task = Task {
            await service.processBatchConversion(items: items)
        }

        // Wait a bit for processing to start
        try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

        // Cancel processing
        task.cancel()

        await task.value

        // Should be cancelled
        XCTAssertEqual(service.processingState, .cancelled)
    }

    // MARK: - Input Validation Tests

    func testValidateBatchInput() {
        let input = """
            1640995200
            1641081600

            1641168000

            """

        let results = service.validateBatchInput(input, format: .timestamp)

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0], "1640995200")
        XCTAssertEqual(results[1], "1641081600")
        XCTAssertEqual(results[2], "1641168000")
    }

    func testValidateBatchInputEmpty() {
        let input = ""
        let results = service.validateBatchInput(input, format: .timestamp)
        XCTAssertTrue(results.isEmpty)
    }

    func testValidateBatchInputOnlyWhitespace() {
        let input = "   \n\n   \n   "
        let results = service.validateBatchInput(input, format: .timestamp)
        XCTAssertTrue(results.isEmpty)
    }

    func testValidateBatchItems() {
        let inputs = ["1640995200", "invalid", "1641081600", ""]
        let validation = service.validateBatchItems(inputs, format: .timestamp)

        XCTAssertEqual(validation.validItems.count, 2)
        XCTAssertEqual(validation.invalidItems.count, 1)
        XCTAssertEqual(validation.totalItems, 4)
        XCTAssertTrue(validation.hasValidItems)
        XCTAssertTrue(validation.hasInvalidItems)

        XCTAssertEqual(validation.validItems[0], "1640995200")
        XCTAssertEqual(validation.validItems[1], "1641081600")
        XCTAssertEqual(validation.invalidItems[0].input, "invalid")
        XCTAssertEqual(validation.invalidItems[0].error, "Invalid timestamp format")
    }

    // MARK: - Export Functionality Tests

    func testExportToCSV() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(input: "invalid", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        let results = await service.processBatchConversion(items: items)
        let csv = service.exportResults(results, format: .csv)

        XCTAssertTrue(csv.contains("Input,Output,Success,Error,Processing Time (ms)"))
        XCTAssertTrue(csv.contains("1640995200"))
        XCTAssertTrue(csv.contains("invalid"))
        XCTAssertTrue(csv.contains("true"))
        XCTAssertTrue(csv.contains("false"))
    }

    func testExportToJSON() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601)
        ]

        let results = await service.processBatchConversion(items: items)
        let json = service.exportResults(results, format: .json)

        XCTAssertTrue(json.contains("\"input\" : \"1640995200\""))
        XCTAssertTrue(json.contains("\"success\" : true"))
        XCTAssertFalse(json.isEmpty)

        // Verify it's valid JSON
        let jsonData = json.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: jsonData))
    }

    func testExportToText() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(input: "invalid", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        let results = await service.processBatchConversion(items: items)
        let text = service.exportResults(results, format: .txt)

        XCTAssertTrue(text.contains("Batch Conversion Results"))
        XCTAssertTrue(text.contains("Item 1:"))
        XCTAssertTrue(text.contains("Item 2:"))
        XCTAssertTrue(text.contains("Input: 1640995200"))
        XCTAssertTrue(text.contains("Input: invalid"))
        XCTAssertTrue(text.contains("Status: Success"))
        XCTAssertTrue(text.contains("Status: Failed"))
        XCTAssertTrue(text.contains("Summary:"))
        XCTAssertTrue(text.contains("Total Items: 2"))
        XCTAssertTrue(text.contains("Successful: 1"))
        XCTAssertTrue(text.contains("Failed: 1"))
    }

    // MARK: - Performance Tests

    func testLargeBatchPerformance() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Create 100 items for performance testing
        let items = Array(1...100).map { i in
            BatchConversionItem(
                input: "\(1_640_995_200 + i * 86400)", sourceFormat: .timestamp,
                targetFormat: .iso8601)
        }

        let results = await service.processBatchConversion(items: items)

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        XCTAssertEqual(results.count, 100)
        XCTAssertTrue(results.allSatisfy { $0.success })
        XCTAssertLessThan(totalTime, 5.0)  // Should complete within 5 seconds

        // Verify processing times are recorded
        XCTAssertTrue(results.allSatisfy { $0.processingTime > 0 })
    }

    func testBatchSizeLimit() async {
        // Create more than maxBatchSize items (1000)
        let items = Array(1...1500).map { i in
            BatchConversionItem(
                input: "\(1_640_995_200 + i * 86400)", sourceFormat: .timestamp,
                targetFormat: .iso8601)
        }

        let results = await service.processBatchConversion(items: items)

        // Should be limited to maxBatchSize
        XCTAssertEqual(results.count, 1000)
        XCTAssertTrue(results.allSatisfy { $0.success })
    }

    func testPerformanceAnalysis() async {
        let items = Array(1...10).map { i in
            BatchConversionItem(
                input: "\(1_640_995_200 + i * 86400)", sourceFormat: .timestamp,
                targetFormat: .iso8601)
        }

        let results = await service.processBatchConversion(items: items)
        let analysis = service.analyzePerformance(results: results)

        XCTAssertEqual(analysis.totalItems, 10)
        XCTAssertGreaterThan(analysis.averageProcessingTime, 0)
        XCTAssertGreaterThanOrEqual(analysis.maxProcessingTime, analysis.minProcessingTime)
        XCTAssertGreaterThanOrEqual(analysis.averageProcessingTime, analysis.minProcessingTime)
        XCTAssertLessThanOrEqual(analysis.averageProcessingTime, analysis.maxProcessingTime)
        XCTAssertGreaterThan(analysis.itemsPerSecond, 0)
    }

    // MARK: - Batch Conversion Summary Tests

    func testBatchConversionSummary() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),  // Success
            BatchConversionItem(
                input: "invalid1", sourceFormat: .timestamp, targetFormat: .iso8601),  // Failure
            BatchConversionItem(
                input: "1641081600", sourceFormat: .timestamp, targetFormat: .iso8601),  // Success
            BatchConversionItem(
                input: "invalid2", sourceFormat: .timestamp, targetFormat: .iso8601),  // Failure
        ]

        let results = await service.processBatchConversion(items: items)
        let summary = BatchConversionSummary(results: results)

        XCTAssertEqual(summary.totalItems, 4)
        XCTAssertEqual(summary.successfulItems, 2)
        XCTAssertEqual(summary.failedItems, 2)
        XCTAssertEqual(summary.successRate, 0.5)
        XCTAssertTrue(summary.hasErrors)
        XCTAssertEqual(summary.errors.count, 2)
        XCTAssertGreaterThan(summary.totalProcessingTime, 0)
        XCTAssertGreaterThan(summary.averageProcessingTime, 0)
    }

    // MARK: - Different Format Tests

    func testBatchProcessingWithDifferentFormats() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "2022-01-01T00:00:00Z", sourceFormat: .iso8601, targetFormat: .timestamp),
            BatchConversionItem(
                input: "Sat, 01 Jan 2022 00:00:00 GMT", sourceFormat: .rfc2822,
                targetFormat: .timestamp),
        ]

        let results = await service.processBatchConversion(items: items)

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.success })
        XCTAssertTrue(results.allSatisfy { $0.output != nil })
    }

    // MARK: - Async Processing Tests

    func testStartBatchProcessing() async {
        let items = [
            BatchConversionItem(
                input: "1640995200", sourceFormat: .timestamp, targetFormat: .iso8601),
            BatchConversionItem(
                input: "1641081600", sourceFormat: .timestamp, targetFormat: .iso8601),
        ]

        service.startBatchProcessing(items: items)

        // Wait for processing to complete
        while service.processingState.isProcessing {
            try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms
        }

        XCTAssertEqual(service.lastResults.count, 2)
        XCTAssertNotNil(service.lastSummary)
        XCTAssertTrue(service.lastResults.allSatisfy { $0.success })
    }

    func testCancelProcessing() async {
        let items = Array(1...100).map { i in
            BatchConversionItem(
                input: "\(1_640_995_200 + i * 86400)", sourceFormat: .timestamp,
                targetFormat: .iso8601)
        }

        service.startBatchProcessing(items: items)

        // Wait a bit for processing to start
        try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

        XCTAssertTrue(service.processingState.isProcessing)

        service.cancelProcessing()

        // Wait a bit for cancellation to take effect
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms

        XCTAssertEqual(service.processingState, .cancelled)
    }
}
