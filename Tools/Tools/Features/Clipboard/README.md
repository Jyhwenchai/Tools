# 粘贴板管理器使用指南

## 功能概述
粘贴板管理器是一个智能的剪贴板历史记录工具，能够自动监控和保存你复制的内容，支持文本、链接和代码的智能分类和管理。

## 主要功能特性

### 1. 自动监控与记录
- **自动启动监控**：打开功能后会自动开始监控系统剪贴板
- **实时保存**：每次复制内容时自动保存到历史记录
- **智能去重**：相同内容不会重复保存，会将最新的移到顶部
- **容量限制**：默认保存最近100条记录，超出后自动删除最旧的记录

### 2. 智能内容分类
系统会自动识别复制内容的类型：

- **📄 文本**：普通文字内容
- **🔗 链接**：自动识别URL链接，支持点击打开
- **⚡ 代码**：识别编程代码，支持语法高亮显示

### 3. 界面布局与操作

**主界面结构：**
- **左侧边栏**：历史记录和统计信息切换
- **顶部工具栏**：监控控制、清空历史等操作
- **搜索过滤栏**：内容搜索和类型筛选
- **内容列表**：显示所有历史记录

## 具体使用方法

### 启动和控制监控
1. **开始监控**：点击"开始监控"按钮，系统开始记录剪贴板变化
2. **暂停监控**：点击"暂停监控"可临时停止记录
3. **状态指示**：绿色表示正在监控，橙色表示已暂停

### 搜索和筛选
1. **内容搜索**：在搜索框输入关键词快速查找历史记录
2. **类型筛选**：点击"类型"下拉菜单，选择特定类型（文本/链接/代码）
3. **清除筛选**：点击搜索框的×按钮或选择"全部类型"

### 内容操作
**对于每条记录，你可以：**
1. **快速复制**：鼠标悬停时点击复制图标，或右键选择"复制"
2. **删除记录**：点击垃圾桶图标或右键选择"删除"
3. **展开/收起**：长内容会自动截断，点击"展开全部"查看完整内容
4. **链接操作**：URL类型支持直接点击打开，或右键"在浏览器中打开"

### 代码内容特殊功能
- **语言识别**：自动识别Swift、JavaScript、Python、Java等编程语言
- **语法高亮**：代码内容会有颜色区分（准备支持完整语法高亮）
- **行号显示**：多行代码展开时显示行号
- **水平滚动**：长代码行支持水平滚动查看

### 统计信息查看
切换到"统计信息"标签页可以看到：
- 总记录数量
- 各类型内容的数量分布
- 最早和最新记录的时间
- 当前监控状态

## 隐私和安全特性
- **本地存储**：所有数据仅保存在本地，不会上传到网络
- **安全清理**：支持一键清空所有历史记录
- **敏感数据处理**：内置安全服务会对输入内容进行清理
- **权限最小化**：不需要额外的系统权限

## 使用建议
1. **保持监控开启**：建议始终开启监控以获得最佳体验
2. **定期清理**：根据需要定期清空历史记录释放存储空间
3. **善用搜索**：利用搜索功能快速找到需要的历史内容
4. **类型筛选**：处理特定类型内容时使用类型筛选提高效率

## 技术实现

### 架构设计
- **MVVM模式**：采用SwiftUI + SwiftData的现代架构
- **模块化设计**：Models、Services、Views分离
- **响应式编程**：使用@Observable进行状态管理

### 核心组件
- `ClipboardService`：核心业务逻辑和剪贴板监控
- `ClipboardItem`：数据模型，支持SwiftData持久化
- `ClipboardView`：主界面视图
- `ClipboardManagerView`：管理界面，包含侧边栏导航
- `ClipboardItemRow`：单个记录的显示组件

### 数据存储
- 使用SwiftData进行本地数据持久化
- 支持自动数据迁移和版本管理
- 内存中维护最近记录的缓存以提高性能

### 安全特性
- 集成SecurityService进行内容清理
- 支持敏感数据自动清除
- 监控状态可通过通知中心控制

---

*此文档对应代码版本：当前开发版本*
*最后更新时间：2025年1月*