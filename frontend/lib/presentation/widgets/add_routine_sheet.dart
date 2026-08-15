import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/routine_item.dart';
import '../providers/routine_provider.dart';

class AddRoutineSheet extends StatefulWidget {
  final WidgetRef ref;
  final String date;

  const AddRoutineSheet({super.key, required this.ref, required this.date});

  static Future<void> show(BuildContext context, WidgetRef ref, String date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddRoutineSheet(ref: ref, date: date),
    );
  }

  @override
  State<AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<AddRoutineSheet> {
  final _titleController = TextEditingController();
  final _dosageController = TextEditingController();
  String _category = 'MEDS';
  TimeWindow _window = TimeWindow.morning;

  @override
  void dispose() {
    _titleController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final repo = widget.ref.read(offlineRoutineRepositoryProvider);
    final now = DateTime.now();
    final item = RoutineItem(
      id: const Uuid().v4(),
      title: title,
      category: _category,
      timeWindow: _window,
      scheduledDate: widget.date,
      status: ItemStatus.pending,
      metadata: _dosageController.text.isNotEmpty
          ? {'dosage': _dosageController.text.trim()}
          : {},
      updatedAt: now,
      createdAt: now,
    );

    await repo.createRoutine(item);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'MEDS', child: Text('Meds/Supps')),
        DropdownMenuItem(value: 'WORKOUT', child: Text('Workout')),
        DropdownMenuItem(value: 'NUTRITION', child: Text('Nutrition')),
        DropdownMenuItem(value: 'HABIT', child: Text('Habit')),
      ],
      onChanged: (val) => setState(() => _category = val ?? 'MEDS'),
    );
  }

  Widget _buildWindowDropdown() {
    return DropdownButtonFormField<TimeWindow>(
      initialValue: _window,
      decoration: const InputDecoration(
        labelText: 'Time Window',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: TimeWindow.morning, child: Text('Morning')),
        DropdownMenuItem(value: TimeWindow.afternoon, child: Text('Mid-Day')),
        DropdownMenuItem(value: TimeWindow.evening, child: Text('Evening')),
        DropdownMenuItem(value: TimeWindow.night, child: Text('Night')),
      ],
      onChanged: (val) => setState(() => _window = val ?? TimeWindow.morning),
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Habit Title',
            hintText: 'e.g. Creatine 5g, Zone 2 Cardio',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dosageController,
          decoration: const InputDecoration(
            labelText: 'Dosage / Notes (Optional)',
            hintText: 'e.g. 5g with water, NFC shelf',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCategoryDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _buildWindowDropdown()),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Daily Habit / Medication',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInputs(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveRoutine,
              child: const Text('Save Ticket', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

