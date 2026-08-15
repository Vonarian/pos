# Customizable Actionable Reminders & Time Window Nudges Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a local-first, customizable reminder and time-window closing nudge engine with background notification actions (`Mark Done`, `Snooze`, `Skip`) in POS.

**Architecture:** 
- `ReminderConfig` & `WindowSettings` immutable domain models.
- `NativeNotificationService` managing Android notification channels and exact zoned alarms via `flutter_local_notifications` and `timezone`.
- Headless background isolate callback (`@pragma('vm:entry-point') notificationTapBackground`) for instant SQLite mutations.
- Reactive `ReminderSchedulerService` synchronizing active alarms on routine updates, window changes, and device boot.
- Modular presentation widgets (`ReminderPickerSection`, `WindowSettingsSheet`, `RoutineItemTile` reminder badges).

**Tech Stack:** Dart, Flutter 3.x, Riverpod, Drift (SQLite), flutter_local_notifications, timezone, flutter_timezone.

## Global Constraints
- Target platforms: Android / Desktop (macOS/Linux).
- Sound null-safety, 100% offline-first capability.
- Strict LoC Limits: $\le 200$ lines per Dart source file, $\le 40$ lines per function, $\le 50$ lines per `build()` method, $\le 400$ lines per test file.
- Strict TDD (Red $\rightarrow$ Green $\rightarrow$ Refactor) with $\ge 80\%$ test coverage.
- GitFlow Conventional Commits on branch `feat/customizable-actionable-reminders`.

---

### Task 1: Add Notification & Timezone Dependencies and Android Manifest Configurations

**Files:**
- Modify: `frontend/pubspec.yaml`
- Modify: `frontend/android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: Flutter plugins
- Produces: `flutter_local_notifications`, `timezone`, `flutter_timezone` dependencies configured

- [ ] **Step 1: Update `frontend/pubspec.yaml` with required dependencies**

Add `flutter_local_notifications: ^19.0.0`, `timezone: ^0.10.0`, `flutter_timezone: ^3.0.1` under `dependencies`.

- [ ] **Step 2: Run `flutter pub get`**

Run: `cd frontend && flutter pub get`
Expected: Resolution and download of packages without errors.

- [ ] **Step 3: Update `frontend/android/app/src/main/AndroidManifest.xml` with permissions and receivers**

Add:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```
And receiver entries for boot and scheduled notifications.

- [ ] **Step 4: Commit changes**

```bash
git add frontend/pubspec.yaml frontend/pubspec.lock frontend/android/app/src/main/AndroidManifest.xml
git commit -m "chore(notifications): add flutter_local_notifications and android permissions"
```

---

### Task 2: Domain Models — `ReminderConfig` and `WindowSettings` (TDD)

**Files:**
- Create: `frontend/lib/domain/models/reminder_config.dart`
- Create: `frontend/lib/domain/models/window_settings.dart`
- Test: `frontend/test/domain/models/reminder_config_test.dart`
- Test: `frontend/test/domain/models/window_settings_test.dart`

**Interfaces:**
- Consumes: None
- Produces: `ReminderConfig` and `WindowSettings` classes with JSON serialization and validation methods.

- [ ] **Step 1: Write failing tests for `ReminderConfig`**

```dart
// frontend/test/domain/models/reminder_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/reminder_config.dart';

void main() {
  group('ReminderConfig', () {
    test('default constructor provides sensible defaults', () {
      const config = ReminderConfig();
      expect(config.enabled, false);
      expect(config.time, '08:00');
      expect(config.daysOfWeek, isEmpty);
      expect(config.snoozeMinutes, 15);
      expect(config.isDaily, true);
    });

    test('isScheduledForDay returns true for daily or matching day', () {
      const daily = ReminderConfig(enabled: true, daysOfWeek: []);
      expect(daily.isScheduledForDay(DateTime.monday), true);
      expect(daily.isScheduledForDay(DateTime.sunday), true);

      const weekdays = ReminderConfig(enabled: true, daysOfWeek: [1, 2, 3, 4, 5]);
      expect(weekdays.isScheduledForDay(DateTime.wednesday), true);
      expect(weekdays.isScheduledForDay(DateTime.saturday), false);
    });

    test('json serialization roundtrip', () {
      final config = ReminderConfig(
        enabled: true,
        time: '09:30',
        daysOfWeek: [1, 3, 5],
        snoozeMinutes: 10,
        lastSnoozedUntil: DateTime(2026, 8, 15, 9, 40),
      );
      final json = config.toJson();
      final parsed = ReminderConfig.fromJson(json);
      expect(parsed.enabled, config.enabled);
      expect(parsed.time, config.time);
      expect(parsed.daysOfWeek, [1, 3, 5]);
      expect(parsed.snoozeMinutes, 10);
      expect(parsed.lastSnoozedUntil, config.lastSnoozedUntil);
    });
  });
}
```

