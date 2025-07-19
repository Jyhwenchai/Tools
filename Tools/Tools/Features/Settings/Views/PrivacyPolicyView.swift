import SwiftUI

struct PrivacyPolicyView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text("隐私政策")
              .font(.largeTitle)
              .fontWeight(.bold)
            
            Text("最后更新：2025年7月19日")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          
          // Data Processing Section
          privacySection(
            title: "数据处理原则",
            icon: "shield.checkered",
            content: """
            • 所有数据处理完全在您的设备本地进行
            • 不会向任何服务器或第三方发送您的数据
            • 不收集任何个人身份信息
            • 不使用任何网络连接进行数据传输
            """
          )
          
          // Clipboard Data Section
          privacySection(
            title: "剪贴板数据",
            icon: "doc.on.clipboard",
            content: """
            • 剪贴板历史记录仅存储在您的设备上
            • 您可以随时清空剪贴板历史记录
            • 应用退出时可选择自动清理敏感数据
            • 支持暂停和恢复剪贴板监控功能
            """
          )
          
          // File Processing Section
          privacySection(
            title: "文件处理",
            icon: "doc.text",
            content: """
            • 只处理您主动选择的文件
            • 处理后的文件保存在您指定的位置
            • 不会备份或复制您的原始文件
            • 支持的文件大小限制为100MB以确保性能
            """
          )
          
          // Encryption Section
          privacySection(
            title: "加密功能",
            icon: "lock.shield",
            content: """
            • 使用行业标准的加密算法（AES、SHA等）
            • 加密密钥不会被存储或记录
            • 所有加密操作在本地内存中完成
            • 应用退出时自动清理临时加密数据
            """
          )
          
          // Permissions Section
          privacySection(
            title: "系统权限",
            icon: "key",
            content: """
            • 文件访问：仅用于处理您选择的文件
            • 剪贴板访问：用于剪贴板管理功能
            • 不请求网络访问权限
            • 不请求位置或其他敏感权限
            """
          )
          
          // Data Security Section
          privacySection(
            title: "数据安全",
            icon: "checkmark.shield",
            content: """
            • 输入数据经过安全验证和清理
            • 防止恶意代码注入攻击
            • 敏感数据在内存中的存储时间最短
            • 支持手动清理所有敏感数据
            """
          )
          
          // User Control Section
          privacySection(
            title: "用户控制",
            icon: "person.badge.key",
            content: """
            • 您完全控制所有数据的处理和存储
            • 可以随时删除任何存储的数据
            • 可以随时禁用任何功能
            • 应用设置支持导入导出，便于数据迁移
            """
          )
          
          // Contact Section
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Image(systemName: "envelope")
                .foregroundColor(.accentColor)
                .frame(width: 20)
              
              Text("联系我们")
                .font(.headline)
                .fontWeight(.semibold)
            }
            
            Text("如果您对隐私政策有任何疑问，请通过应用内反馈功能联系我们。")
              .font(.body)
              .foregroundColor(.secondary)
          }
          .padding()
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(8)
        }
        .padding()
      }
      .navigationTitle("隐私政策")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("关闭") {
            dismiss()
          }
        }
      }
    }
    .frame(minWidth: 600, minHeight: 500)
  }
  
  // MARK: - Helper Views
  
  @ViewBuilder
  private func privacySection(title: String, icon: String, content: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(.accentColor)
          .frame(width: 20)
        
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
      }
      
      Text(content)
        .font(.body)
        .lineSpacing(4)
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(8)
  }
}

#Preview {
  PrivacyPolicyView()
}