import XCTest

@testable import Tools

@MainActor
final class ColorConversionServiceTests: XCTestCase {

    var service: ColorConversionService!

    override func setUp() {
        super.setUp()
        service = ColorConversionService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - RGB to HSL Conversion Tests

    func testRGBToHSL_PureRed() {
        let rgb = RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 0, accuracy: 1.0, "Pure red should have hue of 0°")
        XCTAssertEqual(hsl.saturation, 100, accuracy: 1.0, "Pure red should have 100% saturation")
        XCTAssertEqual(hsl.lightness, 50, accuracy: 1.0, "Pure red should have 50% lightness")
        XCTAssertEqual(hsl.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSL_PureGreen() {
        let rgb = RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 120, accuracy: 1.0, "Pure green should have hue of 120°")
        XCTAssertEqual(hsl.saturation, 100, accuracy: 1.0, "Pure green should have 100% saturation")
        XCTAssertEqual(hsl.lightness, 50, accuracy: 1.0, "Pure green should have 50% lightness")
        XCTAssertEqual(hsl.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSL_PureBlue() {
        let rgb = RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 240, accuracy: 1.0, "Pure blue should have hue of 240°")
        XCTAssertEqual(hsl.saturation, 100, accuracy: 1.0, "Pure blue should have 100% saturation")
        XCTAssertEqual(hsl.lightness, 50, accuracy: 1.0, "Pure blue should have 50% lightness")
        XCTAssertEqual(hsl.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSL_White() {
        let rgb = RGBColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 0, accuracy: 1.0, "White should have hue of 0°")
        XCTAssertEqual(hsl.saturation, 0, accuracy: 1.0, "White should have 0% saturation")
        XCTAssertEqual(hsl.lightness, 100, accuracy: 1.0, "White should have 100% lightness")
        XCTAssertEqual(hsl.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSL_Black() {
        let rgb = RGBColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 0, accuracy: 1.0, "Black should have hue of 0°")
        XCTAssertEqual(hsl.saturation, 0, accuracy: 1.0, "Black should have 0% saturation")
        XCTAssertEqual(hsl.lightness, 0, accuracy: 1.0, "Black should have 0% lightness")
        XCTAssertEqual(hsl.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSL_Gray() {
        let rgb = RGBColor(red: 128, green: 128, blue: 128, alpha: 1.0)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 0, accuracy: 1.0, "Gray should have hue of 0°")
        XCTAssertEqual(hsl.saturation, 0, accuracy: 1.0, "Gray should have 0% saturation")
        XCTAssertEqual(hsl.lightness, 50.2, accuracy: 1.0, "Gray should have ~50% lightness")
        XCTAssertEqual(hsl.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSL_WithAlpha() {
        let rgb = RGBColor(red: 255, green: 0, blue: 0, alpha: 0.5)
        let hsl = service.rgbToHSL(rgb)

        XCTAssertEqual(hsl.hue, 0, accuracy: 1.0, "Hue should be preserved")
        XCTAssertEqual(hsl.saturation, 100, accuracy: 1.0, "Saturation should be preserved")
        XCTAssertEqual(hsl.lightness, 50, accuracy: 1.0, "Lightness should be preserved")
        XCTAssertEqual(hsl.alpha, 0.5, accuracy: 0.01, "Alpha should be preserved")
    }

    // MARK: - RGB to HSV Conversion Tests

    func testRGBToHSV_PureRed() {
        let rgb = RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 0, accuracy: 1.0, "Pure red should have hue of 0°")
        XCTAssertEqual(hsv.saturation, 100, accuracy: 1.0, "Pure red should have 100% saturation")
        XCTAssertEqual(hsv.value, 100, accuracy: 1.0, "Pure red should have 100% value")
        XCTAssertEqual(hsv.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSV_PureGreen() {
        let rgb = RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 120, accuracy: 1.0, "Pure green should have hue of 120°")
        XCTAssertEqual(hsv.saturation, 100, accuracy: 1.0, "Pure green should have 100% saturation")
        XCTAssertEqual(hsv.value, 100, accuracy: 1.0, "Pure green should have 100% value")
        XCTAssertEqual(hsv.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSV_PureBlue() {
        let rgb = RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 240, accuracy: 1.0, "Pure blue should have hue of 240°")
        XCTAssertEqual(hsv.saturation, 100, accuracy: 1.0, "Pure blue should have 100% saturation")
        XCTAssertEqual(hsv.value, 100, accuracy: 1.0, "Pure blue should have 100% value")
        XCTAssertEqual(hsv.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSV_White() {
        let rgb = RGBColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 0, accuracy: 1.0, "White should have hue of 0°")
        XCTAssertEqual(hsv.saturation, 0, accuracy: 1.0, "White should have 0% saturation")
        XCTAssertEqual(hsv.value, 100, accuracy: 1.0, "White should have 100% value")
        XCTAssertEqual(hsv.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSV_Black() {
        let rgb = RGBColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 0, accuracy: 1.0, "Black should have hue of 0°")
        XCTAssertEqual(hsv.saturation, 0, accuracy: 1.0, "Black should have 0% saturation")
        XCTAssertEqual(hsv.value, 0, accuracy: 1.0, "Black should have 0% value")
        XCTAssertEqual(hsv.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSV_Gray() {
        let rgb = RGBColor(red: 128, green: 128, blue: 128, alpha: 1.0)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 0, accuracy: 1.0, "Gray should have hue of 0°")
        XCTAssertEqual(hsv.saturation, 0, accuracy: 1.0, "Gray should have 0% saturation")
        XCTAssertEqual(hsv.value, 50.2, accuracy: 1.0, "Gray should have ~50% value")
        XCTAssertEqual(hsv.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")
    }

    func testRGBToHSV_WithAlpha() {
        let rgb = RGBColor(red: 255, green: 0, blue: 0, alpha: 0.75)
        let hsv = service.rgbToHSV(rgb)

        XCTAssertEqual(hsv.hue, 0, accuracy: 1.0, "Hue should be preserved")
        XCTAssertEqual(hsv.saturation, 100, accuracy: 1.0, "Saturation should be preserved")
        XCTAssertEqual(hsv.value, 100, accuracy: 1.0, "Value should be preserved")
        XCTAssertEqual(hsv.alpha, 0.75, accuracy: 0.01, "Alpha should be preserved")
    }

    // MARK: - Color Conversion Service Tests

    func testConvertColor_RGBToHSL() {
        let result = service.convertColor(from: .rgb, to: .hsl, value: "rgb(255, 0, 0)")

        switch result {
        case .success(let hslString):
            XCTAssertEqual(
                hslString, "hsl(0, 100%, 50%)", "RGB to HSL conversion should work correctly")
        case .failure(let error):
            XCTFail("Conversion should succeed, but failed with: \(error)")
        }
    }

    func testConvertColor_RGBToHSV() {
        let result = service.convertColor(from: .rgb, to: .hsv, value: "rgb(0, 255, 0)")

        switch result {
        case .success(let hsvString):
            XCTAssertEqual(
                hsvString, "hsv(120, 100%, 100%)", "RGB to HSV conversion should work correctly")
        case .failure(let error):
            XCTFail("Conversion should succeed, but failed with: \(error)")
        }
    }

    func testConvertColor_RGBToHex() {
        let result = service.convertColor(from: .rgb, to: .hex, value: "rgb(255, 128, 64)")

        switch result {
        case .success(let hexString):
            XCTAssertEqual(hexString, "#FF8040", "RGB to Hex conversion should work correctly")
        case .failure(let error):
            XCTFail("Conversion should succeed, but failed with: \(error)")
        }
    }

    func testConvertColor_HexToRGB() {
        let result = service.convertColor(from: .hex, to: .rgb, value: "#FF0000")

        switch result {
        case .success(let rgbString):
            XCTAssertEqual(
                rgbString, "rgb(255, 0, 0)", "Hex to RGB conversion should work correctly")
        case .failure(let error):
            XCTFail("Conversion should succeed, but failed with: \(error)")
        }
    }

    func testConvertColor_InvalidInput() {
        let result = service.convertColor(from: .rgb, to: .hsl, value: "invalid color")

        switch result {
        case .success:
            XCTFail("Conversion should fail for invalid input")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("Invalid RGB color format"))
            XCTAssertEqual(service.lastError, error, "Service should store the last error")
        }
    }

    // MARK: - Color Representation Creation Tests

    func testCreateColorRepresentation_FromRGB() {
        let result = service.createColorRepresentation(from: .rgb, value: "rgb(255, 128, 0)")

        switch result {
        case .success(let colorRep):
            XCTAssertEqual(colorRep.rgb.red, 255, "RGB red component should be correct")
            XCTAssertEqual(colorRep.rgb.green, 128, "RGB green component should be correct")
            XCTAssertEqual(colorRep.rgb.blue, 0, "RGB blue component should be correct")
            XCTAssertEqual(colorRep.hex, "#FF8000", "Hex representation should be correct")
            XCTAssertTrue(
                colorRep.hslString.contains("hsl("), "HSL representation should be generated")
            XCTAssertTrue(
                colorRep.hsvString.contains("hsv("), "HSV representation should be generated")
        case .failure(let error):
            XCTFail("Color representation creation should succeed, but failed with: \(error)")
        }
    }

    func testCreateColorRepresentation_FromHex() {
        let result = service.createColorRepresentation(from: .hex, value: "#00FF80")

        switch result {
        case .success(let colorRep):
            XCTAssertEqual(colorRep.rgb.red, 0, "RGB red component should be correct")
            XCTAssertEqual(colorRep.rgb.green, 255, "RGB green component should be correct")
            XCTAssertEqual(colorRep.rgb.blue, 128, "RGB blue component should be correct")
            XCTAssertEqual(colorRep.hex, "#00FF80", "Hex representation should be preserved")
        case .failure(let error):
            XCTFail("Color representation creation should succeed, but failed with: \(error)")
        }
    }

    // MARK: - Validation Tests

    func testValidateColorInput_ValidRGB() {
        let result = service.validateColorInput("rgb(255, 128, 64)", format: .rgb)
        XCTAssertTrue(result.isValid, "Valid RGB input should pass validation")
        XCTAssertNil(result.errorMessage, "Valid input should not have error message")
    }

    func testValidateColorInput_ValidHex() {
        let result = service.validateColorInput("#FF8040", format: .hex)
        XCTAssertTrue(result.isValid, "Valid hex input should pass validation")
        XCTAssertNil(result.errorMessage, "Valid input should not have error message")
    }

    func testValidateColorInput_InvalidRGB() {
        let result = service.validateColorInput("rgb(300, 128, 64)", format: .rgb)
        XCTAssertFalse(result.isValid, "Invalid RGB input should fail validation")
        XCTAssertNotNil(result.errorMessage, "Invalid input should have error message")
    }

    func testValidateColorInput_InvalidHex() {
        let result = service.validateColorInput("#GGGGGG", format: .hex)
        XCTAssertFalse(result.isValid, "Invalid hex input should fail validation")
        XCTAssertNotNil(result.errorMessage, "Invalid input should have error message")
    }

    // MARK: - Edge Cases and Error Handling

    func testRGBToHSL_EdgeCases() {
        // Test very small values
        let smallRGB = RGBColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        let smallHSL = service.rgbToHSL(smallRGB)
        XCTAssertEqual(
            smallHSL.saturation, 0, accuracy: 1.0, "Very small RGB values should have 0 saturation")

        // Test maximum values
        let maxRGB = RGBColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        let maxHSL = service.rgbToHSL(maxRGB)
        XCTAssertEqual(
            maxHSL.lightness, 100, accuracy: 1.0, "Maximum RGB values should have 100% lightness")
    }

    func testRGBToHSV_EdgeCases() {
        // Test very small values
        let smallRGB = RGBColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        let smallHSV = service.rgbToHSV(smallRGB)
        XCTAssertEqual(
            smallHSV.saturation, 0, accuracy: 1.0, "Very small RGB values should have 0 saturation")

        // Test maximum values
        let maxRGB = RGBColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        let maxHSV = service.rgbToHSV(maxRGB)
        XCTAssertEqual(
            maxHSV.value, 100, accuracy: 1.0, "Maximum RGB values should have 100% value")
    }

    func testErrorHandling_ClearsLastError() {
        // First, cause an error
        _ = service.convertColor(from: .rgb, to: .hsl, value: "invalid")
        XCTAssertNotNil(service.lastError, "Error should be stored")

        // Then, perform a successful operation
        _ = service.convertColor(from: .rgb, to: .hsl, value: "rgb(255, 0, 0)")
        XCTAssertNil(service.lastError, "Error should be cleared on successful operation")
    }

    // MARK: - Performance Tests

    func testRGBToHSLPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<1000 {
                _ = service.rgbToHSL(rgb)
            }
        }
    }

    func testRGBToHSVPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<1000 {
                _ = service.rgbToHSV(rgb)
            }
        }
    }

    func testColorConversionPerformance() {
        measure {
            for _ in 0..<100 {
                _ = service.convertColor(from: .rgb, to: .hsl, value: "rgb(128, 64, 192)")
                _ = service.convertColor(from: .rgb, to: .hsv, value: "rgb(128, 64, 192)")
                _ = service.convertColor(from: .hex, to: .rgb, value: "#8040C0")
            }
        }
    }

    // MARK: - Advanced Color Format Conversion Tests

    func testRGBToCMYK_PureColors() {
    // Test pure red
    let redRGB = RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0)
    let redCMYK = service.rgbToCMYK(redRGB)

    XCTAssertEqual(redCMYK.cyan, 0, accuracy: 1.0, "Pure red should have 0% cyan")
    XCTAssertEqual(redCMYK.magenta, 100, accuracy: 1.0, "Pure red should have 100% magenta")
    XCTAssertEqual(redCMYK.yellow, 100, accuracy: 1.0, "Pure red should have 100% yellow")
    XCTAssertEqual(redCMYK.key, 0, accuracy: 1.0, "Pure red should have 0% key")

    // Test pure green
    let greenRGB = RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0)
    let greenCMYK = service.rgbToCMYK(greenRGB)

    XCTAssertEqual(greenCMYK.cyan, 100, accuracy: 1.0, "Pure green should have 100% cyan")
    XCTAssertEqual(greenCMYK.magenta, 0, accuracy: 1.0, "Pure green should have 0% magenta")
    XCTAssertEqual(greenCMYK.yellow, 100, accuracy: 1.0, "Pure green should have 100% yellow")
    XCTAssertEqual(greenCMYK.key, 0, accuracy: 1.0, "Pure green should have 0% key")

    // Test pure blue
    let blueRGB = RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0)
    let blueCMYK = service.rgbToCMYK(blueRGB)

    XCTAssertEqual(blueCMYK.cyan, 100, accuracy: 1.0, "Pure blue should have 100% cyan")
    XCTAssertEqual(blueCMYK.magenta, 100, accuracy: 1.0, "Pure blue should have 100% magenta")
    XCTAssertEqual(blueCMYK.yellow, 0, accuracy: 1.0, "Pure blue should have 0% yellow")
    XCTAssertEqual(blueCMYK.key, 0, accuracy: 1.0, "Pure blue should have 0% key")
}

func testRGBToCMYK_BlackAndWhite() {
    // Test black
    let blackRGB = RGBColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    let blackCMYK = service.rgbToCMYK(blackRGB)

    XCTAssertEqual(blackCMYK.cyan, 0, accuracy: 1.0, "Black should have 0% cyan")
    XCTAssertEqual(blackCMYK.magenta, 0, accuracy: 1.0, "Black should have 0% magenta")
    XCTAssertEqual(blackCMYK.yellow, 0, accuracy: 1.0, "Black should have 0% yellow")
    XCTAssertEqual(blackCMYK.key, 100, accuracy: 1.0, "Black should have 100% key")

    // Test white
    let whiteRGB = RGBColor(red: 255, green: 255, blue: 255, alpha: 1.0)
    let whiteCMYK = service.rgbToCMYK(whiteRGB)

    XCTAssertEqual(whiteCMYK.cyan, 0, accuracy: 1.0, "White should have 0% cyan")
    XCTAssertEqual(whiteCMYK.magenta, 0, accuracy: 1.0, "White should have 0% magenta")
    XCTAssertEqual(whiteCMYK.yellow, 0, accuracy: 1.0, "White should have 0% yellow")
    XCTAssertEqual(whiteCMYK.key, 0, accuracy: 1.0, "White should have 0% key")
}

func testRGBToLAB_PureColors() {
    // Test pure red
    let redRGB = RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0)
    let redLAB = service.rgbToLAB(redRGB)

    XCTAssertEqual(redLAB.lightness, 53.2, accuracy: 2.0, "Pure red should have ~53 lightness")
    XCTAssertEqual(redLAB.a, 80.1, accuracy: 5.0, "Pure red should have positive a value")
    XCTAssertEqual(redLAB.b, 67.2, accuracy: 5.0, "Pure red should have positive b value")

    // Test pure green
    let greenRGB = RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0)
    let greenLAB = service.rgbToLAB(greenRGB)

    XCTAssertEqual(greenLAB.lightness, 87.7, accuracy: 2.0, "Pure green should have ~88 lightness")
    XCTAssertEqual(greenLAB.a, -86.2, accuracy: 5.0, "Pure green should have negative a value")
    XCTAssertEqual(greenLAB.b, 83.2, accuracy: 5.0, "Pure green should have positive b value")

    // Test pure blue
    let blueRGB = RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0)
    let blueLAB = service.rgbToLAB(blueRGB)

    XCTAssertEqual(blueLAB.lightness, 32.3, accuracy: 2.0, "Pure blue should have ~32 lightness")
    XCTAssertEqual(blueLAB.a, 79.2, accuracy: 5.0, "Pure blue should have positive a value")
    XCTAssertEqual(blueLAB.b, -107.9, accuracy: 5.0, "Pure blue should have negative b value")
}

func testRGBToLAB_BlackAndWhite() {
    // Test black
    let blackRGB = RGBColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    let blackLAB = service.rgbToLAB(blackRGB)

    XCTAssertEqual(blackLAB.lightness, 0, accuracy: 1.0, "Black should have 0 lightness")
    XCTAssertEqual(blackLAB.a, 0, accuracy: 1.0, "Black should have 0 a value")
    XCTAssertEqual(blackLAB.b, 0, accuracy: 1.0, "Black should have 0 b value")

    // Test white
    let whiteRGB = RGBColor(red: 255, green: 255, blue: 255, alpha: 1.0)
    let whiteLAB = service.rgbToLAB(whiteRGB)

    XCTAssertEqual(whiteLAB.lightness, 100, accuracy: 1.0, "White should have 100 lightness")
    XCTAssertEqual(whiteLAB.a, 0, accuracy: 1.0, "White should have ~0 a value")
    XCTAssertEqual(whiteLAB.b, 0, accuracy: 1.0, "White should have ~0 b value")
}

// MARK: - Advanced Format Conversion Tests

func testConvertColor_RGBToCMYK() {
    let result = service.convertColor(from: .rgb, to: .cmyk, value: "rgb(255, 128, 0)")

    switch result {
    case .success(let cmykString):
        XCTAssertTrue(cmykString.contains("cmyk("), "CMYK string should start with 'cmyk('")
        XCTAssertTrue(cmykString.contains("%"), "CMYK string should contain percentage signs")
    case .failure(let error):
        XCTFail("RGB to CMYK conversion should succeed, but failed with: \(error)")
    }
}

func testConvertColor_RGBToLAB() {
    let result = service.convertColor(from: .rgb, to: .lab, value: "rgb(128, 64, 192)")

    switch result {
    case .success(let labString):
        XCTAssertTrue(labString.contains("lab("), "LAB string should start with 'lab('")
    case .failure(let error):
        XCTFail("RGB to LAB conversion should succeed, but failed with: \(error)")
    }
}

func testConvertColor_CMYKToRGB() {
    let result = service.convertColor(from: .cmyk, to: .rgb, value: "cmyk(0%, 100%, 100%, 0%)")

    switch result {
    case .success(let rgbString):
        XCTAssertEqual(rgbString, "rgb(255, 0, 0)", "CMYK to RGB conversion should work correctly")
    case .failure(let error):
        XCTFail("CMYK to RGB conversion should succeed, but failed with: \(error)")
    }
}

func testConvertColor_LABToRGB() {
    let result = service.convertColor(from: .lab, to: .rgb, value: "lab(53.2, 80.1, 67.2)")

    switch result {
    case .success(let rgbString):
        XCTAssertTrue(rgbString.contains("rgb("), "LAB to RGB conversion should produce RGB string")
    case .failure(let error):
        XCTFail("LAB to RGB conversion should succeed, but failed with: \(error)")
    }
}

// MARK: - String Parsing Tests

func testParseCMYKString_Valid() {
    let testCases = [
        "cmyk(0%, 100%, 100%, 0%)",
        "cmyk(50%, 25%, 75%, 10%)",
        "cmyk(100%, 100%, 100%, 100%)",
    ]

    for testCase in testCases {
        let result = service.validateColorInput(testCase, format: .cmyk)
        XCTAssertTrue(result.isValid, "Valid CMYK string '\(testCase)' should pass validation")
    }
}

func testParseCMYKString_Invalid() {
    let testCases = [
        "cmyk(0, 100, 100, 0)",  // Missing % signs
        "cmyk(0%, 100%, 100%)",  // Missing component
        "cmyk(101%, 100%, 100%, 0%)",  // Out of range
        "invalid cmyk string",
    ]

    for testCase in testCases {
        let result = service.validateColorInput(testCase, format: .cmyk)
        XCTAssertFalse(result.isValid, "Invalid CMYK string '\(testCase)' should fail validation")
    }
}

func testParseLABString_Valid() {
    let testCases = [
        "lab(50, 0, 0)",
        "lab(100, -128, 127)",
        "lab(0, 50.5, -25.3)",
    ]

    for testCase in testCases {
        let result = service.validateColorInput(testCase, format: .lab)
        XCTAssertTrue(result.isValid, "Valid LAB string '\(testCase)' should pass validation")
    }
}

func testParseLABString_Invalid() {
    let testCases = [
        "lab(50, 0)",  // Missing component
        "lab(101, 0, 0)",  // L out of range
        "lab(50, 200, 0)",  // a out of range
        "lab(50, 0, -200)",  // b out of range
        "invalid lab string",
    ]

    for testCase in testCases {
        let result = service.validateColorInput(testCase, format: .lab)
        XCTAssertFalse(result.isValid, "Invalid LAB string '\(testCase)' should fail validation")
    }
}

// MARK: - Hex String Enhancement Tests

func testHexConversion_ThreeDigit() {
    let result = service.convertColor(from: .hex, to: .rgb, value: "#F0A")

    switch result {
    case .success(let rgbString):
        XCTAssertEqual(rgbString, "rgb(255, 0, 170)", "3-digit hex should expand correctly")
    case .failure(let error):
        XCTFail("3-digit hex conversion should succeed, but failed with: \(error)")
    }
}

func testHexConversion_SixDigit() {
    let result = service.convertColor(from: .hex, to: .rgb, value: "#FF8040")

    switch result {
    case .success(let rgbString):
        XCTAssertEqual(rgbString, "rgb(255, 128, 64)", "6-digit hex should convert correctly")
    case .failure(let error):
        XCTFail("6-digit hex conversion should succeed, but failed with: \(error)")
    }
}

func testHexConversion_EightDigit() {
    let result = service.convertColor(from: .hex, to: .rgb, value: "#FF804080")

    switch result {
    case .success(let rgbString):
        XCTAssertEqual(
            rgbString, "rgba(255, 128, 64, 0.50)", "8-digit hex with alpha should convert correctly"
        )
    case .failure(let error):
        XCTFail("8-digit hex conversion should succeed, but failed with: \(error)")
    }
}

func testRGBToHex_WithAlpha() {
    let result = service.convertColor(from: .rgb, to: .hex, value: "rgba(255, 128, 64, 0.5)")

    switch result {
    case .success(let hexString):
        XCTAssertEqual(hexString, "#FF804080", "RGBA to hex should include alpha channel")
    case .failure(let error):
        XCTFail("RGBA to hex conversion should succeed, but failed with: \(error)")
    }
}

// MARK: - Comprehensive Color Representation Tests

func testCreateColorRepresentation_AllFormats() {
    let result = service.createColorRepresentation(from: .rgb, value: "rgb(255, 128, 64)")

    switch result {
    case .success(let colorRep):
        // Verify all formats are populated
        XCTAssertEqual(colorRep.rgb.red, 255, "RGB red should be correct")
        XCTAssertEqual(colorRep.rgb.green, 128, "RGB green should be correct")
        XCTAssertEqual(colorRep.rgb.blue, 64, "RGB blue should be correct")

        XCTAssertEqual(colorRep.hex, "#FF8040", "Hex should be correct")

        XCTAssertTrue(colorRep.hslString.contains("hsl("), "HSL should be generated")
        XCTAssertTrue(colorRep.hsvString.contains("hsv("), "HSV should be generated")
        XCTAssertTrue(colorRep.cmykString.contains("cmyk("), "CMYK should be generated")
        XCTAssertTrue(colorRep.labString.contains("lab("), "LAB should be generated")

    case .failure(let error):
        XCTFail("Color representation creation should succeed, but failed with: \(error)")
    }
}

// MARK: - Performance Tests for Advanced Conversions

func testAdvancedConversionPerformance() {
    let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

    measure {
        for _ in 0..<100 {
            _ = service.rgbToCMYK(rgb)
            _ = service.rgbToLAB(rgb)
        }
    }
}

// MARK: - Bidirectional Conversion Tests

func testHSLToRGB_PureColors() {
    // Test pure red
    let redHSL = HSLColor(hue: 0, saturation: 100, lightness: 50, alpha: 1.0)
    let redRGB = service.hslToRGB(redHSL)

    XCTAssertEqual(redRGB.red, 255, accuracy: 1.0, "HSL red should convert to RGB red")
    XCTAssertEqual(redRGB.green, 0, accuracy: 1.0, "HSL red should have 0 green")
    XCTAssertEqual(redRGB.blue, 0, accuracy: 1.0, "HSL red should have 0 blue")
    XCTAssertEqual(redRGB.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")

    // Test pure green
    let greenHSL = HSLColor(hue: 120, saturation: 100, lightness: 50, alpha: 1.0)
    let greenRGB = service.hslToRGB(greenHSL)

    XCTAssertEqual(greenRGB.red, 0, accuracy: 1.0, "HSL green should have 0 red")
    XCTAssertEqual(greenRGB.green, 255, accuracy: 1.0, "HSL green should convert to RGB green")
    XCTAssertEqual(greenRGB.blue, 0, accuracy: 1.0, "HSL green should have 0 blue")

    // Test pure blue
    let blueHSL = HSLColor(hue: 240, saturation: 100, lightness: 50, alpha: 1.0)
    let blueRGB = service.hslToRGB(blueHSL)

    XCTAssertEqual(blueRGB.red, 0, accuracy: 1.0, "HSL blue should have 0 red")
    XCTAssertEqual(blueRGB.green, 0, accuracy: 1.0, "HSL blue should have 0 green")
    XCTAssertEqual(blueRGB.blue, 255, accuracy: 1.0, "HSL blue should convert to RGB blue")
}

func testHSVToRGB_PureColors() {
    // Test pure red
    let redHSV = HSVColor(hue: 0, saturation: 100, value: 100, alpha: 1.0)
    let redRGB = service.hsvToRGB(redHSV)

    XCTAssertEqual(redRGB.red, 255, accuracy: 1.0, "HSV red should convert to RGB red")
    XCTAssertEqual(redRGB.green, 0, accuracy: 1.0, "HSV red should have 0 green")
    XCTAssertEqual(redRGB.blue, 0, accuracy: 1.0, "HSV red should have 0 blue")
    XCTAssertEqual(redRGB.alpha, 1.0, accuracy: 0.01, "Alpha should be preserved")

    // Test pure green
    let greenHSV = HSVColor(hue: 120, saturation: 100, value: 100, alpha: 1.0)
    let greenRGB = service.hsvToRGB(greenHSV)

    XCTAssertEqual(greenRGB.red, 0, accuracy: 1.0, "HSV green should have 0 red")
    XCTAssertEqual(greenRGB.green, 255, accuracy: 1.0, "HSV green should convert to RGB green")
    XCTAssertEqual(greenRGB.blue, 0, accuracy: 1.0, "HSV green should have 0 blue")

    // Test pure blue
    let blueHSV = HSVColor(hue: 240, saturation: 100, value: 100, alpha: 1.0)
    let blueRGB = service.hsvToRGB(blueHSV)

    XCTAssertEqual(blueRGB.red, 0, accuracy: 1.0, "HSV blue should have 0 red")
    XCTAssertEqual(blueRGB.green, 0, accuracy: 1.0, "HSV blue should have 0 green")
    XCTAssertEqual(blueRGB.blue, 255, accuracy: 1.0, "HSV blue should convert to RGB blue")
}

func testCMYKToRGB_PureColors() {
    // Test pure red (0% cyan, 100% magenta, 100% yellow, 0% key)
    let redCMYK = CMYKColor(cyan: 0, magenta: 100, yellow: 100, key: 0)
    let redRGB = service.cmykToRGB(redCMYK)

    XCTAssertEqual(redRGB.red, 255, accuracy: 1.0, "CMYK red should convert to RGB red")
    XCTAssertEqual(redRGB.green, 0, accuracy: 1.0, "CMYK red should have 0 green")
    XCTAssertEqual(redRGB.blue, 0, accuracy: 1.0, "CMYK red should have 0 blue")

    // Test pure green (100% cyan, 0% magenta, 100% yellow, 0% key)
    let greenCMYK = CMYKColor(cyan: 100, magenta: 0, yellow: 100, key: 0)
    let greenRGB = service.cmykToRGB(greenCMYK)

    XCTAssertEqual(greenRGB.red, 0, accuracy: 1.0, "CMYK green should have 0 red")
    XCTAssertEqual(greenRGB.green, 255, accuracy: 1.0, "CMYK green should convert to RGB green")
    XCTAssertEqual(greenRGB.blue, 0, accuracy: 1.0, "CMYK green should have 0 blue")

    // Test pure blue (100% cyan, 100% magenta, 0% yellow, 0% key)
    let blueCMYK = CMYKColor(cyan: 100, magenta: 100, yellow: 0, key: 0)
    let blueRGB = service.cmykToRGB(blueCMYK)

    XCTAssertEqual(blueRGB.red, 0, accuracy: 1.0, "CMYK blue should have 0 red")
    XCTAssertEqual(blueRGB.green, 0, accuracy: 1.0, "CMYK blue should have 0 green")
    XCTAssertEqual(blueRGB.blue, 255, accuracy: 1.0, "CMYK blue should convert to RGB blue")

    // Test black (0% cyan, 0% magenta, 0% yellow, 100% key)
    let blackCMYK = CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 100)
    let blackRGB = service.cmykToRGB(blackCMYK)

    XCTAssertEqual(blackRGB.red, 0, accuracy: 1.0, "CMYK black should have 0 red")
    XCTAssertEqual(blackRGB.green, 0, accuracy: 1.0, "CMYK black should have 0 green")
    XCTAssertEqual(blackRGB.blue, 0, accuracy: 1.0, "CMYK black should have 0 blue")
}

// MARK: - Round-Trip Conversion Tests

func testRoundTripConversion_RGBToHSLToRGB() {
    let originalRGB = RGBColor(red: 128, green: 64, blue: 192, alpha: 0.8)

    // Convert RGB -> HSL -> RGB
    let hsl = service.rgbToHSL(originalRGB)
    let convertedRGB = service.hslToRGB(hsl)

    XCTAssertEqual(
        convertedRGB.red, originalRGB.red, accuracy: 2.0,
        "Round-trip RGB->HSL->RGB should preserve red")
    XCTAssertEqual(
        convertedRGB.green, originalRGB.green, accuracy: 2.0,
        "Round-trip RGB->HSL->RGB should preserve green")
    XCTAssertEqual(
        convertedRGB.blue, originalRGB.blue, accuracy: 2.0,
        "Round-trip RGB->HSL->RGB should preserve blue")
    XCTAssertEqual(
        convertedRGB.alpha, originalRGB.alpha, accuracy: 0.01,
        "Round-trip RGB->HSL->RGB should preserve alpha")
}

func testRoundTripConversion_RGBToHSVToRGB() {
    let originalRGB = RGBColor(red: 200, green: 100, blue: 50, alpha: 0.6)

    // Convert RGB -> HSV -> RGB
    let hsv = service.rgbToHSV(originalRGB)
    let convertedRGB = service.hsvToRGB(hsv)

    XCTAssertEqual(
        convertedRGB.red, originalRGB.red, accuracy: 2.0,
        "Round-trip RGB->HSV->RGB should preserve red")
    XCTAssertEqual(
        convertedRGB.green, originalRGB.green, accuracy: 2.0,
        "Round-trip RGB->HSV->RGB should preserve green")
    XCTAssertEqual(
        convertedRGB.blue, originalRGB.blue, accuracy: 2.0,
        "Round-trip RGB->HSV->RGB should preserve blue")
    XCTAssertEqual(
        convertedRGB.alpha, originalRGB.alpha, accuracy: 0.01,
        "Round-trip RGB->HSV->RGB should preserve alpha")
}

func testRoundTripConversion_RGBToCMYKToRGB() {
    let originalRGB = RGBColor(red: 180, green: 90, blue: 45, alpha: 1.0)

    // Convert RGB -> CMYK -> RGB
    let cmyk = service.rgbToCMYK(originalRGB)
    let convertedRGB = service.cmykToRGB(cmyk)

    XCTAssertEqual(
        convertedRGB.red, originalRGB.red, accuracy: 5.0,
        "Round-trip RGB->CMYK->RGB should preserve red")
    XCTAssertEqual(
        convertedRGB.green, originalRGB.green, accuracy: 5.0,
        "Round-trip RGB->CMYK->RGB should preserve green")
    XCTAssertEqual(
        convertedRGB.blue, originalRGB.blue, accuracy: 5.0,
        "Round-trip RGB->CMYK->RGB should preserve blue")
}

func testRoundTripConversion_RGBToLABToRGB() {
    let originalRGB = RGBColor(red: 150, green: 75, blue: 225, alpha: 1.0)

    // Convert RGB -> LAB -> RGB
    let lab = service.rgbToLAB(originalRGB)
    let convertedRGB = service.labToRGB(lab)

    // LAB conversion has more tolerance due to color space differences
    XCTAssertEqual(
        convertedRGB.red, originalRGB.red, accuracy: 10.0,
        "Round-trip RGB->LAB->RGB should preserve red")
    XCTAssertEqual(
        convertedRGB.green, originalRGB.green, accuracy: 10.0,
        "Round-trip RGB->LAB->RGB should preserve green")
    XCTAssertEqual(
        convertedRGB.blue, originalRGB.blue, accuracy: 10.0,
        "Round-trip RGB->LAB->RGB should preserve blue")
}

// MARK: - Universal Conversion Method Tests

func testUniversalConversion_AllFormats() {
    let testColor = "rgb(255, 128, 64)"

    let result = service.convertColorUniversal(from: .rgb, to: .hsl, value: testColor)

    switch result {
    case .success(let colorRep):
        // Verify all formats are populated correctly
        XCTAssertEqual(colorRep.rgb.red, 255, "Universal conversion should preserve RGB red")
        XCTAssertEqual(colorRep.rgb.green, 128, "Universal conversion should preserve RGB green")
        XCTAssertEqual(colorRep.rgb.blue, 64, "Universal conversion should preserve RGB blue")

        XCTAssertEqual(colorRep.hex, "#FF8040", "Universal conversion should generate correct hex")

        // Verify HSL values are reasonable
        XCTAssertGreaterThan(colorRep.hsl.hue, 0, "HSL hue should be positive")
        XCTAssertGreaterThan(colorRep.hsl.saturation, 0, "HSL saturation should be positive")
        XCTAssertGreaterThan(colorRep.hsl.lightness, 0, "HSL lightness should be positive")

        // Verify HSV values are reasonable
        XCTAssertGreaterThan(colorRep.hsv.hue, 0, "HSV hue should be positive")
        XCTAssertGreaterThan(colorRep.hsv.saturation, 0, "HSV saturation should be positive")
        XCTAssertGreaterThan(colorRep.hsv.value, 0, "HSV value should be positive")

        // Verify CMYK values are reasonable
        XCTAssertGreaterThanOrEqual(colorRep.cmyk.cyan, 0, "CMYK cyan should be non-negative")
        XCTAssertGreaterThanOrEqual(colorRep.cmyk.magenta, 0, "CMYK magenta should be non-negative")
        XCTAssertGreaterThanOrEqual(colorRep.cmyk.yellow, 0, "CMYK yellow should be non-negative")
        XCTAssertGreaterThanOrEqual(colorRep.cmyk.key, 0, "CMYK key should be non-negative")

    case .failure(let error):
        XCTFail("Universal conversion should succeed, but failed with: \(error)")
    }
}

func testUniversalConversion_InvalidInput() {
    let result = service.convertColorUniversal(from: .rgb, to: .hsl, value: "invalid color")

    switch result {
    case .success:
        XCTFail("Universal conversion should fail for invalid input")
    case .failure(let error):
        XCTAssertTrue(error.localizedDescription.contains("Invalid RGB color format"))
        XCTAssertEqual(service.lastError, error, "Service should store the last error")
    }
}

// MARK: - Integration Tests for All Conversions

func testAllFormatConversions_Integration() {
    let testCases: [(ColorFormat, String)] = [
        (.rgb, "rgb(255, 128, 64)"),
        (.hex, "#FF8040"),
        (.hsl, "hsl(30, 100%, 62%)"),
        (.hsv, "hsv(30, 75%, 100%)"),
        (.cmyk, "cmyk(0%, 50%, 75%, 0%)"),
        (.lab, "lab(70, 25, 45)"),
    ]

    for (sourceFormat, sourceValue) in testCases {
        for targetFormat in ColorFormat.allCases {
            let result = service.convertColor(
                from: sourceFormat, to: targetFormat, value: sourceValue)

            switch result {
            case .success(let convertedValue):
                XCTAssertFalse(
                    convertedValue.isEmpty,
                    "Conversion from \(sourceFormat) to \(targetFormat) should produce non-empty result"
                )

                // Verify the converted value has the expected format prefix
                switch targetFormat {
                case .rgb:
                    XCTAssertTrue(
                        convertedValue.hasPrefix("rgb"), "RGB conversion should start with 'rgb'")
                case .hex:
                    XCTAssertTrue(
                        convertedValue.hasPrefix("#"), "Hex conversion should start with '#'")
                case .hsl:
                    XCTAssertTrue(
                        convertedValue.hasPrefix("hsl"), "HSL conversion should start with 'hsl'")
                case .hsv:
                    XCTAssertTrue(
                        convertedValue.hasPrefix("hsv"), "HSV conversion should start with 'hsv'")
                case .cmyk:
                    XCTAssertTrue(
                        convertedValue.hasPrefix("cmyk"), "CMYK conversion should start with 'cmyk'"
                    )
                case .lab:
                    XCTAssertTrue(
                        convertedValue.hasPrefix("lab"), "LAB conversion should start with 'lab'")
                }

            case .failure(let error):
                XCTFail(
                    "Conversion from \(sourceFormat) to \(targetFormat) should succeed, but failed with: \(error)"
                )
            }
        }
    }
}

// MARK: - Performance Tests for Bidirectional Conversions

func testBidirectionalConversionPerformance() {
    let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)
    let hsl = HSLColor(hue: 270, saturation: 75, lightness: 50, alpha: 1.0)
    let hsv = HSVColor(hue: 270, saturation: 67, value: 75, alpha: 1.0)
    let cmyk = CMYKColor(cyan: 33, magenta: 67, yellow: 0, key: 25)
    let lab = LABColor(lightness: 45, a: 35, b: -65)

    measure {
        for _ in 0..<50 {
            _ = service.hslToRGB(hsl)
            _ = service.hsvToRGB(hsv)
            _ = service.cmykToRGB(cmyk)
            _ = service.labToRGB(lab)
            _ = service.rgbToHSL(rgb)
            _ = service.rgbToHSV(rgb)
            _ = service.rgbToCMYK(rgb)
            _ = service.rgbToLAB(rgb)
        }
    }
}
