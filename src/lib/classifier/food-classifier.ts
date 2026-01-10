/**
 * Ultra-Fast Food / Non-Food Image Classifier
 * 
 * Uses MobileNetV2 with ImageNet classes to detect food.
 * Design: < 10ms inference, zero external API calls.
 * 
 * NOTE: This classifier is disabled on Vercel deployments due to
 * serverless function size limits. In that case, it returns isFood: true
 * (fail-open behavior) to allow all images through.
 */

// Environment detection: Vercel sets VERCEL=1 in production
const IS_VERCEL = process.env.VERCEL === '1';
const CLASSIFIER_ENABLED = !IS_VERCEL;

// Conditional import: only load onnxruntime-node when not on Vercel
let ort: typeof import('onnxruntime-node') | null = null;
if (CLASSIFIER_ENABLED) {
    try {
        ort = require('onnxruntime-node');
    } catch (e) {
        console.warn('[FoodClassifier] onnxruntime-node not available, classifier disabled');
    }
}
import sharp from 'sharp';
import path from 'path';
import { IMAGENET_FOOD_CLASSES, getFoodClassName } from './food-classes';

// ============================================================================
// Types
// ============================================================================

export interface ClassifierConfig {
    threshold: number;
    modelPath: string;
    inputSize: number;
    debug: boolean;
}

export interface ClassificationResult {
    isFood: boolean;
    confidence: number;
    inferenceTimeMs: number;
    detectedClass?: string;
    topClass?: number;
}

export interface PreprocessedImage {
    data: Float32Array;
    originalDimensions: { width: number; height: number };
}

// ============================================================================
// Configuration
// ============================================================================

const DEFAULT_CONFIG: ClassifierConfig = {
    threshold: 0.15, // Low threshold - we want to be lenient (fail-open)
    modelPath: path.join(process.cwd(), 'models', 'mobilenet_v2.onnx'),
    inputSize: 224,
    debug: false,
};

// MobileNetV2 ImageNet normalization
const IMAGENET_MEAN = [0.485, 0.456, 0.406];
const IMAGENET_STD = [0.229, 0.224, 0.225];

// ============================================================================
// Singleton Model Manager
// ============================================================================

class FoodClassifierModel {
    private static instance: FoodClassifierModel | null = null;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    private session: any = null;
    private config: ClassifierConfig;
    private isLoading = false;
    private loadPromise: Promise<void> | null = null;

    private constructor(config: Partial<ClassifierConfig> = {}) {
        this.config = { ...DEFAULT_CONFIG, ...config };
    }

    static getInstance(config?: Partial<ClassifierConfig>): FoodClassifierModel {
        if (!FoodClassifierModel.instance) {
            FoodClassifierModel.instance = new FoodClassifierModel(config);
        }
        return FoodClassifierModel.instance;
    }

    static resetInstance(): void {
        if (FoodClassifierModel.instance?.session) {
            FoodClassifierModel.instance.session = null;
        }
        FoodClassifierModel.instance = null;
    }

    async loadModel(): Promise<void> {
        // Skip model loading if ort is not available (Vercel deployment)
        if (!ort) {
            if (this.config.debug) {
                console.log('[FoodClassifier] Skipping model load - onnxruntime not available (Vercel mode)');
            }
            return;
        }

        if (this.session) return;
        if (this.isLoading && this.loadPromise) return this.loadPromise;

        this.isLoading = true;
        this.loadPromise = this._loadModelInternal();

        try {
            await this.loadPromise;
        } finally {
            this.isLoading = false;
            this.loadPromise = null;
        }
    }

    private async _loadModelInternal(): Promise<void> {
        if (!ort) return;

        const startTime = performance.now();

        const sessionOptions: ort.InferenceSession.SessionOptions = {
            executionProviders: ['cpu'],
            graphOptimizationLevel: 'all',
            enableCpuMemArena: true,
            enableMemPattern: true,
            executionMode: 'sequential',
            intraOpNumThreads: 1,
        };

        try {
            this.session = await ort.InferenceSession.create(
                this.config.modelPath,
                sessionOptions
            );

            if (this.config.debug) {
                console.log(`[FoodClassifier] Model loaded in ${(performance.now() - startTime).toFixed(2)}ms`);
                console.log(`[FoodClassifier] Inputs: ${this.session.inputNames}`);
                console.log(`[FoodClassifier] Outputs: ${this.session.outputNames}`);
            }
        } catch (error) {
            throw new Error(`Failed to load model from ${this.config.modelPath}: ${(error as Error).message}`);
        }
    }

    async preprocessImage(input: Buffer | string): Promise<PreprocessedImage> {
        const imageBuffer = typeof input === 'string'
            ? Buffer.from(input, 'base64')
            : input;

        const image = sharp(imageBuffer);
        const metadata = await image.metadata();
        const originalDimensions = {
            width: metadata.width || 0,
            height: metadata.height || 0,
        };

        const { data, info } = await image
            .resize(this.config.inputSize, this.config.inputSize, {
                fit: 'cover',
                position: 'center',
            })
            .removeAlpha()
            .raw()
            .toBuffer({ resolveWithObject: true });

        const { width, height, channels } = info;
        const tensorData = new Float32Array(channels * height * width);

        // NCHW format with ImageNet normalization
        for (let c = 0; c < channels; c++) {
            const mean = IMAGENET_MEAN[c];
            const std = IMAGENET_STD[c];
            const channelOffset = c * height * width;

            for (let h = 0; h < height; h++) {
                for (let w = 0; w < width; w++) {
                    const srcIdx = (h * width + w) * channels + c;
                    const dstIdx = channelOffset + h * width + w;
                    tensorData[dstIdx] = (data[srcIdx] / 255.0 - mean) / std;
                }
            }
        }

        return { data: tensorData, originalDimensions };
    }

