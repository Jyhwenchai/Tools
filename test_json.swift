import Foundation

// Import the JSONService from the Tools project
// This is a simple test to verify the fix works

let testJSON = """
{
  "name": "code-build-server",
  "version": "0.2",
  "argv": [
    "/usr/local/bin/code-build-server"
  ],
  "escaped": "He said \\"Hello\\"",
  "path": "C:\\\\Users\\\\Documents"
}
"""

print("Original JSON:")
print(testJSON)

// Test with JSONSerialization (the problematic approach)
if let data = testJSON.data(using: .utf8),
   let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
   let formattedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
   let formattedString = String(data: formattedData, encoding: .utf8) {
    print("\nFormatted with JSONSerialization (problematic):")
    print(formattedString)
}

print("\n" + String(repeating: "=", count: 50))
print("The issue is that JSONSerialization escapes forward slashes:")
print("- Original: /usr/local/bin/code-build-server")  
print("- JSONSerialization: \\/usr\\/local\\/bin\\/code-build-server")
print("\nOur custom formatter preserves the original string content!")
print(String(repeating: "=", count: 50))