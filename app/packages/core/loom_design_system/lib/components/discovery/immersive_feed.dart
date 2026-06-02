import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

class ImmersiveFeedItemView {
  const ImmersiveFeedItemView({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.creatorName,
    required this.summary,
    required this.posterRef,
    required this.providerLabel,
    required this.reason,
  });

  final String id;
  final String creatorId;
  final String title;
  final String creatorName;
  final String summary;
  final String posterRef;
  final String providerLabel;
  final String reason;
}

class ImmersiveDiscoveryFeed extends StatelessWidget {
  const ImmersiveDiscoveryFeed({
    required this.items,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onOpenItem,
    required this.onOpenCreator,
    super.key,
  });

  final List<ImmersiveFeedItemView> items;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final ValueChanged<ImmersiveFeedItemView> onOpenItem;
  final ValueChanged<ImmersiveFeedItemView> onOpenCreator;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No immersive content is ready yet.'));
    }
    return PageView.builder(
      key: const ValueKey('p14_immersive_discovery'),
      scrollDirection: Axis.vertical,
      itemCount: items.length + (hasMore ? 1 : 0),
      onPageChanged: (index) {
        if (hasMore && index >= items.length - 1 && !loadingMore) {
          onLoadMore();
        }
      },
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return _LoadMoreCard(
            loadingMore: loadingMore,
            onLoadMore: onLoadMore,
          );
        }
        final item = items[index];
        return _ImmersiveCard(
          item: item,
          onOpenItem: () => onOpenItem(item),
          onOpenCreator: () => onOpenCreator(item),
        );
      },
    );
  }
}

class _ImmersiveCard extends StatelessWidget {
  const _ImmersiveCard({
    required this.item,
    required this.onOpenItem,
    required this.onOpenCreator,
  });

  final ImmersiveFeedItemView item;
  final VoidCallback onOpenItem;
  final VoidCallback onOpenCreator;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(item.posterRef);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              key: ValueKey('p14_immersive_card_${item.id}'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.black.withAlpha(70),
                      Colors.black.withAlpha(190),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: _PosterBadge(label: _categoryLabel(item.posterRef)),
            ),
            Positioned(
              right: 12,
              bottom: 112,
              child: _ActionRail(onOpenItem: onOpenItem),
            ),
            Positioned(
              left: 18,
              right: 72,
              bottom: 18,
              child: _MetadataPanel(
                item: item,
                onOpenCreator: onOpenCreator,
                onOpenItem: onOpenItem,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({
    required this.item,
    required this.onOpenCreator,
    required this.onOpenItem,
  });

  final ImmersiveFeedItemView item;
  final VoidCallback onOpenCreator;
  final VoidCallback onOpenItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: ValueKey('p14_immersive_creator_${item.creatorId}_${item.id}'),
          onTap: onOpenCreator,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  item.creatorName.characters.first,
                  style: const TextStyle(
                    color: LoomColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: LoomSpacing.sm),
              Expanded(
                child: Text(
                  item.creatorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LoomSpacing.sm),
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.summary,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withAlpha(225),
            height: 1.24,
          ),
        ),
        const SizedBox(height: LoomSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(label: item.providerLabel),
            _Pill(label: item.reason),
          ],
        ),
        const SizedBox(height: LoomSpacing.md),
        FilledButton.icon(
          key: ValueKey('p14_immersive_open_${item.id}'),
          onPressed: onOpenItem,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Open'),
        ),
      ],
    );
  }
}

class _ActionRail extends StatelessWidget {
  const _ActionRail({required this.onOpenItem});

  final VoidCallback onOpenItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RailButton(icon: Icons.favorite_border_rounded, onPressed: () {}),
        const SizedBox(height: LoomSpacing.sm),
        _RailButton(
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: onOpenItem,
        ),
        const SizedBox(height: LoomSpacing.sm),
        _RailButton(icon: Icons.ios_share_rounded, onPressed: () {}),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      color: Colors.white,
      style: IconButton.styleFrom(backgroundColor: Colors.black.withAlpha(120)),
    );
  }
}

class _PosterBadge extends StatelessWidget {
  const _PosterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadMoreCard extends StatelessWidget {
  const _LoadMoreCard({required this.loadingMore, required this.onLoadMore});

  final bool loadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        key: const ValueKey('p14_immersive_load_more_button'),
        onPressed: loadingMore ? null : onLoadMore,
        icon: loadingMore
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more_rounded),
        label: Text(loadingMore ? 'Loading more' : 'Load more'),
      ),
    );
  }
}

List<Color> _palette(String posterRef) {
  final seed = posterRef.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return switch (seed % 5) {
    0 => const [Color(0xFF0F6B55), Color(0xFFF2C94C)],
    1 => const [Color(0xFF1D4E89), Color(0xFFFFB703)],
    2 => const [Color(0xFF8F2D56), Color(0xFFFFD166)],
    3 => const [Color(0xFF2D6A4F), Color(0xFF90BE6D)],
    _ => const [Color(0xFF172A3A), Color(0xFF4FB0C6)],
  };
}

String _categoryLabel(String posterRef) {
  if (posterRef.contains('solar')) {
    return 'Home Energy';
  }
  if (posterRef.contains('ferment')) {
    return 'Food';
  }
  if (posterRef.contains('motion')) {
    return 'Movement';
  }
  return 'Creator';
}
