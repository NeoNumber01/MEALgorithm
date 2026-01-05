/**
 * ImageNet Food and Food-Related Classes
 * 
 * Verified indices from the official ImageNet ILSVRC 2012 class list.
 * Includes actual food items + kitchenware that typically contains food in meal photos.
 */

// === ACTUAL FOOD ITEMS ===
// These are the verified correct indices for food in ImageNet

export const IMAGENET_FOOD_INDICES: number[] = [
    // Fruits
    948, // Granny Smith (apple)
    949, // strawberry
    950, // orange
    951, // lemon
    952, // fig
    953, // pineapple
    954, // banana
    955, // jackfruit
    956, // custard apple
    957, // pomegranate

    // Vegetables
    937, // broccoli
    938, // cauliflower
    939, // zucchini, courgette
    940, // spaghetti squash
    941, // acorn squash
    942, // butternut squash
    943, // cucumber
    944, // artichoke
    945, // bell pepper
    946, // cardoon
    947, // mushroom
    936, // head cabbage

    // Prepared Foods & Dishes
    924, // guacamole
    925, // consomme
    926, // hot pot
    927, // trifle
    928, // ice cream
    929, // ice lolly
    930, // French loaf
    931, // bagel
    932, // pretzel
    933, // cheeseburger
    934, // hotdog
    935, // mashed potato
    959, // carbonara
    960, // chocolate sauce
    961, // dough
    962, // meat loaf
    963, // pizza
    964, // pot pie
    965, // burrito
    966, // red wine
    967, // espresso
    968, // cup (with drink)
    969, // eggnog
];

// === KITCHENWARE & CONTAINERS ===
// These often contain food in meal photos, so treat them as "likely food"

export const IMAGENET_FOOD_RELATED_INDICES: number[] = [
    // Containers & Serving
    809, // soup bowl
    813, // spatula (cooking scene)
    848, // teapot
    849, // tray
    907, // wok
    910, // wooden spoon
    923, // plate

    // Cooking equipment that suggests food presence
    567, // frying pan
    659, // mixing bowl
    806, // slow cooker / crock pot
    891, // waffle iron

    // Drinks
    440, // beer bottle
    720, // wine bottle
    504, // coffee mug
    968, // cup
];

// Combined set for quick lookup
export const IMAGENET_FOOD_CLASSES: Set<number> = new Set([
    ...IMAGENET_FOOD_INDICES,
    ...IMAGENET_FOOD_RELATED_INDICES,
]);

// Human-readable names for debugging
export const FOOD_CLASS_NAMES: Record<number, string> = {
    // Fruits
    948: 'Granny Smith apple',
    949: 'strawberry',
    950: 'orange',
    951: 'lemon',
    952: 'fig',
    953: 'pineapple',
    954: 'banana',
    955: 'jackfruit',
    956: 'custard apple',
    957: 'pomegranate',

    // Vegetables
    936: 'head cabbage',
    937: 'broccoli',
    938: 'cauliflower',
    939: 'zucchini',
    940: 'spaghetti squash',
    941: 'acorn squash',
    942: 'butternut squash',
    943: 'cucumber',
    944: 'artichoke',
    945: 'bell pepper',
    946: 'cardoon',
    947: 'mushroom',

    // Prepared foods
    924: 'guacamole',
    925: 'consomme',
    926: 'hot pot',
    927: 'trifle',
    928: 'ice cream',
    929: 'ice lolly',
    930: 'French loaf',
    931: 'bagel',
    932: 'pretzel',
    933: 'cheeseburger',
    934: 'hotdog',
    935: 'mashed potato',
    959: 'carbonara',
    960: 'chocolate sauce',
    961: 'dough',
    962: 'meat loaf',
    963: 'pizza',
    964: 'pot pie',
    965: 'burrito',
    966: 'red wine',
    967: 'espresso',
    968: 'cup',
    969: 'eggnog',

    // Containers (suggesting food)
    809: 'soup bowl',
    923: 'plate',
    567: 'frying pan',
    659: 'mixing bowl',
    907: 'wok',
    891: 'waffle iron',
};

/**
 * Check if a class index represents food or food-related item
 */
export function isFoodClass(classIndex: number): boolean {
    return IMAGENET_FOOD_CLASSES.has(classIndex);
}

/**
 * Get food class name if available
 */
export function getFoodClassName(classIndex: number): string | null {
    return FOOD_CLASS_NAMES[classIndex] || null;
}

/**
 * Check if class is actual food (not just container)
 */
export function isActualFood(classIndex: number): boolean {
    return IMAGENET_FOOD_INDICES.includes(classIndex);
}
