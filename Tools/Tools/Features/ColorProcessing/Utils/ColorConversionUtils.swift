import Foundation
import SwiftUI

/// 颜色转换工具类 - 提供 SwiftUI Color 和 ColorRepresentation 之间的转换功能
/// Color conversion utility class - Provides conversion between SwiftUI Color and ColorRepresentation
struct ColorConversionUtils {

    // MARK: - SwiftUI Color 转换方法 / SwiftUI Color Conversion Methods

    /// 将 SwiftUI Color 转换为 RGBColor
    /// Convert SwiftUI Color to RGBColor
    /// - Parameter color: SwiftUI Color 对象
    /// - Returns: RGBColor 结构体，包含 RGB 和 alpha 值
    static func rgbColor(from color: Color) -> RGBColor {
        let nsColor = NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // 转换到 sRGB 色彩空间以确保一致性
        // Convert to sRGB color space for consistency
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return RGBColor(
            red: Double(red * 255),
            green: Double(green * 255),
            blue: Double(blue * 255),
            alpha: Double(alpha)
        )
    }

    /// 将 RGBColor 转换为 SwiftUI Color
    /// Convert RGBColor to SwiftUI Color
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: SwiftUI Color 对象
    static func swiftUIColor(from rgb: RGBColor) -> Color {
        return Color(
            red: rgb.red / 255.0,
            green: rgb.green / 255.0,
            blue: rgb.blue / 255.0,
            opacity: rgb.alpha
        )
    }

    /// 将 ColorRepresentation 转换为 SwiftUI Color
    /// Convert ColorRepresentation to SwiftUI Color
    /// - Parameter colorRepresentation: 完整的颜色表示对象
    /// - Returns: SwiftUI Color 对象
    static func swiftUIColor(from colorRepresentation: ColorRepresentation) -> Color {
        return swiftUIColor(from: colorRepresentation.rgb)
    }

    // MARK: - 颜色表示创建方法 / Color Representation Creation Methods

    /// 从 SwiftUI Color 创建基础的 ColorRepresentation
    /// Create basic ColorRepresentation from SwiftUI Color
    /// - Parameter color: SwiftUI Color 对象
    /// - Returns: 包含所有颜色格式的 ColorRepresentation
    static func createBasicColorRepresentation(from color: Color) -> ColorRepresentation {
        let rgb = rgbColor(from: color)
        return createBasicColorRepresentation(from: rgb)
    }

    /// 从 RGBColor 创建基础的 ColorRepresentation（作为备用方案）
    /// Create basic ColorRepresentation from RGBColor (as fallback)
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: 包含所有颜色格式的 ColorRepresentation
    static func createBasicColorRepresentation(from rgb: RGBColor) -> ColorRepresentation {
        let hex = rgbToHex(rgb)
        let hsl = rgbToHSL(rgb)
        let hsv = rgbToHSV(rgb)
        let cmyk = rgbToCMYK(rgb)
        let lab = rgbToLAB(rgb)

        return ColorRepresentation(
            rgb: rgb,
            hex: hex,
            hsl: hsl,
            hsv: hsv,
            cmyk: cmyk,
            lab: lab
        )
    }

    // MARK: - 颜色格式转换算法 / Color Format Conversion Algorithms

    /// 将 RGB 转换为十六进制格式
    /// Convert RGB to hexadecimal format
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: 十六进制颜色字符串（包含 # 前缀）
    static func rgbToHex(_ rgb: RGBColor) -> String {
        if rgb.alpha < 1.0 {
            return String(
                format: "#%02X%02X%02X%02X",
                Int(rgb.red), Int(rgb.green), Int(rgb.blue), Int(rgb.alpha * 255))
        } else {
            return String(
                format: "#%02X%02X%02X",
                Int(rgb.red), Int(rgb.green), Int(rgb.blue))
        }
    }

