# AI Usage Dashboard

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg) ![Platform](https://img.shields.io/badge/Platform-iOS%2017%20%7C%20macOS%2014%20%7C%20iPadOS%2017-blue.svg) ![Charts](https://img.shields.io/badge/SwiftUI-Charts-green.svg)

A SwiftUI multiplatform app to monitor real-time AI credits and usage across multiple AI platforms.

## Supported Platforms

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 17.0           |
| iPadOS   | 17.0           |
| macOS    | 14.0           |

## Monitored AI Services

- 🧠 **Claude** (Anthropic) — Pro subscription + API usage
- 💬 **ChatGPT** (OpenAI) — Plus subscription + API usage
- ✨ **Gemini** (Google) — Advanced subscription + API usage
- 🤖 **Manus** — Credit-based usage

## Features

- **Real-time Dashboard** — Overview of all AI platform usage at a glance
- **Usage Charts** — 30-day trends, hourly breakdowns using Swift Charts
- **Budget Tracking** — Monthly cost monitoring with configurable alerts
- **Quota Monitoring** — Track remaining credits/messages per platform
- **Smart Alerts** — Automatic warnings at 75%/90%/95% usage thresholds
- **Settings** — Configure quotas, budgets, and API keys per provider
- **Adaptive Layout** — Optimized for iPhone, iPad, and Mac
- **macOS Menu Bar** — Quick status widget in the menu bar

## Architecture

```
AIUsageDashboard/
├── AIUsageDashboardApp.swift    # App entry point + macOS MenuBarExtra
├── ContentView.swift            # Platform-adaptive navigation
├── Models/
│   ├── AIProvider.swift          # Provider definitions, config, alert levels
│   └── UsageRecord.swift         # Usage snapshots, daily/hourly records
├── ViewModels/
│   └── DashboardViewModel.swift  # Main business logic + data generation
├── Views/
│   ├── DashboardView.swift       # Main dashboard with stats grid
│   ├── ProviderCardView.swift    # Expandable provider cards
│   ├── UsageChartView.swift      # Swift Charts (trend, pie, hourly, comparison)
│   ├── AlertsView.swift          # Alert notification center
│   └── SettingsView.swift        # Provider config + API key management
└── Services/
    ├── APIService.swift           # API integrations (Anthropic, OpenAI, Google, Manus)
    └── StorageService.swift       # UserDefaults + Keychain persistence
```

## Setup

### Option A: Create Xcode Project (Recommended)

1. Clone this repository
2. Open **Xcode 15+**
3. **File → New → Project → Multiplatform → App**
4. Product Name: `AIUsageDashboard`
5. Organization Identifier: `com.macrovision`
6. Interface: SwiftUI, Language: Swift
7. Set deployment targets: iOS 17.0, macOS 14.0
8. Delete the generated source files
9. Drag `AIUsageDashboard/` folder into the project navigator
10. Build and run

### Option B: Quick Start

```bash
git clone https://github.com/chchlin1018/AIUsageDashboard.git
cd AIUsageDashboard
open -a Xcode .
```

### API Keys (Optional)

Create a `Secrets.swift` file (gitignored) with your API keys:

```swift
enum Secrets {
    static let anthropicAPIKey = "sk-ant-..."
    static let openAIAPIKey = "sk-..."
    static let geminiAPIKey = "AI..."
}
```

Or configure them in-app via **Settings → [Provider] → Set API Key**.

## Roadmap

- [ ] Real API integration (Anthropic Admin API)
- [ ] OpenAI billing endpoint integration
- [ ] Widgets for macOS/iOS (WidgetKit)
- [ ] Menu bar app improvements
- [ ] Push notification alerts
- [ ] iCloud sync across devices
- [ ] Apple Shortcuts integration
- [ ] SwiftData migration for usage history
- [ ] Export reports (CSV/PDF)

## License

MIT © MacroVision Systems
