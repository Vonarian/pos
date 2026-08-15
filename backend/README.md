# POS Backend – Go 1.26 Sync Daemon & Home Assistant Relay

[![Go Version](https://img.shields.io/badge/Go-1.26.x-00ADD8?logo=go)](https://go.dev)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL%2015+-336791?logo=postgresql)](https://www.postgresql.org)
[![Home Assistant](https://img.shields.io/badge/Automation-Home%20Assistant-41BDF5?logo=home-assistant)](https://www.home-assistant.io)
[![API Protocol](https://img.shields.io/badge/API-REST%20%2B%20WebSocket-009688)](https://swagger.io/specification/)

> **The high-performance, lightweight synchronization daemon and Home Assistant integration engine for the Personal Operating System (POS).**  
> Centralizes multi-device state synchronization, automated midnight routine rollbacks, normalized time-series health telemetry ingestion, and bidirectional Home Assistant NFC/notification automation.

---

## ⚡ Key Capabilities

### 🔄 1. Delta Sync & Multi-Device State Engine
- **Differential Sync:** `/api/v1/sync/push` and `/api/v1/sync/pull` endpoints process batch mutations with client-generated UUIDs and idempotent upsert clauses (`ON CONFLICT DO UPDATE`).
- **WebSocket Pub/Sub Hub (`/api/v1/ws`):** Broadcasts real-time events (`ROUTINE_COMPLETED`, `ROUTINE_UPDATED`, `METRICS_INGESTED`, `QUADRANT_REFRESH`) to all connected Flutter desktop/mobile clients.

### ⏱️ 2. Routine Lifecycle & Midnight Reset Cron Engine
- **Ticket Lifecycle:** `PENDING` $\rightarrow$ `COMPLETED` | `SKIPPED` | `DEFERRED` | `MISSED`.
- **Automated Midnight Rollover (`00:00` Local):**
  - Uncompleted `PENDING` items from previous days are automatically transitioned to `MISSED`.
  - Accurately preserves historical daily adherence % in time-series logs **without** cluttering the active day's dashboard with backlog rollover debt.
  - Spawns fresh `PENDING` tickets from active `RoutineTemplate` definitions matching the target weekday.

### 🏠 3. Home Assistant Bidirectional Integration
- **Inbound NFC Tag Ingest:**
  - Maintains a persistent WebSocket connection to Home Assistant (`ws://<host>/api/websocket`).
  - Listens for `tag_scanned` events (e.g. physical NFC sticker on supplement container or gym bag).
  - Automatically completes matching routine items and broadcasts real-time updates to connected Flutter clients.
- **Outbound Actionable Notifications:**
  - Monitors closing time-fenced windows (e.g. Bedtime Stack).
  - Dispatches actionable notifications with 1-tap `[Done]` actions to the Home Assistant companion mobile app.

---

## 📂 Internal Directory Architecture

```
backend/
├── cmd/
│   └── server/
│       └── main.go                  # Service entrypoint & graceful shutdown
├── internal/
│   ├── api/
│   │   ├── middleware/              # CORS headers & HTTP logging
│   │   ├── rest/                    # HTTP handlers (Routines, Metrics, Delta Sync)
│   │   │   ├── handler.go
│   │   │   ├── handler_test.go
│   │   │   └── sync_handler.go
│   │   └── ws/                      # WebSocket pub/sub hub & client pumps
│   │       └── hub.go
│   ├── config/                      # Environment variable configuration loader
│   │   └── config.go
│   ├── domain/                      # Domain entities, enums & repository interfaces
│   │   ├── enums.go                 # ItemStatus, TimeWindow, MetricType
│   │   ├── models.go                # RoutineItem, HealthDataPoint, RoutineTemplate
│   │   └── repository.go            # RoutineRepository, HealthMetricRepository
│   ├── ha/                          # Home Assistant connector
│   │   ├── client.go                # Long-lived WebSocket & REST service client
│   │   ├── nfc_listener.go          # Tag scanned event parser & routine dispatcher
│   │   └── notification_sender.go   # Actionable push notification builder
│   ├── repository/
│   │   └── postgres/                # PostgreSQL pgx implementation
│   │       ├── db.go                # Connection pooling (pgxpool)
│   │       ├── routine_repo.go      # Routine CRUD, upserts & midnight reset
│   │       └── metric_repo.go       # Health metric time-series aggregation
│   └── service/                     # Business logic services
│       ├── routine_service.go       # 4-Quadrant view & state transitions
│       ├── metric_service.go        # Telemetry ingestion & aggregation
│       └── cron_service.go          # Midnight reset & daily ticket spawner
├── migrations/                      # PostgreSQL DDL migration scripts
│   ├── 000001_init_schema.up.sql
│   └── 000001_init_schema.down.sql
├── go.mod
└── go.sum
```

---

## ⚙️ Configuration & Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8080` | HTTP & WebSocket server port |
| `POSTGRES_HOST` | `localhost` | PostgreSQL host |
| `POSTGRES_PORT` | `5432` | PostgreSQL port |
| `POSTGRES_USER` | `postgres` | Database user |
| `POSTGRES_PASSWORD` | `postgres` | Database password |
| `POSTGRES_DB` | `pos_db` | Database name |
| `POSTGRES_SSLMODE` | `disable` | PostgreSQL SSL mode (`disable`, `require`, `verify-full`) |
| `HA_HOST` | `""` | Home Assistant host / IP (e.g. `192.168.1.100:8123`) |
| `HA_TOKEN` | `""` | Home Assistant Long-Lived Access Token |

---

## 🛠️ API Reference & Endpoints

Complete OpenAPI 3.1 specification is available in [`docs/openapi.yaml`](../docs/openapi.yaml).

### Key Endpoints

| Method | Route | Description |
|---|---|---|
| `GET` | `/api/v1/health` | Service health status check |
| `GET` | `/api/v1/routines/quadrants?date=YYYY-MM-DD` | Returns 4-quadrant routine items & adherence % |
| `POST` | `/api/v1/routines/complete` | Marks item `COMPLETED` |
| `POST` | `/api/v1/routines/skip` | Marks item `SKIPPED` |
| `POST` | `/api/v1/routines/defer` | Defers item to the next time fence |
| `POST` | `/api/v1/routines` | Creates new routine item |
| `GET` | `/api/v1/metrics/daily-summary?date=YYYY-MM-DD` | Returns aggregate metrics (Steps, Calories, Sleep, Weight) |
| `POST` | `/api/v1/metrics/ingest` | Batch ingests time-series health metrics |
| `POST` | `/api/v1/sync/push` | Delta push from mobile/desktop client |
| `GET` | `/api/v1/sync/pull?since=RFC3339` | Delta pull for syncing changes since timestamp |
| `GET` | `/api/v1/ws` | Real-time WebSocket pub/sub stream |

---

## 🧪 Development & Testing

```bash
cd backend

# Run all unit, service, repository, and REST test suites
go test -v ./...

# Run Go static analysis
go vet ./...

# Build binary
go build -o bin/server ./cmd/server

# Start daemon
go run ./cmd/server
```
