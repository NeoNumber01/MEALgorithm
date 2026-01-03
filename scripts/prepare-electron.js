const fs = require('fs');
const path = require('path');

/**
 * Prepare Next.js standalone build for Electron packaging
 * This script copies static assets to the correct locations for standalone server
 */

const projectRoot = path.join(__dirname, '..');
const nextDir = path.join(projectRoot, '.next');
const standaloneDir = path.join(nextDir, 'standalone');

function copyRecursiveSync(src, dest) {
    const exists = fs.existsSync(src);
    const stats = exists && fs.statSync(src);
    const isDirectory = exists && stats.isDirectory();

    if (isDirectory) {
        if (!fs.existsSync(dest)) {
            fs.mkdirSync(dest, { recursive: true });
        }
        fs.readdirSync(src).forEach(childItemName => {
            copyRecursiveSync(
                path.join(src, childItemName),
                path.join(dest, childItemName)
            );
        });
    } else {
        try {
            fs.copyFileSync(src, dest);
        } catch (err) {
            console.error(`Error copying file from ${src} to ${dest}:`, err);
            throw err;
        }
    }
}

function fixServerJs() {
    const serverJsPath = path.join(standaloneDir, 'server.js');

    if (fs.existsSync(serverJsPath)) {
        console.log('Fixing server.js hardcoded paths...');
        let content = fs.readFileSync(serverJsPath, 'utf8');

        // Get the absolute project root path in various formats
        const absoluteRoot = path.resolve(projectRoot);

        // 1. Replace outputFileTracingRoot with empty string (use current directory)
        content = content.replace(
            /"outputFileTracingRoot":"[^"]+"/g,
            '"outputFileTracingRoot":""'
        );

        // 2. Replace Windows-style escaped paths (\\)
        const escapedWinPath = absoluteRoot.replace(/\\/g, '\\\\');
        content = content.replace(new RegExp(escapeRegExp(escapedWinPath), 'g'), '.');

        // 3. Replace forward-slash paths
        const forwardSlashPath = absoluteRoot.replace(/\\/g, '/');
        content = content.replace(new RegExp(escapeRegExp(forwardSlashPath), 'g'), '.');

        // 4. Replace raw Windows paths
        content = content.replace(new RegExp(escapeRegExp(absoluteRoot), 'g'), '.');

        // 5. Fix all paths in .next/server directory (includes chunks, app, and all subdirectories)
        const serverDir = path.join(standaloneDir, '.next', 'server');
        if (fs.existsSync(serverDir)) {
            console.log('Fixing hardcoded paths in server files...');
            fixPathsInDirectory(serverDir, absoluteRoot);
        }

        fs.writeFileSync(serverJsPath, content, 'utf8');
        console.log('  ✓ server.js patched');
    }
}

// Helper function to escape special regex characters
function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Helper function to fix paths in all JS files in a directory
function fixPathsInDirectory(dir, absoluteRoot) {
    const files = fs.readdirSync(dir);

    for (const file of files) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
            fixPathsInDirectory(filePath, absoluteRoot);
        } else if (file.endsWith('.js')) {
            let content = fs.readFileSync(filePath, 'utf8');
            let modified = false;

            // Replace various path formats
            const escapedWinPath = absoluteRoot.replace(/\\/g, '\\\\');
            const forwardSlashPath = absoluteRoot.replace(/\\/g, '/');

            // Also handle URL-encoded paths (for metadata routes)
            const urlEncodedPath = encodeURIComponent(absoluteRoot).replace(/%/g, '%');
            const urlEncodedWinPath = absoluteRoot.replace(/\\/g, '%5C').replace(/:/g, '%3A').replace(/ /g, '%20');

            if (content.includes(escapedWinPath) ||
                content.includes(forwardSlashPath) ||
                content.includes(absoluteRoot) ||
                content.includes(urlEncodedPath) ||
                content.includes(urlEncodedWinPath)) {

                content = content.replace(new RegExp(escapeRegExp(escapedWinPath), 'g'), '.');
                content = content.replace(new RegExp(escapeRegExp(forwardSlashPath), 'g'), '.');
                content = content.replace(new RegExp(escapeRegExp(absoluteRoot), 'g'), '.');
                content = content.replace(new RegExp(escapeRegExp(urlEncodedPath), 'g'), '.');
                content = content.replace(new RegExp(escapeRegExp(urlEncodedWinPath), 'g'), '.');
                modified = true;
            }

            if (modified) {
                fs.writeFileSync(filePath, content, 'utf8');
                console.log(`  ✓ Fixed paths in: ${path.relative(standaloneDir, filePath)}`);
            }
        }
    }
}

/**
 * Fix hardcoded absolute paths in required-server-files.json
 * This JSON file contains paths that Next.js uses at runtime to locate server files.
 * When the app is moved to a different location, these paths become invalid.
 */
