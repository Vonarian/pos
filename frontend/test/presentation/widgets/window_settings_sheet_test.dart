import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_frontend/domain/models/window_settings.dart';
import 'package:pos_frontend/presentation/widgets/window_settings_sheet.dart';

void main() {
  group('WindowSettingsSheet', () {
    testWidgets('renders window settings controls and save button', (
      tester,
    ) async {
      WindowSettings? savedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WindowSettingsSheet(
              initialSettings: WindowSettings.defaults(),
              onSave: (settings) {
                savedSettings = settings;
              },
            ),
          ),
        ),
      );

      expect(find.text('Window & Reminder Settings'), findsOneWidget);
      expect(find.text('Time-Window Closing Nudges'), findsOneWidget);
      expect(find.text('Save Configuration'), findsOneWidget);

      await tester.tap(find.text('Save Configuration'));
      await tester.pumpAndSettle();

      expect(savedSettings, isNotNull);
      expect(savedSettings!.nudgeLeadMinutes, 30);
    });
  });
}
