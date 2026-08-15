# POS Frontend – Flutter Client & Native Health Bridge

[![Flutter](https://img.shields.io/badge/Flutter-3.44.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.x-0175C2?logo=dart)](https://dart.dev)
[![Drift](https://img.shields.io/badge/Storage-Drift%20SQLite-40C4FF)](https://drift.simonbinder.eu)
[![Riverpod](https://img.shields.io/badge/State-Riverpod%203.x-546E7A)](https://riverpod.dev)
[![Android](https://img.shields.io/badge/Native-Health%20Connect-34A853?logo=android)](https://developer.android.com/health-and-fitness/guides/health-connect)

> **The primary user interface for the Personal Operating System (POS).**  
> Built with Flutter and Kotlin, designed for instantaneous zero-latency local execution, automated habit state management, passive Google Health Connect metric telemetry, and bidirectional delta-sync with the Go backend daemon.

---

## 📱 Features & Highlights

### ⚡ 1. Zero-Lag Offline-First Architecture
- Powered by an embedded **Drift SQLite** database.
- Checking off medications, logging habits, or deferring routines executes instantaneously with optimistic local updates.
- Background sync queues buffer changes when offline and sync delta changes when network connectivity is restored.

### ⏱️ 2. 4-Quadrant Time-Fenced Execution ("The Ticket Engine")
Daily recurring tickets are categorized into four distinct time windows:
1. **Morning Protocol (`06:00` – `12:00`):** Fasted meds, morning hydration, supplements (Creatine, D3), mobility.
2. **Mid-Day & Pre-Workout (`12:00` – `18:00`):** High-protein meal, pre-workout hydration and caffeine.
3. **Evening & Post-Workout (`18:00` – `21:00`):** Gym/workout session, post-workout dinner, daily step count check.
4. **Night / Bedtime Stack (`21:00` – `23:59`):** Magnesium/Zinc stack, screen wind-down, sleep prep.

*The UI automatically detects the current hour and emphasizes the active quadrant with contextual glow and active badges.*

### 🩺 3. Android Health Connect Differential Ingest Engine
- **Differential Queries:** Uses Health Connect `ChangesToken` to read only new or updated records rather than scanning full histories.
- **Background Automation:** Kotlin `HealthSyncWorker` runs via AndroidX `WorkManager` every 15 minutes to ingest steps, burned calories, sleep stages, weight, and exercise sessions.
- **Desktop Fallback:** When running on macOS, Linux, or Web, the frontend seamlessly displays aggregated metrics fetched directly from the Go backend.

---

## 📂 Architecture & Directory Structure

```
frontend/
├── android/                         # Kotlin platform bridge & Health Connect
│   └── app/src/main/
│       ├── AndroidManifest.xml      # Health permissions & rationale filters
│       └── kotlin/com/pos/pos_frontend/
│           ├── MainActivity.kt      # MethodChannel handler ('com.pos.app/health')
│           └── health/
│               ├── HealthConnectManager.kt  # Permissions & Differential queries
│               └── HealthSyncWorker.kt      # Periodic WorkManager background worker
├── lib/
│   ├── data/
│   │   ├── local/                   # Drift SQLite schema & DAOs
│   │   │   ├── daos/
│   │   │   │   ├── routine_dao.dart # Routine persistence & queries
│   │   │   │   └── metric_dao.dart  # Metric time-series aggregation
│   │   │   └── database.dart        # Drift AppDatabase definition
│   │   ├── native/
│   │   │   └── health_connect_channel.dart # MethodChannel normalization bridge
│   │   ├── remote/
│   │   │   ├── api_client.dart      # Dio REST client
│   │   │   └── ws_client.dart       # WebSocket pub/sub subscriber
│   │   └── repositories/
│   │       ├── offline_routine_repository.dart
│   │       └── offline_metric_repository.dart
│   ├── domain/
│   │   └── models/
│   │       ├── routine_item.dart    # RoutineItem, ItemStatus, TimeWindow
│   │       └── health_data_point.dart # HealthDataPoint, MetricType
│   ├── presentation/
│   │   ├── providers/               # Riverpod 3.x NotifierProviders
│   │   │   ├── routine_provider.dart
│   │   │   └── metric_provider.dart
│   │   ├── screens/
│   │   │   └── dashboard_screen.dart # 4-Quadrant responsive UI
│   │   └── widgets/
│   │       ├── quadrant_card.dart
│   │       ├── routine_item_tile.dart
│   │       └── metric_summary_chart.dart
│   └── main.dart                    # App entrypoint & Material 3 theming
├── test/                            # Unit, DAO, and widget test suites
│   ├── data/
│   │   ├── local/database_test.dart
│   │   ├── native/health_connect_channel_test.dart
│   │   └── repositories/offline_routine_repository_test.dart
│   └── presentation/screens/dashboard_screen_test.dart
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK:** `>= 3.44.0` (Channel stable)
- **Dart SDK:** `>= 3.12.0`
- **Android Studio / SDK:** Target SDK `34`, Min SDK `26` (Android 8.0+ for Health Connect)

### 1. Install Dependencies
```bash
cd frontend
flutter pub get
```

### 2. Code Generation (Drift Database Bindings)
If you modify Drift tables or DAOs, regenerate the type-safe bindings:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run on Android Device / Emulator
```bash
# Ensure an Android device or emulator is running
flutter run -d android
```

### 4. Run on macOS / Linux Desktop
```bash
flutter run -d macos
# or
flutter run -d linux
```

---

## 🧪 Testing & Verification

Run the comprehensive test suite (including in-memory SQLite DAO tests and UI widget tests):

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## ⚙️ Backend Sync Configuration

The API client connects to the Go daemon at `http://localhost:8080` by default.  
When running inside an Android Emulator:
- Set API base URL to `http://10.0.2.2:8080` (loopback to host).
- Set WebSocket URL to `ws://10.0.2.2:8080/api/v1/ws`.
