export type Json =
    | string
    | number
    | boolean
    | null
    | { [key: string]: Json | undefined }
    | Json[]

export interface Database {
    public: {
        Tables: {
            profiles: {
                Row: {
                    id: string
                    calorie_target: number
                    goal: 'maintenance' | 'weight-loss' | 'muscle-gain' | null
                    full_name: string | null
                    avatar_url: string | null
                    updated_at: string | null
                }
                Insert: {
                    id: string
                    calorie_target?: number
                    goal?: 'maintenance' | 'weight-loss' | 'muscle-gain' | null
                    full_name?: string | null
                    avatar_url?: string | null
                    updated_at?: string | null
                }
                Update: {
                    id?: string
                    calorie_target?: number
                    goal?: 'maintenance' | 'weight-loss' | 'muscle-gain' | null
                    full_name?: string | null
                    avatar_url?: string | null
                    updated_at?: string | null
                }
            }
            meals: {
                Row: {
                    id: string
                    user_id: string
                    text_content: string | null
                    analysis: Json | null
                    meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack' | null
                    created_at: string
                }
                Insert: {
                    id?: string
                    user_id: string
                    text_content?: string | null
                    analysis?: Json | null
                    meal_type?: 'breakfast' | 'lunch' | 'dinner' | 'snack' | null
                    created_at?: string
                }
                Update: {
                    id?: string
                    user_id?: string
                    text_content?: string | null
                    analysis?: Json | null
                    meal_type?: 'breakfast' | 'lunch' | 'dinner' | 'snack' | null
                    created_at?: string
                }
            }
            food_catalog: {
                Row: {
                    id: string
                    name: string
                    brand: string | null
                    nutrition: Json
                    created_at: string
                }
                Insert: {
                    id?: string
                    name: string
                    brand?: string | null
                    nutrition: Json
                    created_at?: string
                }
                Update: {
                    id?: string
                    name?: string
                    brand?: string | null
                    nutrition?: Json
                    created_at?: string
                }
            }
        }
    }
}
