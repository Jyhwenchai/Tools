import Foundation
import SwiftUI

// MARK: - Color Format Enumeration

/// Supported color formats for conversion
enum ColorFormat: String, CaseIterable {
    case rgb = "RGB"
    case hex = "Hex"
    case hsl = "HSL"
    case hsv = "HSV"
    case cmyk = "CMYK"
    case lab = "LAB"
}

// MARK: - Color Format Structures

/// RGB color representation (0-255 for RGB, 0-1 for alpha)
struct RGBColor: Equatable, Codable {
    let red: Double  // 0-255
    let green: Double  // 0-255
    let blue: Double  // 0-255
    let alpha: Double  // 0-1

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = max(0, min(255, red))
        self.green = max(0, min(255, green))
        self.blue = max(0, min(255, blue))
        self.alpha = max(0, min(1, alpha))
    }
}

/// HSL color representation (0-360 for hue, 0-100 for saturation/lightness, 0-1 for alpha)
struct HSLColor: Equatable, Codable {
    let hue: Double  // 0-360
    let saturation: Double  // 0-100
    let lightness: Double  // 0-100
    let alpha: Double  // 0-1

    init(hue: Double, saturation: Double, lightness: Double, alpha: Double = 1.0) {
        self.hue = max(0, min(360, hue))
        self.saturation = max(0, min(100, saturation))
        self.lightness = max(0, min(100, lightness))
        self.alpha = max(0, min(1, alpha))
    }
}

/// HSV color representation (0-360 for hue, 0-100 for saturation/value, 0-1 for alpha)
struct HSVColor: Equatable, Codable {
    let hue: Double  // 0-360
    let saturation: Double  // 0-100
    let value: Double  // 0-100
    let alpha: Double  // 0-1

    init(hue: Double, saturation: Double, value: Double, alpha: Double = 1.0) {
        self.hue = max(0, min(360, hue))
        self.saturation = max(0, min(100, saturation))
        self.value = max(0, min(100, value))
        self.alpha = max(0, min(1, alpha))
    }
}

/// CMYK color representation (0-100 for all components)
struct CMYKColor: Equatable, Codable {
    let cyan: Double  // 0-100
    let magenta: Double  // 0-100
    let yellow: Double  // 0-100
    let key: Double  // 0-100 (black)

    init(cyan: Double, magenta: Double, yellow: Double, key: Double) {
        self.cyan = max(0, min(100, cyan))
        self.magenta = max(0, min(100, magenta))
        self.yellow = max(0, min(100, yellow))
        self.key = max(0, min(100, key))
    }
}

/// LAB color representation (0-100 for L, -128 to 127 for a and b)
struct LABColor: Equatable, Codable {
    let lightness: Double  // 0-100
    let a: Double  // -128 to 127
    let b: Double  // -128 to 127

    init(lightness: Double, a: Double, b: Double) {
        self.lightness = max(0, min(100, lightness))
        self.a = max(-128, min(127, a))
        self.b = max(-128, min(127, b))
    }
}

// MARK: - Comprehensive Color Representation

/// Complete color representation containing all supported formats
struct ColorRepresentation: Equatable, Codable {
    let rgb: RGBColor
    let hex: String
    let hsl: HSLColor
    let hsv: HSVColor
    let cmyk: CMYKColor
    let lab: LABColor

    // MARK: - Formatted String Properties

    var rgbString: String {
        if rgb.alpha < 1.0 {
            return
                "rgba(\(Int(rgb.red)), \(Int(rgb.green)), \(Int(rgb.blue)), \(String(format: "%.2f", rgb.alpha)))"
        } else {
            return "rgb(\(Int(rgb.red)), \(Int(rgb.green)), \(Int(rgb.blue)))"
        }
    }

    var hexString: String {
        return hex
    }

    var hslString: String {
        if hsl.alpha < 1.0 {
            return
                "hsla(\(Int(hsl.hue)), \(Int(hsl.saturation))%, \(Int(hsl.lightness))%, \(String(format: "%.2f", hsl.alpha)))"
        } else {
            return "hsl(\(Int(hsl.hue)), \(Int(hsl.saturation))%, \(Int(hsl.lightness))%)"
        }
    }

