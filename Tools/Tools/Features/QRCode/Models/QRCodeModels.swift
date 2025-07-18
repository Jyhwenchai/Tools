import Foundation
import SwiftUI

// MARK: - QR Code Models

/// QR码纠错级别
enum QRCodeCorrectionLevel: String, CaseIterable, Codable {
  case low = "L"
  case medium = "M"
  case quartile = "Q"
  case high = "H"
  
  var displayName: String {
    switch self {
    case .low:
      return "低 (7%)"
    case .medium:
      return "中 (15%)"
    case .quartile:
      return "高 (25%)"
    case .high:
      return "最高 (30%)"
    }
  }
  
  var coreImageValue: String {
    return self.rawValue
  }
}

/// QR码生成选项
struct QRCodeOptions: Codable {
  var size: CGSize
  var correctionLevel: QRCodeCorrectionLevel
  var foregroundColor: Color
  var backgroundColor: Color
  
  init(
    size: CGSize = CGSize(width: 200, height: 200),
    correctionLevel: QRCodeCorrectionLevel = .medium,
    foregroundColor: Color = .black,
    backgroundColor: Color = .white
  ) {
    self.size = size
    self.correctionLevel = correctionLevel
    self.foregroundColor = foregroundColor
    self.backgroundColor = backgroundColor
  }
}

/// QR码生成结果
struct QRCodeGenerationResult {
  let image: NSImage
  let inputText: String
  let options: QRCodeOptions
  let timestamp: Date
  
  init(image: NSImage, inputText: String, options: QRCodeOptions) {
    self.image = image
    self.inputText = inputText
    self.options = options
    self.timestamp = Date()
  }
}

/// QR码识别结果
struct QRCodeRecognitionResult {
  let text: String
  let confidence: Float
  let boundingBox: CGRect?
  let timestamp: Date
  
  init(text: String, confidence: Float = 1.0, boundingBox: CGRect? = nil) {
    self.text = text
    self.confidence = confidence
    self.boundingBox = boundingBox
    self.timestamp = Date()
  }
}

// MARK: - Color Extensions for Codable Support

extension Color: Codable {
  enum CodingKeys: String, CodingKey {
    case red, green, blue, alpha
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let red = try container.decode(Double.self, forKey: .red)
    let green = try container.decode(Double.self, forKey: .green)
    let blue = try container.decode(Double.self, forKey: .blue)
    let alpha = try container.decode(Double.self, forKey: .alpha)
    
    self.init(red: red, green: green, blue: blue, opacity: alpha)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    let nsColor = NSColor(self)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    
    nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    
    try container.encode(Double(red), forKey: .red)
    try container.encode(Double(green), forKey: .green)
    try container.encode(Double(blue), forKey: .blue)
    try container.encode(Double(alpha), forKey: .alpha)
  }
}