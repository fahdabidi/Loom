import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class EntitlementRow extends StatelessWidget {
  const EntitlementRow({
    required this.title,
    required this.subtitle,
    required this.active,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEAF8F5) : LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0xFFCDEBE4) : LoomColors.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.verified_rounded : Icons.radio_button_unchecked,
            color: active ? const Color(0xFF167A55) : LoomColors.mutedInk,
          ),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          Text(
            active ? 'Active' : 'Available',
            style: TextStyle(
              color: active ? const Color(0xFF167A55) : LoomColors.mutedInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
