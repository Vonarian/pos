# Personal Operating System (POS) - Architecture & System Design

**Date:** 2026-08-15  
**Target:** Local-First, Low-Cognitive-Load Personal Operating System ("Jira for Life")  
**Platforms:** Android (Primary), macOS, Linux, Web, Windows  
**Backend:** Go 1.26.x Sync Daemon & Home Assistant Relay (PostgreSQL Default)  
**Frontend:** Flutter 3.x / Dart (Drift SQLite, Riverpod, Health Connect Native Bridge)

---

## 1. Executive Summary & Core Objective

The Personal Operating System (POS) is a local-first, low-friction operating system designed to centralize daily routine/habit execution, medication and supplement adherence, caloric/workout telemetry, and long-term goal progression.

### Core Principles
1. **Zero-Lag Offline First:** All day-to-day actions (checking off meds, reviewing time fences, logging habits) execute with zero latency against an embedded SQLite database (via Drift) and sync asynchronously.
2. **Low Cognitive Load ("Jira for Daily Life"):** Routines are time-fenced into four clear daily windows (Morning, Mid-Day, Evening, Bedtime). Tasks reset at midnight automatically without messy rollover backlog accumulation.
3. **Passive Metric Telemetry:** Automated background differential polling from Google Health Connect on Android and Home Assistant auxiliary sensors, with normalized time-series ingestion into PostgreSQL.
4. **Seamless Automation:** Bidirectional Home Assistant integration for physical NFC tag scanning (e.g. pill bottle taps) and actionable notifications for closing windows.

---

## 2. Monorepo Directory Architecture

```
POS/
├── .github/
│   └── workflows/
│       ├── backend-ci.yml           # Go test, lint, vet, build
│       └── frontend-ci.yml          # Flutter test, analyze
├── backend/                         # Go 1.26 Sync Daemon & Home Assistant Relay
│   ├── cmd/
│   │   └── server/
│   │       └── main.go              # Service entrypoint
│   ├── internal/
│   │   ├── config/                  # Environment & configuration loader
│   │   ├── domain/                  # Core domain models, enums & repository interfaces
│   │   ├── repository/
│   │   │   └── postgres/            # PostgreSQL pgx/sqlx repository implementations
│   │   ├── service/                 # Routine state engine, metric aggregator, sync engine
│   │   ├── api/
│   │   │   ├── rest/                # HTTP routing & handlers (Routines, Metrics, Sync)
│   │   │   ├── ws/                  # WebSocket pub/sub hub for real-time state sync
│   │   │   └── middleware/          # Logging, CORS, recovery middleware
│   │   └── ha/                      # Home Assistant WebSocket client & Webhook handler
│   ├── migrations/                  # PostgreSQL schema migration files (.sql)
│   ├── go.mod
│   └── go.sum
├── frontend/                        # Flutter 3.x / Dart Client
│   ├── android/                     # Kotlin platform channel & Health Connect WorkManager
│   │   └── app/src/main/kotlin/com/pos/app/health/
│   │       ├── HealthConnectManager.kt
│   │       └── HealthSyncWorker.kt
│   ├── lib/
│   │   ├── core/                    # App constants, themes, router, network client
│   │   ├── data/
│   │   │   ├── local/               # Drift SQLite DB, DAOs, schema tables
│   │   │   ├── remote/              # Dio REST client, WebSocket listener
│   │   │   └── repositories/        # Offline-first repository implementations
│   │   ├── domain/                  # RoutineItem, HealthMetric, TimeWindow models
│   │   └── presentation/            # Riverpod providers, 4-quadrant UI, metric charts
│   ├── pubspec.yaml
│   └── test/
├── docs/                            # Architecture specs, OpenAPI 3.1 definitions
│   └── openapi.yaml
├── .gitignore
└── README.md
```

---

## 3. Data Models & Schemas

### 3.1 Routine Item (`RoutineItem`)
Represents recurring daily execution items ("tickets").

```go
package domain

import "time"

type ItemStatus string

const (
    StatusPending   ItemStatus = "PENDING"
    StatusCompleted ItemStatus = "COMPLETED"
    StatusSkipped   ItemStatus = "SKIPPED"
    StatusMissed    ItemStatus = "MISSED"
)

type TimeWindow string

const (
    WindowMorning   TimeWindow = "MORNING"    // 06:00 - 12:00
    WindowAfternoon TimeWindow = "AFTERNOON"  // 12:00 - 18:00
    WindowEvening   TimeWindow = "EVENING"    // 18:00 - 21:00
    WindowNight     TimeWindow = "NIGHT"      // 21:00 - 23:59
)

type RoutineItem struct {
    ID            string         `json:"id" db:"id"`
    TemplateID    *string        `json:"template_id,omitempty" db:"template_id"`
    Title         string         `json:"title" db:"title"`
    Category      string         `json:"category" db:"category"` // MEDS, WORKOUT, NUTRITION, HABIT
    TimeWindow    TimeWindow     `json:"time_window" db:"time_window"`
    ScheduledDate string         `json:"scheduled_date" db:"scheduled_date"` // YYYY-MM-DD
    Status        ItemStatus     `json:"status" db:"status"`
    CompletedAt   *time.Time     `json:"completed_at,omitempty" db:"completed_at"`
    Metadata      map[string]any `json:"metadata" db:"metadata"` // e.g. {"dosage": "5g", "nfc_tag": "med_1"}
    UpdatedAt     time.Time      `json:"updated_at" db:"updated_at"`
    CreatedAt     time.Time      `json:"created_at" db:"created_at"`
}
```

### 3.2 Normalized Health Data Point (`HealthDataPoint`)
Time-series metrics ingested from Health Connect or Home Assistant sensors.