    var hsvString: String {
        if hsv.alpha < 1.0 {
            return
                "hsva(\(Int(hsv.hue)), \(Int(hsv.saturation))%, \(Int(hsv.value))%, \(String(format: "%.2f", hsv.alpha)))"
        } else {
            return "hsv(\(Int(hsv.hue)), \(Int(hsv.saturation))%, \(Int(hsv.value))%)"
        }
    }

    var cmykString: String {
        return
            "cmyk(\(Int(cmyk.cyan))%, \(Int(cmyk.magenta))%, \(Int(cmyk.yellow))%, \(Int(cmyk.key))%)"
    }

    var labString: String {
        return
            "lab(\(String(format: "%.1f", lab.lightness)), \(String(format: "%.1f", lab.a)), \(String(format: "%.1f", lab.b)))"
    }
}

// MARK: - Validation Models

/// Result of color input validation
enum ValidationResult: Equatable {
    case valid
    case invalid(reason: String)

    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let reason):
            return reason
        }
    }
}

// MARK: - Color Processing Protocols

/// Protocol for color format conversion
protocol ColorConvertible {
    func toRGB() -> RGBColor
    func toColorRepresentation() -> ColorRepresentation
}

/// Protocol for color validation
protocol ColorValidatable {
    static func validate(_ input: String) -> ValidationResult
    static func sanitize(_ input: String) -> String
}

/// Protocol for color sampling
protocol ColorSamplable {
    func startSampling() async -> Result<Void, ColorProcessingError>
    func stopSampling()
    func sampleColorAt(point: CGPoint) -> Result<ColorRepresentation, ColorProcessingError>
}

// MARK: - Color Format Validation Extensions

extension RGBColor: ColorValidatable {
    static func validate(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)

        // Check for rgb() or rgba() format
        let rgbPattern =
            #"^rgba?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)$"#
        let regex = try! NSRegularExpression(pattern: rgbPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sanitized.count)

        guard let match = regex.firstMatch(in: sanitized, options: [], range: range) else {
            return .invalid(
                reason: "Invalid RGB format. Expected: rgb(r, g, b) or rgba(r, g, b, a)")
        }

        let components: [Double] = (1...4).compactMap { index in
            guard match.range(at: index).location != NSNotFound else { return nil }
            let range = Range(match.range(at: index), in: sanitized)!
            return Double(String(sanitized[range]))
        }

        guard components.count >= 3 else {
            return .invalid(reason: "RGB requires at least 3 components")
        }

        // Validate RGB values (0-255)
        for (index, value) in components.prefix(3).enumerated() {
            if value < 0 || value > 255 {
                let component = ["red", "green", "blue"][index]
                return .invalid(
                    reason: "Invalid \(component) value: \(value). Expected range: 0-255")
            }
        }

        // Validate alpha if present (0-1)
        if components.count > 3 {
            let alpha = components[3]
            if alpha < 0 || alpha > 1 {
                return .invalid(reason: "Invalid alpha value: \(alpha). Expected range: 0-1")
            }
        }

