import XCTest

@testable import Tools

final class ColorModelsTests: XCTestCase {

    // MARK: - RGB Color Tests

    func testRGBColorValidation() {
        // Valid RGB formats
        XCTAssertEqual(RGBColor.validate("rgb(255, 128, 0)"), .valid)
        XCTAssertEqual(RGBColor.validate("rgba(255, 128, 0, 0.5)"), .valid)
        XCTAssertEqual(RGBColor.validate("RGB(0, 0, 0)"), .valid)
        XCTAssertEqual(RGBColor.validate("rgba(255, 255, 255, 1.0)"), .valid)

        // Invalid RGB formats
        XCTAssertFalse(RGBColor.validate("rgb(256, 128, 0)").isValid)
        XCTAssertFalse(RGBColor.validate("rgb(-1, 128, 0)").isValid)
        XCTAssertFalse(RGBColor.validate("rgba(255, 128, 0, 1.5)").isValid)
        XCTAssertFalse(RGBColor.validate("rgb(255, 128)").isValid)
        XCTAssertFalse(RGBColor.validate("invalid").isValid)
    }

    func testRGBColorSanitization() {
        XCTAssertEqual(RGBColor.sanitize("  rgb(255, 128, 0)  "), "rgb(255, 128, 0)")
        XCTAssertEqual(RGBColor.sanitize("\trgba(255, 128, 0, 0.5)\n"), "rgba(255, 128, 0, 0.5)")
    }

    // MARK: - HSL Color Tests

    func testHSLColorValidation() {
        // Valid HSL formats
        XCTAssertEqual(HSLColor.validate("hsl(360, 100%, 50%)"), .valid)
        XCTAssertEqual(HSLColor.validate("hsla(180, 50%, 25%, 0.8)"), .valid)
        XCTAssertEqual(HSLColor.validate("HSL(0, 0%, 100%)"), .valid)

        // Invalid HSL formats
        XCTAssertFalse(HSLColor.validate("hsl(361, 100%, 50%)").isValid)
        XCTAssertFalse(HSLColor.validate("hsl(180, 101%, 50%)").isValid)
        XCTAssertFalse(HSLColor.validate("hsl(180, 50%, 101%)").isValid)
        XCTAssertFalse(HSLColor.validate("hsla(180, 50%, 50%, 1.5)").isValid)
        XCTAssertFalse(HSLColor.validate("hsl(180, 50)").isValid)
    }

    func testHSLColorSanitization() {
        XCTAssertEqual(HSLColor.sanitize("  hsl(180, 50%, 25%)  "), "hsl(180, 50%, 25%)")
    }

    // MARK: - HSV Color Tests

    func testHSVColorValidation() {
        // Valid HSV formats
        XCTAssertEqual(HSVColor.validate("hsv(360, 100%, 50%)"), .valid)
        XCTAssertEqual(HSVColor.validate("hsva(180, 50%, 25%, 0.8)"), .valid)
        XCTAssertEqual(HSVColor.validate("HSV(0, 0%, 100%)"), .valid)

        // Invalid HSV formats
        XCTAssertFalse(HSVColor.validate("hsv(361, 100%, 50%)").isValid)
        XCTAssertFalse(HSVColor.validate("hsv(180, 101%, 50%)").isValid)
        XCTAssertFalse(HSVColor.validate("hsv(180, 50%, 101%)").isValid)
        XCTAssertFalse(HSVColor.validate("hsva(180, 50%, 50%, 1.5)").isValid)
    }

    // MARK: - CMYK Color Tests

    func testCMYKColorValidation() {
        // Valid CMYK formats
        XCTAssertEqual(CMYKColor.validate("cmyk(0%, 50%, 100%, 25%)"), .valid)
        XCTAssertEqual(CMYKColor.validate("CMYK(100%, 0%, 0%, 0%)"), .valid)

        // Invalid CMYK formats
        XCTAssertFalse(CMYKColor.validate("cmyk(101%, 50%, 100%, 25%)").isValid)
        XCTAssertFalse(CMYKColor.validate("cmyk(-1%, 50%, 100%, 25%)").isValid)
        XCTAssertFalse(CMYKColor.validate("cmyk(0%, 50%, 100%)").isValid)
    }

