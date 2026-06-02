import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioExtensionConfigForm extends StatelessWidget {
  const StudioExtensionConfigForm({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final Map<String, String> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const ValueKey('p19_extension_config_form'),
      width: double.infinity,
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: LoomSpacing.sm),
          for (final entry in entries.entries) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LoomSpacing.xs),
          ],
        ],
      ),
    );
  }
}
