import Testing
import AppKit
@testable import Tools

struct ImageProcessingServiceTests {
    let service = ImageProcessingService()
    
    private func getTestImageURL() throws -> URL {
        // Create a test image programmatically instead of relying on bundle resources
        let tempDir = FileManager.default.temporaryDirectory
        let testImageURL = tempDir.appendingPathComponent("test_image.jpeg")
        
        // Create a simple test image if it doesn't exist
        if !FileManager.default.fileExists(atPath: testImageURL.path) {
            let testImage = createTestImage()
            guard let imageData = testImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: imageData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else {
                throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create test image data"])
            }
            
            try jpegData.write(to: testImageURL)
        }
        
        return testImageURL
    }
    
    private func createTestImage() -> NSImage {
        let size = NSSize(width: 200, height: 200)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
    
    @Test("图片格式枚举测试")
    func testImageFormatEnum() {
        // Test all supported formats
        let formats = ImageFormat.allCases
        #expect(formats.count >= 7)
        
        // Test format properties
        let pngFormat = ImageFormat.png
        #expect(pngFormat.displayName == "PNG")
        #expect(pngFormat.fileExtension == "png")
        
        let jpegFormat = ImageFormat.jpeg(quality: 0.8)
        #expect(jpegFormat.displayName == "JPEG")
        #expect(jpegFormat.fileExtension == "jpg")
        
        let webpFormat = ImageFormat.webp
        #expect(webpFormat.displayName == "WebP")
        #expect(webpFormat.fileExtension == "webp")
    }
    
    @Test("图片操作枚举测试")
    func testImageOperationEnum() {
        let size = NSSize(width: 800, height: 600)
        let cropRect = NSRect(x: 10, y: 10, width: 100, height: 100)
        
        // Test all operation types
        let resizeOp = ImageOperation.resize(size: size, maintainAspectRatio: true)
        let convertOp = ImageOperation.convert(format: .png)
        let compressOp = ImageOperation.compress(quality: 0.7)
        let cropOp = ImageOperation.crop(rect: cropRect)
        let textWatermarkOp = ImageOperation.addTextWatermark(
            text: "Test",
            font: NSFont.systemFont(ofSize: 24),
            color: .white,
            opacity: 0.7,
            position: .bottomRight
        )
        let imageWatermarkOp = ImageOperation.addImageWatermark(
            watermarkImage: createTestImage(),
            opacity: 0.5,
            position: .center,
            scale: 0.2
        )
        
        // Verify operations can be created (enums are always non-nil)
        _ = resizeOp
        _ = convertOp
        _ = compressOp
        _ = cropOp
        _ = textWatermarkOp
        _ = imageWatermarkOp
    }
    
    @Test("处理结果模型测试")
    func testProcessingResult() {
        let url = URL(fileURLWithPath: "/test/image.jpg")
        let result = ProcessingResult(
            originalURL: url,
            processedImage: nil,
            success: true,
            error: nil
        )
        
        #expect(result.originalURL == url)
        #expect(result.processedImage == nil)
        #expect(result.success == true)
        #expect(result.error == nil)
    }
    
    @Test("服务初始化测试")
    func testServiceInitialization() {
        #expect(service.isProcessing == false)
        #expect(service.errorMessage == nil)
    }
    
    @Test("有效URL加载图片测试")
    func testLoadImageWithValidURL() throws {
        let testImageURL = try getTestImageURL()
        let image = service.loadImage(from: testImageURL)
        
        #expect(image != nil)
        #expect(service.errorMessage == nil)
        #expect((image?.size.width ?? 0) > 0)
        #expect((image?.size.height ?? 0) > 0)
    }
    
    @Test("无效URL加载图片测试")
    func testLoadImageWithInvalidURL() {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/image.jpg")
        let image = service.loadImage(from: invalidURL)
        
        #expect(image == nil)
        #expect(service.errorMessage != nil)
        #expect(service.errorMessage == "无法加载图片")
    }
    
    @Test("有效图片调整大小测试")
    func testResizeImageWithValidImage() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        let targetSize = NSSize(width: 200, height: 200)
        let resizedImage = service.resizeImage(testImage, to: targetSize, maintainAspectRatio: false)
        
        #expect(resizedImage != nil)
        #expect(abs((resizedImage?.size.width ?? 0) - targetSize.width) < 1.0)
        #expect(abs((resizedImage?.size.height ?? 0) - targetSize.height) < 1.0)
    }
    