    /// 将 RGB 转换为 HSL 格式
    /// Convert RGB to HSL format
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: HSLColor 结构体
    static func rgbToHSL(_ rgb: RGBColor) -> HSLColor {
        // 将 RGB 值标准化到 0-1 范围
        // Normalize RGB values to 0-1 range
        let r = rgb.red / 255.0
        let g = rgb.green / 255.0
        let b = rgb.blue / 255.0

        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min

        // 计算亮度 / Calculate lightness
        let lightness = (max + min) / 2.0

        // 计算饱和度 / Calculate saturation
        var saturation: Double = 0
        if delta != 0 {
            saturation = lightness > 0.5 ? delta / (2.0 - max - min) : delta / (max + min)
        }

        // 计算色相 / Calculate hue
        var hue: Double = 0
        if delta != 0 {
            switch max {
            case r:
                hue = ((g - b) / delta) + (g < b ? 6 : 0)
            case g:
                hue = (b - r) / delta + 2
            case b:
                hue = (r - g) / delta + 4
            default:
                break
            }
            hue /= 6
        }

        return HSLColor(
            hue: hue * 360,
            saturation: saturation * 100,
            lightness: lightness * 100,
            alpha: rgb.alpha
        )
    }

    /// 将 RGB 转换为 HSV 格式
    /// Convert RGB to HSV format
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: HSVColor 结构体
    static func rgbToHSV(_ rgb: RGBColor) -> HSVColor {
        // 将 RGB 值标准化到 0-1 范围
        // Normalize RGB values to 0-1 range
        let r = rgb.red / 255.0
        let g = rgb.green / 255.0
        let b = rgb.blue / 255.0

        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min

        // 计算明度（亮度）/ Calculate value (brightness)
        let value = max

        // 计算饱和度 / Calculate saturation
        let saturation = max == 0 ? 0 : delta / max

        // 计算色相 / Calculate hue
        var hue: Double = 0
        if delta != 0 {
            switch max {
            case r:
                hue = ((g - b) / delta) + (g < b ? 6 : 0)
            case g:
                hue = (b - r) / delta + 2
            case b:
                hue = (r - g) / delta + 4
            default:
                break
            }
            hue /= 6
        }

        return HSVColor(
            hue: hue * 360,
            saturation: saturation * 100,
            value: value * 100,
            alpha: rgb.alpha
        )
    }

    /// 将 RGB 转换为 CMYK 格式
    /// Convert RGB to CMYK format
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: CMYKColor 结构体
    static func rgbToCMYK(_ rgb: RGBColor) -> CMYKColor {
        // 将 RGB (0-255) 转换为标准化值 (0-1)
        // Convert RGB (0-255) to normalized values (0-1)
        let r = rgb.red / 255.0
        let g = rgb.green / 255.0
        let b = rgb.blue / 255.0

        // 计算关键色（黑色）分量
        // Calculate key (black) component
        let k = 1.0 - max(r, max(g, b))

        // 处理纯黑色情况
        // Handle pure black case
        if k == 1.0 {
            return CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 100)
        }

        // 计算 CMY 分量
        // Calculate CMY components
        let c = (1.0 - r - k) / (1.0 - k)
        let m = (1.0 - g - k) / (1.0 - k)
        let y = (1.0 - b - k) / (1.0 - k)

