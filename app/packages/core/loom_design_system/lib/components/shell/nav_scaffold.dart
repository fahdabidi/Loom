import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class LoomNavItem {
  const LoomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class LoomNavScaffold extends StatelessWidget {
  const LoomNavScaffold({
    required this.brand,
    required this.subtitle,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    required this.child,
    this.onSearch,
    this.trailing,
    super.key,
  });

  final String brand;
  final String subtitle;
  final int selectedIndex;
  final List<LoomNavItem> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  final VoidCallback? onSearch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: LoomSpacing.md,
        title: Row(
          children: [
            const _LoomMark(),
            const SizedBox(width: LoomSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    brand,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: LoomColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _ShellIconButton(
            key: const ValueKey('shell_search_button'),
            tooltip: 'Search',
            icon: Icons.search_rounded,
            onPressed: onSearch,
          ),
          const _ShellIconButton(
            tooltip: 'Notifications',
            icon: Icons.notifications_none_rounded,
          ),
          if (trailing != null) trailing!,
          const SizedBox(width: LoomSpacing.xs),
        ],
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: LoomColors.surface,
          border: Border(top: BorderSide(color: LoomColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: [
              for (final destination in destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoomMark extends StatelessWidget {
  const _LoomMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F111417),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Text(
        'L',
        style: TextStyle(
          color: LoomColors.surface,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ShellIconButton extends StatelessWidget {
  const _ShellIconButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton.filledTonal(
          onPressed: onPressed ?? () {},
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: LoomColors.surfaceAlt,
            foregroundColor: LoomColors.ink,
          ),
        ),
      ),
    );
  }
}