- [ ] **Step 2: Write failing tests for `WindowSettings`**

```dart
// frontend/test/domain/models/window_settings_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/window_settings.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';

void main() {
  group('WindowSettings', () {
    test('defaults match standard 4 quadrants', () {
      final settings = WindowSettings.defaults();
      expect(settings.morningStartHour, 6);
      expect(settings.morningEndHour, 12);
      expect(settings.afternoonStartHour, 12);
      expect(settings.afternoonEndHour, 18);
      expect(settings.eveningStartHour, 18);
      expect(settings.eveningEndHour, 21);
      expect(settings.nightStartHour, 21);
      expect(settings.nightEndHour, 6);
      expect(settings.nudgeLeadMinutes, 30);
      expect(settings.windowNudgesEnabled, true);
    });

    test('calculateWindow returns correct TimeWindow based on custom hours', () {
      final settings = WindowSettings.defaults();
      expect(settings.calculateWindow(DateTime(2026, 8, 15, 8, 0)), TimeWindow.morning);
      expect(settings.calculateWindow(DateTime(2026, 8, 15, 14, 0)), TimeWindow.afternoon);
      expect(settings.calculateWindow(DateTime(2026, 8, 15, 19, 30)), TimeWindow.evening);
      expect(settings.calculateWindow(DateTime(2026, 8, 15, 23, 0)), TimeWindow.night);
      expect(settings.calculateWindow(DateTime(2026, 8, 15, 4, 0)), TimeWindow.night);
    });

    test('getClosingTime returns correct DateTime today', () {
      final settings = WindowSettings.defaults();
      final date = DateTime(2026, 8, 15);
      final morningClose = settings.getClosingTime(date, TimeWindow.morning);
      expect(morningClose, DateTime(2026, 8, 15, 12, 0));
    });
  });
}
```

- [ ] **Step 3: Run tests to verify failure**

Run: `cd frontend && flutter test test/domain/models/reminder_config_test.dart test/domain/models/window_settings_test.dart`
Expected: Compilation error (types not defined).

- [ ] **Step 4: Implement `ReminderConfig` and `WindowSettings`**

Create `frontend/lib/domain/models/reminder_config.dart` ($\le 200$ lines):
```dart
class ReminderConfig {
  final bool enabled;
  final String time; // "HH:mm"
  final List<int> daysOfWeek; // 1 (Mon) .. 7 (Sun)
  final int snoozeMinutes;
  final DateTime? lastSnoozedUntil;

  const ReminderConfig({
    this.enabled = false,
    this.time = '08:00',
    this.daysOfWeek = const [],
    this.snoozeMinutes = 15,
    this.lastSnoozedUntil,
  });

  bool get isDaily => daysOfWeek.isEmpty || daysOfWeek.length == 7;

  bool isScheduledForDay(int weekday) {
    if (!enabled) return false;
    if (isDaily) return true;
    return daysOfWeek.contains(weekday);
  }

  factory ReminderConfig.fromJson(Map<String, dynamic> json) {
    return ReminderConfig(
      enabled: json['enabled'] as bool? ?? false,
      time: json['time'] as String? ?? '08:00',
      daysOfWeek: (json['days_of_week'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      snoozeMinutes: json['snooze_minutes'] as int? ?? 15,
      lastSnoozedUntil: json['last_snoozed_until'] != null ? DateTime.parse(json['last_snoozed_until'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'time': time,
    'days_of_week': daysOfWeek,
    'snooze_minutes': snoozeMinutes,
    if (lastSnoozedUntil != null) 'last_snoozed_until': lastSnoozedUntil!.toIso8601String(),
  };

  ReminderConfig copyWith({
    bool? enabled,
    String? time,
    List<int>? daysOfWeek,
    int? snoozeMinutes,
    DateTime? lastSnoozedUntil,
  }) {
    return ReminderConfig(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      lastSnoozedUntil: lastSnoozedUntil ?? this.lastSnoozedUntil,
    );
  }
}
```

