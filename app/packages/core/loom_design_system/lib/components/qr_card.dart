import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class QrCard extends StatelessWidget {
  const QrCard({
    required this.payload,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String payload;
  final String title;
  final String subtitle;

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
      child: Row(
        children: [
          _QrGlyph(payload: payload),
          const SizedBox(width: LoomSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: LoomSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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

class _QrGlyph extends StatelessWidget {
  const _QrGlyph({required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) {
    final seed = payload.codeUnits.fold<int>(
      17,
      (value, unit) => (value * 31 + unit) & 0x7fffffff,
    );
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 121,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 11,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ 11;
          final col = index % 11;
          final finder =
              (row < 3 && col < 3) ||
              (row < 3 && col > 7) ||
              (row > 7 && col < 3);
          final filled = finder || ((seed >> ((row + col) % 23)) & 1) == 1;
          return Padding(
            padding: const EdgeInsets.all(1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: filled ? LoomColors.ink : Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        },
      ),
    );
  }
}
