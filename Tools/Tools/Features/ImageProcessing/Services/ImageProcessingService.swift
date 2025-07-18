import Foundation
import AppKit
import CoreImage
import UniformTypeIdentifiers
import CoreGraphics

class ImageProcessingService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let ciContext = CIContext()
    
    // MARK: - Image Loading
    func loadImage(from url: URL) -> NSImage? {
        guard let image = NSImage(contentsOf: url) else {
            errorMessage = "无法加载图片"
            return nil
        }
        return image
    }
    
    // MARK: - Format Conversion
    func convertImage(_ image: NSImage, to format: ImageFormat) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            errorMessage = "图片转换失败"
            return nil
        }
        
        switch format {
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .jpeg(let quality):
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        case .gif:
            return bitmap.representation(using: .gif, properties: [:])
        case .tiff:
            return bitmap.representation(using: .tiff, properties: [:])
        case .bmp:
            return bitmap.representation(using: .bmp, properties: [:])
        case .webp:
            // WebP conversion would require additional framework
            errorMessage = "WebP格式暂不支持"
            return nil
        case .heic:
            // HEIC conversion
            return convertToHEIC(bitmap: bitmap)
        }
    }
    
    // MARK: - Resizing
    func resizeImage(_ image: NSImage, to size: NSSize, maintainAspectRatio: Bool = true) -> NSImage? {
        let targetSize = maintainAspectRatio ? calculateAspectFitSize(image.size, targetSize: size) : size
        
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        
        let context = NSGraphicsContext.current?.cgContext
        context?.interpolationQuality = .high
        
        image.draw(in: NSRect(origin: .zero, size: targetSize))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    
    // MARK: - Compression
    func compressImage(_ image: NSImage, quality: Double) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            errorMessage = "图片压缩失败"
            return nil
        }
        
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
    
    // MARK: - Advanced Image Processing
    
    // MARK: - Image Cropping
    func cropImage(_ image: NSImage, to cropRect: NSRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            errorMessage = "无法获取图片数据"
            return nil
        }
        
        // Convert NSRect to CGRect with proper coordinate system
        let imageSize = image.size
        let cropCGRect = CGRect(
            x: cropRect.origin.x,
            y: imageSize.height - cropRect.origin.y - cropRect.size.height,
            width: cropRect.size.width,
            height: cropRect.size.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cropCGRect) else {
            errorMessage = "图片裁剪失败"
            return nil
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: cropRect.size)
        return croppedImage
    }
    
    // MARK: - Text Watermark
    func addTextWatermark(
        to image: NSImage,
        text: String,
        font: NSFont = NSFont.systemFont(ofSize: 24),
        color: NSColor = .white,
        opacity: Double = 0.7,
        position: WatermarkPosition = .bottomRight,
        margin: CGFloat = 20
    ) -> NSImage? {
        let imageSize = image.size
        let watermarkedImage = NSImage(size: imageSize)
        
        watermarkedImage.lockFocus()
        
        // Draw the original image
        image.draw(in: NSRect(origin: .zero, size: imageSize))
        
        // Prepare text attributes
        let textColor = color.withAlphaComponent(opacity)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        // Calculate position based on watermark position
        let textRect = calculateWatermarkRect(
            textSize: textSize,
            imageSize: imageSize,
            position: position,
            margin: margin
        )
        
        // Draw the text
        attributedString.draw(in: textRect)
        
        watermarkedImage.unlockFocus()
        
        return watermarkedImage
    }
    
    // MARK: - Image Watermark
    func addImageWatermark(
        to image: NSImage,
        watermarkImage: NSImage,
        opacity: Double = 0.7,
        position: WatermarkPosition = .bottomRight,
        margin: CGFloat = 20,
        scale: Double = 0.2
    ) -> NSImage? {
        let imageSize = image.size
        let watermarkedImage = NSImage(size: imageSize)
        
        watermarkedImage.lockFocus()
        
        // Draw the original image
        image.draw(in: NSRect(origin: .zero, size: imageSize))
        
        // Calculate watermark size
        let watermarkSize = NSSize(
            width: watermarkImage.size.width * scale,
            height: watermarkImage.size.height * scale
        )
        
        // Calculate position
        let watermarkRect = calculateWatermarkRect(
            textSize: watermarkSize,
            imageSize: imageSize,
            position: position,
            margin: margin
        )
        
        // Draw watermark with opacity
        watermarkImage.draw(
            in: watermarkRect,
            from: NSRect(origin: .zero, size: watermarkImage.size),
            operation: .sourceOver,
            fraction: opacity
        )
        
        watermarkedImage.unlockFocus()
        
        return watermarkedImage
    }
    
    // MARK: - Enhanced Format Conversion
    func convertImageToFormat(_ image: NSImage, format: ImageFormat, quality: Double = 0.8) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            errorMessage = "图片转换失败"
            return nil
        }
        
        switch format {
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .jpeg(let compressionQuality):
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        case .gif:
            return bitmap.representation(using: .gif, properties: [:])
        case .tiff:
            return bitmap.representation(using: .tiff, properties: [:])
        case .bmp:
            return bitmap.representation(using: .bmp, properties: [:])
        case .webp:
            // WebP support would require additional framework
            // For now, convert to JPEG as fallback
            errorMessage = "WebP格式暂不支持，已转换为JPEG格式"
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        case .heic:
            return convertToHEIC(bitmap: bitmap)
        }
    }
    
    // MARK: - Batch Processing
    func batchProcess(urls: [URL], operations: [ImageOperation]) async -> [ProcessingResult] {
        isProcessing = true
        defer { isProcessing = false }
        
        var results: [ProcessingResult] = []
        
        for url in urls {
            guard let image = loadImage(from: url) else {
                results.append(ProcessingResult(originalURL: url, processedImage: nil, success: false, error: "加载失败"))
                continue
            }
            
            var processedImage = image
            var success = true
            var error: String?
            
            for operation in operations {
                switch operation {
                case .resize(let size, let maintainAspect):
                    if let resized = resizeImage(processedImage, to: size, maintainAspectRatio: maintainAspect) {
                        processedImage = resized
                    } else {
                        success = false
                        error = "调整大小失败"
                        break
                    }
                case .convert(_):
                    // For batch processing, we'll save the conversion for the final step
                    break
                case .compress(let quality):
                    if let compressed = compressImage(processedImage, quality: quality),
                       let compressedImage = NSImage(data: compressed) {
                        processedImage = compressedImage
                    } else {
                        success = false
                        error = "压缩失败"
                        break
                    }
                case .crop(let rect):
                    if let cropped = cropImage(processedImage, to: rect) {
                        processedImage = cropped
                    } else {
                        success = false
                        error = "裁剪失败"
                        break
                    }
                case .addTextWatermark(let text, let font, let color, let opacity, let position):
                    if let watermarked = addTextWatermark(
                        to: processedImage,
                        text: text,
                        font: font,
                        color: color,
                        opacity: opacity,
                        position: position
                    ) {
                        processedImage = watermarked
                    } else {
                        success = false
                        error = "添加水印失败"
                        break
                    }
                case .addImageWatermark(let watermarkImage, let opacity, let position, let scale):
                    if let watermarked = addImageWatermark(
                        to: processedImage,
                        watermarkImage: watermarkImage,
                        opacity: opacity,
                        position: position,
                        scale: scale
                    ) {
                        processedImage = watermarked
                    } else {
                        success = false
                        error = "添加图片水印失败"
                        break
                    }
                }
            }
            
            results.append(ProcessingResult(
                originalURL: url,
                processedImage: success ? processedImage : nil,
                success: success,
                error: error
            ))
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    private func calculateAspectFitSize(_ originalSize: NSSize, targetSize: NSSize) -> NSSize {
        let aspectRatio = originalSize.width / originalSize.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        if aspectRatio > targetAspectRatio {
            // Image is wider than target
            return NSSize(width: targetSize.width, height: targetSize.width / aspectRatio)
        } else {
            // Image is taller than target
            return NSSize(width: targetSize.height * aspectRatio, height: targetSize.height)
        }
    }
    
    func calculateWatermarkRect(
        textSize: NSSize,
        imageSize: NSSize,
        position: WatermarkPosition,
        margin: CGFloat
    ) -> NSRect {
        switch position {
        case .topLeft:
            return NSRect(x: margin, y: imageSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case .topRight:
            return NSRect(x: imageSize.width - textSize.width - margin, y: imageSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case .bottomLeft:
            return NSRect(x: margin, y: margin, width: textSize.width, height: textSize.height)
        case .bottomRight:
            return NSRect(x: imageSize.width - textSize.width - margin, y: margin, width: textSize.width, height: textSize.height)
        case .center:
            return NSRect(
                x: (imageSize.width - textSize.width) / 2,
                y: (imageSize.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
        }
    }
    
    private func convertToHEIC(bitmap: NSBitmapImageRep) -> Data? {
        // HEIC conversion implementation
        // This would require additional setup for HEIC support
        errorMessage = "HEIC格式暂不支持"
        return nil
    }
}

// MARK: - Supporting Types
enum ImageFormat: Hashable, CaseIterable {
    case png
    case jpeg(quality: Double)
    case gif
    case tiff
    case bmp
    case webp
    case heic
    
    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        case .gif: return "GIF"
        case .tiff: return "TIFF"
        case .bmp: return "BMP"
        case .webp: return "WebP"
        case .heic: return "HEIC"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .gif: return "gif"
        case .tiff: return "tiff"
        case .bmp: return "bmp"
        case .webp: return "webp"
        case .heic: return "heic"
        }
    }
    
    static var allCases: [ImageFormat] {
        return [.png, .jpeg(quality: 0.8), .gif, .tiff, .bmp, .webp, .heic]
    }
}

enum WatermarkPosition: String, CaseIterable {
    case topLeft = "左上"
    case topRight = "右上"
    case bottomLeft = "左下"
    case bottomRight = "右下"
    case center = "居中"
}

enum ImageOperation {
    case resize(size: NSSize, maintainAspectRatio: Bool)
    case convert(format: ImageFormat)
    case compress(quality: Double)
    case crop(rect: NSRect)
    case addTextWatermark(text: String, font: NSFont, color: NSColor, opacity: Double, position: WatermarkPosition)
    case addImageWatermark(watermarkImage: NSImage, opacity: Double, position: WatermarkPosition, scale: Double)
}

struct ProcessingResult {
    let originalURL: URL
    let processedImage: NSImage?
    let success: Bool
    let error: String?
}