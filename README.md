# Personal Operating System (POS)

[![Backend CI](https://github.com/pos/pos/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/pos/pos/actions/workflows/backend-ci.yml)
[![Frontend CI](https://github.com/pos/pos/actions/workflows/frontend-ci.yml/badge.svg)](https://github.com/pos/pos/actions/workflows/frontend-ci.yml)

> **Local-First, Low-Cognitive-Load Personal Operating System ("Jira for Life")**  
> Centralizes daily habit execution, medication/supplement adherence, caloric and workout telemetry, and automated Home Assistant integrations.

---

## 1. System Architecture

```
                     ┌────────────────────────────────────────┐
                     │         Android Mobile Device          │
                     │  ┌──────────────────────────────────┐  │
                     │  │   Google Health Connect (Local)  │  │
                     │  └────────────────┬─────────────────┘  │
                     │                   │ Android MethodChannel / WorkManager
                     │  ┌────────────────▼─────────────────┐  │
                     │  │      Flutter App (Android)       │  │
                     │  │   (Local Drift SQLite DB / UI)   │  │
                     │  └────────────────┬─────────────────┘  │
                     └───────────────────┼────────────────────┘
                                         │ REST / WebSocket Delta Sync
                                         ▼
                     ┌────────────────────────────────────────┐
                     │          Go 1.26 Sync Daemon           │
                     │  ┌──────────────────────────────────┐  │
                     │  │ - Time-Series Metric Ingest      │  │
                     │  │ - Routine / Task State Engine    │  │
                     │  │ - Home Assistant WebSocket/REST  │  │
                     │  └────────────────┬─────────────────┘  │
                     └───────────────────┼────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        ▼                                ▼                                ▼
┌──────────────┐                 ┌──────────────┐                 ┌──────────────┐
│ Flutter Mac/ │                 │  PostgreSQL  │                 │Home Assistant│
│ Desktop UI   │                 │ (Time-Series)│                 │ (Auxiliary)  │
└──────────────┘                 └──────────────┘                 └──────────────┘
```

---

## 2. Core Modules

### 📱 A. Android Native Health Connect & Drift Offline Engine
- **Differential Polling:** Uses Health Connect `ChangesToken` to poll only updated/inserted health records.
- **Background Sync:** AndroidX `WorkManager` runs every 15 minutes to synchronize steps, calories burned, sleep stages, weight, and exercise sessions even when the app is closed.
- **Zero-Lag Offline UX:** All actions are committed instantly to an embedded Drift SQLite database and synchronized asynchronously.

### ⏱️ B. 4-Quadrant Routine State Machine ("The Ticket Engine")
- Non-blocking recurring tickets with automated state progression: `PENDING` $\rightarrow$ `COMPLETED` | `SKIPPED` | `DEFERRED`.
- **4 Time-Fenced Context Blocks:**
  1. *Morning Protocol* (`06:00` – `12:00`): Meds, hydration, morning mobility.
  2. *Mid-Day & Pre-Workout* (`12:00` – `18:00`): High-protein lunch, pre-workout.
  3. *Evening & Post-Workout* (`18:00` – `21:00`): Workout session, dinner, step target check.
  4. *Night / Bedtime Stack* (`21:00` – `23:59`): Magnesium/Zinc stack, wind-down.
- **Midnight Reset Cron:** Daily items automatically reset at `00:00` local time. Incomplete items transition to `MISSED` in time-series logs without carrying over as backlog clutter.

### 🏠 C. Home Assistant Relay & Bidirectional Automation
- **NFC Tag Ingest:** Tapping physical NFC tags (e.g. pill bottle, gym bag) triggers Home Assistant `tag_scanned` events, which the Go backend receives over WebSocket to mark routines `COMPLETED` in real time.
- **Actionable Notifications:** 30 minutes before a time window closes, the daemon pushes notifications to the Home Assistant Companion app with 1-tap `[Done]` actions.

---

## 3. Directory Layout

```
POS/
├── .github/workflows/               # GitHub Actions CI for Go and Flutter
├── backend/                         # Go 1.26 Sync Daemon & HA Connector
│   ├── cmd/server/main.go           # Daemon Entrypoint
│   ├── internal/
│   │   ├── api/                     # REST handlers, WebSocket pub/sub & CORS
│   │   ├── domain/                  # Entities, Enums & Repository interfaces
│   │   ├── ha/                      # Home Assistant WebSocket client & notifications
│   │   ├── repository/postgres/     # PostgreSQL pgx repository & schema migrations
│   │   └── service/                 # Routine state machine, aggregators & cron
│   └── migrations/                  # PostgreSQL migration SQL files
├── frontend/                        # Flutter Cross-Platform Client
│   ├── android/                     # Kotlin Health Connect & WorkManager bridge
│   ├── lib/
│   │   ├── data/                    # Drift SQLite database, DAOs & Dio sync client
│   │   ├── domain/                  # RoutineItem & HealthDataPoint models
│   │   └── presentation/            # Riverpod providers & 4-Quadrant UI
│   └── test/                        # Flutter unit and widget tests
└── docs/
    ├── openapi.yaml                 # OpenAPI 3.1 REST/Sync specification
    └── superpowers/                 # Architecture design specs & plans
```

---

## 4. Quick Start Guide

### Prerequisites
- **Go:** 1.26.x+
- **Flutter:** 3.44.x+ / Dart 3.12.x+
- **PostgreSQL:** 15+ (for backend persistence)

### 1. Run Backend Daemon
```bash
cd backend

# Configure environment (optional, defaults provided)
export PORT=8080
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=postgres
export POSTGRES_DB=pos_db

# Run tests
go test -v ./...

# Start server
go run ./cmd/server
```

### 2. Run Flutter Client
```bash
cd frontend

# Install dependencies & run tests
flutter pub get
flutter test

# Launch on Android (Emulator or Device)
flutter run -d android

# Launch on macOS Desktop
flutter run -d macos
```

---

## 5. API Documentation

The complete REST & Delta Sync specification is available at [docs/openapi.yaml](docs/openapi.yaml).

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/v1/health` | Service health status |
| `GET` | `/api/v1/routines/quadrants?date=YYYY-MM-DD` | 4-Quadrant time-fenced view |
| `POST` | `/api/v1/routines/complete` | Complete routine item |
| `POST` | `/api/v1/routines/skip` | Skip routine item |
| `POST` | `/api/v1/routines/defer` | Defer routine item to next window |
| `POST` | `/api/v1/sync/push` | Push client mutations |
| `GET` | `/api/v1/sync/pull?since=RFC3339` | Pull remote delta changes |
| `GET` | `/api/v1/ws` | WebSocket pub/sub stream |

---

## 6. License
MIT License
