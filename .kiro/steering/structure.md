# Project Structure

## Directory Organization

### Main Application (`Tools/Tools/`)
```
Tools/
├── ToolsApp.swift              # App entry point with SwiftData container
├── ContentView.swift           # Main navigation and layout
├── Tools.entitlements         # App sandbox permissions
├── Assets.xcassets/           # App icons and assets
└── Resources/                 # Static resources (HTML, CSS, JS)
```

### Feature Modules (`Tools/Tools/Features/`)
Each feature follows a consistent modular structure:
```
Features/
├── [FeatureName]/
│   ├── Models/                # Data models and types
│   ├── Services/              # Business logic and operations
│   └── Views/                 # SwiftUI views and components
```

**Available Features:**
- `Clipboard/` - Clipboard history management
- `Encryption/` - Hashing and encryption tools
- `ImageProcessing/` - Image manipulation utilities
- `JSON/` - JSON formatting and validation
- `QRCode/` - QR code generation and scanning
- `Settings/` - App configuration
- `TimeConverter/` - Timestamp conversion tools

### Core Infrastructure (`Tools/Tools/Core/`)
- `Navigation/` - App navigation management

### Shared Components (`Tools/Tools/Shared/`)
```
Shared/
├── Components/               # Reusable UI components
├── Extensions/              # Swift extensions
├── Models/                  # Shared data models
├── Services/               # Cross-feature services
└── Utils/                  # Utility functions
```

### Testing (`Tools/ToolsTests/`)
- Comprehensive test coverage for all features
- Performance and stability tests
- Permission verification tests
- UI integration tests

## Architecture Patterns

### MVVM Structure
- **Models**: Data structures and business entities
- **Views**: SwiftUI views with minimal logic
- **Services**: Business logic, API calls, and data processing

### Key Conventions
- Each feature is self-contained with its own Models/Services/Views
- Shared components are in the `Shared/` directory
- Services handle all business logic and async operations
- Views are kept lightweight and focused on UI

### File Naming
- Views: `[Feature]View.swift`
- Services: `[Feature]Service.swift`
- Models: `[Feature]Models.swift`
- Tests: `[Feature][Type]Tests.swift`

### Performance Optimizations
- Lazy loading with `LazyToolView` wrapper
- Background initialization for non-critical services
- Memory pressure monitoring
- Async operation management with cancellation support