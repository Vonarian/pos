# Task 2: SnackBar Elimination & In-Place Sync Button Animation

**Files:**
- Modify: `frontend/lib/presentation/screens/dashboard_screen.dart`
- Modify: `frontend/test/presentation/screens/dashboard_screen_test.dart`

**Interfaces:**
- Consumes: `OfflineRoutineRepository`, `RoutineItemProvider`
- Produces: `DashboardScreen` with instant item toggling (no bottom SnackBar) and animated AppBar sync button with rotating icon and temporary checkmark

**Step 1: Write/Update test asserting no SnackBars are shown**
In `frontend/test/presentation/screens/dashboard_screen_test.dart`, add/update tests verifying:
1. Completing a habit does NOT show a `SnackBar`.
2. Sync button rotates/animates in-place.

**Step 2: Run test to verify failure**
Run: `cd frontend && flutter test test/presentation/screens/dashboard_screen_test.dart`

**Step 3: Remove habit snackbars & add sync button in-place animation**
In `frontend/lib/presentation/screens/dashboard_screen.dart`:
- Remove `_completeWithUndo` and any `ScaffoldMessenger.of(context).showSnackBar` for habit actions.
- Update `onComplete`, `onRevert`, `onSkip`, `onDefer` to call repository methods directly without opening bottom SnackBars.
- Update the AppBar sync action: add an `AnimationController` so when `_isSyncing` is true, the sync icon rotates smoothly (`RotationTransition`). When sync finishes, display `Icons.check_rounded` with `Colors.teal` for 1.2s before returning to idle.
- Keep `dashboard_screen.dart` $\le 200$ lines, methods $\le 40$ lines, `build()` $\le 50$ lines.

**Step 4: Run test to verify it passes**
Run: `cd frontend && flutter test test/presentation/screens/dashboard_screen_test.dart`

**Step 5: Commit**
Commit with Conventional Commits: `refactor(dashboard): eliminate completion snackbars and add in-place sync animation`
