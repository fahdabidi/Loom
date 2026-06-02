import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class StudioBannerOption {
  const StudioBannerOption({
    required this.bannerRef,
    required this.label,
    required this.tone,
  });

  final String bannerRef;
  final String label;
  final String tone;
}

class StudioBannerPicker extends StatelessWidget {
  const StudioBannerPicker({
    required this.options,
    required this.selectedBannerRef,
    required this.onSelect,
    super.key,
  });

  final List<StudioBannerOption> options;
  final String selectedBannerRef;
  final ValueChanged<StudioBannerOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return _StudioSection(
      title: 'Banner',
      icon: Icons.panorama_rounded,
      child: Column(
        children: [
          for (final option in options) ...[
            InkWell(
              key: ValueKey('p19_banner_${option.bannerRef}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelect(option),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LoomSpacing.md),
                decoration: BoxDecoration(
                  color: selectedBannerRef == option.bannerRef
                      ? LoomColors.moss.withAlpha(38)
                      : LoomColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedBannerRef == option.bannerRef
                        ? LoomColors.moss
                        : LoomColors.line,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _toneColor(option.tone),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.landscape_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: LoomSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            option.bannerRef,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: LoomColors.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selectedBannerRef == option.bannerRef
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selectedBannerRef == option.bannerRef
                          ? LoomColors.moss
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

Color _toneColor(String tone) {
  switch (tone) {
    case 'arena':
      return const Color(0xFF16213E);
    case 'lore':
      return const Color(0xFF7C2D12);
    case 'guild':
      return const Color(0xFF1F2937);
    default:
      return LoomColors.moss;
  }
}
