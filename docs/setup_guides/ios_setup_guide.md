# MEALgorithm iOS 客户端设置指南

## 前置要求

- **Xcode 16.0+** (支持 iOS 17+)
- **Xcode 16.5+** (如需 iOS 26 Liquid Glass 功能)
- **macOS 15.0+** (Sequoia)

## 快速开始

### 1. 打开项目

项目已完全配置好，直接在 Xcode 中打开：

```
/Users/y.h/MEALgorithm/MEALgorithmiOS/MEALgorithmiOS.xcodeproj
```

### 2. 构建并运行

按 **⌘ + R** 运行应用。

---

## 已完成的配置

以下配置**已自动完成**，无需手动操作：

| 配置项 | 状态 |
|--------|------|
| Swift Package 依赖 (Supabase, Gemini AI) | ✅ 已添加 |
| API 密钥 (Build Settings) | ✅ 已配置 |
| Info.plist (权限声明) | ✅ 已创建 |
| 相机/相册权限 | ✅ 已声明 |

### API 密钥位置

API 密钥通过 Build Settings 注入到 Info.plist：

| 变量 | 位置 |
|------|------|
| `SUPABASE_URL` | Project → Target → Build Settings |
| `SUPABASE_ANON_KEY` | Project → Target → Build Settings |
| `GEMINI_API_KEY` | Project → Target → Build Settings |

代码通过 `Bundle.main.infoDictionary` 读取这些值。

---

## iOS 26 Liquid Glass

本项目实现了自动兼容：

```swift
if #available(iOS 26, *) {
    content.glassEffect(.regular)  // 原生 Liquid Glass
} else {
    content.background(.ultraThinMaterial)  // 回退效果
}
```

详见 `Utilities/LiquidGlassModifier.swift`。

---

## 项目结构

```
MEALgorithmiOS/
├── App/           # 应用入口
├── Models/        # 数据模型 (Profile, Meal, Recommendation)
├── Services/      # 业务服务 (Supabase, Gemini, Auth)
├── ViewModels/    # 视图模型 (MVVM)
├── Views/         # SwiftUI 视图
├── Utilities/     # 扩展和工具
└── Config/        # 配置文件 (Secrets.xcconfig)
```

---

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| 找不到模块 'Supabase' | ⇧⌘K 清理后重新构建 |
| 崩溃 "Missing SUPABASE_URL" | 检查 Build Settings 中的变量 |
| iOS 26 效果没有显示 | 需要 Xcode 16.5+ 和 iOS 26 Beta |
| Package 解析失败 | File → Packages → Reset Package Caches |
