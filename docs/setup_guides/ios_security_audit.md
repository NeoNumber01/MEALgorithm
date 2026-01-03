# iOS Security & Secrets Management Guide

## 1. The Golden Rule
**NEVER commit API Keys, Service Role Keys, or Passwords to Git.**
Even if a repo is private now, it might be public later / shared with contractors.

## 2. Status of Audit
We have performed a deep scan of the codebase:
- ✅ **Gemini API Key (`AIza...`)**: CRITICAL. Was exposed, now **SCRUBBED** from history.
- ✅ **Supabase Service Role Key**: CRITICAL. Not found (Good).
- ⚠️ **Supabase Anon Key**: FOUND in `project.pbxproj`.
  - *Context*: This key is technically "public" and safe to be in client apps (it respects Row Level Security policies).
  - *Recommendation*: Move to `Secrets.xcconfig` for consistency, but it is **NOT a fatal security risk**.

## 3. How to Setup Secrets locally
Since we removed hardcoded keys, the app will crash if you don't provide them.

### Method A: Environment Variables (Scheme) [Recommended for Solo Dev]
1. In Xcode, go to **Product > Scheme > Edit Scheme**.
2. Select **Run** (on the left) > **Arguments** tab.
3. Under **Environment Variables**, add:
   - `GEMINI_API_KEY` = `your_new_key_here`
   - `SUPABASE_URL` = `...`
   - `SUPABASE_ANON_KEY` = `...`
4. **Important**: Ensure the "Shared" checkbox for the Scheme is **UNCHECKED** if you commit the `.xcscheme` file.

### Method B: Secrets.xcconfig [Recommended for Teams]
1. Create a file named `Secrets.xcconfig` in the project root.
2. Add your keys:
   ```xcconfig
   GEMINI_API_KEY = AIza...
   SUPABASE_URL = https://...
   SUPABASE_ANON_KEY = ...
   ```
3. **Verify** that `Secrets.xcconfig` is in `.gitignore` (It is!).
4. Is Xcode, go to Project > Info > Configurations. Set the configuration file to `Secrets`.
5. In `Info.plist`, use `$(GEMINI_API_KEY)`.

## 4. Emergency Plan (If Leak Happens Again)
1. **Revoke Immediately**: Go to Google Cloud / Supabase / OpenAI dashboard and delete the key.
2. **Scrub History**: Do not just delete the file and commit. Use `git filter-repo` or `git commit --amend` (for immediate last commit) to rewrite history.
3. **Rotate**: Generate new keys.
