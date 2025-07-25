# Requirements Document

## Introduction

This feature adds a universal Toast notification system to the macOS Utility Toolkit that provides non-intrusive, temporary feedback messages to users across all features. The Toast component will serve as a reusable shared component that can replace existing alert dialogs for simple notifications and provide a consistent way to show success, failure, warning, and info messages throughout the entire application including Clipboard, JSON processing, Encryption, QR Code generation, Image Processing, and all other tools.

## Requirements

### Requirement 1

**User Story:** As a user, I want to see temporary toast notifications for any application actions (copying, saving, processing, errors, etc.), so that I get immediate feedback without interrupting my workflow.

#### Acceptance Criteria

1. WHEN a user performs an action that requires feedback THEN the system SHALL display a toast notification that automatically disappears after a configurable duration
2. WHEN a toast is displayed THEN the system SHALL position it in a non-intrusive location that doesn't block important UI elements
3. WHEN multiple toasts are triggered THEN the system SHALL queue them or stack them appropriately without overlapping

### Requirement 2

**User Story:** As a user, I want different visual styles for different types of notifications (success, error, warning), so that I can quickly understand the nature of the feedback.

#### Acceptance Criteria

1. WHEN displaying a success message THEN the system SHALL show a green-themed toast with a checkmark icon
2. WHEN displaying an error message THEN the system SHALL show a red-themed toast with an error icon
3. WHEN displaying a warning message THEN the system SHALL show an orange/yellow-themed toast with a warning icon
4. WHEN displaying an info message THEN the system SHALL show a blue-themed toast with an info icon

### Requirement 3

**User Story:** As a developer, I want a reusable Toast component that can be easily integrated into any view across all features (Clipboard, JSON, Encryption, QR Code, Image Processing, etc.), so that I can provide consistent feedback throughout the entire application.

#### Acceptance Criteria

1. WHEN integrating the Toast component THEN the system SHALL provide a simple API for showing toasts with message and type parameters
2. WHEN using the Toast component THEN the system SHALL support customizable duration for auto-dismissal
3. WHEN implementing the Toast THEN the system SHALL provide a SwiftUI modifier or environment-based approach for easy integration
4. WHEN displaying toasts THEN the system SHALL ensure proper accessibility support with VoiceOver announcements

### Requirement 4

**User Story:** As a user, I want toast notifications to respect macOS design guidelines and appearance settings, so that they feel native to the operating system.

#### Acceptance Criteria

1. WHEN displaying toasts THEN the system SHALL adapt to light and dark mode automatically
2. WHEN showing toasts THEN the system SHALL use native macOS visual effects like blur and vibrancy where appropriate
3. WHEN positioning toasts THEN the system SHALL respect safe areas and window boundaries
4. WHEN animating toasts THEN the system SHALL use smooth, native-feeling animations for appearance and dismissal

### Requirement 5

**User Story:** As a user, I want the ability to dismiss toast notifications manually if needed, so that I have control over the interface.

#### Acceptance Criteria

1. WHEN a toast is displayed THEN the system SHALL allow manual dismissal by clicking on the toast or a close button
2. WHEN hovering over a toast THEN the system SHALL pause the auto-dismissal timer
3. WHEN the mouse leaves the toast area THEN the system SHALL resume the auto-dismissal countdown
4. WHEN multiple toasts are shown THEN the system SHALL allow dismissing individual toasts without affecting others
