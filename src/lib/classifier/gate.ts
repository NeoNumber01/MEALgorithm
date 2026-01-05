/**
 * Food Detection Gate - High-level API for filtering before AI calls
 */

import {
    classifyImage,
    initializeFoodClassifier,
    type ClassifierConfig,
    type ClassificationResult,
} from './food-classifier';

export interface GateConfig extends Partial<ClassifierConfig> {
    threshold?: number;
    verbose?: boolean;
}

export interface GateCheckResult {
    shouldProceed: boolean;
    foodConfidence: number;
    processingTimeMs: number;
    rejectionReason?: string;
}

export interface FoodGate {
    check: (image: Buffer | string) => Promise<GateCheckResult>;
    warmup: () => Promise<void>;
    getConfig: () => GateConfig;
}

export function createFoodGate(config: GateConfig = {}): FoodGate {
    const gateConfig: GateConfig = {
        threshold: 0.6,
        verbose: false,
        ...config,
    };

    const check = async (image: Buffer | string): Promise<GateCheckResult> => {
        const startTime = performance.now();

        try {
            const result: ClassificationResult = await classifyImage(image, {
                threshold: gateConfig.threshold,
                debug: gateConfig.verbose,
            });

            const processingTimeMs = performance.now() - startTime;

            if (!result.isFood) {
                return {
                    shouldProceed: false,
                    foodConfidence: 1 - result.confidence,
                    processingTimeMs,
                    rejectionReason: `Image classified as non-food (${((1 - result.confidence) * 100).toFixed(1)}%)`,
                };
            }

            return {
                shouldProceed: true,
                foodConfidence: result.confidence,
                processingTimeMs,
            };
        } catch (error) {
            const processingTimeMs = performance.now() - startTime;
            const message = error instanceof Error ? error.message : String(error);

            // Fail-open: allow through on error
            return {
                shouldProceed: true,
                foodConfidence: 0,
                processingTimeMs,
                rejectionReason: `Classification error: ${message}`,
            };
        }
    };

    const warmup = async (): Promise<void> => {
        await initializeFoodClassifier({
            threshold: gateConfig.threshold,
            debug: gateConfig.verbose,
        });
    };

    const getConfig = (): GateConfig => ({ ...gateConfig });

    return { check, warmup, getConfig };
}

let defaultGate: FoodGate | null = null;

export function getDefaultGate(): FoodGate {
    if (!defaultGate) {
        defaultGate = createFoodGate({
            threshold: 0.6,
            verbose: process.env.NODE_ENV === 'development',
        });
    }
    return defaultGate;
}

export async function quickFoodCheck(image: Buffer | string): Promise<GateCheckResult> {
    return getDefaultGate().check(image);
}
