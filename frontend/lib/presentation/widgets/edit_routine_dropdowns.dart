import 'package:flutter/material.dart';

import '../../domain/models/routine_item.dart';

class EditRoutineDropdowns extends StatelessWidget {
  final String category;
  final TimeWindow window;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<TimeWindow> onWindowChanged;

  const EditRoutineDropdowns({
    super.key,
    required this.category,
    required this.window,
    required this.categories,
    required this.onCategoryChanged,
    required this.onWindowChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) onCategoryChanged(v);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<TimeWindow>(
            initialValue: window,
            decoration: const InputDecoration(
              labelText: 'Time Window',
              border: OutlineInputBorder(),
            ),
            items: TimeWindow.values
                .map(
                  (w) => DropdownMenuItem(
                    value: w,
                    child: Text(w.name[0].toUpperCase() + w.name.substring(1)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onWindowChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
