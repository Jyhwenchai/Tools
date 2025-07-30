# Design Document

## Overview

The enhanced time converter will provide a comprehensive time conversion experience with real-time current timestamp display, tabbed interface for single and batch conversions, improved timezone handling, and modern UI design. The design maintains the existing MVVM architecture while adding new components for real-time updates, batch processing, and enhanced user interactions.

## Architecture

### Component Structure

```
TimeConverter/
├── Models/
│   ├── TimeConverterModels.swift (enhanced)
│   ├── BatchConversionModels.swift (new)
│   └── RealTimeTimestampModels.swift (new)
├── Services/
│   ├── TimeConverterService.swift (enhanced)
│   ├── BatchConversionService.swift (new)
│   └── RealTimeTimestampService.swift (new)
└── Views/
    ├── TimeConverterView.swift (redesigned)
    ├── RealTimeTimestampView.swift (new)
    ├── SingleConversionView.swift (new)
    ├── BatchConversionView.swift (new)
    └── TimestampToDateView.swift (new)
    └── DateToTimestampView.swift (new)
```

### Real-Time Timestamp System

The real-time timestamp display will use a dedicated service that manages timer-based updates:

- **RealTimeTimestampService**: Manages timer lifecycle and timestamp generation
- **RealTimeTimestampView**: Displays current timestamp with controls
- **Timer Management**: Automatic start/stop with view lifecycle
- **Unit Switching**: Toggle between seconds and milliseconds
- **Copy Functionality**: One-click clipboard integration

### Tabbed Interface Design

The main view will feature a tabbed interface with two primary modes:

1. **Single Conversion Tab** (`单个转换`):

   - Timestamp to Date conversion
   - Date to Timestamp conversion
   - Real-time validation and conversion
   - Enhanced timezone selection

2. **Batch Conversion Tab** (`批量转换`):
   - Multiple input processing
   - Bulk conversion results
   - Error handling per item
   - Export functionality

## Components and Interfaces

### RealTimeTimestampService

```swift
@Observable
class RealTimeTimestampService {
    var currentTimestamp: String
    var isRunning: Bool
    var useMilliseconds: Bool

    func startTimer()
    func stopTimer()
    func toggleUnit()
    func copyToClipboard()
}
```

### BatchConversionService

```swift
@Observable
class BatchConversionService {
    func processBatchConversion(items: [BatchConversionItem]) -> [BatchConversionResult]
    func validateBatchInput(_ input: String) -> [String]
    func exportResults(_ results: [BatchConversionResult]) -> String
}
```

### Enhanced TimeConverterService

The existing service will be enhanced with:

- Improved timezone handling
- Better error messages
- Performance optimizations for batch operations
- Real-time conversion capabilities

## Data Models

### RealTimeTimestampModels

```swift
struct RealTimeTimestampState {
    var timestamp: String
    var isRunning: Bool
    var unit: TimestampUnit
    var lastUpdate: Date
}

enum TimestampUnit: CaseIterable {
    case seconds
    case milliseconds

    var displayName: String
    var formatFunction: (TimeInterval) -> String
}
```

### BatchConversionModels

```swift
struct BatchConversionItem {
    let id: UUID
    var input: String
    var sourceFormat: TimeFormat
    var targetFormat: TimeFormat
    var sourceTimeZone: TimeZone
    var targetTimeZone: TimeZone
}

struct BatchConversionResult {
    let id: UUID
    let input: String
    let output: String?
    let error: String?
    let success: Bool
}
```

### Enhanced TimeConverterModels

Additional models for improved functionality:

```swift
struct ConversionPreset {
    let name: String
    let sourceFormat: TimeFormat
    let targetFormat: TimeFormat
    let sourceTimeZone: TimeZone
    let targetTimeZone: TimeZone
}

struct ConversionHistory {
    let timestamp: Date
    let input: String
    let output: String
    let options: TimeConversionOptions
}
```

## Error Handling

### Validation Strategy

1. **Real-time Validation**: Input validation as user types
2. **Format-specific Validation**: Different validation rules per format
3. **Timezone Validation**: Ensure timezone compatibility
4. **Batch Validation**: Individual item validation with aggregated results

### Error Types

```swift
enum TimeConverterError: LocalizedError {
    case invalidTimestamp(String)
    case invalidDateFormat(String)
    case timezoneConversionFailed
    case batchProcessingFailed([String])
    case realTimeServiceUnavailable

    var errorDescription: String?
    var recoverySuggestion: String?
}
```

## Testing Strategy

### Unit Tests

1. **RealTimeTimestampService Tests**:

   - Timer lifecycle management
   - Unit switching functionality
   - Clipboard integration
   - Memory leak prevention

2. **BatchConversionService Tests**:

   - Multiple input processing
   - Error handling per item
   - Performance with large datasets
   - Export functionality

3. **Enhanced TimeConverterService Tests**:
   - Improved timezone handling
   - Real-time conversion accuracy
   - Error message clarity

### Integration Tests

1. **Tabbed Interface Tests**:

   - Tab switching functionality
   - State preservation between tabs
   - UI responsiveness

2. **Real-time Update Tests**:

   - Timer accuracy
   - UI update performance
   - Background/foreground behavior

3. **Batch Processing Tests**:
   - Large dataset handling
   - UI responsiveness during processing
   - Error aggregation and display

### UI Tests

1. **Accessibility Tests**:

   - Screen reader compatibility
   - Keyboard navigation
   - Focus management

2. **Visual Tests**:
   - Layout responsiveness
   - Dark/light mode support
   - Animation smoothness

## User Interface Design

### Main Layout Structure

```
┌─────────────────────────────────────────┐
│ 时间戳转换                                │
├─────────────────────────────────────────┤
│ 当前时间戳                                │
│ 1753690051 秒                           │
│ [切换单位] [复制] [停止]                    │
├─────────────────────────────────────────┤
│ [单个转换] [批量转换]                       │
├─────────────────────────────────────────┤
│ Single/Batch Conversion Content          │
│                                         │
└─────────────────────────────────────────┘
```

### Single Conversion Layout

Two main sections:

1. **Timestamp to Date** (`时间戳转日期时间`)
2. **Date to Timestamp** (`日期时间转时间戳`)

Each section includes:

- Input field with validation
- Timezone selection dropdown
- Convert button
- Result display with copy functionality

### Batch Conversion Layout

- Multi-line input area
- Format selection for batch items
- Process button
- Results table with individual copy buttons
- Export functionality

## Performance Considerations

### Real-time Updates

- Use efficient timer management to prevent battery drain
- Implement proper cleanup on view disappearance
- Optimize string formatting for frequent updates

### Batch Processing

- Implement async processing for large datasets
- Provide progress indicators for long operations
- Use background queues to prevent UI blocking

### Memory Management

- Proper timer cleanup
- Efficient string handling for large batches
- Lazy loading for timezone data

## Accessibility Features

### Screen Reader Support

- Proper accessibility labels for all controls
- Descriptive hints for complex interactions
- Logical reading order

### Keyboard Navigation

- Tab order follows visual layout
- Enter key triggers primary actions
- Escape key cancels operations

### Visual Accessibility

- High contrast support
- Scalable text support
- Clear focus indicators

## Integration Points

### Clipboard Integration

- System clipboard access for copy operations
- Paste functionality for input fields
- Format detection for pasted content

### System Services

- Timezone data from system
- Locale-aware formatting
- Background/foreground state handling

### Toast Notifications

- Success confirmations for copy operations
- Error notifications for failed conversions
- Progress updates for batch operations
