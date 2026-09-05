# Habit Streaks & Adherence History Design Spec

## Overview
This specification details the architecture and implementation for:
1. **Per-Habit Streak Counters**: For every recurring habit (template-backed routine), compute the current consecutive-completion streak and the all-time best streak directly from retained `RoutineItemsTable` history — no schema changes required.
2. **Weekly Adherence Heatmap**: A trailing 7-day dot-row heatmap per habit showing completed / missed / skipped / not-scheduled days.
3. **Analytics Integration**: A new "Habit Streaks" section on the Analytics screen rendering one streak card per active recurring template, reactive to live DB changes.

---

## 1. Domain Layer — Pure Streak Computation

### 1.1 StreakStats Model (`frontend/lib/domain/models/streak_stats.dart`)
Immutable value object:
```dart
class StreakStats {
  final String templateId;
  final int currentStreak;   // consecutive scheduled-day completions up to today
  final int bestStreak;      // longest run in retained history
  final double completionRate30d;
  final List<DayOutcome> last7Days; // oldest -> newest, ends today
}

enum DayOutcome { completed, missed, skipped, notScheduled }
```

### 1.2 HabitStreakCalculator (same file)
Pure static function: `compute({required String templateId, required List<RoutineItem> history, required DateTime today})`.

**Rules** (history = all items sharing the `templateId`, any status):
1. **Scheduled days** are exactly the dates present in history (the spawner only materializes items on scheduled weekdays).
2. **COMPLETED** extends a streak.
3. **SKIPPED** is neutral: preserves an existing streak but does not extend it.
4. **MISSED / PENDING on past dates** break the streak.
5. **PENDING today** does not break the streak (the day is not over); today contributes nothing until completed.
6. `currentStreak`: walk backwards from today over scheduled days applying rules 2–5.
7. `bestStreak`: maximum run of rule-2-extended streaks across all history.
8. `last7Days`: outcome for each of the 6 days preceding today plus today; absent item ⇒ `notScheduled`.
9. `completionRate30d`: completed ÷ scheduled within the last 30 days inclusive (0.0 when nothing scheduled).

---

## 2. Data Layer

### 2.1 RoutineDao History Query (`frontend/lib/data/local/daos/routine_dao.dart`)
Add focused query + stream (LoC budget respected):
```dart
Future<List<RoutineItemsTableData>> getRoutinesByTemplateId(String templateId);
Stream<List<RoutineItemsTableData>> watchRoutinesByTemplateId(String templateId);
```
Both filter `templateId.equals(templateId)` ordered by `scheduledDate`.

### 2.2 Repository Facade (`OfflineRoutineRepository`)
Thin pass-throughs mapping rows to domain `RoutineItem` via existing `OfflineRoutineMapper`.

### 2.3 No Schema Migration
History retention already satisfies all inputs; `schemaVersion` stays `2`.

---

## 3. Presentation Layer

### 3.1 Provider (`frontend/lib/presentation/providers/streak_provider.dart`)
- `activeTemplatesProvider`: StreamProvider exposing `watchActiveTemplates()`.
- `habitStreakStatsProvider(StreamProvider.family<StreakStats, String>)`: keyed by template id; combines `watchRoutinesByTemplateId` with `HabitStreakCalculator.compute(today: DateTime.now())`.

### 3.2 Widgets (`frontend/lib/presentation/widgets/`)
- **HabitStreakCard**: title row, 🔥 current-streak badge ("N day streak"), best-streak caption, 30-day rate, and a `StreakHeatmapRow`.
- **StreakHeatmapRow**: 7 rounded dots colored by `DayOutcome` (completed = primary, missed = error, skipped = amber, notScheduled = surface variant) with weekday initial labels.
- Both are small focused `StatelessWidget`s (build() ≤ 50 LoC).

### 3.3 Analytics Screen Section
Insert a "Habit Streaks" header + list of `HabitStreakCard`s between the chart area and the quick-log banner. Renders nothing when no active recurring templates exist.

---

## 4. Test & Verification Plan
1. **Unit Tests** (`test/domain/models/streak_stats_test.dart`): table-driven cases for consecutive completions, miss-breaks, skip-neutral, pending-today-neutral, best-streak across gaps, unscheduled days ignored, empty history, 30-day rate boundaries, heatmap outcomes.
2. **DAO Tests** (`test/data/local/routine_dao_history_test.dart`): template-filtered fetch/stream ordering and isolation from other templates.
3. **Provider Test** (`test/presentation/providers/habit_streak_stats_provider_test.dart`): seeded in-memory Drift DB → stats emitted through container.
4. **Widget Tests** (`test/presentation/widgets/habit_streak_card_test.dart`): badge text, best-streak caption, dot count/colors per outcome.
5. **Full Verification**: `flutter analyze && flutter test`; backend untouched (`go test -race ./...` sanity).
6. **Live Device Verification (ADB)**: build/install debug APK, complete habits to grow a streak, open Analytics → Habit Streaks section, screencap and visually verify carousel.
