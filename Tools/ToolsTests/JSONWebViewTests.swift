//
//  JSONWebViewTests.swift
//  ToolsTests
//
//  Created by Kiro on 2025/7/23.
//

import Testing
import SwiftUI
@testable import Tools

struct JSONWebViewTests {
  
  @Test("JSONWebView 初始化测试")
  func jSONWebViewInitialization() {
    let jsonString = #"{"name":"John","age":30}"#
    let webView = JSONWebView(jsonString: jsonString)
    
    // 验证JSONWebView可以正常初始化
    #expect(webView.jsonString == jsonString)
  }
  
  @Test("通知名称定义测试")
  func notificationNamesDefinition() {
    // 验证所有通知名称都已正确定义
    #expect(Notification.Name.jsonExpandAll.rawValue == "jsonExpandAll")
    #expect(Notification.Name.jsonCollapseAll.rawValue == "jsonCollapseAll")
    #expect(Notification.Name.jsonSearch.rawValue == "jsonSearch")
    #expect(Notification.Name.jsonClearSearch.rawValue == "jsonClearSearch")
  }
  
  @Test("通知发送测试")
  func notificationPosting() {
    var receivedNotifications: [String] = []
    
    // 设置通知观察者
    let expandObserver = NotificationCenter.default.addObserver(
      forName: .jsonExpandAll,
      object: nil,
      queue: .main
    ) { _ in
      receivedNotifications.append("expandAll")
    }
    
    let collapseObserver = NotificationCenter.default.addObserver(
      forName: .jsonCollapseAll,
      object: nil,
      queue: .main
    ) { _ in
      receivedNotifications.append("collapseAll")
    }
    
    let searchObserver = NotificationCenter.default.addObserver(
      forName: .jsonSearch,
      object: nil,
      queue: .main
    ) { notification in
      if let query = notification.userInfo?["query"] as? String {
        receivedNotifications.append("search:\(query)")
      }
    }
    
    let clearSearchObserver = NotificationCenter.default.addObserver(
      forName: .jsonClearSearch,
      object: nil,
      queue: .main
    ) { _ in
      receivedNotifications.append("clearSearch")
    }
    
    // 发送通知
    NotificationCenter.default.post(name: .jsonExpandAll, object: nil)
    NotificationCenter.default.post(name: .jsonCollapseAll, object: nil)
    NotificationCenter.default.post(
      name: .jsonSearch,
      object: nil,
      userInfo: ["query": "test"]
    )
    NotificationCenter.default.post(name: .jsonClearSearch, object: nil)
    
    // 等待通知处理
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
    
    // 验证通知已接收
    #expect(receivedNotifications.contains("expandAll"))
    #expect(receivedNotifications.contains("collapseAll"))
    #expect(receivedNotifications.contains("search:test"))
    #expect(receivedNotifications.contains("clearSearch"))
    
    // 清理观察者
    NotificationCenter.default.removeObserver(expandObserver)
    NotificationCenter.default.removeObserver(collapseObserver)
    NotificationCenter.default.removeObserver(searchObserver)
    NotificationCenter.default.removeObserver(clearSearchObserver)
  }
  
  @Test("空JSON字符串处理测试")
  func emptyJSONStringHandling() {
    let webView = JSONWebView(jsonString: "")
    
    // 验证空字符串不会导致崩溃
    #expect(webView.jsonString.isEmpty)
  }
  
  @Test("无效JSON字符串处理测试")
  func invalidJSONStringHandling() {
    let invalidJSON = #"{"name": "John", "age":}"#
    let webView = JSONWebView(jsonString: invalidJSON)
    
    // 验证无效JSON不会导致崩溃
    #expect(webView.jsonString == invalidJSON)
  }
  
  @Test("复杂JSON字符串处理测试")
  func complexJSONStringHandling() {
    let complexJSON = """
    {
      "users": [
        {
          "name": "John",
          "age": 30,
          "details": {
            "email": "john@example.com",
            "active": true,
            "preferences": {
              "theme": "dark",
              "notifications": true
            }
          }
        },
        {
          "name": "Jane",
          "age": 25,
          "details": {
            "email": "jane@example.com",
            "active": false,
            "preferences": {
              "theme": "light",
              "notifications": false
            }
          }
        }
      ],
      "metadata": {
        "total": 2,
        "page": 1,
        "timestamp": "2025-07-23T10:00:00Z"
      }
    }
    """
    
    let webView = JSONWebView(jsonString: complexJSON)
    
    // 验证复杂JSON可以正常处理
    #expect(webView.jsonString == complexJSON)
  }
}