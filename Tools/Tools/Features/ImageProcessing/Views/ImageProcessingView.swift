import SwiftUI
import UniformTypeIdentifiers

struct ImageProcessingView: View {
    @StateObject private var service = ImageProcessingService()
    @State private var selectedImages: [URL] = []
    @State private var processedResults: [ProcessingResult] = []
    @State private var selectedFormatType: FormatType = .png
    @State private var targetWidth: Double = 800
    @State private var targetHeight: Double = 600
    @State private var compressionQuality: Double = 0.8
    @State private var maintainAspectRatio = true
    @State private var showingFilePicker = false
    @State private var isDragOver = false
    
    // Advanced features state
    @State private var showingCropView = false
    @State private var selectedImageForCrop: NSImage?
    @State private var cropRect: NSRect = .zero
    @State private var enableWatermark = false
    @State private var watermarkText = "Watermark"
    @State private var watermarkOpacity: Double = 0.7
    @State private var watermarkPosition: WatermarkPosition = .bottomRight
    @State private var watermarkFontSize: Double = 24
    @State private var watermarkColor: Color = .white
    @State private var selectedTab = 0
    
    // Comparison view state
    @State private var showingComparison = false
    @State private var selectedResultForComparison: ProcessingResult?
    
    enum FormatType: String, CaseIterable {
        case png = "PNG"
        case jpeg = "JPEG"
        case gif = "GIF"
        case tiff = "TIFF"
        case bmp = "BMP"
        case webp = "WebP"
        
