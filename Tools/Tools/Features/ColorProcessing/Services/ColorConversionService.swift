import Foundation
import SwiftUI

/// 颜色转换服务 - 处理不同颜色格式之间的转换
/// Service for converting colors between different formats
@MainActor
@Observable
class ColorConversionService {

    // MARK: - 可观察属性 / Observable Properties

    var isProcessing: Bool = false
    var lastError: ColorProcessingError?
    var currentColor: ColorRepresentation?

    // MARK: - 错误处理 / Error Handling

    private let errorHandler = ColorProcessingErrorHandler()
    private var toastService: ColorProcessingToastService?

    // MARK: - 核心转换方法 / Core Conversion Methods

    /// 在不同颜色格式之间转换颜色
    /// Convert color from one format to another
    func convertColor(from sourceFormat: ColorFormat, to targetFormat: ColorFormat, value: String)
        -> Result<String, ColorProcessingError>
    {
        // 清除之前的错误 / Clear previous errors
        lastError = nil
        errorHandler.clearError()

        // 检查空输入 / Check for empty input
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            let error = ColorProcessingError.emptyColorInput
            handleError(error, context: "Color conversion with empty input")
            return .failure(error)
        }

        // 首先验证输入 / First validate the input
        let validationResult = ColorFormatDetector.validateInput(
            trimmedValue, expectedFormat: sourceFormat)
        guard validationResult.isValid else {
            let error = ColorProcessingError.invalidColorFormat(
                format: sourceFormat.rawValue, input: trimmedValue)
            handleError(error, context: "Input validation failed")
            return .failure(error)
        }