function fixRequiredServerFiles() {
    const requiredFilesPath = path.join(standaloneDir, '.next', 'required-server-files.json');

    if (!fs.existsSync(requiredFilesPath)) {
        console.log('⚠ required-server-files.json not found, skipping...');
        return;
    }

    console.log('Fixing required-server-files.json...');

    try {
        // Read and parse the JSON file
        const content = fs.readFileSync(requiredFilesPath, 'utf8');
        const json = JSON.parse(content);

        let modified = false;

        // Fix config.experimental.outputFileTracingRoot
        if (json.config?.experimental?.outputFileTracingRoot) {
            console.log('  - Original outputFileTracingRoot:', json.config.experimental.outputFileTracingRoot);
            json.config.experimental.outputFileTracingRoot = '';
            modified = true;
        }

        // Fix appDir - set to relative path
        if (json.appDir) {
            console.log('  - Original appDir:', json.appDir);
            json.appDir = '.';
            modified = true;
        }

        // Also fix any other potential absolute path fields
        const absoluteRoot = path.resolve(projectRoot);
        const escapedWinPath = absoluteRoot.replace(/\\/g, '\\\\');
        const forwardSlashPath = absoluteRoot.replace(/\\/g, '/');

        // Convert to string and replace any remaining absolute paths
        let jsonString = JSON.stringify(json, null, 2);

        if (jsonString.includes(escapedWinPath) ||
            jsonString.includes(forwardSlashPath) ||
            jsonString.includes(absoluteRoot)) {
            jsonString = jsonString.replace(new RegExp(escapeRegExp(escapedWinPath), 'g'), '.');
            jsonString = jsonString.replace(new RegExp(escapeRegExp(forwardSlashPath), 'g'), '.');
            jsonString = jsonString.replace(new RegExp(escapeRegExp(absoluteRoot), 'g'), '.');
            modified = true;
        }

        if (modified) {
            fs.writeFileSync(requiredFilesPath, jsonString, 'utf8');
            console.log('  ✓ required-server-files.json patched successfully');
        } else {
            console.log('  ✓ required-server-files.json already clean, no changes needed');
        }

    } catch (error) {
        console.error('  ✗ Failed to fix required-server-files.json:', error.message);
    }
}

function prepareStandalone() {
    console.log('Preparing Next.js standalone for Electron...');

    // Check if standalone build exists
    if (!fs.existsSync(standaloneDir)) {
        console.error('Error: Standalone build not found. Run "npm run build" first.');
        process.exit(1);
    }

    // 1. Copy .next/static to .next/standalone/.next/static
    const staticSrc = path.join(nextDir, 'static');
    const staticDest = path.join(standaloneDir, '.next', 'static');

    if (fs.existsSync(staticSrc)) {
        console.log('Copying static files...');
        console.log(`  From: ${staticSrc}`);
        console.log(`  To: ${staticDest}`);
        copyRecursiveSync(staticSrc, staticDest);
        console.log('  ✓ Static files copied');
    } else {
        console.warn('Warning: .next/static not found');
    }

    // 2. Copy public folder to .next/standalone/public
    const publicSrc = path.join(projectRoot, 'public');
    const publicDest = path.join(standaloneDir, 'public');

    if (fs.existsSync(publicSrc)) {
        console.log('Copying public files...');
        console.log(`  From: ${publicSrc}`);
        console.log(`  To: ${publicDest}`);
        copyRecursiveSync(publicSrc, publicDest);
        console.log('  ✓ Public files copied');
    } else {
        console.warn('Warning: public folder not found');
    }

    // 3. Create a placeholder .env.local that prompts users to configure their own keys
    // SECURITY: We no longer copy actual API keys to the build output
    const envDest = path.join(standaloneDir, '.env.local');

    // Create a template .env.local that tells users to set up their own keys
    const envTemplate = `# MEALgorithm Environment Configuration
# =====================================
# SECURITY WARNING: You must configure your own API keys!
# 
# Copy this file and fill in your actual values.
# Never commit your actual API keys to version control.
#
# Get Supabase keys from: https://supabase.com/dashboard/project/_/settings/api
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL_HERE
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE

# Get Gemini API key from: https://aistudio.google.com/apikey
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
`;

    console.log('Creating placeholder .env.local...');
    console.log(`  To: ${envDest}`);
    fs.writeFileSync(envDest, envTemplate, 'utf8');
    console.log('  ✓ Placeholder .env.local created');
    console.log('  ⚠ IMPORTANT: Users must configure their own API keys before running the app!');

    // 4. Fix hardcoded paths in server.js and server chunks
    fixServerJs();

    // 5. Fix hardcoded paths in required-server-files.json
    fixRequiredServerFiles();

    console.log('\n✓ Standalone preparation complete!');
}

prepareStandalone();