    async runInference(preprocessedData: Float32Array): Promise<ClassificationResult> {
        // Fail-open if ort is not available (Vercel deployment)
        if (!ort || !this.session) {
            return {
                isFood: true,
                confidence: 1,
                inferenceTimeMs: 0,
                detectedClass: 'classifier_disabled',
            };
        }

        const startTime = performance.now();

        // Create input tensor (NCHW: batch=1, channels=3, height=224, width=224)
        const inputTensor = new ort.Tensor('float32', preprocessedData, [
            1, 3, this.config.inputSize, this.config.inputSize,
        ]);

        const inputName = this.session.inputNames[0];
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const feeds: Record<string, any> = { [inputName]: inputTensor };
        const results = await this.session.run(feeds);
        const inferenceTime = performance.now() - startTime;

        const outputName = this.session.outputNames[0];
        const outputData = results[outputName].data as Float32Array;

        // Apply softmax to get probabilities
        const probs = this.softmax(outputData);

        // Find top class and check if it's food
        let maxProb = 0;
        let maxIdx = 0;
        let foodProb = 0;

        for (let i = 0; i < probs.length; i++) {
            if (probs[i] > maxProb) {
                maxProb = probs[i];
                maxIdx = i;
            }
            // Accumulate probability for all food classes
            if (IMAGENET_FOOD_CLASSES.has(i)) {
                foodProb += probs[i];
            }
        }

        const isFood = IMAGENET_FOOD_CLASSES.has(maxIdx) || foodProb > this.config.threshold;
        const detectedClass = getFoodClassName(maxIdx) || undefined;

        if (this.config.debug) {
            console.log(`[FoodClassifier] Inference: ${inferenceTime.toFixed(2)}ms`);
            console.log(`[FoodClassifier] Top class: ${maxIdx} (${(maxProb * 100).toFixed(1)}%)`);
            console.log(`[FoodClassifier] Food prob sum: ${(foodProb * 100).toFixed(1)}%`);
            console.log(`[FoodClassifier] Is food: ${isFood}`);
            if (detectedClass) {
                console.log(`[FoodClassifier] Detected: ${detectedClass}`);
            }
        }

        return {
            isFood,
            confidence: isFood ? Math.max(maxProb, foodProb) : 1 - foodProb,
            inferenceTimeMs: inferenceTime,
            detectedClass,
            topClass: maxIdx,
        };
    }

    private softmax(logits: Float32Array): number[] {
        const arr = Array.from(logits);
        const maxVal = Math.max(...arr);
        const exp = arr.map(x => Math.exp(x - maxVal));
        const sum = exp.reduce((a, b) => a + b, 0);
        return exp.map(x => x / sum);
    }

    getConfig(): ClassifierConfig { return { ...this.config }; }

    updateConfig(newConfig: Partial<ClassifierConfig>): void {
        const oldPath = this.config.modelPath;
        this.config = { ...this.config, ...newConfig };
        if (newConfig.modelPath && newConfig.modelPath !== oldPath) {
            this.session = null;
        }
    }

    isModelLoaded(): boolean { return this.session !== null; }
}

// ============================================================================
// Public API
// ============================================================================

export async function initializeFoodClassifier(
    config?: Partial<ClassifierConfig>
): Promise<void> {
    const classifier = FoodClassifierModel.getInstance(config);
    await classifier.loadModel();
}

export async function classifyImage(
    imageInput: Buffer | string,
    options?: Partial<ClassifierConfig>
): Promise<ClassificationResult> {
    const classifier = FoodClassifierModel.getInstance(options);
    await classifier.loadModel();

    if (options?.threshold !== undefined) {
        classifier.updateConfig({ threshold: options.threshold });
    }

    const preprocessed = await classifier.preprocessImage(imageInput);
    return classifier.runInference(preprocessed.data);
}

export async function classifyImages(
    images: (Buffer | string)[],
    options?: Partial<ClassifierConfig>
): Promise<ClassificationResult[]> {
    const classifier = FoodClassifierModel.getInstance(options);
    await classifier.loadModel();

    const results: ClassificationResult[] = [];
    for (const image of images) {
        const preprocessed = await classifier.preprocessImage(image);
        const result = await classifier.runInference(preprocessed.data);
        results.push(result);
    }
    return results;
}

export async function isFood(
    imageInput: Buffer | string,
    threshold = 0.3
): Promise<boolean> {
    const result = await classifyImage(imageInput, { threshold });
    return result.isFood;
}

export function getClassifierStatus(): { isLoaded: boolean; config: ClassifierConfig } {
    const classifier = FoodClassifierModel.getInstance();
    return {
        isLoaded: classifier.isModelLoaded(),
        config: classifier.getConfig(),
    };
}

export function resetClassifier(): void {
    FoodClassifierModel.resetInstance();
}
