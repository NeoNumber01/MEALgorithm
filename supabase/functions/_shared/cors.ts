// Shared CORS configuration for Supabase Edge Functions

export const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
}

/**
 * Handle CORS preflight requests
 * @param req - The incoming request
 * @returns Response if it's a preflight request, null otherwise
 */
export function handleCors(req: Request): Response | null {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders })
    }
    return null
}
