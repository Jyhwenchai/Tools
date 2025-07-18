//
//  ContentView.swift
//  Tools
//
//  Created by didong on 2025/7/17.
//

import SwiftUI

struct ContentView: View {
  @State
  private var navigationManager = NavigationManager()

  var body: some View {
    NavigationSplitView {
      SidebarView(selection: $navigationManager.selectedTool)
        .navigationSplitViewColumnWidth(240)
    } detail: {
      ToolDetailView(tool: navigationManager.selectedTool)
        .navigationSplitViewColumnWidth(min: 600, ideal: 800)
    }
    .navigationSplitViewStyle(.balanced)
  }
}

struct SidebarView: View {
  @Binding
  var selection: NavigationManager.ToolType

  var body: some View {
    List(NavigationManager.ToolType.allCases, id: \.self, selection: $selection) { tool in
      NavigationLink(value: tool) {
        HStack(spacing: 12) {
          Image(systemName: tool.icon)
            .frame(width: 20, height: 20)
            .foregroundStyle(.secondary)

          Text(tool.name)
            .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 4)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("工具")
  }
}

struct ToolDetailView: View {
  let tool: NavigationManager.ToolType

  var body: some View {
    VStack(spacing: 0) {
      switch tool {
        case .encryption:
          EncryptionView()
        case .json:
          JSONView()
        case .imageProcessing:
          ImageProcessingView()
        case .qrCode:
          QRCodeView()
        case .timeConverter:
          TimeConverterView()
        default:
          PlaceholderView(tool: tool)
      }
    }
  }
}

struct PlaceholderView: View {
  let tool: NavigationManager.ToolType

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      // Header
      VStack(alignment: .leading, spacing: 8) {
        Text(tool.name)
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(tool.description)
          .font(.callout)
          .foregroundStyle(.secondary)
      }

      // Tool content placeholder
      BrightCardView {
        VStack {
          Image(systemName: tool.icon)
            .font(.system(size: 48))
            .foregroundStyle(.secondary)

          Text("功能开发中...")
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
      }

      Spacer()
    }
    .padding(24)
    .navigationTitle(tool.name)
  }
}

#Preview {
  ContentView()
}
