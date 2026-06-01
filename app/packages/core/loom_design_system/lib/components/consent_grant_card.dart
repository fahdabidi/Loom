import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class ConsentGrantCard extends StatelessWidget {
  const ConsentGrantCard({
    required this.creatorName,
    required this.purpose,
    required this.fields,
    required this.valueExchange,
    required this.stateLabel,
    this.onApprove,
    this.onNarrow,
    this.onDeny,
    this.onRevoke,
    super.key,
  });

  final String creatorName;
  final String purpose;
  final List<String> fields;
  final String valueExchange;
  final String stateLabel;
  final VoidCallback? onApprove;
  final VoidCallback? onNarrow;
  final VoidCallback? onDeny;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              CircleAvatar(
                backgroundColor: LoomColors.lilac.withAlpha(34),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: LoomColors.lilac,
                ),
              ),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: LoomSpacing.xs),
                    Text(
                      purpose,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: stateLabel),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.xs,
            runSpacing: LoomSpacing.xs,
            children: [
              for (final field in fields)
                Chip(
                  label: Text(_fieldLabel(field)),
                  side: BorderSide.none,
                  backgroundColor: LoomColors.surfaceAlt,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            valueExchange,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoomColors.mutedInk,
              height: 1.25,
            ),
          ),
          if (onApprove != null ||
              onNarrow != null ||
              onDeny != null ||
              onRevoke != null) ...[
            const SizedBox(height: LoomSpacing.md),
            Wrap(
              spacing: LoomSpacing.sm,
              runSpacing: LoomSpacing.sm,
              children: [
                if (onApprove != null)
                  FilledButton.icon(
                    key: const ValueKey('p7_approve_grant_button'),
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                if (onNarrow != null)
                  FilledButton.tonalIcon(
                    key: const ValueKey('p7_narrow_grant_button'),
                    onPressed: onNarrow,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Narrow'),
                  ),
                if (onDeny != null)
                  OutlinedButton.icon(
                    onPressed: onDeny,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Deny'),
                  ),
                if (onRevoke != null)
                  OutlinedButton.icon(
                    key: const ValueKey('p7_revoke_grant_button'),
                    onPressed: onRevoke,
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Revoke'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _fieldLabel(String field) {
  switch (field) {
    case 'interest_categories':
      return 'Interest categories';
    case 'interest_tokens':
      return 'Interest tokens';
    default:
      return field.replaceAll('_', ' ');
  }
}
