import XCTest

@testable import Tools

@MainActor
final class ColorProcessingPerformanceTests: XCTestCase {

    // MARK: - Test Properties

    var colorConversionService: ColorConversionService!
    var colorSamplingService: ColorSamplingService!

    override func setUp() {
        super.setUp()
        colorConversionService = ColorConversionService()
        colorSamplingService = ColorSamplingService()
    }

    override func tearDown() {
        colorConversionService = nil
        colorSamplingService = nil
        super.tearDown()
    }

    // MARK: - Color Conversion Performance Tests

    func testRGBToHexConversionPerformance() {
        let rgbValues = (0..<1000).map { i in
            "rgb(\(i % 256), \((i * 2) % 256), \((i * 3) % 256))"
        }

        measure {
            for rgbValue in rgbValues {
                _ = colorConversionService.createColorRepresentation(
                    from: .rgb, value: rgbValue)
            }
        }
    }

    func testHexToRGBConversionPerformance() {
        let hexValues = (0..<1000).map { i in
            String(format: "#%02X%02X%02X", i % 256, (i * 2) % 256, (i * 3) % 256)
        }

        measure {
            for hexValue in hexValues {
                _ = colorConversionService.createColorRepresentation(
                    from: .hex, value: hexValue)
            }
        }
    }

    func testHSLConversionPerformance() {
        let hslValues = (0..<1000).map { i in
            "hsl(\(i % 360), \((i * 2) % 100)%, \((i * 3) % 100)%)"
        }

        measure {
            for hslValue in hslValues {
                _ = colorConversionService.createColorRepresentation(
                    from: .hsl, value: hslValue)
            }
        }
    }

    func testHSVConversionPerformance() {
        let hsvValues = (0..<1000).map { i in
            "hsv(\(i % 360), \((i * 2) % 100)%, \((i * 3) % 100)%)"
        }

        measure {
            for hsvValue in hsvValues {
                _ = colorConversionService.createColorRepresentation(
                    from: .hsv, value: hsvValue)
            }
        }
    }

    func testCMYKConversionPerformance() {
        let cmykValues = (0..<1000).map { i in
            "cmyk(\(i % 100)%, \((i * 2) % 100)%, \((i * 3) % 100)%, \((i * 4) % 100)%)"
        }

        measure {
            for cmykValue in cmykValues {
                _ = colorConversionService.createColorRepresentation(
                    from: .cmyk, value: cmykValue)
            }
        }
    }

    func testLABConversionPerformance() {
        let labValues = (0..<1000).map { i in
            "lab(\(i % 100), \((i * 2) % 128 - 64), \((i * 3) % 128 - 64))"
        }

        measure {
            for labValue in labValues {
                _ = colorConversionService.createColorRepresentation(
                    from: .lab, value: labValue)
            }
        }
    }

    // MARK: - Color Validation Performance Tests

    func testColorValidationPerformance() {
        let testInputs = [
            ("rgb", (0..<1000).map { i in "rgb(\(i % 256), \((i * 2) % 256), \((i * 3) % 256))" }),
            (
                "hex",
                (0..<1000).map { i in
                    String(format: "#%02X%02X%02X", i % 256, (i * 2) % 256, (i * 3) % 256)
                }
            ),
            (
                "hsl",
                (0..<1000).map { i in "hsl(\(i % 360), \((i * 2) % 100)%, \((i * 3) % 100)%)" }
            ),
            (
                "hsv",
                (0..<1000).map { i in "hsv(\(i % 360), \((i * 2) % 100)%, \((i * 3) % 100)%)" }
            ),
            (
                "cmyk",
                (0..<1000).map { i in
                    "cmyk(\(i % 100)%, \((i * 2) % 100)%, \((i * 3) % 100)%, \((i * 4) % 100)%)"
                }
            ),
            (
                "lab",
                (0..<1000).map { i in
                    "lab(\(i % 100), \((i * 2) % 128 - 64), \((i * 3) % 128 - 64))"
                }
            ),
        ]

        for (formatName, inputs) in testInputs {
            measure(metrics: [XCTClockMetric()]) {
                for input in inputs {
                    let format = ColorFormat(rawValue: formatName.uppercased()) ?? .rgb
                    _ = ColorFormatDetector.validateInput(input, expectedFormat: format)
                }
            }
        }
    }

