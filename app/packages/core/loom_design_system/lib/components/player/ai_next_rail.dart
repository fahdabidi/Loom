import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class AiNextRailItemView {
  const AiNextRailItemView({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sourceLabel,
    required this.thumbnailRef,
    required this.isExternal,
  });

  final String id;
  final String title;
  final String subtitle;
  final String sourceLabel;
  final String thumbnailRef;
  final bool isExternal;
}

class AiNextRail extends StatelessWidget {
  const AiNextRail({
    required this.items,
    required this.onOpenItem,
    this.loading = false,
    this.errorMessage,
    super.key,
  });

  final List<AiNextRailItemView> items;
  final ValueChanged<AiNextRailItemView> onOpenItem;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('p24_ai_next_rail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Next from your AI search',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: LoomSpacing.sm),
        if (loading)
          const LinearProgressIndicator()
        else if (errorMessage != null)
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoomColors.coral,
              fontWeight: FontWeight.w800,
            ),
          )
        else if (items.isEmpty)
          Text(
            'No additional AI-ranked items for this search yet.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
          )
        else
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _AiNextCard(item: item, onTap: () => onOpenItem(item));
              },
            ),
          ),
      ],
    );
  }
}

class _AiNextCard extends StatelessWidget {
  const _AiNextCard({required this.item, required this.onTap});

  final AiNextRailItemView item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('p24_ai_next_${item.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 208,
        decoration: BoxDecoration(
          color: LoomColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: LoomColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _posterGradientFor(item.thumbnailRef),
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      item.isExternal
                          ? Icons.public_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.sourceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LoomColors.moss,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Color> _posterGradientFor(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit);
  final palettes = const [
    [Color(0xFF172A3A), Color(0xFF1C8EA8)],
    [Color(0xFF253528), Color(0xFFF2C94C)],
    [Color(0xFF2E253A), Color(0xFF7C5CFC)],
    [Color(0xFF332B20), Color(0xFFE45858)],
  ];
  return palettes[hash % palettes.length];
}