    // MARK: - LAB Color Tests

    func testLABColorValidation() {
        // Valid LAB formats
        XCTAssertEqual(LABColor.validate("lab(50, 0, 0)"), .valid)
        XCTAssertEqual(LABColor.validate("lab(100, 127, -128)"), .valid)
        XCTAssertEqual(LABColor.validate("LAB(0, -50, 50)"), .valid)

        // Invalid LAB formats
        XCTAssertFalse(LABColor.validate("lab(101, 0, 0)").isValid)
        XCTAssertFalse(LABColor.validate("lab(-1, 0, 0)").isValid)
        XCTAssertFalse(LABColor.validate("lab(50, 128, 0)").isValid)
        XCTAssertFalse(LABColor.validate("lab(50, 0, -129)").isValid)
        XCTAssertFalse(LABColor.validate("lab(50, 0)").isValid)
    }

    // MARK: - Hex Color Tests

    func testHexColorValidation() {
        // Valid hex formats
        XCTAssertEqual(HexColor.validate("#FF0000"), .valid)
        XCTAssertEqual(HexColor.validate("#f00"), .valid)
        XCTAssertEqual(HexColor.validate("#FF0000AA"), .valid)
        XCTAssertEqual(HexColor.validate("#123abc"), .valid)

        // Invalid hex formats
        XCTAssertFalse(HexColor.validate("FF0000").isValid)
        XCTAssertFalse(HexColor.validate("#GG0000").isValid)
        XCTAssertFalse(HexColor.validate("#FF00").isValid)
        XCTAssertFalse(HexColor.validate("#FF000000AA").isValid)
    }

    func testHexColorSanitization() {
        XCTAssertEqual(HexColor.sanitize("  FF0000  "), "#FF0000")
        XCTAssertEqual(HexColor.sanitize("#FF0000"), "#FF0000")
        XCTAssertEqual(HexColor.sanitize("f00"), "#f00")
    }

    // MARK: - Format Detection Tests

    func testColorFormatDetection() {
        XCTAssertEqual(ColorFormatDetector.detectFormat("#FF0000"), .hex)
        XCTAssertEqual(ColorFormatDetector.detectFormat("rgb(255, 0, 0)"), .rgb)
        XCTAssertEqual(ColorFormatDetector.detectFormat("hsl(0, 100%, 50%)"), .hsl)
        XCTAssertEqual(ColorFormatDetector.detectFormat("hsv(0, 100%, 100%)"), .hsv)
        XCTAssertEqual(ColorFormatDetector.detectFormat("cmyk(0%, 100%, 100%, 0%)"), .cmyk)
        XCTAssertEqual(ColorFormatDetector.detectFormat("lab(50, 75, 25)"), .lab)
        XCTAssertNil(ColorFormatDetector.detectFormat("invalid"))
    }

    func testValidateInputWithExpectedFormat() {
        XCTAssertEqual(
            ColorFormatDetector.validateInput("rgb(255, 0, 0)", expectedFormat: .rgb), .valid)
        XCTAssertEqual(ColorFormatDetector.validateInput("#FF0000", expectedFormat: .hex), .valid)
        XCTAssertFalse(ColorFormatDetector.validateInput("invalid", expectedFormat: .rgb).isValid)
    }

    func testSanitizeInputWithFormat() {
        XCTAssertEqual(
            ColorFormatDetector.sanitizeInput("  rgb(255, 0, 0)  ", format: .rgb), "rgb(255, 0, 0)")
        XCTAssertEqual(ColorFormatDetector.sanitizeInput("FF0000", format: .hex), "#FF0000")
    }

    // MARK: - Color Structure Tests

