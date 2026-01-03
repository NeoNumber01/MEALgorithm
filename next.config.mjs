/** @type {import('next').NextConfig} */
const nextConfig = {
    output: 'standalone',
    // Use relative path for outputFileTracingRoot to reduce hardcoded absolute paths
    // This helps make the Electron build more portable when moved to different locations
    experimental: {
        outputFileTracingRoot: process.cwd(),
    },
};

export default nextConfig;
