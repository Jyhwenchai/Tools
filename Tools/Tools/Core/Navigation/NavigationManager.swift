//
//  NavigationManager.swift
//  Tools
//
//  Created by Kiro on 2025/7/17.
//

import SwiftUI

@Observable
class NavigationManager {
  var selectedTool: ToolType = .encryption

  enum ToolType: String, CaseIterable, Identifiable {
    case encryption = "加密解密"
    case json = "JSON工具"
    case imageProcessing = "图片处理"
    case qrCode = "二维码"
    case timeConverter = "时间转换"
    case clipboard = "粘贴板"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
      switch self {
      case .encryption: return "lock.shield"
      case .json: return "doc.text"
      case .imageProcessing: return "photo"
      case .qrCode: return "qrcode"
      case .timeConverter: return "clock"
      case .clipboard: return "doc.on.clipboard"
      case .settings: return "gearshape"
      }
    }

    var name: String { rawValue }

    var description: String {
      switch self {
      case .encryption: return "文本加密解密工具"
      case .json: return "JSON格式化和处理"
      case .imageProcessing: return "图片压缩和处理"
      case .qrCode: return "二维码生成和识别"
      case .timeConverter: return "时间格式转换"
      case .clipboard: return "粘贴板历史管理"
      case .settings: return "应用设置和偏好"
      }
    }
  }
}
