import Foundation

let testJSON = "[1,2,3,]"
print("Testing JSON: \(testJSON)")

if let data = testJSON.data(using: .utf8) {
  do {
    let result = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
    print("✅ Valid JSON: \(result)")
  } catch {
    print("❌ Invalid JSON: \(error)")
  }
} else {
  print("❌ Failed to convert to data")
}
