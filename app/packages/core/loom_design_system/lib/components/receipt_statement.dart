import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class ReceiptStatement extends StatelessWidget {
  const ReceiptStatement({
    required this.title,
    required this.rows,
    this.emptyLabel = 'No receipts yet',
    super.key,
  });

  final String title;
  final List<ReceiptStatementRow> rows;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          if (rows.isEmpty)
            Text(emptyLabel, style: const TextStyle(color: LoomColors.mutedInk))
          else
            for (final row in rows)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(row.icon),
                title: Text(row.title),
                subtitle: Text(row.subtitle),
                trailing: row.trailing == null
                    ? null
                    : Text(
                        row.trailing!,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
        ],
      ),
    );
  }
}

class ReceiptStatementRow {
  const ReceiptStatementRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
}
