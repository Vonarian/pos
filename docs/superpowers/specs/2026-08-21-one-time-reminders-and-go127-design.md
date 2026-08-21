# One-Time Reminders & Go 1.27 Upgrade Design Specification

## Overview
This specification details the architecture and implementation for supporting reliable, one-time reminders (e.g. single-occurrence tasks scheduled for tonight or a specific date/time) in POS alongside recurring habit templates, as well as upgrading CI and build pipelines to Go 1.27.0.

---

## 1. Problem Statement & Motivation
Currently:
1. `ReminderConfig` only supports recurring patterns (`daysOfWeek` / daily) and lacks an explicit one-off vs. recurring distinction.
2. `OfflineRoutineSpawner` automatically creates recurring templates for every routine in SQLite, unintentionally turning one-off reminders into daily repeating templates.
3. `ReminderPickerSection` and `AddRoutineSheet` only expose recurring daily/weekday filters without quick presets for one-time alerts (e.g. *Tonight 9:00 PM*, *In 1 hour*).
4. Go was upgraded locally to 1.27.0 in `backend/go.mod`, but CI and release workflows still have legacy references (`1.26.x` in `release.yml`).

---

## 2. Architecture & Design

### 2.1 Domain & Model Architecture
- **`ReminderConfig` (`frontend/lib/domain/models/reminder_config.dart`)**:
  - Add `isRecurring: bool` (default `false` for one-time items, `true` for recurring habits).
  - Add `isOneTime: bool` getter (`!isRecurring`).
  - Maintain backwards-compatible JSON serialization: `is_recurring: bool`.
  - Update `isScheduledForDay(int weekday)`: For recurring items, evaluates day-of-week; for one-time items, returns `true` (the parent `RoutineItem.scheduledDate` determines the exact day).
- **`RoutineItem` (`frontend/lib/domain/models/routine_item.dart`)**:
  - `isRecurring`: Getter returning `reminderConfig?.isRecurring ?? (templateId != null)`.

### 2.2 Routine Spawner Isolation (`OfflineRoutineSpawner`)
- In `frontend/lib/data/repositories/offline_routine_spawner.dart`:
  - When migrating or spawning from active templates, only items with `isRecurring == true` or an explicit non-null `templateId` are converted to/spawned from templates.
  - One-time reminders (`templateId == null && isRecurring == false`) are ignored during template auto-generation, keeping them strictly on their designated `scheduledDate`.

### 2.3 Exact Alarm & Notification Scheduling
- In `frontend/lib/data/services/reminder_scheduler_service.dart`:
  - For one-time items (`isRecurring == false`), verify `item.scheduledDate` matches the target date (e.g. today).
  - Compute trigger `DateTime` using `item.scheduledDate` + `reminderConfig.time`.
  - Trigger exact alarm via `NativeNotificationService.scheduleHabitReminder` when `trigger.isAfter(now)`.
  - Cancel notification when marked done/skipped.

### 2.4 User Interface
- **`ReminderPickerSection` (`frontend/lib/presentation/widgets/reminder_picker_section.dart`)**:
  - Add segmented control: **"One-Time (Once)"** vs **"Repeating Habit"**.
  - If **One-Time**: Provide quick chips:
    - *Tonight 9 PM* (`21:00`)
    - *In 1 Hour* (`now + 1h`)
    - *Custom Time* (Time Picker)
  - If **Repeating**: Daily / Weekdays / Custom Day Chips.
- **`AddRoutineSheet` / `EditRoutineSheet`**:
  - Update to support one-time reminders with default `isRecurring: false` for one-shot tickets.

### 2.5 Go 1.27 CI & Build Verification
- `.github/workflows/ci.yml`: Verified setup-go `1.27.x`.
- `.github/workflows/release.yml`: Update setup-go to `1.27.x`.
- `backend/go.mod`: Confirmed `go 1.27.0`.
- Verify `go test -race ./...` and `go build ./cmd/server` pass cleanly.
