/**
 * Download MobileNetV2 ONNX Model
 * 
 * Run: npx ts-node scripts/download-model.ts
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const MODEL_URL = 'https://github.com/onnx/models/raw/main/validated/vision/classification/mobilenet/model/mobilenetv2-12.onnx';
const MODEL_PATH = path.join(process.cwd(), 'models', 'mobilenet_v2.onnx');

async function downloadFile(url: string, dest: string): Promise<void> {
    return new Promise((resolve, reject) => {
        const dir = path.dirname(dest);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }

        console.log(`📥 Downloading from: ${url}`);

        const file = fs.createWriteStream(dest);

        const request = (currentUrl: string) => {
            https.get(currentUrl, (response: any) => {
                // Handle redirect
                if (response.statusCode === 301 || response.statusCode === 302) {
                    const redirectUrl = response.headers.location;
                    console.log(`↪️ Redirecting to: ${redirectUrl.substring(0, 80)}...`);
                    request(redirectUrl);
                    return;
                }

                if (response.statusCode !== 200) {
                    reject(new Error(`HTTP ${response.statusCode}`));
                    return;
                }

                const total = parseInt(response.headers['content-length'] || '0', 10);
                let downloaded = 0;

                response.on('data', (chunk: Buffer) => {
                    downloaded += chunk.length;
                    if (total > 0) {
                        const pct = ((downloaded / total) * 100).toFixed(1);
                        process.stdout.write(`\r📊 Progress: ${pct}% (${(downloaded / 1024 / 1024).toFixed(2)} MB)`);
                    }
                });

                response.pipe(file);

                file.on('finish', () => {
                    file.close();
                    console.log('\n✅ Download complete!');
                    resolve();
                });
            }).on('error', reject);
        };

        request(url);
    });
}

async function main() {
    console.log('🚀 Downloading MobileNetV2 ONNX Model\n');

    if (fs.existsSync(MODEL_PATH)) {
        const stats = fs.statSync(MODEL_PATH);
        console.log(`✅ Model already exists: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
        return;
    }

    try {
        await downloadFile(MODEL_URL, MODEL_PATH);
        const stats = fs.statSync(MODEL_PATH);
        console.log(`✅ Model saved: ${MODEL_PATH}`);
        console.log(`   Size: ${(stats.size / 1024 / 1024).toFixed(2)} MB`);
    } catch (error) {
        console.error('❌ Download failed:', (error as Error).message);
        console.log('\n📝 Manual download instructions:');
        console.log('1. Go to: https://github.com/onnx/models/tree/main/validated/vision/classification/mobilenet');
        console.log('2. Download mobilenetv2-12.onnx');
        console.log('3. Save to: models/mobilenet_v2.onnx');
        process.exit(1);
    }
}

main();
