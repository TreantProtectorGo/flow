# Flow

<p align="center">
  <img src="../appstore.png" alt="Flow app icon" width="160" />
</p>

<p align="center">
  <a href="https://apps.apple.com/us/app/flow-ai-focus-planner/id6761019011">Download on the App Store</a>
</p>

Flow is a cross-platform productivity app built with Flutter. It combines Pomodoro timeboxing, task management, AI-assisted task planning, and optional cloud sync in one clean workflow.

This project is designed as a production-style portfolio app that demonstrates end-to-end product thinking across mobile UX, local persistence, backend AI streaming, and Firebase cloud infrastructure.

Flow is publicly available on iOS via the App Store.

## Preview

<p align="center">
  <img src="../time.png" alt="Flow timer screen" width="30%" />
  <img src="../task.png" alt="Flow tasks screen" width="30%" />
  <img src="../ai_chat_planning.png" alt="Flow AI chat planning screen" width="30%" />
</p>

## Highlights

- Pomodoro timer with focus, short break, and long break modes
- Task management with priority, status tracking, and estimated pomodoro counts
- AI planning chat that turns user goals into structured task breakdowns (SSE streaming)
- Persistent AI chat history with multi-session support
- Calendar export for AI-generated task plans
- Statistics dashboard (today/week/month trends, streaks, goal progress, heatmap)
- Offline-first local storage with SQLite (`sqflite`), schema migrations to v7
- **Firebase Cloud Sync** — Google Sign-In, Firestore mirror, per-account data isolation
- Adaptive navigation for phone, tablet, and desktop layouts
- Localization support (English and Traditional Chinese)
- Material 3 + dynamic color theming with M3 Expressive motion

## Tech Stack

- Flutter 3.8+ / Dart 3.8+
- `flutter_riverpod` for state management (`ChangeNotifierProvider` + `StateNotifierProvider`)
- `go_router` for navigation (ShellRoute)
- `sqflite` + `shared_preferences` for local persistence
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` for cloud sync
- `http` for AI backend SSE streaming
- Material 3 + `dynamic_color`
- `fl_chart` for analytics visualizations
- `flutter_svg` for vector assets
- `flutter_markdown` for rendering AI responses
- `flutter_local_notifications` + `audioplayers` for timer alerts

## Architecture

```
lib/
├── config/          # ApiConfig (--dart-define overrides)
├── l10n/            # ARB files + generated localizations
├── models/          # Task, ChatMessage, TaskPlan, ChatSession
├── providers/       # Riverpod providers (timer, tasks, AI chat, auth, sync, settings)
├── screens/         # TimerScreen, TasksScreen, StatsScreen, SettingsScreen, AIChatScreen
├── services/        # DatabaseHelper, SyncService, FirebaseService, NotificationService, CalendarService
├── theme/           # AppTheme, M3 Expressive
├── utils/           # AdaptiveNavigation, PriorityUtils, SnackbarUtil
└── widgets/         # Reusable components and dialogs
```

## Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or newer
- Dart SDK 3.8.1 or newer
- A running backend server for AI chat (see `focus-backend` project)
- (Optional) A Firebase project configured via `flutterfire configure`

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

If `API_BASE_URL` is not provided, debug builds default to `http://localhost:3000`.
Release builds must provide a real backend URL:

```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://your-api-domain.com
```

### Testing

```bash
flutter test          # Run all tests
flutter analyze       # Lint check (must pass with zero issues)
flutter format lib/ test/
```

## Cloud Sync

Cloud sync is optional. When a user signs in with Google, tasks are mirrored to Firestore under their UID. Data is isolated per account — signing out or switching accounts clears the local state. The app works fully offline without a Firebase project configured.

## Related Project

- Backend API: `focus-backend/` (Express + AI provider integration with SSE streaming)

## Status

Active personal project — publicly available on the App Store, core features complete, cloud sync live, AI chat history persistent.
