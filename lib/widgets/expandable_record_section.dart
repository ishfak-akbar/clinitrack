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

  IconData _getIcon() {
    switch (title) {
      case 'Prescriptions':
        return Icons.medication_outlined;
      case 'Visit History':
        return Icons.history_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accent = isDark
        ? AppColors.primaryTealAccent
        : AppColors.primaryTeal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: accent.withValues(
            alpha: isDark ? 0.25 : 0.15,
          ),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        childrenPadding: EdgeInsets.zero,
        collapsedIconColor: AppColors.iconGray,
        iconColor: accent,

        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(
              alpha: isDark ? 0.15 : 0.10,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIcon(),
            color: accent,
            size: 22,
          ),
        ),

        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        subtitle: Text(
          items.isEmpty
              ? 'No records available'
              : '${items.length} record${items.length == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall,
        ),

        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: accent.withValues(
              alpha: isDark ? 0.18 : 0.10,
            ),
          ),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 19,
                    color: AppColors.iconGray,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No ${title.toLowerCase()} recorded yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: items.map((item) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: isDark ? 0.08 : 0.05,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}