import SwiftUI
import WebKit

// MARK: - Notification Names
extension Notification.Name {
  static let jsonExpandAll = Notification.Name("jsonExpandAll")
  static let jsonCollapseAll = Notification.Name("jsonCollapseAll")
  static let jsonSearch = Notification.Name("jsonSearch")
  static let jsonClearSearch = Notification.Name("jsonClearSearch")
}

struct JSONWebView: View {
  let jsonString: String
  @State private var searchText: String = ""
  @State private var isSearching: Bool = false
  
  var body: some View {
    VStack(spacing: 0) {
      // 控制工具栏
      controlToolbar
      
      // JSON WebView
      _PlatformWebView(
        jsonString: jsonString,
        searchText: searchText,
        isSearching: isSearching
      )
      .edgesIgnoringSafeArea(.all)
      .id(jsonString)  // 当jsonString改变时重新创建视图
    }
  }
  
  private var controlToolbar: some View {
    HStack(spacing: 12) {
      // 展开/收起按钮
      HStack(spacing: 8) {
        Button(action: {
          // 展开所有
          NotificationCenter.default.post(name: .jsonExpandAll, object: nil)
        }) {
          HStack(spacing: 4) {
            Image(systemName: "chevron.down.circle")
              .font(.system(size: 14))
            Text("展开")
              .font(.caption)
          }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.blue)
        
        Button(action: {
          // 收起所有
          NotificationCenter.default.post(name: .jsonCollapseAll, object: nil)
        }) {
          HStack(spacing: 4) {
            Image(systemName: "chevron.up.circle")
              .font(.system(size: 14))
            Text("收起")
              .font(.caption)
          }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.blue)
      }
      
      Spacer()
      
      // 搜索区域
      HStack(spacing: 8) {
        if isSearching {
          HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 12))
              .foregroundStyle(.secondary)
            
            TextField("搜索JSON...", text: $searchText)
              .textFieldStyle(.plain)
              .font(.caption)
              .frame(width: 120)
              .onSubmit {
                performSearch()
              }
              .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                  clearSearch()
                } else {
                  performSearch()
                }
              }
            
            Button(action: {
              clearSearch()
              isSearching = false
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color(NSColor.controlBackgroundColor))
          .cornerRadius(6)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )
        } else {
          Button(action: {
            isSearching = true
          }) {
            HStack(spacing: 4) {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
              Text("搜索")
                .font(.caption)
            }
          }
          .buttonStyle(.borderless)
          .foregroundStyle(.blue)
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    .overlay(
      Rectangle()
        .frame(height: 0.5)
        .foregroundStyle(Color.secondary.opacity(0.3)),
      alignment: .bottom
    )
  }
  
  private func performSearch() {
    NotificationCenter.default.post(
      name: .jsonSearch,
      object: nil,
      userInfo: ["query": searchText]
    )
  }
  
  private func clearSearch() {
    searchText = ""
    NotificationCenter.default.post(name: .jsonClearSearch, object: nil)
  }
}

