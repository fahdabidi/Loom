import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioMonetizationEditor extends StatelessWidget {
  const StudioMonetizationEditor({
    required this.tierCount,
    required this.entitlementCount,
    required this.onDefineTiers,
    super.key,
  });

  final int tierCount;
  final int entitlementCount;
  final VoidCallback onDefineTiers;

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
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined),
              const SizedBox(width: LoomSpacing.sm),
              Text(
                'Membership tiers',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
          Text(
            '$tierCount tiers - $entitlementCount entitlement definitions',
            key: const ValueKey('p2_membership_status'),
            style: const TextStyle(color: LoomColors.mutedInk),
          ),
          const SizedBox(height: LoomSpacing.md),
          FilledButton.icon(
            key: const ValueKey('p2_define_tiers_button'),
            onPressed: onDefineTiers,
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Define tiers'),
          ),
        ],
      ),
    );
  }
}
