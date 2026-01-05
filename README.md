# 🥗 MEALgorithm

> **Smart Nutrition Tracking Powered by AI**

MEALgorithm is a modern, AI-enhanced nutrition tracking application designed to help users effortlessly monitor their diet. By leveraging Google's **Gemini 2.5 Flash** multimodal AI, users can log meals simply by taking a photo or describing them in text. The application automatically analyzes nutritional content and provides personalized feedback with intelligent recommendations.

<img width="2554" height="1401" alt="MEALgorithm Dashboard" src="https://github.com/user-attachments/assets/5cd63aaf-023d-49ad-a280-13fe5198e0d1" />

---

## ✨ Key Features

### 📸 Smart Meal Logging
- **Multimodal Input**: Log meals via **Text Description** ("I had a chicken salad") or **Image Upload**
- **AI-Powered Analysis**: Gemini AI automatically detects ingredients, estimates portions, and outputs structured nutrition data
- **Local Food Classifier**: Ultra-fast (< 10ms) ImageNet-based image local food classifier AI pre-screening to reduce unnecessary API calls
- **Customized Suggestions**: AI generates next meal suggestions based on user preferences and dietary restrictions
- **Day Plan**: AI generates a day plan based on user preferences dietary restrictions，and remaining calories, protein, carbs, and fat.
- **AI Coach**: Provides personalized feedback and recommendations based on user progress and goals
- **Target calculation**: App calculates the target calories based on user's goal and age, gender, height, weight, and activity level locally.
- **Statistics in Dashboard**: Users can view their statistics in the dashboard, can see their meal history, and their AI coach insights in a time range selected by the user.

### 📊 Comprehensive Dashboard

#### Today's Overview
- **Real-time Progress Ring**: Visual calorie intake vs. daily target
- **Macro Tracking**: Protein, Carbs, Fat breakdowns with color-coded progress bars
- **Today's Meals List**: Edit meal types, view details, or delete entries
- **AI Coach Insight**: Real-time personalized feedback comparing current intake to stage-based targets

#### Statistics View
- **Flexible Time Ranges**: 7-day, 30-day, or custom date range analysis
- **Interactive Bar Charts**: Click any day to drill down into individual meals
- **Calorie Consistency Score**: Percentage of days within ±10% of target
- **Macro Balance Analysis**: Protein/Carbs/Fat distribution as percentages
- **Meal Type Distribution**: Visual breakdown of breakfast/lunch/dinner/snack consumption
- **AI Coach Report**: Period-based analysis with actionable improvement suggestions

### 🤖 AI Nutrition Coach
- **Context-Aware Feedback**: Different prompts for "Today" vs "Statistics" contexts
- **Stage-Based Assessment**: Evaluates progress against proportional targets based on meals consumed
  - Breakfast: 25% of daily target
  - Lunch: 30% of daily target
  - Dinner: 30% of daily target
  - Snack: 15% of daily target
- **Actionable Insights**: Highlights if you're over (>120%) or under (<80%) proportional targets

### 🍽️ Smart Recommendations

#### Next Meal
- **3 Creative Suggestions**: Varied meal ideas based on user preferences
- **Cuisine Variety**: Random cuisine and style inspiration for each generation
- **Nutrition Breakdown**: Calories, Protein, Carbs, Fat for each suggestion
- **Personalization**: Respects favorite foods, dislikes, and dietary restrictions

#### Day Plan
- **Remaining Meals Planning**: Plans only meals you haven't eaten yet
- **Calorie Distribution**: Evenly distributes remaining budget across meals
- **Macro Targeting**: Balances protein/carbs/fat across planned meals
- **Optional Snack**: Adds snack recommendation if calories remain

### 👤 User Customization

#### Food Preferences Modal
| Field | Function | Example |
|-------|----------|---------|
| **Foods I Love** | AI prioritizes these | "Sushi, steak, pasta" |
| **Foods I Dislike** | AI strictly excludes | "Cilantro, raw onions" |
| **Dietary Restrictions** | Hard constraints | "Vegetarian, Gluten-free" |
| **Special Requests** | Free-form notes | "Trying to lose weight" |

#### Profile Settings
- **Daily Calorie Target**: Customizable goal (default: 2000 kcal)
- **Goal Description**: Text description of health/fitness objectives
- **OAuth Profile Sync**: Auto-populated name and avatar from Google/GitHub

### 🚀 Performance Optimizations

#### Multi-Level Caching Strategy
| Layer | Storage | Strategy | Invalidation Trigger |
|-------|---------|----------|---------------------|
| **Frontend localStorage** | Browser | Dashboard today's data | Meal add/delete, target change |
| **AI Feedback Cache** | localStorage + data hash | Reuse AI output for identical data | Data change or manual refresh |
| **Server Profile Cache** | Supabase DB (`profiles` table) | Persistent recommendations | Meal/preference/target changes |

#### Optimistic UI Updates
- Smooth visual feedback on meal logging
- No waiting for server confirmation
- Background sync with rollback on failure

