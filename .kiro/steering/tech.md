# Technology Stack

## Core Technologies
- **Language**: Swift 5.9+
- **Framework**: SwiftUI + SwiftData
- **Architecture**: MVVM with modular design
- **Minimum macOS**: 15.5+
- **Xcode**: 16.0+ (for development)

## Dependencies
- **SwiftUIIntrospect**: UI introspection and customization
- **CodeEditor**: Syntax highlighting and code editing
- **SwiftyJSON**: JSON parsing and manipulation
- **Minimal approach**: Only essential dependencies to maintain performance

## Build System
- **Xcode Project**: `Tools/Tools.xcodeproj`
- **Swift Package Manager**: For dependency management
- **Target**: macOS application with sandboxing support

## Code Quality Tools
- **SwiftLint**: Code style and best practices enforcement (`.swiftlint.yml`)
- **SwiftFormat**: Automatic code formatting (`.swiftformat`)
- **Configuration**: 2-space indentation, 100 character line limit

## Common Commands

### Building
```bash
# Open project
open Tools/Tools.xcodeproj

# Build from command line
xcodebuild -project Tools/Tools.xcodeproj -scheme Tools -destination 'platform=macOS' build

# Clean build
xcodebuild clean -project Tools/Tools.xcodeproj -scheme Tools -configuration Release
```

### Testing
```bash
# Run all tests
xcodebuild test -project Tools/Tools.xcodeproj -scheme Tools -destination 'platform=macOS'

# Run permission verification tests
./Tools/ToolsTests/run_permission_verification_tests.sh
```

### Code Quality
```bash
# Fix code quality issues
./Tools/fix_code_quality.sh

# Run SwiftLint
swiftlint

# Run SwiftFormat
swiftformat .
```

### Release Build
```bash
# Build release version with verification
./Tools/build_release_version.sh
```

## Performance Considerations
- Lazy loading for tool views
- Background initialization for non-essential services
- Memory pressure monitoring and optimization
- Async operations with proper cancellation support