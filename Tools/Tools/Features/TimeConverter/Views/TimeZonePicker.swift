//
//  TimeZonePicker.swift
//  Tools
//
//  Created by Kiro on 2025/7/28.
//

import SwiftUI

struct TimeZonePicker: View {
    @Binding var selection: TimeZone
    @State private var searchText = ""
    @State private var isExpanded = false

    private let timeService = TimeConverterService()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Text(displayName(for: selection))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("时区选择器")
            .accessibilityHint("当前选择: \(displayName(for: selection))")
            .accessibilityValue(displayName(for: selection))

            if isExpanded {
                VStack(spacing: 0) {
                    // Search field
                    TextField("搜索时区...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    // Timezone list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredTimeZones, id: \.identifier) { tzInfo in
                                Button(action: {
                                    if let timeZone = TimeZone(identifier: tzInfo.identifier) {
                                        selection = timeZone
                                        isExpanded = false
                                        searchText = ""
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(tzInfo.displayName)
                                                .font(.callout)
                                                .foregroundStyle(.primary)

                                            Text("\(tzInfo.identifier) (\(tzInfo.offsetString))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if tzInfo.identifier == selection.identifier {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        tzInfo.identifier == selection.identifier
                                            ? Color.blue.opacity(0.1)
                                            : Color.clear
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("选择时区: \(tzInfo.displayName)")
                                .accessibilityHint("偏移量: \(tzInfo.offsetString)")

                                if tzInfo.identifier != filteredTimeZones.last?.identifier {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .onTapGesture {
            // Close picker when tapping outside
            if isExpanded {
                isExpanded = false
                searchText = ""
            }
        }
    }

    private var filteredTimeZones: [TimeZoneInfo] {
        let allTimeZones =
            TimeZoneInfo.commonTimeZones
            + timeService.searchTimezones(query: searchText.isEmpty ? "" : searchText)

        if searchText.isEmpty {
            return Array(Set(allTimeZones)).sorted { $0.displayName < $1.displayName }
        } else {
            return Array(Set(allTimeZones))
                .filter { tzInfo in
                    tzInfo.displayName.localizedCaseInsensitiveContains(searchText)
                        || tzInfo.identifier.localizedCaseInsensitiveContains(searchText)
                        || tzInfo.abbreviation.localizedCaseInsensitiveContains(searchText)
                }
                .sorted { $0.displayName < $1.displayName }
        }
    }

    private func displayName(for timeZone: TimeZone) -> String {
        let tzInfo = TimeZoneInfo(timeZone: timeZone)
        return "\(tzInfo.displayName) (\(tzInfo.offsetString))"
    }
}

#Preview {
    @Previewable @State var selectedTimeZone = TimeZone.current

    VStack {
        TimeZonePicker(selection: $selectedTimeZone)

        Text("Selected: \(selectedTimeZone.identifier)")
            .padding()
    }
    .padding()
    .frame(width: 400, height: 300)
}
