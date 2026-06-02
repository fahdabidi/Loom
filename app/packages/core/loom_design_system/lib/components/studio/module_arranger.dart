import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioModuleItem {
  const StudioModuleItem({
    required this.moduleId,
    required this.title,
    required this.kind,
    required this.enabled,
    this.extensionName,
  });

  final String moduleId;
  final String title;
  final String kind;
  final bool enabled;
  final String? extensionName;
}

class StudioModuleArranger extends StatelessWidget {
  const StudioModuleArranger({
    required this.modules,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onToggleEnabled,
    super.key,
  });

  final List<StudioModuleItem> modules;
  final ValueChanged<String> onMoveUp;
  final ValueChanged<String> onMoveDown;
  final ValueChanged<String> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    return _StudioSection(
      title: 'Surface order',
      icon: Icons.reorder_rounded,
      child: Column(
        children: [
          for (var index = 0; index < modules.length; index++) ...[
            _ModuleRow(
              key: ValueKey('p19_arrange_${modules[index].moduleId}'),
              item: modules[index],
              first: index == 0,
              last: index == modules.length - 1,
              onMoveUp: () => onMoveUp(modules[index].moduleId),
              onMoveDown: () => onMoveDown(modules[index].moduleId),
              onToggle: () => onToggleEnabled(modules[index].moduleId),
            ),
            const SizedBox(height: LoomSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.item,
    required this.first,
    required this.last,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onToggle,
    super.key,
  });

  final StudioModuleItem item;
  final bool first;
  final bool last;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LoomSpacing.sm),
      decoration: BoxDecoration(
        color: item.enabled ? LoomColors.surface : LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        children: [
          Icon(
            item.kind == 'extension'
                ? Icons.extension_rounded
                : Icons.dashboard_customize_rounded,
            color: item.enabled ? LoomColors.ink : LoomColors.mutedInk,
          ),
          const SizedBox(width: LoomSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  item.extensionName ?? item.kind,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('p19_move_up_${item.moduleId}'),
            onPressed: first ? null : onMoveUp,
            tooltip: 'Move up',
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
          IconButton(
            key: ValueKey('p19_move_down_${item.moduleId}'),
            onPressed: last ? null : onMoveDown,
            tooltip: 'Move down',
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
          IconButton(
            key: ValueKey('p19_toggle_${item.moduleId}'),
            onPressed: onToggle,
            tooltip: item.enabled ? 'Disable' : 'Enable',
            icon: Icon(
              item.enabled
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioSection extends StatelessWidget {
  const _StudioSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
              Icon(icon, color: LoomColors.ink),
              const SizedBox(width: LoomSpacing.sm),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: LoomSpacing.md),
          child,
        ],
      ),
    );
  }
}
