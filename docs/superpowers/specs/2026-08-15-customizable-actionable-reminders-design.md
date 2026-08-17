# Customizable Actionable Reminders & Time Window Nudges Design

## 1. Overview & Motivation
The Personal Operating System (POS) currently tracks habits, medications, and wellness routines in a 4-quadrant time-fence layout (Morning, Mid-Day, Evening, Night). However, users currently have to manually remember to check the app. To make POS a dependable daily driver, this feature adds a **Local-First, Customizable, Actionable Notification & Reminder Engine**.

Users can configure exact reminder times and recurring days for individual habits (e.g., *08:30 AM Creatine on weekdays*), while POS provides an intelligent safety net with customizable time-window closing nudges (e.g. *11:30 AM nudge for remaining Morning items*). Crucially, all notifications feature **direct inline background actions** (`[Mark Done]`, `[Snooze 15m]`, `[Skip]`) that update the local Drift SQLite database immediately without requiring the UI to open.

---

## 2. Core Requirements & Scope

### 2.1 Per-Habit Reminders
- **Exact Time Scheduling:** Custom `HH:mm` trigger time per habit ticket.
- **Recurrence Filtering:** Active days of week (1=Monday .. 7=Sunday, with presets for Daily, Weekdays, Weekends).
- **Snooze Configuration:** Configurable default snooze interval (e.g. 5, 15, 30 minutes).
- **Auto-Reconciliation:** Checking off or skipping a habit immediately cancels its scheduled alarm; deferring it reschedules to the new window or snooze time.

### 2.2 Quadrant Window Nudges
- **Configurable Window Boundaries:** Custom hour ranges for Morning, Mid-Day, Evening, and Night.
- **Intelligent Closing Warnings:** Summary alert fired $N$ minutes (configurable: 15m, 30m, 45m, 60m) before a time window closes if any items remain pending.
- **Auto-Dismissal:** If all items in a quadrant are marked completed, the closing nudge for that quadrant is automatically suppressed.

### 2.3 Inline Actionability (Lockscreen & Notification Shade)
- **`[Mark Done]`:** Background update marking the habit `COMPLETED` in SQLite + queues optimistic sync.
- **`[Snooze]`:** Schedules an exact one-shot alarm for `now + snoozeMinutes`.
- **`[Skip]`:** Background update marking the habit `SKIPPED` in SQLite.

### 2.4 Offline-First & Deterministic Reliability
- Zero reliance on external servers or active network connections.
- Native Android exact alarms (`AlarmManager.setExactAndAllowWhileIdle`) and `RECEIVE_BOOT_COMPLETED` rescheduling.

---

## 3. Architecture & Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Frontend UI                    │
│  [AddRoutineSheet]  [RoutineItemTile]  [WindowSettingsSheet]│
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 OfflineRoutineRepository & DAOs             │
│            (Watches / Mutates Local Drift SQLite DB)        │
└──────────────┬───────────────────────────────▲──────────────┘
               │ Reactive Stream                │ Background
               ▼                                │ Mutation
┌─────────────────────────────────────────┐     │
│       ReminderSchedulerService          │     │
│ (Computes exact alarms & window nudges) │     │
└──────────────┬──────────────────────────┘     │
               ▼                                │
┌─────────────────────────────────────────┐     │
│         NativeNotificationService       │     │
│  - Android Notification Channels        │     │
│  - Scheduled Exact Alarms (zoned)       │     │
│  - Quick Action Buttons                 │     │
└──────────────┬──────────────────────────┘     │
               │ Triggers / User Tap            │
               ▼                                │
┌─────────────────────────────────────────┐     │
│    @pragma('vm:entry-point')            │     │
│    notificationTapBackground            ├─────┘
│    (Headless Isolate DB Action Handler) │
└─────────────────────────────────────────┘
```

---

## 4. Detailed Data Models & Storage

### 4.1 `ReminderConfig` (Embedded in `RoutineItem.metadata['reminder']`)
```dart
class ReminderConfig {
  final bool enabled;
  final String time; // "HH:mm" (24h)
  final List<int> daysOfWeek; // 1 (Mon) .. 7 (Sun), empty = all days
  final int snoozeMinutes; // default 15
  final DateTime? lastSnoozedUntil;

