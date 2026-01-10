/**
 * Food Classification API Route
 * POST /api/classify-food
 */

import { NextRequest, NextResponse } from 'next/server';
import { classifyImage, initializeFoodClassifier } from '@/lib/classifier';
import path from 'path';

// Environment detection: Vercel sets VERCEL=1 in production
const IS_VERCEL = process.env.VERCEL === '1';

let modelWarmedUp = false;
let warmupError: string | null = null;

// Skip model warmup on Vercel (classifier will use fail-open mode)
const warmupPromise = IS_VERCEL
    ? Promise.resolve().then(() => {
        modelWarmedUp = true;
        console.log('[API/classify-food] Running on Vercel - classifier in fail-open mode');
    })
    : initializeFoodClassifier({
        modelPath: path.join(process.cwd(), 'models', 'mobilenet_v2.onnx'),
        debug: process.env.NODE_ENV === 'development',
    }).then(() => {
        modelWarmedUp = true;
        console.log('[API/classify-food] Model warmed up and ready');
    }).catch((err) => {
        warmupError = err.message;
        console.error('[API/classify-food] Model warmup failed:', err);
    });

export async function POST(request: NextRequest) {
    const startTime = performance.now();

    try {
        if (!modelWarmedUp) {
            await warmupPromise;
            if (warmupError) {
                throw new Error(`Model not available: ${warmupError}`);
            }
        }

        const { image, threshold = 0.3 } = await request.json();

        if (!image) {
            return NextResponse.json({ error: 'Missing image data' }, { status: 400 });
        }

        const result = await classifyImage(image, {
            threshold: Math.max(0, Math.min(1, Number(threshold))),
            debug: process.env.NODE_ENV === 'development',
        });

        return NextResponse.json({
            isFood: result.isFood,
            confidence: Number(result.confidence.toFixed(4)),
            processingTimeMs: Number((performance.now() - startTime).toFixed(2)),
            detectedClass: result.detectedClass,
        });
    } catch (error) {
        const errMsg = error instanceof Error ? error.message : 'Unknown error';
        console.error('[API/classify-food] Error:', errMsg);

        return NextResponse.json({
            isFood: true, // Fail-open
            confidence: 0,
            processingTimeMs: performance.now() - startTime,
            error: errMsg,
            failOpen: true,
        });
    }
}

export async function GET() {
    return NextResponse.json({
        status: modelWarmedUp ? 'ready' : (warmupError ? 'error' : 'loading'),
        error: warmupError,
        usage: 'POST { image: base64, threshold?: 0-1 }',
    });
}
