import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioRevenueDashboard extends StatelessWidget {
  const StudioRevenueDashboard({
    required this.totalLabel,
    required this.sourceRows,
    required this.intentRows,
    required this.receiptRows,
    super.key,
  });

  final String totalLabel;
  final List<RevenueDashboardRow> sourceRows;
  final List<RevenueDashboardRow> intentRows;
  final List<RevenueDashboardRow> receiptRows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LoomSpacing.lg),
          decoration: BoxDecoration(
            color: LoomColors.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simulated creator revenue',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: LoomSpacing.sm),
              Text(
                totalLabel,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LoomSpacing.md),
        _BreakdownPanel(
          key: const ValueKey('p6_revenue_by_source'),
          title: 'By source',
          rows: sourceRows,
        ),
        const SizedBox(height: LoomSpacing.md),
        _BreakdownPanel(
          key: const ValueKey('p6_revenue_by_intent'),
          title: 'By session intent',
          rows: intentRows,
        ),
        const SizedBox(height: LoomSpacing.md),
        _BreakdownPanel(
          key: const ValueKey('p6_recent_receipts'),
          title: 'Recent receipts',
          rows: receiptRows,
        ),
      ],
    );
  }
}

class RevenueDashboardRow {
  const RevenueDashboardRow({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;
}

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({required this.title, required this.rows, super.key});

  final String title;
  final List<RevenueDashboardRow> rows;

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
            const Text('No settled rows yet')
          else
            for (final row in rows)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(row.label),
                subtitle: row.subtitle == null ? null : Text(row.subtitle!),
                trailing: Text(
                  row.value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
        ],
      ),
    );
  }
}
