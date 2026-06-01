import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class CategoryDefaultControl extends StatelessWidget {
  const CategoryDefaultControl({
    required this.category,
    required this.stateLabel,
    required this.onAllow,
    required this.onDeny,
    super.key,
  });

  final String category;
  final String stateLabel;
  final VoidCallback onAllow;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.md),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.rule_folder_outlined, color: LoomColors.moss),
          const SizedBox(width: LoomSpacing.md),
          Expanded(
            child: InkWell(
              key: const ValueKey('p7_category_default_button'),
              onTap: onDeny,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: LoomSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$category defaults',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      stateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LoomColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: true,
                icon: Icon(Icons.check_rounded),
                label: Text('Allow'),
                tooltip: 'Allow by default',
              ),
              ButtonSegment(
                value: false,
                icon: Icon(Icons.block_rounded),
                label: Text(
                  'Deny',
                  key: ValueKey('p7_category_default_deny_button'),
                ),
                tooltip: 'Deny by default',
              ),
            ],
            selected: {
              stateLabel.toLowerCase().contains('deny') ? false : true,
            },
            onSelectionChanged: (selection) {
              if (selection.first) {
                onAllow();
              } else {
                onDeny();
              }
            },
          ),
        ],
      ),
    );
  }
}
