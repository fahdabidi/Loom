import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    required this.creatorName,
    required this.title,
    required this.description,
    required this.rewardLabel,
    required this.entryLabel,
    this.offerLabel,
    this.onEnter,
    this.onIssueReward,
    this.onAcceptOffer,
    super.key,
  });

  final String creatorName;
  final String title;
  final String description;
  final String rewardLabel;
  final String entryLabel;
  final String? offerLabel;
  final VoidCallback? onEnter;
  final VoidCallback? onIssueReward;
  final VoidCallback? onAcceptOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              CircleAvatar(
                backgroundColor: LoomColors.aqua.withAlpha(38),
                child: const Icon(Icons.emoji_events_rounded),
              ),
              const SizedBox(width: LoomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LoomColors.mutedInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.sm),
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
              _Pill(icon: Icons.card_giftcard_rounded, label: rewardLabel),
              _Pill(icon: Icons.how_to_reg_rounded, label: entryLabel),
              if (offerLabel != null)
                _Pill(icon: Icons.verified_user_outlined, label: offerLabel!),
            ],
          ),
          if (onEnter != null ||
              onIssueReward != null ||
              onAcceptOffer != null) ...[
            const SizedBox(height: LoomSpacing.md),
            Wrap(
              spacing: LoomSpacing.sm,
              runSpacing: LoomSpacing.sm,
              children: [
                if (onEnter != null)
                  FilledButton.icon(
                    key: const ValueKey('p8_enter_campaign_button'),
                    onPressed: onEnter,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Enter'),
                  ),
                if (onIssueReward != null)
                  FilledButton.tonalIcon(
                    key: const ValueKey('p8_issue_reward_button'),
                    onPressed: onIssueReward,
                    icon: const Icon(Icons.redeem_rounded),
                    label: const Text('Issue reward'),
                  ),
                if (onAcceptOffer != null)
                  OutlinedButton.icon(
                    key: const ValueKey('p8_accept_data_offer_button'),
                    onPressed: onAcceptOffer,
                    icon: const Icon(Icons.verified_user_rounded),
                    label: const Text('Accept data offer'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
