import SwiftData
import XCTest

@testable import Tools

@MainActor
final class ColorPaletteServiceTests: XCTestCase {

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

    private func createTestColor() -> ColorRepresentation {
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

    private func createTestColorWithName(_ name: String, tags: [String] = []) -> ColorRepresentation
    {
        return createTestColor()
    }

    // MARK: - Initialization Tests

    func testServiceInitialization() {
        XCTAssertNotNil(service)
        XCTAssertTrue(service.savedColors.isEmpty)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.errorMessage)
    }

    func testModelContextSetup() {
        XCTAssertNotNil(service)
        XCTAssertTrue(service.isEmpty)
        XCTAssertEqual(service.count, 0)
    }

    // MARK: - Add Color Tests

    func testAddColor() {
        let color = createTestColor()
        let name = "Test Orange"
        let tags = ["warm", "vibrant"]

        service.addColor(color, name: name, tags: tags)

        XCTAssertEqual(service.count, 1)
        XCTAssertFalse(service.isEmpty)

        let savedColor = service.savedColors.first!
        XCTAssertEqual(savedColor.name, name)
        XCTAssertEqual(savedColor.color, color)
        XCTAssertEqual(savedColor.tags, tags)
        XCTAssertNotNil(savedColor.id)
    }

    func testAddMultipleColors() {
        let color1 = createTestColor()
        let color2 = createTestColorWithName("Blue")

        service.addColor(color1, name: "Orange", tags: ["warm"])
        service.addColor(color2, name: "Blue", tags: ["cool"])

        XCTAssertEqual(service.count, 2)
        XCTAssertEqual(service.savedColors[0].name, "Blue")  // Most recent first
        XCTAssertEqual(service.savedColors[1].name, "Orange")
    }

    func testAddColorWithoutTags() {
        let color = createTestColor()

        service.addColor(color, name: "Simple Color")

        XCTAssertEqual(service.count, 1)
        let savedColor = service.savedColors.first!
        XCTAssertTrue(savedColor.tags.isEmpty)
    }

    // MARK: - Remove Color Tests

    func testRemoveColor() {
        let color = createTestColor()
        service.addColor(color, name: "Test Color")

        let colorId = service.savedColors.first!.id
        service.removeColor(id: colorId)

        XCTAssertTrue(service.isEmpty)
        XCTAssertEqual(service.count, 0)
    }

    func testRemoveNonexistentColor() {
        let color = createTestColor()
        service.addColor(color, name: "Test Color")

        let nonexistentId = UUID()
        service.removeColor(id: nonexistentId)

        XCTAssertEqual(service.count, 1)  // Should remain unchanged
    }

    func testRemoveMultipleColors() {
        service.addColor(createTestColor(), name: "Color 1")
        service.addColor(createTestColor(), name: "Color 2")
        service.addColor(createTestColor(), name: "Color 3")

        let ids = service.savedColors.map { $0.id }
        service.removeColors(ids: Array(ids.prefix(2)))

        XCTAssertEqual(service.count, 1)
        XCTAssertEqual(service.savedColors.first!.name, "Color 1")  // Last added, first in array
    }

    // MARK: - Update Color Tests

    func testUpdateColorName() {
        let color = createTestColor()
        service.addColor(color, name: "Original Name", tags: ["tag1"])

        let colorId = service.savedColors.first!.id
        service.updateColor(id: colorId, name: "Updated Name")

        let updatedColor = service.savedColors.first!
        XCTAssertEqual(updatedColor.name, "Updated Name")
        XCTAssertEqual(updatedColor.tags, ["tag1"])  // Tags should remain unchanged
    }

    func testUpdateColorTags() {
        let color = createTestColor()
        service.addColor(color, name: "Test Color", tags: ["old"])

        let colorId = service.savedColors.first!.id
        service.updateColor(id: colorId, tags: ["new", "updated"])

        let updatedColor = service.savedColors.first!
        XCTAssertEqual(updatedColor.name, "Test Color")  // Name should remain unchanged
        XCTAssertEqual(updatedColor.tags, ["new", "updated"])
    }

    func testUpdateColorNameAndTags() {
        let color = createTestColor()
        service.addColor(color, name: "Original", tags: ["old"])

        let colorId = service.savedColors.first!.id
        service.updateColor(id: colorId, name: "Updated", tags: ["new"])

        let updatedColor = service.savedColors.first!
        XCTAssertEqual(updatedColor.name, "Updated")
        XCTAssertEqual(updatedColor.tags, ["new"])
    }

    func testUpdateNonexistentColor() {
        let color = createTestColor()
        service.addColor(color, name: "Test Color")

        let nonexistentId = UUID()
        service.updateColor(id: nonexistentId, name: "Should Not Update")

        // Original color should remain unchanged
        let originalColor = service.savedColors.first!
        XCTAssertEqual(originalColor.name, "Test Color")
    }

