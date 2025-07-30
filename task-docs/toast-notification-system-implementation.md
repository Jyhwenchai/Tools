# Toast Notification System Implementation

## Overview

The Toast Notification System provides a centralized, non-intrusive way to display temporary messages to users across the macOS utility toolkit. This system implements a modern, SwiftUI-based approach to user notifications that respects macOS design principles while providing rich functionality for different message types.

## Application Integration

The toast notification system is integrated at the application level in `ContentView.swift` to provide system-wide access:

```swift
struct ContentView: View {
  @State private var toastManager = ToastManager()

  var body: some View {
    NavigationSplitView {
      // ... sidebar content
    } detail: {
      // ... detail content
    }
    .environment(toastManager)  // Provides ToastManager to all child views
    .toast()                    // Enables toast functionality
  }
}
```

### Integration Benefits

This application-level integration ensures:

- **Global Availability**: All child views have access to the `ToastManager` through the SwiftUI environment
- **Centralized Management**: Single instance manages all toast notifications across the application
- **Consistent Behavior**: Uniform toast behavior and styling throughout the app
- **Performance Optimization**: Single initialization at app startup prevents multiple instances
- **Memory Efficiency**: Shared instance reduces memory overhead

### Environment Access Pattern

Child views can access the toast manager using:

```swift
struct SomeFeatureView: View {
  @Environment(ToastManager.self) private var toastManager

  private func showSuccess() {
    toastManager.show("Operation completed successfully", type: .success)
  }
}
```

### Toast Modifier

The `.toast()` modifier applied to the root view enables the toast display functionality:

```swift
.toast()  // Activates ToastContainer for displaying notifications
```

This modifier:

- **Activates Display Layer**: Enables the `ToastContainer` to render notifications
- **Manages Overlay**: Provides the overlay layer where toasts appear
- **Handles Positioning**: Integrates with the advanced positioning system
- **Enables Animations**: Activates the animation and transition system

## Architecture

### Core Components

#### 1. ToastManager (@Observable)

The central coordinator for all toast notifications, managing display, timing, and lifecycle.

**Key Responsibilities:**

- Maintains active toast queue
- Handles auto-dismiss timing
- Provides pause/resume functionality for user interactions
- Manages memory cleanup and timer invalidation

#### 2. ToastModels

Defines the data structures and types for the notification system.

**Components:**

- `ToastMessage`: Individual notification data model
- `ToastType`: Enumeration of notification types (success, error, warning, info)
- Visual styling and icon mappings

#### 3. ToastContainer (Advanced Positioning)

The sophisticated container component that manages toast positioning with window size awareness and safe area handling.

**Key Features:**

- **Responsive Layout**: Adapts to window size changes dynamically
- **Safe Area Awareness**: Respects macOS window chrome and safe areas
- **Intelligent Positioning**: Calculates optimal placement considering toolbars and title bars
- **Stacking Management**: Handles multiple toasts with proper z-indexing and visual hierarchy

### Design Decisions

#### Observable Pattern

Uses SwiftUI's `@Observable` macro for reactive state management, ensuring UI updates automatically when toasts are added or removed.

#### Timer-Based Auto-Dismiss

Implements `Timer.scheduledTimer` for precise control over toast lifetime, with proper cleanup to prevent memory leaks.

#### UUID-Based Identification

Each toast has a unique identifier for precise management and timer tracking.

#### Responsive Positioning System

The container implements a sophisticated positioning system that:

- **Calculates Safe Areas**: Dynamically determines safe positioning based on window chrome
- **Adapts to Window Size**: Adjusts toast width and positioning based on available space
- **Prevents Overflow**: Ensures toasts never appear outside visible bounds
- **Maintains Accessibility**: Keeps toasts within reachable areas for all users

## Key Implementation Details

### ToastManager Service

```swift
@Observable
class ToastManager {
    var toasts: [ToastMessage] = []
    private var dismissTimers: [UUID: Timer] = [:]

    func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0)
    func dismiss(_ toast: ToastMessage)
    func dismissAll()
}
```

