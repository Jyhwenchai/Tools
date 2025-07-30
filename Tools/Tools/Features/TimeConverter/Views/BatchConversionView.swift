import SwiftUI
import UniformTypeIdentifiers

struct BatchConversionView: View {
    @State private var batchService = BatchConversionService()
    @Environment(ToastManager.self) private var toastManager

    // Input and configuration
    @State private var inputText = ""
    @State private var sourceFormat: TimeFormat = .timestamp
    @State private var targetFormat: TimeFormat = .iso8601
    @State private var sourceTimeZone: TimeZone = .current
    @State private var targetTimeZone: TimeZone = .current
    @State private var customFormat = "yyyy-MM-dd HH:mm:ss"
    @State private var includeMilliseconds = false

    // Processing state
    @State private var isProcessing = false
    @State private var results: [BatchConversionResult] = []
    @State private var validationResult: BatchInputValidationResult?

    // Export functionality
    @State private var exportFormat: BatchExportFormat = .csv
    @State private var isExporting = false

    // UI state
    @State private var showValidationDetails = false
    @State private var expandedResultIds: Set<UUID> = []

    // Performance optimization
    @State private var isLargeDataset = false
    @State private var displayedResults: [BatchConversionResult] = []
    @State private var resultsPageSize = 50
    @State private var currentResultsPage = 0

