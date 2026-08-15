# Task 3: Metric Logger Modal Feedback & SnackBar Elimination

**Files:**
- Modify: `frontend/lib/presentation/screens/analytics_screen.dart`

**Interfaces:**
- Consumes: `OfflineMetricRepository`, `_LogMetricModal`
- Produces: `AnalyticsScreen` with in-place modal dismissal (no bottom SnackBar) and smooth button feedback on entry save

**Step 1: Update `AnalyticsScreen` to remove SnackBar on log completion**
In `frontend/lib/presentation/screens/analytics_screen.dart`:
- Remove `ScaffoldMessenger.of(context).showSnackBar` in `_LogMetricModal`.
- On Save Entry, provide smooth inline feedback on the button (e.g. checkmark icon) for 250ms before calling `Navigator.of(context).pop()`.
- Ensure `analytics_screen.dart` or any extracted widgets adhere to strict LoC rules: files $\le 200$ lines, methods $\le 40$ lines, `build()` $\le 50$ lines.

**Step 2: Run all frontend tests & analyzer**
Run: `cd frontend && flutter analyze --no-fatal-infos && flutter test`

**Step 3: Commit**
Commit with Conventional Commits: `refactor(analytics): remove metric logging snackbar in favor of modal dismissal`
