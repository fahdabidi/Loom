import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class AdSlot extends StatelessWidget {
  const AdSlot({
    required this.brandName,
    required this.category,
    required this.disclosure,
    super.key,
  });

  final String brandName;
  final String category;
  final String disclosure;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p4_ad_slot'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2D49B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFF8A5A00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contextual ad · $brandName',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category · $disclosure',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoomColors.mutedInk,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