    var body: some View {
        VStack(spacing: 16) {
            // Input section
            inputSection

            // Configuration section
            configurationSection

            // Validation and processing section
            processingSection

            // Results section
            if !results.isEmpty {
                resultsSection
            }

            Spacer()
        }
        .padding()
        .onChange(of: batchService.processingState) { _, newState in
            handleProcessingStateChange(newState)
        }
        .onChange(of: inputText) { _, _ in
            validateInput()
        }
        .onChange(of: sourceFormat) { _, _ in
            validateInput()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("批量转换界面")
        .accessibilityHint("提供多个时间戳或日期的批量转换功能")
        .onReceive(NotificationCenter.default.publisher(for: .timeConverterTriggerConversion)) {
            notification in
            if let userInfo = notification.userInfo,
                let tab = userInfo["tab"] as? String,
                tab == "batch"
            {
                startBatchProcessing()
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("批量输入")
                .font(.headline)
                .fontWeight(.semibold)

            ToolTextField(
                title: "输入数据（每行一个）",
                text: $inputText,
                placeholder: "请输入要转换的时间戳或日期，每行一个\n例如：\n1640995200\n1641081600\n1641168000",
                minHeight: 120,
                maxHeight: 200
            )
            .accessibilityLabel("批量输入文本框")
            .accessibilityHint("输入要批量转换的时间戳或日期，每行一个")
            .focusable(true)

            // Validation summary
            if let validation = validationResult {
                validationSummaryView(validation)
            }
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("转换配置")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                // Source format
                VStack(alignment: .leading, spacing: 4) {
                    Text("源格式")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Menu {
                        ForEach(TimeFormat.allCases) { format in
                            Button(action: {
                                sourceFormat = format
                            }) {
                                HStack {
                                    Text(format.displayName)
                                    if sourceFormat == format {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(sourceFormat.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("源格式选择器")
                    .accessibilityHint("选择输入数据的格式")
                    .accessibilityValue(sourceFormat.displayName)
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                // Target format
                VStack(alignment: .leading, spacing: 4) {
                    Text("目标格式")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Menu {
                        ForEach(TimeFormat.allCases) { format in
                            Button(action: {
                                targetFormat = format
                            }) {
                                HStack {
                                    Text(format.displayName)
                                    if targetFormat == format {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(targetFormat.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("目标格式选择器")
                    .accessibilityHint("选择输出数据的格式")
                    .accessibilityValue(targetFormat.displayName)
                }
            }

            // Timezone configuration
            if sourceFormat != .timestamp || targetFormat != .timestamp {
                timezoneConfigurationView
            }

            // Custom format configuration
            if sourceFormat == .custom || targetFormat == .custom {
                customFormatView
            }

            // Additional options
            additionalOptionsView
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var timezoneConfigurationView: some View {
        HStack(spacing: 16) {
            if sourceFormat != .timestamp {
                VStack(alignment: .leading, spacing: 4) {
                    Text("源时区")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Menu {
                        ForEach(TimeZoneInfo.commonTimeZones, id: \.identifier) { tzInfo in
                            Button(action: {
                                if let timeZone = TimeZone(identifier: tzInfo.identifier) {
                                    sourceTimeZone = timeZone
                                }
                            }) {
                                HStack {
                                    Text("\(tzInfo.displayName) (\(tzInfo.offsetString))")
                                    if sourceTimeZone.identifier == tzInfo.identifier {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(
                                "\(TimeZoneInfo(timeZone: sourceTimeZone).displayName) (\(TimeZoneInfo(timeZone: sourceTimeZone).offsetString))"
                            )
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if targetFormat != .timestamp {
                VStack(alignment: .leading, spacing: 4) {
                    Text("目标时区")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Menu {
                        ForEach(TimeZoneInfo.commonTimeZones, id: \.identifier) { tzInfo in
                            Button(action: {
                                if let timeZone = TimeZone(identifier: tzInfo.identifier) {
                                    targetTimeZone = timeZone
                                }
                            }) {
                                HStack {
                                    Text("\(tzInfo.displayName) (\(tzInfo.offsetString))")
                                    if targetTimeZone.identifier == tzInfo.identifier {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(
                                "\(TimeZoneInfo(timeZone: targetTimeZone).displayName) (\(TimeZoneInfo(timeZone: targetTimeZone).offsetString))"
                            )
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var customFormatView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("自定义格式")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("例如: yyyy-MM-dd HH:mm:ss", text: $customFormat)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                )

            Text("常用格式: yyyy-MM-dd, MM/dd/yyyy, dd.MM.yyyy HH:mm")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var additionalOptionsView: some View {
        HStack {
            Toggle("包含毫秒", isOn: $includeMilliseconds)
                .font(.callout)
                .toggleStyle(.switch)

            Spacer()
        }
    }

    // MARK: - Processing Section

    private var processingSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: startBatchProcessing) {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isProcessing ? "处理中..." : "开始批量转换")
                    }
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(
                    inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || isProcessing
                )
                .accessibilityLabel(isProcessing ? "正在处理批量转换" : "开始批量转换")
                .accessibilityHint("开始处理所有输入的转换项目")
                .keyboardShortcut(.return, modifiers: [])

                if isProcessing {
                    ToolButton(
                        title: "取消",
                        action: cancelProcessing,
                        style: .secondary
                    )
                    .accessibilityLabel("取消批量处理")
                    .accessibilityHint("停止当前的批量转换处理")
                }

                Spacer()

                if let validation = validationResult, validation.hasValidItems {
                    Text("有效项目: \(validation.validItems.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Progress indicator
            if case .processing(let current, let total) = batchService.processingState {
                VStack(spacing: 4) {
                    ProgressView(value: Double(current), total: Double(total))
                    Text("处理进度: \(current)/\(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("转换结果")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Export controls
                exportControlsView
            }

            // Summary
            if let summary = batchService.lastSummary {
                summaryView(summary)
            }

            // Results list with pagination for large datasets
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(displayedResults) { result in
                        resultRowView(result)
                    }

                    // Load more button for large datasets
                    if isLargeDataset && displayedResults.count < results.count {
                        Button("加载更多结果 (\(results.count - displayedResults.count) 项)") {
                            loadMoreResults()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var exportControlsView: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(BatchExportFormat.allCases) { format in
                    Button(action: {
                        exportFormat = format
                    }) {
                        HStack {
                            Text(format.displayName)
                            if exportFormat == format {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(exportFormat.displayName)
                        .foregroundStyle(.primary)
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                )
            }
            .frame(width: 80)

            Button(action: exportResults) {
                HStack(spacing: 4) {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text("导出")
                }
                .font(.callout)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.controlBackgroundColor))
                )
                .foregroundStyle(.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor).opacity(0.6), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(results.isEmpty || isExporting)
        }
    }

    // MARK: - Helper Views

    private func validationSummaryView(_ validation: BatchInputValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if validation.hasValidItems {
                    Label(
                        "\(validation.validItems.count) 个有效项目", systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                    .font(.caption)
                }

                if validation.hasInvalidItems {
                    Label(
                        "\(validation.invalidItems.count) 个无效项目",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                    .font(.caption)
                }

                Spacer()

                if validation.hasInvalidItems {
                    Button("查看详情") {
                        showValidationDetails.toggle()
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }

            if showValidationDetails && validation.hasInvalidItems {
                VStack(alignment: .leading, spacing: 2) {
                    Text("无效项目:")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ForEach(Array(validation.invalidItems.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text("• \(item.input)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.error)
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func summaryView(_ summary: BatchConversionSummary) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("总计: \(summary.totalItems)")
                    .font(.caption)
                    .foregroundStyle(.primary)
                Text("成功: \(summary.successfulItems)")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("失败: \(summary.failedItems)")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text("成功率: \(String(format: "%.1f", summary.successRate * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("总耗时: \(String(format: "%.0f", summary.totalProcessingTime * 1000))ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("平均: \(String(format: "%.1f", summary.averageProcessingTime * 1000))ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func resultRowView(_ result: BatchConversionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Status indicator
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.success ? .green : .red)
                    .font(.caption)

                // Input
                Text(result.input)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Processing time
                Text("\(String(format: "%.1f", result.processingTime * 1000))ms")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                // Expand/collapse button
                Button(action: {
                    if expandedResultIds.contains(result.id) {
                        expandedResultIds.remove(result.id)
                    } else {
                        expandedResultIds.insert(result.id)
                    }
                }) {
                    Image(
                        systemName: expandedResultIds.contains(result.id)
                            ? "chevron.up" : "chevron.down"
                    )
                    .font(.caption2)
                }
                .buttonStyle(.borderless)
            }

            // Expanded content
            if expandedResultIds.contains(result.id) {
                VStack(alignment: .leading, spacing: 4) {
                    if result.success, let output = result.output {
                        HStack {
                            Text("结果:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Spacer()

                            CopyButton(content: output)
                        }

                        Text(output)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                            .padding(6)
                            .background(Color(.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else if let error = result.error {
                        HStack {
                            Text("错误:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Actions

    private func validateInput() {
        let inputs = batchService.validateBatchInput(
            inputText, format: sourceFormat, customFormat: customFormat)
        let newValidationResult = batchService.validateBatchItems(
            inputs, format: sourceFormat, customFormat: customFormat)

        // Show validation warnings if there are invalid items
        if let oldResult = validationResult,
            newValidationResult.hasInvalidItems
                && newValidationResult.invalidItems.count > oldResult.invalidItems.count
        {
            let newInvalidCount =
                newValidationResult.invalidItems.count - oldResult.invalidItems.count
            toastManager.show(
                "发现 \(newInvalidCount) 个新的无效输入项目",
                type: .warning,
                duration: 2.0
            )
        }

        validationResult = newValidationResult
    }

    private func startBatchProcessing() {
        guard let validation = validationResult, validation.hasValidItems else {
            toastManager.show("没有有效的输入项目", type: .warning, duration: 3.0)
            return
        }

        isProcessing = true
        results = []

        // Create batch items
        let items = validation.validItems.map { input in
            BatchConversionItem(
                input: input,
                sourceFormat: sourceFormat,
                targetFormat: targetFormat,
                sourceTimeZone: sourceTimeZone,
                targetTimeZone: targetTimeZone,
                customFormat: customFormat,
                includeMilliseconds: includeMilliseconds
            )
        }

        // Show start notification
        toastManager.show(
            "准备批量处理 \(items.count) 个项目",
            type: .info,
            duration: 2.0
        )

        // Start processing
        batchService.startBatchProcessing(items: items)
    }

    private func cancelProcessing() {
        batchService.cancelProcessing()
        isProcessing = false
        toastManager.show("批量处理已取消", type: .info)
    }

    private func handleProcessingStateChange(_ state: BatchProcessingState) {
        switch state {
        case .idle:
            isProcessing = false

        case .processing(let current, let total):
            isProcessing = true

            // Show progress notification for significant milestones
            if current == 1 {
                toastManager.show(
                    "开始批量处理 \(total) 个项目",
                    type: .info,
                    duration: 2.0
                )
            } else if current % max(1, total / 4) == 0 || current == total {
                // Show progress at 25%, 50%, 75%, and 100%
                let percentage = Int((Double(current) / Double(total)) * 100)
                toastManager.show(
                    "批量处理进度: \(percentage)% (\(current)/\(total))",
                    type: .info,
                    duration: 1.5
                )
            }

        case .completed(let summary):
            isProcessing = false
            results = batchService.lastResults

            // Optimize display for large datasets
            updateDisplayedResults()

            // Show completion toast
            if summary.hasErrors {
                toastManager.show(
                    "批量转换完成，\(summary.successfulItems) 成功，\(summary.failedItems) 失败",
                    type: .warning,
                    duration: 4.0
                )
            } else {
                toastManager.show(
                    "批量转换完成，共处理 \(summary.totalItems) 个项目",
                    type: .success,
                    duration: 3.0
                )
            }

        case .cancelled:
            isProcessing = false
            toastManager.show("批量处理已取消", type: .info, duration: 2.0)
        }
    }

    // MARK: - Performance Optimization Methods

    private func updateDisplayedResults() {
        isLargeDataset = results.count > resultsPageSize
        currentResultsPage = 0

        if isLargeDataset {
            displayedResults = Array(results.prefix(resultsPageSize))

            // Show performance tip for large datasets
            if results.count > 200 {
                toastManager.show(
                    "大数据集检测：为了保持界面流畅，结果将分页显示",
                    type: .info,
                    duration: 3.0
                )
            }
        } else {
            displayedResults = results
        }
    }

    private func loadMoreResults() {
        let startIndex = (currentResultsPage + 1) * resultsPageSize
        let endIndex = min(startIndex + resultsPageSize, results.count)

        if startIndex < results.count {
            let newResults = Array(results[startIndex..<endIndex])
            displayedResults.append(contentsOf: newResults)
            currentResultsPage += 1
        }
    }

    private func exportResults() {
        guard !results.isEmpty else {
            toastManager.show("没有可导出的结果", type: .warning, duration: 2.0)
            return
        }

        isExporting = true

        // Show export start notification
        toastManager.show(
            "开始导出 \(results.count) 个转换结果",
            type: .info,
            duration: 2.0
        )

        Task {
            do {
                let content = batchService.exportResults(results, format: exportFormat)
                let fileName =
                    "batch_conversion_results_\(Date().timeIntervalSince1970).\(exportFormat.fileExtension)"

                let utType: UTType =
                    switch exportFormat {
                    case .csv: .commaSeparatedText
                    case .json: .json
                    case .txt: .plainText
                    }

                if let url = await FileDialogUtils.showEnhancedSaveDialog(
                    suggestedName: fileName,
                    allowedTypes: [utType],
                    message: "导出批量转换结果",
                    title: "保存转换结果"
                ) {
                    try content.write(to: url, atomically: true, encoding: .utf8)

                    await MainActor.run {
                        toastManager.show("结果已导出到 \(url.lastPathComponent)", type: .success)
                    }
                }
            } catch {
                await MainActor.run {
                    toastManager.show("导出失败: \(error.localizedDescription)", type: .error)
                }
            }

            await MainActor.run {
                isExporting = false
            }
        }
    }
}

#Preview {
    BatchConversionView()
        .frame(width: 600, height: 800)
}