        return CMYKColor(
            cyan: c * 100,
            magenta: m * 100,
            yellow: y * 100,
            key: k * 100
        )
    }

    /// 将 RGB 转换为 LAB 格式
    /// Convert RGB to LAB format
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: LABColor 结构体
    static func rgbToLAB(_ rgb: RGBColor) -> LABColor {
        // 首先转换 RGB 到 XYZ 色彩空间
        // First convert RGB to XYZ color space
        let xyz = rgbToXYZ(rgb)

        // 然后转换 XYZ 到 LAB
        // Then convert XYZ to LAB
        return xyzToLAB(xyz)
    }

    // MARK: - 私有辅助方法 / Private Helper Methods

    /// 将 RGB 转换为 XYZ 色彩空间
    /// Convert RGB to XYZ color space
    /// - Parameter rgb: RGBColor 结构体
    /// - Returns: XYZ 色彩空间的元组 (x, y, z)
    private static func rgbToXYZ(_ rgb: RGBColor) -> (x: Double, y: Double, z: Double) {
        // 将 RGB 值标准化到 0-1
        // Normalize RGB values to 0-1
        var r = rgb.red / 255.0
        var g = rgb.green / 255.0
        var b = rgb.blue / 255.0

        // 应用伽马校正
        // Apply gamma correction
        r = r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92
        g = g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92
        b = b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92

        // 使用 sRGB 矩阵转换到 XYZ
        // Convert to XYZ using sRGB matrix
        let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
        let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
        let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

        return (x * 100, y * 100, z * 100)
    }

    /// 将 XYZ 转换为 LAB 色彩空间
    /// Convert XYZ to LAB color space
    /// - Parameter xyz: XYZ 色彩空间的元组
    /// - Returns: LABColor 结构体
    private static func xyzToLAB(_ xyz: (x: Double, y: Double, z: Double)) -> LABColor {
        // D65 光源参考值
        // D65 illuminant reference values
        let xn = 95.047
        let yn = 100.000
        let zn = 108.883

        // 通过参考光源标准化
        // Normalize by reference illuminant
        let fx = labFunction(xyz.x / xn)
        let fy = labFunction(xyz.y / yn)
        let fz = labFunction(xyz.z / zn)

        // 计算 LAB 值
        // Calculate LAB values
        let l = 116 * fy - 16
        let a = 500 * (fx - fy)
        let b = 200 * (fy - fz)

        return LABColor(lightness: l, a: a, b: b)
    }

    /// LAB 转换函数
    /// LAB conversion function
    /// - Parameter t: 输入值
    /// - Returns: 转换后的值
    private static func labFunction(_ t: Double) -> Double {
        let delta = 6.0 / 29.0
        return t > pow(delta, 3) ? pow(t, 1.0 / 3.0) : t / (3 * pow(delta, 2)) + 4.0 / 29.0
    }

    // MARK: - 颜色比较工具 / Color Comparison Utilities

    /// 比较两个 SwiftUI Color 是否相等（考虑浮点数精度）
    /// Compare two SwiftUI Colors for equality (considering floating point precision)
    /// - Parameters:
    ///   - color1: 第一个颜色
    ///   - color2: 第二个颜色
    /// - Returns: 如果颜色相等返回 true
    static func areColorsEqual(_ color1: Color, _ color2: Color) -> Bool {
        let rgb1 = rgbColor(from: color1)
        let rgb2 = rgbColor(from: color2)

        return abs(rgb1.red - rgb2.red) < 0.5
            && abs(rgb1.green - rgb2.green) < 0.5
            && abs(rgb1.blue - rgb2.blue) < 0.5
            && abs(rgb1.alpha - rgb2.alpha) < 0.005
    }

    /// 生成颜色的可访问性描述
    /// Generate accessibility description for color
    /// - Parameter color: SwiftUI Color 对象
    /// - Returns: 颜色的文字描述，用于辅助功能
    static func colorDescription(for color: Color) -> String {
        let rgb = rgbColor(from: color)
        let alpha = rgb.alpha < 1.0 ? ", alpha \(String(format: "%.2f", rgb.alpha))" : ""
        return "Red \(Int(rgb.red)), Green \(Int(rgb.green)), Blue \(Int(rgb.blue))\(alpha)"
    }

    /// 生成 ColorRepresentation 的可访问性描述
    /// Generate accessibility description for ColorRepresentation
    /// - Parameter colorRepresentation: ColorRepresentation 对象
    /// - Returns: 颜色的文字描述，用于辅助功能
    static func colorDescription(for colorRepresentation: ColorRepresentation) -> String {
        let rgb = colorRepresentation.rgb
        let alpha = rgb.alpha < 1.0 ? ", alpha \(String(format: "%.2f", rgb.alpha))" : ""
        return "Red \(Int(rgb.red)), Green \(Int(rgb.green)), Blue \(Int(rgb.blue))\(alpha)"
    }
}