Create `frontend/lib/domain/models/window_settings.dart` ($\le 200$ lines):
```dart
import 'routine_item.dart';

class WindowSettings {
  final int morningStartHour;
  final int morningEndHour;
  final int afternoonStartHour;
  final int afternoonEndHour;
  final int eveningStartHour;
  final int eveningEndHour;
  final int nightStartHour;
  final int nightEndHour;
  final int nudgeLeadMinutes;
  final bool windowNudgesEnabled;

  const WindowSettings({
    required this.morningStartHour,
    required this.morningEndHour,
    required this.afternoonStartHour,
    required this.afternoonEndHour,
    required this.eveningStartHour,
    required this.eveningEndHour,
    required this.nightStartHour,
    required this.nightEndHour,
    this.nudgeLeadMinutes = 30,
    this.windowNudgesEnabled = true,
  });

  factory WindowSettings.defaults() => const WindowSettings(
    morningStartHour: 6,
    morningEndHour: 12,
    afternoonStartHour: 12,
    afternoonEndHour: 18,
    eveningStartHour: 18,
    eveningEndHour: 21,
    nightStartHour: 21,
    nightEndHour: 6,
    nudgeLeadMinutes: 30,
    windowNudgesEnabled: true,
  );

  TimeWindow calculateWindow(DateTime time) {
    final hour = time.hour;
    if (hour >= morningStartHour && hour < morningEndHour) return TimeWindow.morning;
    if (hour >= afternoonStartHour && hour < afternoonEndHour) return TimeWindow.afternoon;
    if (hour >= eveningStartHour && hour < eveningEndHour) return TimeWindow.evening;
    return TimeWindow.night;
  }

  DateTime getClosingTime(DateTime baseDate, TimeWindow window) {
    switch (window) {
      case TimeWindow.morning:
        return DateTime(baseDate.year, baseDate.month, baseDate.day, morningEndHour, 0);
      case TimeWindow.afternoon:
        return DateTime(baseDate.year, baseDate.month, baseDate.day, afternoonEndHour, 0);
      case TimeWindow.evening:
        return DateTime(baseDate.year, baseDate.month, baseDate.day, eveningEndHour, 0);
      case TimeWindow.night:
        return DateTime(baseDate.year, baseDate.month, baseDate.day, nightEndHour, 0).add(const Duration(days: 1));
    }
  }

  factory WindowSettings.fromJson(Map<String, dynamic> json) => WindowSettings(
    morningStartHour: json['morning_start'] as int? ?? 6,
    morningEndHour: json['morning_end'] as int? ?? 12,
    afternoonStartHour: json['afternoon_start'] as int? ?? 12,
    afternoonEndHour: json['afternoon_end'] as int? ?? 18,
    eveningStartHour: json['evening_start'] as int? ?? 18,
    eveningEndHour: json['evening_end'] as int? ?? 21,
    nightStartHour: json['night_start'] as int? ?? 21,
    nightEndHour: json['night_end'] as int? ?? 6,
    nudgeLeadMinutes: json['nudge_lead_minutes'] as int? ?? 30,
    windowNudgesEnabled: json['window_nudges_enabled'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'morning_start': morningStartHour,
    'morning_end': morningEndHour,
    'afternoon_start': afternoonStartHour,
    'afternoon_end': afternoonEndHour,
    'evening_start': eveningStartHour,
    'evening_end': eveningEndHour,
    'night_start': nightStartHour,
    'night_end': nightEndHour,
    'nudge_lead_minutes': nudgeLeadMinutes,
    'window_nudges_enabled': windowNudgesEnabled,
  };
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd frontend && flutter test test/domain/models/reminder_config_test.dart test/domain/models/window_settings_test.dart`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/domain/models/reminder_config.dart frontend/lib/domain/models/window_settings.dart frontend/test/domain/models/
git commit -m "feat(domain): implement ReminderConfig and WindowSettings models with tests"
```

---

### Task 3: Notification Service & Background Action Callback

**Files:**
- Create: `frontend/lib/data/native/notification_service.dart`
- Create: `frontend/lib/data/native/background_notification_handler.dart`
- Test: `frontend/test/data/native/notification_service_test.dart`

**Interfaces:**
- Consumes: `flutter_local_notifications`, `timezone`, `ReminderConfig`
- Produces: `NativeNotificationService` with methods `initialize()`, `scheduleHabitReminder()`, `scheduleWindowNudge()`, `cancelNotification()`.

- [ ] **Step 1: Write unit tests for notification ID hashing and payload packaging**

Create `frontend/test/data/native/notification_service_test.dart` testing deterministic notification ID generation and action constants (`ACTION_DONE`, `ACTION_SNOOZE`, `ACTION_SKIP`).

- [ ] **Step 2: Run test to verify failure**

Run: `cd frontend && flutter test test/data/native/notification_service_test.dart`
Expected: Fail (missing file).

- [ ] **Step 3: Implement `notification_service.dart` and `background_notification_handler.dart`**

Implement `NativeNotificationService` and `@pragma('vm:entry-point') notificationTapBackground` with Drift DB isolated execution for action clicks.

- [ ] **Step 4: Run tests and verify passing**

Run: `cd frontend && flutter test test/data/native/notification_service_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/data/native/ frontend/test/data/native/
git commit -m "feat(notifications): implement NativeNotificationService and background action handler"
```

---

### Task 4: Reminder Scheduler Engine (TDD)

**Files:**
- Create: `frontend/lib/data/services/reminder_scheduler_service.dart`
- Test: `frontend/test/data/services/reminder_scheduler_service_test.dart`

**Interfaces:**
- Consumes: `NativeNotificationService`, `RoutineItem`, `WindowSettings`, `ReminderConfig`
- Produces: `ReminderSchedulerService` with `syncRemindersForDay()`, `reconcileItem()`, `scheduleWindowNudges()`.

- [ ] **Step 1: Write comprehensive test suite for `ReminderSchedulerService`**

Test scenarios:
1. Pending item with reminder enabled for today in the future schedules alarm.
2. Completed or skipped item cancels alarm.
3. Item for non-active day of week is ignored.
4. Window closing nudge calculates correct warning time ($closing - leadMinutes$) and schedules summary.
5. If 0 items pending in quadrant, window nudge is cancelled.

- [ ] **Step 2: Run tests to verify failure**

Run: `cd frontend && flutter test test/data/services/reminder_scheduler_service_test.dart`
Expected: Fail.

- [ ] **Step 3: Implement `ReminderSchedulerService` ($\le 200$ lines)**

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd frontend && flutter test test/data/services/reminder_scheduler_service_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/data/services/reminder_scheduler_service.dart frontend/test/data/services/
git commit -m "feat(services): implement ReminderSchedulerService with window nudge calculation"
```

