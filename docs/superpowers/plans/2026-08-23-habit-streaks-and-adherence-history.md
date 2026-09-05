# Habit Streaks & Adherence History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Compute and surface per-habit current/best streaks, 30-day completion rate, and a trailing 7-day adherence heatmap for recurring habits, integrated into the Analytics screen.

**Architecture:** Pure domain calculator over retained `RoutineItemsTable` history (no schema change), new template-scoped DAO queries, Riverpod family stream provider, two focused widgets embedded in Analytics.

**Tech Stack:** Dart, Flutter, Drift SQLite, flutter_riverpod.

## Global Constraints
- Maximum 200 LoC per non-test Dart/Go source file.
- Maximum 40 LoC per function/method.
- Maximum 50 LoC per Flutter widget `build()` method.
- Follow TDD: Red -> Green -> Refactor.

---

### Task 1: StreakStats Model & Calculator Unit Tests (TDD)
**Files:**
- Test: `frontend/test/domain/models/streak_stats_test.dart`
- Modify (create): `frontend/lib/domain/models/streak_stats.dart`

- [ ] **Step 1: Write failing table-driven unit tests** covering consecutive completions, missed-breaks-streak, skipped-neutral, pending-today-neutral, best streak across gaps, unscheduled-day heatmap outcome, empty history, and 30-day rate boundaries
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/domain/models/streak_stats_test.dart`
  Expected: FAIL
- [ ] **Step 3: Implement `DayOutcome`, `StreakStats`, `HabitStreakCalculator.compute`**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/domain/models/streak_stats_test.dart`
  Expected: PASS

---

### Task 2: Template-Scoped History Queries (TDD)
**Files:**
- Test: `frontend/test/data/local/routine_dao_history_test.dart`
- Modify: `frontend/lib/data/local/daos/routine_dao.dart`
- Modify: `frontend/lib/data/repositories/offline_routine_repository.dart`

- [ ] **Step 1: Write failing in-memory DB tests for `getRoutinesByTemplateId` / `watchRoutinesByTemplateId`** (filter isolation + date ordering)
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/data/local/routine_dao_history_test.dart`
  Expected: FAIL
- [ ] **Step 3: Add DAO queries + repository pass-throughs**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/data/local/routine_dao_history_test.dart`
  Expected: PASS

---

### Task 3: Streak Provider (TDD)
**Files:**
- Test: `frontend/test/presentation/providers/habit_streak_stats_provider_test.dart`
- Modify (create): `frontend/lib/presentation/providers/streak_provider.dart`

- [ ] **Step 1: Write failing provider test** seeding an in-memory DB override and asserting emitted `StreakStats` react to completion updates
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/presentation/providers/habit_streak_stats_provider_test.dart`
  Expected: FAIL
- [ ] **Step 3: Implement `activeTemplatesProvider` and `habitStreakStatsProvider` family**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/presentation/providers/habit_streak_stats_provider_test.dart`
  Expected: PASS

---

### Task 4: Streak Widgets & Analytics Integration (TDD)
**Files:**
- Test: `frontend/test/presentation/widgets/habit_streak_card_test.dart`
- Modify (create): `frontend/lib/presentation/widgets/streak_heatmap_row.dart`
- Modify (create): `frontend/lib/presentation/widgets/habit_streak_card.dart`
- Modify: `frontend/lib/presentation/screens/analytics_screen.dart`

- [ ] **Step 1: Write failing widget tests** (streak badge text, best caption, dot count/colors per `DayOutcome`)
- [ ] **Step 2: Run test to verify it fails**
  Run: `cd frontend && flutter test test/presentation/widgets/habit_streak_card_test.dart`
  Expected: FAIL
- [ ] **Step 3: Implement widgets and embed "Habit Streaks" section in AnalyticsScreen**
- [ ] **Step 4: Run test to verify it passes**
  Run: `cd frontend && flutter test test/presentation/widgets/habit_streak_card_test.dart`
  Expected: PASS

---

### Task 5: Full Verification & ADB Live Test
- [ ] **Step 1: Run full test suites and linter**
  Run: `cd backend && go test -race ./... && cd ../frontend && flutter analyze && flutter test`
- [ ] **Step 2: Build & install debug APK on attached device**
- [ ] **Step 3: Complete habits across days via app UI to grow a streak; open Analytics -> Habit Streaks**
- [ ] **Step 4: Capture screencap, verify visually with `view_file`, and present verification carousel**