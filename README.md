# Pflege-Lock-App

Android Flutter app that blocks distracting apps until you answer Pflegefachmann exam-style questions in German.

## Features

- Block apps like Instagram, TikTok, and YouTube
- Full-screen overlay with nursing exam questions
- Streak-based unlock (default: 3 correct answers)
- Local SQLite storage — no cloud, no internet required
- Stats and configurable settings

## Requirements

- Android 6.0+ (API 23)
- Flutter 3.12+

## Setup

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk --debug
```

APK output: `build/app/outputs/flutter-apk/app-debug.apk`

## Permissions

PflegeLock requires these Android permissions to function:

- Display over other apps (overlay)
- Usage access (detect foreground app)
- Battery optimization exemption (recommended)
- Foreground service (background monitoring)

All data stays on device only.
