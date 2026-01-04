# supabase 认证配置手把手指南 (Google, Apple, GitHub, Email)

这篇文档将手把手教您如何找到并配置所有第三方登录所需的 ID 和 Secret。

**核心前提：**
在开始之前，请先去 [Supabase Dashboard](https://supabase.com/dashboard) -> `Project Settings` -> `API`，找到您的 **Project URL** (例如: `https://euungrfqqnmgfhkptlpb.supabase.co`)。
你需要用到它来拼接 **Redirect URL (回调地址)**：
`https://euungrfqqnmgfhkptlpb.supabase.co/auth/v1/callback`

---

## 1. 📧 Email / Password (基础邮箱登录)
**位置**: Supabase Dashboard -> Authentication -> Sign In / Providers -> Email

*   **配置**: 
    *   **Enable Email Provider**: 开启 ✅
    *   **Confirm Email**: 开启此项后，用户注册必须点邮件里的链接才能登录。**测试阶段建议先关闭**，以免收不到邮件导致无法登录。
    *   **Secure Password Change**: 建议开启。

---

## 2. 🐙 GitHub 登录配置
**难度**: ⭐ (最简单)

1.  登录 [GitHub Developer Settings](https://github.com/settings/developers)。
2.  点击 **"New OAuth App"**。
3.  **填写信息**:
    *   **Application Name**: MEALgorithmiOS (或者您喜欢的名字)
    *   **Homepage URL**: `https://euungrfqqnmgfhkptlpb.supabase.co`
    *   **Authorization callback URL**: `https://euungrfqqnmgfhkptlpb.supabase.co/auth/v1/callback` (**关键步骤，必须填对**)
4.  点击 **Register application**。
5.  **获取 Key**:
    *   **Client ID**: 直接复制页面上显示的 `Client ID`。
    *   **Client Secret**: 点击 "Generate a new client secret"，复制生成的字符串。
6.  **回到 Supabase**:
    *   填入 `Client ID` 和 `Client Secret`。
    *   开启 `Enable GitHub`。
    *   保存。

---

## 3. 🔵 Google 登录配置
**难度**: ⭐⭐

1.  登录 [Google Cloud Console](https://console.cloud.google.com/)。
2.  创建一个新项目 (New Project)，或者选现有项目。
3.  **配置 OAuth Consent Screen (同意屏幕)**:
    *   左侧菜单 -> `APIs & Services` -> `OAuth consent screen`。
    *   User Type 选 **External**。
    *   填写 App Name (MEALgorithm)，Support Email。
    *   保存并继续。
4.  **创建凭证 (Credentials)**:
    *   左侧菜单 -> `Credentials` -> `+ Create Credentials` -> **OAuth client ID**。
    *   Application type 选 **Web application** (注意：虽然是iOS App，但我们通过Supabase网页认证，所以选Web)。
    *   **Authorized redirect URIs**: 添加 `https://euungrfqqnmgfhkptlpb.supabase.co/auth/v1/callback`。
5.  **获取 Key**:
    *   创建后会弹窗显示 **Client ID** 和 **Client Secret**。
6.  **iOS 特别配置 (Google 必须)**:
    *   Google 要求 iOS App 还需要要在 URL Schemes 里加一个反转的 Client ID。
    *   复制 Client ID (例如 `123456...apps.googleusercontent.com`)。
    *   去 Xcode -> Info -> URL Types -> 粘贴到 URL Schemes (如果有需要的话，目前我们的 Supabase 方案由 Supabase 托管 Web 登录，这一步通常由 Supabase 处理，但为了以防万一可以记下)。
7.  **回到 Supabase**:
    *   填入 Client ID, Client Secret。
    *   开启 `Enable Google`。

---

## 4. 🍎 Apple 登录配置 (iOS 必须)
**难度**: ⭐⭐⭐⭐⭐ (最繁琐，且必须要有 Apple Developer 账号，每年99刀那个)

**重要**：如果不开启 Apple 登录，App Store 会拒绝您的 App 上架，因为您使用了其他第三方登录。

1.  登录 [Apple Developer Portal](https://developer.apple.com/account)。
2.  **创建 App ID**:
    *   Certificates, Identifiers & Profiles -> Identifiers -> App IDs。
    *   确保您的 App ID (Bundle ID `Yuan-Tech.MEALgorithmiOS`) 勾选了 **Sign In with Apple**.
3.  **创建 Service ID** (Supabase 需要这个):
    *   Identifiers -> 右上角加号 -> 选 **Service IDs**。
    *   Identifier: `com.yuan-tech.mealgorithm.signin` (示例，不能和 Bundle ID 相同)。
    *   Description: MEALgorithm Sign In.
    *   注册后，点击刚创建的 Service ID 进入编辑 -> 勾选 **Sign In with Apple** -> 点击它旁边的 Configure。
    *   **Domains and Subdomains**: 填入 `euungrfqqnmgfhkptlpb.supabase.co` (去掉 https://)。
    *   **Return URLs**: 填入 `https://euungrfqqnmgfhkptlpb.supabase.co/auth/v1/callback`。
    *   保存。
4.  **创建 Key (密钥)**:
    *   左侧 Keys -> 加号。
    *   Key Name: Supabase Auth Key.
    *   勾选 **Sign In with Apple** -> Configure -> 选择您的 **Primary App ID**。
    *   下载 `.p8` 文件 (只能下载一次！保存好)。
    *   记下 **Key ID**。
5.  **回到 Supabase**:
    *   **Client ID**: 填如第 3 步创建的 **Service ID** (不是 Bundle ID)。
    *   **Services ID**: 同上。
    *   **Team ID**: 您开发者账号的 Team ID (右上角能看到)。
    *   **Key ID**: 第 4 步记下的 Key ID。
    *   **Private Key**: 用文本编辑器打开下载的 `.p8` 文件，复制全部内容粘贴进去。
    *   开启 `Enable Apple`。

---

## 5. 最后一步：iOS URL Scheme 配置
为了让 Safari 登录完能自动跳回 App，您要在 Supabase 允许这个跳转。

1.  **Supabase 后台**:
    *   Authentication -> URL Configuration -> **Redirect URLs**。
    *   添加：`mealgorithm://auth/callback` (这是您 App 的 Scheme)。

配置完成后，请重新运行 App 测试。
建议先从 **GitHub** 开始，因为它最简单，可以验证流程通不通。
