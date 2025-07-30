//
//  SingleConversionView.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI

struct SingleConversionView: View {
    @State private var selectedConversionMode: ConversionMode = .timestampToDate
    @Environment(ToastManager.self) private var toastManager

    enum ConversionMode: String, CaseIterable, Identifiable {
        case timestampToDate = "timestamp_to_date"
        case dateToTimestamp = "date_to_timestamp"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .timestampToDate:
                return "时间戳转日期"
            case .dateToTimestamp:
                return "日期转时间戳"
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Mode Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("转换模式")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityLabel("转换模式选择")

                HStack(spacing: 4) {
                    ForEach(ConversionMode.allCases) { mode in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedConversionMode = mode
                            }
                        }) {
                            Text(mode.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedConversionMode == mode ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            selectedConversionMode == mode
                                                ? Color.accentColor : Color(.controlBackgroundColor)
                                        )
                                        .animation(
                                            .easeInOut(duration: 0.2), value: selectedConversionMode
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedConversionMode == mode
                                                ? Color.clear : Color(.separatorColor).opacity(0.3),
                                            lineWidth: 1
                                        )
                                        .animation(
                                            .easeInOut(duration: 0.2), value: selectedConversionMode
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(mode.displayName)
                        .accessibilityHint("选择\(mode.displayName)模式")
                        .accessibilityAddTraits(
                            selectedConversionMode == mode ? [.isSelected, .isButton] : [.isButton])
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("转换模式选择器")
                .accessibilityValue(selectedConversionMode.displayName)
            }

            // Conversion Content with smooth transitions
            Group {
                switch selectedConversionMode {
                case .timestampToDate:
                    TimestampToDateView()
                        .environment(toastManager)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                case .dateToTimestamp:
                    DateToTimestampView()
                        .environment(toastManager)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedConversionMode)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("单个转换界面")
        .accessibilityHint("提供时间戳和日期之间的单个转换功能")
        .onReceive(NotificationCenter.default.publisher(for: .timeConverterTriggerConversion)) {
            notification in
            if let userInfo = notification.userInfo,
                let tab = userInfo["tab"] as? String,
                tab == "single"
            {
                // Trigger conversion in the active mode
                triggerConversion()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeConverterTriggerCopy)) {
            notification in
            if let userInfo = notification.userInfo,
                let tab = userInfo["tab"] as? String,
                tab == "single"
            {
                // Trigger copy in the active mode
                triggerCopy()
            }
        }
    }

    // MARK: - Keyboard Actions

    private func triggerConversion() {
        // Post notification to the active conversion view
        switch selectedConversionMode {
        case .timestampToDate:
            NotificationCenter.default.post(name: .timestampToDateTriggerConversion, object: nil)
        case .dateToTimestamp:
            NotificationCenter.default.post(name: .dateToTimestampTriggerConversion, object: nil)
        }
    }

    private func triggerCopy() {
        // Post notification to the active conversion view
        switch selectedConversionMode {
        case .timestampToDate:
            NotificationCenter.default.post(name: .timestampToDateTriggerCopy, object: nil)
        case .dateToTimestamp:
            NotificationCenter.default.post(name: .dateToTimestampTriggerCopy, object: nil)
        }
    }
}

#Preview {
    SingleConversionView()
        .padding()
}
