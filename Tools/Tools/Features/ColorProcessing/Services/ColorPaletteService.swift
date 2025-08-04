import Foundation
import SwiftData
import SwiftUI

/// Service for managing color palette persistence with SwiftData integration
@MainActor
class ColorPaletteService: ObservableObject {
    @Published var savedColors: [SavedColor] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastError: ColorProcessingError?

    private var modelContext: ModelContext?

    // MARK: - Error Handling

    private let errorHandler = ColorProcessingErrorHandler()
    private let maxPaletteSize = 1000  // Maximum number of colors in palette
    private var toastService: ColorProcessingToastService?

    // MARK: - Initialization

    init() {
        // Service will be initialized with model context when needed
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await loadPalette()
        }
    }

    // MARK: - Palette Operations

    /// Load all saved colors from persistent storage
    func loadPalette() async {
        guard let context = modelContext else {
            let error = ColorProcessingError.paletteOperationFailed(
                operation: "Model context not available")
            handleError(error, context: "Loading palette without model context")
            return
        }

        isLoading = true
        clearError()

        do {
            let descriptor = FetchDescriptor<SavedColorModel>(
                sortBy: [SortDescriptor(\.dateCreated, order: .reverse)]
            )
            let colorModels = try context.fetch(descriptor)

            // Attempt to convert models to saved colors, handling corruption
            var loadedColors: [SavedColor] = []
            var corruptedCount = 0

            for colorModel in colorModels {
                do {
                    let savedColor = try colorModel.toSavedColor()
                    loadedColors.append(savedColor)
                } catch {
                    corruptedCount += 1
                    print("⚠️ ColorPaletteService: Skipping corrupted color model - \(error)")
                }
            }

            savedColors = loadedColors

            if corruptedCount > 0 {
                let error = ColorProcessingError.paletteCorrupted
                handleError(error, context: "\(corruptedCount) corrupted colors found")
            } else {
                clearError()
            }

        } catch {
            let loadError = ColorProcessingError.paletteOperationFailed(
                operation: "load palette from database")
            handleError(loadError, context: "Database fetch failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Add a new color to the palette
    func addColor(_ color: ColorRepresentation, name: String, tags: [String] = []) {
        guard let context = modelContext else {
            let error = ColorProcessingError.paletteOperationFailed(
                operation: "Model context not available")
            handleError(error, context: "Adding color without model context")
            return
        }

        // Check palette size limit
        guard savedColors.count < maxPaletteSize else {
            let error = ColorProcessingError.paletteStorageFull
            handleError(error, context: "Adding color to full palette")
            return
        }

        // Check for duplicate colors
        if colorExists(color) {
            let error = ColorProcessingError.colorAlreadyExists(name: name)
            handleError(error, context: "Adding duplicate color")
            return
        }

        let savedColor = SavedColor(name: name, color: color, tags: tags)

        do {
            let colorModel = try SavedColorModel(savedColor: savedColor)
            context.insert(colorModel)
            try context.save()

            // Update local array
            savedColors.insert(savedColor, at: 0)
            clearError()

            print("✅ ColorPaletteService: Added color '\(name)' to palette")

        } catch {
            let paletteError = ColorProcessingError.paletteOperationFailed(
                operation: "save color '\(name)'")
            handleError(paletteError, context: "Database save operation failed")
        }
    }

    /// Remove a color from the palette
    func removeColor(id: UUID) {
        guard let context = modelContext else {
            let error = ColorProcessingError.paletteOperationFailed(
                operation: "Model context not available")
            handleError(error, context: "Removing color without model context")
            return
        }

        // Check if color exists
        guard savedColors.contains(where: { $0.id == id }) else {
            let error = ColorProcessingError.colorNotFound(id: id)
            handleError(error, context: "Removing non-existent color")
            return
        }

        do {
            let descriptor = FetchDescriptor<SavedColorModel>(
                predicate: #Predicate { $0.id == id }
            )
            let colorModels = try context.fetch(descriptor)

            if let colorModel = colorModels.first {
                context.delete(colorModel)
                try context.save()

                // Update local array
                savedColors.removeAll { $0.id == id }
                clearError()

                print("✅ ColorPaletteService: Removed color from palette")
            } else {
                let error = ColorProcessingError.colorNotFound(id: id)
                handleError(error, context: "Color not found in database")
            }

        } catch {
            let paletteError = ColorProcessingError.paletteOperationFailed(
                operation: "remove color")
            handleError(paletteError, context: "Database delete operation failed")
        }
    }

    /// Update an existing color's metadata
    func updateColor(id: UUID, name: String? = nil, tags: [String]? = nil) {
        guard let context = modelContext else {
            errorMessage = "Model context not available"
            return
        }

        do {
            let descriptor = FetchDescriptor<SavedColorModel>(
                predicate: #Predicate { $0.id == id }
            )
            let colorModels = try context.fetch(descriptor)

            if let colorModel = colorModels.first {
                if let newName = name {
                    colorModel.name = newName
                }
                if let newTags = tags {
                    colorModel.tags = newTags
                }

                try context.save()

                // Update local array
                if let index = savedColors.firstIndex(where: { $0.id == id }) {
                    let existingColor = savedColors[index]
                    let updatedColor = SavedColor(
                        id: existingColor.id,
                        name: name ?? existingColor.name,
                        color: existingColor.color,
                        dateCreated: existingColor.dateCreated,
                        tags: tags ?? existingColor.tags
                    )
                    savedColors[index] = updatedColor
                }

                print("✅ ColorPaletteService: Updated color metadata")
            }

        } catch {
            errorMessage = "Failed to update color: \(error.localizedDescription)"
            print("❌ ColorPaletteService: Failed to update color - \(error)")
        }
    }

    /// Find colors by tag
    func findColors(withTag tag: String) -> [SavedColor] {
        return savedColors.filter { $0.tags.contains(tag) }
    }

    /// Find colors by name (case-insensitive search)
    func findColors(withName name: String) -> [SavedColor] {
        return savedColors.filter { $0.name.localizedCaseInsensitiveContains(name) }
    }

    /// Check if a color already exists in the palette
    func colorExists(_ color: ColorRepresentation) -> Bool {
        return savedColors.contains { $0.color == color }
    }

    /// Get color by ID
    func getColor(id: UUID) -> SavedColor? {
        return savedColors.first { $0.id == id }
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        return savedColors.isEmpty
    }

    var count: Int {
        return savedColors.count
    }

    var recentColors: [SavedColor] {
        return Array(savedColors.prefix(10))
    }

    var allTags: [String] {
        let allTags = savedColors.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    /// Get the error handler for external access
    func getErrorHandler() -> ColorProcessingErrorHandler {
        return errorHandler
    }

    /// Set the toast service for notifications
    func setToastService(_ toastService: ColorProcessingToastService) {
        self.toastService = toastService
    }

    /// Add color with toast notifications
    func addColorWithToast(_ color: ColorRepresentation, name: String, tags: [String] = []) {
        addColor(color, name: name, tags: tags)

        if lastError == nil {
            toastService?.showColorSaved(name: name)
        }
    }

    /// Remove color with toast notifications
    func removeColorWithToast(id: UUID) {
        let colorName = savedColors.first { $0.id == id }?.name ?? "Unknown"
        removeColor(id: id)

        if lastError == nil {
            toastService?.showPaletteOperationSuccess(
                "removed", details: "Color '\(colorName)' removed")
        }
    }

    /// Import palette with toast notifications
    func importPaletteWithToast(from data: Data, replaceExisting: Bool = false) -> Result<
        Int, ColorProcessingError
    > {
        toastService?.startProgressToast(message: "Importing color palette...")

        let result = importPalette(from: data, replaceExisting: replaceExisting)

        switch result {
        case .success(let count):
            toastService?.completeProgressToast()
            toastService?.showPaletteImported(count: count)
            return .success(count)
        case .failure(let error):
            toastService?.cancelProgressToast(error: error)
            return .failure(error)
        }
    }

    /// Export palette with toast notifications
    func exportPaletteWithToast() -> Result<Data, ColorProcessingError> {
        toastService?.startProgressToast(message: "Exporting color palette...")

        let result = exportPalette()

        switch result {
        case .success(let data):
            toastService?.completeProgressToast()
            toastService?.showPaletteExported(count: savedColors.count, format: "JSON")
            return .success(data)
        case .failure(let error):
            toastService?.cancelProgressToast(error: error)
            return .failure(error)
        }
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
        lastError = nil
        errorHandler.clearError()
    }

    private func handleError(_ error: ColorProcessingError, context: String) {
        lastError = error
        errorMessage = error.localizedDescription
        errorHandler.handleError(error, context: context)

        // Show toast notification for errors
        toastService?.showError(error)

        print(
            "❌ ColorPaletteService: \(error.localizedDescription ?? "Unknown error") - Context: \(context)"
        )
    }

    private func handleError(_ error: Error, operation: String) {
        let paletteError = ColorProcessingError.paletteOperationFailed(operation: operation)
        handleError(paletteError, context: error.localizedDescription)
    }
}

// MARK: - Import/Export Extensions

extension ColorPaletteService {

    /// Export palette to JSON data
    func exportPalette() -> Result<Data, ColorProcessingError> {
        do {
            let palette = ColorPalette(
                id: UUID(),
                name: "Exported Palette",
                colors: savedColors,
                dateCreated: Date(),
                dateModified: Date()
            )

            let data = try palette.exportToJSON()
            print("✅ ColorPaletteService: Exported \(savedColors.count) colors to JSON")
            return .success(data)

        } catch {
            let errorMsg = "Failed to export palette to JSON"
            handleError(error, operation: "export palette")
            return .failure(.paletteOperationFailed(operation: errorMsg))
        }
    }

    /// Import palette from JSON data
    func importPalette(from data: Data, replaceExisting: Bool = false) -> Result<
        Int, ColorProcessingError
    > {
        // Validate data size
        guard data.count > 0 else {
            let error = ColorProcessingError.paletteImportFailed(reason: "Empty data")
            handleError(error, context: "Importing empty palette data")
            return .failure(error)
        }

        // Check if data is too large (>10MB)
        guard data.count < 10_000_000 else {
            let error = ColorProcessingError.paletteImportFailed(reason: "File too large")
            handleError(error, context: "Importing oversized palette data")
            return .failure(error)
        }

        do {
            let importedPalette = try ColorPalette.importFromJSON(data)

            // Check if import would exceed palette size limit
            if !replaceExisting
                && (savedColors.count + importedPalette.colors.count) > maxPaletteSize
            {
                let error = ColorProcessingError.paletteStorageFull
                handleError(error, context: "Import would exceed palette size limit")
                return .failure(error)
            }

            if replaceExisting {
                // Clear existing colors
                let existingIds = savedColors.map { $0.id }
                for id in existingIds {
                    removeColor(id: id)
                }
            }

            // Add imported colors
            var importedCount = 0
            var skippedCount = 0

            for color in importedPalette.colors {
                // Check for duplicates if not replacing
                if !replaceExisting && colorExists(color.color) {
                    skippedCount += 1
                    continue
                }

                addColor(color.color, name: color.name, tags: color.tags)
                importedCount += 1

                // Check if we hit an error during add
                if lastError != nil {
                    break
                }
            }

            clearError()
            print(
                "✅ ColorPaletteService: Imported \(importedCount) colors from JSON (skipped \(skippedCount) duplicates)"
            )
            return .success(importedCount)

        } catch {
            let importError = ColorProcessingError.paletteImportFailed(
                reason: "Invalid JSON format: \(error.localizedDescription)")
            handleError(importError, context: "JSON parsing failed")
            return .failure(importError)
        }
    }

    /// Export palette to CSV format
    func exportPaletteToCSV() -> Result<String, ColorProcessingError> {
        do {
            let palette = ColorPalette(
                id: UUID(),
                name: "Exported Palette",
                colors: savedColors,
                dateCreated: Date(),
                dateModified: Date()
            )

            let csvData = palette.exportToCSV()
            print("✅ ColorPaletteService: Exported \(savedColors.count) colors to CSV")
            return .success(csvData)

        } catch {
            let errorMsg = "Failed to export palette to CSV"
            handleError(error, operation: "export palette to CSV")
            return .failure(.paletteOperationFailed(operation: errorMsg))
        }
    }
}

// MARK: - Batch Operations

extension ColorPaletteService {

    /// Add multiple colors at once
    func addColors(_ colors: [(name: String, color: ColorRepresentation, tags: [String])]) {
        for colorData in colors {
            addColor(colorData.color, name: colorData.name, tags: colorData.tags)
        }
    }

    /// Remove multiple colors by IDs
    func removeColors(ids: [UUID]) {
        for id in ids {
            removeColor(id: id)
        }
    }

    /// Clear all colors from palette
    func clearPalette() {
        let allIds = savedColors.map { $0.id }
        removeColors(ids: allIds)
        print("✅ ColorPaletteService: Cleared all colors from palette")
    }

    /// Get colors grouped by tags
    func getColorsGroupedByTags() -> [String: [SavedColor]] {
        var groupedColors: [String: [SavedColor]] = [:]

        for color in savedColors {
            if color.tags.isEmpty {
                groupedColors["Untagged", default: []].append(color)
            } else {
                for tag in color.tags {
                    groupedColors[tag, default: []].append(color)
                }
            }
        }

        return groupedColors
    }
}
