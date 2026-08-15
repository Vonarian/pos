# Personal Operating System (POS) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade, local-first Personal Operating System ("Jira for Life") with a Go 1.26 sync daemon, Flutter cross-platform client (Android/Desktop), Drift SQLite local storage, Android Health Connect native bridge, Home Assistant automation relay, and 4-quadrant time-fenced daily execution dashboard.

**Architecture:** Monorepo containing `frontend/` (Flutter 3.x with Drift SQLite and Riverpod 2.x) and `backend/` (Go 1.26 with PostgreSQL persistence, REST endpoints, WebSocket pub/sub hub, and Home Assistant WebSocket client). Delta sync enables offline-first zero-latency mobile execution while centralizing long-term telemetry.

**Tech Stack:**
- **Backend:** Go 1.26, PostgreSQL (pgx/v5 & standard sql), gorilla/websocket, golang-migrate, log/slog.
- **Frontend:** Flutter 3.44.x, Dart 3.12.x, Drift SQLite, Riverpod, Dio, fl_chart, web_socket_channel.
- **Native Android:** Kotlin, AndroidX Health Connect Client (`1.1.0-alpha11+`), AndroidX WorkManager.

## Global Constraints
- Target Go version: `1.26.x`
- Target Flutter version: `3.x` / Dart `3.x`
- Primary database backend: PostgreSQL (with clean repository abstraction)
- Local mobile/desktop database: SQLite via Drift
- Target API contract: REST + WebSocket with JSON DTOs matching the design spec
- All routine items must support 4 time windows: `MORNING`, `AFTERNOON`, `EVENING`, `NIGHT`
- Automated midnight reset transitions pending tickets to `MISSED` for accurate historical analytics without backlog clutter

---

### Task 1: Go Monorepo Scaffolding & Core Domain Models

**Files:**
- Create: `backend/go.mod`
- Create: `backend/internal/domain/enums.go`
- Create: `backend/internal/domain/models.go`
- Create: `backend/internal/domain/repository.go`
- Create: `backend/internal/domain/models_test.go`

**Interfaces:**
- Produces: `domain.ItemStatus`, `domain.TimeWindow`, `domain.MetricType`, `domain.RoutineItem`, `domain.HealthDataPoint`, `domain.RoutineRepository`, `domain.HealthMetricRepository`

- [ ] **Step 1: Write the failing domain models unit tests**

```go
// backend/internal/domain/models_test.go
package domain_test

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/pos/backend/internal/domain"
)

func TestRoutineItemSerialization(t *testing.T) {
	now := time.Now().UTC().Truncate(time.Second)
	item := domain.RoutineItem{
		ID:            "item-123",
		Title:         "Morning Creatine & D3",
		Category:      "MEDS",
		TimeWindow:    domain.WindowMorning,
		ScheduledDate: "2026-08-15",
		Status:        domain.StatusPending,
		Metadata:      map[string]any{"dosage": "5g", "nfc_tag": "med_box_1"},
		UpdatedAt:     now,
		CreatedAt:     now,
	}

	data, err := json.Marshal(item)
	if err != nil {
		t.Fatalf("failed to marshal RoutineItem: %v", err)
	}

	var unmarshaled domain.RoutineItem
	if err := json.Unmarshal(data, &unmarshaled); err != nil {
		t.Fatalf("failed to unmarshal RoutineItem: %v", err)
	}

	if unmarshaled.ID != item.ID || unmarshaled.Status != domain.StatusPending {
		t.Errorf("expected ID %s and status %s, got ID %s and status %s", item.ID, item.Status, unmarshaled.ID, unmarshaled.Status)
	}
}

func TestHealthDataPointValidation(t *testing.T) {
	pt := domain.HealthDataPoint{
		ID:        "dp-1",
		Source:    "health_connect",
		Metric:    domain.MetricSteps,
		Value:     8450,
		Unit:      "count",
		StartTime: time.Now().Add(-1 * time.Hour),
		EndTime:   time.Now(),
		SyncedAt:  time.Now(),
	}

	if err := pt.Validate(); err != nil {
		t.Errorf("expected valid data point, got error: %v", err)
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && go test -v ./internal/domain/...`  
Expected: FAIL (missing packages/types)

- [ ] **Step 3: Write minimal Go domain models and enums**

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && go test -v ./internal/domain/...`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/
git commit -m "feat(backend): scaffold Go module and core domain entities"
```

---

### Task 2: PostgreSQL Migrations & Repository Layer

**Files:**
- Create: `backend/migrations/000001_init_schema.up.sql`
- Create: `backend/migrations/000001_init_schema.down.sql`
- Create: `backend/internal/repository/postgres/db.go`
- Create: `backend/internal/repository/postgres/routine_repo.go`
- Create: `backend/internal/repository/postgres/metric_repo.go`
- Create: `backend/internal/repository/postgres/routine_repo_test.go`

