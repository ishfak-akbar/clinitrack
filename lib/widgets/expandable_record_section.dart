import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ExpandableRecordSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const ExpandableRecordSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        collapsedIconColor: AppColors.iconGray,
        iconColor: AppColors.primaryTeal,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: items.isEmpty
            ? [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('No records yet', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ]
            : items
            .map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 6, color: AppColors.textLight),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}