import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioExtensionCatalogItem {
  const StudioExtensionCatalogItem({
    required this.extensionId,
    required this.name,
    required this.category,
    required this.riskTier,
    required this.description,
    required this.surfaces,
    required this.permissions,
    required this.installed,
  });

  final String extensionId;
  final String name;
  final String category;
  final String riskTier;
  final String description;
  final List<String> surfaces;
  final List<String> permissions;
  final bool installed;
}

class StudioExtensionBrowser extends StatelessWidget {
  const StudioExtensionBrowser({
    required this.items,
    required this.onInstall,
    required this.onSuspend,
    super.key,
  });

  final List<StudioExtensionCatalogItem> items;
  final ValueChanged<StudioExtensionCatalogItem> onInstall;
  final ValueChanged<StudioExtensionCatalogItem> onSuspend;

  @override
  Widget build(BuildContext context) {
    return _StudioSection(
      title: 'Extensions',
      icon: Icons.extension_rounded,
      child: Column(
        children: [
          for (final item in items) ...[
            Container(
              key: ValueKey('p19_extension_${item.extensionId}'),
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
                  Row(
                    children: [
                      _RiskBadge(riskTier: item.riskTier),
                      const SizedBox(width: LoomSpacing.sm),
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Icon(
                        item.installed
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: item.installed
                            ? LoomColors.moss
                            : LoomColors.mutedInk,
                      ),
                    ],
                  ),
                  const SizedBox(height: LoomSpacing.xs),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoomColors.mutedInk,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: LoomSpacing.sm),
                  Wrap(
                    spacing: LoomSpacing.xs,
                    runSpacing: LoomSpacing.xs,
                    children: [
                      _Pill(label: item.category),
                      _Pill(label: item.surfaces.join(', ')),
                    ],
                  ),
                  const SizedBox(height: LoomSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: item.installed
                        ? OutlinedButton.icon(
                            key: ValueKey(
                              'p19_suspend_${item.extensionId}_button',
                            ),
                            onPressed: () => onSuspend(item),
                            icon: const Icon(Icons.pause_circle_rounded),
                            label: const Text('Suspend'),
                          )
                        : FilledButton.tonalIcon(
                            key: ValueKey(
                              'p19_install_${item.extensionId}_button',
                            ),
                            onPressed: () => onInstall(item),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Install'),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LoomSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.riskTier});

  final String riskTier;

  @override
  Widget build(BuildContext context) {
    final high = riskTier == 'high';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: high
            ? LoomColors.sun.withAlpha(58)
            : LoomColors.moss.withAlpha(34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        riskTier,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LoomColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LoomColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: LoomColors.line),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LoomColors.mutedInk,
          fontWeight: FontWeight.w800,
        ),
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
