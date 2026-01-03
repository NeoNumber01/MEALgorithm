const { app, BrowserWindow, shell, ipcMain, Menu } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const net = require('net');
const fs = require('fs');

let mainWindow;
let nextProcess;

const isDev = process.env.NODE_ENV === 'development';
const DEFAULT_PORT = Number(process.env.PORT) || 3000;
let selectedPort = DEFAULT_PORT;

// Load environment variables from .env.local for packaged app
function loadEnvFile(envPath) {
    if (fs.existsSync(envPath)) {
        const envContent = fs.readFileSync(envPath, 'utf8');
        const lines = envContent.split('\n');
        const envVars = {};
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed && !trimmed.startsWith('#')) {
                const [key, ...valueParts] = trimmed.split('=');
                if (key && valueParts.length > 0) {
                    envVars[key.trim()] = valueParts.join('=').trim();
                }
            }
        }
        return envVars;
    }
    return {};
}

// GPU Configuration for better compatibility when app is moved to different locations
// The GPU cache can become invalid when the app path changes, causing GPU process crashes.
// Solution: Clear problematic GPU cache on startup and configure GPU settings properly.

/**
 * Clear GPU-related caches that can cause crashes when the app is moved to a different location.
 * This must be called before app.ready event.
 */
function clearGPUCache() {
    try {
        const userDataPath = app.getPath('userData');
        const cacheDirs = ['GPUCache', 'DawnGraphiteCache', 'DawnWebGPUCache', 'Code Cache'];

        for (const dir of cacheDirs) {
            const cachePath = path.join(userDataPath, dir);
            if (fs.existsSync(cachePath)) {
                fs.rmSync(cachePath, { recursive: true, force: true });
                console.log(`Cleared cache: ${dir}`);
            }
        }
    } catch (error) {
        console.error('Failed to clear GPU cache:', error.message);
    }
}

// Clear GPU cache before app is ready to prevent crashes when app is moved
clearGPUCache();

// GPU settings for maximum compatibility while keeping hardware acceleration enabled
app.commandLine.appendSwitch('ignore-gpu-blocklist');
app.commandLine.appendSwitch('disable-gpu-sandbox');
app.commandLine.appendSwitch('no-sandbox');

// Enable GPU acceleration features
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-accelerated-2d-canvas');

// Use ANGLE with D3D11 for better compatibility on Windows
app.commandLine.appendSwitch('use-angle', 'd3d11');

function isPortFree(port) {
    return new Promise((resolve) => {
        const tester = net.createServer()
            .once('error', () => resolve(false))
            .once('listening', () => {
                tester.close(() => resolve(true));
            })
            .listen(port, '127.0.0.1');
    });
}

async function pickPort(preferredPort) {
    // Try a small range to avoid EADDRINUSE from previous runs.
    const portsToTry = [preferredPort, preferredPort + 1, preferredPort + 2, preferredPort + 3, preferredPort + 4];
    for (const port of portsToTry) {
        // eslint-disable-next-line no-await-in-loop
        if (await isPortFree(port)) return port;
    }
    return preferredPort;
}

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        frame: true,
        autoHideMenuBar: true,  // Hide menu bar by default
        backgroundColor: '#ffffff',  // Prevent flash during fullscreen transition
        show: false,  // Don't show until ready
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js'),
        },
        icon: path.join(__dirname, '../public/images/MEAL_icon.ico'),
    });

    // Remove the menu bar completely
    Menu.setApplicationMenu(null);

    // Show window when ready to prevent flash
    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
    });

    // Listen for fullscreen state changes and notify renderer
    mainWindow.on('enter-full-screen', () => {
        mainWindow.webContents.send('fullscreen-change', true);
    });

    mainWindow.on('leave-full-screen', () => {
        mainWindow.webContents.send('fullscreen-change', false);
    });

    const url = isDev
        ? `http://localhost:${selectedPort}`
        : `http://localhost:${selectedPort}`;

    mainWindow.loadURL(url);

    // Allow popup windows for OAuth (Google/GitHub login popups)
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        // Allow all popup windows - OAuth providers may use popups
        return {
            action: 'allow',
            overrideBrowserWindowOptions: {
                width: 500,
                height: 700,
                webPreferences: {
                    nodeIntegration: false,
                    contextIsolation: true,
                }
            }
        };
    });

    if (isDev) {
        mainWindow.webContents.openDevTools();
    }

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

