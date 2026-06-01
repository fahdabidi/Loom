import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class SupportedCreatorsView extends StatelessWidget {
  const SupportedCreatorsView({
    required this.totalLabel,
    required this.rows,
    super.key,
  });

  final String totalLabel;
  final List<SupportedCreatorRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p9_supported_creators_view'),
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: LoomColors.surfaceAlt,
                child: Icon(Icons.favorite_rounded, color: LoomColors.coral),
              ),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supported creators',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      totalLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          if (rows.isEmpty)
            const Text(
              'Membership and premium allocations will appear here.',
              style: TextStyle(color: LoomColors.mutedInk),
            )
          else
            for (final row in rows)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text(row.creatorName),
                subtitle: Text(row.reason),
                trailing: Text(
                  row.amountLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
        ],
      ),
    );
  }
}

class SupportedCreatorRow {
  const SupportedCreatorRow({
    required this.creatorName,
    required this.reason,
    required this.amountLabel,
  });

  final String creatorName;
  final String reason;
  final String amountLabel;
}
