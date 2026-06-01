import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioCampaignBuilder extends StatelessWidget {
  const StudioCampaignBuilder({
    required this.title,
    required this.description,
    required this.rewardLabel,
    this.campaignLabel,
    this.offerLabel,
    this.onCreateCampaign,
    this.onAttachOffer,
    super.key,
  });

  final String title;
  final String description;
  final String rewardLabel;
  final String? campaignLabel;
  final String? offerLabel;
  final VoidCallback? onCreateCampaign;
  final VoidCallback? onAttachOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.lg),
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
                backgroundColor: LoomColors.moss.withAlpha(38),
                child: const Icon(Icons.campaign_rounded),
              ),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Text(
                  'Giveaway campaign',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoomColors.mutedInk,
              height: 1.28,
            ),
          ),
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.xs,
            runSpacing: LoomSpacing.xs,
            children: [
              _Pill(label: rewardLabel),
              _Pill(label: campaignLabel ?? 'Draft'),
              if (offerLabel != null) _Pill(label: offerLabel!),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              FilledButton.icon(
                key: const ValueKey('p8_create_campaign_button'),
                onPressed: onCreateCampaign,
                icon: const Icon(Icons.add_circle_rounded),
                label: const Text('Create campaign'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('p8_attach_data_offer_button'),
                onPressed: onAttachOffer,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Attach offer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
