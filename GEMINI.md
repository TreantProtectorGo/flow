# Gemini Code Assistant Context

This document provides context for the Gemini code assistant to understand the "Focus" project.

## Project Overview

**Focus** is a cross-platform productivity application built with **Flutter**. It helps users manage their time and tasks by combining the **Pomodoro technique** with task management features.

### Key Features:

*   **Focus Timer:** A timer based on the Pomodoro technique.
*   **Task Management:** Create, organize, and track tasks.
*   **Statistics:** View focus time and work efficiency data.
*   **Theme Switching:** Light and dark mode support.

### Architecture and Technologies:

*   **Framework:** Flutter
*   **Language:** Dart
*   **State Management:** `flutter_riverpod`
*   **Navigation:** `go_router`
*   **Storage:** `shared_preferences` for key-value storage and `sqflite` for local database.
*   **UI:**
    *   `fl_chart` for data visualization.
    *   `lottie` for animations.
    *   `dynamic_color` for Material 3 dynamic theming.
*   **Background Operations:** `flutter_background_service` and `flutter_local_notifications`.

### Project Structure:

The project follows a standard Flutter project structure, with the main application code located in the `lib` directory. The code is organized into the following directories:

*   `lib/screens`: UI screens for different features.
*   `lib/providers`: State management using Riverpod providers.
*   `lib/models`: Data models for the application.
*   `lib/theme`: Application theme and styling.
*   `lib/utils`: Utility functions.
*   `lib/widgets`: Reusable UI components.

## Building and Running

### Prerequisites:

*   Flutter SDK (version 3.0 or higher)
*   Dart SDK (version 2.17 or higher)

### Commands:

*   **Install dependencies:**
    ```bash
    flutter pub get
    ```
*   **Run the application:**
    ```bash
    flutter run
    ```
*   **Run tests:**
    ```bash
    flutter test
    ```

## Development Conventions

*   **Coding Style:** The project follows the standard `flutter_lints` for good coding practices.
*   **State Management:** State is managed using `flutter_riverpod`. Providers are defined in the `lib/providers` directory.
*   **Navigation:** Navigation is handled by the `go_router` package. Routes are defined in `lib/main.dart`.
*   **Asynchronous Operations:** The app uses `Future`s for asynchronous operations like loading data from `shared_preferences`.
