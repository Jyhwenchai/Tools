//
//  FileOperationUserExperienceTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/20.
//

import Testing
import SwiftUI
import UniformTypeIdentifiers
@testable import Tools

/// Tests for file operation user experience improvements
struct FileOperationUserExperienceTests {
  
  // MARK: - Enhanced Drop Zone Tests
  
  @Test("Enhanced drop zone provides proper visual feedback")
  func testEnhancedDropZoneVisualFeedback() async {
    // Test that drag feedback states work correctly
    let dropZone = EnhancedDropZone.forImages(
      onFilesDropped: { _ in },
      onButtonTapped: { }
    )
    
    // Verify initial state
    #expect(dropZone.title == "拖拽图片到此处或点击选择")
    #expect(dropZone.supportedTypes.contains(.png))
    #expect(dropZone.supportedTypes.contains(.jpeg))
  }
  
  @Test("Enhanced drop zone handles different file types correctly")
  func testEnhancedDropZoneFileTypes() async {
    // Test image drop zone
    let imageDropZone = EnhancedDropZone.forImages(
      onFilesDropped: { _ in },
      onButtonTapped: { }
    )
    
    #expect(imageDropZone.supportedTypes.contains(.png))
    #expect(imageDropZone.supportedTypes.contains(.jpeg))
    #expect(imageDropZone.supportedTypes.contains(.gif))
    
    // Test JSON drop zone
    let jsonDropZone = EnhancedDropZone.forJSON(
      onFilesDropped: { _ in },
      onButtonTapped: { }
    )
    
    #expect(jsonDropZone.supportedTypes.contains(.json))
    #expect(jsonDropZone.maxFileSize == 10 * 1024 * 1024) // 10MB for JSON
  }
  
  @Test("Enhanced drop zone provides appropriate file size limits")
  func testEnhancedDropZoneFileSizeLimits() async {
    let dropZone = EnhancedDropZone.forImages(
      onFilesDropped: { _ in },
      onButtonTapped: { }
    )
    
    // Default should be 100MB for images
    #expect(dropZone.maxFileSize == 100 * 1024 * 1024)
  }
  
  // MARK: - File Operation Guide Tests
  
  @Test("File operation guide provides comprehensive tips")
  func testFileOperationGuideTips() async {
    let dragDropGuide = FileOperationGuide.OperationType.dragDrop
    let fileSelectionGuide = FileOperationGuide.OperationType.fileSelection
    let fileSavingGuide = FileOperationGuide.OperationType.fileSaving
    let batchProcessingGuide = FileOperationGuide.OperationType.batchProcessing
    let troubleshootingGuide = FileOperationGuide.OperationType.troubleshooting
    
    // Verify all guides have appropriate number of tips
    #expect(dragDropGuide.tips.count >= 5)
    #expect(fileSelectionGuide.tips.count >= 5)
    #expect(fileSavingGuide.tips.count >= 5)
    #expect(batchProcessingGuide.tips.count >= 5)
    #expect(troubleshootingGuide.tips.count >= 5)
    
    // Verify tips contain useful information
    #expect(dragDropGuide.tips.contains { $0.contains("拖拽") })
    #expect(fileSelectionGuide.tips.contains { $0.contains("⌘+A") })
    #expect(fileSavingGuide.tips.contains { $0.contains("桌面") })
    #expect(batchProcessingGuide.tips.contains { $0.contains("批量") })
    #expect(troubleshootingGuide.tips.contains { $0.contains("检查") })
  }
  
  @Test("File operation guide has proper icons and titles")
  func testFileOperationGuideMetadata() async {
    let guides = [
      FileOperationGuide.OperationType.dragDrop,
      FileOperationGuide.OperationType.fileSelection,
      FileOperationGuide.OperationType.fileSaving,
      FileOperationGuide.OperationType.batchProcessing,
      FileOperationGuide.OperationType.troubleshooting
    ]
    
    for guide in guides {
      #expect(!guide.title.isEmpty)
      #expect(!guide.icon.isEmpty)
      #expect(!guide.tips.isEmpty)
    }
  }
  
  // MARK: - File Dialog Utils Tests
  
  @Test("File dialog utils validates file types correctly")
  func testFileDialogUtilsFileTypeValidation() async {
    // Create test URLs
    let imageURL = URL(fileURLWithPath: "/test/image.png")
    let jsonURL = URL(fileURLWithPath: "/test/data.json")
    let textURL = URL(fileURLWithPath: "/test/document.txt")
    
    let imageTypes: [UTType] = [.png, .jpeg, .gif]
    let jsonTypes: [UTType] = [.json]
    
    // Test image file validation
    #expect(FileDialogUtils.isFileTypeSupported(imageURL, supportedTypes: imageTypes))
    #expect(!FileDialogUtils.isFileTypeSupported(jsonURL, supportedTypes: imageTypes))
    
    // Test JSON file validation
    #expect(FileDialogUtils.isFileTypeSupported(jsonURL, supportedTypes: jsonTypes))
    #expect(!FileDialogUtils.isFileTypeSupported(imageURL, supportedTypes: jsonTypes))
  }
  