#### Local Timezone Support
- Accurate day boundaries regardless of user location
- Server-side date calculations respect client timezone

---

## 🛠️ Tech Stack

| Layer | Technology | Description |
|-------|------------|-------------|
| **Framework** | [Next.js 14](https://nextjs.org/) (App Router) | React Server Components + Server Actions |
| **Language** | TypeScript | Type-safe full-stack development |
| **Styling** | [Tailwind CSS](https://tailwindcss.com/) | Utility-first CSS with custom glassmorphism |
| **Database & Auth** | [Supabase](https://supabase.com/) | PostgreSQL + OAuth + Row Level Security |
| **AI Model** | [Google Gemini 3 Flash](https://ai.google.dev/) | Multimodal + JSON structured output |
| **Edge Functions** | Deno (Supabase Edge Functions) | Low-latency serverless AI gateway |
| **Desktop App** | Electron / Tauri | Optional cross-platform packaging |

---

## ⚡ Edge Functions Architecture

All AI inference tasks run on Supabase Edge Functions, ensuring:
- **API Key Security**: GEMINI_API_KEY stored only in edge function environment
- **Low Latency**: Edge nodes process requests at the nearest location
- **Built-in Authentication**: Functions internally verify JWT tokens

### 📡 Deployed Edge Functions

| Function | Purpose | Description |
|----------|---------|-------------|
| `analyze-meal` | Meal Analysis | Multimodal input (text + image), structured nutrition output |
| `generate-suggestions` | Recommendations | Next Meal / Day Plan / AI Coach - unified endpoint |
| `ai-generate` | General AI | Flexible prompt-based generation interface |

```
┌─────────────────────────────────────────────────────────────────┐
│                      Frontend (Next.js)                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Server Action → getSession() → fetch Edge Function      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (with JWT Authorization header)
┌─────────────────────────────────────────────────────────────────┐
│                 Supabase Edge Functions (Deno)                  │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │  analyze-meal  │  │ generate-      │  │   ai-generate    │   │
│  │                │  │   suggestions  │  │                  │   │
│  └───────┬────────┘  └───────┬────────┘  └────────┬─────────┘   │
│          └───────────────────┴────────────────────┘             │
│                              │                                  │
│                              ▼                                  │
│                  ┌────────────────────┐                         │
│                  │  Google Gemini API │                         │
│                  │  (gemini-2.0-flash)│                         │
│                  └────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
MEALgorithm/
├── src/
│   ├── app/                    # Next.js App Router pages
│   │   ├── auth/               # OAuth callback routes
│   │   ├── dashboard/          # Main dashboard page
│   │   ├── log/                # Meal logging page
│   │   ├── recommendations/    # Smart recommendations page
│   │   ├── settings/           # User profile settings
│   │   └── page.tsx            # Landing page with hero section
│   ├── components/
│   │   ├── dashboard/          # DashboardContent, StatisticsView, AICoachCard
│   │   ├── meals/              # MealLogForm (519 lines of meal logging)
│   │   ├── recommendations/    # RecommendationsContent, PreferencesModal
│   │   └── ui/                 # Shared UI components (ConfirmModal, etc.)
│   ├── lib/
│   │   ├── ai/                 # AI prompts, schema, coach-actions
│   │   ├── cache-utils.ts      # Multi-level caching utilities
│   │   ├── classifier/         # ImageNet food classifier (< 1ms)
│   │   ├── recommendations/    # Server Actions for recommendations
│   │   ├── suggestions/        # Next Meal / Day Plan actions
│   │   ├── preferences/        # User preferences actions
│   │   ├── supabase/           # Supabase clients (server/browser)
│   │   ├── meals/              # Meal CRUD Server Actions
│   │   └── dashboard/          # Dashboard data fetching
│   └── types/                  # TypeScript type definitions
├── supabase/
│   ├── functions/              # Deno Edge Functions
│   │   ├── _shared/            # Shared CORS handling
│   │   ├── ai-generate/        # General AI generation
│   │   ├── analyze-meal/       # Meal analysis with retry logic
│   │   └── generate-suggestions/ # Unified suggestions endpoint
│   └── migrations/             # Database schema migrations
├── electron/                   # Electron desktop config
├── src-tauri/                  # Tauri desktop config
└── package.json
```

---

## 🔧 Getting Started

For detailed local development setup, database configuration, and Edge Functions deployment instructions, please refer to:

📖 **[SECURITY.md](./SECURITY.md)** - Complete Setup & Security Guide

This includes:
- Prerequisites and dependencies
- Supabase project creation
- Database migrations
- Edge Functions deployment
- Environment variables configuration
- Security best practices

---

## 🖥️ Desktop App Build

### Electron Version

```bash
# Development mode
npm run electron:dev

# Build distributable
npm run electron:dist
```

### Tauri Version (Lightweight)

```bash
npm run tauri dev
npm run tauri build
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  Made with 💚 by <a href="https://github.com/NeoNumber01">NeoNumber01's team</a>
</p>
