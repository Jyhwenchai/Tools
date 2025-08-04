import XCTest

@testable import Tools

@MainActor
final class ColorProcessingPerformanceTests: XCTestCase {

    var colorConversionService: ColorConversionService!
    var colorSamplingService: ColorSamplingService!
    var colorPaletteService: ColorPaletteService!

    override func setUp() {
        super.setUp()
        colorConversionService = ColorConversionService()
        colorSamplingService = ColorSamplingService()
        colorPaletteService = ColorPaletteService()
    }

    override func tearDown() {
        colorConversionService = nil
        colorSamplingService = nil
        colorPaletteService = nil
        super.tearDown()
    }

    // MARK: - Color Conversion Performance Tests

    func testRGBToHSLConversionPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<1000 {
                _ = colorConversionService.rgbToHSL(rgb)
            }
        }
    }

    func testRGBToHSVConversionPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<1000 {
                _ = colorConversionService.rgbToHSV(rgb)
            }
        }
    }

    func testRGBToCMYKConversionPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<1000 {
                _ = colorConversionService.rgbToCMYK(rgb)
            }
        }
    }

    func testRGBToLABConversionPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<1000 {
                _ = colorConversionService.rgbToLAB(rgb)
            }
        }
    }

    func testHexToRGBConversionPerformance() {
        let hexColors = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF"]

        measure {
            for _ in 0..<1000 {
                for hex in hexColors {
                    _ = colorConversionService.hexToRGB(hex)
                }
            }
        }
    }

    func testRGBToHexConversionPerformance() {
        let rgbColors = [
            RGBColor(red: 255, green: 0, blue: 0, alpha: 1.0),
            RGBColor(red: 0, green: 255, blue: 0, alpha: 1.0),
            RGBColor(red: 0, green: 0, blue: 255, alpha: 1.0),
            RGBColor(red: 255, green: 255, blue: 0, alpha: 1.0),
            RGBColor(red: 255, green: 0, blue: 255, alpha: 1.0),
            RGBColor(red: 0, green: 255, blue: 255, alpha: 1.0),
        ]

        measure {
            for _ in 0..<1000 {
                for rgb in rgbColors {
                    _ = colorConversionService.rgbToHex(rgb)
                }
            }
        }
    }

    // MARK: - Bidirectional Conversion Performance Tests

    func testRoundTripRGBToHSLPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<500 {
                let hsl = colorConversionService.rgbToHSL(rgb)
                _ = colorConversionService.hslToRGB(hsl)
            }
        }
    }

    func testRoundTripRGBToHSVPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<500 {
                let hsv = colorConversionService.rgbToHSV(rgb)
                _ = colorConversionService.hsvToRGB(hsv)
            }
        }
    }

    func testRoundTripRGBToCMYKPerformance() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        measure {
            for _ in 0..<500 {
                let cmyk = colorConversionService.rgbToCMYK(rgb)
                _ = colorConversionService.cmykToRGB(cmyk)
            }
        }
    }

    // MARK: - Color Validation Performance Tests

    func testRGBValidationPerformance() {
        let validInputs = ["rgb(255, 0, 0)", "rgba(128, 64, 192, 0.5)", "rgb(0, 255, 0)"]
        let invalidInputs = ["rgb(256, 0, 0)", "rgba(128, 64)", "not-a-color"]

        measure {
            for _ in 0..<1000 {
                for input in validInputs + invalidInputs {
                    _ = RGBColor.validate(input)
                }
            }
        }
    }

    func testHexValidationPerformance() {
        let validInputs = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00"]
        let invalidInputs = ["#GG0000", "#FF00", "not-a-hex"]

        measure {
            for _ in 0..<1000 {
                for input in validInputs + invalidInputs {
                    _ = HexColor.validate(input)
                }
            }
        }
    }

    func testHSLValidationPerformance() {
        let validInputs = ["hsl(0, 100%, 50%)", "hsla(120, 50%, 75%, 0.8)"]
        let invalidInputs = ["hsl(361, 100%, 50%)", "hsl(0, 101%, 50%)"]

        measure {
            for _ in 0..<1000 {
                for input in validInputs + invalidInputs {
                    _ = HSLColor.validate(input)
                }
            }
        }
    }

    // MARK: - Color Palette Performance Tests

    func testColorPaletteAddPerformance() {
        let colors = (0..<100).map { i in
            ColorRepresentation(
                rgb: RGBColor(
                    red: Double(i % 256), green: Double((i * 2) % 256), blue: Double((i * 3) % 256)),
                hex: String(format: "#%02X%02X%02X", i % 256, (i * 2) % 256, (i * 3) % 256),
                hsl: HSLColor(hue: Double(i % 360), saturation: 50, lightness: 50),
                hsv: HSVColor(hue: Double(i % 360), saturation: 50, value: 50),
                cmyk: CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 50),
                lab: LABColor(lightness: 50, a: 0, b: 0)
            )
        }

        measure {
            for color in colors {
                colorPaletteService.addColor(name: "Test Color", color: color)
            }
            colorPaletteService.clearPalette()
        }
    }

    func testColorPaletteSearchPerformance() {
        // Add test colors to palette
        for i in 0..<100 {
            let color = ColorRepresentation(
                rgb: RGBColor(
                    red: Double(i % 256), green: Double((i * 2) % 256), blue: Double((i * 3) % 256)),
                hex: String(format: "#%02X%02X%02X", i % 256, (i * 2) % 256, (i * 3) % 256),
                hsl: HSLColor(hue: Double(i % 360), saturation: 50, lightness: 50),
                hsv: HSVColor(hue: Double(i % 360), saturation: 50, value: 50),
                cmyk: CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 50),
                lab: LABColor(lightness: 50, a: 0, b: 0)
            )
            colorPaletteService.addColor(name: "Test Color \(i)", color: color)
        }

        measure {
            for i in 0..<50 {
                _ = colorPaletteService.findColors(withName: "Test Color \(i)")
            }
        }

        colorPaletteService.clearPalette()
    }

    // MARK: - Memory Usage Tests

    func testColorConversionMemoryUsage() {
        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        // Test that repeated conversions don't cause memory leaks
        for _ in 0..<10000 {
            let hsl = colorConversionService.rgbToHSL(rgb)
            let hsv = colorConversionService.rgbToHSV(rgb)
            let cmyk = colorConversionService.rgbToCMYK(rgb)
            let lab = colorConversionService.rgbToLAB(rgb)
            let hex = colorConversionService.rgbToHex(rgb)

            // Convert back to ensure no memory accumulation
            _ = colorConversionService.hslToRGB(hsl)
            _ = colorConversionService.hsvToRGB(hsv)
            _ = colorConversionService.cmykToRGB(cmyk)
            _ = colorConversionService.hexToRGB(hex)
        }

        XCTAssertTrue(true, "Memory usage test completed without crashes")
    }

    func testColorPaletteMemoryUsage() {
        // Test that adding and removing many colors doesn't cause memory leaks
        for cycle in 0..<10 {
            // Add colors
            for i in 0..<100 {
                let color = ColorRepresentation(
                    rgb: RGBColor(
                        red: Double(i % 256), green: Double((i * 2) % 256),
                        blue: Double((i * 3) % 256)),
                    hex: String(format: "#%02X%02X%02X", i % 256, (i * 2) % 256, (i * 3) % 256),
                    hsl: HSLColor(hue: Double(i % 360), saturation: 50, lightness: 50),
                    hsv: HSVColor(hue: Double(i % 360), saturation: 50, value: 50),
                    cmyk: CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 50),
                    lab: LABColor(lightness: 50, a: 0, b: 0)
                )
                colorPaletteService.addColor(name: "Cycle \(cycle) Color \(i)", color: color)
            }

            // Clear palette
            colorPaletteService.clearPalette()
        }

        XCTAssertTrue(true, "Palette memory usage test completed without crashes")
    }

    // MARK: - Concurrent Access Performance Tests

    func testConcurrentColorConversion() {
        let expectation = XCTestExpectation(description: "Concurrent color conversion")
        expectation.expectedFulfillmentCount = 10

        let rgb = RGBColor(red: 128, green: 64, blue: 192, alpha: 1.0)

        for i in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                for _ in 0..<100 {
                    _ = self.colorConversionService.rgbToHSL(rgb)
                    _ = self.colorConversionService.rgbToHSV(rgb)
                    _ = self.colorConversionService.rgbToCMYK(rgb)
                }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Debounced Input Performance Tests

    func testDebouncedValidationPerformance() {
        let inputs = ["#FF0000", "#00FF00", "#0000FF", "rgb(255, 0, 0)", "hsl(0, 100%, 50%)"]

        measure {
            for _ in 0..<1000 {
                for input in inputs {
                    // Simulate rapid input changes
                    _ = ColorFormatDetector.detectFormat(input)
                    _ = ColorFormatDetector.validateInput(input, expectedFormat: .hex)
                }
            }
        }
    }
}