  const ReminderConfig({
    this.enabled = false,
    this.time = '08:00',
    this.daysOfWeek = const [],
    this.snoozeMinutes = 15,
    this.lastSnoozedUntil,
  });

  factory ReminderConfig.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  ReminderConfig copyWith(...);
}
```

### 4.2 `WindowSettings` (Persistent Settings Table / Preferences)
```dart
class WindowSettings {
  final int morningStartHour;   // default 6
  final int morningEndHour;     // default 12
  final int afternoonStartHour; // default 12
  final int afternoonEndHour;   // default 18
  final int eveningStartHour;   // default 18
  final int eveningEndHour;     // default 21
  final int nightStartHour;     // default 21
  final int nightEndHour;       // default 6
  final int nudgeLeadMinutes;   // default 30
  final bool windowNudgesEnabled;// default true

  const WindowSettings({...});
  factory WindowSettings.defaults();
  factory WindowSettings.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

---

## 5. Notification Service & Background Handling

### 5.1 Notification Channels
1. `pos_habit_reminders`:
   - Name: "Habit & Medication Reminders"
   - Importance: `Importance.max` / `Priority.high`
   - Play sound, vibrate, heads-up display.
2. `pos_window_nudges`:
   - Name: "Time Window Closing Alerts"
   - Importance: `Importance.high` / `Priority.high`
   - Play sound, vibrate.

### 5.2 Background Action Dispatcher
```dart
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final actionId = response.actionId;
  final payload = response.payload; // Contains JSON: {"type": "routine", "id": "...", ...}
  if (payload == null) return;
  
  final data = jsonDecode(payload) as Map<String, dynamic>;
  final routineId = data['id'] as String;
  final db = AppDatabase();
  
  try {
    if (actionId == 'ACTION_DONE') {
      await db.routineDao.updateStatus(routineId, 'COMPLETED', DateTime.now());
    } else if (actionId == 'ACTION_SKIP') {
      await db.routineDao.updateStatus(routineId, 'SKIPPED', null);
    } else if (actionId == 'ACTION_SNOOZE') {
      final snoozeMins = data['snoozeMinutes'] as int? ?? 15;
      final targetTime = DateTime.now().add(Duration(minutes: snoozeMins));
      await NativeNotificationService.scheduleSnooze(
        id: routineId,
        title: data['title'] as String,
        targetTime: targetTime,
      );
    }
  } finally {
    await db.close();
  }
}
```

---

## 6. UI & Ergonomics

### 6.1 `AddRoutineSheet` / `EditRoutineSheet`
- Interactive **Reminder Toggle**: Expands time picker, recurrence selector, and snooze presets.
- **Time Picker**: Clean Cupertino/Material time dial with formatted 12h/24h display.
- **Day Selector**: Weekday chips `[M] [T] [W] [T] [F] [S] [S]` with quick buttons (`All`, `Weekdays`, `Weekends`).

### 6.2 `RoutineItemTile`
- Reminder badge: `⏰ 08:30 AM` displayed in sub-line.
- Snoozed indicator: `💤 Snoozed (+15m)` with pulse badge.
- Long-press / context menu includes quick `Snooze (15m)` option.

### 6.3 `WindowSettingsSheet`
- Accessible via dashboard settings gear icon.
- Interactive time window boundary sliders/pickers.
- Nudge lead time selector (`15m`, `30m`, `45m`, `60m`) and toggle.

---

## 7. Quality & Verification Standards

### 7.1 Automated Testing
- **Unit Tests:** `ReminderConfig` parsing, active day calculations, `WindowSettings` boundary evaluations.
- **Scheduler Tests:** Alarm calculation logic, ID collision resistance, cancellation on completion/skip, window nudge suppression.
- **Widget Tests:** `AddRoutineSheet` with reminder toggle, `WindowSettingsSheet` rendering and persistence.

### 7.2 Strict LoC Ceilings (AGENTS.md)
- Non-test Dart files $\le 200$ lines.
- Widget `build()` methods $\le 50$ lines.
- Helper functions $\le 40$ lines.
- Test files $\le 400$ lines.

### 7.3 Live Device Verification (ADB)
- Deploy debug APK to Android device.
- Verify notification permission prompts, heads-up reminder arrival, and 1-tap lockscreen background actions (`Mark Done`, `Snooze`, `Skip`).
- Capture screenshots for verification evidence.