    // MARK: - Search and Query Tests

    func testFindColorsByTag() {
        service.addColor(createTestColor(), name: "Color 1", tags: ["warm", "bright"])
        service.addColor(createTestColor(), name: "Color 2", tags: ["cool", "dark"])
        service.addColor(createTestColor(), name: "Color 3", tags: ["warm", "dark"])

        let warmColors = service.findColors(withTag: "warm")
        XCTAssertEqual(warmColors.count, 2)

        let coolColors = service.findColors(withTag: "cool")
        XCTAssertEqual(coolColors.count, 1)

        let nonexistentColors = service.findColors(withTag: "nonexistent")
        XCTAssertTrue(nonexistentColors.isEmpty)
    }

    func testFindColorsByName() {
        service.addColor(createTestColor(), name: "Red Apple")
        service.addColor(createTestColor(), name: "Blue Ocean")
        service.addColor(createTestColor(), name: "Green Apple")

        let appleColors = service.findColors(withName: "Apple")
        XCTAssertEqual(appleColors.count, 2)

        let oceanColors = service.findColors(withName: "ocean")
        XCTAssertEqual(oceanColors.count, 1)  // Case insensitive

        let nonexistentColors = service.findColors(withName: "Purple")
        XCTAssertTrue(nonexistentColors.isEmpty)
    }