    // MARK: - Color Format Detection Performance Tests

    func testColorFormatDetectionPerformance() {
        let mixedInputs = [
            "rgb(255, 0, 0)", "#FF0000", "hsl(0, 100%, 50%)",
            "hsv(0, 100%, 100%)", "cmyk(0%, 100%, 100%, 0%)",
            "lab(53, 80, 67)", "rgba(255, 0, 0, 0.5)",
            "#FF0000FF", "hsla(0, 100%, 50%, 0.5)",
        ]

        let testData = (0..<1000).map { i in
            mixedInputs[i % mixedInputs.count]
        }

        measure {
            for input in testData {
                _ = ColorFormatDetector.detectFormat(input)
            }
        }
    }

    // MARK: - Memory Usage Tests

    func testColorConversionMemoryUsage() {
        // Test that repeated conversions don't cause memory leaks
        measure(metrics: [XCTMemoryMetric()]) {
            for i in 0..<10000 {
                let rgbValue = "rgb(\(i % 256), \((i * 2) % 256), \((i * 3) % 256))"
                _ = colorConversionService.createColorRepresentation(
                    from: .rgb, value: rgbValue)
            }
        }
    }

    // MARK: - Concurrent Processing Tests

    func testConcurrentColorConversion() {
        let expectation = XCTestExpectation(description: "Concurrent conversion")
        expectation.expectedFulfillmentCount = 10

        measure {
            for i in 0..<10 {
                DispatchQueue.global().async {
                    let rgbValue = "rgb(\(i * 25), \(i * 25), \(i * 25))"
                    _ = self.colorConversionService.createColorRepresentation(
                        from: .rgb, value: rgbValue)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Error Handling Performance Tests

    func testErrorHandlingPerformance() {
        let invalidInputs = [
            "invalid", "rgb()", "hex(#)", "hsl(invalid)",
            "hsv(999, 999, 999)", "cmyk(200%, 200%, 200%, 200%)",
            "lab(200, 300, 300)", "", "   ", "null",
        ]

        measure {
            for input in invalidInputs {
                for format in ColorFormat.allCases {
                    _ = colorConversionService.createColorRepresentation(
                        from: format, value: input)
                }
            }
        }
    }

    // MARK: - Large Dataset Tests

    func testLargeDatasetProcessing() {
        let largeDataset = (0..<10000).map { i in
            "rgb(\(i % 256), \((i * 2) % 256), \((i * 3) % 256))"
        }

        measure {
            let results = largeDataset.compactMap { rgbValue in
                colorConversionService.createColorRepresentation(
                    from: .rgb, value: rgbValue)
            }
            XCTAssertEqual(results.count, largeDataset.count)
        }
    }

    // MARK: - Stress Tests

    func testColorConversionStressTest() {
        // Stress test with rapid successive conversions
        measure {
            for _ in 0..<1000 {
                let randomR = Int.random(in: 0...255)
                let randomG = Int.random(in: 0...255)
                let randomB = Int.random(in: 0...255)
                let rgbValue = "rgb(\(randomR), \(randomG), \(randomB))"

                let result = colorConversionService.createColorRepresentation(
                    from: .rgb, value: rgbValue)

                switch result {
                case .success(let color):
                    XCTAssertEqual(Int(color.rgb.red), randomR)
                    XCTAssertEqual(Int(color.rgb.green), randomG)
                    XCTAssertEqual(Int(color.rgb.blue), randomB)
                case .failure:
                    XCTFail("Valid RGB conversion should not fail")
                }
            }
        }
    }
}
