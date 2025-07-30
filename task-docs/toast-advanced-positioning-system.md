# Toast Advanced Positioning System

## Overview

The Toast Advanced Positioning System is a sophisticated layout management component that provides intelligent, responsive positioning for toast notifications in the macOS utility toolkit. This system ensures toasts are always positioned optimally within the window bounds while respecting macOS window chrome and safe areas.

## Architecture

### Core Components

#### 1. Dynamic Layout Calculation

The system continuously monitors and adapts to:

- Window size changes
- Safe area insets
- macOS window chrome (title bar, toolbar)
- Available screen real estate

#### 2. Responsive Width Management

Toasts dynamically adjust their width based on:

- Available window width
- Minimum/maximum width constraints (300-500 points)
- Horizontal margin requirements

#### 3. Safe Area Integration

Intelligent positioning that considers:

- macOS title bar height (28 points)
- Standard toolbar height (52 points)
- System safe area insets
- Minimum padding requirements

## Key Implementation Details

### Layout Constants

```swift
private let maxToasts: Int = 5
private let toastSpacing: CGFloat = 12
private let horizontalMargin: CGFloat = 20
private let minimumTopPadding: CGFloat = 20
private let toolbarHeight: CGFloat = 52
private let titleBarHeight: CGFloat = 28
```

These constants provide:

- **Consistent Spacing**: Uniform gaps between stacked toasts
- **Safe Margins**: Adequate distance from window edges
- **Platform Compliance**: Standard macOS chrome dimensions

### Dynamic Calculations

#### Safe Top Padding

```swift
private var safeTopPadding: CGFloat {
    let basePadding = safeAreaInsets.top + titleBarHeight + toolbarHeight + minimumTopPadding
    return max(basePadding, 80)
}
```

**Features:**

- Combines multiple safe area factors
- Ensures minimum 80-point top margin
- Adapts to different window configurations

#### Responsive Width

```swift
private var maxToastWidth: CGFloat {
    let availableWidth = windowSize.width - (horizontalMargin * 2)
    return min(max(availableWidth, 300), 500)
}
```

**Features:**

- Maintains 20-point margins on each side
- Enforces 300-point minimum width
- Caps at 500-point maximum width
- Scales smoothly with window resizing

#### Container Height Management

```swift
private var containerHeight: CGFloat {
    let bottomSafeArea = safeAreaInsets.bottom + 20
    return windowSize.height - safeTopPadding - bottomSafeArea
}
```

**Features:**

- Prevents toasts from extending below visible area
- Accounts for bottom safe areas
- Provides additional bottom margin

### State Management

#### Window Metrics Tracking

```swift
@State private var windowSize: CGSize = .zero
@State private var safeAreaInsets: EdgeInsets = EdgeInsets()

private func updateLayoutMetrics(_ geometry: GeometryProxy) {
    windowSize = geometry.size
    safeAreaInsets = geometry.safeAreaInsets
}
```

**Features:**

- Real-time window size monitoring
- Safe area inset tracking
- Efficient state updates

### Visual Hierarchy System

#### Stacking Effects

```swift
private func stackingScale(for index: Int) -> CGFloat {
    return 1.0 - (CGFloat(index) * 0.02)
}

private func stackingOffset(for index: Int) -> CGFloat {
    return CGFloat(index) * 2.0
}

private func stackingOpacity(for index: Int) -> CGFloat {
    return 1.0 - (CGFloat(index) * 0.1)
}
```

**Visual Features:**

- **Subtle Scaling**: 2% reduction per stack level
- **Minimal Offset**: 2-point vertical displacement
- **Opacity Gradation**: 10% transparency increase per level

#### Z-Index Management

```swift
.zIndex(Double(maxToasts - index))
```

Ensures proper layering with newest toasts appearing on top.

### Animation System

#### Spring Animation Configuration

```swift
.animation(
    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1),
    value: toastManager.toasts.map { $0.id }
)
```

**Parameters:**

- **Response**: 0.6 seconds for natural movement
- **Damping**: 0.8 for controlled oscillation
- **Blend Duration**: 0.1 seconds for smooth transitions

#### Transition Effects

```swift
private func toastTransition(for index: Int) -> AnyTransition {
    .asymmetric(
        insertion: .move(edge: .top)
            .combined(with: .opacity)
            .combined(with: .scale(scale: 0.85)),
        removal: .opacity
            .combined(with: .scale(scale: 0.75))
            .combined(with: .move(edge: .top))
    )
}
```

**Features:**

- **Asymmetric Transitions**: Different entry and exit animations
- **Combined Effects**: Multiple animation properties
- **Smooth Scaling**: Natural size transitions

## Performance Optimizations

### Efficient Rendering

#### Lazy Loading

```swift
LazyVStack(spacing: toastSpacing) {
    ForEach(Array(toastManager.toasts.prefix(maxToasts).enumerated()), id: \.element.id) { ... }
}
```

**Benefits:**

- Only renders visible toasts
- Reduces memory footprint
- Improves scrolling performance

#### Clipping Optimization

```swift
.clipped()
```

Prevents rendering outside visible bounds, improving performance.

### Memory Management

#### State Caching

- Window size cached to avoid recalculation
- Safe area insets stored for reuse
- Layout metrics updated only when necessary

#### Efficient Updates

- Geometry changes trigger targeted updates
- Animation values computed on-demand
- State changes batched for efficiency

## Integration Points

### SwiftUI Integration

```swift
GeometryReader { geometry in
    // Layout calculations based on geometry
}
.onAppear {
    updateLayoutMetrics(geometry)
}
.onChange(of: geometry.size) { _, newSize in
    updateLayoutMetrics(geometry)
}
```

### Environment Integration

```swift
@Environment(ToastManager.self) private var toastManager
```

Seamless integration with the toast management system.

## Testing Considerations

### Layout Testing

- Window resizing scenarios
- Safe area variations
- Multiple toast stacking
- Animation performance

### Edge Cases

- Minimum window sizes
- Maximum toast counts
- Rapid show/dismiss cycles
- Memory pressure conditions

## Platform Compliance

### macOS Guidelines

- Respects Human Interface Guidelines
- Follows standard spacing conventions
- Integrates with system appearance
- Maintains accessibility standards

### Window Management

- Adapts to window resizing
- Respects full-screen mode
- Handles multiple displays
- Supports split-screen scenarios

## Future Enhancements

### Planned Improvements

- **Multi-Display Support**: Positioning across multiple screens
- **Custom Positioning**: User-configurable placement preferences
- **Adaptive Sizing**: Content-based width calculation
- **Performance Metrics**: Layout performance monitoring

### Extensibility Points

- **Custom Animations**: Pluggable transition systems
- **Layout Strategies**: Alternative positioning algorithms
- **Theme Integration**: Dynamic styling based on system appearance
- **Accessibility Enhancements**: Improved screen reader support

## Conclusion

The Toast Advanced Positioning System represents a sophisticated approach to notification layout management in macOS applications. By combining responsive design principles with platform-specific considerations, it provides a robust foundation for user-friendly, accessible, and performant toast notifications.

The system's architecture ensures that toasts are always positioned optimally while maintaining visual hierarchy and smooth animations, creating a professional and polished user experience that integrates seamlessly with macOS design patterns.
