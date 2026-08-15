import 'package:flutter/material.dart';

import '../../domain/models/reminder_config.dart';
import '../../domain/models/routine_item.dart';
import 'edit_routine_dropdowns.dart';
import 'edit_routine_scope_card.dart';
import 'reminder_picker_section.dart';

class EditRoutineSheet extends StatefulWidget {
  final RoutineItem item;
  final Function(RoutineItem updatedItem, bool applyToFuture) onSave;

  const EditRoutineSheet({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditRoutineSheet> createState() => _EditRoutineSheetState();
}

class _EditRoutineSheetState extends State<EditRoutineSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _dosageController;
  late String _category;
  late TimeWindow _window;
  late ReminderConfig _reminder;
  bool _applyToFuture = true;

  final _categories = const [
    'Meds/Supps',
    'Nutrition',
    'Training',
    'Mobility',
    'Focus',
    'Recovery',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _dosageController = TextEditingController(
      text: widget.item.metadata['dosage']?.toString() ?? '',
    );
    _category =
        _categories.contains(widget.item.category)
            ? widget.item.category
            : _categories.first;
    _window = widget.item.timeWindow;
    _reminder = widget.item.reminderConfig ?? const ReminderConfig();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final meta = Map<String, dynamic>.from(widget.item.metadata);
    final dosage = _dosageController.text.trim();
    if (dosage.isNotEmpty) {
      meta['dosage'] = dosage;
    } else {
      meta.remove('dosage');
    }

    if (_reminder.enabled) {
      meta['reminder'] = _reminder.toJson();
    } else {
      meta.remove('reminder');
    }

    final updated = widget.item.copyWith(
      title: title,
      category: _category,
      timeWindow: _window,
      metadata: meta,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updated, _applyToFuture);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Habit / Medication',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Habit Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage / Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            EditRoutineDropdowns(
              category: _category,
              window: _window,
              categories: _categories,
              onCategoryChanged: (v) => setState(() => _category = v),
              onWindowChanged: (v) => setState(() => _window = v),
            ),
            const SizedBox(height: 12),
            ReminderPickerSection(
              config: _reminder,
              onChanged: (config) => setState(() => _reminder = config),
            ),
            const SizedBox(height: 12),
            EditRoutineScopeCard(
              applyToFuture: _applyToFuture,
              onChanged: (val) => setState(() => _applyToFuture = val),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _handleSave,
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
