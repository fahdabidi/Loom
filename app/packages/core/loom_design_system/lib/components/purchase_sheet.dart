import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class PurchaseSheet extends StatelessWidget {
  const PurchaseSheet({
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.benefits,
    required this.onConfirm,
    this.confirming = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final List<String> benefits;
  final VoidCallback onConfirm;
  final bool confirming;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  amountLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LoomColors.aqua,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LoomSpacing.xs),
            Text(subtitle, style: const TextStyle(color: LoomColors.mutedInk)),
            const SizedBox(height: LoomSpacing.md),
            for (final benefit in benefits)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_rounded),
                title: Text(benefit),
              ),
            const SizedBox(height: LoomSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('p6_confirm_purchase_button'),
                onPressed: confirming ? null : onConfirm,
                icon: confirming
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_rounded),
                label: const Text('Confirm simulated payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