    @Test("保持宽高比调整大小测试")
    func testResizeImageWithAspectRatio() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        let originalSize = testImage.size
        let targetSize = NSSize(width: 300, height: 300)
        let resizedImage = service.resizeImage(testImage, to: targetSize, maintainAspectRatio: true)
        
        #expect(resizedImage != nil)
        
        // Calculate expected size maintaining aspect ratio
        let originalAspectRatio = originalSize.width / originalSize.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        let expectedSize: NSSize
        if originalAspectRatio > targetAspectRatio {
            // Image is wider than target
            expectedSize = NSSize(width: targetSize.width, height: targetSize.width / originalAspectRatio)
        } else {
            // Image is taller than target
            expectedSize = NSSize(width: targetSize.height * originalAspectRatio, height: targetSize.height)
        }
        
        #expect(abs((resizedImage?.size.width ?? 0) - expectedSize.width) < 1.0)
        #expect(abs((resizedImage?.size.height ?? 0) - expectedSize.height) < 1.0)
    }
    
    @Test("有效图片压缩测试")
    func testCompressImageWithValidImage() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        let highQualityData = service.compressImage(testImage, quality: 0.9)
        let lowQualityData = service.compressImage(testImage, quality: 0.1)
        
        #expect(highQualityData != nil)
        #expect(lowQualityData != nil)
        #expect((highQualityData?.count ?? 0) > 0)
        #expect((lowQualityData?.count ?? 0) > 0)
        
        // High quality should produce larger file size than low quality
        #expect((highQualityData?.count ?? 0) > (lowQualityData?.count ?? 0))
    }
    
    @Test("空数组批量处理测试")
    func testBatchProcessingWithEmptyArray() async {
        let results = await service.batchProcess(urls: [], operations: [])
        
        #expect(results.isEmpty)
        #expect(service.isProcessing == false)
    }
    
    @Test("有效图片批量处理测试")
    func testBatchProcessingWithValidImage() async throws {
        let testImageURL = try getTestImageURL()
        let operations: [ImageOperation] = [
            .resize(size: NSSize(width: 150, height: 150), maintainAspectRatio: true),
            .compress(quality: 0.8)
        ]
        
        let results = await service.batchProcess(urls: [testImageURL], operations: operations)
        
        #expect(results.count == 1)
        #expect(results[0].success == true)
        #expect(results[0].processedImage != nil)
        #expect(results[0].error == nil)
        #expect(results[0].originalURL == testImageURL)
    }
    
    @Test("无效URL批量处理测试")
    func testBatchProcessingWithInvalidURLs() async {
        let invalidURLs = [
            URL(fileURLWithPath: "/nonexistent1.jpg"),
            URL(fileURLWithPath: "/nonexistent2.png")
        ]
        
        let results = await service.batchProcess(urls: invalidURLs, operations: [])
        
        #expect(results.count == 2)
        #expect(results[0].success == false)
        #expect(results[1].success == false)
        #expect(results[0].error == "加载失败")
        #expect(results[1].error == "加载失败")
    }
    
    @Test("图片转PNG测试")
    func testConvertImageToPNG() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        let pngData = service.convertImage(testImage, to: .png)
        
        #expect(pngData != nil)
        #expect((pngData?.count ?? 0) > 0)
        
        // Verify it's actually PNG data by checking the header
        if let data = pngData, data.count >= 8 {
            let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
            let dataHeader = data.prefix(8)
            #expect(dataHeader == pngHeader, "Data should have PNG header")
        }
    }
    
    @Test("图片转JPEG测试")
    func testConvertImageToJPEG() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        let highQualityJpeg = service.convertImage(testImage, to: .jpeg(quality: 0.9))
        let lowQualityJpeg = service.convertImage(testImage, to: .jpeg(quality: 0.3))
        
        #expect(highQualityJpeg != nil)
        #expect(lowQualityJpeg != nil)
        #expect((highQualityJpeg?.count ?? 0) > 0)
        #expect((lowQualityJpeg?.count ?? 0) > 0)
        
        // High quality should produce larger file size
        #expect((highQualityJpeg?.count ?? 0) > (lowQualityJpeg?.count ?? 0))
        
        // Verify JPEG header (FF D8)
        if let data = highQualityJpeg, data.count >= 2 {
            #expect(data[0] == 0xFF)
            #expect(data[1] == 0xD8)
        }
    }
    
    @Test("不支持格式转换测试")
    func testConvertImageToUnsupportedFormat() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        // Clear any previous error messages
        service.errorMessage = nil
        
        let webpData = service.convertImage(testImage, to: .webp)
        #expect(webpData == nil)
        #expect(service.errorMessage == "WebP格式暂不支持")
        
        // Clear error message for next test
        service.errorMessage = nil
        
        let heicData = service.convertImage(testImage, to: .heic)
        #expect(heicData == nil)
        #expect(service.errorMessage == "HEIC格式暂不支持")
    }
    
    @Test("图片处理性能测试", .timeLimit(.minutes(1)))
    func testImageProcessingPerformance() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        // Test resize performance
        _ = service.resizeImage(testImage, to: NSSize(width: 500, height: 500), maintainAspectRatio: true)
    }
    
    @Test("图片质量对比测试")
    func testImageQualityComparison() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        let qualities: [Double] = [0.1, 0.5, 0.9]
        var dataSizes: [Int] = []
        
        for quality in qualities {
            if let data = service.compressImage(testImage, quality: quality) {
                dataSizes.append(data.count)
            }
        }
        
        #expect(dataSizes.count == 3)
        // Verify that higher quality produces larger files
        #expect(dataSizes[0] < dataSizes[1]) // 0.1 < 0.5
        #expect(dataSizes[1] < dataSizes[2]) // 0.5 < 0.9
    }
    
    // MARK: - Advanced Feature Tests
    
    @Test("图片裁剪功能测试")
    func testImageCropping() {
        let testImage = createTestImage()
        
        // Test cropping to a smaller rectangle
        let cropRect = NSRect(x: 50, y: 50, width: 100, height: 100)
        let croppedImage = service.cropImage(testImage, to: cropRect)
        
        #expect(croppedImage != nil)
        #expect(croppedImage?.size.width == cropRect.width)
        #expect(croppedImage?.size.height == cropRect.height)
    }
    
    @Test("图片裁剪边界测试")
    func testImageCroppingBounds() {
        let testImage = createTestImage()
        
        // Test cropping with invalid bounds (outside image)
        let invalidCropRect = NSRect(x: 300, y: 300, width: 100, height: 100)
        let result = service.cropImage(testImage, to: invalidCropRect)
        
        // Should handle gracefully
        #expect(result == nil || service.errorMessage != nil)
    }
    
    @Test("文字水印功能测试")
    func testTextWatermark() {
        let testImage = createTestImage()
        let watermarkText = "Test Watermark"
        let font = NSFont.systemFont(ofSize: 24)
        let color = NSColor.white
        let opacity = 0.7
        let position = WatermarkPosition.bottomRight
        
        let watermarkedImage = service.addTextWatermark(
            to: testImage,
            text: watermarkText,
            font: font,
            color: color,
            opacity: opacity,
            position: position
        )
        
        #expect(watermarkedImage != nil)
        #expect(watermarkedImage?.size == testImage.size)
    }
    
    @Test("文字水印位置测试", arguments: WatermarkPosition.allCases)
    func testTextWatermarkPositions(position: WatermarkPosition) {
        let testImage = createTestImage()
        
        let watermarkedImage = service.addTextWatermark(
            to: testImage,
            text: "Test",
            position: position
        )
        
        #expect(watermarkedImage != nil)
        #expect(watermarkedImage?.size == testImage.size)
    }
    
    @Test("图片水印功能测试")
    func testImageWatermark() {
        let testImage = createTestImage()
        let watermarkImage = createTestImage()
        
        let watermarkedImage = service.addImageWatermark(
            to: testImage,
            watermarkImage: watermarkImage,
            opacity: 0.5,
            position: .center,
            scale: 0.2
        )
        
        #expect(watermarkedImage != nil)
        #expect(watermarkedImage?.size == testImage.size)
    }
    
    @Test("增强格式转换测试")
    func testEnhancedFormatConversion() {
        let testImage = createTestImage()
        
        // Test conversion to different formats
        let formats: [ImageFormat] = [.png, .jpeg(quality: 0.8), .gif, .tiff, .bmp]
        
        for format in formats {
            let convertedData = service.convertImageToFormat(testImage, format: format)
            #expect(convertedData != nil, "Failed to convert to \(format.displayName)")
            #expect((convertedData?.count ?? 0) > 0, "Converted data is empty for \(format.displayName)")
        }
    }
    
    @Test("WebP格式支持评估测试")
    func testWebPFormatSupport() {
        let testImage = createTestImage()
        
        // Clear any previous error messages
        service.errorMessage = nil
        
        let webpData = service.convertImageToFormat(testImage, format: .webp)
        
        // Currently WebP is not supported, should fallback to JPEG
        #expect(webpData != nil, "WebP conversion should fallback to JPEG")
        #expect(service.errorMessage?.contains("WebP格式暂不支持") == true)
    }
    
    @Test("水印位置计算测试")
    func testWatermarkPositionCalculation() {
        let imageSize = NSSize(width: 400, height: 300)
        let textSize = NSSize(width: 100, height: 20)
        let margin: CGFloat = 10
        
        // Test all watermark positions
        for position in WatermarkPosition.allCases {
            let rect = service.calculateWatermarkRect(
                textSize: textSize,
                imageSize: imageSize,
                position: position,
                margin: margin
            )
            
            // Verify rect is within image bounds
            #expect(rect.origin.x >= 0)
            #expect(rect.origin.y >= 0)
            #expect(rect.maxX <= imageSize.width)
            #expect(rect.maxY <= imageSize.height)
            #expect(rect.size == textSize)
        }
    }
    
    @Test("批量处理高级功能测试")
    func testBatchProcessingWithAdvancedFeatures() async throws {
        let testImageURL = try getTestImageURL()
        
        let operations: [ImageOperation] = [
            .crop(rect: NSRect(x: 10, y: 10, width: 100, height: 100)),
            .addTextWatermark(
                text: "Batch Test",
                font: NSFont.systemFont(ofSize: 16),
                color: .white,
                opacity: 0.8,
                position: .bottomRight
            ),
            .resize(size: NSSize(width: 150, height: 150), maintainAspectRatio: true),
            .convert(format: .png)
        ]
        
        let results = await service.batchProcess(urls: [testImageURL], operations: operations)
        
        #expect(results.count == 1)
        #expect(results[0].success == true)
        #expect(results[0].processedImage != nil)
        #expect(results[0].error == nil)
    }
    
    @Test("性能测试 - 高级图片处理", .timeLimit(.minutes(1)))
    func testAdvancedProcessingPerformance() throws {
        let testImageURL = try getTestImageURL()
        guard let testImage = service.loadImage(from: testImageURL) else {
            Issue.record("Failed to load test image")
            return
        }
        
        // Test cropping performance
        let cropRect = NSRect(x: 10, y: 10, width: 100, height: 100)
        _ = service.cropImage(testImage, to: cropRect)
        
        // Test watermark performance
        _ = service.addTextWatermark(
            to: testImage,
            text: "Performance Test",
            font: NSFont.systemFont(ofSize: 24),
            color: .white,
            opacity: 0.7,
            position: .center
        )
        
        // Test format conversion performance
        _ = service.convertImageToFormat(testImage, format: .png)
    }
    
    @Test("错误处理测试")
    func testErrorHandling() {
        // Test with nil image data
        let invalidImage = NSImage()
        
        service.errorMessage = nil
        let cropResult = service.cropImage(invalidImage, to: NSRect(x: 0, y: 0, width: 100, height: 100))
        #expect(cropResult == nil)
        #expect(service.errorMessage != nil)
        
        // Test watermark with empty text
        service.errorMessage = nil
        let watermarkResult = service.addTextWatermark(to: invalidImage, text: "")
        #expect(watermarkResult != nil) // Should still work with empty text
    }
}