**Interfaces:**
- Consumes: `domain.RoutineItem`, `domain.HealthDataPoint`, `domain.RoutineRepository`, `domain.HealthMetricRepository`
- Produces: `postgres.NewDB`, `postgres.NewRoutineRepository`, `postgres.NewMetricRepository`

- [ ] **Step 1: Write database migration SQL files**
- [ ] **Step 2: Write repository unit/integration tests with in-memory / mock queries**
- [ ] **Step 3: Implement Postgres repository structs with SQL queries**
- [ ] **Step 4: Run repository tests**

Run: `cd backend && go test -v ./internal/repository/postgres/...`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/migrations backend/internal/repository/
git commit -m "feat(backend): add postgres migrations and repository implementations"
```

---

### Task 3: Routine State Engine, Metric Aggregator & Midnight Reset Service

**Files:**
- Create: `backend/internal/service/routine_service.go`
- Create: `backend/internal/service/metric_service.go`
- Create: `backend/internal/service/cron_service.go`
- Create: `backend/internal/service/routine_service_test.go`
- Create: `backend/internal/service/cron_service_test.go`

**Interfaces:**
- Consumes: `domain.RoutineRepository`, `domain.HealthMetricRepository`
- Produces: `service.RoutineService`, `service.MetricService`, `service.CronService`

- [ ] **Step 1: Write failing service tests for time-fence routing and midnight reset**
- [ ] **Step 2: Implement RoutineService, MetricService, and CronService**
- [ ] **Step 3: Run service tests**

Run: `cd backend && go test -v ./internal/service/...`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add backend/internal/service/
git commit -m "feat(backend): add routine state machine, metric aggregator, and midnight reset cron"
```

---

### Task 4: REST API, WebSocket Pub/Sub Hub & Sync Endpoints

**Files:**
- Create: `backend/internal/api/rest/handler.go`
- Create: `backend/internal/api/rest/sync_handler.go`
- Create: `backend/internal/api/ws/hub.go`
- Create: `backend/internal/api/ws/client.go`
- Create: `backend/internal/api/middleware/cors.go`
- Create: `backend/cmd/server/main.go`
- Create: `backend/internal/api/rest/handler_test.go`

**Interfaces:**
- Consumes: `service.RoutineService`, `service.MetricService`, `service.CronService`
- Produces: HTTP Router (`net/http`), WebSocket Handler `/api/v1/ws`, Sync Endpoints `/api/v1/sync/push`, `/api/v1/sync/pull`

- [ ] **Step 1: Write REST endpoint tests with `net/http/httptest`**
- [ ] **Step 2: Implement REST handlers, WebSocket hub, and main server entrypoint**
- [ ] **Step 3: Run API tests**

Run: `cd backend && go test -v ./internal/api/...`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add backend/internal/api backend/cmd/server/
git commit -m "feat(backend): implement REST API, delta sync endpoints, and WebSocket pub/sub hub"
```

---

### Task 5: Home Assistant Integration Engine

**Files:**
- Create: `backend/internal/ha/client.go`
- Create: `backend/internal/ha/nfc_listener.go`
- Create: `backend/internal/ha/notification_sender.go`
- Create: `backend/internal/ha/client_test.go`

**Interfaces:**
- Consumes: `service.RoutineService`
- Produces: `ha.Client`, `ha.StartNFCEventListener`, `ha.SendActionableNotification`

- [ ] **Step 1: Write HA event parsing and dispatch unit tests**
- [ ] **Step 2: Implement Home Assistant WebSocket listener and Notification Sender**
- [ ] **Step 3: Run HA tests**

Run: `cd backend && go test -v ./internal/ha/...`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add backend/internal/ha/
git commit -m "feat(backend): implement Home Assistant WebSocket relay and actionable notifications"
```

---

### Task 6: Flutter Monorepo Scaffolding & Drift SQLite Local Database

**Files:**
- Create: `frontend/pubspec.yaml`
- Create: `frontend/lib/domain/models/routine_item.dart`
- Create: `frontend/lib/domain/models/health_data_point.dart`
- Create: `frontend/lib/data/local/database.dart`
- Create: `frontend/lib/data/local/daos/routine_dao.dart`
- Create: `frontend/lib/data/local/daos/metric_dao.dart`
- Create: `frontend/test/data/local/database_test.dart`

**Interfaces:**
- Produces: `AppDatabase`, `RoutineDao`, `MetricDao`, `RoutineItemDto`, `HealthDataPointDto`

- [ ] **Step 1: Write failing Drift SQLite in-memory database test**
- [ ] **Step 2: Implement Drift database schema and DAOs**
- [ ] **Step 3: Run Flutter Drift database test**

