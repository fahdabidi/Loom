import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioRecommendationBuilder extends StatelessWidget {
  const StudioRecommendationBuilder({
    required this.sourceCreatorName,
    required this.destinationCreatorName,
    required this.contentTitle,
    required this.note,
    this.manifestLabel,
    this.termsLabel,
    this.referralLabel,
    this.onPublishRecommendation,
    this.onPublishTerms,
    this.onSimulateReferral,
    super.key,
  });

  final String sourceCreatorName;
  final String destinationCreatorName;
  final String contentTitle;
  final String note;
  final String? manifestLabel;
  final String? termsLabel;
  final String? referralLabel;
  final VoidCallback? onPublishRecommendation;
  final VoidCallback? onPublishTerms;
  final VoidCallback? onSimulateReferral;

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
          _Header(
            icon: Icons.recommend_rounded,
            title: 'Recommendation',
            subtitle: '$sourceCreatorName -> $destinationCreatorName',
          ),
          const SizedBox(height: LoomSpacing.md),
          Text(
            contentTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.xs),
          Text(
            note,
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
              _StatusPill(label: manifestLabel ?? 'Manifest draft'),
              _StatusPill(label: termsLabel ?? 'Terms draft'),
              if (referralLabel != null) _StatusPill(label: referralLabel!),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          Wrap(
            spacing: LoomSpacing.sm,
            runSpacing: LoomSpacing.sm,
            children: [
              FilledButton.icon(
                key: const ValueKey('p8_publish_recommendation_button'),
                onPressed: onPublishRecommendation,
                icon: const Icon(Icons.publish_rounded),
                label: const Text('Publish pick'),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('p8_publish_referral_terms_button'),
                onPressed: onPublishTerms,
                icon: const Icon(Icons.handshake_rounded),
                label: const Text('Publish terms'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('p8_record_referral_conversion_button'),
                onPressed: onSimulateReferral,
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Settle referral'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: LoomColors.lilac.withAlpha(34),
          child: Icon(icon, color: LoomColors.lilac),
        ),
        const SizedBox(width: LoomSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LoomColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