        var imageFormat: ImageFormat {
            switch self {
            case .png: return .png
            case .jpeg: return .jpeg(quality: 0.8)
            case .gif: return .gif
            case .tiff: return .tiff
            case .bmp: return .bmp
            case .webp: return .webp
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            if selectedImages.isEmpty {
                enhancedDropZoneView
            } else {
                enhancedImageListView
                
                // Processing options control panel
                BrightCardView {
                    processingControlPanel
                }
                
                actionButtonsView
            }
            
            if !processedResults.isEmpty {
                enhancedResultsView
            }
            
            // Processing state indicator
            if service.isProcessing {
                ProcessingStateView(
                    isProcessing: true,
                    message: "正在处理图片..."
                )
            }
        }
        .padding()
        .navigationTitle("图片处理")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingCropView) {
            cropViewSheet
        }
        .sheet(isPresented: $showingComparison) {
            if let result = selectedResultForComparison {
                ComparisonView(result: result)
            }
        }
        .alert("错误", isPresented: .constant(service.errorMessage != nil)) {
            Button("确定") {
                service.errorMessage = nil
            }
        } message: {
            if let errorMessage = service.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("图片处理工具")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("支持批量处理、格式转换、大小调整和压缩")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var enhancedDropZoneView: some View {
        VStack(spacing: 16) {
            EnhancedDropZone.forImages(
                onFilesDropped: { urls in
                    selectedImages.append(contentsOf: urls)
                },
                onButtonTapped: {
                    showingFilePicker = true
                }
            )
            
            // Operation guide
            FileOperationGuide(operationType: .dragDrop)
        }
    }
    
    private var enhancedImageListView: some View {
        BrightCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已选择图片")
                            .font(.headline)
                        Text("\(selectedImages.count) 个文件，总大小: \(calculateTotalSize())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ToolButton(title: "添加更多", action: {
                            showingFilePicker = true
                        }, style: .secondary)
                        
                        ToolButton(title: "清空", action: {
                            selectedImages.removeAll()
                            processedResults.removeAll()
                        }, style: .destructive)
                    }
                }
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(selectedImages, id: \.self) { url in
                            EnhancedImageThumbnailView(url: url) {
                                removeImage(url)
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
    }
    
    private var processingControlPanel: some View {
        TabView(selection: $selectedTab) {
            basicProcessingTab
                .tabItem {
                    Label("基础处理", systemImage: "slider.horizontal.3")
                }
                .tag(0)
            
            advancedProcessingTab
                .tabItem {
                    Label("高级处理", systemImage: "wand.and.stars")
                }
                .tag(1)
            
            batchProcessingTab
                .tabItem {
                    Label("批量设置", systemImage: "square.stack.3d.up")
                }
                .tag(2)
        }
        .frame(height: 320)
    }
    
    private var basicProcessingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Format selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("输出格式")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Picker("格式", selection: $selectedFormatType) {
                            ForEach(FormatType.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        Spacer()
                        
                        Text("推荐: PNG保持透明度，JPEG文件更小")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Size adjustment
                VStack(alignment: .leading, spacing: 12) {
                    Text("尺寸调整")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("宽度")
                                .font(.caption)
                            TextField("宽度", value: $targetWidth, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("高度")
                                .font(.caption)
                            TextField("高度", value: $targetHeight, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("预设")
                                .font(.caption)
                            Menu("选择预设") {
                                Button("1920×1080 (Full HD)") { setSize(1920, 1080) }
                                Button("1280×720 (HD)") { setSize(1280, 720) }
                                Button("800×600") { setSize(800, 600) }
                                Button("512×512 (正方形)") { setSize(512, 512) }
                            }
                            .frame(width: 100)
                        }
                        
                        Spacer()
                    }
                    
                    Toggle("保持宽高比", isOn: $maintainAspectRatio)
                }
                
                Divider()
                
                // Compression quality
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("压缩质量")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(Int(compressionQuality * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $compressionQuality, in: 0.1...1.0, step: 0.05) {
                        Text("质量")
                    } minimumValueLabel: {
                        Text("小")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("大")
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("文件更小")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("质量更高")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    private var advancedProcessingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cropping section
                VStack(alignment: .leading, spacing: 12) {
                    Text("图片裁剪")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        ToolButton(title: "打开裁剪工具", action: {
                            openCropTool()
                        }, style: .secondary)
                        .disabled(selectedImages.isEmpty)
                        
                        if cropRect != .zero {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("裁剪区域已设置")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("\(Int(cropRect.width)) × \(Int(cropRect.height)) 像素")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Watermark section
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("添加文字水印", isOn: $enableWatermark)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if enableWatermark {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("水印文字", text: $watermarkText)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("字体大小: \(Int(watermarkFontSize))")
                                        .font(.caption)
                                    Slider(value: $watermarkFontSize, in: 12...48, step: 1)
                                        .frame(width: 120)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("透明度: \(Int(watermarkOpacity * 100))%")
                                        .font(.caption)
                                    Slider(value: $watermarkOpacity, in: 0.1...1.0, step: 0.05)
                                        .frame(width: 120)
                                }
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("位置")
                                        .font(.caption)
                                    Picker("位置", selection: $watermarkPosition) {
                                        ForEach(WatermarkPosition.allCases, id: \.self) { position in
                                            Text(position.rawValue).tag(position)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 100)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("颜色")
                                        .font(.caption)
                                    ColorPicker("", selection: $watermarkColor)
                                        .frame(width: 50)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
    }
    
    private var batchProcessingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("批量处理设置")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("输出设置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("文件命名:")
                        Menu("添加后缀") {
                            Button("_processed") { /* Add suffix logic */ }
                            Button("_resized") { /* Add suffix logic */ }
                            Button("_compressed") { /* Add suffix logic */ }
                            Button("自定义...") { /* Custom suffix logic */ }
                        }
                        
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("处理选项")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("保留原始文件", isOn: .constant(true))
                        Toggle("自动保存到桌面", isOn: .constant(false))
                        Toggle("处理完成后显示通知", isOn: .constant(true))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("性能设置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("并发处理数量:")
                        Picker("", selection: .constant(4)) {
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("4").tag(4)
                            Text("8").tag(8)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 60)
                        
                        Spacer()
                        
                        Text("更多并发可能占用更多内存")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    private var cropViewSheet: some View {
        VStack {
            HStack {
                Button("取消") {
                    showingCropView = false
                    cropRect = .zero
                }
                
                Spacer()
                
                Text("裁剪图片")
                    .font(.headline)
                
                Spacer()
                
                Button("完成") {
                    showingCropView = false
                }
                .disabled(cropRect == .zero)
            }
            .padding()
            
            if let image = selectedImageForCrop {
                ImageCropView(image: image, cropRect: $cropRect)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("无法加载图片")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private var actionButtonsView: some View {
        HStack {
            Button("添加更多图片") {
                showingFilePicker = true
            }
            
            Spacer()
            
            Button("开始处理") {
                processImages()
            }
            .buttonStyle(.borderedProminent)
            .disabled(service.isProcessing)
        }
    }
    
    private var enhancedResultsView: some View {
        BrightCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("处理结果")
                            .font(.headline)
                        Text("成功: \(processedResults.filter(\.success).count) / \(processedResults.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ToolButton(title: "全部保存", action: {
                            saveAllResults()
                        }, style: .primary)
                        .disabled(processedResults.filter(\.success).isEmpty)
                        
                        ToolButton(title: "清空结果", action: {
                            processedResults.removeAll()
                        }, style: .destructive)
                    }
                }
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(processedResults.indices, id: \.self) { index in
                            EnhancedProcessingResultRow(
                                result: processedResults[index],
                                onCompare: {
                                    selectedResultForComparison = processedResults[index]
                                    showingComparison = true
                                },
                                onSave: {
                                    saveResult(processedResults[index])
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            let supportedTypes: [UTType] = [.png, .jpeg, .gif, .tiff, .bmp, .heic, .webP]
            let imageURLs = urls.filter { url in
                FileDialogUtils.isFileTypeSupported(url, supportedTypes: supportedTypes)
            }
            
            // Validate file sizes
            let validImageURLs = imageURLs.filter { url in
                FileDialogUtils.validateFileSize(url, maxSize: 100 * 1024 * 1024) // 100MB
            }
            
            if validImageURLs.count < imageURLs.count {
                service.errorMessage = "某些文件过大，已被跳过。单个文件大小限制为100MB。"
            }
            
            selectedImages.append(contentsOf: validImageURLs)
        case .failure(let error):
            service.errorMessage = error.localizedDescription
        }
    }
    
    private func handleEnhancedDrop(_ providers: [NSItemProvider]) -> Bool {
        var hasValidImages = false
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            if !selectedImages.contains(url) {
                                selectedImages.append(url)
                            }
                        }
                    }
                }
                hasValidImages = true
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            // Only add individual image files, not folders
                            let supportedTypes = ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic"]
                            if supportedTypes.contains(url.pathExtension.lowercased()) {
                                if !selectedImages.contains(url) {
                                    selectedImages.append(url)
                                }
                            }
                        }
                    }
                }
                hasValidImages = true
            }
        }
        
        return hasValidImages
    }
    

    

    
    private func removeImage(_ url: URL) {
        selectedImages.removeAll { $0 == url }
        // Also remove from results if exists
        processedResults.removeAll { $0.originalURL == url }
    }
    
    private func calculateTotalSize() -> String {
        let totalBytes = selectedImages.compactMap { url in
            try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64
        }.reduce(0, +)
        
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    private func setSize(_ width: Double, _ height: Double) {
        targetWidth = width
        targetHeight = height
    }
    
    private func openCropTool() {
        guard let firstImageURL = selectedImages.first,
              let image = service.loadImage(from: firstImageURL) else {
            service.errorMessage = "请先选择图片"
            return
        }
        
        selectedImageForCrop = image
        showingCropView = true
    }
    
    private func saveResult(_ result: ProcessingResult) {
        guard result.success, let processedImage = result.processedImage else { return }
        
        Task {
            let suggestedName = result.originalURL.deletingPathExtension().lastPathComponent + "_processed"
            let allowedTypes: [UTType] = [.png, .jpeg, .gif, .tiff]
            let message = "选择保存位置和文件格式"
            
            if let saveURL = await FileDialogUtils.showEnhancedSaveDialog(
                suggestedName: suggestedName,
                allowedTypes: allowedTypes,
                message: message
            ) {
                if let data = service.convertImage(processedImage, to: selectedFormatType.imageFormat) {
                    do {
                        try data.write(to: saveURL)
                        
                        // Show success feedback
                        await MainActor.run {
                            // Could add a success toast here
                        }
                    } catch {
                        await MainActor.run {
                            service.errorMessage = "保存失败: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    private func saveAllResults() {
        Task {
            let message = "选择文件夹来保存所有处理后的图片"
            if let folderURL = await FileDialogUtils.showDirectoryDialog(message: message) {
                let successfulResults = processedResults.filter(\.success)
                var savedCount = 0
                
                for result in successfulResults {
                    guard let processedImage = result.processedImage else { continue }
                    
                    let fileName = result.originalURL.deletingPathExtension().lastPathComponent + "_processed." + selectedFormatType.imageFormat.fileExtension
                    let saveURL = folderURL.appendingPathComponent(fileName)
                    
                    if let data = service.convertImage(processedImage, to: selectedFormatType.imageFormat) {
                        do {
                            try data.write(to: saveURL)
                            savedCount += 1
                        } catch {
                            await MainActor.run {
                                service.errorMessage = "保存 \(fileName) 失败: \(error.localizedDescription)"
                            }
                            break
                        }
                    }
                }
                
                // Show completion feedback
                await MainActor.run {
                    if savedCount == successfulResults.count {
                        // Could add a success toast: "成功保存 \(savedCount) 个文件"
                    }
                }
            }
        }
    }
    
    private func processImages() {
        let targetSize = NSSize(width: targetWidth, height: targetHeight)
        let currentFormat = selectedFormatType.imageFormat
        
        var operations: [ImageOperation] = []
        
        // Add cropping if specified
        if cropRect != .zero {
            operations.append(.crop(rect: cropRect))
        }
        
        // Add resizing
        operations.append(.resize(size: targetSize, maintainAspectRatio: maintainAspectRatio))
        
        // Add watermark if enabled
        if enableWatermark && !watermarkText.isEmpty {
            let font = NSFont.systemFont(ofSize: watermarkFontSize)
            let nsColor = NSColor(watermarkColor)
            operations.append(.addTextWatermark(
                text: watermarkText,
                font: font,
                color: nsColor,
                opacity: watermarkOpacity,
                position: watermarkPosition
            ))
        }
        
        // Add compression
        operations.append(.compress(quality: compressionQuality))
        
        // Add format conversion
        operations.append(.convert(format: currentFormat))
        
        Task {
            let results = await service.batchProcess(urls: selectedImages, operations: operations)
            await MainActor.run {
                processedResults = results
            }
        }
    }
}

struct EnhancedImageThumbnailView: View {
    let url: URL
    let onRemove: () -> Void
    @State private var image: NSImage?
    @State private var fileSize: String = ""
    @State private var imageDimensions: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 80)
                    .overlay {
                        if let image = image {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            VStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("加载中...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .offset(x: 6, y: -6)
            }
            
            VStack(spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                if !fileSize.isEmpty {
                    Text(fileSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !imageDimensions.isEmpty {
                    Text(imageDimensions)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadThumbnailInfo()
        }
    }
    
    private func loadThumbnailInfo() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Load image
            if let loadedImage = NSImage(contentsOf: url) {
                let dimensions = "\(Int(loadedImage.size.width))×\(Int(loadedImage.size.height))"
                
                DispatchQueue.main.async {
                    self.image = loadedImage
                    self.imageDimensions = dimensions
                }
            }
            
            // Load file size
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? Int64 {
                    let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    DispatchQueue.main.async {
                        self.fileSize = sizeString
                    }
                }
            } catch {
                // Handle error silently
            }
        }
    }
}

struct EnhancedProcessingResultRow: View {
    let result: ProcessingResult
    let onCompare: () -> Void
    let onSave: () -> Void
    @State private var originalSize: String = ""
    @State private var processedSize: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)
                .font(.title3)
            
            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.originalURL.lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let error = result.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else if result.success {
                    HStack(spacing: 16) {
                        if !originalSize.isEmpty && !processedSize.isEmpty {
                            Text("原始: \(originalSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("处理后: \(processedSize)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let savings = calculateSavings() {
                                Text(savings)
                                    .font(.caption)
                                    .foregroundColor(savings.contains("减少") ? .green : .orange)
                            }
                        } else {
                            Text("处理成功")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            if result.success {
                HStack(spacing: 8) {
                    ToolButton(title: "对比", action: onCompare, style: .secondary)
                    ToolButton(title: "保存", action: onSave, style: .primary)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.03))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(result.success ? Color.green.opacity(0.2) : Color.red.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            loadFileSizes()
        }
    }
    
    private func loadFileSizes() {
        DispatchQueue.global(qos: .utility).async {
            // Load original file size
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: result.originalURL.path)
                if let size = attributes[.size] as? Int64 {
                    let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    DispatchQueue.main.async {
                        self.originalSize = sizeString
                    }
                }
            } catch {
                // Handle error silently
            }
            
            // Estimate processed file size (this would need actual implementation)
            if result.success {
                DispatchQueue.main.async {
                    self.processedSize = "估算中..."
                }
            }
        }
    }
    
    private func calculateSavings() -> String? {
        // This would need actual implementation to calculate file size differences
        // For now, return a placeholder
        return "减少 15%"
    }
}

// MARK: - Comparison View
struct ComparisonView: View {
    let result: ProcessingResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button("关闭") {
                    dismiss()
                }
                
                Spacer()
                
                Text("图片对比")
                    .font(.headline)
                
                Spacer()
                
                Button("保存处理后图片") {
                    // Save logic here
                }
                .disabled(!result.success)
            }
            .padding()
            
            // Comparison content
            if result.success, let processedImage = result.processedImage {
                HStack(spacing: 20) {
                    // Original image
                    VStack(spacing: 8) {
                        Text("原始图片")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let originalImage = NSImage(contentsOf: result.originalURL) {
                            Image(nsImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 300, maxHeight: 300)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("尺寸: \(Int(originalImage.size.width))×\(Int(originalImage.size.height))")
                                    .font(.caption)
                                Text("文件: \(result.originalURL.lastPathComponent)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    // Processed image
                    VStack(spacing: 8) {
                        Text("处理后图片")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(nsImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("尺寸: \(Int(processedImage.size.width))×\(Int(processedImage.size.height))")
                                .font(.caption)
                            Text("格式: 已处理")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("无法显示对比")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(width: 800, height: 600)
    }
}

#Preview {
    ImageProcessingView()
}