        return .valid
    }

    static func sanitize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension HSLColor: ColorValidatable {
    static func validate(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)

        // Check for hsl() or hsla() format
        let hslPattern =
            #"^hsla?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)$"#
        let regex = try! NSRegularExpression(pattern: hslPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sanitized.count)

        guard let match = regex.firstMatch(in: sanitized, options: [], range: range) else {
            return .invalid(
                reason: "Invalid HSL format. Expected: hsl(h, s%, l%) or hsla(h, s%, l%, a)")
        }

        let components: [Double] = (1...4).compactMap { index in
            guard match.range(at: index).location != NSNotFound else { return nil }
            let range = Range(match.range(at: index), in: sanitized)!
            return Double(String(sanitized[range]))
        }

        guard components.count >= 3 else {
            return .invalid(reason: "HSL requires at least 3 components")
        }

        // Validate hue (0-360)
        let hue = components[0]
        if hue < 0 || hue > 360 {
            return .invalid(reason: "Invalid hue value: \(hue). Expected range: 0-360")
        }

        // Validate saturation and lightness (0-100)
        for (index, value) in components[1...2].enumerated() {
            if value < 0 || value > 100 {
                let component = index == 0 ? "saturation" : "lightness"
                return .invalid(
                    reason: "Invalid \(component) value: \(value)%. Expected range: 0-100%")
            }
        }

        // Validate alpha if present (0-1)
        if components.count > 3 {
            let alpha = components[3]
            if alpha < 0 || alpha > 1 {
                return .invalid(reason: "Invalid alpha value: \(alpha). Expected range: 0-1")
            }
        }

        return .valid
    }

    static func sanitize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension HSVColor: ColorValidatable {
    static func validate(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)

        // Check for hsv() or hsva() format
        let hsvPattern =
            #"^hsva?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)$"#
        let regex = try! NSRegularExpression(pattern: hsvPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sanitized.count)

        guard let match = regex.firstMatch(in: sanitized, options: [], range: range) else {
            return .invalid(
                reason: "Invalid HSV format. Expected: hsv(h, s%, v%) or hsva(h, s%, v%, a)")
        }

        let components: [Double] = (1...4).compactMap { index in
            guard match.range(at: index).location != NSNotFound else { return nil }
            let range = Range(match.range(at: index), in: sanitized)!
            return Double(String(sanitized[range]))
        }

        guard components.count >= 3 else {
            return .invalid(reason: "HSV requires at least 3 components")
        }

        // Validate hue (0-360)
        let hue = components[0]
        if hue < 0 || hue > 360 {
            return .invalid(reason: "Invalid hue value: \(hue). Expected range: 0-360")
        }

        // Validate saturation and value (0-100)
        for (index, value) in components[1...2].enumerated() {
            if value < 0 || value > 100 {
                let component = index == 0 ? "saturation" : "value"
                return .invalid(
                    reason: "Invalid \(component) value: \(value)%. Expected range: 0-100%")
            }
        }

        // Validate alpha if present (0-1)
        if components.count > 3 {
            let alpha = components[3]
            if alpha < 0 || alpha > 1 {
                return .invalid(reason: "Invalid alpha value: \(alpha). Expected range: 0-1")
            }
        }

        return .valid
    }

    static func sanitize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension CMYKColor: ColorValidatable {
    static func validate(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)

        // Check for cmyk() format
        let cmykPattern =
            #"^cmyk\(\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*\)$"#
        let regex = try! NSRegularExpression(pattern: cmykPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sanitized.count)

        guard let match = regex.firstMatch(in: sanitized, options: [], range: range) else {
            return .invalid(reason: "Invalid CMYK format. Expected: cmyk(c%, m%, y%, k%)")
        }

        let components: [Double] = (1...4).compactMap { index in
            let range = Range(match.range(at: index), in: sanitized)!
            return Double(String(sanitized[range]))
        }

        guard components.count == 4 else {
            return .invalid(reason: "CMYK requires exactly 4 components")
        }

        // Validate all components (0-100)
        let componentNames = ["cyan", "magenta", "yellow", "key"]
        for (index, value) in components.enumerated() {
            if value < 0 || value > 100 {
                return .invalid(
                    reason:
                        "Invalid \(componentNames[index]) value: \(value)%. Expected range: 0-100%")
            }
        }

        return .valid
    }

    static func sanitize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension LABColor: ColorValidatable {
    static func validate(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)

        // Check for lab() format
        let labPattern =
            #"^lab\(\s*(\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)$"#
        let regex = try! NSRegularExpression(pattern: labPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sanitized.count)

        guard let match = regex.firstMatch(in: sanitized, options: [], range: range) else {
            return .invalid(reason: "Invalid LAB format. Expected: lab(l, a, b)")
        }

        let components: [Double] = (1...3).compactMap { index in
            let range = Range(match.range(at: index), in: sanitized)!
            return Double(String(sanitized[range]))
        }

        guard components.count == 3 else {
            return .invalid(reason: "LAB requires exactly 3 components")
        }

        // Validate lightness (0-100)
        let lightness = components[0]
        if lightness < 0 || lightness > 100 {
            return .invalid(reason: "Invalid lightness value: \(lightness). Expected range: 0-100")
        }

        // Validate a and b components (-128 to 127)
        for (index, value) in components[1...2].enumerated() {
            if value < -128 || value > 127 {
                let component = index == 0 ? "a" : "b"
                return .invalid(
                    reason: "Invalid \(component) value: \(value). Expected range: -128 to 127")
            }
        }

        return .valid
    }

    static func sanitize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Hex Color Validation

