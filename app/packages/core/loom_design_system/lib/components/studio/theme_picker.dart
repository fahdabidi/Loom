import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioThemeOption {
  const StudioThemeOption({
    required this.themeId,
    required this.name,
    required this.primaryHex,
    required this.secondaryHex,
    required this.backgroundHex,
    required this.accentHex,
  });

  final String themeId;
  final String name;
  final String primaryHex;
  final String secondaryHex;
  final String backgroundHex;
  final String accentHex;
}

class StudioThemePicker extends StatelessWidget {
  const StudioThemePicker({
    required this.options,
    required this.selectedThemeId,
    required this.onSelect,
    super.key,
  });

  final List<StudioThemeOption> options;
  final String selectedThemeId;
  final ValueChanged<StudioThemeOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StudioSection(
      title: 'Theme',
      icon: Icons.palette_rounded,
      child: Column(
        children: [
          for (final option in options) ...[
            InkWell(
              key: ValueKey('p19_theme_${option.themeId}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(option),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LoomSpacing.md),
                decoration: BoxDecoration(
                  color: selectedThemeId == option.themeId
                      ? LoomColors.ink
                      : LoomColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedThemeId == option.themeId
                        ? LoomColors.ink
                        : LoomColors.line,
                  ),
                ),
                child: Row(
                  children: [
                    _Swatches(option: option),
                    const SizedBox(width: LoomSpacing.md),
                    Expanded(
                      child: Text(
                        option.name,
                        style: TextStyle(
                          color: selectedThemeId == option.themeId
                              ? Colors.white
                              : LoomColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      selectedThemeId == option.themeId
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selectedThemeId == option.themeId
                          ? Colors.white
                          : LoomColors.mutedInk,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LoomSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({required this.option});

  final StudioThemeOption option;

  @override
  Widget build(BuildContext context) {
    final colors = [
      option.primaryHex,
      option.secondaryHex,
      option.backgroundHex,
      option.accentHex,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in colors)
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _colorFromHex(color),
              shape: BoxShape.circle,
              border: Border.all(color: LoomColors.line),
            ),
          ),
      ],
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

Color _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? LoomColors.line : Color(0xFF000000 | parsed);
}
