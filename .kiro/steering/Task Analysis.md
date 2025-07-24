---
inclusion: always
---

# Task Analysis & Development Guidelines

## Pre-Implementation Analysis
- **Complexity Assessment**: Evaluate implementation difficulty before starting new features
- **Library Research**: Use 'fetch' MCP to search GitHub for existing libraries that could implement the required functionality
- **Decision Framework**: If third-party libraries significantly simplify implementation, recommend manual addition; otherwise implement natively
- **Dependency Minimalism**: Maintain minimal dependencies to preserve performance and security

## Code Quality Standards
- **Test Coverage**: Maintain 100% test coverage for all new features and modifications
- **Error Handling**: Implement comprehensive error handling with user-friendly messages
- **Performance**: Use async/await patterns with proper cancellation support
- **Memory Management**: Monitor memory pressure and implement lazy loading where appropriate

## Development Workflow
1. **Feature Analysis**: Assess complexity and research existing solutions
2. **Architecture Planning**: Follow modular structure (Models/Services/Views)
3. **Test-Driven Development**: Write tests before implementation
4. **Code Quality**: Run SwiftLint and SwiftFormat before committing
5. **Permission Verification**: Test file operations without requesting additional permissions

## Architecture Patterns
- **MVVM**: Keep views lightweight, business logic in services
- **Dependency Injection**: Use @StateObject and @ObservedObject appropriately
- **Modular Design**: Each feature should be self-contained and testable
- **Shared Components**: Reuse components from `Shared/Components/` directory

## File Operation Guidelines
- **No File Permissions**: Use system file dialogs and drag & drop exclusively
- **Local Processing**: All operations must happen locally (privacy-first)
- **User Control**: Users must explicitly choose files through system dialogs
- **Error Recovery**: Provide clear feedback when file operations fail

## UI/UX Conventions
- **Native macOS**: Use SwiftUI with native macOS patterns
- **Accessibility**: Implement proper accessibility labels and hints
- **Dark/Light Mode**: Support both appearance modes
- **Responsive Design**: Handle window resizing gracefully

## Performance Optimization
- **Lazy Loading**: Use `LazyToolView` for non-essential features
- **Background Processing**: Move heavy operations off main thread
- **Memory Monitoring**: Implement memory pressure handling
- **Startup Performance**: Minimize app launch time with background initialization

## Security & Privacy
- **Sandboxing**: Respect macOS sandbox limitations
- **No Network**: All processing happens locally
- **Data Protection**: Never store sensitive user data
- **Minimal Permissions**: Request only essential entitlements