struct HexColor: ColorValidatable {
    static func validate(_ input: String) -> ValidationResult {
        let sanitized = sanitize(input)

        // Check for hex format (#RGB, #RRGGBB, #RRGGBBAA)
        let hexPattern = #"^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$"#
        let regex = try! NSRegularExpression(pattern: hexPattern, options: [])
        let range = NSRange(location: 0, length: sanitized.count)

        guard regex.firstMatch(in: sanitized, options: [], range: range) != nil else {
            return .invalid(reason: "Invalid hex format. Expected: #RGB, #RRGGBB, or #RRGGBBAA")
        }

        return .valid
    }

    static func sanitize(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        // Add # prefix if missing
        return trimmed.hasPrefix("#") ? trimmed : "#" + trimmed
    }
}

// MARK: - Format Detection Utility

struct ColorFormatDetector {
    static func detectFormat(_ input: String) -> ColorFormat? {
        let sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if sanitized.hasPrefix("#")
            || sanitized.range(of: #"^[0-9a-f]{3,8}$"#, options: .regularExpression) != nil
        {
            return .hex
        } else if sanitized.hasPrefix("rgb") {
            return .rgb
        } else if sanitized.hasPrefix("hsl") {
            return .hsl
        } else if sanitized.hasPrefix("hsv") {
            return .hsv
        } else if sanitized.hasPrefix("cmyk") {
            return .cmyk
        } else if sanitized.hasPrefix("lab") {
            return .lab
        }

        return nil
    }

    static func validateInput(_ input: String, expectedFormat: ColorFormat) -> ValidationResult {
        switch expectedFormat {
        case .rgb:
            return RGBColor.validate(input)
        case .hex:
            return HexColor.validate(input)
        case .hsl:
            return HSLColor.validate(input)
        case .hsv:
            return HSVColor.validate(input)
        case .cmyk:
            return CMYKColor.validate(input)
        case .lab:
            return LABColor.validate(input)
        }
    }

    static func sanitizeInput(_ input: String, format: ColorFormat) -> String {
        switch format {
        case .rgb:
            return RGBColor.sanitize(input)
        case .hex:
            return HexColor.sanitize(input)
        case .hsl:
            return HSLColor.sanitize(input)
        case .hsv:
            return HSVColor.sanitize(input)
        case .cmyk:
            return CMYKColor.sanitize(input)
        case .lab:
            return LABColor.sanitize(input)
        }
    }
}

// MARK: - Error Types

/// Comprehensive error handling for color processing operations
enum ColorProcessingError: LocalizedError, Equatable, Hashable {
    // Input validation errors
    case invalidColorFormat(format: String, input: String)
    case invalidColorValue(component: String, value: String, range: String)
    case emptyColorInput
    case unsupportedColorFormat(format: String)

    // Conversion errors
    case conversionFailed(from: ColorFormat, to: ColorFormat)
    case colorSpaceConversionFailed(reason: String)
    case precisionLoss(from: ColorFormat, to: ColorFormat)

    // Screen sampling errors
    case screenSamplingPermissionDenied
    case screenSamplingFailed(reason: String)
    case screenSamplingTimeout
    case screenSamplingCancelled
    case displayNotFound
    case pixelAccessFailed(point: CGPoint)

    // System errors
    case systemResourceUnavailable
    case memoryPressure
    case operationTimeout
    case operationCancelled
    case unknown(String)