        // 先转换为 RGB，然后转换为目标格式 / Convert to RGB first, then to target format
        do {
            let rgbColor = try parseToRGB(trimmedValue, format: sourceFormat)
            let targetValue = try formatFromRGB(rgbColor, to: targetFormat)
            return .success(targetValue)
        } catch let error as ColorProcessingError {
            handleError(error, context: "Color format conversion")
            return .failure(error)
        } catch {
            let conversionError = ColorProcessingError.conversionFailed(
                from: sourceFormat, to: targetFormat)
            handleError(conversionError, context: "Unexpected conversion error")
            return .failure(conversionError)
        }
    }

    /// 从任何格式创建完整的 ColorRepresentation
    /// Create complete ColorRepresentation from any format
    func createColorRepresentation(from format: ColorFormat, value: String) -> Result<
        ColorRepresentation, ColorProcessingError
    > {
        // 清除之前的错误 / Clear previous errors
        lastError = nil
        errorHandler.clearError()

        // 检查空输入 / Check for empty input
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            let error = ColorProcessingError.emptyColorInput
            handleError(error, context: "Creating color representation with empty input")
            return .failure(error)
        }

        // 验证输入 / Validate input
        let validationResult = ColorFormatDetector.validateInput(
            trimmedValue, expectedFormat: format)
        guard validationResult.isValid else {
            let error = ColorProcessingError.invalidColorFormat(
                format: format.rawValue, input: trimmedValue)
            handleError(error, context: "Input validation for color representation")
            return .failure(error)
        }

        do {
            let rgbColor = try parseToRGB(trimmedValue, format: format)
            let colorRepresentation = try createFullColorRepresentation(from: rgbColor)
            return .success(colorRepresentation)
        } catch let error as ColorProcessingError {
            handleError(error, context: "Creating color representation")
            return .failure(error)
        } catch {
            let conversionError = ColorProcessingError.conversionFailed(from: format, to: .rgb)
            handleError(conversionError, context: "Unexpected error creating color representation")
            return .failure(conversionError)
        }
    }

    /// Validate color input for specific format
    func validateColorInput(_ input: String, format: ColorFormat) -> ValidationResult {
        return ColorFormatDetector.validateInput(input, expectedFormat: format)
    }

    /// Universal color conversion method that handles any format to any format
    func convertColorUniversal(
        from sourceFormat: ColorFormat, to targetFormat: ColorFormat, value: String
    ) -> Result<ColorRepresentation, ColorProcessingError> {
        // Clear previous errors
        lastError = nil

        // First validate the input
        let validationResult = ColorFormatDetector.validateInput(
            value, expectedFormat: sourceFormat)
        guard validationResult.isValid else {
            let error = ColorProcessingError.invalidColorFormat(
                format: sourceFormat.rawValue, input: value)
            lastError = error
            return .failure(error)
        }

        do {
            // Convert to RGB as intermediate format
            let rgbColor = try parseToRGB(value, format: sourceFormat)

            // Create complete color representation
            let colorRepresentation = try createFullColorRepresentation(from: rgbColor)

            return .success(colorRepresentation)
        } catch let error as ColorProcessingError {
            lastError = error
            return .failure(error)
        } catch {
            let conversionError = ColorProcessingError.conversionFailed(
                from: sourceFormat, to: targetFormat)
            lastError = conversionError
            return .failure(conversionError)
        }
    }

    /// 从 RGBColor 创建 ColorRepresentation
    /// Create ColorRepresentation from RGBColor
    func createColorRepresentation(from rgb: RGBColor) -> ColorRepresentation {
        do {
            return try createFullColorRepresentation(from: rgb)
        } catch {
            // 如果转换失败，使用基础表示作为备用方案
            // Fallback to basic representation if conversion fails
            return ColorConversionUtils.createBasicColorRepresentation(from: rgb)
        }
    }

    /// 更新当前颜色并通知观察者
    /// Update current color and notify observers
    func updateCurrentColor(_ color: ColorRepresentation) {
        currentColor = color
        lastError = nil
        errorHandler.clearError()
    }

    /// Get the error handler for external access
    func getErrorHandler() -> ColorProcessingErrorHandler {
        return errorHandler
    }

    /// Set the toast service for notifications
    func setToastService(_ toastService: ColorProcessingToastService) {
        self.toastService = toastService
    }

    /// Convert color with toast notifications
    func convertColorWithToast(
        from sourceFormat: ColorFormat, to targetFormat: ColorFormat, value: String
    ) -> Result<String, ColorProcessingError> {
        let result = convertColor(from: sourceFormat, to: targetFormat, value: value)

        switch result {
        case .success(let convertedValue):
            toastService?.showColorConverted(from: sourceFormat, to: targetFormat)
            return .success(convertedValue)
        case .failure(let error):
            toastService?.showError(error)
            return .failure(error)
        }
    }

    /// Create color representation with toast notifications
    func createColorRepresentationWithToast(from format: ColorFormat, value: String) -> Result<
        ColorRepresentation, ColorProcessingError
    > {
        let result = createColorRepresentation(from: format, value: value)

        switch result {
        case .success(let colorRepresentation):
            // Don't show success toast for basic color representation creation
            return .success(colorRepresentation)
        case .failure(let error):
            toastService?.showError(error)
            return .failure(error)
        }
    }

    // MARK: - Private Error Handling

    private func handleError(_ error: ColorProcessingError, context: String) {
        lastError = error
        errorHandler.handleError(error, context: context)

        // Show toast notification for errors
        toastService?.showError(error)
    }

    // MARK: - RGB 转换方法 / RGB Conversion Methods

    /// 将 RGB 转换为 HSL（使用工具类）
    /// Convert RGB to HSL (using utility class)
    func rgbToHSL(_ rgb: RGBColor) -> HSLColor {
        return ColorConversionUtils.rgbToHSL(rgb)
    }

    /// 将 RGB 转换为 HSV（使用工具类）
    /// Convert RGB to HSV (using utility class)
    func rgbToHSV(_ rgb: RGBColor) -> HSVColor {
        return ColorConversionUtils.rgbToHSV(rgb)
    }

    // MARK: - Private Helper Methods

    /// Parse input string to RGB color based on format
    private func parseToRGB(_ input: String, format: ColorFormat) throws -> RGBColor {
        let sanitized = ColorFormatDetector.sanitizeInput(input, format: format)

        switch format {
        case .rgb:
            return try parseRGBString(sanitized)
        case .hex:
            return try parseHexString(sanitized)
        case .hsl:
            let hsl = try parseHSLString(sanitized)
            return hslToRGB(hsl)
        case .hsv:
            let hsv = try parseHSVString(sanitized)
            return hsvToRGB(hsv)
        case .cmyk:
            let cmyk = try parseCMYKString(sanitized)
            return cmykToRGB(cmyk)
        case .lab:
            let lab = try parseLABString(sanitized)
            return labToRGB(lab)
        }
    }

    /// Format RGB color to target format string
    private func formatFromRGB(_ rgb: RGBColor, to format: ColorFormat) throws -> String {
        switch format {
        case .rgb:
            return rgb.alpha < 1.0
                ? "rgba(\(Int(rgb.red)), \(Int(rgb.green)), \(Int(rgb.blue)), \(String(format: "%.2f", rgb.alpha)))"
                : "rgb(\(Int(rgb.red)), \(Int(rgb.green)), \(Int(rgb.blue)))"
        case .hex:
            return rgbToHex(rgb)
        case .hsl:
            let hsl = rgbToHSL(rgb)
            return hsl.alpha < 1.0
                ? "hsla(\(Int(hsl.hue)), \(Int(hsl.saturation))%, \(Int(hsl.lightness))%, \(String(format: "%.2f", hsl.alpha)))"
                : "hsl(\(Int(hsl.hue)), \(Int(hsl.saturation))%, \(Int(hsl.lightness))%)"
        case .hsv:
            let hsv = rgbToHSV(rgb)
            return hsv.alpha < 1.0
                ? "hsva(\(Int(hsv.hue)), \(Int(hsv.saturation))%, \(Int(hsv.value))%, \(String(format: "%.2f", hsv.alpha)))"
                : "hsv(\(Int(hsv.hue)), \(Int(hsv.saturation))%, \(Int(hsv.value))%)"
        case .cmyk:
            let cmyk = rgbToCMYK(rgb)
            return
                "cmyk(\(Int(cmyk.cyan))%, \(Int(cmyk.magenta))%, \(Int(cmyk.yellow))%, \(Int(cmyk.key))%)"
        case .lab:
            let lab = rgbToLAB(rgb)
            return
                "lab(\(String(format: "%.1f", lab.lightness)), \(String(format: "%.1f", lab.a)), \(String(format: "%.1f", lab.b)))"
        }
    }

    /// 从 RGB 创建完整的 ColorRepresentation（使用工具类）
    /// Create complete ColorRepresentation from RGB (using utility class)
    private func createFullColorRepresentation(from rgb: RGBColor) throws -> ColorRepresentation {
        return ColorConversionUtils.createBasicColorRepresentation(from: rgb)
    }

    // MARK: - String Parsing Methods

    private func parseRGBString(_ input: String) throws -> RGBColor {
        let pattern =
            #"^rgba?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)$"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: input.count)

        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            throw ColorProcessingError.invalidColorFormat(format: "RGB", input: input)
        }

        let components: [Double] = (1...4).compactMap { index in
            guard match.range(at: index).location != NSNotFound else { return nil }
            let range = Range(match.range(at: index), in: input)!
            return Double(String(input[range]))
        }

        guard components.count >= 3 else {
            throw ColorProcessingError.invalidColorFormat(format: "RGB", input: input)
        }

        return RGBColor(
            red: components[0],
            green: components[1],
            blue: components[2],
            alpha: components.count > 3 ? components[3] : 1.0
        )
    }

    private func parseHexString(_ input: String) throws -> RGBColor {
        var hex = input
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else {
            throw ColorProcessingError.invalidColorFormat(format: "Hex", input: input)
        }

        switch hex.count {
        case 3:  // RGB
            let r = Double((rgb >> 8) & 0xF) * 17
            let g = Double((rgb >> 4) & 0xF) * 17
            let b = Double(rgb & 0xF) * 17
            return RGBColor(red: r, green: g, blue: b, alpha: 1.0)
        case 6:  // RRGGBB
            let r = Double((rgb >> 16) & 0xFF)
            let g = Double((rgb >> 8) & 0xFF)
            let b = Double(rgb & 0xFF)
            return RGBColor(red: r, green: g, blue: b, alpha: 1.0)
        case 8:  // RRGGBBAA
            let r = Double((rgb >> 24) & 0xFF)
            let g = Double((rgb >> 16) & 0xFF)
            let b = Double((rgb >> 8) & 0xFF)
            let a = Double(rgb & 0xFF) / 255.0
            return RGBColor(red: r, green: g, blue: b, alpha: a)
        default:
            throw ColorProcessingError.invalidColorFormat(format: "Hex", input: input)
        }
    }

    private func parseHSLString(_ input: String) throws -> HSLColor {
        let pattern =
            #"^hsla?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)$"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: input.count)

        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            throw ColorProcessingError.invalidColorFormat(format: "HSL", input: input)
        }

        let components: [Double] = (1...4).compactMap { index in
            guard match.range(at: index).location != NSNotFound else { return nil }
            let range = Range(match.range(at: index), in: input)!
            return Double(String(input[range]))
        }

        guard components.count >= 3 else {
            throw ColorProcessingError.invalidColorFormat(format: "HSL", input: input)
        }

        return HSLColor(
            hue: components[0],
            saturation: components[1],
            lightness: components[2],
            alpha: components.count > 3 ? components[3] : 1.0
        )
    }

    private func parseHSVString(_ input: String) throws -> HSVColor {
        let pattern =
            #"^hsva?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*(?:,\s*(\d+(?:\.\d+)?))?\s*\)$"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: input.count)

        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            throw ColorProcessingError.invalidColorFormat(format: "HSV", input: input)
        }

        let components: [Double] = (1...4).compactMap { index in
            guard match.range(at: index).location != NSNotFound else { return nil }
            let range = Range(match.range(at: index), in: input)!
            return Double(String(input[range]))
        }

        guard components.count >= 3 else {
            throw ColorProcessingError.invalidColorFormat(format: "HSV", input: input)
        }

        return HSVColor(
            hue: components[0],
            saturation: components[1],
            value: components[2],
            alpha: components.count > 3 ? components[3] : 1.0
        )
    }

    // MARK: - Basic Conversion Algorithms (Placeholders for now)

    func hslToRGB(_ hsl: HSLColor) -> RGBColor {
        let h = hsl.hue / 360.0
        let s = hsl.saturation / 100.0
        let l = hsl.lightness / 100.0

        if s == 0 {
            // Achromatic (gray)
            let gray = l * 255
            return RGBColor(red: gray, green: gray, blue: gray, alpha: hsl.alpha)
        }

        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2

        var r: Double = 0
        var g: Double = 0
        var b: Double = 0

        let hueSegment = Int(h * 6)
        switch hueSegment {
        case 0:
            r = c
            g = x
            b = 0
        case 1:
            r = x
            g = c
            b = 0
        case 2:
            r = 0
            g = c
            b = x
        case 3:
            r = 0
            g = x
            b = c
        case 4:
            r = x
            g = 0
            b = c
        case 5:
            r = c
            g = 0
            b = x
        default:
            r = c
            g = x
            b = 0
        }

        return RGBColor(
            red: (r + m) * 255,
            green: (g + m) * 255,
            blue: (b + m) * 255,
            alpha: hsl.alpha
        )
    }

    func hsvToRGB(_ hsv: HSVColor) -> RGBColor {
        let h = hsv.hue / 360.0
        let s = hsv.saturation / 100.0
        let v = hsv.value / 100.0

        if s == 0 {
            // Achromatic (gray)
            let gray = v * 255
            return RGBColor(red: gray, green: gray, blue: gray, alpha: hsv.alpha)
        }

        let c = v * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = v - c

        var r: Double = 0
        var g: Double = 0
        var b: Double = 0

        let hueSegment = Int(h * 6)
        switch hueSegment {
        case 0:
            r = c
            g = x
            b = 0
        case 1:
            r = x
            g = c
            b = 0
        case 2:
            r = 0
            g = c
            b = x
        case 3:
            r = 0
            g = x
            b = c
        case 4:
            r = x
            g = 0
            b = c
        case 5:
            r = c
            g = 0
            b = x
        default:
            r = c
            g = x
            b = 0
        }

        return RGBColor(
            red: (r + m) * 255,
            green: (g + m) * 255,
            blue: (b + m) * 255,
            alpha: hsv.alpha
        )
    }

    /// 将 RGB 转换为十六进制（使用工具类）
    /// Convert RGB to hex (using utility class)
    private func rgbToHex(_ rgb: RGBColor) -> String {
        return ColorConversionUtils.rgbToHex(rgb)
    }

    /// 将 RGB 转换为 CMYK（使用工具类）
    /// Convert RGB to CMYK (using utility class)
    func rgbToCMYK(_ rgb: RGBColor) -> CMYKColor {
        return ColorConversionUtils.rgbToCMYK(rgb)
    }

    /// 将 RGB 转换为 LAB（使用工具类）
    /// Convert RGB to LAB (using utility class)
    func rgbToLAB(_ rgb: RGBColor) -> LABColor {
        return ColorConversionUtils.rgbToLAB(rgb)
    }

    func cmykToRGB(_ cmyk: CMYKColor) -> RGBColor {
        // Convert CMYK percentages to normalized values (0-1)
        let c = cmyk.cyan / 100.0
        let m = cmyk.magenta / 100.0
        let y = cmyk.yellow / 100.0
        let k = cmyk.key / 100.0

        // Convert to RGB
        let r = 255 * (1 - c) * (1 - k)
        let g = 255 * (1 - m) * (1 - k)
        let b = 255 * (1 - y) * (1 - k)

        return RGBColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    func labToRGB(_ lab: LABColor) -> RGBColor {
        // First convert LAB to XYZ
        let xyz = labToXYZ(lab)

        // Then convert XYZ to RGB
        return xyzToRGB(xyz)
    }

    private func labToXYZ(_ lab: LABColor) -> (x: Double, y: Double, z: Double) {
        // D65 illuminant reference values
        let xn = 95.047
        let yn = 100.000
        let zn = 108.883

        let fy = (lab.lightness + 16) / 116
        let fx = lab.a / 500 + fy
        let fz = fy - lab.b / 200

        let delta = 6.0 / 29.0
        let deltaSquared = pow(delta, 2)
        let deltaCubed = pow(delta, 3)

        let x = xn * (fx > delta ? pow(fx, 3) : 3 * deltaSquared * (fx - 4.0 / 29.0))
        let y = yn * (fy > delta ? pow(fy, 3) : 3 * deltaSquared * (fy - 4.0 / 29.0))
        let z = zn * (fz > delta ? pow(fz, 3) : 3 * deltaSquared * (fz - 4.0 / 29.0))

        return (x, y, z)
    }

    private func xyzToRGB(_ xyz: (x: Double, y: Double, z: Double)) -> RGBColor {
        // Normalize XYZ values
        let x = xyz.x / 100.0
        let y = xyz.y / 100.0
        let z = xyz.z / 100.0

        // Convert XYZ to linear RGB using sRGB matrix
        var r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
        var g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
        var b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

        // Apply gamma correction
        r = r > 0.0031308 ? 1.055 * pow(r, 1.0 / 2.4) - 0.055 : 12.92 * r
        g = g > 0.0031308 ? 1.055 * pow(g, 1.0 / 2.4) - 0.055 : 12.92 * g
        b = b > 0.0031308 ? 1.055 * pow(b, 1.0 / 2.4) - 0.055 : 12.92 * b

        // Clamp values to valid range and convert to 0-255
        r = max(0, min(1, r)) * 255
        g = max(0, min(1, g)) * 255
        b = max(0, min(1, b)) * 255

        return RGBColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private func parseCMYKString(_ input: String) throws -> CMYKColor {
        let pattern =
            #"^cmyk\(\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*,\s*(\d+(?:\.\d+)?)%\s*\)$"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: input.count)

        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            throw ColorProcessingError.invalidColorFormat(format: "CMYK", input: input)
        }

        let components: [Double] = (1...4).compactMap { index in
            let range = Range(match.range(at: index), in: input)!
            return Double(String(input[range]))
        }

        guard components.count == 4 else {
            throw ColorProcessingError.invalidColorFormat(format: "CMYK", input: input)
        }

        return CMYKColor(
            cyan: components[0],
            magenta: components[1],
            yellow: components[2],
            key: components[3]
        )
    }

    private func parseLABString(_ input: String) throws -> LABColor {
        let pattern =
            #"^lab\(\s*(\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)$"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: input.count)

        guard let match = regex.firstMatch(in: input, options: [], range: range) else {
            throw ColorProcessingError.invalidColorFormat(format: "LAB", input: input)
        }

        let components: [Double] = (1...3).compactMap { index in
            let range = Range(match.range(at: index), in: input)!
            return Double(String(input[range]))
        }

        guard components.count == 3 else {
            throw ColorProcessingError.invalidColorFormat(format: "LAB", input: input)
        }

        return LABColor(
            lightness: components[0],
            a: components[1],
            b: components[2]
        )
    }
}
