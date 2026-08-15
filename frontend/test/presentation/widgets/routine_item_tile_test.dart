import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/routine_item.dart';
import 'package:pos_frontend/presentation/widgets/routine_item_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RoutineItem buildItem({
    String id = 'item-1',
    String title = 'Morning Meditation',
    String category = 'MINDFULNESS',
    ItemStatus status = ItemStatus.pending,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return RoutineItem(
      id: id,
      title: title,
      category: category,
      timeWindow: TimeWindow.morning,
      scheduledDate: '2026-08-15',
      status: status,
      metadata: metadata,
      updatedAt: now,
      createdAt: now,
    );
  }

  group('RoutineItemTile', () {
    final List<MethodCall> hapticCalls = [];

    setUp(() {
      hapticCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          hapticCalls.add(call);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('renders item title, category badge, and dosage info', (
      WidgetTester tester,
    ) async {
      final item = buildItem(
        title: 'Vitamin D3',
        category: 'MEDS',
        metadata: {'dosage': '5000 IU'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineItemTile(
              item: item,
              onComplete: () {},
              onRevert: () {},
              onSkip: () {},
              onDefer: () {},
            ),
          ),
        ),
      );

      expect(find.text('Vitamin D3'), findsOneWidget);
      expect(find.text('MEDS'), findsOneWidget);
      expect(find.text('Dosage: 5000 IU'), findsOneWidget);
      expect(
        find.byKey(const Key('routine_tile_scale_transition')),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping checkmark triggers spring scale animation, haptics, and onComplete',
      (WidgetTester tester) async {
        var completed = false;
        final item = buildItem(title: 'Drink Water');

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

        final scaleFinder = find.byKey(
          const Key('routine_tile_scale_transition'),
        );
        expect(scaleFinder, findsOneWidget);

        final scaleWidgetBefore = tester.widget<ScaleTransition>(scaleFinder);
        expect(scaleWidgetBefore.scale.value, equals(1.0));

        // Tap the action button / checkmark
        await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
        await tester.pump(); // Start animation

        expect(completed, isTrue);
        expect(hapticCalls.isNotEmpty, isTrue);
        expect(
          hapticCalls.first.arguments,
          equals('HapticFeedbackType.lightImpact'),
        );

        // Mid-animation: scale is transitioning
        await tester.pump(const Duration(milliseconds: 125));
        final scaleWidgetMid = tester.widget<ScaleTransition>(scaleFinder);
        expect(scaleWidgetMid.scale.value, isNot(equals(1.0)));

        // Settle animation
        await tester.pumpAndSettle();
        final scaleWidgetAfter = tester.widget<ScaleTransition>(scaleFinder);
        expect(scaleWidgetAfter.scale.value, equals(1.0));
      },
    );

    testWidgets('tapping tile when completed triggers onRevert and haptic pulse', (
      WidgetTester tester,
    ) async {
      var reverted = false;
      final item = buildItem(
        title: 'Morning Run',
        status: ItemStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineItemTile(
              item: item,
              onComplete: () {},
              onRevert: () => reverted = true,
              onSkip: () {},
              onDefer: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check_circle_rounded));
      await tester.pumpAndSettle();

      expect(reverted, isTrue);
      expect(hapticCalls.isNotEmpty, isTrue);
      expect(
        hapticCalls.first.arguments,
        equals('HapticFeedbackType.lightImpact'),
      );
    });

    testWidgets('renders NFC badge when metadata has nfc_tag', (
      WidgetTester tester,
    ) async {
      final item = buildItem(
        title: 'Scan Gym Badge',
        metadata: {'nfc_tag': 'tag_gym_123'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineItemTile(
              item: item,
              onComplete: () {},
              onRevert: () {},
              onSkip: () {},
              onDefer: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.nfc_rounded), findsOneWidget);
      expect(find.text('NFC'), findsOneWidget);
    });

    testWidgets('popup menu triggers defer, skip, and delete callbacks', (
      WidgetTester tester,
    ) async {
      var deferred = false;
      var skipped = false;
      var deleted = false;
      final item = buildItem(title: 'Read 20 mins');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutineItemTile(
              item: item,
              onComplete: () {},
              onRevert: () {},
              onSkip: () => skipped = true,
              onDefer: () => deferred = true,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Defer to Next Window'), findsOneWidget);
      expect(find.text('Skip for Today'), findsOneWidget);
      expect(find.text('Delete Habit'), findsOneWidget);

      // Tap Defer
      await tester.tap(find.text('Defer to Next Window'));
      await tester.pumpAndSettle();
      expect(deferred, isTrue);

      // Open popup menu again and tap Skip
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip for Today'));
      await tester.pumpAndSettle();
      expect(skipped, isTrue);

      // Open popup menu again and tap Delete
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Habit'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });
}