```go
package domain

import "time"

type MetricType string

const (
    MetricSteps          MetricType = "STEPS"
    MetricCaloriesBurned MetricType = "CALORIES_BURNED"
    MetricSleepDuration  MetricType = "SLEEP_DURATION"
    MetricWeight         MetricType = "WEIGHT"
    MetricBodyFat        MetricType = "BODY_FAT"
    MetricWorkoutSession MetricType = "WORKOUT_SESSION"
)

type HealthDataPoint struct {
    ID         string     `json:"id" db:"id"`
    Source     string     `json:"source" db:"source"` // "health_connect", "manual", "ha_relay"
    Metric     MetricType `json:"metric" db:"metric"`
    Value      float64    `json:"value" db:"value"`
    Unit       string     `json:"unit" db:"unit"` // "kcal", "minutes", "kg", "count", "%"
    StartTime  time.Time  `json:"start_time" db:"start_time"`
    EndTime    time.Time  `json:"end_time" db:"end_time"`
    ExternalID *string    `json:"external_id,omitempty" db:"external_id"` // Health Connect UID
    SyncedAt   time.Time  `json:"synced_at" db:"synced_at"`
}
```

---

## 4. Subsystem Architectures

### 4.1 Health Connect Ingestion & Delta Sync
1. **Differential Polling:**
   - Android Kotlin Native Bridge uses `androidx.health.connect:connect-client`.
   - `ChangesToken` persists on device to query differential changes on background `WorkManager` ticks (every 15–30 min) and app foreground events (`onResume`).
2. **Deduplication:**
   - Database tables enforce unique constraints on `external_id` with idempotent upsert operations (`ON CONFLICT DO UPDATE`).
3. **Delta Sync Contract:**
   - `POST /api/v1/sync/push`: Client uploads local changes (routines & metrics) with client-generated UUIDs.
   - `GET /api/v1/sync/pull?since={timestamp}`: Client retrieves changes since the last sync cursor.
   - Non-Android clients (macOS/Linux/Web) fetch aggregated time-series summaries from the Go backend via `/api/v1/metrics/daily-summary`.

### 4.2 Routine & Daily Execution State Engine ("Ticket Engine")
1. **Time-Fenced Quadrants:**
   - **Morning Protocol (06:00 – 12:00):** Meds/supplements, hydration, morning mobility.
   - **Mid-Day & Pre-Workout (12:00 – 18:00):** High-protein meal, pre-workout hydration/caffeine.
   - **Evening & Post-Workout (18:00 – 21:00):** Workout session, post-workout nutrition, daily step review.
   - **Night / Bedtime Stack (21:00 – 23:59):** Magnesium/Zinc, screen wind-down, sleep prep.
2. **Midnight Reset Engine:**
   - At `00:00` local time, all `PENDING` items for the previous day transition to `MISSED` in historical logs.
   - New `PENDING` routine tickets are spawned from active templates for the new day (`scheduled_date = today`).
   - Ensures zero rollover clutter while preserving 100% accurate time-series adherence metrics.

### 4.3 Home Assistant Relay
1. **Bidirectional WebSocket Connection:**
   - Go daemon maintains a long-lived `/api/websocket` connection to Home Assistant with automatic reconnection and ping/pong heartbeat.
2. **Inbound NFC Automation:**
   - Tapping an NFC tag (e.g. supplement box) emits a Home Assistant `tag_scanned` event.
   - Go backend matches the tag ID to `metadata.nfc_tag`, marks the routine `COMPLETED`, and publishes real-time WebSocket events to connected Flutter clients.
3. **Outbound Actionable Notifications:**
   - 30 minutes before a time window closes, the Go daemon checks for pending items and dispatches an actionable notification to the Home Assistant mobile companion app (`[Done]` / `[Skip]`).

---

## 5. Error Handling & Testing Strategy

### 5.1 Error Handling & Resilience
- **Offline First:** Drift SQLite transactions ensure local mutations succeed instantly. Sync payloads are queued and flushed when online.
- **Structured Logging:** Go backend utilizes standard library `log/slog` for structured, leveled JSON logging.
- **Graceful Health Connect Fallback:** If permissions are denied or on non-Android platforms, UI smoothly offers manual input and backend-synced aggregates.

### 5.2 Testing Strategy
- **Backend Tests:**
  - Unit tests for routine state transitions, time-fence calculations, and metric aggregation.
  - Mock WebSocket tests for Home Assistant event parsing.
  - HTTP handler tests using `net/http/httptest`.
- **Frontend Tests:**
  - In-memory Drift SQLite tests for database queries and migrations.
  - Riverpod provider unit tests for time-fence state transitions.
  - Widget tests for 4-quadrant views and quick-action buttons.
- **Continuous Integration (CI):**
  - GitHub Actions running `go test -v -race ./...` and `flutter test` on every pull request.

---

## 6. Implementation Phasing

- **Phase 1 (MVP):**
  - Monorepo scaffolding with Flutter frontend and Go backend.
  - Drift SQLite database, Riverpod state management, and 4-quadrant UI.
  - Kotlin Health Connect native channel & WorkManager scaffolding.
  - Go sync daemon REST & WebSocket endpoints with PostgreSQL persistence.
  - Midnight reset cron and daily template generation.
- **Phase 2 (Sync & Multi-Platform):**
  - Bidirectional delta-sync between Flutter Drift and Go PostgreSQL.
  - Desktop (macOS/Linux) fallback mode consuming Go daemon summary APIs.
- **Phase 3 (Home Assistant & Analytics):**
  - Home Assistant WebSocket client, NFC event ingestion, and actionable notification egress.
  - Weekly aggregation reports (caloric trends, routine adherence %, sleep vs. workout correlation).
