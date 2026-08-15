# Inline Micro-Interactions & SnackBar Elimination Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace intrusive bottom SnackBar banners with responsive in-place visual micro-interactions (spring bounce, smooth color and text transitions, light haptic feedback, and in-place sync state).

**Architecture:** Convert `RoutineItemTile` to a stateful widget managing a spring scale animation (`ScaleTransition` with `Curves.easeOutBack`) and haptic pulse; remove all completion/sync/logging SnackBar popups from `DashboardScreen` and `AnalyticsScreen`.

**Tech Stack:** Flutter / Dart, `flutter_test`, `flutter/services.dart` (HapticFeedback), Material 3.

## Global Constraints
- Maximum file length $\le 200$ lines per non-test file.
- Maximum method length $\le 40$ lines; `build()` methods $\le 50$ lines.
- Test files $\le 400$ lines.
- TDD Red $\rightarrow$ Green $\rightarrow$ Refactor workflow.
- Conventional Commits: `feat(...)`, `test(...)`, `refactor(...)`.

---

### Task 1: Habit Item Spring Scale Animation & Haptic Pulse

**Files:**
- Create: `frontend/test/presentation/widgets/routine_item_tile_test.dart`
- Modify: `frontend/lib/presentation/widgets/routine_item_tile.dart`

**Interfaces:**
- Consumes: `RoutineItem`, `ItemStatus`, `VoidCallback onComplete`, `VoidCallback onRevert`
- Produces: `RoutineItemTile` with `ScaleTransition` spring-bounce on toggle, `AnimatedContainer` background/border, `AnimatedDefaultTextStyle`, and `HapticFeedback.lightImpact()`

- [ ] **Step 1: Write the failing widget test**

```dart
// frontend/test/presentation/widgets/routine_item_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';
import 'package:pos_frontend/presentation/widgets/routine_item_tile.dart';

void main() {
  testWidgets('RoutineItemTile toggles complete and triggers scale animation without snackbars', (tester) async {
    bool completed = false;
    final item = RoutineItem(
      id: 'test-item-1',
      title: 'Take Creatine',
      category: 'NUTRITION',
      window: TimeWindow.morning,
      status: ItemStatus.pending,
      scheduledDate: DateTime.now(),
      targetPlatform: 'MOBILE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoutineItemTile(
            item: item,
            onComplete: () => completed = true,
            onRevert: () {},
            onSkip: () {},
            onDefer: () {},
          ),
        ),
      ),
    );

    expect(find.text('Take Creatine'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(completed, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `cd frontend && flutter test test/presentation/widgets/routine_item_tile_test.dart`  
Expected: PASS/FAIL depending on current structure

- [ ] **Step 3: Implement spring scale animation & haptic feedback**

Update `frontend/lib/presentation/widgets/routine_item_tile.dart` to statefully animate `ScaleTransition` on tap and add `HapticFeedback.lightImpact()`. Keep file $\le 200$ lines.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/presentation/widgets/routine_item_tile_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/presentation/widgets/routine_item_tile.dart frontend/test/presentation/widgets/routine_item_tile_test.dart
git commit -m "feat(habits): add spring-bounce checkmark animation and tactile haptic pulse"
```

---

### Task 2: SnackBar Elimination & In-Place Sync Button Animation

**Files:**
- Modify: `frontend/lib/presentation/screens/dashboard_screen.dart`
- Modify: `frontend/test/presentation/screens/dashboard_screen_test.dart`

**Interfaces:**
- Consumes: `OfflineRoutineRepository`, `RoutineItemProvider`
- Produces: `DashboardScreen` with instant item toggling (no bottom SnackBar) and animated AppBar sync button with rotating icon and temporary checkmark

- [ ] **Step 1: Write/Update the test asserting no SnackBars are shown**

Update `frontend/test/presentation/screens/dashboard_screen_test.dart` to verify that completing an item or triggering sync does not create `SnackBar` widgets in the tree.

- [ ] **Step 2: Run test to verify failure**

Run: `cd frontend && flutter test test/presentation/screens/dashboard_screen_test.dart`  
Expected: FAIL if SnackBar is present

- [ ] **Step 3: Remove habit snackbars & add sync button in-place animation**

In `frontend/lib/presentation/screens/dashboard_screen.dart`:
- Remove `_completeWithUndo` and all `ScaffoldMessenger.of(context).showSnackBar`.
- Update AppBar sync action to rotate during sync and flash `Icons.check_rounded` on completion.

- [ ] **Step 4: Run test to verify it passes**

Run: `cd frontend && flutter test test/presentation/screens/dashboard_screen_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/lib/presentation/screens/dashboard_screen.dart frontend/test/presentation/screens/dashboard_screen_test.dart
git commit -m "refactor(dashboard): eliminate completion snackbars and add in-place sync animation"
```

---

### Task 3: Metric Logger Modal Feedback & SnackBar Elimination

**Files:**
- Modify: `frontend/lib/presentation/screens/analytics_screen.dart`

**Interfaces:**
- Consumes: `OfflineMetricRepository`, `_LogMetricModal`
- Produces: `AnalyticsScreen` with clean in-place modal dismissal (no bottom SnackBar)

- [ ] **Step 1: Update `AnalyticsScreen` to remove SnackBar on log completion**

Remove `ScaffoldMessenger.of(context).showSnackBar` in `_LogMetricModal` save handler.

- [ ] **Step 2: Run all frontend tests**

Run: `cd frontend && flutter test`  
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add frontend/lib/presentation/screens/analytics_screen.dart
git commit -m "refactor(analytics): remove metric logging snackbar in favor of modal dismissal"
```

---

### Task 4: Physical Device Build & Live Verification

**Files:**
- Build & Deploy: `frontend/build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 1: Run static analysis & full test suite**

Run: `cd frontend && flutter analyze --no-fatal-infos && flutter test && cd ../backend && go test ./...`  
Expected: All 0 issues, 100% tests pass.

- [ ] **Step 2: Build & install debug APK on connected phone**

Run: `cd frontend && env FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk && adb shell am start -n com.pos.pos_frontend/.MainActivity`

- [ ] **Step 3: Capture live screenshots and verify visual flow**

Take screenshots showing:
1. Tap habit checkmark $\rightarrow$ spring pop + color change + adherence update without any bottom SnackBar obscuring bottom nav.
2. Tap sync button $\rightarrow$ in-place rotation and checkmark.
3. Tap Log Metric $\rightarrow$ smooth save and return without bottom SnackBar.
