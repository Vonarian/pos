# Habit Editing & Dynamic Recurrence Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement dynamic offline habit recurrence across future dates and complete habit editing & granular deletion capabilities for POS.

**Architecture:** Add `RoutineTemplatesTable` and `RoutineTemplateDao` to Drift SQLite. `OfflineRoutineRepository` dynamically evaluates active templates against the weekday of any requested date (`date.weekday`) to spawn `PENDING` routine tickets on-demand. Habit edits and deletions provide options to apply changes to single occurrences or propagate across all future occurrences and the underlying template.

**Tech Stack:** Flutter, Dart, Drift (SQLite ORM), Riverpod, Flutter Local Notifications.

## Global Constraints
- Target Platforms: Android Physical Device (`R5GL13Y25VH`), Desktop Flutter.
- Strict LoC Limits: Max 200 lines per non-test Dart file, max 40 lines per function, max 50 lines per `build()` method, max 400 lines per test file.
- TDD Red-Green-Refactor: Tests written before implementation.
- Conventional Commits: `feat(...)`, `fix(...)`, `chore(...)`, `test(...)`.

---

### Task 1: Drift Schema & RoutineTemplate DAO

**Files:**
- Create: `frontend/lib/domain/models/routine_template.dart`
- Create: `frontend/lib/data/local/daos/routine_template_dao.dart`
- Modify: `frontend/lib/data/local/database.dart`
- Test: `frontend/test/data/local/routine_template_dao_test.dart`

**Interfaces:**
- Produces: `RoutineTemplate` model, `RoutineTemplateDao` with `getActiveTemplates()`, `upsertTemplate()`, `deactivateTemplate()`, `getTemplateById()`.

- [ ] **Step 1: Write the failing test for RoutineTemplateDao**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `RoutineTemplate` model, `RoutineTemplatesTable`, and `RoutineTemplateDao`**
- [ ] **Step 4: Run `dart run build_runner build --delete-conflicting-outputs`**
- [ ] **Step 5: Run tests and verify they pass**
- [ ] **Step 6: Commit**

---

### Task 2: Dynamic On-Demand Date Spawning Engine

**Files:**
- Modify: `frontend/lib/data/repositories/offline_routine_repository.dart`
- Modify: `frontend/lib/data/local/daos/routine_dao.dart`
- Test: `frontend/test/data/repositories/offline_routine_repository_test.dart`

**Interfaces:**
- Consumes: `RoutineTemplateDao`, `RoutineDao`.
- Produces: `OfflineRoutineRepository.watchRoutinesForDate(date)` and `getRoutinesForDate(date)` that automatically spawn pending habit tickets for matching template weekdays on any selected date (today, tomorrow, future).

- [ ] **Step 1: Write failing tests in `offline_routine_repository_test.dart` for future date spawning**
- [ ] **Step 2: Run tests to verify failure**
- [ ] **Step 3: Implement template-backed habit creation and on-demand date spawning logic**
- [ ] **Step 4: Run tests and verify they pass**
- [ ] **Step 5: Commit**

---

### Task 3: Habit Editing & Granular Deletion Engine

**Files:**
- Modify: `frontend/lib/data/repositories/offline_routine_repository.dart`
- Modify: `frontend/lib/presentation/providers/routine_provider.dart`
- Test: `frontend/test/data/repositories/offline_routine_repository_test.dart`

**Interfaces:**
- Produces: `updateRoutine(RoutineItem item, {bool applyToFuture = true})`, `deleteRoutine(String id, {bool deleteEverywhere = false})`.

- [ ] **Step 1: Write failing tests for updating and deleting habits with `applyToFuture` options**
- [ ] **Step 2: Run tests to verify failure**
- [ ] **Step 3: Implement update and delete propagation logic in repository and provider**
- [ ] **Step 4: Run tests and verify they pass**
- [ ] **Step 5: Commit**

---

### Task 4: UI Edit Sheet & Context Menu Integration

**Files:**
- Create: `frontend/lib/presentation/widgets/edit_routine_sheet.dart`
- Modify: `frontend/lib/presentation/widgets/routine_item_menu.dart`
- Modify: `frontend/lib/presentation/widgets/routine_item_tile.dart`
- Test: `frontend/test/presentation/widgets/edit_routine_sheet_test.dart`
- Test: `frontend/test/presentation/widgets/routine_item_tile_test.dart`

**Interfaces:**
- Produces: `EditRoutineSheet` modal pre-filled with habit data, category dropdown, quadrant window selector, `ReminderPickerSection`, and `applyToFuture` switch.

- [ ] **Step 1: Write failing widget test for `EditRoutineSheet`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement `EditRoutineSheet` and update `RoutineItemMenu`**
- [ ] **Step 4: Run tests and verify they pass**
- [ ] **Step 5: Commit**

---

### Task 5: End-to-End Verification & Live ADB Physical Device Testing

**Files:**
- Test all backend and frontend suites.
- Verify on live physical Android device (`R5GL13Y25VH`).
- Create `walkthrough.md`.

- [ ] **Step 1: Run Go backend tests: `cd backend && go test -v -race ./...`**
- [ ] **Step 2: Run Flutter tests: `cd frontend && flutter test --coverage`**
- [ ] **Step 3: Verify strict LoC ceilings across all Dart files ($\le 200$ LoC)**
- [ ] **Step 4: Build & install APK on Android physical device via ADB**
- [ ] **Step 5: Verify future date navigation (Aug 16) and editing habit on live device**
- [ ] **Step 6: Capture screenshots to artifact directory and update walkthrough**
- [ ] **Step 7: Merge `feat/habit-editing-and-recurring-scheduling` to `dev`**
