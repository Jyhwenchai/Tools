import SwiftUI

/// Main color processing tool view that orchestrates all color functionality
struct ColorProcessingView: View {

    // MARK: - State Objects

    @State private var conversionService = ColorConversionService()
    @StateObject private var samplingService = ColorSamplingService()
    @StateObject private var paletteService = ColorPaletteService()

    // MARK: - State Properties

    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isInitialized: Bool = false
    @State private var selectedColor: Color = .gray

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Color picker section
                colorPickerSection

                // Color format display section
                colorFormatSection

                // Screen sampling section
                screenSamplingSection

                // Color palette section
                colorPaletteSection
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
        .onChange(of: conversionService.currentColor) { _, newColor in
            // Announce color changes for accessibility
            announceColorChange(newColor)
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])  // Focus color picker
        .onKeyPress(.tab) {
            // Handle tab navigation between sections
            return .ignored  // Let system handle tab navigation
        }
        .onKeyPress(.escape) {
            // Handle escape key for canceling operations
            if samplingService.isActive {
                samplingService.stopScreenSampling()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - View Sections

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
            ColorPickerView(selectedColor: $selectedColor)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color Picker Section")
        .accessibilityHint("Interactive color picker for selecting colors visually")
        .onChange(of: selectedColor) { _, newColor in
            // Convert SwiftUI Color to ColorRepresentation
          updateColorRepresentation(from: newColor)
//          selectedColor = swiftUIColor(from: colorRep.rgb)
        }
//        .onChange(of: conversionService.currentColor) { _, newColorRep in
//            // Convert ColorRepresentation to SwiftUI Color
//            if let colorRep = newColorRep {
//                selectedColor = swiftUIColor(from: colorRep.rgb)
//            }
//        }
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

    private var colorPaletteSection: some View {
        GroupBox("Saved Colors") {
            ColorPaletteViewWrapper(
                paletteService: paletteService,
                currentColor: conversionService.currentColor,
                onColorSelected: handleColorSelected
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Saved Colors Section")
        .accessibilityHint("Manage your saved color palette")
    }

    // MARK: - Helper Methods

    private func setupInitialState() {
        // Initialize with a default color for better UX
        let defaultRGB = RGBColor(red: 128, green: 128, blue: 128, alpha: 1.0)
        let defaultColor = ColorRepresentation(
            rgb: defaultRGB,
            hex: "#808080",
            hsl: HSLColor(hue: 0, saturation: 0, lightness: 50, alpha: 1.0),
            hsv: HSVColor(hue: 0, saturation: 0, value: 50, alpha: 1.0),
            cmyk: CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 50),
            lab: LABColor(lightness: 53.6, a: 0, b: 0)
        )

        conversionService.currentColor = defaultColor

        // Load saved palette
        Task {
            await paletteService.loadPalette()
        }
    }

    private func handleColorSampled(_ color: ColorRepresentation) {
        // Update current color with sampled color
        conversionService.currentColor = color
    }

    private func handleColorSelected(_ color: ColorRepresentation) {
        // Update current color with selected color from palette
        conversionService.currentColor = color
    }

    private func handleError(_ error: ColorProcessingError) {
        errorMessage = error.localizedDescription
        showingError = true
    }

    /// Convert SwiftUI Color to ColorRepresentation
    private func updateColorRepresentation(from color: Color) {
        let rgbColor = rgbColor(from: color)

        // Use the conversion service to create a proper ColorRepresentation
        let result = conversionService.createColorRepresentation(
            from: .rgb,
            value:
                "rgba(\(Int(rgbColor.red)), \(Int(rgbColor.green)), \(Int(rgbColor.blue)), \(rgbColor.alpha))"
        )

        switch result {
        case .success(let representation):
            conversionService.currentColor = representation
        case .failure(let error):
            print("Color conversion failed: \(error)")
            // Fallback to basic representation
            conversionService.currentColor = createBasicColorRepresentation(from: rgbColor)
        }
    }

    /// Convert SwiftUI Color to RGBColor
    private func rgbColor(from color: Color) -> RGBColor {
        let nsColor = NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return RGBColor(
            red: Double(red * 255),
            green: Double(green * 255),
            blue: Double(blue * 255),
            alpha: Double(alpha)
        )
    }

    /// Convert RGBColor to SwiftUI Color
    private func swiftUIColor(from rgb: RGBColor) -> Color {
        return Color(
            red: rgb.red / 255.0,
            green: rgb.green / 255.0,
            blue: rgb.blue / 255.0,
            opacity: rgb.alpha
        )
    }

    /// Create basic ColorRepresentation as fallback
    private func createBasicColorRepresentation(from rgb: RGBColor) -> ColorRepresentation {
        let hex = String(format: "#%02X%02X%02X", Int(rgb.red), Int(rgb.green), Int(rgb.blue))

        return ColorRepresentation(
            rgb: rgb,
            hex: hex,
            hsl: HSLColor(hue: 0, saturation: 0, lightness: 50, alpha: rgb.alpha),
            hsv: HSVColor(hue: 0, saturation: 0, value: 50, alpha: rgb.alpha),
            cmyk: CMYKColor(cyan: 0, magenta: 0, yellow: 0, key: 0),
            lab: LABColor(lightness: 50, a: 0, b: 0)
        )
    }

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
            "Color changed to \(color.hexString), RGB \(Int(color.rgb.red)), \(Int(color.rgb.green)), \(Int(color.rgb.blue))"
        if let app = NSApp {
            NSAccessibility.post(
                element: app, notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement
                ])
        }
    }
}

// MARK: - Color Palette Wrapper

private struct ColorPaletteViewWrapper: View {
    @ObservedObject var paletteService: ColorPaletteService
    let currentColor: ColorRepresentation?
    let onColorSelected: (ColorRepresentation) -> Void

    var body: some View {
        ColorPaletteView(
            paletteService: paletteService,
            onColorSelected: onColorSelected,
            currentColor: currentColor
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ColorProcessingView()
    }
}
