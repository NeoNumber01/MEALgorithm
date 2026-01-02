import { z } from 'zod'

export const NutritionalInfoSchema = z.object({
    calories: z.number().describe('Estimated calories (kcal)'),
    protein: z.number().describe('Protein in grams'),
    carbs: z.number().describe('Carbohydrates in grams'),
    fat: z.number().describe('Fat in grams'),
})

export const MealItemSchema = z.object({
    name: z.string().describe('Name of the food item'),
    quantity: z.string().describe('Estimated quantity/portion (e.g. "1 cup", "150g")'),
    nutrition: NutritionalInfoSchema,
    confidence: z.number().min(0).max(1).optional().default(0.8).describe('Confidence score between 0 and 1'),
})

export const MealAnalysisSchema = z.object({
    items: z.array(MealItemSchema),
    summary: NutritionalInfoSchema.describe('Total nutritional values for the entire meal'),
    feedback: z.string().describe('Short feedback/comment on the healthiness or goal alignment'),
})

export type MealAnalysis = z.infer<typeof MealAnalysisSchema>
