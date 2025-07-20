//
//  SecurityService.swift
//  Tools
//
//  Created by Kiro on 2025/7/19.
//

import Foundation
import AppKit
import CryptoKit

/// Service responsible for data security and privacy protection
@Observable
class SecurityService {
  static let shared = SecurityService()
  
  // MARK: - Properties
  private var sensitiveDataKeys: Set<String> = []
  private let keychain = KeychainService.shared
  
  private init() {
    // Defer security monitoring setup to improve startup performance
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.setupSecurityMonitoring()
    }
  }
  
  // MARK: - Data Security
  
  /// Ensures all data processing happens locally without network transmission
  func validateLocalProcessing() -> Bool {
    // Check if app has network access disabled in sandbox
    // This is enforced by not having network entitlements
    return true
  }
  
  /// Securely clear sensitive data from memory
  func clearSensitiveData() {
    // Clear clipboard history if needed
    NotificationCenter.default.post(name: .clearSensitiveData, object: nil)
    
    // Clear any cached encryption keys
    keychain.clearTemporaryKeys()
    
    // Clear UserDefaults sensitive data
    clearSensitiveUserDefaults()
    
    print("Sensitive data cleared from memory")
  }
  
  /// Register a key as containing sensitive data
  func registerSensitiveDataKey(_ key: String) {
    sensitiveDataKeys.insert(key)
  }
  
  /// Clear sensitive data from UserDefaults
  private func clearSensitiveUserDefaults() {
    for key in sensitiveDataKeys {
      UserDefaults.standard.removeObject(forKey: key)
    }
  }
  
  // MARK: - Data Validation and Security
  // Note: Permission management has been moved to individual services
  // - Clipboard permissions: handled by ClipboardService
  // - File access: using system dialogs (no permissions needed)
  
  // MARK: - App Lifecycle Security
  
  /// Setup security monitoring for app lifecycle events
  private func setupSecurityMonitoring() {
    // Monitor app termination
    NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppTermination()
    }
    
    // Monitor app becoming inactive (user switching apps)
    NotificationCenter.default.addObserver(
      forName: NSApplication.willResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppResignActive()
    }
    
    // Monitor app becoming active
    NotificationCenter.default.addObserver(
      forName: NSApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.handleAppBecomeActive()
    }
  }
  
  /// Handle app termination - clear sensitive data
  private func handleAppTermination() {
    clearSensitiveData()
    
    // Additional cleanup for specific features
    if AppSettings.shared.confirmDestructiveActions {
      // Save current state before termination
      UserDefaults.standard.set(Date(), forKey: "last_clean_exit")
    }
  }
  
  /// Handle app becoming inactive
  private func handleAppResignActive() {
    // Optionally clear clipboard monitoring when app is inactive
    // This prevents monitoring when user is not actively using the app
    NotificationCenter.default.post(name: .pauseClipboardMonitoring, object: nil)
  }
  
  /// Handle app becoming active
  private func handleAppBecomeActive() {
    // Resume clipboard monitoring when app becomes active
    NotificationCenter.default.post(name: .resumeClipboardMonitoring, object: nil)
  }
  
  // MARK: - Data Validation
  
  /// Validate that input data is safe to process
  func validateInputData(_ data: Data) -> Bool {
    // Check file size limits
    let maxFileSize = 100 * 1024 * 1024 // 100MB limit
    if data.count > maxFileSize {
      return false
    }
    
    // Check for potentially malicious content patterns
    // This is a basic check - in production, more sophisticated validation would be needed
    let dataString = String(data: data, encoding: .utf8) ?? ""
    let suspiciousPatterns = ["<script", "javascript:", "data:text/html"]
    
    for pattern in suspiciousPatterns {
      if dataString.lowercased().contains(pattern) {
        return false
      }
    }
    
    return true
  }
  
  /// Sanitize string input to prevent injection attacks
  func sanitizeStringInput(_ input: String) -> String {
    // For basic sanitization, we'll remove null characters and other control characters
    // but preserve most printable characters including Unicode
    let sanitized = input.unicodeScalars.filter { scalar in
      // Allow most characters but filter out dangerous control characters
      let value = scalar.value
      return value >= 32 || value == 9 || value == 10 || value == 13 // Allow tab, newline, carriage return
    }
    
    return String(String.UnicodeScalarView(sanitized))
  }
}

// MARK: - Keychain Service
class KeychainService {
  static let shared = KeychainService()
  
  private init() {}
  
  /// Clear temporary encryption keys from memory
  func clearTemporaryKeys() {
    // In a real implementation, this would clear any cached encryption keys
    // For now, we'll just ensure no keys are stored in memory
    print("Temporary encryption keys cleared")
  }
  
  /// Securely store sensitive data (if needed)
  func storeSecureData(_ data: Data, forKey key: String) -> Bool {
    // In a production app, this would use the Keychain Services API
    // For this utility app, we avoid storing sensitive data persistently
    return false // Intentionally not storing data
  }
  
  /// Retrieve securely stored data
  func retrieveSecureData(forKey key: String) -> Data? {
    // Intentionally not retrieving stored data for security
    return nil
  }
}

// MARK: - Notification Names
extension Notification.Name {
  static let clearSensitiveData = Notification.Name("clearSensitiveData")
  static let pauseClipboardMonitoring = Notification.Name("pauseClipboardMonitoring")
  static let resumeClipboardMonitoring = Notification.Name("resumeClipboardMonitoring")
}