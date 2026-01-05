# 🔐 Security & Setup Guide

This document covers security best practices and complete local development setup for MEALgorithm.

---

## 📋 Table of Contents

1. [Security Architecture](#-security-architecture)
2. [Prerequisites](#-prerequisites)
3. [Local Development Setup](#-local-development-setup)
4. [Database Configuration](#-database-configuration)
5. [Edge Functions Deployment](#-edge-functions-deployment)
6. [Environment Variables](#-environment-variables)
7. [Key Security Practices](#-key-security-practices)
8. [Troubleshooting](#-troubleshooting)

---

## 🏰 Security Architecture

MEALgorithm implements a **defense-in-depth** security model:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client (Browser)                         │
│  • Only has access to NEXT_PUBLIC_* env variables               │
│  • GEMINI_API_KEY is NEVER exposed here                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (JWT Token in Authorization header)
┌─────────────────────────────────────────────────────────────────┐
│                    Next.js Server Actions                       │
│  • Validates user session                                       │
│  • Forwards requests to Edge Functions                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Supabase Edge Functions (Deno)                  │
│  • Verifies JWT internally (even with --no-verify-jwt)          │
│  • Has access to GEMINI_API_KEY via secrets                     │
│  • All AI API calls happen here                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase PostgreSQL                          │
│  • Row Level Security (RLS) enforced on all tables              │
│  • Users can only access their own data                         │
└─────────────────────────────────────────────────────────────────┘
```

### Key Security Features

| Feature | Implementation |
|---------|----------------|
| **API Key Protection** | GEMINI_API_KEY stored only in Edge Function secrets |
| **Row Level Security** | All tables have RLS policies enforcing user isolation |
| **OAuth Authentication** | Google/GitHub OAuth - no password storage |
| **JWT Verification** | Edge Functions verify tokens before processing |
| **CORS Whitelist** | Edge Functions only accept requests from trusted origins |

---

## 📦 Prerequisites

Before starting, ensure you have:

- **Node.js 18+** - [Download](https://nodejs.org/)
- **npm** or **pnpm** - Comes with Node.js
- **Supabase CLI** - Install globally:
  ```bash
  npm install -g supabase
  ```
- **Git** - [Download](https://git-scm.com/)

### Required Accounts

| Service | Purpose | Sign Up |
|---------|---------|---------|
| **Supabase** | Database, Auth, Edge Functions | [supabase.com](https://supabase.com/) |
| **Google AI Studio** | Gemini API Key | [ai.google.dev](https://ai.google.dev/) |

---

## 🚀 Local Development Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/NeoNumber01/MEALgorithm.git
cd MEALgorithm
```

### Step 2: Install Dependencies

```bash
npm install
```

### Step 3: Create Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Click **"New Project"**
3. Fill in:
   - **Name**: `mealgorithm` (or your preferred name)
   - **Database Password**: Generate a strong password (save it securely)
   - **Region**: Choose the closest to your users
4. Wait for the project to initialize (~2 minutes)

### Step 4: Get Your Supabase Credentials

1. In your Supabase project, go to **Settings → API**
2. Note down these values:
   - **Project URL**: `https://<project-id>.supabase.co`
   - **anon public key**: `sb_publishable_...` or `eyJ...` format

### Step 5: Get Your Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Click **"Create API Key"**
3. Copy the generated key (starts with `AIza...`)

---

## 🗄️ Database Configuration

### Run Database Migrations

MEALgorithm requires three migration files to set up the database schema.

#### Option A: Using Supabase Dashboard (Recommended for beginners)

1. Go to **SQL Editor** in your Supabase project
2. Copy and paste each migration file content in order:

**Migration 1: Initial Schema** (`supabase/migrations/20240101000000_init_schema.sql`)
```sql
-- Creates: profiles, meals, food_catalog tables
-- Enables: RLS policies for user data isolation
-- Sets up: Auto-profile creation trigger on user signup
```

**Migration 2: Profile Stats** (`supabase/migrations/20240102000000_add_profile_stats.sql`)
```sql
-- Adds: Cache columns to profiles table
-- Includes: food_preferences, food_dislikes, dietary_restrictions
-- Adds: Recommendation cache columns
```

**Migration 3: Remove Image Storage** (`supabase/migrations/20240103000000_remove_image_storage.sql`)
```sql
-- Removes: image_path dependency (images are processed but not stored)
```

3. Execute each migration in order

#### Option B: Using Supabase CLI

```bash
# Link to your project
supabase login
supabase link --project-ref <your-project-id>

# Push all migrations
supabase db push
```

### Configure OAuth Providers (Optional but Recommended)

1. Go to **Authentication → Providers** in Supabase Dashboard
2. Enable **Google** and/or **GitHub**:

#### Google OAuth Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Google+ API**
4. Create **OAuth 2.0 credentials**
5. Add authorized redirect URI: `https://<project-id>.supabase.co/auth/v1/callback`
6. Copy Client ID and Secret to Supabase

#### GitHub OAuth Setup
1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create a new OAuth App
3. Set Authorization callback URL: `https://<project-id>.supabase.co/auth/v1/callback`
4. Copy Client ID and Secret to Supabase

---

## ⚡ Edge Functions Deployment

### Step 1: Link Local Project to Supabase

```bash
supabase login
supabase link --project-ref <your-project-id>
```

Replace `<your-project-id>` with the ID from your project URL (e.g., `abcdefghijklmnop` from `https://abcdefghijklmnop.supabase.co`).

### Step 2: Set Edge Function Secrets

```bash
supabase secrets set GEMINI_API_KEY=<your-gemini-api-key>
```

**⚠️ Important**: This is the ONLY place where your Gemini API key should be stored. Never put it in `.env.local` or commit it to version control.

### Step 3: Deploy All Edge Functions

```bash
# Deploy meal analysis function
supabase functions deploy analyze-meal --no-verify-jwt

# Deploy recommendations/coach function
supabase functions deploy generate-suggestions --no-verify-jwt

# Deploy general AI function
supabase functions deploy ai-generate --no-verify-jwt
```

**Note**: `--no-verify-jwt` is required because the functions handle JWT verification internally. This allows more flexible error handling while maintaining security.

### Verify Deployment

```bash
supabase functions list
```

You should see all three functions listed with status `Active`.

---

## 🔑 Environment Variables

### Create `.env.local`

In the project root, create a file named `.env.local`:

```env
# ============================================
# Supabase Configuration
# ============================================
NEXT_PUBLIC_SUPABASE_URL=https://<project-id>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_xxx

# ============================================
# Gemini API Key - DO NOT ADD HERE!
# ============================================
# The GEMINI_API_KEY is configured in Edge Functions via:
#   supabase secrets set GEMINI_API_KEY=your_key
#
# This ensures your API key is never exposed to the frontend.
```

### Environment Variable Reference

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Public | ✅ | Your Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public | ✅ | Supabase anonymous key (safe for client) |
| `GEMINI_API_KEY` | Secret | ✅ | Set via `supabase secrets set` ONLY |

---

## 🛡️ Key Security Practices

### ✅ DO

- ✅ Store `.env.local` locally only - never commit it
- ✅ Use `supabase secrets set` for sensitive API keys
- ✅ Enable RLS on all database tables
- ✅ Use OAuth providers instead of email/password
- ✅ Verify JWT tokens in Edge Functions
- ✅ Rotate API keys periodically
- ✅ Use different credentials for dev/staging/production

### ❌ DON'T

- ❌ Hardcode API keys in source code
- ❌ Put `GEMINI_API_KEY` in `.env.local`
- ❌ Commit `.env.local` to version control
- ❌ Share credentials in public channels
- ❌ Disable RLS policies
- ❌ Use `service_role` key in client-side code

---

## � Running the Application

### Development Mode

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Production Build

```bash
npm run build
npm run start
```

### Desktop App (Electron)

```bash
# Development
npm run electron:dev

# Build distributable
npm run electron:dist
```

---

## 🚨 If Keys Are Leaked

### Gemini API Key

1. Immediately go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Delete the compromised key
3. Create a new key
4. Update Edge Function secrets:
   ```bash
   supabase secrets set GEMINI_API_KEY=<new-key>
   ```

### Supabase Keys

1. Go to **Settings → API** in Supabase Dashboard
2. Click **"Regenerate"** for the compromised key
3. Update all applications using that key

### Git History Cleanup

If keys were committed to Git:

```bash
# Using BFG Repo-Cleaner (recommended)
bfg --replace-text passwords.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Or using filter-branch
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env.local' \
  --prune-empty --tag-name-filter cat -- --all
```

---

## ❓ Troubleshooting

### Edge Function Returns 401 Unauthorized

**Cause**: JWT token not being passed correctly.

**Solution**: Ensure `getSession()` is called before Edge Function requests:
```typescript
const { data: { session } } = await supabase.auth.getSession()
const response = await fetch(url, {
  headers: {
    'Authorization': `Bearer ${session.access_token}`
  }
})
```

### "AI service not configured" Error

**Cause**: `GEMINI_API_KEY` not set in Edge Functions.

**Solution**:
```bash
supabase secrets set GEMINI_API_KEY=your_key
supabase functions deploy <function-name> --no-verify-jwt
```

### Database RLS Blocking Queries

**Cause**: Queries failing due to RLS policies.

**Solution**: Ensure user is authenticated and `auth.uid()` matches `user_id`:
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';

-- Verify policy exists
SELECT * FROM pg_policies WHERE tablename = 'meals';
```

### OAuth Callback Errors

**Cause**: Redirect URI mismatch.

**Solution**: Ensure callback URL is exactly:
```
https://<project-id>.supabase.co/auth/v1/callback
```

---

## 📞 Need Help?

- [Supabase Documentation](https://supabase.com/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Google AI Documentation](https://ai.google.dev/docs)
- [Supabase Discord](https://discord.supabase.com/)

---

<p align="center">
  <strong>Stay Secure! 🔒</strong>
</p>