    func testRGBColorInitialization() {
        let color = RGBColor(red: 300, green: -10, blue: 128, alpha: 1.5)
        XCTAssertEqual(color.red, 255)  // Clamped to max
        XCTAssertEqual(color.green, 0)  // Clamped to min
        XCTAssertEqual(color.blue, 128)  // Within range
        XCTAssertEqual(color.alpha, 1.0)  // Clamped to max
    }

    func testHSLColorInitialization() {
        let color = HSLColor(hue: 400, saturation: -10, lightness: 150, alpha: -0.5)
        XCTAssertEqual(color.hue, 360)  // Clamped to max
        XCTAssertEqual(color.saturation, 0)  // Clamped to min
        XCTAssertEqual(color.lightness, 100)  // Clamped to max
        XCTAssertEqual(color.alpha, 0.0)  // Clamped to min
    }

    func testHSVColorInitialization() {
        let color = HSVColor(hue: 180, saturation: 50, value: 75, alpha: 0.8)
        XCTAssertEqual(color.hue, 180)
        XCTAssertEqual(color.saturation, 50)
        XCTAssertEqual(color.value, 75)
        XCTAssertEqual(color.alpha, 0.8)
    }

    func testCMYKColorInitialization() {
        let color = CMYKColor(cyan: 150, magenta: -10, yellow: 50, key: 25)
        XCTAssertEqual(color.cyan, 100)  // Clamped to max
        XCTAssertEqual(color.magenta, 0)  // Clamped to min
        XCTAssertEqual(color.yellow, 50)
        XCTAssertEqual(color.key, 25)
    }

    func testLABColorInitialization() {
        let color = LABColor(lightness: 150, a: -200, b: 200)
        XCTAssertEqual(color.lightness, 100)  // Clamped to max
        XCTAssertEqual(color.a, -128)  // Clamped to min
        XCTAssertEqual(color.b, 127)  // Clamped to max
    }

    // MARK: - ColorRepresentation Tests

    func testColorRepresentationStringFormatting() {
        let rgb = RGBColor(red: 255, green: 128, blue: 0, alpha: 0.8)
        let hsl = HSLColor(hue: 30, saturation: 100, lightness: 50, alpha: 0.8)
        let hsv = HSVColor(hue: 30, saturation: 100, value: 100, alpha: 0.8)
        let cmyk = CMYKColor(cyan: 0, magenta: 50, yellow: 100, key: 0)
        let lab = LABColor(lightness: 70, a: 25, b: 75)

        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#FF8000CC",
            hsl: hsl,
            hsv: hsv,
            cmyk: cmyk,
            lab: lab
        )