Run: `cd frontend && flutter test test/data/local/database_test.dart`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add frontend/
git commit -m "feat(frontend): scaffold Flutter client and implement Drift SQLite offline database"
```

---

### Task 7: Offline-First Repository, Dio REST & WebSocket Client

**Files:**
- Create: `frontend/lib/data/remote/api_client.dart`
- Create: `frontend/lib/data/remote/ws_client.dart`
- Create: `frontend/lib/data/repositories/offline_routine_repository.dart`
- Create: `frontend/lib/data/repositories/offline_metric_repository.dart`
- Create: `frontend/test/data/repositories/offline_routine_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `ApiClient`, `WsClient`
- Produces: `OfflineRoutineRepository`, `OfflineMetricRepository`

- [ ] **Step 1: Write offline repository synchronization tests**
- [ ] **Step 2: Implement optimistic local updates and background sync queue**
- [ ] **Step 3: Run repository tests**

Run: `cd frontend && flutter test test/data/repositories/`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/data/
git commit -m "feat(frontend): implement offline-first repository with optimistic updates and delta sync"
```

---

### Task 8: Android Native Health Connect Bridge & WorkManager Background Worker

**Files:**
- Create: `frontend/android/app/src/main/kotlin/com/pos/app/health/HealthConnectManager.kt`
- Create: `frontend/android/app/src/main/kotlin/com/pos/app/health/HealthSyncWorker.kt`
- Create: `frontend/android/app/src/main/kotlin/com/pos/app/MainActivity.kt`
- Create: `frontend/android/app/src/main/AndroidManifest.xml`
- Create: `frontend/lib/data/native/health_connect_channel.dart`
- Create: `frontend/test/data/native/health_connect_channel_test.dart`

**Interfaces:**
- Produces: `HealthConnectChannel.checkAvailability()`, `HealthConnectChannel.requestPermissions()`, `HealthConnectChannel.fetchDifferentialChanges()`

- [ ] **Step 1: Write Kotlin HealthConnectManager with `ChangesToken` differential polling & WorkManager worker**
- [ ] **Step 2: Implement Dart MethodChannel bridge with automatic data normalization to `HealthDataPoint`**
- [ ] **Step 3: Run Flutter native channel unit tests**

Run: `cd frontend && flutter test test/data/native/`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add frontend/android/ frontend/lib/data/native/
git commit -m "feat(android): implement Health Connect differential ChangesToken polling and WorkManager sync"
```

---

### Task 9: Presentation Layer: Riverpod State, 4-Quadrant Time-Fenced Dashboard & Telemetry Visualizations

**Files:**
- Create: `frontend/lib/presentation/providers/routine_provider.dart`
- Create: `frontend/lib/presentation/providers/metric_provider.dart`
- Create: `frontend/lib/presentation/widgets/quadrant_card.dart`
- Create: `frontend/lib/presentation/widgets/routine_item_tile.dart`
- Create: `frontend/lib/presentation/widgets/metric_summary_chart.dart`
- Create: `frontend/lib/presentation/screens/dashboard_screen.dart`
- Create: `frontend/lib/main.dart`
- Create: `frontend/test/presentation/screens/dashboard_screen_test.dart`

**Interfaces:**
- Produces: 4-Quadrant dynamic UI (Morning, Mid-Day, Evening, Night) with active time-fence detection, 1-tap complete/skip actions, fl_chart telemetry graphs.

- [ ] **Step 1: Write widget test for 4-quadrant dashboard rendering and item toggling**
- [ ] **Step 2: Implement Riverpod providers and responsive UI widgets**
- [ ] **Step 3: Run widget tests**

Run: `cd frontend && flutter test test/presentation/`  
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add frontend/lib/presentation/ frontend/lib/main.dart frontend/test/presentation/
git commit -m "feat(frontend): implement 4-quadrant time-fenced dashboard and telemetry visualizers"
```

---

### Task 10: CI/CD Workflows, OpenAPI 3.1 Contract & Verification

**Files:**
- Create: `.github/workflows/backend-ci.yml`
- Create: `.github/workflows/frontend-ci.yml`
- Create: `docs/openapi.yaml`
- Create: `README.md`

- [ ] **Step 1: Create GitHub Actions workflows for Go and Flutter CI**
- [ ] **Step 2: Create complete OpenAPI 3.1 YAML specification**
- [ ] **Step 3: Write root README with quickstart, architecture diagram, and deployment instructions**
- [ ] **Step 4: Run full end-to-end verification across Go and Flutter**

Run:
```bash
cd backend && go test -v ./...
cd ../frontend && flutter test
```
Expected: PASS across all test suites.

- [ ] **Step 5: Commit**

```bash
git add .github/ docs/ README.md
git commit -m "ci(all): add GitHub Actions workflows, OpenAPI 3.1 spec, and documentation"
```
