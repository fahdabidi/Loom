import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

import 'discovery_controller.dart';

class DiscoveryHomeScreen extends StatefulWidget {
  const DiscoveryHomeScreen({
    required this.onStartOnboarding,
    this.onOpenCreator,
    this.onOpenContent,
    super.key,
  });

  final VoidCallback onStartOnboarding;
  final ValueChanged<String>? onOpenCreator;
  final ValueChanged<String>? onOpenContent;

  @override
  State<DiscoveryHomeScreen> createState() => _DiscoveryHomeScreenState();
}

class _DiscoveryHomeScreenState extends State<DiscoveryHomeScreen> {
  late final DiscoveryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DiscoveryController()..bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading && _controller.feedItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.errorMessage != null) {
          return Center(child: Text(_controller.errorMessage!));
        }
        return ListView(
          key: const ValueKey('p3_discovery_scroll'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _DiscoveryToolbar(onStartOnboarding: widget.onStartOnboarding),
            const SizedBox(height: 14),
            _SearchField(controller: _controller),
            const SizedBox(height: 16),
            _IntentRail(controller: _controller),
            const SizedBox(height: 14),
            ByoAgentToggle(
              enabled: _controller.rankPreference?.summaryFirst ?? false,
              onChanged: _controller.setSummaryFirst,
            ),
            if (_controller.rankPreference?.summaryFirst ?? false) ...[
              const SizedBox(height: 10),
              _SummaryRankNote(
                candidateCount: _controller.summaryRankCandidateCount ?? 0,
              ),
            ],
            const SizedBox(height: 14),
            if (_controller.sessionIntent != null)
              _DisclosureCard(sessionIntent: _controller.sessionIntent!),
            if (_controller.searchResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SearchResults(results: _controller.searchResults),
            ],
            const SizedBox(height: 16),
            const _SectionHeader(
              title: 'For you',
              subtitle: 'Creator-led posts ranked with visible signals.',
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 10),
            for (final item in _controller.feedItems) ...[
              _DiscoveryFeedCard(
                key: ValueKey('p3_feed_card_${item.tile.contentId}'),
                item: item,
                onWhy: () => _showWhySheet(context, item),
                onOpen: () {
                  final onOpenContent = widget.onOpenContent;
                  if (onOpenContent == null) {
                    _showContentSheet(context, item);
                    return;
                  }
                  onOpenContent(item.tile.contentId);
                },
                onOpenCreator: () =>
                    widget.onOpenCreator?.call(item.tile.creatorId),
                onFeedback: (action) =>
                    _controller.submitFeedback(item, action),
              ),
              const SizedBox(height: 14),
            ],
            if (_controller.hasMore)
              FilledButton.icon(
                key: const ValueKey('p3_load_more_button'),
                onPressed: _controller.loadingMore
                    ? null
                    : _controller.loadMore,
                icon: _controller.loadingMore
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: const Text('Load more'),
              ),
          ],
        );
      },
    );
  }
}

class _DiscoveryToolbar extends StatelessWidget {
  const _DiscoveryToolbar({required this.onStartOnboarding});

  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LoomColors.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'L',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loom',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                'Transparent discovery',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LoomColors.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: 'Start onboarding',
          child: IconButton.filled(
            key: const ValueKey('start_fan_onboarding_button'),
            onPressed: onStartOnboarding,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ),
        Tooltip(
          message: 'Tune feed',
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller});

  final DiscoveryController controller;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('p3_search_field'),
      controller: _textController,
      textInputAction: TextInputAction.search,
      onSubmitted: widget.controller.search,
      decoration: InputDecoration(
        hintText: 'Search creators, topics, summaries',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: 'Run search',
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => widget.controller.search(_textController.text),
        ),
      ),
    );
  }
}

class _SummaryRankNote extends StatelessWidget {
  const _SummaryRankNote({required this.candidateCount});

  final int candidateCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p5_summary_rank_note'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LoomColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Summary used for relevance across $candidateCount existing candidates. Title deemphasized; candidate set unchanged.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LoomColors.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntentRail extends StatelessWidget {
  const _IntentRail({required this.controller});

  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        key: const ValueKey('p3_intent_rail'),
        scrollDirection: Axis.horizontal,
        itemCount: controller.startupTiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tile = controller.startupTiles[index];
          final selected =
              controller.sessionIntent?.platformIntentId == tile.id;
          return _IntentTile(
            key: ValueKey('p3_startup_tile_${tile.id}'),
            tile: tile,
            selected: selected,
            onTap: () => controller.selectIntent(tile),
          );
        },
      ),
    );
  }
}

