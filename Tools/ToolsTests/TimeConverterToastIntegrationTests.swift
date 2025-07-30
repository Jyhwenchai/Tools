import SwiftUI
import XCTest

@testable import Tools

@MainActor
final class TimeConverterToastIntegrationTests: XCTestCase {

    var toastManager: ToastManager!

    override func setUp() {
        super.setUp()
        toastManager = ToastManager()
    }

    override func tearDown() {
        toastManager = nil
        super.tearDown()
    }

    // MARK: - Real-Time Timestamp View Toast Tests

    func testRealTimeTimestampCopySuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Copy success toast shown")

        // When
        toastManager.show("时间戳已复制到剪贴板", type: .success, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.message, "时间戳已复制到剪贴板")
        XCTAssertEqual(toastManager.toasts.first?.duration, 2.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testRealTimeTimestampCopyFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Copy failure toast shown")

        // When
        toastManager.show("复制失败，请重试", type: .error, duration: 3.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .error)
        XCTAssertEqual(toastManager.toasts.first?.message, "复制失败，请重试")
        XCTAssertEqual(toastManager.toasts.first?.duration, 3.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Timestamp to Date Conversion Toast Tests

    func testTimestampToDateConversionSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Conversion success toast shown")

        // When
        toastManager.show("时间戳转换成功", type: .success, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.message, "时间戳转换成功")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testTimestampToDateConversionFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Conversion failure toast shown")
        let errorMessage = "Invalid timestamp format"

        // When
        toastManager.show("时间戳转换失败: \(errorMessage)", type: .error, duration: 4.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .error)
        XCTAssertEqual(toastManager.toasts.first?.message, "时间戳转换失败: \(errorMessage)")
        XCTAssertEqual(toastManager.toasts.first?.duration, 4.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testTimestampToDateCopySuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Copy success toast shown")

        // When
        toastManager.show("转换结果已复制到剪贴板", type: .success, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.message, "转换结果已复制到剪贴板")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testTimestampToDateCopyWithoutResult() {
        // Given
        let expectation = XCTestExpectation(description: "Copy warning toast shown")

        // When
        toastManager.show("没有可复制的转换结果", type: .warning, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .warning)
        XCTAssertEqual(toastManager.toasts.first?.message, "没有可复制的转换结果")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Date to Timestamp Conversion Toast Tests

    func testDateToTimestampConversionSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Conversion success toast shown")

        // When
        toastManager.show("日期转换成功", type: .success, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.message, "日期转换成功")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testDateToTimestampConversionFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Conversion failure toast shown")
        let errorMessage = "Invalid date format"

        // When
        toastManager.show("日期转换失败: \(errorMessage)", type: .error, duration: 4.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .error)
        XCTAssertEqual(toastManager.toasts.first?.message, "日期转换失败: \(errorMessage)")
        XCTAssertEqual(toastManager.toasts.first?.duration, 4.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testDateToTimestampGenericError() {
        // Given
        let expectation = XCTestExpectation(description: "Generic error toast shown")

        // When
        toastManager.show("日期转换失败，请检查输入格式", type: .error, duration: 3.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .error)
        XCTAssertEqual(toastManager.toasts.first?.message, "日期转换失败，请检查输入格式")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Batch Conversion Toast Tests

    func testBatchProcessingStart() {
        // Given
        let expectation = XCTestExpectation(description: "Batch processing start toast shown")
        let itemCount = 5

        // When
        toastManager.show("准备批量处理 \(itemCount) 个项目", type: .info, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .info)
        XCTAssertEqual(toastManager.toasts.first?.message, "准备批量处理 \(itemCount) 个项目")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testBatchProcessingProgress() {
        // Given
        let expectation = XCTestExpectation(description: "Batch processing progress toast shown")
        let current = 3
        let total = 10
        let percentage = Int((Double(current) / Double(total)) * 100)

        // When
        toastManager.show(
            "批量处理进度: \(percentage)% (\(current)/\(total))", type: .info, duration: 1.5)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .info)
        XCTAssertEqual(
            toastManager.toasts.first?.message, "批量处理进度: \(percentage)% (\(current)/\(total))")
        XCTAssertEqual(toastManager.toasts.first?.duration, 1.5)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testBatchProcessingCompletionSuccess() {
        // Given
        let expectation = XCTestExpectation(
            description: "Batch processing completion success toast shown")
        let totalItems = 10

        // When
        toastManager.show("批量转换完成，共处理 \(totalItems) 个项目", type: .success, duration: 3.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.message, "批量转换完成，共处理 \(totalItems) 个项目")
        XCTAssertEqual(toastManager.toasts.first?.duration, 3.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testBatchProcessingCompletionWithErrors() {
        // Given
        let expectation = XCTestExpectation(
            description: "Batch processing completion with errors toast shown")
        let successfulItems = 7
        let failedItems = 3

        // When
        toastManager.show(
            "批量转换完成，\(successfulItems) 成功，\(failedItems) 失败", type: .warning, duration: 4.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .warning)
        XCTAssertEqual(
            toastManager.toasts.first?.message, "批量转换完成，\(successfulItems) 成功，\(failedItems) 失败")
        XCTAssertEqual(toastManager.toasts.first?.duration, 4.0)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testBatchProcessingCancellation() {
        // Given
        let expectation = XCTestExpectation(
            description: "Batch processing cancellation toast shown")

        // When
        toastManager.show("批量处理已取消", type: .info, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .info)
        XCTAssertEqual(toastManager.toasts.first?.message, "批量处理已取消")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testBatchValidationWarning() {
        // Given
        let expectation = XCTestExpectation(description: "Batch validation warning toast shown")
        let invalidCount = 2

        // When
        toastManager.show("发现 \(invalidCount) 个新的无效输入项目", type: .warning, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .warning)
        XCTAssertEqual(toastManager.toasts.first?.message, "发现 \(invalidCount) 个新的无效输入项目")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testBatchNoValidItems() {
        // Given
        let expectation = XCTestExpectation(description: "No valid items warning toast shown")

        // When
        toastManager.show("没有有效的输入项目", type: .warning, duration: 3.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .warning)
        XCTAssertEqual(toastManager.toasts.first?.message, "没有有效的输入项目")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Export Toast Tests

    func testExportStart() {
        // Given
        let expectation = XCTestExpectation(description: "Export start toast shown")
        let resultCount = 15

        // When
        toastManager.show("开始导出 \(resultCount) 个转换结果", type: .info, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .info)
        XCTAssertEqual(toastManager.toasts.first?.message, "开始导出 \(resultCount) 个转换结果")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testExportSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Export success toast shown")
        let fileName = "batch_results.csv"

        // When
        toastManager.show("结果已导出到 \(fileName)", type: .success)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .success)
        XCTAssertEqual(toastManager.toasts.first?.message, "结果已导出到 \(fileName)")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testExportFailure() {
        // Given
        let expectation = XCTestExpectation(description: "Export failure toast shown")
        let errorMessage = "Permission denied"

        // When
        toastManager.show("导出失败: \(errorMessage)", type: .error)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .error)
        XCTAssertEqual(toastManager.toasts.first?.message, "导出失败: \(errorMessage)")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testExportNoResults() {
        // Given
        let expectation = XCTestExpectation(description: "Export no results warning toast shown")

        // When
        toastManager.show("没有可导出的结果", type: .warning, duration: 2.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 1)
        XCTAssertEqual(toastManager.toasts.first?.type, .warning)
        XCTAssertEqual(toastManager.toasts.first?.message, "没有可导出的结果")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Multiple Toast Tests

    func testMultipleToastSequence() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple toasts shown in sequence")

        // When
        toastManager.show("第一个通知", type: .info, duration: 1.0)
        toastManager.show("第二个通知", type: .success, duration: 1.0)
        toastManager.show("第三个通知", type: .warning, duration: 1.0)

        // Then
        XCTAssertEqual(toastManager.toasts.count, 3)
        XCTAssertEqual(toastManager.toasts[0].message, "第一个通知")
        XCTAssertEqual(toastManager.toasts[1].message, "第二个通知")
        XCTAssertEqual(toastManager.toasts[2].message, "第三个通知")

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    func testToastQueueManagement() {
        // Given
        let expectation = XCTestExpectation(description: "Toast queue managed properly")

        // When - Add more toasts than the maximum simultaneous limit
        for i in 1...10 {
            toastManager.show("通知 \(i)", type: .info, duration: 0.5)
        }

        // Then - Should not exceed maximum simultaneous toasts
        let queueStatus = toastManager.queueStatus
        XCTAssertLessThanOrEqual(queueStatus.displayedCount, queueStatus.maxCapacity)
        XCTAssertEqual(queueStatus.displayedCount + queueStatus.queuedCount, 10)

        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Toast Accessibility Tests

    func testToastAccessibilityDescription() {
        // Given
        toastManager.show("测试通知", type: .success, duration: 3.0)

        // When
        let accessibilityDescription = toastManager.accessibilityDescription

        // Then
        XCTAssertTrue(accessibilityDescription.contains("1个通知"))
        XCTAssertTrue(accessibilityDescription.contains("成功"))
        XCTAssertTrue(accessibilityDescription.contains("测试通知"))
    }

    func testToastDetailedAccessibilityDescription() {
        // Given
        toastManager.show("第一个通知", type: .success, duration: 3.0)
        toastManager.show("第二个通知", type: .error, duration: 3.0)

        // When
        let detailedDescription = toastManager.detailedAccessibilityDescription

        // Then
        XCTAssertTrue(detailedDescription.contains("第 1 个成功通知"))
        XCTAssertTrue(detailedDescription.contains("第 2 个错误通知"))
        XCTAssertTrue(detailedDescription.contains("第一个通知"))
        XCTAssertTrue(detailedDescription.contains("第二个通知"))
    }

    // MARK: - Performance Tests

    func testToastPerformanceWithManyNotifications() {
        // Given
        let expectation = XCTestExpectation(description: "Performance test completed")

        // When
        measure {
            for i in 1...100 {
                toastManager.show("性能测试通知 \(i)", type: .info, duration: 0.1)
            }
        }

        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
}
