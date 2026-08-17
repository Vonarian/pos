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
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekdays'), findsOneWidget);
    });
  });
}
