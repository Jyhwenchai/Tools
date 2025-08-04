import SwiftData
import XCTest

@testable import Tools

@MainActor
final class ColorPaletteImportExportTests: XCTestCase {

    var service: ColorPaletteService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([SavedColorModel.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)

        // Initialize service
        service = ColorPaletteService()
        service.setModelContext(modelContext)

        // Wait for initial load
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }

    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func createTestColor(name: String = "Test Color", tags: [String] = [])
        -> ColorRepresentation
    {
        let rgb = RGBColor(red: 255, green: 128, blue: 64, alpha: 1.0)
        let hex = "#FF8040"
        let hsl = HSLColor(hue: 24, saturation: 100, lightness: 63, alpha: 1.0)
        let hsv = HSVColor(hue: 24, saturation: 75, value: 100, alpha: 1.0)
        let cmyk = CMYKColor(cyan: 0, magenta: 50, yellow: 75, key: 0)
        let lab = LABColor(lightness: 70, a: 25, b: 45)

        return ColorRepresentation(
            rgb: rgb,
            hex: hex,
            hsl: hsl,
            hsv: hsv,
            cmyk: cmyk,
            lab: lab
        )
    }

    private func createTestPalette() -> ColorPalette {
        var palette = ColorPalette(name: "Test Palette")

        palette.addColor(name: "Orange", color: createTestColor(), tags: ["warm", "vibrant"])
        palette.addColor(name: "Blue", color: createTestColor(), tags: ["cool", "calm"])
        palette.addColor(name: "Green", color: createTestColor(), tags: ["nature", "fresh"])

        return palette
    }

    // MARK: - JSON Export Tests

    func testExportEmptyPalette() {
        let result = service.exportPalette()

        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)