class _IntentTile extends StatelessWidget {
  const _IntentTile({
    required this.tile,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final PlatformIntent tile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 188,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? LoomColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? LoomColors.ink : LoomColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.white : LoomColors.mutedInk,
              size: 20,
            ),
            const Spacer(),
            Text(
              tile.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? Colors.white : LoomColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tile.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white70 : LoomColors.mutedInk,
                height: 1.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard({required this.sessionIntent});

  final SessionIntent sessionIntent;

  @override
  Widget build(BuildContext context) {
    final disclosure = sessionIntent.disclosure;
    return Container(
      key: const ValueKey('p3_session_disclosure'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDEBE4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF167A55)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disclosure.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  disclosure.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoomColors.mutedInk,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...disclosure.matchedInterests
                        .take(3)
                        .map((label) => _MiniPill(label: label)),
                    ...disclosure.excludedSignals
                        .take(2)
                        .map((label) => _MiniPill(label: label)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});

  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LoomColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Search results',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            results.first.neutralityLabel,
            key: const ValueKey('p3_search_no_ads_label'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final result in results.take(3))
            ListTile(
              key: ValueKey('p3_search_result_${result.tile.contentId}'),
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: LoomColors.ink,
                child: Text(
                  result.tile.creatorName.characters.first,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                result.tile.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(result.tile.creatorName),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscoveryFeedCard extends StatelessWidget {
  const _DiscoveryFeedCard({
    required this.item,
    required this.onWhy,
    required this.onOpen,
    required this.onOpenCreator,
    required this.onFeedback,
    super.key,
  });

  final FeedItem item;
  final VoidCallback onWhy;
  final VoidCallback onOpen;
  final VoidCallback? onOpenCreator;
  final ValueChanged<FeedbackAction> onFeedback;

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(item: item),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    key: ValueKey(
                      'p4_open_channel_${item.tile.creatorId}_${item.tile.contentId}',
                    ),
                    onTap: onOpenCreator,
                    borderRadius: BorderRadius.circular(999),
                    child: _CreatorAvatar(name: item.tile.creatorName),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onOpenCreator,
                          child: Text(
                            item.tile.creatorName,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.tile.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.tile.summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: LoomColors.mutedInk,
                                height: 1.28,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                children: [
                  _ActionChip(
                    icon: item.tile.contentTypeLabel == 'Video'
                        ? Icons.play_arrow_rounded
                        : Icons.article_rounded,
                    label: item.tile.contentTypeLabel == 'Video'
                        ? 'Play'
                        : 'Read',
                  ),
                  const SizedBox(width: 6),
                  _FeedbackIcon(
                    keyValue: 'p3_feedback_like_${item.tile.contentId}',
                    icon: Icons.thumb_up_alt_outlined,
                    label: 'Like',
                    onTap: () => onFeedback(FeedbackAction.like),
                  ),
                  _FeedbackIcon(
                    keyValue: 'p3_feedback_dislike_${item.tile.contentId}',
                    icon: Icons.thumb_down_alt_outlined,
                    label: 'Dislike',
                    onTap: () => onFeedback(FeedbackAction.dislike),
                  ),
                  _FeedbackIcon(
                    keyValue: 'p3_feedback_mute_${item.tile.contentId}',
                    icon: Icons.volume_off_outlined,
                    label: 'Mute creator',
                    onTap: () => onFeedback(FeedbackAction.muteCreator),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    key: ValueKey('p3_why_button_${item.tile.contentId}'),
                    onPressed: onWhy,
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Why'),
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

class _Poster extends StatelessWidget {
  const _Poster({required this.item});

  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(item.tile.thumbnailRef);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -12,
              child: Icon(
                item.tile.contentTypeLabel == 'Video'
                    ? Icons.play_circle_fill_rounded
                    : Icons.article_rounded,
                color: Colors.white.withAlpha(44),
                size: 138,
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _MiniPill(label: item.trendingLabel, dark: true),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                item.tile.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: LoomColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackIcon extends StatelessWidget {
  const _FeedbackIcon({
    required this.keyValue,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyValue;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        key: ValueKey(keyValue),
        onPressed: onTap,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: LoomColors.aqua,
      child: Text(
        name.characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: dark ? Colors.black.withAlpha(132) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: dark ? null : Border.all(color: LoomColors.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : LoomColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

void _showWhySheet(BuildContext context, FeedItem item) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SingleChildScrollView(
      key: const ValueKey('p3_why_sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this is here',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(item.explanation.summary),
            const SizedBox(height: 14),
            for (final signal in item.explanation.matchedSignals)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_rounded),
                title: Text(signal),
              ),
            for (final signal in item.explanation.suppressedSignals)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_rounded),
                title: Text(signal),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showContentSheet(BuildContext context, FeedItem item) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      key: ValueKey('p3_content_sheet_${item.tile.contentId}'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.tile.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(item.tile.summary),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              item.tile.contentTypeLabel == 'Video' ? 'Play' : 'Read',
            ),
          ),
        ],
      ),
    ),
  );
}

List<Color> _paletteFor(String seed) {
  if (seed.contains('solar')) {
    return const [Color(0xFF0F6B55), Color(0xFFF2C94C)];
  }
  if (seed.contains('ferment')) {
    return const [Color(0xFF7C2D46), Color(0xFFEFA94A)];
  }
  if (seed.contains('motion')) {
    return const [Color(0xFF1C508A), Color(0xFF69C7B8)];
  }
  return const [LoomColors.charcoal, LoomColors.aqua];
}