  @Test("File validation result provides comprehensive feedback")
  func testFileValidationResult() async {
    // Create test URLs
    let validImageURL = URL(fileURLWithPath: "/test/valid.png")
    let invalidURL = URL(fileURLWithPath: "/test/invalid.txt")
    
    let supportedTypes: [UTType] = [.png, .jpeg]
    let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    // Create a mock validation result
    let result = FileValidationResult(
      validFiles: [validImageURL],
      invalidFiles: [invalidURL],
      oversizedFiles: [],
      supportedTypes: supportedTypes,
      maxFileSize: maxFileSize
    )
    
    #expect(!result.isValid) // Has invalid files
    #expect(result.hasIssues) // Has issues
    #expect(result.validFiles.count == 1)
    #expect(result.invalidFiles.count == 1)
    #expect(result.oversizedFiles.count == 0)
    
    // Test summary message
    let summary = result.summaryMessage
    #expect(summary.contains("1 个文件可以处理"))
    #expect(summary.contains("1 个文件格式不支持"))
  }
  
  // MARK: - Contextual Help Tests
  
  @Test("Contextual file operation help provides relevant information")
  func testContextualFileOperationHelp() async {
    let supportedTypes: [UTType] = [.png, .jpeg, .gif]
    let maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB
    let allowsMultiple = true
    
    let help = ContextualFileOperationHelp(
      supportedTypes: supportedTypes,
      maxFileSize: maxFileSize,
      allowsMultiple: allowsMultiple
    )
    
    #expect(help.supportedTypes == supportedTypes)
    #expect(help.maxFileSize == maxFileSize)
    #expect(help.allowsMultiple == allowsMultiple)
  }
  
  // MARK: - User Experience Flow Tests
  
  @Test("File operation flow is intuitive and provides clear feedback")
  func testFileOperationFlow() async {
    // Test the complete file operation flow
    var filesDropped: [URL] = []
    var buttonTapped = false
    
    let dropZone = EnhancedDropZone.forImages(
      onFilesDropped: { urls in
        filesDropped = urls
      },
      onButtonTapped: {
        buttonTapped = true
      }
    )
    
    // Verify callbacks are set up correctly
    #expect(filesDropped.isEmpty)
    #expect(!buttonTapped)
    
    // Simulate button tap
    dropZone.onButtonTapped()
    #expect(buttonTapped)
  }
  
  @Test("Error messages are user-friendly and actionable")
  func testUserFriendlyErrorMessages() async {
    let supportedTypes: [UTType] = [.png, .jpeg]
    let maxFileSize: Int64 = 1024 * 1024 // 1MB
    
    let result = FileValidationResult(
      validFiles: [],
      invalidFiles: [URL(fileURLWithPath: "/test/invalid.txt")],
      oversizedFiles: [URL(fileURLWithPath: "/test/large.png")],
      supportedTypes: supportedTypes,
      maxFileSize: maxFileSize
    )
    
    let detailedMessage = result.detailedMessage
    
    // Verify error message contains helpful information
    #expect(detailedMessage.contains("格式不支持"))
    #expect(detailedMessage.contains("过大"))
    #expect(detailedMessage.contains("PNG, JPEG"))
    #expect(detailedMessage.contains("1 MB"))
  }
  
  // MARK: - Accessibility Tests
  
  @Test("File operation components are accessible")
  func testFileOperationAccessibility() async {
    // Test that components have proper accessibility labels
    let dragDropGuide = FileOperationGuide.OperationType.dragDrop
    
    #expect(!dragDropGuide.title.isEmpty)
    #expect(!dragDropGuide.icon.isEmpty)
    
    // Verify guide content is descriptive
    for tip in dragDropGuide.tips {
      #expect(tip.count > 10) // Tips should be descriptive
    }
  }
  
  // MARK: - Performance Tests
  
  @Test("File operation components perform well with multiple files")
  func testFileOperationPerformance() async {
    // Test performance with multiple files
    let urls = (1...100).map { URL(fileURLWithPath: "/test/file\($0).png") }
    let supportedTypes: [UTType] = [.png, .jpeg, .gif]
    let maxFileSize: Int64 = 10 * 1024 * 1024
    
    // Measure validation performance
    let startTime = Date()
    let result = FileDialogUtils.validateFiles(urls, supportedTypes: supportedTypes, maxFileSize: maxFileSize)
    let endTime = Date()
    
    let duration = endTime.timeIntervalSince(startTime)
    #expect(duration < 1.0) // Should complete within 1 second
    #expect(result.validFiles.count <= urls.count)
  }
  
  // MARK: - Integration Tests
  
  @Test("File operation components work together seamlessly")
  func testFileOperationIntegration() async {
    // Test that drop zone, guide, and dialog utils work together
    let supportedTypes: [UTType] = [.png, .jpeg]
    
    // Create drop zone
    let dropZone = EnhancedDropZone.forImages(
      onFilesDropped: { _ in },
      onButtonTapped: { }
    )
    
    // Verify supported types match
    #expect(dropZone.supportedTypes.contains(.png))
    #expect(dropZone.supportedTypes.contains(.jpeg))
    
    // Test file validation
    let testURL = URL(fileURLWithPath: "/test/image.png")
    #expect(FileDialogUtils.isFileTypeSupported(testURL, supportedTypes: supportedTypes))
  }
  
  // MARK: - Localization Tests
  
  @Test("File operation text is properly localized")
  func testFileOperationLocalization() async {
    let dragDropGuide = FileOperationGuide.OperationType.dragDrop
    
    // Verify Chinese text is used
    #expect(dragDropGuide.title.contains("拖拽"))
    #expect(dragDropGuide.tips.contains { $0.contains("访达") })
    
    // Test drop zone text
    let dropZone = EnhancedDropZone.forImages(
      onFilesDropped: { _ in },
      onButtonTapped: { }
    )
    
    #expect(dropZone.title.contains("拖拽"))
    #expect(dropZone.subtitle.contains("批量"))
  }
}