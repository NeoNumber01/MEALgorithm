# 🔐 安全配置指南 / Security Configuration Guide

## ⚠️ 重要安全提醒 / Important Security Notice

**永远不要在代码中硬编码 API 密钥！**  
**Never hardcode API keys in your code!**

---

## 📋 配置步骤 / Setup Steps

### 1. 创建本地环境文件 / Create Local Environment File

复制示例文件并填入您的真实密钥：
```bash
cp .env.example .env.local
```

### 2. 获取 API 密钥 / Get API Keys

#### Supabase 密钥
1. 访问 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择您的项目 → Settings → API
3. 复制以下值：
   - `Project URL` → `NEXT_PUBLIC_SUPABASE_URL`
   - `anon public` key → `NEXT_PUBLIC_SUPABASE_ANON_KEY`

#### Gemini AI 密钥
1. 访问 [Google AI Studio](https://aistudio.google.com/apikey)
2. 创建新的 API 密钥
3. 复制到 `GEMINI_API_KEY`

### 3. 配置 .env.local 文件

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOi...your-key...
GEMINI_API_KEY=AIzaSy...your-key...
```

---

## 🛡️ 安全最佳实践 / Security Best Practices

### ✅ 应该做的 / DO

- ✅ 使用 `.env.local` 存储敏感信息
- ✅ 确保 `.env.local` 在 `.gitignore` 中
- ✅ 使用不同的密钥用于开发和生产环境
- ✅ 定期轮换 API 密钥
- ✅ 在 Supabase 中设置行级安全策略 (RLS)

### ❌ 不应该做的 / DON'T

- ❌ 在代码中硬编码 API 密钥
- ❌ 将 `.env.local` 提交到版本控制
- ❌ 在公开仓库中分享密钥
- ❌ 在客户端代码中使用服务端密钥
- ❌ 将构建产物 (`dist-electron/`) 提交到版本控制

---

## 🔑 密钥说明 / Key Descriptions

| 密钥 | 类型 | 说明 |
|------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | 公开 | Supabase 项目 URL，可安全暴露在客户端 |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | 公开 | Supabase 匿名公钥，配合 RLS 使用是安全的 |
| `GEMINI_API_KEY` | **敏感** | Google AI API 密钥，仅在服务端使用 |

---

## 🚨 如果密钥泄露 / If Keys Are Leaked

如果您不小心泄露了密钥：

1. **Gemini API Key**: 
   - 立即在 [Google AI Studio](https://aistudio.google.com/apikey) 删除旧密钥
   - 创建新密钥并更新 `.env.local`

2. **Supabase Keys**:
   - 在 Supabase Dashboard → Settings → API 重新生成密钥
   - 更新所有使用该密钥的应用

3. **检查泄露范围**:
   - 检查 Git 历史记录
   - 使用 `git filter-branch` 或 BFG Repo-Cleaner 清理历史

---

## 📦 打包发布 / Distribution

当打包 Electron 应用分发时：

1. 构建产物不再包含真实的 API 密钥
2. 用户需要自行配置 `.env.local` 文件
3. 或者考虑使用后端代理来保护敏感 API 密钥

---

## 📞 需要帮助？ / Need Help?

- [Supabase 文档](https://supabase.com/docs)
- [Google AI 文档](https://ai.google.dev/docs)
- [Next.js 环境变量](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)
