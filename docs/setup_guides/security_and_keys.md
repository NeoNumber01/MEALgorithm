# Security & API Key Setup Guide

## 1. Overview
MEALgorithm uses sensitive API keys (e.g., Google Gemini AI) that **must never be committed to git**. We use a combination of Xcode Configuration (`.xcconfig`) files and `.gitignore` to keep these secrets safe.

## 2. Setting Up Local Keys
To run the app locally, you need to provide your own API keys.

1.  **Navigate to the Config Directory**:
    Go to `MEALgorithm/MEALgorithmiOS/MEALgorithmiOS/Config/`.

2.  **Create Secrets File**:
    Copy `Secrets-Example.xcconfig` and rename it to `Secrets.xcconfig`.
    ```bash
    cp Secrets-Example.xcconfig Secrets.xcconfig
    ```

3.  **Add Your Key**:
    Open `Secrets.xcconfig` and paste your Gemini API key:
    ```xcconfig
    GEMINI_API_KEY = ai...your_actual_key...
    ```

4.  **Verify Git Ignore**:
    Run `git status` to ensure `Secrets.xcconfig` is **NOT** being tracked. It should be ignored automatically.

## 3. Best Practices
-   **Never force add** ignored config files.
-   **Never paste keys** directly into Swift code.
-   **Use Environment Variables** for CI/CD pipelines.

## 4. Troubleshooting
If you see "GEMINI_API_KEY not found" crash:
- Check if `Secrets.xcconfig` exists.
- Check if the key inside it is correct.
- Clean the build folder (Product -> Clean Build Folder) and rebuild.