**Features:**

- **Queue Management**: Maintains array of active toasts
- **Timer Coordination**: Maps toast IDs to dismissal timers
- **Memory Safety**: Proper cleanup in deinit
- **Thread Safety**: Main queue dispatch for UI updates

### Advanced ToastContainer Positioning

The ToastContainer implements sophisticated layout calculations:

```swift
struct ToastContainer: View {
    @State private var windowSize: CGSize = .zero
    @State private var safeAreaInsets: EdgeInsets = EdgeInsets()

    private var safeTopPadding: CGFloat {
        let basePadding = safeAreaInsets.top + titleBarHeight + toolbarHeight + minimumTopPadding
        return max(basePadding, 80)
    }

    private var maxToastWidth: CGFloat {
        let availableWidth = windowSize.width - (horizontalMargin * 2)
        return min(max(availableWidth, 300), 500)
    }
}
```

**Advanced Features:**

- **Dynamic Width Calculation**: Toasts adapt between 300-500 points based on window size
- **Safe Area Integration**: Respects macOS window chrome including title bar and toolbar
- **Overflow Prevention**: Clips content to prevent toasts from appearing outside bounds
- **Responsive Margins**: Maintains appropriate spacing from window edges

### Auto-Dismiss Functionality

The system provides sophisticated timing control:

```swift
private func scheduleAutoDismiss(for toast: ToastMessage) {
    let timer = Timer.scheduledTimer(withTimeInterval: toast.duration, repeats: false) { [weak self] _ in
        DispatchQueue.main.async {
            self?.dismiss(toast)
        }
    }
    dismissTimers[toast.id] = timer
}
```

**Advanced Features:**

- **Pause/Resume**: Allows interrupting auto-dismiss (e.g., on hover)
- **Remaining Time**: Calculates and preserves remaining display time
- **Weak References**: Prevents retain cycles

### Toast Types and Styling

Each toast type has associated visual styling:

- **Success**: Green theme with checkmark icon
- **Error**: Red theme with exclamation icon
- **Warning**: Orange theme with triangle icon
- **Info**: Blue theme with info icon

### Stacking and Animation System

The container provides sophisticated visual management:

```swift
private func stackingScale(for index: Int) -> CGFloat {
    return 1.0 - (CGFloat(index) * 0.02)  // Subtle scale reduction
}

private func stackingOffset(for index: Int) -> CGFloat {
    return CGFloat(index) * 2.0  // Slight vertical offset
}

private func stackingOpacity(for index: Int) -> CGFloat {
    return 1.0 - (CGFloat(index) * 0.1)  // Gradual opacity reduction
}
```

**Visual Features:**

- **Z-Index Management**: Proper layering with newer toasts on top
- **Stacking Effects**: Subtle scale and offset for visual depth
- **Smooth Transitions**: Spring animations for natural movement
- **Opacity Gradation**: Visual hierarchy through transparency

## Integration Points

### SwiftUI Integration

The ToastManager integrates seamlessly with SwiftUI views through the environment system:

```swift
// Application-level integration (ContentView.swift)
@State private var toastManager = ToastManager()
.environment(toastManager)
.toast()

// Feature-level usage
@Environment(ToastManager.self) private var toastManager
toastManager.show("Operation completed", type: .success)
```

### Cross-Feature Usage

Any feature module can display toasts by accessing the shared manager:

- **File Operations**: Success/error feedback
- **Processing Results**: Completion notifications
- **Validation Errors**: User input feedback
- **System Events**: Status updates

## Usage Patterns

### Basic Toast Display

```swift
// Simple success message
toastManager.show("File saved successfully", type: .success)

// Error with custom duration
toastManager.show("Invalid input format", type: .error, duration: 5.0)

// Persistent toast (manual dismiss only)
toastManager.show("Processing...", type: .info, duration: 0)
```

### Advanced Interaction

