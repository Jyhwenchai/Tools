# Design Document

## Overview

The Color Processing Tool is a comprehensive color utility that enables users to work with colors in multiple formats, select colors interactively, and sample colors from the screen. The tool integrates seamlessly with the existing macOS utility toolkit architecture, following the established modular design patterns and providing a native macOS experience.

## Architecture

### High-Level Architecture

The color processing tool follows the established MV (Model-View) architecture with modular design:

```
Features/ColorProcessing/
├── Models/
│   ├── ColorModels.swift          # Color data structures and formats
│   └── ColorPaletteModels.swift   # Saved color palette management
├── Services/
│   ├── ColorConversionService.swift    # Color format conversions
│   ├── ColorSamplingService.swift      # Screen color sampling
│   └── ColorPaletteService.swift       # Palette persistence
└── Views/
    ├── ColorProcessingView.swift       # Main color tool interface
    ├── ColorFormatView.swift           # Color format display/input
    ├── ColorPickerView.swift           # Interactive color picker
    ├── ScreenSamplerView.swift         # Screen sampling interface
    └── ColorPaletteView.swift          # Saved colors management
```

### Integration Points

- **Navigation**: Integrates with `NavigationManager` for consistent app navigation
- **Toast System**: Uses `ToastManager` for user feedback and notifications
- **Shared Components**: Leverages existing `ToolButton`, `ToolTextField`, and `ToolResultView` components
- **Error Handling**: Follows established error handling patterns with `ToolError`
- **Accessibility**: Implements full accessibility support consistent with other tools

## Components and Interfaces

### Core Models

#### ColorModels.swift

```swift
// Color representation in multiple formats
struct ColorRepresentation {
    let rgb: RGBColor
    let hex: String
    let hsl: HSLColor
    let hsv: HSVColor
    let cmyk: CMYKColor
    let lab: LABColor

    // Computed properties for formatted strings
    var rgbString: String
    var hexString: String
    var hslString: String
    var hsvaString: String
    var cmykString: String
}

// Individual color format structures
struct RGBColor {
    let red: Double    // 0-255
    let green: Double  // 0-255
    let blue: Double   // 0-255
    let alpha: Double  // 0-1
}

struct HSLColor {
    let hue: Double        // 0-360
    let saturation: Double // 0-100
    let lightness: Double  // 0-100
    let alpha: Double      // 0-1
}

// Additional color format structures...
```

#### ColorPaletteModels.swift

```swift
struct SavedColor {
    let id: UUID
    let name: String
    let color: ColorRepresentation
    let dateCreated: Date
    let tags: [String]
}

struct ColorPalette {
    var colors: [SavedColor]

    mutating func addColor(_ color: SavedColor)
    mutating func removeColor(id: UUID)
    func exportToFile() -> Data
}
```

### Services Layer

#### ColorConversionService.swift

```swift
class ColorConversionService: ObservableObject {
    // Convert between different color formats
    func convertColor(from sourceFormat: ColorFormat,
                     to targetFormat: ColorFormat,
                     value: String) -> Result<String, ColorConversionError>

    // Create ColorRepresentation from any format
    func createColorRepresentation(from format: ColorFormat,
                                 value: String) -> Result<ColorRepresentation, ColorConversionError>

    // Validate color format input
    func validateColorInput(_ input: String,
                          format: ColorFormat) -> ValidationResult
}
```

#### ColorSamplingService.swift

```swift
class ColorSamplingService: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentSampledColor: ColorRepresentation?

    // Start screen color sampling
    func startScreenSampling() async -> Result<Void, SamplingError>

    // Stop screen color sampling
    func stopScreenSampling()

    // Sample color at specific screen coordinates
    func sampleColorAt(point: CGPoint) -> Result<ColorRepresentation, SamplingError>

    // Request screen capture permissions
    private func requestScreenCapturePermission() async -> Bool
}
```

#### ColorPaletteService.swift

```swift
class ColorPaletteService: ObservableObject {
    @Published var savedColors: [SavedColor] = []

    // Persistence operations
    func loadPalette() async
    func savePalette() async
    func addColor(_ color: ColorRepresentation, name: String)
    func removeColor(id: UUID)
    func exportPalette() -> Data
    func importPalette(from data: Data) -> Result<Void, PaletteError>
}
```

### View Layer

#### ColorProcessingView.swift

Main container view that orchestrates all color processing functionality:

```swift
struct ColorProcessingView: View {
    @StateObject private var conversionService = ColorConversionService()
    @StateObject private var samplingService = ColorSamplingService()
    @StateObject private var paletteService = ColorPaletteService()
    @State private var currentColor: ColorRepresentation?

    var body: some View {
        VStack(spacing: 20) {
            // Color picker section
            ColorPickerView(selectedColor: $currentColor)

            // Color format display/input section
            ColorFormatView(color: $currentColor,
                          conversionService: conversionService)

            // Screen sampling controls
            ScreenSamplerView(samplingService: samplingService,
                            onColorSampled: { color in
                                currentColor = color
                            })

            // Saved colors palette
            ColorPaletteView(paletteService: paletteService,
                           onColorSelected: { color in
                               currentColor = color
                           })
        }
        .padding()
        .navigationTitle("Color Processing")
    }
}
```

