/**
 * Food Classifier Module Exports
 */

export {
    classifyImage,
    classifyImages,
    isFood,
    initializeFoodClassifier,
    resetClassifier,
    getClassifierStatus,
    type ClassifierConfig,
    type ClassificationResult,
    type PreprocessedImage,
} from './food-classifier';

export {
    createFoodGate,
    getDefaultGate,
    quickFoodCheck,
    type FoodGate,
    type GateConfig,
    type GateCheckResult,
} from './gate';
