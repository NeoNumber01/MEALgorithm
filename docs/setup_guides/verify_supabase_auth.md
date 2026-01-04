# Supabase 认证配置检查指南 (Supabase Auth Config Check)

虽然我们刚才修复了本地的 URL 错误，但为了确保修复后能顺利登录，请按照以下步骤检查 Supabase 后台配置。

**核心概念澄清**: 
Supabase 的登录功能是**内置服务** (Built-in Service)，不需要你上传代码去开启。只需要在后台"打开开关"即可。

## 1. 检查 Authentication (认证) 开关
1. 打开浏览器访问 [Supabase Dashboard](https://supabase.com/dashboard/project/_/auth/providers)。
2. 进入你的项目 -> 左侧菜单点击 **Authentication** 图标 (像个文件夹或锁)。
3. 点击 **Providers** (提供商)。
4. 找到 **Email** 选项。
   - 确保 **Enable Email provider** 是 **开启 (Enabled)** 状态。
   - **Confirm email**: 如果开启了此项，用户注册后必须去邮箱点链接才能登录。**开发阶段建议先关闭 (Disable)**，这样注册完直接就能登录，方便测试。

## 2. 检查 Database (数据库) 权限
如果是存取用户数据失败，可能涉及 RLS (Row Level Security)。
1. 点击左侧 **Table Editor**。
2. 查看 `profiles` 或其他表。
3. 确保 RLS 策略允许 `SELECT` / `INSERT`。
   - (如果是刚开始开发，且遇到 permission denied，可以暂时 disable RLS 测试，但生产环境必须开启)。

## 3. 下一步
回到 Xcode，运行 App。
- 如果 URL 修复成功，且配置正确，应该能注册/登录。
- 如果报错 `400 Bad Request` 或 `User not found`，说明已经连通服务器，只是参数或账号问题。