    var errorDescription: String? {
        switch self {
        // Input validation errors
        case .invalidColorFormat(let format, let input):
            return "Invalid \(format) color format: '\(input)'"
        case .invalidColorValue(let component, let value, let range):
            return "Invalid \(component) value '\(value)'. Expected range: \(range)"
        case .emptyColorInput:
            return "Color input cannot be empty"
        case .unsupportedColorFormat(let format):
            return "Unsupported color format: \(format)"

        // Conversion errors
        case .conversionFailed(let from, let to):
            return "Failed to convert from \(from.rawValue) to \(to.rawValue)"
        case .colorSpaceConversionFailed(let reason):
            return "Color space conversion failed: \(reason)"
        case .precisionLoss(let from, let to):
            return "Precision loss detected converting from \(from.rawValue) to \(to.rawValue)"

        // Screen sampling errors
        case .screenSamplingPermissionDenied:
            return "Screen recording permission is required for color sampling"
        case .screenSamplingFailed(let reason):
            return "Screen color sampling failed: \(reason)"
        case .screenSamplingTimeout:
            return "Screen sampling operation timed out"
        case .screenSamplingCancelled:
            return "Screen sampling was cancelled"
        case .displayNotFound:
            return "Display not found for color sampling"
        case .pixelAccessFailed(let point):
            return "Failed to access pixel at point (\(Int(point.x)), \(Int(point.y)))"

        // System errors
        case .systemResourceUnavailable:
            return "System resource unavailable"
        case .memoryPressure:
            return "Low memory - operation cancelled"
        case .operationTimeout:
            return "Operation timed out"
        case .operationCancelled:
            return "Operation was cancelled"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        // Input validation errors
        case .invalidColorFormat:
            return "Please enter a valid color value in the specified format"
        case .invalidColorValue:
            return "Please enter a value within the valid range"
        case .emptyColorInput:
            return "Please enter a color value"
        case .unsupportedColorFormat:
            return "Please use a supported color format (RGB, Hex, HSL, HSV, CMYK, LAB)"

        // Conversion errors
        case .conversionFailed:
            return "Please check the input color value and try again"
        case .colorSpaceConversionFailed:
            return "Try using a different color format or check input values"
        case .precisionLoss:
            return "Some precision may be lost in this conversion"

        // Screen sampling errors
        case .screenSamplingPermissionDenied:
            return "Grant screen recording permission in System Preferences > Privacy & Security"
        case .screenSamplingFailed:
            return "Try sampling again or restart the application"
        case .screenSamplingTimeout:
            return "Try sampling again with a shorter operation"
        case .screenSamplingCancelled:
            return "Press the sample button to try again"
        case .displayNotFound:
            return "Ensure your display is properly connected"
        case .pixelAccessFailed:
            return "Try sampling a different area of the screen"

        // System errors
        case .systemResourceUnavailable:
            return "Try again later or restart the application"
        case .memoryPressure:
            return "Close other applications to free up memory"
        case .operationTimeout:
            return "Try the operation again"
        case .operationCancelled:
            return "You can retry the operation if needed"
        case .unknown:
            return "Please try again or contact support"
        }
    }

    var isRetryable: Bool {
        switch self {
        // Retryable errors
        case .conversionFailed, .colorSpaceConversionFailed:
            return true
        case .screenSamplingFailed, .screenSamplingTimeout, .pixelAccessFailed:
            return true
        case .systemResourceUnavailable, .operationTimeout:
            return true
        case .unknown:
            return true

        // Non-retryable errors
        case .invalidColorFormat, .invalidColorValue, .emptyColorInput, .unsupportedColorFormat:
            return false
        case .screenSamplingPermissionDenied, .screenSamplingCancelled, .displayNotFound:
            return false
        case .memoryPressure, .operationCancelled:
            return false
        case .precisionLoss:
            return false
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .invalidColorFormat, .invalidColorValue, .emptyColorInput:
            return .warning
        case .precisionLoss:
            return .warning
        case .screenSamplingPermissionDenied:
            return .error
        case .screenSamplingFailed:
            return .error
        case .systemResourceUnavailable, .memoryPressure:
            return .critical
        case .operationCancelled, .screenSamplingCancelled:
            return .info
        default:
            return .error
        }
    }