---

### Task 5: UI Components — Reminder Picker & Customization Sheets (TDD)

**Files:**
- Create: `frontend/lib/presentation/widgets/reminder_picker_section.dart`
- Create: `frontend/lib/presentation/widgets/window_settings_sheet.dart`
- Modify: `frontend/lib/presentation/widgets/add_routine_sheet.dart`
- Modify: `frontend/lib/presentation/widgets/routine_item_tile.dart`
- Modify: `frontend/lib/presentation/screens/dashboard_screen.dart`
- Test: `frontend/test/presentation/widgets/reminder_picker_section_test.dart`
- Test: `frontend/test/presentation/widgets/window_settings_sheet_test.dart`

**Interfaces:**
- Consumes: `ReminderConfig`, `WindowSettings`, `ReminderSchedulerService`
- Produces: Visual reminder time pickers, active day selector chips, snooze duration selection, window configuration modal, and reminder badges on routine cards.

- [ ] **Step 1: Write widget tests for `ReminderPickerSection` and `WindowSettingsSheet`**

- [ ] **Step 2: Run tests to verify failure**

Run: `cd frontend && flutter test test/presentation/widgets/reminder_picker_section_test.dart`
Expected: Fail.

- [ ] **Step 3: Implement `ReminderPickerSection` and `WindowSettingsSheet` ($\le 200$ lines each, $\le 50$ lines `build()`)**

- [ ] **Step 4: Wire reminder picker into `AddRoutineSheet` and reminder badges into `RoutineItemTile`**

- [ ] **Step 5: Run all widget tests and verify pass**

Run: `cd frontend && flutter test`
Expected: 100% tests green.

- [ ] **Step 6: Commit**

```bash
git add frontend/lib/presentation/ frontend/test/presentation/
git commit -m "feat(ui): add reminder picker section, window settings sheet, and routine item badges"
```

---

### Task 6: Full Integration, Regression Test & ADB Physical Device Verification

**Files:**
- Run backend & frontend test suites
- Deploy APK to physical Android device via ADB

- [ ] **Step 1: Run full test suite with coverage**

```bash
cd backend && go test -v -race ./...
cd ../frontend && flutter test --coverage
```
Expected: All backend and frontend tests pass with $\ge 80\%$ coverage.

- [ ] **Step 2: Build & install APK on connected physical device**

```bash
cd frontend && env FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

- [ ] **Step 3: Verify notification triggers, permission flows, and lockscreen quick actions**

- Wake screen: `adb shell input keyevent KEYCODE_WAKEUP`
- Launch POS: `adb shell am start -n com.example.pos_frontend/.MainActivity`
- Create a habit with an immediate reminder.
- Verify notification heads-up arrival.
- Tap `[Done]` or `[Snooze]` from notification shade.
- Verify SQLite database state and UI update.
- Capture verification screenshot to conversation artifacts directory.

- [ ] **Step 4: Merge to `dev` and verify zero regression**

```bash
git checkout dev
git merge --ff-only feat/customizable-actionable-reminders
cd frontend && flutter test
cd ../backend && go test -v -race ./...
```
