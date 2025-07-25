import Foundation

class SecurityService {
  static let shared = SecurityService()
  
  private init() {}
  
  func sanitizeStringInput(_ input: String) -> String {
    // Basic sanitization - remove null characters and control characters
    let sanitized = input.replacingOccurrences(of: "\0", with: "")
    return sanitized.trimmingCharacters(in: .controlCharacters)
  }
}

// MARK: - Notifications

extension Notification.Name {
  static let clearSensitiveData = Notification.Name("clearSensitiveData")
}