import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/reminder_config.dart';
import 'package:pos_frontend/presentation/widgets/reminder_picker_section.dart';

void main() {
  group('ReminderPickerSection', () {
    testWidgets('renders toggle switch and expands options when enabled', (
      tester,
    ) async {
      ReminderConfig currentConfig = const ReminderConfig(enabled: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReminderPickerSection(
                  config: currentConfig,
                  onChanged: (newConfig) {
                    setState(() {
                      currentConfig = newConfig;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Set Reminder Alert'), findsOneWidget);
      expect(find.text('08:00'), findsNothing);

      // Toggle switch to true
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(currentConfig.enabled, true);
      expect(find.text('Once / Tonight'), findsOneWidget);
      expect(find.text('Repeating Habit'), findsOneWidget);
      expect(find.text('Tonight 9 PM'), findsOneWidget);
    });

    testWidgets('tapping Tonight 9 PM preset updates time to 21:00', (
      tester,
    ) async {
      ReminderConfig currentConfig = const ReminderConfig(
        enabled: true,
        isRecurring: false,
        time: '08:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReminderPickerSection(
                  config: currentConfig,
                  onChanged: (newConfig) {
                    setState(() {
                      currentConfig = newConfig;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tonight 9 PM'), findsOneWidget);
      await tester.tap(find.text('Tonight 9 PM'));
      await tester.pumpAndSettle();

      expect(currentConfig.time, '21:00');
      expect(currentConfig.isRecurring, false);
    });

    testWidgets('switching to Repeating Habit shows Daily and Weekdays chips', (
      tester,
    ) async {
      ReminderConfig currentConfig = const ReminderConfig(
        enabled: true,
        isRecurring: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ReminderPickerSection(
                  config: currentConfig,
                  onChanged: (newConfig) {
                    setState(() {
                      currentConfig = newConfig;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Repeating Habit'), findsOneWidget);
      await tester.tap(find.text('Repeating Habit'));
      await tester.pumpAndSettle();

      expect(currentConfig.isRecurring, true);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekdays'), findsOneWidget);
    });
  });
}
