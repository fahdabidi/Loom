import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioAdPolicyEditor extends StatelessWidget {
  const StudioAdPolicyEditor({
    required this.savedLabel,
    required this.onSavePolicy,
    super.key,
  });

  final String savedLabel;
  final VoidCallback onSavePolicy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creator ad policy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          const Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              Chip(label: Text('Allow: home energy')),
              Chip(label: Text('Allow: sustainable living')),
              Chip(label: Text('Block: gambling')),
              Chip(label: Text('Block: alcohol')),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            savedLabel,
            key: const ValueKey('p2_ad_policy_status'),
            style: const TextStyle(color: LoomColors.mutedInk),
          ),
          const SizedBox(height: LoomSpacing.md),
          FilledButton.icon(
            key: const ValueKey('p2_save_ad_policy_button'),
            onPressed: onSavePolicy,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Save policy'),
          ),
        ],
      ),
    );
  }
}
