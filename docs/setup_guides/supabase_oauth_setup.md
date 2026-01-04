# Supabase OAuth 配置指南 (Google & GitHub)

本指南将帮助你在 Supabase 后台配置 Google 和 GitHub 第三方登录。

---

## 前置条件

- 已有 Supabase 项目
- Google Cloud 账户（用于 Google 登录）
- GitHub 账户（用于 GitHub 登录）

---

## 第一步：配置 Google OAuth

### 1.1 创建 Google Cloud OAuth 客户端

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 选择你的项目（或创建新项目）
3. 导航至 **APIs & Services → Credentials**
4. 点击 **Create Credentials → OAuth client ID**
5. 选择 **iOS** 应用类型
6. 填写配置：
   - **Name**: MEALgorithm iOS
   - **Bundle ID**: `Yuan-Tech.MEALgorithmiOS`（与你的 Xcode Bundle Identifier 匹配）
7. 点击 **Create**
8. 复制 **Client ID**

### 1.2 在 Supabase 启用 Google Provider

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择你的项目
3. 导航至 **Authentication → Providers**
4. 找到 **Google** 并点击启用
5. 填入：
   - **Client ID**: 从 Google Cloud Console 复制的 Client ID
   - **Client Secret**: 从 Google Cloud Console 复制的 Client Secret
6. 复制 **Callback URL**（格式如 `https://xxx.supabase.co/auth/v1/callback`）
7. 回到 Google Cloud Console，将此 Callback URL 添加到 **Authorized redirect URIs**
8. 保存配置

---

## 第二步：配置 GitHub OAuth

### 2.1 创建 GitHub OAuth App

1. 访问 [GitHub Developer Settings](https://github.com/settings/developers)
2. 点击 **New OAuth App**
3. 填写配置：
   - **Application name**: MEALgorithm
   - **Homepage URL**: 你的应用主页（如 `https://yourdomain.com`）
   - **Authorization callback URL**: 从 Supabase 复制的 Callback URL
4. 点击 **Register application**
5. 复制 **Client ID**
6. 点击 **Generate a new client secret**，复制 **Client Secret**

### 2.2 在 Supabase 启用 GitHub Provider

1. 回到 Supabase Dashboard → **Authentication → Providers**
2. 找到 **GitHub** 并点击启用
3. 填入 Client ID 和 Client Secret
4. 保存配置

---

## 第三步：配置 Supabase Redirect URL

确保 Supabase 接受你的 iOS 应用回调 URL：

1. 在 Supabase Dashboard 导航至 **Authentication → URL Configuration**
2. 在 **Redirect URLs** 中添加：
   ```
   mealgorithm://auth/callback
   ```
3. 保存

---

## 第四步：验证 iOS 配置

确保你的 iOS 项目已正确配置：

### 4.1 URL Scheme（已在 Info.plist 中配置）

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mealgorithm</string>
        </array>
    </dict>
</array>
```

### 4.2 检查 Supabase URL

确保你的 `Secrets.xcconfig` 或环境变量中包含正确的 Supabase URL 和 Key。

---

## 常见问题排查

### 问题 1：OAuth 页面显示 "redirect_uri_mismatch"

**原因**: Supabase 的 Redirect URL 配置不包含你的 iOS 应用 URL Scheme。

**解决**: 在 Supabase Dashboard → Authentication → URL Configuration 中添加 `mealgorithm://auth/callback`

### 问题 2：登录成功但应用未收到回调

**原因**: iOS URL Scheme 配置错误。

**解决**: 
- 检查 Info.plist 中的 `CFBundleURLSchemes` 是否为 `mealgorithm`
- 检查代码中的 redirect URL 是否匹配

### 问题 3：Google 登录显示 "Error 400: invalid_request"

**原因**: Google OAuth 客户端 Bundle ID 与实际 iOS Bundle ID 不匹配。

**解决**: 在 Google Cloud Console 中确保 Bundle ID 与 Xcode 中的 Bundle Identifier 完全一致。

---

## 架构说明

### OAuth 登录流程

```
┌─────────────┐     ┌───────────────────┐     ┌──────────────┐
│  iOS App    │────▶│ ASWebAuthSession  │────▶│  Supabase    │
│ OAuthButton │     │ (系统浏览器窗口)    │     │  OAuth URL   │
└─────────────┘     └───────────────────┘     └──────────────┘
                                                    │
                                                    ▼
┌─────────────┐     ┌───────────────────┐     ┌──────────────┐
│  iOS App    │◀────│ URL Scheme 回调    │◀────│ Google/GitHub│
│ handleOAuth │     │mealgorithm://...  │     │   登录页面    │
└─────────────┘     └───────────────────┘     └──────────────┘
```

### 关键文件

| 文件 | 职责 |
|------|------|
| `AuthService.swift` | 调用 Supabase API 生成 OAuth URL，处理回调 |
| `AuthViewModel.swift` | 管理 OAuth 状态，触发认证流程 |
| `LoginView.swift` | 渲染 Google/GitHub 登录按钮，显示认证窗口 |
| `MEALgorithmApp.swift` | 通过 `onOpenURL` 接收 OAuth 回调 |

---

## 参考链接

- [Supabase Auth with Swift](https://supabase.com/docs/guides/auth/native-mobile-deep-linking?platform=swift)
- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios/start)
- [GitHub OAuth Apps](https://docs.github.com/en/developers/apps/building-oauth-apps)
