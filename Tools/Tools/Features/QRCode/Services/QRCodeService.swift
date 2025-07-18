import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision
import AppKit

/// QR码处理服务
@Observable
class QRCodeService {
  
  // MARK: - Properties
  
  private let context = CIContext()
  
  // MARK: - QR Code Generation
  
  /// 生成二维码
  /// - Parameters:
  ///   - text: 要编码的文本
  ///   - options: 生成选项
  /// - Returns: 生成结果
  /// - Throws: 生成过程中的错误
  func generateQRCode(from text: String, options: QRCodeOptions) throws -> QRCodeGenerationResult {
    guard !text.isEmpty else {
      throw QRCodeError.emptyInput
    }
    
    // 创建QR码过滤器
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(text.utf8)
    filter.correctionLevel = options.correctionLevel.coreImageValue
    
    guard let outputImage = filter.outputImage else {
      throw QRCodeError.generationFailed("无法生成QR码图像")
    }
    
    // 缩放到指定尺寸
    let scaleX = options.size.width / outputImage.extent.width
    let scaleY = options.size.height / outputImage.extent.height
    let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    
    // 应用颜色
    let coloredImage = try applyColors(to: scaledImage, options: options)
    
    // 转换为NSImage
    guard let cgImage = context.createCGImage(coloredImage, from: coloredImage.extent) else {
      throw QRCodeError.generationFailed("无法创建CGImage")
    }
    
    let nsImage = NSImage(cgImage: cgImage, size: options.size)
    
    return QRCodeGenerationResult(image: nsImage, inputText: text, options: options)
  }
  
  /// 应用前景色和背景色
  private func applyColors(to image: CIImage, options: QRCodeOptions) throws -> CIImage {
    // 转换SwiftUI Color到CIColor
    let nsColor = NSColor(options.foregroundColor)
    let backgroundNSColor = NSColor(options.backgroundColor)
    
    // 确保颜色转换成功
    guard let foregroundCIColor = CIColor(color: nsColor),
          let backgroundCIColor = CIColor(color: backgroundNSColor) else {
      throw QRCodeError.generationFailed("无法转换颜色格式")
    }
    
    // 应用颜色过滤器
    let colorFilter = CIFilter.falseColor()
    colorFilter.inputImage = image
    colorFilter.color0 = backgroundCIColor // 背景色 (0值)
    colorFilter.color1 = foregroundCIColor // 前景色 (1值)
    
    guard let coloredImage = colorFilter.outputImage else {
      throw QRCodeError.generationFailed("无法应用颜色")
    }
    
    return coloredImage
  }
  
  // MARK: - QR Code Recognition
  
  /// 识别二维码
  /// - Parameter image: 要识别的图像
  /// - Returns: 识别结果数组
  /// - Throws: 识别过程中的错误
  func recognizeQRCode(from image: NSImage) async throws -> [QRCodeRecognitionResult] {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      throw QRCodeError.invalidImage
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      let request = VNDetectBarcodesRequest { request, error in
        if let error = error {
          continuation.resume(throwing: QRCodeError.recognitionFailed(error.localizedDescription))
          return
        }
        
        guard let observations = request.results as? [VNBarcodeObservation] else {
          continuation.resume(returning: [])
          return
        }
        
        let results = observations.compactMap { observation -> QRCodeRecognitionResult? in
          guard let payload = observation.payloadStringValue,
                observation.symbology == .qr else {
            return nil
          }
          
          return QRCodeRecognitionResult(
            text: payload,
            confidence: observation.confidence,
            boundingBox: observation.boundingBox
          )
        }
        
        continuation.resume(returning: results)
      }
      
      // 配置识别请求
      request.symbologies = [.qr]
      
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      
      do {
        try handler.perform([request])
      } catch {
        continuation.resume(throwing: QRCodeError.recognitionFailed(error.localizedDescription))
      }
    }
  }
  
  // MARK: - Utility Methods
  
  /// 验证文本是否适合生成QR码
  /// - Parameter text: 要验证的文本
  /// - Returns: 验证结果和建议
  func validateTextForQRCode(_ text: String) -> (isValid: Bool, suggestion: String?) {
    if text.isEmpty {
      return (false, "请输入要生成QR码的文本")
    }
    
    let byteCount = text.utf8.count
    
    // QR码容量限制（根据纠错级别）
    let maxCapacity = 2953 // 最大字符数（低纠错级别）
    
    if byteCount > maxCapacity {
      return (false, "文本过长，建议减少到 \(maxCapacity) 个字符以内")
    }
    
    if byteCount > 1000 {
      return (true, "文本较长，建议使用高纠错级别以确保识别准确性")
    }
    
    return (true, nil)
  }
  
  /// 获取推荐的QR码尺寸
  /// - Parameter textLength: 文本长度
  /// - Returns: 推荐尺寸
  func getRecommendedSize(for textLength: Int) -> CGSize {
    switch textLength {
    case 0...50:
      return CGSize(width: 150, height: 150)
    case 51...200:
      return CGSize(width: 200, height: 200)
    case 201...500:
      return CGSize(width: 250, height: 250)
    default:
      return CGSize(width: 300, height: 300)
    }
  }
}

// MARK: - QR Code Errors

enum QRCodeError: LocalizedError, Equatable {
  case emptyInput
  case generationFailed(String)
  case recognitionFailed(String)
  case invalidImage
  case unsupportedFormat
  
  var errorDescription: String? {
    switch self {
    case .emptyInput:
      return "输入文本不能为空"
    case .generationFailed(let message):
      return "QR码生成失败: \(message)"
    case .recognitionFailed(let message):
      return "QR码识别失败: \(message)"
    case .invalidImage:
      return "无效的图像格式"
    case .unsupportedFormat:
      return "不支持的图像格式"
    }
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .emptyInput:
      return "请输入要生成QR码的文本内容"
    case .generationFailed:
      return "请检查输入文本是否过长或包含特殊字符"
    case .recognitionFailed:
      return "请确保图像清晰且包含有效的QR码"
    case .invalidImage:
      return "请选择有效的图像文件"
    case .unsupportedFormat:
      return "请使用PNG、JPG或其他常见图像格式"
    }
  }
}