    static func == (lhs: ColorProcessingError, rhs: ColorProcessingError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidColorFormat(let a1, let b1), .invalidColorFormat(let a2, let b2)):
            return a1 == a2 && b1 == b2
        case (
            .invalidColorValue(let a1, let b1, let c1), .invalidColorValue(let a2, let b2, let c2)
        ):
            return a1 == a2 && b1 == b2 && c1 == c2
        case (.emptyColorInput, .emptyColorInput):
            return true
        case (.unsupportedColorFormat(let a1), .unsupportedColorFormat(let a2)):
            return a1 == a2
        case (.conversionFailed(let a1, let b1), .conversionFailed(let a2, let b2)):
            return a1 == a2 && b1 == b2
        case (.colorSpaceConversionFailed(let a1), .colorSpaceConversionFailed(let a2)):
            return a1 == a2
        case (.precisionLoss(let a1, let b1), .precisionLoss(let a2, let b2)):
            return a1 == a2 && b1 == b2
        case (.screenSamplingPermissionDenied, .screenSamplingPermissionDenied):
            return true
        case (.screenSamplingFailed(let a1), .screenSamplingFailed(let a2)):
            return a1 == a2
        case (.screenSamplingTimeout, .screenSamplingTimeout):
            return true
        case (.screenSamplingCancelled, .screenSamplingCancelled):
            return true
        case (.displayNotFound, .displayNotFound):
            return true
        case (.pixelAccessFailed(let a1), .pixelAccessFailed(let a2)):
            return a1 == a2
        case (.systemResourceUnavailable, .systemResourceUnavailable):
            return true
        case (.memoryPressure, .memoryPressure):
            return true
        case (.operationTimeout, .operationTimeout):
            return true
        case (.operationCancelled, .operationCancelled):
            return true
        case (.unknown(let a1), .unknown(let a2)):
            return a1 == a2
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .invalidColorFormat(let format, let input):
            hasher.combine("invalidColorFormat")
            hasher.combine(format)
            hasher.combine(input)
        case .invalidColorValue(let component, let value, let range):
            hasher.combine("invalidColorValue")
            hasher.combine(component)
            hasher.combine(value)
            hasher.combine(range)
        case .emptyColorInput:
            hasher.combine("emptyColorInput")
        case .unsupportedColorFormat(let format):
            hasher.combine("unsupportedColorFormat")
            hasher.combine(format)
        case .conversionFailed(let from, let to):
            hasher.combine("conversionFailed")
            hasher.combine(from)
            hasher.combine(to)
        case .colorSpaceConversionFailed(let reason):
            hasher.combine("colorSpaceConversionFailed")
            hasher.combine(reason)
        case .precisionLoss(let from, let to):
            hasher.combine("precisionLoss")
            hasher.combine(from)
            hasher.combine(to)
        case .screenSamplingPermissionDenied:
            hasher.combine("screenSamplingPermissionDenied")
        case .screenSamplingFailed(let reason):
            hasher.combine("screenSamplingFailed")
            hasher.combine(reason)
        case .screenSamplingTimeout:
            hasher.combine("screenSamplingTimeout")
        case .screenSamplingCancelled:
            hasher.combine("screenSamplingCancelled")
        case .displayNotFound:
            hasher.combine("displayNotFound")
        case .pixelAccessFailed(let point):
            hasher.combine("pixelAccessFailed")
            hasher.combine(point.x)
            hasher.combine(point.y)
        case .systemResourceUnavailable:
            hasher.combine("systemResourceUnavailable")
        case .memoryPressure:
            hasher.combine("memoryPressure")
        case .operationTimeout:
            hasher.combine("operationTimeout")
        case .operationCancelled:
            hasher.combine("operationCancelled")
        case .unknown(let message):
            hasher.combine("unknown")
            hasher.combine(message)
        }
    }
}

/// Error severity levels for UI display
enum ErrorSeverity: Hashable {
    case info
    case warning
    case error
    case critical

    var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        }
    }

    var icon: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        case .critical:
            return "exclamationmark.octagon"
        }
    }
}