        XCTAssertEqual(colorRep.rgbString, "rgba(255, 128, 0, 0.80)")
        XCTAssertEqual(colorRep.hexString, "#FF8000CC")
        XCTAssertEqual(colorRep.hslString, "hsla(30, 100%, 50%, 0.80)")
        XCTAssertEqual(colorRep.hsvString, "hsva(30, 100%, 100%, 0.80)")
        XCTAssertEqual(colorRep.cmykString, "cmyk(0%, 50%, 100%, 0%)")
        XCTAssertEqual(colorRep.labString, "lab(70.0, 25.0, 75.0)")
    }

    func testColorRepresentationStringFormattingWithoutAlpha() {
        let rgb = RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0)
        let hsl = HSLColor(hue: 0, saturation: 100, lightness: 50, alpha: 1.0)
        let hsv = HSVColor(hue: 0, saturation: 100, value: 100, alpha: 1.0)
        let cmyk = CMYKColor(cyan: 0, magenta: 100, yellow: 100, key: 0)
        let lab = LABColor(lightness: 50, a: 75, b: 50)

        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#FF0000",
            hsl: hsl,
            hsv: hsv,
            cmyk: cmyk,
            lab: lab
        )

        XCTAssertEqual(colorRep.rgbString, "rgb(255, 0, 0)")
        XCTAssertEqual(colorRep.hslString, "hsl(0, 100%, 50%)")
        XCTAssertEqual(colorRep.hsvString, "hsv(0, 100%, 100%)")
    }

    // MARK: - ValidationResult Tests

    func testValidationResult() {
        let validResult = ValidationResult.valid
        let invalidResult = ValidationResult.invalid(reason: "Test error")

        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(validResult.errorMessage)
        XCTAssertEqual(invalidResult.errorMessage, "Test error")
    }

    // MARK: - SavedColor Tests

    func testSavedColorInitialization() {
        let rgb = RGBColor(red: 255, green: 128, blue: 0, alpha: 1.0)
        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#FF8000",
            hsl: HSLColor(hue: 30, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 30, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 0, magenta: 50, yellow: 100, key: 0),
            lab: LABColor(lightness: 70, a: 25, b: 75)
        )

        let savedColor = SavedColor(name: "Orange", color: colorRep, tags: ["warm", "vibrant"])

        XCTAssertEqual(savedColor.name, "Orange")
        XCTAssertEqual(savedColor.color, colorRep)
        XCTAssertEqual(savedColor.tags, ["warm", "vibrant"])
        XCTAssertNotNil(savedColor.id)
        XCTAssertTrue(savedColor.dateCreated <= Date())
    }

    func testSavedColorEquality() {
        let rgb = RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0)
        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#FF0000",
            hsl: HSLColor(hue: 0, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 0, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 0, magenta: 100, yellow: 100, key: 0),
            lab: LABColor(lightness: 50, a: 75, b: 50)
        )

        let id = UUID()
        let date = Date()

        let savedColor1 = SavedColor(
            id: id, name: "Red", color: colorRep, dateCreated: date, tags: ["primary"])
        let savedColor2 = SavedColor(
            id: id, name: "Red", color: colorRep, dateCreated: date, tags: ["primary"])
        let savedColor3 = SavedColor(name: "Different Red", color: colorRep, tags: ["primary"])

        XCTAssertEqual(savedColor1, savedColor2)
        XCTAssertNotEqual(savedColor1, savedColor3)
    }

    // MARK: - ColorPalette Tests

    func testColorPaletteInitialization() {
        let palette = ColorPalette(name: "Test Palette")

        XCTAssertEqual(palette.name, "Test Palette")
        XCTAssertTrue(palette.isEmpty)
        XCTAssertEqual(palette.count, 0)
        XCTAssertNotNil(palette.id)
        XCTAssertTrue(palette.dateCreated <= Date())
        XCTAssertTrue(palette.dateModified <= Date())
    }

    func testColorPaletteAddColor() {
        var palette = ColorPalette()
        let rgb = RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0)
        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#00FF00",
            hsl: HSLColor(hue: 120, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 120, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 100, magenta: 0, yellow: 100, key: 0),
            lab: LABColor(lightness: 80, a: -50, b: 50)
        )

        palette.addColor(name: "Green", color: colorRep, tags: ["primary", "nature"])

        XCTAssertFalse(palette.isEmpty)
        XCTAssertEqual(palette.count, 1)
        XCTAssertEqual(palette.colors.first?.name, "Green")
        XCTAssertEqual(palette.colors.first?.tags, ["primary", "nature"])
    }

    func testColorPaletteRemoveColor() {
        var palette = ColorPalette()
        let rgb = RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0)
        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#0000FF",
            hsl: HSLColor(hue: 240, saturation: 100, lightness: 50),
            hsv: HSVColor(hue: 240, saturation: 100, value: 100),
            cmyk: CMYKColor(cyan: 100, magenta: 100, yellow: 0, key: 0),
            lab: LABColor(lightness: 30, a: 25, b: -75)
        )

        palette.addColor(name: "Blue", color: colorRep)
        let colorId = palette.colors.first!.id

        XCTAssertEqual(palette.count, 1)

        palette.removeColor(id: colorId)

        XCTAssertTrue(palette.isEmpty)
        XCTAssertEqual(palette.count, 0)
    }

    func testColorPaletteExportImportJSON() throws {
        var palette = ColorPalette(name: "Test Export Palette")
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 0.8)
        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#8040C0CC",
            hsl: HSLColor(hue: 270, saturation: 50, lightness: 50, alpha: 0.8),
            hsv: HSVColor(hue: 270, saturation: 67, value: 75, alpha: 0.8),
            cmyk: CMYKColor(cyan: 33, magenta: 67, yellow: 0, key: 25),
            lab: LABColor(lightness: 40, a: 30, b: -60)
        )

        palette.addColor(name: "Purple", color: colorRep, tags: ["purple", "test"])

        // Test export
        let jsonData = try palette.exportToJSON()
        XCTAssertFalse(jsonData.isEmpty)

        // Test import
        let importedPalette = try ColorPalette.importFromJSON(jsonData)
        XCTAssertEqual(importedPalette.name, palette.name)
        XCTAssertEqual(importedPalette.count, palette.count)
        XCTAssertEqual(importedPalette.colors.first?.name, "Purple")
        XCTAssertEqual(importedPalette.colors.first?.tags, ["purple", "test"])
    }

    func testColorPaletteExportCSV() {
        var palette = ColorPalette(name: "CSV Test Palette")
        let rgb = RGBColor(red: 255, green: 128, blue: 64, alpha: 1.0)
        let colorRep = ColorRepresentation(
            rgb: rgb,
            hex: "#FF8040",
            hsl: HSLColor(hue: 20, saturation: 100, lightness: 62.5),
            hsv: HSVColor(hue: 20, saturation: 75, value: 100),
            cmyk: CMYKColor(cyan: 0, magenta: 50, yellow: 75, key: 0),
            lab: LABColor(lightness: 70, a: 30, b: 50)
        )

        palette.addColor(name: "Orange Sunset", color: colorRep, tags: ["orange", "warm"])

        let csv = palette.exportToCSV()

        XCTAssertTrue(csv.contains("Name,RGB,Hex,HSL,HSV,CMYK,LAB,Tags,Date Created"))
        XCTAssertTrue(csv.contains("\"Orange Sunset\""))
        XCTAssertTrue(csv.contains("\"rgb(255, 128, 64)\""))
        XCTAssertTrue(csv.contains("\"#FF8040\""))
        XCTAssertTrue(csv.contains("\"orange; warm\""))
    }

    // MARK: - ColorProcessingError Tests

    func testColorProcessingErrorDescriptions() {
        let invalidFormatError = ColorProcessingError.invalidColorFormat(
            format: "RGB", input: "invalid")
        let conversionError = ColorProcessingError.conversionFailed(from: .rgb, to: .hsl)
        let permissionError = ColorProcessingError.screenSamplingPermissionDenied
        let samplingError = ColorProcessingError.screenSamplingFailed(reason: "Test failure")
        let paletteError = ColorProcessingError.paletteOperationFailed(operation: "save")
        let valueError = ColorProcessingError.invalidColorValue(
            component: "red", value: "300", range: "0-255")

        XCTAssertNotNil(invalidFormatError.errorDescription)
        XCTAssertNotNil(conversionError.errorDescription)
        XCTAssertNotNil(permissionError.errorDescription)
        XCTAssertNotNil(samplingError.errorDescription)
        XCTAssertNotNil(paletteError.errorDescription)
        XCTAssertNotNil(valueError.errorDescription)

        XCTAssertNotNil(invalidFormatError.recoverySuggestion)
        XCTAssertNotNil(conversionError.recoverySuggestion)
        XCTAssertNotNil(permissionError.recoverySuggestion)
        XCTAssertNotNil(samplingError.recoverySuggestion)
        XCTAssertNotNil(paletteError.recoverySuggestion)
        XCTAssertNotNil(valueError.recoverySuggestion)
    }
}
