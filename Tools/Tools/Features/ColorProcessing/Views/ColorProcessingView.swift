import SwiftUI

/// 主要的颜色处理工具视图，协调所有颜色功能
/// Main color processing tool view that orchestrates all color functionality
struct ColorProcessingView: View {

    // MARK: - 状态对象 / State Objects

    @State private var conversionService = ColorConversionService()
    @StateObject private var samplingService = ColorSamplingService()

    // MARK: - 状态属性 / State Properties

    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isInitialized: Bool = false

    // MARK: - 主体视图 / Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题部分 / Header
                headerSection

                // 颜色选择器部分 / Color picker section
                colorPickerSection

                // 颜色格式显示部分 / Color format display section
                colorFormatSection

                // 屏幕取色部分 / Screen sampling section
                screenSamplingSection
            }
            .padding()
        }
        .navigationTitle("Color Processing")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color Processing Tool")
        .accessibilityHint(
            "A comprehensive tool for color conversion, picking, and screen sampling"
        )
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if !isInitialized {
                setupInitialState()
                isInitialized = true
            }
        }
        .onChange(of: conversionService.currentColor) { oldColor, newColor in
            // 为辅助功能宣布颜色变化 / Announce color changes for accessibility
            announceColorChange(newColor)
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])  // 聚焦颜色选择器 / Focus color picker
        .onKeyPress(.tab) {
            // 处理标签页导航 / Handle tab navigation between sections
            return .ignored  // 让系统处理标签页导航 / Let system handle tab navigation
        }
        .onKeyPress(.escape) {
            // 处理取消操作的 Escape 键 / Handle escape key for canceling operations
            if samplingService.isActive {
                samplingService.stopScreenSampling()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - 视图部分 / View Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Processing Tool")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)

            Text(
                "Convert colors between formats, pick colors interactively, and sample from screen"
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .accessibilityLabel(
                "Tool description: Convert colors between formats, pick colors interactively, and sample from screen"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Color Processing Tool header")
    }

    private var colorPickerSection: some View {
        GroupBox("Color Picker") {
            ColorPickerViewWrapper(conversionService: conversionService)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color Picker Section")
        .accessibilityHint("Interactive color picker for selecting colors visually")
    }

    private var colorFormatSection: some View {
        GroupBox("Color Formats") {
            ColorFormatView(
                color: $conversionService.currentColor,
                conversionService: conversionService
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color Formats Section")
        .accessibilityHint("Display and edit color values in different formats like RGB, Hex, HSL")
    }

    private var screenSamplingSection: some View {
        GroupBox("Screen Sampling") {
            ScreenSamplerView(
                samplingService: samplingService,
                onColorSampled: handleColorSampled
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Screen Sampling Section")
        .accessibilityHint("Sample colors directly from anywhere on your screen")
    }

    // MARK: - 辅助方法 / Helper Methods

    private func setupInitialState() {
        // 使用默认颜色初始化以提供更好的用户体验
        // Initialize with a default color for better UX
        let defaultRGB = RGBColor(red: 128, green: 128, blue: 128, alpha: 1.0)
        let defaultColor = ColorConversionUtils.createBasicColorRepresentation(from: defaultRGB)

        conversionService.currentColor = defaultColor
    }

    private func handleColorSampled(_ color: ColorRepresentation) {
        // 使用采样的颜色更新当前颜色
        // Update current color with sampled color
        conversionService.currentColor = color
    }

    private func handleError(_ error: ColorProcessingError) {
        errorMessage = error.localizedDescription
        showingError = true
    }

    /// 向 VoiceOver 用户宣布颜色变化
    /// Announce color changes to VoiceOver users
    private func announceColorChange(_ color: ColorRepresentation?) {
        guard let color = color else {
            if let app = NSApp {
                NSAccessibility.post(
                    element: app, notification: .announcementRequested,
                    userInfo: [
                        .announcement: "Color cleared"
                    ])
            }
            return
        }

        let announcement =
            "Color changed to \(color.hexString), \(ColorConversionUtils.colorDescription(for: color))"
        if let app = NSApp {
            NSAccessibility.post(
                element: app, notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement
                ])
        }
    }
}

// MARK: - 颜色选择器包装器 / Color Picker Wrapper

/// 连接 ColorPickerView 和 ColorConversionService 的包装器
/// Wrapper that connects ColorPickerView and ColorConversionService
private struct ColorPickerViewWrapper: View {
    @Bindable var conversionService: ColorConversionService
    @State private var selectedColor: Color = .gray

    var body: some View {
        ColorPickerView(selectedColor: $selectedColor)
            .onChange(of: selectedColor) { oldColor, newColor in
                // 将 SwiftUI Color 转换为 ColorRepresentation
                // Convert SwiftUI Color to ColorRepresentation
                updateColorRepresentation(from: newColor)
            }
            .onChange(of: conversionService.currentColor) { oldColorRep, newColorRep in
                // 将 ColorRepresentation 转换为 SwiftUI Color
                // Convert ColorRepresentation to SwiftUI Color
                if let colorRep = newColorRep {
                    let newSwiftUIColor = ColorConversionUtils.swiftUIColor(from: colorRep)
                    if !ColorConversionUtils.areColorsEqual(selectedColor, newSwiftUIColor) {
                        selectedColor = newSwiftUIColor
                    }
                }
            }
            .onAppear {
                // 初始化时同步颜色
                // Sync color on initialization
                if let currentColor = conversionService.currentColor {
                    selectedColor = ColorConversionUtils.swiftUIColor(from: currentColor)
                }
            }
    }

    /// 从 SwiftUI Color 更新 ColorRepresentation
    /// Update ColorRepresentation from SwiftUI Color
    private func updateColorRepresentation(from color: Color) {
        let rgbColor = ColorConversionUtils.rgbColor(from: color)

        // 使用转换服务创建适当的 ColorRepresentation
        // Use the conversion service to create a proper ColorRepresentation
        let result = conversionService.createColorRepresentation(
            from: ColorFormat.rgb,
            value:
                "rgba(\(Int(rgbColor.red)), \(Int(rgbColor.green)), \(Int(rgbColor.blue)), \(rgbColor.alpha))"
        )

        switch result {
        case .success(let representation):
            conversionService.currentColor = representation
        case .failure(let error):
            print("Color conversion failed: \(error)")
            // 使用基础表示作为备用方案
            // Fallback to basic representation
            conversionService.currentColor = ColorConversionUtils.createBasicColorRepresentation(
                from: rgbColor)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ColorProcessingView()
    }
}
