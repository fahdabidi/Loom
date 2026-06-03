import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedLabel = labels[selectedIndex];

    return Tooltip(
      message: 'Switch workspace',
      child: Padding(
        padding: const EdgeInsets.only(right: LoomSpacing.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _showRoleSheet(context),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: LoomColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: LoomColors.ink,
                  child: Text(
                    selectedLabel.characters.first,
                    style: const TextStyle(
                      color: LoomColors.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LoomSpacing.lg,
              0,
              LoomSpacing.lg,
              LoomSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch workspace',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: LoomSpacing.md),
                for (var index = 0; index < labels.length; index += 1)
                  _RoleChoice(
                    label: labels[index],
                    selected: index == selectedIndex,
                    onTap: () {
                      Navigator.of(context).pop();
                      onChanged(index);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LoomSpacing.sm),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: selected ? LoomColors.ink : LoomColors.surfaceAlt,
        textColor: selected ? LoomColors.surface : LoomColors.ink,
        iconColor: selected ? LoomColors.surface : LoomColors.mutedInk,
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        onTap: onTap,
      ),
    );
  }
}