```swift
// Pause auto-dismiss on hover
toastManager.pauseAutoDismiss(for: toast)

// Resume with remaining time
toastManager.resumeAutoDismiss(for: toast, remainingTime: 2.5)

// Clear all notifications
toastManager.dismissAll()
```

## Performance Considerations

### Memory Management

- **Timer Cleanup**: All timers invalidated on deinit
- **Weak References**: Prevents memory leaks in closures
- **Efficient Removal**: O(n) removal with `removeAll` predicate

### Threading

- **Main Queue**: UI updates dispatched to main thread
- **Timer Scheduling**: Uses main run loop for consistency
- **Async Safety**: Proper synchronization for concurrent access

### Layout Performance

- **Lazy Evaluation**: Uses `LazyVStack` for efficient rendering of multiple toasts
- **Geometry Caching**: Stores window size and safe area metrics to avoid recalculation
- **Clipping Optimization**: Uses `.clipped()` to prevent unnecessary rendering outside bounds
- **Animation Efficiency**: Spring animations with optimized parameters for smooth performance

## Error Handling

The system is designed to be fault-tolerant:

- **Timer Failures**: Graceful handling of timer invalidation
- **Memory Pressure**: Automatic cleanup prevents accumulation
- **Thread Safety**: Main queue dispatch prevents race conditions

## Testing Strategy

The implementation supports comprehensive testing:

### Unit Tests

- Toast creation and properties
- Timer scheduling and cleanup
- Auto-dismiss functionality
- Pause/resume behavior

### Integration Tests

- SwiftUI view integration
- Cross-feature usage
- Memory leak detection
- Performance benchmarks

## Accessibility Support

The Toast Notification System provides comprehensive accessibility support to ensure all users can effectively interact with notifications.

### Core Accessibility Features

#### Basic Accessibility Properties

- **accessibilityLabel**: Descriptive content for screen readers
- **accessibilityHint**: Contextual usage guidance
- **accessibilityValue**: Current state information
- **accessibilityTraits**: Proper semantic marking as notifications

#### Enhanced Accessibility Actions

The system provides multiple ways for users to interact with toasts through assistive technologies:

- **关闭通知 (Close Notification)**: Dismisses the toast with confirmation feedback
- **暂停自动关闭 (Pause Auto-Dismiss)**: Prevents automatic dismissal with status feedback
- **恢复自动关闭 (Resume Auto-Dismiss)**: Restores automatic dismissal with status feedback
- **重复消息 (Repeat Message)**: Re-announces the toast content for clarity

#### Multi-Language Input Label Support

The system supports diverse input methods and languages:

```swift
.accessibilityInputLabels([
    "关闭", "关闭通知", "取消", "dismiss", "close",
    "暂停", "pause", "停止", "stop",
    "恢复", "resume", "继续", "continue"
])
```

This ensures users can interact with toasts using various voice commands and input methods.

#### VoiceOver Integration

- **Automatic Announcement**: New toasts are automatically announced
- **Action Feedback**: Confirmation messages when actions are performed
- **State Changes**: Announces when auto-dismiss is paused or resumed
- **Content Repetition**: Users can request message re-announcement

#### Accessibility Feedback System

The system includes a sophisticated feedback mechanism:

```swift
private func announceAccessibilityAction(_ message: String) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        NSAccessibility.post(
            element: NSApp.mainWindow ?? NSApp,
            notification: .announcementRequested,
            userInfo: [.announcement: message]
        )
    }
}
```

**Features:**

- **Immediate Feedback**: Users receive instant confirmation of their actions
- **System Integration**: Uses native macOS accessibility APIs
- **Delayed Announcement**: Prevents audio conflicts with slight delay
- **Context Awareness**: Announcements are contextually relevant

### Accessibility Testing

The accessibility implementation has been thoroughly tested for:

- **Screen Reader Compatibility**: Full VoiceOver support
- **Keyboard Navigation**: Complete keyboard accessibility
- **Voice Control**: Support for voice commands
- **Switch Control**: Compatible with switch-based input devices

## Future Enhancements

### Completed Features

