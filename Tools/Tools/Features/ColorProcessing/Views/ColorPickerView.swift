import SwiftUI

/// Observable model for color picker state
@Observable
class ColorPickerModel {
    var selectedColor: Color = .red
    var colorHistory: [Color] = []
    var supportsOpacity: Bool = true

    private let maxHistoryItems = 10

    func addToHistory(_ color: Color) {
        // Avoid duplicates with stricter comparison
        if !colorHistory.contains(where: { areColorsEqual($0, color) }) {
            colorHistory.insert(color, at: 0)

            // Limit history size
            if colorHistory.count > maxHistoryItems {
                colorHistory = Array(colorHistory.prefix(maxHistoryItems))
            }
        }
    }

    private func areColorsEqual(_ color1: Color, _ color2: Color) -> Bool {
        let rgb1 = rgbColor(from: color1)
        let rgb2 = rgbColor(from: color2)

        return abs(rgb1.red - rgb2.red) < 0.5 && abs(rgb1.green - rgb2.green) < 0.5
            && abs(rgb1.blue - rgb2.blue) < 0.5 && abs(rgb1.alpha - rgb2.alpha) < 0.005
    }

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
}

/// Interactive color picker view with SwiftUI ColorPicker integration
struct ColorPickerView: View {
    // MARK: - Properties

    @Binding var selectedColor: Color
    @State private var model = ColorPickerModel()

    // MARK: - Initializers

    init(selectedColor: Binding<Color>) {
        self._selectedColor = selectedColor
    }

    // MARK: - Constants

    private let swatchSize: CGFloat = 40
    private let historySwatchSize: CGFloat = 30

    // MARK: - Body

    var body: some View {
        @Bindable var bindableModel = model

        VStack(alignment: .leading, spacing: 16) {
            // Color Picker Section
            colorPickerSection

            // Color Swatch Preview
            colorSwatchPreview

            // Color History
            if !model.colorHistory.isEmpty {
                colorHistorySection
            }
        }
        .padding()
        .onChange(of: model.selectedColor) { _, newColor in
            model.addToHistory(newColor)
            selectedColor = newColor
        }
        .onChange(of: selectedColor) { _, newColor in
            if model.selectedColor != newColor {
                model.selectedColor = newColor
                model.addToHistory(newColor)
            }
        }
        .onAppear {
            model.selectedColor = selectedColor
        }
        .onKeyPress(.space) {
            // Toggle opacity support with spacebar
            model.supportsOpacity.toggle()
            announceOpacityToggle()
            return .handled
        }
        .onKeyPress(.return) {
            // Announce current color when Enter is pressed
            announceCurrentColor()
            return .handled
        }
    }

    // MARK: - Color Picker Section

    private var colorPickerSection: some View {
        @Bindable var bindableModel = model

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color Picker")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Opacity Toggle
                Toggle("Opacity", isOn: $bindableModel.supportsOpacity)
                    .toggleStyle(SwitchToggleStyle())
                    .accessibilityLabel("Toggle opacity support")
                    .accessibilityHint("When enabled, allows selecting colors with transparency")
            }

            ColorPicker(
                "Select Color",
                selection: $bindableModel.selectedColor,
                supportsOpacity: model.supportsOpacity
            )
            .labelsHidden()
            .frame(height: 44)
            .accessibilityLabel("Color picker")
            .accessibilityHint(
                "Select a color. \(model.supportsOpacity ? "Opacity adjustment is enabled" : "Only opaque colors can be selected")"
            )
            .accessibilityValue(colorDescription(for: model.selectedColor))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color picker section")
    }

    // MARK: - Color Swatch Preview

    private var colorSwatchPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Preview")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            // Large color swatch
            RoundedRectangle(cornerRadius: 8)
                .fill(model.selectedColor)
                .frame(width: swatchSize * 2, height: swatchSize * 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .accessibilityLabel("Currently selected color")
                .accessibilityValue(colorDescription(for: model.selectedColor))
                .accessibilityHint("Visual preview of the selected color")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color preview section")
    }

    // MARK: - Color History Section

    private var colorHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Colors")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(model.colorHistory.enumerated()), id: \.offset) { index, color in
                        Button(action: {
                            model.selectedColor = color
                            announceColorSelection(color, index: index)
                        }) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(width: historySwatchSize, height: historySwatchSize)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Recent color \(index + 1)")
                        .accessibilityHint("Tap to select this color")
                        .accessibilityValue(colorDescription(for: color))
                        .accessibilityAddTraits(.isButton)
                    }
                }
                .padding(.horizontal, 4)
            }
            .accessibilityLabel("Color history")
            .accessibilityHint("Horizontal scroll view with recently used colors")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recent colors section")
    }

    // MARK: - Helper Methods

    /// Convert SwiftUI Color to RGBColor for comparison
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

    /// Generate accessibility description for color
    private func colorDescription(for color: Color) -> String {
        let rgb = rgbColor(from: color)
        let alpha = rgb.alpha < 1.0 ? ", alpha \(String(format: "%.2f", rgb.alpha))" : ""
        return "Red \(Int(rgb.red)), Green \(Int(rgb.green)), Blue \(Int(rgb.blue))\(alpha)"
    }

    /// Announce color selection to VoiceOver
    private func announceColorSelection(_ color: Color, index: Int) {
        let description = colorDescription(for: color)
        let announcement = "Selected recent color \(index + 1): \(description)"
        if let app = NSApp {
            NSAccessibility.post(
                element: app, notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement
                ])
        }
    }

    /// Announce opacity toggle to VoiceOver
    private func announceOpacityToggle() {
        let announcement = "Opacity support \(model.supportsOpacity ? "enabled" : "disabled")"
        if let app = NSApp {
            NSAccessibility.post(
                element: app, notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement
                ])
        }
    }

    /// Announce current color information
    private func announceCurrentColor() {
        let description = colorDescription(for: model.selectedColor)
        let announcement = "Current color: \(description)"
        if let app = NSApp {
            NSAccessibility.post(
                element: app, notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement
                ])
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedColor: Color = .red

    return ColorPickerView(selectedColor: $selectedColor)
        .frame(width: 400, height: 300)
        .padding()
}
