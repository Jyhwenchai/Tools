# Design Document

## Overview

The Toast notification system will be implemented as a reusable SwiftUI component that provides temporary, non-intrusive feedback messages across all features of the macOS Utility Toolkit. The system will consist of a Toast view component, a Toast manager for state management, and a SwiftUI environment-based integration approach for easy adoption throughout the application.

## Architecture

### Component Structure

```
Shared/Components/
├── ToastView.swift           # Main toast UI component
├── ToastManager.swift        # State management and queue handling
└── ToastModifier.swift       # SwiftUI view modifier for integration
```

### Design Patterns

- **MVVM Pattern**: ToastManager handles business logic, ToastView handles presentation
- **Environment Integration**: Uses SwiftUI environment for global access
- **Queue Management**: Supports multiple toasts with proper stacking/queuing
- **State Management**: Uses @Observable macro for modern reactive updates

## Components and Interfaces

### 1. Toast Data Model

```swift
enum ToastType: CaseIterable {
    case success
    case error
    case warning
    case info

    var icon: String { /* SF Symbol names */ }
    var color: Color { /* Theme colors */ }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let isAutoDismiss: Bool
}
```

### 2. ToastManager (@Observable)

```swift
@Observable
class ToastManager {
    var toasts: [ToastMessage] = []

    func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0)
    func dismiss(_ toast: ToastMessage)
    func dismissAll()
    private func scheduleAutoDismiss(for toast: ToastMessage)
}
```

### 3. ToastView Component

```swift
struct ToastView: View {
    let toast: ToastMessage
    let onDismiss: () -> Void
    @State private var isHovered = false

    // Visual design with blur effects, animations, and accessibility
}
```

### 4. Integration Modifier

```swift
extension View {
    func toast() -> some View {
        // Adds toast overlay and environment setup
    }
}
```

## Data Models

### ToastMessage Properties

- `id`: Unique identifier for each toast
- `message`: Text content to display
- `type`: Visual style and icon (success, error, warning, info)
- `duration`: Auto-dismiss timeout (default: 3.0 seconds)
- `isAutoDismiss`: Whether toast should auto-dismiss

### ToastType Styling

- **Success**: Green background, checkmark icon, positive feedback
- **Error**: Red background, exclamation icon, error states
- **Warning**: Orange background, warning icon, caution messages
- **Info**: Blue background, info icon, general notifications

## Error Handling

### Toast Display Failures

- Graceful degradation if toast system fails
- Fallback to console logging for critical messages
- Memory management for toast queue to prevent accumulation

### Animation and Timing Issues

- Robust animation state management
- Proper cleanup of timers and observers
- Handle rapid successive toast requests

## Testing Strategy

### Unit Tests

- ToastManager state management and queue operations
- ToastMessage model validation and equality
- Timer and auto-dismiss functionality
- Toast type styling and configuration

### Integration Tests

- SwiftUI environment integration
- View modifier functionality
- Multiple toast handling and stacking
- Animation and transition testing

### UI Tests

- Visual appearance across light/dark modes
- Positioning and layout in different window sizes
- User interaction (hover, click to dismiss)
- Accessibility compliance testing

### Performance Tests

- Memory usage with multiple toasts
- Animation performance and smoothness
- Queue management efficiency
- Timer cleanup and resource management

## Implementation Details

### Visual Design

- **Background**: Translucent blur effect with vibrancy
- **Shape**: Rounded rectangle with subtle shadow
- **Typography**: System font with appropriate sizing
- **Icons**: SF Symbols for consistent iconography
- **Colors**: Semantic colors that adapt to appearance mode

### Animation Behavior

- **Entrance**: Slide in from top with spring animation
- **Exit**: Fade out with scale animation
- **Hover**: Pause auto-dismiss timer, subtle scale effect
- **Stacking**: Vertical offset for multiple toasts

### Positioning Strategy

- **Default**: Top-center of the window
- **Safe Area**: Respects window title bar and toolbar
- **Multiple Toasts**: Vertical stacking with appropriate spacing
- **Responsive**: Adapts to window resizing

### Integration Approach

```swift
// Usage in any view:
struct SomeFeatureView: View {
    @Environment(ToastManager.self) var toastManager

    var body: some View {
        // View content
        .onTapGesture {
            toastManager.show("操作成功", type: .success)
        }
    }
}

// App-level setup:
struct ContentView: View {
    @State private var toastManager = ToastManager()

    var body: some View {
        MainAppView()
            .environment(toastManager)
            .toast()
    }
}
```

### Performance Optimizations

- Lazy loading of toast views
- Efficient queue management with automatic cleanup
- Minimal memory footprint for toast messages
- Optimized animations using SwiftUI's built-in performance features
