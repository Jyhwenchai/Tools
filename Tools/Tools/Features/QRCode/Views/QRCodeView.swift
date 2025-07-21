import SwiftUI
import UniformTypeIdentifiers

/// 二维码工具主界面
struct QRCodeView: View {
  // MARK: - Properties

  @State private var service = QRCodeService()
  @State private var selectedTab: QRCodeTab = .generate

  // 生成相关状态
  @State private var inputText = ""
  @State private var qrCodeOptions = QRCodeOptions()
  @State private var generationResult: QRCodeGenerationResult?
  @State private var isGenerating = false

  // 识别相关状态
  @State private var recognitionImage: NSImage?
  @State private var recognitionResults: [QRCodeRecognitionResult] = []
  @State private var isRecognizing = false
  @State private var isDragOver = false

  // 错误处理
  @State private var errorMessage: String?
  @State private var showingError = false

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      // 标签页选择器
      tabSelector

      Divider()

      // 主内容区域
      TabView(selection: $selectedTab) {
        generateView
          .tabItem {
            Label("生成", systemImage: "qrcode")
          }
          .tag(QRCodeTab.generate)

        recognizeView
          .tabItem {
            Label("识别", systemImage: "qrcode.viewfinder")
          }
          .tag(QRCodeTab.recognize)
      }
      .tabViewStyle(.automatic)
    }
    .navigationTitle("二维码工具")
    .alert("错误", isPresented: $showingError) {
      Button("确定") {}
    } message: {
      Text(errorMessage ?? "未知错误")
    }
  }

  // MARK: - Tab Selector

  private var tabSelector: some View {
    HStack {
      ForEach(QRCodeTab.allCases, id: \.self) { tab in
        Button(action: { selectedTab = tab }) {
          HStack {
            Image(systemName: tab.icon)
            Text(tab.title)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            selectedTab == tab ? Color.accentColor : Color.clear,
            in: RoundedRectangle(cornerRadius: 8))
          .foregroundColor(selectedTab == tab ? .white : .primary)
        }
        .buttonStyle(.plain)
      }

      Spacer()
    }
    .padding()
  }

  // MARK: - Generate View

  private var generateView: some View {
    HSplitView {
      // 左侧：输入和选项
      VStack(alignment: .leading, spacing: 16) {
        // 文本输入区域
        VStack(alignment: .leading, spacing: 8) {
          Text("输入文本")
            .font(.headline)

          TextEditor(text: $inputText)
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 120)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1))

          // 文本验证提示
          if !inputText.isEmpty {
            let validation = service.validateTextForQRCode(inputText)
            HStack {
              Image(systemName: validation
                .isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(validation.isValid ? .green : .orange)

              Text(validation.suggestion ?? (validation.isValid ? "文本有效" : ""))
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }

        // 生成选项
        generateOptionsView

        // 生成按钮
        Button(action: generateQRCode) {
          HStack {
            if isGenerating {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text(isGenerating ? "生成中..." : "生成二维码")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(inputText.isEmpty || isGenerating)

        Spacer()
      }
      .padding()
      .frame(minWidth: 300)

      // 右侧：预览和结果
      VStack(spacing: 16) {
        if let result = generationResult {
          qrCodePreviewView(result: result)
        } else {
          qrCodePlaceholderView
        }
      }
      .padding()
      .frame(minWidth: 300)
    }
  }

  // MARK: - Generate Options View

  private var generateOptionsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("生成选项")
        .font(.headline)

      // 尺寸设置
      VStack(alignment: .leading, spacing: 4) {
        Text("尺寸")
          .font(.subheadline)

        HStack {
          Text("宽度:")
          TextField("宽度", value: Binding(
            get: { Double(qrCodeOptions.size.width) },
            set: { qrCodeOptions.size.width = CGFloat($0) }), format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)

          Text("高度:")
          TextField("高度", value: Binding(
            get: { Double(qrCodeOptions.size.height) },
            set: { qrCodeOptions.size.height = CGFloat($0) }), format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)

          Button("推荐尺寸") {
            qrCodeOptions.size = service.getRecommendedSize(for: inputText.count)
          }
          .buttonStyle(.bordered)
        }
      }

      // 纠错级别
      VStack(alignment: .leading, spacing: 4) {
        Text("纠错级别")
          .font(.subheadline)

        Picker("纠错级别", selection: $qrCodeOptions.correctionLevel) {
          ForEach(QRCodeCorrectionLevel.allCases, id: \.self) { level in
            Text(level.displayName).tag(level)
          }
        }
        .pickerStyle(.segmented)
      }

      // 颜色设置
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("前景色")
            .font(.subheadline)
          ColorPicker("前景色", selection: $qrCodeOptions.foregroundColor)
            .labelsHidden()
        }

        VStack(alignment: .leading, spacing: 4) {
          Text("背景色")
            .font(.subheadline)
          ColorPicker("背景色", selection: $qrCodeOptions.backgroundColor)
            .labelsHidden()
        }
      }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
  }

  // MARK: - QR Code Preview

  private func qrCodePreviewView(result: QRCodeGenerationResult) -> some View {
    VStack(spacing: 16) {
      Text("生成结果")
        .font(.headline)

      // QR码图像
      Image(nsImage: result.image)
        .interpolation(.none)
        .frame(maxWidth: 300, maxHeight: 300)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)

      // 信息显示
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("尺寸:")
          Text("\(Int(result.options.size.width)) × \(Int(result.options.size.height))")
          Spacer()
        }

        HStack {
          Text("纠错级别:")
          Text(result.options.correctionLevel.displayName)
          Spacer()
        }

        HStack {
          Text("生成时间:")
          Text(result.timestamp.formatted(date: .omitted, time: .shortened))
          Spacer()
        }
      }
      .font(.caption)
      .padding()
      .background(Color(NSColor.controlBackgroundColor))
      .cornerRadius(8)

      // 操作按钮
      HStack {
        Button("复制图像") {
          copyImageToPasteboard(result.image)
        }
        .buttonStyle(.bordered)

        Button("保存图像") {
          saveImage(result.image)
        }
        .buttonStyle(.bordered)
      }
    }
  }

  private var qrCodePlaceholderView: some View {
    VStack(spacing: 16) {
      Text("二维码预览")
        .font(.headline)

      RoundedRectangle(cornerRadius: 8)
        .fill(Color(NSColor.controlBackgroundColor))
        .frame(width: 200, height: 200)
        .overlay(
          VStack {
            Image(systemName: "qrcode")
              .font(.system(size: 48))
              .foregroundColor(.secondary)
            Text("输入文本后生成二维码")
              .font(.caption)
              .foregroundColor(.secondary)
          })
    }
  }

  // MARK: - Recognize View

  private var recognizeView: some View {
    VStack(spacing: 16) {
      // 图像上传区域
      imageDropArea

      // 识别结果
      if !recognitionResults.isEmpty {
        recognitionResultsView
      }
    }
    .padding()
  }

  private var imageDropArea: some View {
    VStack(spacing: 16) {
      Text("二维码识别")
        .font(.headline)

      // 拖拽区域
      RoundedRectangle(cornerRadius: 12)
        .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .frame(height: 200)
        .overlay(
          VStack(spacing: 12) {
            if let image = recognitionImage {
              Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 150)
            } else {
              Image(systemName: "photo.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

              Text("拖拽图像到此处或点击选择")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
          })
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(
              isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
              style: StrokeStyle(lineWidth: 2, dash: [8])))
        .onTapGesture {
          selectImage()
        }
        .onDrop(of: [.image], isTargeted: $isDragOver) { providers in
          handleImageDrop(providers: providers)
        }

      // 操作按钮
      HStack {
        Button("选择图像") {
          selectImage()
        }
        .buttonStyle(.bordered)

        if recognitionImage != nil {
          Button("识别二维码") {
            Task {
              await recognizeQRCode()
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(isRecognizing)

          Button("清除") {
            clearRecognition()
          }
          .buttonStyle(.bordered)
        }
      }

      if isRecognizing {
        ProgressView("识别中...")
      }
    }
  }

  private var recognitionResultsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("识别结果")
        .font(.headline)

      ForEach(Array(recognitionResults.enumerated()), id: \.offset) { index, result in
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("结果 \(index + 1)")
              .font(.subheadline)
              .fontWeight(.medium)

            Spacer()

            Text("置信度: \(Int(result.confidence * 100))%")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Text(result.text)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .textSelection(.enabled)

          HStack {
            Button("复制文本") {
              NSPasteboard.general.clearContents()
              NSPasteboard.general.setString(result.text, forType: .string)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Text("识别时间: \(result.timestamp.formatted(date: .omitted, time: .shortened))")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
      }
    }
  }
}

// MARK: - Methods

extension QRCodeView {
  // MARK: - QR Code Generation

  private func generateQRCode() {
    guard !inputText.isEmpty else { return }

    isGenerating = true

    Task {
      do {
        let result = try service.generateQRCode(from: inputText, options: qrCodeOptions)

        await MainActor.run {
          generationResult = result
          isGenerating = false
        }
      } catch {
        await MainActor.run {
          showError(error.localizedDescription)
          isGenerating = false
        }
      }
    }
  }

  // MARK: - QR Code Recognition

  private func recognizeQRCode() async {
    guard let image = recognitionImage else { return }

    isRecognizing = true

    do {
      let results = try await service.recognizeQRCode(from: image)

      await MainActor.run {
        recognitionResults = results
        isRecognizing = false

        if results.isEmpty {
          showError("未在图像中找到二维码")
        }
      }
    } catch {
      await MainActor.run {
        showError(error.localizedDescription)
        isRecognizing = false
      }
    }
  }

  // MARK: - Image Handling

  private func selectImage() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    if panel.runModal() == .OK, let url = panel.url {
      loadImage(from: url)
    }
  }

  private func handleImageDrop(providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }

    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
        if let url = item as? URL {
          DispatchQueue.main.async {
            loadImage(from: url)
          }
        } else if let data = item as? Data, let image = NSImage(data: data) {
          DispatchQueue.main.async {
            recognitionImage = image
            recognitionResults = []
          }
        }
      }
      return true
    }

    return false
  }

  private func loadImage(from url: URL) {
    guard let image = NSImage(contentsOf: url) else {
      showError("无法加载图像文件")
      return
    }

    recognitionImage = image
    recognitionResults = []
  }

  private func clearRecognition() {
    recognitionImage = nil
    recognitionResults = []
  }

  // MARK: - File Operations

  private func copyImageToPasteboard(_ image: NSImage) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([image])
  }

  private func saveImage(_ image: NSImage) {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.nameFieldStringValue = "QRCode_\(Date().timeIntervalSince1970).png"

    if panel.runModal() == .OK, let url = panel.url {
      saveImageToFile(image, url: url)
    }
  }

  private func saveImageToFile(_ image: NSImage, url: URL) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:])
    else {
      showError("无法保存图像")
      return
    }

    do {
      try pngData.write(to: url)
    } catch {
      showError("保存图像失败: \(error.localizedDescription)")
    }
  }

  // MARK: - Error Handling

  private func showError(_ message: String) {
    errorMessage = message
    showingError = true
  }
}

// MARK: - Supporting Types

public enum QRCodeTab: String, CaseIterable {
  case generate
  case recognize

  public var title: String {
    switch self {
    case .generate:
      "生成"
    case .recognize:
      "识别"
    }
  }

  public var icon: String {
    switch self {
    case .generate:
      "qrcode"
    case .recognize:
      "qrcode.viewfinder"
    }
  }
}

// MARK: - Preview

#Preview {
  QRCodeView()
    .frame(width: 800, height: 600)
}
