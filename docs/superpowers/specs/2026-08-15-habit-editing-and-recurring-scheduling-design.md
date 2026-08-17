# Habit Editing & Dynamic Recurrence Engine Design Spec

## Overview
This specification details the architecture and implementation for:
1. **Dynamic Offline Habit Recurrence**: Habits automatically schedule and appear on future dates (e.g., Aug 16 and beyond) based on recurring templates and day-of-week rules without requiring active network connectivity or waiting for server cron jobs.
2. **Comprehensive Habit Editing**: Users can edit habit attributes (title, category, quadrant window, dosage/notes, reminder config) with the choice to update either the current occurrence or all future occurrences.
3. **Granular Habit Deletion**: Users can delete either a single occurrence or the recurring habit template entirely.

---

## 1. Architecture & Data Layer

### 1.1 Local SQLite / Drift Schema
Add `RoutineTemplatesTable` to `AppDatabase` in `frontend/lib/data/local/database.dart`:
- `id` (Text, Primary Key)
- `title` (Text)
- `category` (Text)
- `timeWindow` (Text)
- `daysOfWeekJson` (Text, default `'[1,2,3,4,5,6,7]'`)
- `metadataJson` (Text, default `'{}'`)
- `isActive` (Bool, default `true`)
- `updatedAt` (DateTime)
- `createdAt` (DateTime)
- `isSynced` (Bool, default `false`)

### 1.2 RoutineTemplate Domain Model
Define immutable domain model `RoutineTemplate`:
```dart
class RoutineTemplate {
  final String id;
  final String title;
  final String category;
  final TimeWindow timeWindow;
  final List<int> daysOfWeek; // 1 = Monday ... 7 = Sunday
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime updatedAt;
  final DateTime createdAt;
  ...
}
```

### 1.3 On-Demand Future Date Spawning Engine
In `OfflineRoutineRepository`:
- When querying `watchRoutinesForDate(date)` or `getRoutinesForDate(date)`:
  1. Retrieve all active templates from `RoutineTemplateDao`.
  2. Parse the target date's weekday (`date.weekday` where 1 = Mon, 7 = Sun).
  3. Filter templates whose `daysOfWeek` contains `date.weekday`.
  4. Fetch existing `RoutineItem` records for that `scheduledDate`.
  5. For any active matching template without an existing item on that date, spawn a new `PENDING` `RoutineItem` linked via `templateId = template.id`.
  6. Batch upsert the newly spawned items into `RoutineItemsTable`.
  7. Stream / return the unified list of routine items for that date.

---

## 2. Habit Editing & Deletion Flow

### 2.1 UI Entry Points
- In `RoutineItemMenu` (`...` popup menu on `RoutineItemTile`):
  - Add **"Edit Habit"** (`Icons.edit_outlined`).
  - Update **"Delete"** to offer deletion choice if the item belongs to a template:
    - "This Occurrence Only"
    - "All Future Occurrences"

### 2.2 Edit Habit Sheet (`EditRoutineSheet`)
A bottom sheet modal pre-filled with the selected item's data:
- **Title Text Field** (pre-filled with `item.title`)
- **Dosage / Notes Field** (pre-filled with `item.metadata['dosage']`)
- **Category Dropdown** (pre-filled with `item.category`)
- **Time Window Dropdown** (pre-filled with `item.timeWindow`)
- **ReminderPickerSection** (pre-filled with `item.reminderConfig`)
- **Scope Toggle**:
  - `Update all future occurrences` (Switch / Radio, default `true`).
- **Save Action**:
  - If `applyToFuture == true`: updates the parent `RoutineTemplate` in Drift DB + updates current and future uncompleted `RoutineItem` instances.
  - If `applyToFuture == false`: updates only the specific `RoutineItem` for the active `scheduledDate`.
  - Re-triggers `ReminderSchedulerService.syncAll(...)` to update alarm registrations.

---

## 3. Synchronisation & Offline Resilience

1. **Local-First Writes**: All edits and spawned items commit immediately to Drift SQLite.
2. **Daemon Push**:
   - `OfflineRoutineRepository.updateRoutine(...)` pushes modified routines and templates to backend REST API `/v1/sync/push`.
3. **Alarm Sync**:
   - Reschedules exact notifications for updated habit alert times and days.

---

## 4. Test & Verification Plan

1. **Unit & DAO Tests**:
   - `RoutineTemplateDao` CRUD & active template filtering.
   - `OfflineRoutineRepository` on-demand date spawning tests:
     - Verify creating a daily template automatically populates Aug 15, Aug 16, and future dates when queried.
     - Verify weekday filter rules (e.g. habit configured for Mon-Fri does not spawn on Saturday).
   - `OfflineRoutineRepository` edit tests:
     - Verify updating single instance modifies only target date.
     - Verify updating template propagates changes to future dates.
2. **Widget Tests**:
   - `EditRoutineSheet` form pre-population, validation, and submission.
   - `RoutineItemMenu` edit item callback trigger.
   - Date navigation bar switching dates and displaying spawned items.
3. **Live Device Verification (ADB)**:
   - Build & install APK on device.
   - Create habit with reminder on Aug 15.
   - Navigate to Aug 16 $\rightarrow$ verify habit is automatically present with reminder badge.
   - Open popup menu $\rightarrow$ tap "Edit Habit" $\rightarrow$ modify title and reminder time $\rightarrow$ save.
   - Verify modified habit on dashboard and future date.
   - Capture screenshots and present in walkthrough carousel.
