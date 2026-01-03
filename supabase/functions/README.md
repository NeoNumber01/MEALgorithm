# Supabase Edge Functions

This directory contains Supabase Edge Functions that handle AI operations using the Gemini API.

## Functions

### `analyze-meal`

Analyzes meal images or text descriptions and returns nutritional information.

**Endpoint:** `POST /functions/v1/analyze-meal`

**Request Body:**
```json
{
  "text": "Optional text description of the meal",
  "imageBase64": "Optional base64 encoded image data",
  "imageMimeType": "image/jpeg or image/png",
  "imageDescription": "Optional additional notes about the meal"
}
```

**Response:**
```json
{
  "data": {
    "items": [
      {
        "name": "Food item name",
        "quantity": "Estimated quantity",
        "nutrition": {
          "calories": 0,
          "protein": 0,
          "carbs": 0,
          "fat": 0
        },
        "confidence": 0.8
      }
    ],
    "summary": {
      "calories": 0,
      "protein": 0,
      "carbs": 0,
      "fat": 0
    },
    "feedback": "Nutritional feedback message"
  }
}
```

### `ai-generate`

Generic AI generation endpoint for various AI operations.

**Endpoint:** `POST /functions/v1/ai-generate`

**Request Body:**
```json
{
  "prompt": "The prompt to send to Gemini AI",
  "type": "meal-analysis | recommendations | feedback"
}
```

## Deployment

### Prerequisites

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project:
   ```bash
   supabase link --project-ref your-project-ref
   ```

### Set Environment Variables

Set the Gemini API key as a secret:

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key
```

To verify secrets are set:
```bash
supabase secrets list
```

### Deploy Functions

Deploy all functions:
```bash
supabase functions deploy
```

Or deploy individual functions:
```bash
supabase functions deploy analyze-meal
supabase functions deploy ai-generate
```

### Local Development

1. Start the local Supabase development environment:
   ```bash
   supabase start
   ```

2. Serve functions locally:
   ```bash
   supabase functions serve --env-file .env.local
   ```

   Create a `.env.local` file with:
   ```
   GEMINI_API_KEY=your_gemini_api_key
   ```

3. Test the function:
   ```bash
   curl -i --location --request POST 'http://localhost:54321/functions/v1/analyze-meal' \
     --header 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
     --header 'Content-Type: application/json' \
     --data '{"text":"I had a chicken salad for lunch"}'
   ```

## Security

- All functions require authentication via Bearer token
- The Gemini API key is stored securely as a Supabase secret
- CORS headers are configured for cross-origin requests
- Request types are validated to prevent abuse

## Updating the Model

To change the Gemini model version, update the `model` parameter in each function:

```typescript
const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash",  // Change this
    generationConfig: {
        responseMimeType: "application/json",
    },
})
```

Available models:
- `gemini-2.0-flash` (recommended)
- `gemini-1.5-flash`
- `gemini-1.5-pro`
