import SwiftUI

/// Observable model for color format management
@Observable
class ColorFormatModel {
    var selectedFormat: ColorFormat = .rgb
    var currentValue: String = ""
    var validationError: String? = nil
    var isUpdatingFromExternal = false

    func updateValue(_ value: String) {
        currentValue = value
        validationError = nil
    }

    func setError(_ error: String?) {
        validationError = error
    }

    func clearError() {
        validationError = nil
    }
}

/// View for displaying and editing color values in different formats
struct ColorFormatView: View {

    // MARK: - Bindings

    @Binding var color: ColorRepresentation?

    // MARK: - Dependencies

    let conversionService: ColorConversionService
    @Environment(ToastManager.self) private var toastManager

    // MARK: - State Properties

    @State private var model = ColorFormatModel()

    // MARK: - Body

    var body: some View {
        @Bindable var bindableModel = model

        VStack(alignment: .leading, spacing: 16) {
            // Format selector (dropdown style)
            formatSelector

            // Single format input field
            formatInputField

            // Copy button
            copyButtonSection
        }
        .onChange(of: color) { _, newColor in
            updateCurrentValue(with: newColor)
        }
        .onChange(of: model.selectedFormat) { _, _ in
            updateCurrentValue(with: color)
        }
        .onAppear {
            initializeModel()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color format conversion section")
        .accessibilityHint("Convert and display colors in different formats")
        .environment(\.colorScheme, colorScheme)
        .onKeyPress(.return) {
            validateCurrentInput()
            return .handled
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Components

    private var formatSelector: some View {
        @Bindable var bindableModel = model

        return VStack(alignment: .leading, spacing: 8) {
            Text("Color Format")
                .font(.headline)
                .accessibilityLabel("Color format selector")

            Picker("Color Format", selection: $bindableModel.selectedFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accessibilityLabel("Select color format")
            .accessibilityHint("Choose which color format to display and edit")
        }
    }

    private var formatInputField: some View {
        @Bindable var bindableModel = model

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Color Value")
                    .font(.headline)

                Spacer()

                // Validation status indicator
                if model.validationError != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Invalid")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .accessibilityLabel("Validation error present")
                } else if !model.currentValue.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Valid")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .accessibilityLabel("Valid value")
                }

                // Format-specific help button
                Button(action: {
                    showFormatHelp(for: model.selectedFormat)
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Show format help for \(model.selectedFormat.rawValue)")
            }

            TextField(placeholderText(for: model.selectedFormat), text: $bindableModel.currentValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.system(.body, design: .monospaced))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            getInputFieldBorderColor(),
                            lineWidth: model.validationError != nil ? 2 : 1
                        )
                )
                .onChange(of: model.currentValue) { _, newValue in
                    guard !model.isUpdatingFromExternal else { return }
                    validateAndConvert(value: newValue)
                }
                .accessibilityLabel("\(model.selectedFormat.rawValue) color value input field")
                .accessibilityValue(model.currentValue.isEmpty ? "empty" : model.currentValue)
                .accessibilityHint(
                    "Enter a color value in \(model.selectedFormat.rawValue) format. \(getAccessibilityFormatHint(for: model.selectedFormat))"
                )

            // Error message display
            if let error = model.validationError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)
                .accessibilityLabel("Validation error: \(error)")
                .accessibilityAddTraits(.isStaticText)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func showFormatHelp(for format: ColorFormat) {
        let helpMessage: String
        switch format {
        case .rgb:
            helpMessage =
                "RGB format: rgb(red, green, blue) or rgba(red, green, blue, alpha). Values: R,G,B: 0-255, Alpha: 0-1"
        case .hex:
            helpMessage =
                "Hex format: #RRGGBB or #RRGGBBAA. Use 3, 6, or 8 hexadecimal digits after #"
        case .hsl:
            helpMessage =
                "HSL format: hsl(hue, saturation%, lightness%) or hsla(..., alpha). Hue: 0-360°, S,L: 0-100%, Alpha: 0-1"
        case .hsv:
            helpMessage =
                "HSV format: hsv(hue, saturation%, value%) or hsva(..., alpha). Hue: 0-360°, S,V: 0-100%, Alpha: 0-1"
        case .cmyk:
            helpMessage = "CMYK format: cmyk(cyan%, magenta%, yellow%, key%). All values: 0-100%"
        case .lab:
            helpMessage = "LAB format: lab(lightness, a, b). L: 0-100, a,b: -128 to 127"
        }

        toastManager.show(helpMessage, type: .info, duration: 5.0)
    }

    private var copyButtonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Copy to Clipboard")
                .font(.headline)
                .accessibilityLabel("Copy color value to clipboard")

            Button(action: {
                copyToClipboard()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                    Text("Copy \(model.selectedFormat.rawValue)")
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .disabled(model.currentValue.isEmpty || model.validationError != nil)
            .keyboardShortcut("c", modifiers: [.command])
            .accessibilityLabel("Copy \(model.selectedFormat.rawValue) color value to clipboard")
            .accessibilityHint(
                "Copies the current \(model.selectedFormat.rawValue) color value to the system clipboard"
            )
            .accessibilityValue(model.currentValue.isEmpty ? "no value" : model.currentValue)
        }
    }

    // MARK: - Helper Methods

    private func placeholderText(for format: ColorFormat) -> String {
        switch format {
        case .rgb:
            return "rgb(255, 128, 0) or rgba(255, 128, 0, 0.8)"
        case .hex:
            return "#FF8000 or #FF8000CC"
        case .hsl:
            return "hsl(30, 100%, 50%) or hsla(30, 100%, 50%, 0.8)"
        case .hsv:
            return "hsv(30, 100%, 100%) or hsva(30, 100%, 100%, 0.8)"
        case .cmyk:
            return "cmyk(0%, 50%, 100%, 0%)"
        case .lab:
            return "lab(67.5, 42.5, 67.2)"
        }
    }

    private func initializeModel() {
        updateCurrentValue(with: color)
    }

    private func updateCurrentValue(with color: ColorRepresentation?) {
        model.isUpdatingFromExternal = true
        defer { model.isUpdatingFromExternal = false }

        guard let color = color else {
            model.updateValue("")
            model.clearError()
            return
        }

        // Update current value based on selected format
        let newValue: String
        switch model.selectedFormat {
        case .rgb:
            newValue = color.rgbString
        case .hex:
            newValue = color.hexString
        case .hsl:
            newValue = color.hslString
        case .hsv:
            newValue = color.hsvString
        case .cmyk:
            newValue = color.cmykString
        case .lab:
            newValue = color.labString
        }

        model.updateValue(newValue)
        model.clearError()
    }

    private func validateAndConvert(value: String) {
        // Clear previous error
        model.clearError()

        // Skip validation for empty values
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            color = nil
            return
        }

        // Debounce validation for better performance
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second debounce

            // Check if value is still current
            guard model.currentValue == value else { return }

            await performValidationAndConversion(value: trimmedValue)
        }
    }

    @MainActor
    private func performValidationAndConversion(value: String) async {
        // Validate the input
        let validationResult = conversionService.validateColorInput(
            value, format: model.selectedFormat)

        if !validationResult.isValid {
            // Set validation error with improved messaging
            let baseError = validationResult.errorMessage ?? "Invalid format"
            let suggestion = getFormatSuggestion(for: model.selectedFormat)
            let fullError = suggestion.isEmpty ? baseError : "\(baseError). \(suggestion)"
            model.setError(fullError)
            return
        }

        // If validation passes, attempt conversion to create ColorRepresentation
        let conversionResult = conversionService.createColorRepresentation(
            from: model.selectedFormat, value: value)

        switch conversionResult {
        case .success(let colorRepresentation):
            // Update the bound color
            color = colorRepresentation

        case .failure(let error):
            // Set validation error from conversion failure with user-friendly message
            let userFriendlyError = getUserFriendlyError(error, for: model.selectedFormat)
            model.setError(userFriendlyError)
        }
    }

    private func getFormatSuggestion(for format: ColorFormat) -> String {
        switch format {
        case .rgb:
            return "Try: rgb(255, 128, 0) or rgba(255, 128, 0, 0.8)"
        case .hex:
            return "Try: #FF8000 or #FF8000CC"
        case .hsl:
            return "Try: hsl(30, 100%, 50%) or hsla(30, 100%, 50%, 0.8)"
        case .hsv:
            return "Try: hsv(30, 100%, 100%) or hsva(30, 100%, 100%, 0.8)"
        case .cmyk:
            return "Try: cmyk(0%, 50%, 100%, 0%)"
        case .lab:
            return "Try: lab(67.5, 42.5, 67.2)"
        }
    }

    private func getUserFriendlyError(_ error: ColorProcessingError, for format: ColorFormat)
        -> String
    {
        switch error {
        case .invalidColorFormat(_, let input):
            return "Invalid \(format.rawValue) format: '\(input)'"
        case .conversionFailed(let from, let to):
            return "Cannot convert from \(from.rawValue) to \(to.rawValue)"
        case .invalidColorValue(let component, let value, let range):
            return "\(component) value '\(value)' is out of range (\(range))"
        default:
            return error.localizedDescription
        }
    }

    private func copyToClipboard() {
        guard !model.currentValue.isEmpty else { return }
        guard model.validationError == nil else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if pasteboard.setString(model.currentValue, forType: .string) {
            // Show success toast notification
            toastManager.show(
                "Copied \(model.selectedFormat.rawValue) color value to clipboard",
                type: .success,
                duration: 2.0
            )

            // Announce to VoiceOver
            let announcement =
                "Copied \(model.selectedFormat.rawValue) value \(model.currentValue) to clipboard"
            NSAccessibility.post(
                element: NSApp!, notification: .announcementRequested,
                userInfo: [
                    .announcement: announcement
                ])
        } else {
            // Show error toast notification
            toastManager.show(
                "Failed to copy \(model.selectedFormat.rawValue) color value",
                type: .error,
                duration: 3.0
            )
        }
    }

    /// Get accessibility hint for specific color format
    private func getAccessibilityFormatHint(for format: ColorFormat) -> String {
        switch format {
        case .rgb:
            return "Example: rgb(255, 128, 0) for red 255, green 128, blue 0"
        case .hex:
            return "Example: #FF8000 for orange color"
        case .hsl:
            return "Example: hsl(30, 100%, 50%) for hue 30 degrees, full saturation, 50% lightness"
        case .hsv:
            return
                "Example: hsv(30, 100%, 100%) for hue 30 degrees, full saturation, full brightness"
        case .cmyk:
            return
                "Example: cmyk(0%, 50%, 100%, 0%) for cyan 0%, magenta 50%, yellow 100%, black 0%"
        case .lab:
            return "Example: lab(67.5, 42.5, 67.2) for lightness 67.5, a 42.5, b 67.2"
        }
    }

    /// Get appropriate border color for input field based on state and contrast mode
    private func getInputFieldBorderColor() -> Color {
        if model.validationError != nil {
            // Error state - use high contrast red
            return colorScheme == .dark ? Color.red.opacity(0.8) : Color.red
        } else if !model.currentValue.isEmpty {
            // Valid value - use high contrast blue
            return colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue.opacity(0.6)
        } else {
            // Normal state - use subtle border
            return Color.clear
        }
    }

    /// Validate current input when Enter key is pressed
    private func validateCurrentInput() {
        if !model.currentValue.isEmpty {
            validateAndConvert(value: model.currentValue)
        }
    }
}

// MARK: - Preview

#Preview("Empty State") {
    ColorFormatView(
        color: .constant(nil),
        conversionService: ColorConversionService()
    )
    .padding()
    .environment(ToastManager())
}

#Preview("With RGB Color") {
    @Previewable @State var color: ColorRepresentation? = ColorRepresentation(
        rgb: RGBColor(red: 255, green: 128, blue: 0, alpha: 1.0),
        hex: "#FF8000",
        hsl: HSLColor(hue: 30, saturation: 100, lightness: 50, alpha: 1.0),
        hsv: HSVColor(hue: 30, saturation: 100, value: 100, alpha: 1.0),
        cmyk: CMYKColor(cyan: 0, magenta: 50, yellow: 100, key: 0),
        lab: LABColor(lightness: 67.5, a: 42.5, b: 67.2)
    )

    return ColorFormatView(
        color: $color,
        conversionService: ColorConversionService()
    )
    .padding()
    .environment(ToastManager())
}

#Preview("Dark Mode") {
    ColorFormatView(
        color: .constant(nil),
        conversionService: ColorConversionService()
    )
    .padding()
    .environment(ToastManager())
    .preferredColorScheme(.dark)
}
