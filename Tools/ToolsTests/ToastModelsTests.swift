import XCTest

@testable import Tools

final class ToastModelsTests: XCTestCase {

    // MARK: - ToastType Tests

    func testToastTypeIcons() {
        // Test that each toast type has the correct SF Symbol icon
        XCTAssertEqual(ToastType.success.icon, "checkmark.circle.fill")
        XCTAssertEqual(ToastType.error.icon, "exclamationmark.circle.fill")
        XCTAssertEqual(ToastType.warning.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(ToastType.info.icon, "info.circle.fill")
    }

    func testToastTypeColors() {
        // Test that each toast type has the correct theme color
        XCTAssertEqual(ToastType.success.color, .green)
        XCTAssertEqual(ToastType.error.color, .red)
        XCTAssertEqual(ToastType.warning.color, .orange)
        XCTAssertEqual(ToastType.info.color, .blue)
    }

    func testToastTypeCaseIterable() {
        // Test that all toast types are included in CaseIterable
        let allCases = ToastType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.success))
        XCTAssertTrue(allCases.contains(.error))
        XCTAssertTrue(allCases.contains(.warning))
        XCTAssertTrue(allCases.contains(.info))
    }

    // MARK: - ToastMessage Tests

    func testToastMessageInitialization() {
        // Test basic initialization with required parameters
        let message = ToastMessage(message: "Test message", type: .success)

        XCTAssertEqual(message.message, "Test message")
        XCTAssertEqual(message.type, .success)
        XCTAssertEqual(message.duration, 3.0)  // Default duration
        XCTAssertTrue(message.isAutoDismiss)  // Default auto-dismiss
        XCTAssertNotNil(message.id)  // UUID should be generated
    }

    func testToastMessageCustomInitialization() {
        // Test initialization with all custom parameters
        let message = ToastMessage(
            message: "Custom message",
            type: .error,
            duration: 5.0,
            isAutoDismiss: false
        )

        XCTAssertEqual(message.message, "Custom message")
        XCTAssertEqual(message.type, .error)
        XCTAssertEqual(message.duration, 5.0)
        XCTAssertFalse(message.isAutoDismiss)
    }

    func testToastMessageIdentifiable() {
        // Test that each toast message has a unique ID
        let message1 = ToastMessage(message: "Message 1", type: .success)
        let message2 = ToastMessage(message: "Message 2", type: .error)

        XCTAssertNotEqual(message1.id, message2.id)
    }

    func testToastMessageEquatable() {
        // Test equality comparison
        let message1 = ToastMessage(
            message: "Test", type: .success, duration: 3.0, isAutoDismiss: true)
        let message2 = ToastMessage(
            message: "Test", type: .success, duration: 3.0, isAutoDismiss: true)

        // Different messages with same content should not be equal (different IDs)
        XCTAssertNotEqual(message1, message2)

        // Same message should be equal to itself
        XCTAssertEqual(message1, message1)
    }

    func testToastMessageEqualityWithDifferentProperties() {
        // Test that messages with different properties are not equal
        let baseMessage = ToastMessage(message: "Test", type: .success)

        let differentMessage = ToastMessage(message: "Different", type: .success)
        let differentType = ToastMessage(message: "Test", type: .error)
        let differentDuration = ToastMessage(message: "Test", type: .success, duration: 5.0)
        let differentAutoDismiss = ToastMessage(
            message: "Test", type: .success, isAutoDismiss: false)

        XCTAssertNotEqual(baseMessage, differentMessage)
        XCTAssertNotEqual(baseMessage, differentType)
        XCTAssertNotEqual(baseMessage, differentDuration)
        XCTAssertNotEqual(baseMessage, differentAutoDismiss)
    }

    // MARK: - Integration Tests

    func testToastMessageWithAllToastTypes() {
        // Test creating toast messages with all available types
        let successToast = ToastMessage(message: "Success!", type: .success)
        let errorToast = ToastMessage(message: "Error occurred", type: .error)
        let warningToast = ToastMessage(message: "Warning!", type: .warning)
        let infoToast = ToastMessage(message: "Information", type: .info)

        XCTAssertEqual(successToast.type, .success)
        XCTAssertEqual(errorToast.type, .error)
        XCTAssertEqual(warningToast.type, .warning)
        XCTAssertEqual(infoToast.type, .info)
    }

    func testToastMessageDurationValidation() {
        // Test various duration values
        let shortToast = ToastMessage(message: "Short", type: .info, duration: 1.0)
        let longToast = ToastMessage(message: "Long", type: .info, duration: 10.0)
        let zeroToast = ToastMessage(message: "Zero", type: .info, duration: 0.0)

        XCTAssertEqual(shortToast.duration, 1.0)
        XCTAssertEqual(longToast.duration, 10.0)
        XCTAssertEqual(zeroToast.duration, 0.0)
    }
}