#if os(macOS)
  struct _PlatformWebView: NSViewRepresentable {
    let jsonString: String
    let searchText: String
    let isSearching: Bool

    func makeNSView(context: Context) -> WKWebView {
      let config = WKWebViewConfiguration()
      config.userContentController.add(context.coordinator, name: "jsonClick")

      let webView = WKWebView(
        frame: .zero,
        configuration: config
      )
      webView.navigationDelegate = context.coordinator
      webView.setValue(false, forKey: "drawsBackground")

      if let htmlURL = Bundle.main.url(
        forResource: "jsonviewer",
        withExtension: "html"
      ) {
        webView.loadFileURL(
          htmlURL,
          allowingReadAccessTo: htmlURL.deletingLastPathComponent()
        )
      }

      context.coordinator.webView = webView
      context.coordinator.pendingJSON = jsonString
      context.coordinator.setupNotificationObservers()

      return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
      // 当jsonString改变时更新JSON内容
      if context.coordinator.pendingJSON != jsonString {
        context.coordinator.pendingJSON = jsonString
        if !jsonString.isEmpty {
          injectJSON(to: nsView, jsonString: jsonString)
        }
      }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
      weak var webView: WKWebView?
      var pendingJSON: String?

      func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let json = pendingJSON {
          injectJSON(to: webView, jsonString: json)
          pendingJSON = nil
        }
      }

      func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
      ) {
        if message.name == "jsonClick" {
          print("点击节点返回：\(message.body)")
        }
      }
      
      func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(expandAll),
          name: .jsonExpandAll,
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(collapseAll),
          name: .jsonCollapseAll,
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(searchJSON(_:)),
          name: .jsonSearch,
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(clearSearch),
          name: .jsonClearSearch,
          object: nil
        )
      }
      
      @objc private func expandAll() {
        webView?.evaluateJavaScript("expandAll()") { result, error in
          if let error = error {
            print("展开所有节点失败: \(error)")
          }
        }
      }
      
      @objc private func collapseAll() {
        webView?.evaluateJavaScript("collapseAll()") { result, error in
          if let error = error {
            print("收起所有节点失败: \(error)")
          }
        }
      }
      
      @objc private func searchJSON(_ notification: Notification) {
        guard let query = notification.userInfo?["query"] as? String else { return }
        let escapedQuery = query.replacingOccurrences(of: "'", with: "\\'")
        webView?.evaluateJavaScript("searchJSON('\(escapedQuery)')") { result, error in
          if let error = error {
            print("搜索失败: \(error)")
          }
        }
      }
      
      @objc private func clearSearch() {
        webView?.evaluateJavaScript("clearSearch()") { result, error in
          if let error = error {
            print("清除搜索失败: \(error)")
          }
        }
      }
      
      deinit {
        NotificationCenter.default.removeObserver(self)
      }
    }
  }
#else
  struct _PlatformWebView: UIViewRepresentable {
    let jsonString: String
    let searchText: String
    let isSearching: Bool

    func makeUIView(context: Context) -> WKWebView {
      let config = WKWebViewConfiguration()
      config.userContentController.add(context.coordinator, name: "jsonClick")

      let webView = WKWebView(frame: .zero, configuration: config)
      webView.scrollView.bounces = false
      webView.navigationDelegate = context.coordinator

      if let htmlURL = Bundle.main.url(
        forResource: "jsonviewer",
        withExtension: "html"
      ) {
        webView.loadFileURL(
          htmlURL,
          allowingReadAccessTo: htmlURL.deletingLastPathComponent()
        )
      }

      context.coordinator.webView = webView
      context.coordinator.pendingJSON = jsonString
      return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
      // 当jsonString改变时更新JSON内容
      if context.coordinator.pendingJSON != jsonString {
        context.coordinator.pendingJSON = jsonString
        if !jsonString.isEmpty {
          injectJSON(to: uiView, jsonString: jsonString)
        }
      }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
      weak var webView: WKWebView?
      var pendingJSON: String?

      func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let json = pendingJSON {
          injectJSON(to: webView, jsonString: json)
          pendingJSON = nil
        }
      }

      func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
      ) {
        if message.name == "jsonClick" {
          print("点击节点返回：\(message.body)")
        }
      }
    }
  }
#endif

// MARK: - 注入 JSON
private func injectJSON(to webView: WKWebView, jsonString: String) {
  guard !jsonString.isEmpty else {
    // 清空编辑器
    let js = "editor.set({})"
    webView.evaluateJavaScript(js) { result, error in
      if let error = error {
        print("JavaScript执行错误: \(error)")
      }
    }
    return
  }

  guard let data = jsonString.data(using: .utf8),
    let obj = try? JSONSerialization.jsonObject(with: data)
  else {
    print("⚠️ JSON 格式错误，无法解析")
    // 显示错误信息
    let errorJS = "editor.set({\"error\": \"Invalid JSON format\"})"
    webView.evaluateJavaScript(errorJS) { result, error in
      if let error = error {
        print("JavaScript执行错误: \(error)")
      }
    }
    return
  }

  // 将JSON对象转换为JavaScript可以理解的格式
  do {
    let jsonData = try JSONSerialization.data(withJSONObject: obj, options: [])
    if let jsonStr = String(data: jsonData, encoding: .utf8) {
      let js = "setJSON(\(jsonStr))"
      webView.evaluateJavaScript(js) { result, error in
        if let error = error {
          print("JavaScript执行错误: \(error)")
        }
      }
    }
  } catch {
    print("JSON序列化错误: \(error)")
  }
}
