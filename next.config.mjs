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
    // Webpack configuration to handle onnxruntime-node on Vercel
    webpack: (config, { isServer }) => {
        if (isServer && process.env.VERCEL === '1') {
            // On Vercel, replace onnxruntime-node with an empty module
            // This prevents the large native binaries from being included
            config.resolve.alias = {
                ...config.resolve.alias,
                'onnxruntime-node': false,
            };
        }
        return config;
    },
};

export default nextConfig;

