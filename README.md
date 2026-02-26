# Flow (FocusAI)

Flow is a cross-platform productivity app built with Flutter. It combines Pomodoro timeboxing, task management, and AI-assisted task planning in one clean workflow.

This project is designed as a production-style portfolio app that demonstrates end-to-end product thinking across mobile UX, local persistence, and backend AI streaming.

## Highlights

- Pomodoro timer with focus, short break, and long break modes
- Task management with priority, status tracking, and estimated pomodoro counts
- AI planning chat that turns user goals into structured task plans
- Calendar planning support for AI-generated plans
- Statistics dashboard (today/week/month trends, streaks, goal progress, heatmap)
- Persistent local storage with SQLite (`sqflite`)
- Adaptive navigation for phone, tablet, and desktop layouts
- Localization support (English and Traditional Chinese)

## Tech Stack

- Flutter 3.8+ / Dart 3.8+
- `flutter_riverpod` for state management
- `go_router` for navigation
- `sqflite` + `shared_preferences` for persistence
- Material 3 + dynamic color
- `fl_chart` for analytics visualizations

## Architecture (App)

- `lib/screens`: main UI screens (timer, tasks, stats, settings, AI chat)
- `lib/widgets`: reusable UI components and dialogs
- `lib/providers`: state and business logic
- `lib/services`: persistence, notifications, calendar utilities
- `lib/models`: domain models (tasks, chat messages, plans)

## Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or newer
- Dart SDK 3.8.1 or newer
- A running backend server for AI chat (see `focus-backend` project)

### Installation

```bash
git clone https://github.com/<your-username>/focus.git
cd focus/focus
flutter pub get
```

### Run Locally

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

If `API_BASE_URL` is not provided, the app defaults to `http://localhost:3000`.

## Resume / CV Talking Points

- Built a full-stack productivity product (Flutter + Node.js) with real-time AI chat streaming (SSE)
- Designed an AI workflow that transforms natural-language goals into actionable Pomodoro task plans
- Implemented analytics features (streaks, completion trends, and goal tracking) to improve user feedback loops
- Delivered cross-platform UI with localization and adaptive navigation patterns

## Related Project

- Backend API: `focus-backend/` (Express + AI provider integration)

## Status

Active personal project, continuously improving UX and planning intelligence.