- ✅ **Advanced Animation System**: Sophisticated slide-in/fade-out transitions with stacking effects
- ✅ **Responsive Position Control**: Dynamic positioning with window size awareness
- ✅ **Queue Management**: Maximum concurrent toast count with visual stacking
- ✅ **Safe Area Integration**: Respects macOS window chrome and safe areas
- ✅ **Enhanced Accessibility**: Comprehensive screen reader and assistive technology support

### Planned Features

- **Persistence**: Optional toast history
- **Custom Positioning**: User-configurable toast placement
- **Advanced Accessibility**: Additional customization options for accessibility preferences

### Extensibility Points

- **Custom Types**: Additional toast categories
- **Styling Themes**: User-customizable appearance
- **Sound Integration**: Audio feedback options
- **Accessibility**: Enhanced screen reader support

## Dependencies

### Internal Dependencies

- `ToastModels.swift`: Data structures and types
- SwiftUI framework for UI integration
- Foundation for Timer and UUID functionality

### External Dependencies

- None - fully self-contained implementation

## Compliance

### macOS Guidelines

- Follows Human Interface Guidelines for notifications
- Respects system appearance (light/dark mode)
- Non-intrusive user experience
- Comprehensive accessibility compliance with WCAG 2.1 standards
- Full VoiceOver and assistive technology support
- Multi-language accessibility input support

### Privacy & Security

- No data persistence or logging
- Local-only operation
- No network communication
- Sandbox-compliant implementation

## Recent Updates and Bug Fixes

### Text Layout Fix (Latest)

- **Issue**: Toast message text with `.fixedSize(horizontal: false, vertical: true)` was causing layout constraint issues in certain scenarios
- **Fix**: Removed the `.fixedSize()` modifier from the message text component in `ToastView.swift`
- **Impact**: Improved text display and layout flexibility in toast notifications, especially for longer messages
- **Benefits**:
  - Better text wrapping behavior
  - More natural sizing based on content
  - Reduced layout conflicts with container constraints
  - Improved readability for multi-line messages

## Recent Enhancements (Advanced Positioning Update)

The ToastContainer has been significantly enhanced with advanced positioning capabilities:

### Key Improvements

- **Window Size Awareness**: Dynamic adaptation to window resizing
- **Safe Area Calculation**: Intelligent positioning that respects macOS window chrome
- **Responsive Width**: Toast width adapts between 300-500 points based on available space
- **Overflow Prevention**: Clipping ensures toasts never appear outside visible bounds
- **Enhanced Stacking**: Improved visual hierarchy with subtle scale and opacity effects

### Technical Implementation

- **GeometryReader Integration**: Real-time window size tracking
- **Layout Constants**: Configurable margins, padding, and sizing constraints
- **State Management**: Efficient tracking of window metrics and safe areas
- **Animation Optimization**: Spring animations with carefully tuned parameters

## Migration Notes

This implementation replaces any previous notification mechanisms and provides:

- **Unified API**: Single interface for all toast types
- **Better Performance**: Optimized memory and timer management with advanced layout calculations
- **Enhanced UX**: Consistent styling, behavior, and responsive positioning
- **Comprehensive Accessibility**: Full screen reader support with multi-language input labels and action feedback
- **Maintainability**: Clean, testable architecture with sophisticated layout management
- **Platform Integration**: Deep integration with macOS window management, safe areas, and accessibility APIs
- **Application-Level Integration**: Centralized management through SwiftUI environment system

### Integration Steps

To integrate the toast system into the application:

1. **Add ToastManager to ContentView**: Create a `@State` instance of `ToastManager`
2. **Provide Environment Access**: Use `.environment(toastManager)` to make it available to child views
3. **Enable Display Layer**: Apply `.toast()` modifier to activate the display functionality
4. **Access in Features**: Use `@Environment(ToastManager.self)` in feature views to show notifications

The system is designed to be the definitive notification solution for the macOS utility toolkit, providing reliable, performant, and user-friendly feedback across all application features with professional-grade positioning and layout capabilities.
