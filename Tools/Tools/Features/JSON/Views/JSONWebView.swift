import SwiftUI
import WebKit

struct JSONWebView: View {
  let jsonString: String

  var body: some View {
    _PlatformWebView(jsonString: jsonString)
      .edgesIgnoringSafeArea(.all)
      .id(jsonString) // 当jsonString改变时重新创建视图
  }
}

#if os(macOS)
  struct _PlatformWebView: NSViewRepresentable {
    let jsonString: String

    func makeNSView(context: Context) -> WKWebView {
      let config = WKWebViewConfiguration()
      config.userContentController.add(context.coordinator, name: "jsonClick")

      let webView = WKWebView(
        frame: .zero,
        configuration: config
      )
      webView.navigationDelegate = context.coordinator
      webView.setValue(false, forKey: "drawsBackground")

      //      webView.load(URLRequest(url: URL(string: "https://www.baidu.com")!))
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
    }
  }
#else
  struct _PlatformWebView: UIViewRepresentable {
    let jsonString: String

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
