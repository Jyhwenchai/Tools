import SwiftUI

struct SettingsView: View {
  @State private var settings = AppSettings.shared
  @State private var showingResetAlert = false
  @State private var showingImportExport = false
  @State private var showingPrivacyPolicy = false

  var body: some View {
    NavigationView {
      Form {
        // MARK: - Appearance Section

        Section("外观设置") {
          HStack {
            Image(systemName: settings.theme.systemImage)
              .foregroundColor(.accentColor)
              .frame(width: 20)

            Text("主题")

            Spacer()

            Picker("主题", selection: $settings.theme) {
              ForEach(AppTheme.allCases, id: \.self) { theme in
                Text(theme.rawValue).tag(theme)
              }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
          }

          HStack {
            Image(systemName: "sparkles")
              .foregroundColor(.accentColor)
              .frame(width: 20)

            Text("显示处理动画")

            Spacer()

            Toggle("", isOn: $settings.showProcessingAnimations)
              .toggleStyle(.switch)
          }
        }

        // MARK: - Behavior Section

        Section("行为设置") {
          HStack {
            Image(systemName: "doc.on.clipboard")
              .foregroundColor(.accentColor)
              .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
              Text("粘贴板历史记录数量")
              Text("当前设置: \(settings.maxClipboardHistory) 条")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Stepper("", value: $settings.maxClipboardHistory, in: 10...1000, step: 10)
              .frame(width: 100)
          }

          HStack {
            Image(systemName: "square.and.arrow.down")
              .foregroundColor(.accentColor)
              .frame(width: 20)

            Text("自动保存处理结果")

            Spacer()

            Toggle("", isOn: $settings.autoSaveResults)
              .toggleStyle(.switch)
          }

          HStack {
            Image(systemName: "doc.on.doc")
              .foregroundColor(.accentColor)
              .frame(width: 20)

            Text("自动复制结果到剪贴板")

            Spacer()

            Toggle("", isOn: $settings.autoCopyResults)
              .toggleStyle(.switch)
          }

          HStack {
            Image(systemName: "exclamationmark.triangle")
              .foregroundColor(.accentColor)
              .frame(width: 20)

            Text("确认危险操作")

            Spacer()

            Toggle("", isOn: $settings.confirmDestructiveActions)
              .toggleStyle(.switch)
          }
        }

        // MARK: - Image Processing Section

        Section("图片处理设置") {
          HStack {
            Image(systemName: "photo")
              .foregroundColor(.accentColor)
              .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
              Text("默认图片质量")
              Text("当前设置: \(Int(settings.defaultImageQuality * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack {
              Slider(value: $settings.defaultImageQuality, in: 0.1...1.0, step: 0.1)
                .frame(width: 120)

              HStack {
                Text("10%")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                Spacer()
                Text("100%")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
              .frame(width: 120)
            }
          }
        }

        // MARK: - Privacy Section

        Section("隐私") {
          Button(action: { showingPrivacyPolicy = true }) {
            HStack {
              Image(systemName: "hand.raised")
                .foregroundColor(.accentColor)
                .frame(width: 20)

              Text("隐私政策")

              Spacer()

              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .buttonStyle(.plain)
        }

        // MARK: - Advanced Section

        Section("高级设置") {
          Button(action: { showingImportExport = true }) {
            HStack {
              Image(systemName: "square.and.arrow.up.on.square")
                .foregroundColor(.accentColor)
                .frame(width: 20)

              Text("导入/导出设置")

              Spacer()

              Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .buttonStyle(.plain)

          Button(action: { showingResetAlert = true }) {
            HStack {
              Image(systemName: "arrow.clockwise")
                .foregroundColor(.red)
                .frame(width: 20)

              Text("重置为默认设置")
                .foregroundColor(.red)

              Spacer()
            }
          }
          .buttonStyle(.plain)
        }
      }
      .formStyle(.grouped)
      .navigationTitle("设置")
      .frame(minWidth: 500, minHeight: 400)
    }
    .alert("重置设置", isPresented: $showingResetAlert) {
      Button("取消", role: .cancel) {}
      Button("重置", role: .destructive) {
        settings.resetToDefaults()
      }
    } message: {
      Text("这将重置所有设置为默认值，此操作无法撤销。")
    }
    .sheet(isPresented: $showingImportExport) {
      ImportExportSettingsView()
    }
    .sheet(isPresented: $showingPrivacyPolicy) {
      PrivacyPolicyView()
    }
  }

  // MARK: - Helper Methods

  // Note: Sensitive data clearing is now handled automatically by SecurityService
  // when the app becomes inactive or terminates
}

// MARK: - Import/Export Settings View

struct ImportExportSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var settings = AppSettings.shared
  @State private var exportedText = ""
  @State private var importText = ""
  @State private var showingExportSuccess = false
  @State private var showingImportError = false
  @State private var importErrorMessage = ""

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Export Section
        GroupBox("导出设置") {
          VStack(alignment: .leading, spacing: 12) {
            Text("将当前设置导出为JSON格式")
              .font(.caption)
              .foregroundColor(.secondary)

            Button("导出设置") {
              exportSettings()
            }
            .buttonStyle(.borderedProminent)

            if !exportedText.isEmpty {
              ScrollView {
                Text(exportedText)
                  .font(.system(.caption, design: .monospaced))
                  .textSelection(.enabled)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
              .frame(height: 100)
              .background(Color(NSColor.textBackgroundColor))
              .cornerRadius(8)
            }
          }
          .padding()
        }

        // Import Section
        GroupBox("导入设置") {
          VStack(alignment: .leading, spacing: 12) {
            Text("粘贴JSON格式的设置数据")
              .font(.caption)
              .foregroundColor(.secondary)

            TextEditor(text: $importText)
              .font(.system(.caption, design: .monospaced))
              .frame(height: 100)
              .background(Color(NSColor.textBackgroundColor))
              .cornerRadius(8)

            Button("导入设置") {
              importSettings()
            }
            .buttonStyle(.borderedProminent)
            .disabled(importText.isEmpty)
          }
          .padding()
        }

        Spacer()
      }
      .padding()
      .navigationTitle("导入/导出设置")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") {
            dismiss()
          }
        }
      }
    }
    .alert("导出成功", isPresented: $showingExportSuccess) {
      Button("确定") {}
    } message: {
      Text("设置已导出到下方文本框，您可以复制保存。")
    }
    .alert("导入失败", isPresented: $showingImportError) {
      Button("确定") {}
    } message: {
      Text(importErrorMessage)
    }
  }

  private func exportSettings() {
    let settingsData = settings.exportSettings()
    do {
      let jsonData = try JSONSerialization.data(
        withJSONObject: settingsData,
        options: .prettyPrinted)
      exportedText = String(data: jsonData, encoding: .utf8) ?? ""
      showingExportSuccess = true
    } catch {
      exportedText = "导出失败: \(error.localizedDescription)"
    }
  }

  private func importSettings() {
    guard let data = importText.data(using: .utf8) else {
      importErrorMessage = "无效的文本格式"
      showingImportError = true
      return
    }

    do {
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      guard let settingsDict = jsonObject as? [String: Any] else {
        importErrorMessage = "JSON格式不正确"
        showingImportError = true
        return
      }

      settings.importSettings(from: settingsDict)
      dismiss()
    } catch {
      importErrorMessage = "JSON解析失败: \(error.localizedDescription)"
      showingImportError = true
    }
  }
}

#Preview {
  SettingsView()
}
