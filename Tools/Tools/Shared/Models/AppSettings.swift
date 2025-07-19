import Foundation
import SwiftUI

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Codable {
  case light = "浅色"
  case dark = "深色"
  case system = "跟随系统"
  
  var colorScheme: ColorScheme? {
    switch self {
    case .light:
      return .light
    case .dark:
      return .dark
    case .system:
      return nil
    }
  }
  
  var systemImage: String {
    switch self {
    case .light:
      return "sun.max"
    case .dark:
      return "moon"
    case .system:
      return "circle.lefthalf.filled"
    }
  }
}

// MARK: - App Settings
@Observable
class AppSettings {
  // Singleton instance
  static let shared = AppSettings()
  
  // Theme setting with @AppStorage
  @ObservationIgnored @AppStorage("app_theme") private var themeRawValue: String = AppTheme.system.rawValue
  var theme: AppTheme {
    get { AppTheme(rawValue: themeRawValue) ?? .system }
    set { themeRawValue = newValue.rawValue }
  }
  
  // Clipboard settings
  @ObservationIgnored @AppStorage("max_clipboard_history") private var _maxClipboardHistory: Int = 100
  var maxClipboardHistory: Int {
    get { _maxClipboardHistory }
    set { _maxClipboardHistory = newValue }
  }
  
  // Behavior settings
  @ObservationIgnored @AppStorage("auto_save_results") private var _autoSaveResults: Bool = true
  var autoSaveResults: Bool {
    get { _autoSaveResults }
    set { _autoSaveResults = newValue }
  }
  
  @ObservationIgnored @AppStorage("auto_copy_results") private var _autoCopyResults: Bool = false
  var autoCopyResults: Bool {
    get { _autoCopyResults }
    set { _autoCopyResults = newValue }
  }
  
  @ObservationIgnored @AppStorage("confirm_destructive_actions") private var _confirmDestructiveActions: Bool = true
  var confirmDestructiveActions: Bool {
    get { _confirmDestructiveActions }
    set { _confirmDestructiveActions = newValue }
  }
  
  // UI settings
  @ObservationIgnored @AppStorage("show_processing_animations") private var _showProcessingAnimations: Bool = true
  var showProcessingAnimations: Bool {
    get { _showProcessingAnimations }
    set { _showProcessingAnimations = newValue }
  }
  
  // Image processing settings
  @ObservationIgnored @AppStorage("default_image_quality") private var _defaultImageQuality: Double = 0.8
  var defaultImageQuality: Double {
    get { _defaultImageQuality }
    set { _defaultImageQuality = newValue }
  }
  
  private init() {
    // Private initializer for singleton pattern
  }
  
  // MARK: - Methods
  func resetToDefaults() {
    theme = .system
    maxClipboardHistory = 100
    autoSaveResults = true
    defaultImageQuality = 0.8
    showProcessingAnimations = true
    autoCopyResults = false
    confirmDestructiveActions = true
  }
  
  // For testing purposes - clears all UserDefaults keys
  func clearAllSettings() {
    UserDefaults.standard.removeObject(forKey: "app_theme")
    UserDefaults.standard.removeObject(forKey: "max_clipboard_history")
    UserDefaults.standard.removeObject(forKey: "auto_save_results")
    UserDefaults.standard.removeObject(forKey: "auto_copy_results")
    UserDefaults.standard.removeObject(forKey: "confirm_destructive_actions")
    UserDefaults.standard.removeObject(forKey: "show_processing_animations")
    UserDefaults.standard.removeObject(forKey: "default_image_quality")
    
    // Reset to defaults after clearing
    resetToDefaults()
  }
  
  func exportSettings() -> [String: Any] {
    return [
      "theme": theme.rawValue,
      "maxClipboardHistory": maxClipboardHistory,
      "autoSaveResults": autoSaveResults,
      "defaultImageQuality": defaultImageQuality,
      "showProcessingAnimations": showProcessingAnimations,
      "autoCopyResults": autoCopyResults,
      "confirmDestructiveActions": confirmDestructiveActions
    ]
  }
  
  func importSettings(from data: [String: Any]) {
    if let themeString = data["theme"] as? String,
       let themeValue = AppTheme(rawValue: themeString) {
      theme = themeValue
    }
    
    if let maxHistory = data["maxClipboardHistory"] as? Int {
      maxClipboardHistory = max(10, min(1000, maxHistory)) // Clamp between 10-1000
    }
    
    if let autoSave = data["autoSaveResults"] as? Bool {
      autoSaveResults = autoSave
    }
    
    if let imageQuality = data["defaultImageQuality"] as? Double {
      defaultImageQuality = max(0.1, min(1.0, imageQuality)) // Clamp between 0.1-1.0
    }
    
    if let showAnimations = data["showProcessingAnimations"] as? Bool {
      showProcessingAnimations = showAnimations
    }
    
    if let autoCopy = data["autoCopyResults"] as? Bool {
      autoCopyResults = autoCopy
    }
    
    if let confirmActions = data["confirmDestructiveActions"] as? Bool {
      confirmDestructiveActions = confirmActions
    }
  }
}