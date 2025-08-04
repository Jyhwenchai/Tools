import SwiftUI
import UniformTypeIdentifiers

/// View for managing saved color palette with grid display and management features
struct ColorPaletteView: View {
    @ObservedObject var paletteService: ColorPaletteService
    let onColorSelected: (ColorRepresentation) -> Void
    let currentColor: ColorRepresentation?

    @State private var showingAddColorDialog = false
    @State private var newColorName = ""
    @State private var newColorTags = ""
    @State private var showingDeleteConfirmation = false
    @State private var colorToDelete: SavedColor?
    @State private var showingEditColorDialog = false
    @State private var colorToEdit: SavedColor?
    @State private var editColorName = ""
    @State private var editColorTags = ""
    @State private var showingExportImportDialog = false
    @State private var searchText = ""

    // Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 160), spacing: 12)
    ]

    // Computed properties
    private var filteredColors: [SavedColor] {
        if searchText.isEmpty {
            return paletteService.savedColors
        } else {
            return paletteService.savedColors.filter { color in
                color.name.localizedCaseInsensitiveContains(searchText)
                    || color.color.hexString.localizedCaseInsensitiveContains(searchText)
                    || color.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            if !paletteService.savedColors.isEmpty {
                searchAndFilterSection
            }

            if paletteService.isLoading {
                loadingView
            } else if filteredColors.isEmpty && !searchText.isEmpty {
                noSearchResultsView
            } else if paletteService.savedColors.isEmpty {
                emptyStateView
            } else {
                colorGridView
            }

            if let errorMessage = paletteService.errorMessage {
                errorView(errorMessage)
            }
        }
        .sheet(isPresented: $showingAddColorDialog) {
            addColorDialog
        }
        .sheet(isPresented: $showingEditColorDialog) {
            editColorDialog
        }
        .sheet(isPresented: $showingExportImportDialog) {
            exportImportDialog
        }
        .alert("Delete Color", isPresented: $showingDeleteConfirmation) {
            deleteConfirmationAlert
        }
        .onKeyPress(.delete) {
            // Handle delete key for removing selected color
            // This would require tracking selected color
            return .ignored
        }
        .onKeyPress(.return) {
            // Handle enter key for selecting color
            return .ignored
        }

        @Environment(\.colorScheme) var colorScheme
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Color Palette")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(paletteService.count) saved colors")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                ToolButton(
                    title: "Import/Export",
                    action: { showingExportImportDialog = true },
                    style: .secondary
                )
                .disabled(paletteService.isLoading)

                ToolButton(
                    title: "Add Current Color",
                    action: { showingAddColorDialog = true },
                    style: .secondary
                )
                .disabled(currentColor == nil)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Search and Filter Section

    private var searchAndFilterSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search colors by name, hex, or tags", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                }
            }

            if !paletteService.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(paletteService.allTags, id: \.self) { tag in
                            Button(tag) {
                                searchText = tag
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search and filter colors")
    }

    // MARK: - No Search Results View

    private var noSearchResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text("No colors found")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Try adjusting your search terms")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No colors found for search: \(searchText)")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading colors...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .accessibilityLabel("Loading saved colors")
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintpalette")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No Saved Colors")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Select a color and tap 'Add Current Color' to save it to your palette")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "No saved colors. Select a color and tap Add Current Color to save it to your palette")
    }

    // MARK: - Color Grid View

    private var colorGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredColors) { savedColor in
                    ColorSwatchView(
                        savedColor: savedColor,
                        onSelect: { onColorSelected(savedColor.color) },
                        onEdit: {
                            colorToEdit = savedColor
                            editColorName = savedColor.name
                            editColorTags = savedColor.tags.joined(separator: ", ")
                            showingEditColorDialog = true
                        },
                        onDelete: {
                            colorToDelete = savedColor
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 300)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Add Color Dialog

    private var addColorDialog: some View {
        VStack(spacing: 20) {
            Text("Add Color to Palette")
                .font(.headline)

            if let color = currentColor {
                ColorPreviewSwatch(color: color)
                    .frame(width: 80, height: 80)
            }

            ToolTextField(
                title: "Color Name",
                text: $newColorName,
                placeholder: "Enter a name for this color",
                fixedHeight: 40
            )

            ToolTextField(
                title: "Tags (optional)",
                text: $newColorTags,
                placeholder: "Enter tags separated by commas",
                fixedHeight: 40
            )

            HStack(spacing: 12) {
                ToolButton(
                    title: "Cancel",
                    action: {
                        showingAddColorDialog = false
                        newColorName = ""
                    },
                    style: .secondary
                )

                ToolButton(
                    title: "Add Color",
                    action: addCurrentColor,
                    style: .primary
                )
                .disabled(newColorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Delete Confirmation Alert

    private var deleteConfirmationAlert: some View {
        Group {
            Button("Delete", role: .destructive) {
                if let colorToDelete = colorToDelete {
                    paletteService.removeColor(id: colorToDelete.id)
                    self.colorToDelete = nil
                }
            }

            Button("Cancel", role: .cancel) {
                colorToDelete = nil
            }
        }
    }

    // MARK: - Actions

    private func addCurrentColor() {
        guard let color = currentColor else { return }

        let trimmedName = newColorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let tags =
            newColorTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        paletteService.addColor(color, name: trimmedName, tags: tags)

        // Reset dialog state
        showingAddColorDialog = false
        newColorName = ""
        newColorTags = ""

        // Show success toast
        // TODO: Integrate with ToastManager when available
    }

    // MARK: - Edit Color Dialog

    private var editColorDialog: some View {
        VStack(spacing: 20) {
            Text("Edit Color")
                .font(.headline)

            if let color = colorToEdit {
                ColorPreviewSwatch(color: color.color)
                    .frame(width: 80, height: 80)
            }

            ToolTextField(
                title: "Color Name",
                text: $editColorName,
                placeholder: "Enter a name for this color",
                fixedHeight: 40
            )

            ToolTextField(
                title: "Tags",
                text: $editColorTags,
                placeholder: "Enter tags separated by commas",
                fixedHeight: 40
            )

            HStack(spacing: 12) {
                ToolButton(
                    title: "Cancel",
                    action: {
                        showingEditColorDialog = false
                        colorToEdit = nil
                        editColorName = ""
                        editColorTags = ""
                    },
                    style: .secondary
                )

                ToolButton(
                    title: "Save Changes",
                    action: saveColorChanges,
                    style: .primary
                )
                .disabled(editColorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Export/Import Dialog

    private var exportImportDialog: some View {
        VStack(spacing: 20) {
            Text("Import/Export Palette")
                .font(.headline)

            VStack(spacing: 12) {
                Text("Export")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    ToolButton(
                        title: "Export as JSON",
                        action: exportAsJSON,
                        style: .secondary
                    )
                    .disabled(paletteService.savedColors.isEmpty)

                    ToolButton(
                        title: "Export as CSV",
                        action: exportAsCSV,
                        style: .secondary
                    )
                    .disabled(paletteService.savedColors.isEmpty)
                }
            }

            Divider()

            VStack(spacing: 12) {
                Text("Import")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    ToolButton(
                        title: "Import JSON",
                        action: importFromJSON,
                        style: .secondary
                    )

                    ToolButton(
                        title: "Clear All",
                        action: clearAllColors,
                        style: .destructive
                    )
                    .disabled(paletteService.savedColors.isEmpty)
                }
            }

            ToolButton(
                title: "Close",
                action: { showingExportImportDialog = false },
                style: .primary
            )
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Additional Actions

    private func saveColorChanges() {
        guard let colorToEdit = colorToEdit else { return }

        let trimmedName = editColorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let tags =
            editColorTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        paletteService.updateColor(id: colorToEdit.id, name: trimmedName, tags: tags)

        // Reset dialog state
        showingEditColorDialog = false
        self.colorToEdit = nil
        editColorName = ""
        editColorTags = ""
    }

    private func exportAsJSON() {
        let result = paletteService.exportPalette()
        switch result {
        case .success(let data):
            saveToFile(data: data, filename: "color-palette.json", type: "JSON")
        case .failure(let error):
            // Handle error - could show toast or alert
            print("Export failed: \(error)")
        }
    }

    private func exportAsCSV() {
        let result = paletteService.exportPaletteToCSV()
        switch result {
        case .success(let csvString):
            if let data = csvString.data(using: .utf8) {
                saveToFile(data: data, filename: "color-palette.csv", type: "CSV")
            }
        case .failure(let error):
            // Handle error - could show toast or alert
            print("Export failed: \(error)")
        }
    }

    private func importFromJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let result = paletteService.importPalette(from: data, replaceExisting: false)
                switch result {
                case .success(let count):
                    print("Imported \(count) colors successfully")
                // Could show success toast
                case .failure(let error):
                    print("Import failed: \(error)")
                // Could show error toast
                }
            } catch {
                print("Failed to read file: \(error)")
            }
        }

        showingExportImportDialog = false
    }

    private func clearAllColors() {
        paletteService.clearPalette()
        showingExportImportDialog = false
    }

    private func saveToFile(data: Data, filename: String, type: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = filename
        panel.allowedContentTypes = type == "JSON" ? [.json] : [.commaSeparatedText]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                print("\(type) exported successfully")
                // Could show success toast
            } catch {
                print("Failed to save file: \(error)")
                // Could show error toast
            }
        }

        showingExportImportDialog = false
    }

}

// MARK: - Color Swatch View

private struct ColorSwatchView: View {
    let savedColor: SavedColor
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 8) {
            // Color swatch
            Button(action: onSelect) {
                ColorPreviewSwatch(color: savedColor.color)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
            }

            // Color info
            VStack(spacing: 4) {
                Text(savedColor.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(savedColor.color.hexString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)

                if !savedColor.tags.isEmpty {
                    Text(savedColor.tags.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            // Action buttons
            HStack(spacing: 6) {
                Button(action: onSelect) {
                    Image(systemName: "eyedropper")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Select this color")

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Edit this color")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Delete this color")
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Color \(savedColor.name), \(savedColor.color.hexString)")
        .accessibilityHint("Double tap to select this color, or use context menu for more options")
        .contextMenu {
            Button("Select Color") {
                onSelect()
            }

            Button("Edit Color") {
                onEdit()
            }

            Divider()

            Button("Copy Hex") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(savedColor.color.hexString, forType: .string)
            }

            Button("Copy RGB") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(savedColor.color.rgbString, forType: .string)
            }

            Button("Copy HSL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(savedColor.color.hslString, forType: .string)
            }

            Divider()

            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

// MARK: - Color Preview Swatch

private struct ColorPreviewSwatch: View {
    let color: ColorRepresentation

    var body: some View {
        Rectangle()
            .fill(
                Color(
                    red: color.rgb.red / 255.0,
                    green: color.rgb.green / 255.0,
                    blue: color.rgb.blue / 255.0,
                    opacity: color.rgb.alpha
                )
            )
            .accessibilityLabel("Color preview: \(color.hexString)")
    }
}

// MARK: - Preview

#Preview {
    ColorPaletteView(
        paletteService: ColorPaletteService(),
        onColorSelected: { _ in },
        currentColor: nil
    )
    .frame(width: 400, height: 500)
    .padding()
}
