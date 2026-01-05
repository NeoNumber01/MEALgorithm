/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',
    eslint: {
        // Allow production builds to complete even if there are ESLint errors
        ignoreDuringBuilds: true,
    },
    // Use relative path for outputFileTracingRoot to reduce hardcoded absolute paths
    // This helps make the Electron build more portable when moved to different locations
    experimental: {
        outputFileTracingRoot: process.cwd(),
        // Mark native Node.js modules as external (not bundled by webpack)
        serverComponentsExternalPackages: ['onnxruntime-node', 'sharp'],
    },
};

export default nextConfig;