function startNextServer() {
    return new Promise((resolve, reject) => {
        // In packaged app, the standalone files are in resources/app
        const appPath = app.isPackaged
            ? path.join(process.resourcesPath, 'app')
            : path.join(__dirname, '..');

        // Standalone server.js location
        const serverPath = app.isPackaged
            ? path.join(appPath, 'server.js')  // In packaged app, server.js is at root of app
            : path.join(appPath, '.next', 'standalone', 'server.js');

        const serverCwd = app.isPackaged
            ? appPath
            : path.join(appPath, '.next', 'standalone');

        console.log('Starting Next.js standalone server...');
        console.log('App path:', appPath);
        console.log('Server path:', serverPath);
        console.log('Server CWD:', serverCwd);

        // Load environment variables from .env.local
        const envFilePath = path.join(serverCwd, '.env.local');
        const loadedEnv = loadEnvFile(envFilePath);
        console.log('Loaded env vars from:', envFilePath);
        console.log('Env vars loaded:', Object.keys(loadedEnv).length);

        // Use node to run the standalone server - no shell to handle paths with spaces
        const nodeExecutable = app.isPackaged ? process.execPath : 'node';
        const env = {
            ...process.env,
            ...loadedEnv,  // Include loaded environment variables
            PORT: selectedPort.toString(),
            HOSTNAME: 'localhost',
        };

        if (app.isPackaged) {
            env.ELECTRON_RUN_AS_NODE = '1';
        }

        nextProcess = spawn(nodeExecutable, [serverPath], {
            cwd: serverCwd,
            env,
            shell: false,
            stdio: ['pipe', 'pipe', 'pipe'],
        });

        nextProcess.stdout.on('data', (data) => {
            console.log(`Next.js: ${data}`);
            const output = data.toString();
            if (output.includes('Ready') || output.includes('started') || output.includes(selectedPort.toString()) || output.includes('Listening')) {
                resolve();
            }
        });

        nextProcess.stderr.on('data', (data) => {
            console.error(`Next.js Error: ${data}`);
        });

        nextProcess.on('error', (error) => {
            console.error('Failed to start Next.js:', error);
            reject(error);
        });

        // Resolve after timeout as fallback
        setTimeout(() => {
            console.log('Next.js startup timeout - proceeding anyway');
            resolve();
        }, 8000);
    });
}

// IPC handlers for fullscreen control
ipcMain.handle('toggle-fullscreen', () => {
    if (mainWindow) {
        const isFullScreen = mainWindow.isFullScreen();
        mainWindow.setFullScreen(!isFullScreen);
        return !isFullScreen;
    }
    return false;
});

ipcMain.handle('exit-fullscreen', () => {
    if (mainWindow && mainWindow.isFullScreen()) {
        mainWindow.setFullScreen(false);
        return true;
    }
    return false;
});

ipcMain.handle('get-fullscreen-state', () => {
    if (mainWindow) {
        return mainWindow.isFullScreen();
    }
    return false;
});

// Handle GPU process crash - clear cache and log for debugging
app.on('gpu-process-crashed', (event, killed) => {
    console.error('GPU process crashed, killed:', killed);
    console.log('Clearing GPU cache to prevent future crashes...');
    clearGPUCache();
});

// Handle child process gone (includes GPU process)
app.on('child-process-gone', (event, details) => {
    if (details.type === 'GPU') {
        console.error('GPU process gone:', details.reason);
        console.log('Clearing GPU cache...');
        clearGPUCache();
    }
});

app.whenReady().then(async () => {
    selectedPort = await pickPort(DEFAULT_PORT);
    if (!isDev) {
        await startNextServer();
    }
    createWindow();
});

app.on('window-all-closed', () => {
    if (nextProcess) {
        try {
            // On Windows, we need to kill the process tree
            if (process.platform === 'win32') {
                spawn('taskkill', ['/pid', nextProcess.pid.toString(), '/f', '/t'], { shell: true });
            } else {
                nextProcess.kill('SIGTERM');
            }
        } catch (e) {
            console.error('Error killing Next.js process:', e);
        }
    }
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});

app.on('before-quit', () => {
    if (nextProcess) {
        try {
            if (process.platform === 'win32') {
                spawn('taskkill', ['/pid', nextProcess.pid.toString(), '/f', '/t'], { shell: true });
            } else {
                nextProcess.kill('SIGTERM');
            }
        } catch (e) {
            console.error('Error killing Next.js process:', e);
        }
    }
});
