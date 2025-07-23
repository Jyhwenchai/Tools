import Foundation

// Test with more complex JSON including escaped characters
let complexJSON = """
{"name":"test","path":"/usr/local/bin","escaped":"He said \\"Hello\\"","backslash":"C:\\\\Users","mixed":"path/to/file\\\\with\\\\backslashes"}
"""

print("Original minified JSON:")
print(complexJSON)

// Test the custom formatting function
func formatJSONPreservingStrings(_ jsonString: String) throws -> String {
  var result = ""
  var indentLevel = 0
  var insideString = false
  var escapeNext = false
  var i = jsonString.startIndex
  
  while i < jsonString.endIndex {
    let char = jsonString[i]
    
    if escapeNext {
      result.append(char)
      escapeNext = false
      i = jsonString.index(after: i)
      continue
    }
    
    if char == "\\" && insideString {
      result.append(char)
      escapeNext = true
      i = jsonString.index(after: i)
      continue
    }
    
    if char == "\"" {
      insideString.toggle()
      result.append(char)
      i = jsonString.index(after: i)
      continue
    }
    
    if insideString {
      result.append(char)
      i = jsonString.index(after: i)
      continue
    }
    
    // Handle formatting outside of strings
    switch char {
    case "{":
      result.append("{\n")
      indentLevel += 1
      result.append(String(repeating: "  ", count: indentLevel))
    case "}":
      if result.hasSuffix("  ") {
        result = String(result.dropLast(2))
      }
      if result.hasSuffix("\n") {
        result = String(result.dropLast())
      }
      indentLevel = max(0, indentLevel - 1)
      result.append("\n" + String(repeating: "  ", count: indentLevel) + "}")
    case "[":
      result.append("[\n")
      indentLevel += 1
      result.append(String(repeating: "  ", count: indentLevel))
    case "]":
      if result.hasSuffix("  ") {
        result = String(result.dropLast(2))
      }
      if result.hasSuffix("\n") {
        result = String(result.dropLast())
      }
      indentLevel = max(0, indentLevel - 1)
      result.append("\n" + String(repeating: "  ", count: indentLevel) + "]")
    case ":":
      result.append(": ")
    case ",":
      result.append(",\n" + String(repeating: "  ", count: indentLevel))
    case " ", "\t", "\n", "\r":
      // Skip whitespace outside strings
      break
    default:
      result.append(char)
    }
    
    i = jsonString.index(after: i)
  }
  
  return result
}

print("\nFormatted with custom function:")
do {
  let formatted = try formatJSONPreservingStrings(complexJSON)
  print(formatted)
} catch {
  print("Error: \(error)")
}

// Compare with JSONSerialization
if let data = complexJSON.data(using: .utf8),
   let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
   let formattedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
   let formattedString = String(data: formattedData, encoding: .utf8) {
    print("\nFormatted with JSONSerialization:")
    print(formattedString)
}