#### ColorFormatView.swift

Displays and allows editing of color values in different formats:

```swift
struct ColorFormatView: View {
    @Binding var color: ColorRepresentation?
    let conversionService: ColorConversionService

    // Format-specific input fields with real-time validation
    // Copy buttons for each format
    // Format conversion logic
}
```

#### ColorPickerView.swift

Interactive color picker using SwiftUI's native ColorPicker:

```swift
struct ColorPickerView: View {
    @Binding var selectedColor: ColorRepresentation?
    @State private var pickerColor: Color = .white

    var body: some View {
        VStack {
            // Color preview swatch
            ColorSwatchView(color: pickerColor)

            // Native SwiftUI ColorPicker
            ColorPicker("Select Color", selection: $pickerColor)
                .onChange(of: pickerColor) { newColor in
                    // Convert SwiftUI Color to ColorRepresentation
                    selectedColor = convertToColorRepresentation(newColor)
                }
        }
    }
}
```

#### ScreenSamplerView.swift

Screen color sampling interface:

```swift
struct ScreenSamplerView: View {
    let samplingService: ColorSamplingService
    let onColorSampled: (ColorRepresentation) -> Void

    var body: some View {
        VStack {
            Button(action: startSampling) {
                HStack {
                    Image(systemName: "eyedropper")
                    Text("Sample Screen Color")
                }
            }
            .disabled(samplingService.isActive)

            if samplingService.isActive {
                Text("Click anywhere on screen to sample color. Press ESC to cancel.")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## Data Models

### Color Format Support

The tool supports the following color formats with bidirectional conversion:

1. **RGB** - Red, Green, Blue (0-255) with Alpha (0-1)
2. **Hex** - Hexadecimal notation (#RRGGBB, #RRGGBBAA)
3. **HSL** - Hue (0-360°), Saturation (0-100%), Lightness (0-100%)
4. **HSV/HSB** - Hue (0-360°), Saturation (0-100%), Value/Brightness (0-100%)
5. **CMYK** - Cyan, Magenta, Yellow, Key/Black (0-100%)
6. **LAB** - L*a*b\* color space for perceptual uniformity

### Color Validation

Each format includes comprehensive validation:

- Range checking for all components
- Format validation for string inputs
- Real-time feedback for invalid values
- Automatic correction suggestions

### Persistence Model

Saved colors are stored locally using SwiftData with the following structure:

- Unique identifier for each saved color
- User-defined name and optional tags
- Full color representation in all formats
- Creation timestamp for organization

## Error Handling

### Error Types

```swift
enum ColorProcessingError: LocalizedError {
    case invalidColorFormat(format: String, input: String)
    case conversionFailed(from: ColorFormat, to: ColorFormat)
    case screenSamplingPermissionDenied
    case screenSamplingFailed(reason: String)
    case paletteOperationFailed(operation: String)

    var errorDescription: String? {
        // User-friendly error messages
    }
}
```

### Error Recovery

- Graceful degradation when screen sampling permissions are denied
- Fallback to manual color input when sampling fails
- Automatic retry mechanisms for transient failures
- Clear user guidance for resolving permission issues

## Testing Strategy

### Unit Tests

1. **ColorConversionService Tests**

   - Test all color format conversions
   - Validate edge cases and boundary values
   - Test error handling for invalid inputs

2. **ColorSamplingService Tests**

   - Mock screen sampling functionality
   - Test permission handling
   - Validate color extraction accuracy

3. **ColorPaletteService Tests**
   - Test persistence operations
   - Validate import/export functionality
   - Test concurrent access scenarios

### Integration Tests

1. **Color Tool Integration**

   - Test complete color workflow
   - Validate UI state synchronization
   - Test toast notification integration

2. **Accessibility Tests**
   - Screen reader compatibility
   - Keyboard navigation
   - High contrast mode support

### Performance Tests

1. **Color Conversion Performance**

   - Benchmark conversion speed
   - Test with large color datasets
   - Memory usage optimization

2. **Screen Sampling Performance**
   - Test sampling responsiveness
   - Validate memory cleanup
   - Test with multiple displays

## Implementation Considerations

### Screen Sampling Technical Details

Screen color sampling uses Core Graphics APIs:

- `CGDisplayCreateImage` for capturing screen regions
- `CGPreflightScreenCaptureAccess` for permission checking
- `CGRequestScreenCaptureAccess` for requesting permissions
- Custom cursor tracking for real-time color preview

### Color Space Handling

The tool handles multiple color spaces:

- sRGB for standard web colors
- Display P3 for wide gamut displays
- Generic RGB for compatibility
- Automatic color space detection and conversion

### Performance Optimizations

- Lazy loading of color conversion calculations
- Debounced input validation to reduce CPU usage
- Efficient color space conversions using Core Graphics
- Memory-efficient storage of color history

### Accessibility Features

- Keyboard shortcuts for common operations
- High contrast mode compatibility
- Alternative text descriptions for color swatches
- Screen reader announcements for color changes
