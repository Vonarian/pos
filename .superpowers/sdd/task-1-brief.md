# Task 1: Habit Item Spring Scale Animation & Haptic Pulse

**Files:**
- Create: `frontend/test/presentation/widgets/routine_item_tile_test.dart`
- Modify: `frontend/lib/presentation/widgets/routine_item_tile.dart`

**Interfaces:**
- Consumes: `RoutineItem`, `ItemStatus`, `VoidCallback onComplete`, `VoidCallback onRevert`, `VoidCallback onSkip`, `VoidCallback onDefer`, `VoidCallback? onDelete`
- Produces: `RoutineItemTile` (StatefulWidget) with `ScaleTransition` spring-bounce on toggle (`Curves.easeOutBack`, 250ms), `AnimatedContainer` (200ms) background/border, `AnimatedDefaultTextStyle`, and `HapticFeedback.lightImpact()`

**Step 1: Write widget test**
In `frontend/test/presentation/widgets/routine_item_tile_test.dart`, test that tapping checkmark invokes callbacks and triggers animation without errors or SnackBars.

**Step 2: Run test to verify failure**
Run: `cd frontend && flutter test test/presentation/widgets/routine_item_tile_test.dart`

**Step 3: Implement spring scale animation & haptic feedback**
In `frontend/lib/presentation/widgets/routine_item_tile.dart`:
- Convert to `StatefulWidget` with SingleTickerProviderStateMixin.
- Animate `ScaleTransition` on checkmark tap.
- Add `HapticFeedback.lightImpact()` inside the tap handler.
- Keep file $\le 200$ lines, methods $\le 40$ lines.

**Step 4: Run test to verify it passes**
Run: `cd frontend && flutter test test/presentation/widgets/routine_item_tile_test.dart`

**Step 5: Commit**
Commit with Conventional Commits: `feat(habits): add spring-bounce checkmark animation and tactile haptic pulse`
