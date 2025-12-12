# LLM Council

<p align="center">
  <img src="assets/icons/app_icon.png" alt="LLM Council" width="120" height="120">
</p>

<p align="center">
  <strong>A premium mobile app that consults multiple AI models for superior answers</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#how-it-works">How It Works</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## Overview

**LLM Council** is a Flutter mobile application that takes a different approach to AI interactions. Instead of relying on a single AI model, your questions are deliberated by a council of multiple AI models who evaluate each other's responses before a chairman synthesizes the final answer.

> 🎯 **Inspired by [Andrej Karpathy's llm-council](https://github.com/karpathy/llm-council)** - a web-based implementation of the same concept. This mobile app brings the LLM Council experience to iOS and Android with a premium, executive-tier design.

## Features

- 🧠 **Multi-Model Deliberation** - Query multiple AI models simultaneously
- 🔄 **Anonymous Peer Ranking** - Models evaluate each other without knowing who wrote what
- 👔 **Chairman Synthesis** - Final response compiled by a designated chairman model
- 📊 **Aggregate Rankings** - See which responses were ranked highest
- 💾 **Local Persistence** - All conversations stored securely on-device
- 🎨 **Premium UI** - Executive dark theme with gold accents
- ⚡ **Progressive Loading** - Real-time updates as each stage completes
- 🔐 **Secure API Key Storage** - Encrypted storage for your OpenRouter key
- 📱 **Cross-Platform** - Works on both iOS and Android

## How It Works

### Stage 1: Individual Opinions
Your question is sent to all council models in parallel. Each model generates its own independent response.

### Stage 2: Anonymous Peer Review
Each model receives all responses with **anonymized labels** (Response A, B, C...). Models rank responses without knowing who wrote them, preventing bias.

### Stage 3: Chairman Synthesis
The chairman model receives all responses plus ranking results and synthesizes a final, comprehensive answer weighted by peer evaluations.

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.6.0 or higher)
- [OpenRouter API Key](https://openrouter.ai/settings/keys)
- iOS or Android device/emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/llm-council-app.git
   cd llm-council-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # iOS
   flutter run -d ios
   
   # Android
   flutter run -d android
   ```

4. **Enter your OpenRouter API key**
   - Launch the app
   - Tap "Get your API key" to open OpenRouter
   - Paste your key in the onboarding screen

### Building for Production

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## Configuration

### Model Presets

The app includes several pre-configured council presets:

| Preset | Models | Best For |
|--------|--------|----------|
| **Free Council** | Llama 3.3, Gemma 3, Mistral, DeepSeek | Getting started, no cost |
| **Premium Council** | GPT-4o, Claude Sonnet 4, Gemini 2.5 | Best quality responses |
| **Speed Council** | GPT-4o-mini, Claude Haiku, Gemini Flash | Fast responses |
| **Deep Analysis** | o1, Claude Sonnet 4, Gemini Pro | Complex reasoning |

### Custom Models

You can customize council members in Settings:
1. Open Settings
2. Scroll to "Council Members"
3. Add/remove models using OpenRouter model IDs

## Architecture

```
lib/
├── core/               # Constants, extensions
├── data/
│   ├── api/           # OpenRouter API client
│   ├── database/      # SQLite database helper
│   └── storage/       # Secure storage service
├── domain/
│   ├── models/        # Data models (Message, Conversation, etc.)
│   └── services/      # Business logic (CouncilService, RankingParser)
└── presentation/
    ├── bloc/          # State management (Settings, Conversation, Council)
    ├── screens/       # UI screens
    ├── theme/         # Executive dark theme
    └── widgets/       # Reusable components
```

### Tech Stack

- **Framework:** Flutter 3.6+
- **State Management:** flutter_bloc
- **Local Storage:** sqflite, flutter_secure_storage
- **Networking:** dio
- **UI:** Custom executive theme, flutter_animate

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/
```

## Acknowledgments

- **[Andrej Karpathy](https://github.com/karpathy)** - For the original [llm-council](https://github.com/karpathy/llm-council) concept and implementation that inspired this mobile app
- **[OpenRouter](https://openrouter.ai)** - For providing unified access to multiple LLM providers

## License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  Made with ❤️ for executives who demand the best AI insights
</p>