    func testColorExists() {
        let color = createTestColor()
        service.addColor(color, name: "Test Color")

        XCTAssertTrue(service.colorExists(color))

        let differentColor = ColorRepresentation(
            rgb: RGBColor(red: 100, green: 100, blue: 100),
            hex: "#646464",
            hsl: HSLColor(hue: 0, saturation: 0, lightness: 39),
            hsv: HSVColor(hue: 0, saturation: 0, value: 39),
            cmyk: CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 61),
            lab: LABColor(lightness: 43, a: 0, b: 0)
        )
        XCTAssertFalse(service.colorExists(differentColor))
    }

    func testGetColorById() {
        let color = createTestColor()
        service.addColor(color, name: "Test Color")

        let savedColor = service.savedColors.first!
        let retrievedColor = service.getColor(id: savedColor.id)

        XCTAssertNotNil(retrievedColor)
        XCTAssertEqual(retrievedColor!.id, savedColor.id)
        XCTAssertEqual(retrievedColor!.name, "Test Color")

        let nonexistentColor = service.getColor(id: UUID())
        XCTAssertNil(nonexistentColor)
    }

    // MARK: - Computed Properties Tests

    func testRecentColors() {
        // Add more than 10 colors
        for i in 1...15 {
            service.addColor(createTestColor(), name: "Color \(i)")
        }

        let recentColors = service.recentColors
        XCTAssertEqual(recentColors.count, 10)
        XCTAssertEqual(recentColors.first!.name, "Color 15")  // Most recent first
    }

    func testAllTags() {
        service.addColor(createTestColor(), name: "Color 1", tags: ["warm", "bright"])
        service.addColor(createTestColor(), name: "Color 2", tags: ["cool", "bright"])
        service.addColor(createTestColor(), name: "Color 3", tags: ["warm"])

        let allTags = service.allTags
        XCTAssertEqual(Set(allTags), Set(["warm", "bright", "cool"]))
        XCTAssertTrue(allTags.sorted() == allTags)  // Should be sorted
    }

    // MARK: - Batch Operations Tests

    func testAddColors() {
        let colorsData = [
            (name: "Red", color: createTestColor(), tags: ["warm"]),
            (name: "Blue", color: createTestColor(), tags: ["cool"]),
            (name: "Green", color: createTestColor(), tags: ["nature"]),
        ]

        service.addColors(colorsData)

        XCTAssertEqual(service.count, 3)
        XCTAssertEqual(service.savedColors[0].name, "Green")  // Most recent first
        XCTAssertEqual(service.savedColors[1].name, "Blue")
        XCTAssertEqual(service.savedColors[2].name, "Red")
    }

    func testClearPalette() {
        service.addColor(createTestColor(), name: "Color 1")
        service.addColor(createTestColor(), name: "Color 2")
        service.addColor(createTestColor(), name: "Color 3")

        XCTAssertEqual(service.count, 3)

        service.clearPalette()

        XCTAssertTrue(service.isEmpty)
        XCTAssertEqual(service.count, 0)
    }

    func testGetColorsGroupedByTags() {
        service.addColor(createTestColor(), name: "Color 1", tags: ["warm", "bright"])
        service.addColor(createTestColor(), name: "Color 2", tags: ["cool"])
        service.addColor(createTestColor(), name: "Color 3", tags: [])  // Untagged
        service.addColor(createTestColor(), name: "Color 4", tags: ["warm"])

        let groupedColors = service.getColorsGroupedByTags()

        XCTAssertEqual(groupedColors["warm"]?.count, 2)
        XCTAssertEqual(groupedColors["bright"]?.count, 1)
        XCTAssertEqual(groupedColors["cool"]?.count, 1)
        XCTAssertEqual(groupedColors["Untagged"]?.count, 1)
    }

    // MARK: - Export Tests

    func testExportPalette() {
        service.addColor(createTestColor(), name: "Test Color", tags: ["test"])

        let result = service.exportPalette()

        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)

            // Verify JSON structure
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json)
            XCTAssertNotNil(json?["colors"])

        case .failure(let error):
            XCTFail("Export should succeed: \(error)")
        }
    }

    func testExportEmptyPalette() {
        let result = service.exportPalette()

        switch result {
        case .success(let data):
            XCTAssertFalse(data.isEmpty)

            // Should still be valid JSON with empty colors array
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json)

        case .failure(let error):
            XCTFail("Export should succeed even with empty palette: \(error)")
        }
    }

    func testExportPaletteToCSV() {
        service.addColor(createTestColor(), name: "Test Color", tags: ["test", "csv"])

        let result = service.exportPaletteToCSV()

        switch result {
        case .success(let csvString):
            XCTAssertFalse(csvString.isEmpty)
            XCTAssertTrue(csvString.contains("Name,RGB,Hex,HSL,HSV,CMYK,LAB,Tags,Date Created"))
            XCTAssertTrue(csvString.contains("Test Color"))
            XCTAssertTrue(csvString.contains("test; csv"))

        case .failure(let error):
            XCTFail("CSV export should succeed: \(error)")
        }
    }

    // MARK: - Import Tests

    func testImportPalette() {
        // Create test JSON data
        let testPalette = ColorPalette(name: "Test Import")
        var mutablePalette = testPalette
        mutablePalette.addColor(
            name: "Imported Color", color: createTestColor(), tags: ["imported"])

        guard let jsonData = try? mutablePalette.exportToJSON() else {
            XCTFail("Failed to create test JSON data")
            return
        }

        let result = service.importPalette(from: jsonData)

        switch result {
        case .success(let count):
            XCTAssertEqual(count, 1)
            XCTAssertEqual(service.count, 1)
            XCTAssertEqual(service.savedColors.first?.name, "Imported Color")
            XCTAssertEqual(service.savedColors.first?.tags, ["imported"])

        case .failure(let error):
            XCTFail("Import should succeed: \(error)")
        }
    }

    func testImportPaletteWithReplacement() {
        // Add existing color
        service.addColor(createTestColor(), name: "Existing Color")
        XCTAssertEqual(service.count, 1)

        // Create import data
        let testPalette = ColorPalette(name: "Test Import")
        var mutablePalette = testPalette
        mutablePalette.addColor(
            name: "Imported Color", color: createTestColor(), tags: ["imported"])

        guard let jsonData = try? mutablePalette.exportToJSON() else {
            XCTFail("Failed to create test JSON data")
            return
        }

        let result = service.importPalette(from: jsonData, replaceExisting: true)

        switch result {
        case .success(let count):
            XCTAssertEqual(count, 1)
            XCTAssertEqual(service.count, 1)
            XCTAssertEqual(service.savedColors.first?.name, "Imported Color")

        case .failure(let error):
            XCTFail("Import with replacement should succeed: \(error)")
        }
    }

    func testImportInvalidJSON() {
        let invalidData = "invalid json".data(using: .utf8)!

        let result = service.importPalette(from: invalidData)

        switch result {
        case .success:
            XCTFail("Import should fail with invalid JSON")
        case .failure(let error):
            XCTAssertEqual(
                error, .paletteOperationFailed(operation: "Failed to import palette from JSON"))
        }
    }

    // MARK: - Error Handling Tests

    func testErrorHandling() {
        XCTAssertNil(service.errorMessage)

        service.clearError()
        XCTAssertNil(service.errorMessage)
    }

    // MARK: - Performance Tests

    func testPerformanceAddManyColors() {
        measure {
            for i in 1...100 {
                service.addColor(createTestColor(), name: "Color \(i)")
            }
        }
    }

    func testPerformanceSearchInLargePalette() {
        // Add many colors
        for i in 1...1000 {
            let tags = i % 2 == 0 ? ["even"] : ["odd"]
            service.addColor(createTestColor(), name: "Color \(i)", tags: tags)
        }

        measure {
            let evenColors = service.findColors(withTag: "even")
            XCTAssertEqual(evenColors.count, 500)
        }
    }
}
