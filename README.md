# 🚀 PROJEX AI

**AI-Powered Project Management with Social Collaboration**

A modern, full-featured project management platform powered by multiple AI providers (Groq, Gemini, Mistral) with team collaboration features, AI image generation, and intelligent task management.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

### 🤖 AI Integration
- **Multi-AI Chat Assistant** powered by:
  - 🚀 Groq (Ultra-fast inference)
  - 🧠 Google Gemini (Advanced reasoning)
  - ⚡ Mistral AI (Balanced performance)
- **AI Image Generation** via Cloudflare AI & HuggingFace
- **Smart Project Templates** for common workflows
- **AI Actions**: Summarize tasks, prioritize, create timelines, draft emails

### 📊 Project Management
- **Projects**: Create, track, and manage multiple projects
- **Tasks**: Priority-based task management with status tracking
- **Meetings**: Schedule and manage team meetings
- **Team**: Manage team members and departments
- **Reports**: Track project progress and analytics

### 👥 Social Features
- **Team Social Feed**: Share updates, images, and collaborate
- **Real-time Activity**: See what your team is working on
- **Likes & Comments**: Engage with team posts
- **Online Status**: See who's available

### 🍅 Productivity
- **Pomodoro Timer**: Built-in focus timer with statistics
- **Daily Goals**: Set and track pomodoro goals
- **Progress Tracking**: Visual progress bars for all projects

### 💎 Subscription System
- **25-day Free Trial**: Full access to all features
- **Pro Plan ($29/month)**: Unlimited AI, images, and features
- **LemonSqueezy Integration**: Secure payment processing

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ (for API functions)
- Vercel CLI (for deployment)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/projex-ai.git
cd projex-ai

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env.local
# Edit .env.local with your API keys

# Run locally
vercel dev
```

### Environment Variables

Create a `.env.local` file:

```env
# AI API Keys
GROQ_API_KEY=your_groq_key_here
GEMINI_API_KEY=your_gemini_key_here
MISTRAL_API_KEY=your_mistral_key_here
HF_TOKEN=your_huggingface_token_here

# Cloudflare (Optional)
CLOUDFLARE_API_KEY=your_cloudflare_key
CLOUDFLARE_ACCOUNT_ID=your_account_id

# LemonSqueezy (Payment)
LEMONSQUEEZY_API_KEY=your_api_key
LEMONSQUEEZY_STORE_ID=your_store_id
LEMONSQUEEZY_WEBHOOK_SECRET=your_webhook_secret
```

## 📁 Project Structure

```
projex-ai/
├── index.html          # Main SPA application
├── css/
│   └── style.css       # Main stylesheet
├── api/                # Vercel serverless functions
│   ├── groq.js         # Groq AI integration
│   ├── gemini.js       # Gemini AI integration
│   ├── mistral.js      # Mistral AI integration
│   ├── generate-image.js # Image generation
│   ├── subscribe.js    # Payment handling
│   └── webhook.js      # Payment webhooks
├── package.json
├── vercel.json         # Vercel configuration
└── README.md
```

## 🛠️ API Endpoints

### AI Endpoints
- `POST /api/groq` - Groq AI chat completion
- `POST /api/gemini` - Gemini AI chat completion
- `POST /api/mistral` - Mistral AI chat completion
- `POST /api/generate-image` - Generate AI images

### Payment Endpoints
- `POST /api/subscribe` - Create checkout session
- `GET /api/subscribe` - Check subscription status
- `POST /api/webhook` - LemonSqueezy webhooks

## 🎨 Tech Stack

- **Frontend**: Vanilla HTML5, CSS3, JavaScript (ES6+)
- **Backend**: Vercel Serverless Functions (Node.js)
- **AI Providers**: Groq, Google Gemini, Mistral AI
- **Image Gen**: Cloudflare Workers AI, HuggingFace
- **Payments**: LemonSqueezy
- **Hosting**: Vercel

## 🔐 Security

- API keys are server-side only (Vercel functions)
- User data stored in localStorage (client-side)
- Secure payment processing via LemonSqueezy
- Webhook signature verification

## 📱 Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## 📝 License

MIT License - see [LICENSE](LICENSE) file

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 🙏 Credits

- Fonts: Syne, Cabinet Grotesk, DM Sans, Instrument Sans, JetBrains Mono
- Icons: System emojis
- AI: Groq, Google, Mistral AI

## 📞 Support

- 📧 Email: support@projex.ai
- 💬 Discord: [Join our server](https://discord.gg/projex)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/projex-ai/issues)

---

Built with ❤️ by the PROJEX AI Team
