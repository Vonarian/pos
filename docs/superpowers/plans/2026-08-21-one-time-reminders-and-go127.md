# One-Time Reminders & Go 1.27 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement reliable one-time reminders for tonight/specific dates without polluting recurring templates, add fast UI presets, and verify Go 1.27 CI/CD builds.

**Architecture:** Extend `ReminderConfig` with `isRecurring: bool`, isolate `OfflineRoutineSpawner` from auto-templating one-off tickets, update `ReminderSchedulerService` for single-day exact notifications, add segmented Once vs Recurring UI in `ReminderPickerSection`, and update `.github/workflows/release.yml` for Go 1.27.x.

**Tech Stack:** Dart, Flutter, Drift SQLite, flutter_local_notifications, Go 1.27, GitHub Actions.

## Global Constraints
- Maximum 200 LoC per non-test Dart/Go source file.
- Maximum 40 LoC per function/method.
- Maximum 50 LoC per Flutter widget `build()` method.
- Follow TDD: Red -> Green -> Refactor.

---

### Task 1: Go 1.27 CI & Build Verification
**Files:**
- Modify: `.github/workflows/release.yml:161`
- Test: `backend/cmd/server/main.go`

- [ ] **Step 1: Update Go version in `release.yml`**
- [ ] **Step 2: Run Go vet, race test, and build locally**
  Run: `cd backend && go vet ./... && go test -v -race ./... && go build -v -o bin/server ./cmd/server`
  Expected: PASS

---

### Task 2: ReminderConfig Model & Unit Tests (TDD)
**Files:**
- Test: `frontend/test/domain/models/reminder_config_test.dart`
- Modify: `frontend/lib/domain/models/reminder_config.dart`

- [ ] **Step 1: Write failing unit tests for `ReminderConfig` with `isRecurring`**
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/domain/models/reminder_config_test.dart`
  Expected: FAIL
- [ ] **Step 3: Update `ReminderConfig` implementation**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/domain/models/reminder_config_test.dart`
  Expected: PASS

---

### Task 3: Spawner & Routine Isolation (TDD)
**Files:**
- Test: `frontend/test/data/repositories/offline_routine_spawner_test.dart`
- Modify: `frontend/lib/data/repositories/offline_routine_spawner.dart`

- [ ] **Step 1: Write failing test verifying one-off items do not create templates or duplicate**
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/data/repositories/offline_routine_spawner_test.dart`
  Expected: FAIL
- [ ] **Step 3: Update `OfflineRoutineSpawner` to ignore one-time items**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/data/repositories/offline_routine_spawner_test.dart`
  Expected: PASS

---

### Task 4: Reminder Scheduler Service Exact Trigger (TDD)
**Files:**
- Test: `frontend/test/data/services/reminder_scheduler_service_test.dart`
- Modify: `frontend/lib/data/services/reminder_scheduler_service.dart`

- [ ] **Step 1: Write failing test for one-off reminder trigger calculation on matching date**
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/data/services/reminder_scheduler_service_test.dart`
  Expected: FAIL
- [ ] **Step 3: Update `ReminderSchedulerService`**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/data/services/reminder_scheduler_service_test.dart`
  Expected: PASS

---

### Task 5: UI ReminderPickerSection & Add/Edit Routine Sheets
**Files:**
- Test: `frontend/test/presentation/widgets/reminder_picker_section_test.dart`
- Modify: `frontend/lib/presentation/widgets/reminder_picker_section.dart`
- Modify: `frontend/lib/presentation/widgets/add_routine_sheet.dart`
- Modify: `frontend/lib/presentation/widgets/edit_routine_sheet.dart`

- [ ] **Step 1: Write failing widget test for Once/Tonight presets and Recurring mode**
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/presentation/widgets/reminder_picker_section_test.dart`
  Expected: FAIL
- [ ] **Step 3: Implement segmented UI and quick preset buttons**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/presentation/widgets/reminder_picker_section_test.dart`
  Expected: PASS

---

### Task 6: Full Verification & ADB Live Test on `R5GL13Y25VH`
- [ ] **Step 1: Run full test suites and linter**
  Run: `cd backend && go test -race ./... && cd ../frontend && flutter analyze && flutter test`
- [ ] **Step 2: Build & install debug APK on `R5GL13Y25VH`**
- [ ] **Step 3: Create one-time reminder for tonight via app UI**
- [ ] **Step 4: Capture screencap, verify visually with `view_file`, and present verification carousel**
