import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioExtensionInstallSheet extends StatelessWidget {
  const StudioExtensionInstallSheet({
    required this.name,
    required this.riskTier,
    required this.permissions,
    required this.surfaces,
    required this.configPreview,
    required this.onApprove,
    required this.onCancel,
    super.key,
  });

  final String name;
  final String riskTier;
  final List<String> permissions;
  final List<String> surfaces;
  final Map<String, String> configPreview;
  final VoidCallback onApprove;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('p19_extension_install_sheet'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Text(
                  'Approve $name',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            'Risk tier: $riskTier. Permissions are scoped to the surfaces below and can be suspended from this console.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoomColors.mutedInk,
              height: 1.28,
            ),
          ),
          const SizedBox(height: LoomSpacing.md),
          _ChipGroup(title: 'Approved surfaces', values: surfaces),
          const SizedBox(height: LoomSpacing.sm),
          _ChipGroup(title: 'Approved permissions', values: permissions),
          if (configPreview.isNotEmpty) ...[
            const SizedBox(height: LoomSpacing.sm),
            Text(
              'Configuration',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: LoomSpacing.xs),
            for (final entry in configPreview.entries)
              Text(
                '${entry.key}: ${entry.value}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
          const SizedBox(height: LoomSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('p19_cancel_install_button'),
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('p19_approve_install_button'),
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: LoomSpacing.xs),
        Wrap(
          spacing: LoomSpacing.xs,
          runSpacing: LoomSpacing.xs,
          children: [
            for (final value in values)
              Chip(
                label: Text(value),
                side: const BorderSide(color: LoomColors.line),
              ),
          ],
        ),
      ],
    );
  }
}
