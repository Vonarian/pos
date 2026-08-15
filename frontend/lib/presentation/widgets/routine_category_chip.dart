import 'package:flutter/material.dart';

class RoutineCategoryChip extends StatelessWidget {
  final String category;
  final Map<String, dynamic> metadata;

  const RoutineCategoryChip({
    super.key,
    required this.category,
    this.metadata = const {},
  });

  Color _getCategoryColor(String cat) {
    switch (cat.toUpperCase()) {
      case 'MEDS':
        return Colors.teal;
      case 'WORKOUT':
        return Colors.deepOrange;
      case 'NUTRITION':
        return Colors.green;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(category);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: catColor,
            ),
          ),
        ),
        if (metadata['nfc_tag'] != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.nfc_rounded, size: 12, color: Colors.blueGrey.shade400),
          const SizedBox(width: 2),
          Text(
            'NFC',
            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400),
          ),
        ],
      ],
    );
  }
}
