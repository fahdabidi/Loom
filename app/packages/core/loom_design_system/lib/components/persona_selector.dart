import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class PersonaSelector extends StatelessWidget {
  const PersonaSelector({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < options.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: LoomSpacing.sm),
            child: _PersonaOption(
              label: options[index],
              description: _descriptionFor(options[index]),
              icon: index == 0
                  ? Icons.lock_outline_rounded
                  : Icons.public_rounded,
              selected: selectedIndex == index,
              onTap: () => onChanged(index),
            ),
          ),
      ],
    );
  }
}

class _PersonaOption extends StatelessWidget {
  const _PersonaOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(LoomSpacing.md),
        decoration: BoxDecoration(
          color: selected ? LoomColors.ink : LoomColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? LoomColors.ink : LoomColors.line,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected
                  ? LoomColors.surface.withAlpha(28)
                  : LoomColors.surfaceAlt,
              child: Icon(
                icon,
                color: selected ? LoomColors.surface : LoomColors.ink,
              ),
            ),
            const SizedBox(width: LoomSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? LoomColors.surface : LoomColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: selected
                          ? LoomColors.surface.withAlpha(205)
                          : LoomColors.mutedInk,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? LoomColors.surface : LoomColors.mutedInk,
            ),
          ],
        ),
      ),
    );
  }
}

String _descriptionFor(String label) {
  return switch (label) {
    'Private' => 'Only you can see this follow in the demo passport.',
    'Public' => 'This follow can appear on your public relationship graph.',
    _ => 'Choose how this identity behaves across Loom.',
  };
}