            // Verify JSON structure
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)
                XCTAssertNotNil(json?["colors"])

                if let colors = json?["colors"] as? [[String: Any]] {
                    XCTAssertTrue(colors.isEmpty)
                }
            } catch {
                XCTFail("Failed to parse exported JSON: \(error)")
            }

        case .failure(let error):
            XCTFail("Export should succeed even with empty palette: \(error)")
        }
    }

    func testExportPaletteWithColors() {
        // Add test colors
        service.addColor(createTestColor(), name: "Orange", tags: ["warm"])
        service.addColor(createTestColor(), name: "Blue", tags: ["cool"])

        let result = service.exportPalette()

        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)

            // Verify JSON structure and content
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(json)

                if let colors = json?["colors"] as? [[String: Any]] {
                    XCTAssertEqual(colors.count, 2)

                    // Check first color structure
                    let firstColor = colors.first!
                    XCTAssertNotNil(firstColor["id"])
                    XCTAssertNotNil(firstColor["name"])
                    XCTAssertNotNil(firstColor["color"])
                    XCTAssertNotNil(firstColor["dateCreated"])
                    XCTAssertNotNil(firstColor["tags"])
                }
            } catch {
                XCTFail("Failed to parse exported JSON: \(error)")
            }

        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
    }

    func testExportPaletteJSONFormat() {
        service.addColor(createTestColor(), name: "Test Color", tags: ["test", "export"])

        let result = service.exportPalette()

        switch result {
        case .success(let data):
            // Verify it's valid JSON
            do {
                let palette = try ColorPalette.importFromJSON(data)
                XCTAssertEqual(palette.colors.count, 1)
                XCTAssertEqual(palette.colors.first?.name, "Test Color")
                XCTAssertEqual(palette.colors.first?.tags, ["test", "export"])
            } catch {
                XCTFail("Exported JSON should be importable: \(error)")
            }

        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
    }

    // MARK: - JSON Import Tests

    func testImportValidJSON() {
        // Create test palette data
        let testPalette = createTestPalette()

        guard let jsonData = try? testPalette.exportToJSON() else {
            XCTFail("Failed to create test JSON data")
            return
        }

        let result = service.importPalette(from: jsonData)

        switch result {
        case .success(let count):
            XCTAssertEqual(count, 3)
            XCTAssertEqual(service.count, 3)

            // Verify imported colors
            let orangeColors = service.findColors(withName: "Orange")
            XCTAssertEqual(orangeColors.count, 1)
            XCTAssertEqual(orangeColors.first?.tags, ["warm", "vibrant"])

        case .failure(let error):
            XCTFail("Import should succeed: \(error)")
        }
    }

    func testImportWithReplaceExisting() {
        // Add existing colors
        service.addColor(createTestColor(), name: "Existing Color 1")
        service.addColor(createTestColor(), name: "Existing Color 2")
        XCTAssertEqual(service.count, 2)

        // Create import data
        let testPalette = createTestPalette()
        guard let jsonData = try? testPalette.exportToJSON() else {
            XCTFail("Failed to create test JSON data")
            return
        }

        let result = service.importPalette(from: jsonData, replaceExisting: true)

        switch result {
        case .success(let count):
            XCTAssertEqual(count, 3)
            XCTAssertEqual(service.count, 3)  // Should replace existing

            // Verify old colors are gone
            let existingColors = service.findColors(withName: "Existing")
            XCTAssertTrue(existingColors.isEmpty)

        case .failure(let error):
            XCTFail("Import with replacement should succeed: \(error)")
        }
    }

    func testImportWithoutReplaceExisting() {
        // Add existing colors
        service.addColor(createTestColor(), name: "Existing Color")
        XCTAssertEqual(service.count, 1)

        // Create import data
        let testPalette = createTestPalette()
        guard let jsonData = try? testPalette.exportToJSON() else {
            XCTFail("Failed to create test JSON data")
            return
        }

        let result = service.importPalette(from: jsonData, replaceExisting: false)

        switch result {
        case .success(let count):
            XCTAssertEqual(count, 3)  // 3 new colors imported
            XCTAssertEqual(service.count, 4)  // 1 existing + 3 imported

            // Verify existing color is still there
            let existingColors = service.findColors(withName: "Existing")
            XCTAssertEqual(existingColors.count, 1)

        case .failure(let error):
            XCTFail("Import without replacement should succeed: \(error)")
        }
    }

    func testImportInvalidJSON() {
        let invalidData = "invalid json data".data(using: .utf8)!

        let result = service.importPalette(from: invalidData)

        switch result {
        case .success:
            XCTFail("Import should fail with invalid JSON")
        case .failure(let error):
            XCTAssertEqual(
                error, .paletteOperationFailed(operation: "Failed to import palette from JSON"))
        }
    }

    func testImportMalformedJSON() {
        let malformedJSON = """
            {
                "colors": [
                    {
                        "id": "not-a-uuid",
                        "name": "Test",
                        "invalidField": true
                    }
                ]
            }
            """.data(using: .utf8)!

        let result = service.importPalette(from: malformedJSON)

        switch result {
        case .success:
            XCTFail("Import should fail with malformed JSON")
        case .failure(let error):
            XCTAssertEqual(
                error, .paletteOperationFailed(operation: "Failed to import palette from JSON"))
        }
    }

    // MARK: - CSV Export Tests

    func testExportPaletteToCSV() {
        service.addColor(createTestColor(), name: "Test Color", tags: ["test", "csv"])

        let result = service.exportPaletteToCSV()

        switch result {
        case .success(let csvString):
            XCTAssertFalse(csvString.isEmpty)

            // Verify CSV structure
            let lines = csvString.components(separatedBy: .newlines)
            XCTAssertGreaterThan(lines.count, 1)

            // Check header
            let header = lines.first!
            XCTAssertTrue(header.contains("Name"))
            XCTAssertTrue(header.contains("RGB"))
            XCTAssertTrue(header.contains("Hex"))
            XCTAssertTrue(header.contains("HSL"))
            XCTAssertTrue(header.contains("HSV"))
            XCTAssertTrue(header.contains("CMYK"))
            XCTAssertTrue(header.contains("LAB"))
            XCTAssertTrue(header.contains("Tags"))
            XCTAssertTrue(header.contains("Date Created"))

            // Check data row
            let dataRow = lines[1]
            XCTAssertTrue(dataRow.contains("Test Color"))
            XCTAssertTrue(dataRow.contains("test; csv"))

        case .failure(let error):
            XCTFail("CSV export should succeed: \(error)")
        }
    }

    func testExportEmptyPaletteToCSV() {
        let result = service.exportPaletteToCSV()

        switch result {
        case .success(let csvString):
            XCTAssertFalse(csvString.isEmpty)

            // Should still have header
            let lines = csvString.components(separatedBy: .newlines)
            XCTAssertGreaterThanOrEqual(lines.count, 1)

            let header = lines.first!
            XCTAssertTrue(header.contains("Name"))

        case .failure(let error):
            XCTFail("CSV export should succeed even with empty palette: \(error)")
        }
    }

    func testCSVExportSpecialCharacters() {
        // Test with special characters that need escaping in CSV
        service.addColor(
            createTestColor(), name: "Color with \"quotes\"", tags: ["special,chars", "test"])

        let result = service.exportPaletteToCSV()

        switch result {
        case .success(let csvString):
            XCTAssertFalse(csvString.isEmpty)

            // Verify proper CSV escaping
            XCTAssertTrue(csvString.contains("\"Color with \"\"quotes\"\"\""))
            XCTAssertTrue(csvString.contains("\"special,chars; test\""))

        case .failure(let error):
            XCTFail("CSV export should handle special characters: \(error)")
        }
    }

    // MARK: - Round-trip Tests

    func testJSONExportImportRoundTrip() {
        // Add test colors
        service.addColor(createTestColor(), name: "Orange", tags: ["warm", "vibrant"])
        service.addColor(createTestColor(), name: "Blue", tags: ["cool", "calm"])

        // Export
        let exportResult = service.exportPalette()
        guard case .success(let exportData) = exportResult else {
            XCTFail("Export failed")
            return
        }

        // Clear palette
        service.clearPalette()
        XCTAssertTrue(service.isEmpty)

        // Import
        let importResult = service.importPalette(from: exportData)
        guard case .success(let importCount) = importResult else {
            XCTFail("Import failed")
            return
        }

        // Verify round-trip
        XCTAssertEqual(importCount, 2)
        XCTAssertEqual(service.count, 2)

        let orangeColors = service.findColors(withName: "Orange")
        XCTAssertEqual(orangeColors.count, 1)
        XCTAssertEqual(orangeColors.first?.tags, ["warm", "vibrant"])

        let blueColors = service.findColors(withName: "Blue")
        XCTAssertEqual(blueColors.count, 1)
        XCTAssertEqual(blueColors.first?.tags, ["cool", "calm"])
    }

    func testLargeDatasetExportImport() {
        // Add many colors
        for i in 1...100 {
            service.addColor(createTestColor(), name: "Color \(i)", tags: ["batch", "test\(i)"])
        }

        XCTAssertEqual(service.count, 100)

        // Export
        let exportResult = service.exportPalette()
        guard case .success(let exportData) = exportResult else {
            XCTFail("Export failed")
            return
        }

        // Clear and import
        service.clearPalette()
        let importResult = service.importPalette(from: exportData)

        switch importResult {
        case .success(let count):
            XCTAssertEqual(count, 100)
            XCTAssertEqual(service.count, 100)

            // Verify some colors
            let batchColors = service.findColors(withTag: "batch")
            XCTAssertEqual(batchColors.count, 100)

        case .failure(let error):
            XCTFail("Large dataset import should succeed: \(error)")
        }
    }

    // MARK: - Error Handling Tests

    func testImportWithCorruptedData() {
        let corruptedData = Data([0xFF, 0xFE, 0xFD, 0xFC])  // Invalid UTF-8

        let result = service.importPalette(from: corruptedData)

        switch result {
        case .success:
            XCTFail("Import should fail with corrupted data")
        case .failure(let error):
            XCTAssertEqual(
                error, .paletteOperationFailed(operation: "Failed to import palette from JSON"))
        }
    }

    func testImportEmptyData() {
        let emptyData = Data()

        let result = service.importPalette(from: emptyData)

        switch result {
        case .success:
            XCTFail("Import should fail with empty data")
        case .failure(let error):
            XCTAssertEqual(
                error, .paletteOperationFailed(operation: "Failed to import palette from JSON"))
        }
    }

    // MARK: - Performance Tests

    func testExportPerformance() {
        // Add many colors for performance testing
        for i in 1...1000 {
            service.addColor(createTestColor(), name: "Performance Color \(i)")
        }

        measure {
            let result = service.exportPalette()
            switch result {
            case .success:
                break  // Success
            case .failure:
                XCTFail("Export should succeed")
            }
        }
    }

    func testImportPerformance() {
        // Create large test dataset
        var largePalette = ColorPalette(name: "Large Test Palette")
        for i in 1...1000 {
            largePalette.addColor(name: "Performance Color \(i)", color: createTestColor())
        }

        guard let testData = try? largePalette.exportToJSON() else {
            XCTFail("Failed to create test data")
            return
        }

        measure {
            let result = service.importPalette(from: testData, replaceExisting: true)
            switch result {
            case .success:
                break  // Success
            case .failure:
                XCTFail("Import should succeed")
            }
        }
    }
}
