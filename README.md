# MEALgorithm Demo

A full-stack nutrition tracking application built with **Next.js 14**, **Supabase**, and **Google Gemini AI**.

## Features

- 🔐 **Authentication**: OAuth login via Google/GitHub using Supabase Auth
- 📝 **Smart Logging**: Log meals via text description or photo upload
- 🗑️ **Management**: Edit and delete your meal logs seamlessly
- 🤖 **AI Analysis**: **Gemini 2.5 Flash** parses meals into structured nutritional data
- 📊 **Dashboard**: View daily/weekly calorie and macro summaries with interactive charts
- 💡 **AI Recommendations**: Get personalized meal suggestions based on your goals
- 🎨 **Modern UI**: Featuring an **Ultra-Thin Glassmorphism** design system with dynamic 3D hover effects and animated backgrounds

## Tech Stack

- **Frontend**: Next.js 14 (App Router), TypeScript, Tailwind CSS
- **Backend**: Next.js Server Actions
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth (OAuth)
- **Storage**: Supabase Storage (meal images)
- **AI**: Google Gemini 2.5 Flash via `@google/generative-ai`
- **Validation**: Zod

## Prerequisites

- Node.js 18+
- A Supabase account
- A Google AI Studio account (for Gemini API key)

## Environment Variables

Create a `.env.local` file in the project root:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

## Supabase Setup

### 1. Create a new Supabase project

Go to [supabase.com](https://supabase.com) and create a new project.

### 2. Run the database migration

Copy the contents of `supabase/migrations/20240101000000_init_schema.sql` and run it in:
**Supabase Dashboard > SQL Editor > New Query > Paste & Run**

This will create:
- `profiles` table (user settings, calorie target)
- `meals` table (meal logs with AI analysis)
- `food_catalog` table (shared food database)
- `meal_images` storage bucket
- All necessary RLS policies

### 3. Configure OAuth Providers

1. Go to **Authentication > Providers**
2. Enable **Google** and/or **GitHub**
3. Add the OAuth credentials from the respective developer consoles
4. Set the callback URL to: `http://localhost:3000/auth/callback` (for local dev)

### 4. Create Storage Bucket (if not created by migration)

1. Go to **Storage**
2. Create a bucket named `meal_images`
3. Set it to **Public** (for easy image display)

## Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Project Structure

```
src/
├── app/                    # Next.js App Router pages
│   ├── auth/               # Auth callback & error routes
│   ├── dashboard/          # Dashboard page
│   ├── log/                # Meal logging page
│   ├── login/              # Login page
│   ├── recommendations/    # AI recommendations page
│   └── settings/           # User profile settings
├── components/
│   ├── auth/               # Auth components
│   ├── dashboard/          # Dashboard components
│   ├── meals/              # Meal logging components
│   ├── profile/            # Profile settings components
│   └── recommendations/    # Recommendation components
├── lib/
│   ├── ai/                 # Gemini client, prompts, schemas
│   ├── dashboard/          # Dashboard actions
│   ├── meals/              # Meal CRUD actions
│   └── supabase/           # Supabase clients
└── types/                  # TypeScript types

supabase/
└── migrations/             # SQL migration files
```

## Usage Guide

### 1. Login
- Click "Login with Google" or "Login with GitHub"
- You'll be redirected back to the app after authentication

### 2. Log a Meal
- Click "Log Meal" on the home page
- Choose **Text** mode and describe your meal, OR
- Choose **Photo** mode and upload an image
- Click "Analyze with AI" to get nutritional breakdown
- Review the preview and click "Confirm & Save"

### 3. Manage Your Logic
- View your daily logs on the Dashboard
- Hover over any meal item to reveal the **Delete (🗑️)** button
- Confirm deletion to remove it from your records

### 4. View Dashboard
- Click "Dashboard" to see your nutrition summary
- Toggle between "Today" and "This Week" views
- See AI-generated feedback on your progress
- Watch the calorie gauge and macro cards animate with your data

### 5. Get Recommendations
- Click "Suggestions" for AI-powered meal ideas
- Recommendations are personalized based on your goals and recent meals

## Security Notes

- ✅ All database tables have Row Level Security (RLS) enabled
- ✅ Users can only access their own data
- ✅ `GEMINI_API_KEY` is server-side only (never exposed to client)
- ✅ `SUPABASE_SERVICE_ROLE_KEY` is NOT used (all queries use user context)

## License

MIT
