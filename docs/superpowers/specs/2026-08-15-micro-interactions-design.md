# Design Spec: Inline Micro-Interactions & SnackBar Elimination

**Date:** 2026-08-15  
**Scope:** Flutter Frontend (`/frontend`)  
**Status:** Approved  

---

## 1. Overview & Motivation

Bottom `SnackBar` banners for standard daily actions (completing a habit, syncing, logging metrics) introduce unnecessary visual noise, cover bottom navigation elements, and introduce cognitive latency. In modern habit and productivity tracking applications, in-place tactile micro-interactions (spring animations, smooth color transitions, and haptic feedback) provide superior UX and instant affordance without obstructing the screen.

---

## 2. Architecture & Component Design

### 2.1 `RoutineItemTile` (`frontend/lib/presentation/widgets/routine_item_tile.dart`)
- **Stateful Animation Handling**: Convert `RoutineItemTile` to a `StatefulWidget` with a dedicated `AnimationController` and `CurvedAnimation` (`Curves.easeOutBack`, duration 250ms).
- **Checkmark Spring-Pop**:
  - Tapping the checkmark plays forward $\rightarrow$ backward scale bounce (`ScaleTransition` scaling from `1.0` $\rightarrow$ `1.2` $\rightarrow$ `1.0`).
  - Calls `HapticFeedback.lightImpact()` on every toggle.
- **Card Surface Transition**:
  - `AnimatedContainer` (duration 200ms, `Curves.easeInOut`) transitions background color (`Colors.teal.withValues(alpha: 0.08)` when completed vs neutral card color) and border color (`Colors.teal.withValues(alpha: 0.3)` vs divider color).
- **Text Transition**:
  - `AnimatedDefaultTextStyle` (duration 200ms) smoothly applies line-through and text dimming.
- **LoC & Function Limits**: Keep file $\le 200$ lines, `build()` method $\le 50$ lines by extracting the popup menu and category badge into helper sub-widgets if needed.

### 2.2 `DashboardScreen` (`frontend/lib/presentation/screens/dashboard_screen.dart`)
- **Remove Habit SnackBars**: Remove `_completeWithUndo`, `ScaffoldMessenger.of(context).showSnackBar`, and all associated undo snackbars on completion, revert, and skip.
- **In-Place Sync Button Animation**:
  - The top AppBar sync button maintains an `isSyncing` state.
  - When syncing, the `Icon(Icons.sync_rounded)` rotates smoothly (`RotationTransition`).
  - On sync completion, briefly display `Icon(Icons.check_rounded, color: Colors.teal)` for 1.2 seconds before resetting to idle.

### 2.3 `AnalyticsScreen` (`frontend/lib/presentation/screens/analytics_screen.dart`)
- **Remove Metric SnackBar**: Remove `ScaffoldMessenger.of(context).showSnackBar` on manual metric creation.
- **Button Feedback**: `_LogMetricModal` shows a loading/checkmark icon in the "Save Entry" `ElevatedButton` for 300ms before calling `Navigator.pop(context)`.

---

## 3. Verification & Testing

1. **Unit & Widget Tests**:
   - `test/presentation/widgets/routine_item_tile_test.dart`: Test that tapping checkmark invokes `onComplete` / `onRevert` and triggers scale animation without errors.
   - `test/presentation/screens/dashboard_screen_test.dart`: Verify that completing a habit toggles state without triggering `SnackBar` widgets in `tester.widgetList(find.byType(SnackBar))`.
2. **Physical Device Verification (`R5GL13Y25VH`)**:
   - Deploy debug APK to connected phone.
   - Verify tapping checkmark produces visual bounce and smooth color shift.
   - Verify tapping sync button rotates and turns into checkmark.
   - Verify no snackbars appear at the bottom obstructing navigation tabs.
