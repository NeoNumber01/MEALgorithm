# 🥗 MEALgorithm

> **Smart Nutrition Tracking Powered by AI**

MEALgorithm is a modern, AI-enhanced nutrition tracking application designed to help users effortlessly monitor their diet. By leveraging Google's **Gemini 2.5 Flash** multimodal AI, users can log meals simply by taking a photo or describing user text. The application automatically analyzes the nutritional content (calories, protein, carbs, fat) and provides personalized feedback.

<img width="2554" height="1401" alt="image" src="https://github.com/user-attachments/assets/5cd63aaf-023d-49ad-a280-13fe5198e0d1" />


## ✨ Key Features

### 📸 Smart Meal Logging
- **Multimodal Input**: Log meals via **Text Description** ("I had a chicken salad") or **Image Upload**.
- **Gemini AI**: Automatically detects ingredients, portions, and estimates nutritional values (Calories, Protein, Carbs, Fat).
- **Interactive Editing**: Review and adjust AI-generated estimates before saving.

### 📊 Comprehensive Dashboard
- **Daily Overview**: At-a-glance view of today's calorie intake vs. goals.
- **Visual Analytics**: Interactive charts and heatmaps for 7-day, 30-day, or custom date ranges.
- **Macro Breakdown**: Visual distribution of Protein, Carbs, and Fats.
- **History & Trends**: Track your improved consistency streaks and average daily intake over time.

### 🤖 AI Nutrition Coach
- **Personalized Feedback**: get daily insights on your eating patterns.
- **Goal Alignment**: The AI analyzes your history to suggest specific improvements (e.g., "Try increasing protein at breakfast").
- **Smart Recommendations**: Context-aware advice based on your specific dietary goals.

### 👤 User Experience
- **Secure Profiles**: User data isolated via Row Level Security (RLS).
- **Responsive & Fast**: Optimistic UI updates for a snappy feel on all devices.
- **Local Timezone Support**: Accurate day-to-day tracking regardless of where you are in the world.

## 🛠️ Tech Stack

- **Framework**: [Next.js 14](https://nextjs.org/) (App Router)
- **Language**: TypeScript
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **Database & Auth**: [Supabase](https://supabase.com/)
- **AI Model**: [Google Gemini 2.5 Flash](https://ai.google.dev/)
- **State Management**: React Hooks + Server Actions

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites

- Node.js 18+ installed
- A Supabase account
- A Google Cloud account (for Gemini API)

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/meal-algorithm.git
cd meal-algorithm
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Environment Setup

Create a `.env` file in the root directory. You can use the provided example as a template:

```bash
cp .env.example .env
```

Fill in your API keys in `.env`:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

# Gemini AI Configuration
GEMINI_API_KEY=your_gemini_api_key
```

> **Note**: See [SECRETS_GUIDE.md](./SECRETS_GUIDE.md) for detailed instructions on where to find these keys.

### 4. Database Setup

Run the SQL migration scripts located in `supabase/migrations` in your Supabase Dashboard's SQL Editor to set up the requires tables (Profiles, Meals) and Security Policies (RLS).

### 5. Run the Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## 📁 Project Structure

```
src/
├── app/              # Next.js App Router pages
│   ├── auth/         # Authentication routes
│   ├── dashboard/    # Main user dashboard
│   ├── log/          # Meal logging interface
│   └── page.tsx      # Landing page
├── components/       # Reusable React components
│   ├── dashboard/    # Dashboard-specific widgets
│   ├── meals/        # Meal logging forms
│   └── ui/           # Generic UI elements
├── lib/              # Core logic & utilities
│   ├── ai/           # Gemini AI integration
│   ├── supabase/     # Database clients (Server/Client)
│   └── meals/        # Server Actions for meal data
└── styles/           # Global styles
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
