import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

import 'discovery_controller.dart';

class DiscoveryHomeScreen extends StatefulWidget {
  const DiscoveryHomeScreen({
    required this.onStartOnboarding,
    this.initialImmersive = false,
    this.searchRequests,
    this.onOpenCreator,
    this.onOpenContent,
    this.onOpenExternal,
    this.onOpenWallet,
    this.onOpenDataRights,
    this.onOpenCampaigns,
    this.onOpenCaptureLink,
    this.onOpenSettings,
    super.key,
  });

  final VoidCallback onStartOnboarding;
  final bool initialImmersive;
  final ValueListenable<int>? searchRequests;
  final ValueChanged<String>? onOpenCreator;
  final ValueChanged<String>? onOpenContent;
  final ValueChanged<AiSearchItem>? onOpenExternal;
  final VoidCallback? onOpenWallet;
  final VoidCallback? onOpenDataRights;
  final VoidCallback? onOpenCampaigns;
  final VoidCallback? onOpenCaptureLink;
  final VoidCallback? onOpenSettings;

  @override
  State<DiscoveryHomeScreen> createState() => _DiscoveryHomeScreenState();
}

class _DiscoveryHomeScreenState extends State<DiscoveryHomeScreen> {
  late final DiscoveryController _controller;
  bool _immersive = false;
  bool _showSearchPage = false;

  @override
  void initState() {
    super.initState();
    _immersive = widget.initialImmersive;
    _controller = DiscoveryController()..bootstrap();
    widget.searchRequests?.addListener(_handleSearchRequest);
  }

  @override
  void didUpdateWidget(DiscoveryHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchRequests == widget.searchRequests) {
      return;
    }
    oldWidget.searchRequests?.removeListener(_handleSearchRequest);
    widget.searchRequests?.addListener(_handleSearchRequest);
  }

  @override
  void dispose() {
    widget.searchRequests?.removeListener(_handleSearchRequest);
    _controller.dispose();
    super.dispose();
  }

  void _handleSearchRequest() {
    if (!mounted) {
      return;
    }
    _showSearchPanel();
  }

  void _openSearchResults(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return;
    }
    setState(() => _showSearchPage = true);
    _controller.search(normalized);
  }

  Future<void> _showSearchPanel() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _SearchPanel(
        initialQuery: _controller.searchQuery,
        onSearch: (query) {
          Navigator.of(context).pop();
          _openSearchResults(query);
        },
      ),
    );
  }

  Future<void> _showRecommendationPanel() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _RecommendationPanel(
          controller: _controller,
          onOpenSettings: widget.onOpenSettings == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onOpenSettings?.call();
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading && _controller.feedItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(
              title: 'Preparing your discovery feed',
              rows: 4,
            ),
          );
        }
        if (_controller.errorMessage != null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: LoomErrorState(
              title: 'Discovery could not load',
              body: _controller.errorMessage!,
              onRetry: _controller.bootstrap,
            ),
          );
        }
        if (_controller.feedItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoomEmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'No discovery items yet',
              body:
                  'Pick an intent or starter pack to seed a creator-led feed.',
            ),
          );
        }
        if (_showSearchPage) {
          return _DiscoverySearchPage(
            controller: _controller,
            onBack: () => setState(() => _showSearchPage = false),
            onOpenSearchPanel: _showSearchPanel,
            onOpenContent: widget.onOpenContent,
            onOpenCreator: widget.onOpenCreator,
            onOpenExternal: widget.onOpenExternal,
          );
        }
        if (_immersive) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: _DiscoveryToolbar(
                  onStartOnboarding: widget.onStartOnboarding,
                  onOpenWallet: widget.onOpenWallet,
                  onOpenDataRights: widget.onOpenDataRights,
                  onOpenCampaigns: widget.onOpenCampaigns,
                  onOpenCaptureLink: widget.onOpenCaptureLink,
                  onOpenSettings: widget.onOpenSettings,
                  immersive: _immersive,
                  onToggleImmersive: () =>
                      setState(() => _immersive = !_immersive),
                ),
              ),
              Expanded(
                child: ImmersiveDiscoveryFeed(
                  items: _controller.feedItems
                      .map(_mapImmersiveItem)
                      .toList(growable: false),
                  hasMore: _controller.hasMore,
                  loadingMore: _controller.loadingMore,
                  onLoadMore: _controller.loadMore,
                  onOpenItem: (item) => widget.onOpenContent?.call(item.id),
                  onOpenCreator: (item) =>
                      widget.onOpenCreator?.call(item.creatorId),
                ),
              ),
            ],
          );
        }
        return ListView(
          key: const ValueKey('p3_discovery_scroll'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _DiscoveryToolbar(
              onStartOnboarding: widget.onStartOnboarding,
              onOpenWallet: widget.onOpenWallet,
              onOpenDataRights: widget.onOpenDataRights,
              onOpenCampaigns: widget.onOpenCampaigns,
              onOpenCaptureLink: widget.onOpenCaptureLink,
              onOpenSettings: widget.onOpenSettings,
              immersive: _immersive,
              onToggleImmersive: () => setState(() => _immersive = !_immersive),
            ),
            const SizedBox(height: 14),
            if (_controller.recommendationMessage != null) ...[
              DataDashboardRow(
                key: const ValueKey('p8_discovery_receipt'),
                icon: Icons.receipt_long_rounded,
                title: _controller.recommendationMessage!,
                subtitle:
                    'Recommended content stays labeled before attribution is recorded.',
              ),
              const SizedBox(height: 12),
            ],
            _RecommendationTypeRow(
              controller: _controller,
              onTap: _showRecommendationPanel,
            ),
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
                onRecordDiscovery:
                    item.providerLabel.startsWith('Recommended by ')
                    ? () => _controller.recordRecommendedDiscovery(item)
                    : null,
              ),
              if (_controller.latestDiscoveryReceipt?.contentId ==
                  item.tile.contentId) ...[
                const SizedBox(height: 10),
                DataDashboardRow(
                  key: const ValueKey('p8_discovery_receipt'),
                  icon: Icons.receipt_long_rounded,
                  title:
                      _controller.recommendationMessage ??
                      'Discovery receipt recorded.',
                  subtitle:
                      'Recommendation attribution is visible before conversion.',
                ),
              ],
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
  const _DiscoveryToolbar({
    required this.onStartOnboarding,
    required this.onOpenWallet,
    required this.onOpenDataRights,
    required this.onOpenCampaigns,
    required this.onOpenCaptureLink,
    required this.onOpenSettings,
    required this.immersive,
    required this.onToggleImmersive,
  });

  final VoidCallback onStartOnboarding;
  final VoidCallback? onOpenWallet;
  final VoidCallback? onOpenDataRights;
  final VoidCallback? onOpenCampaigns;
  final VoidCallback? onOpenCaptureLink;
  final VoidCallback? onOpenSettings;
  final bool immersive;
  final VoidCallback onToggleImmersive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Discover',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
          message: immersive ? 'Dense feed' : 'Immersive feed',
          child: IconButton.filledTonal(
            key: const ValueKey('p14_toggle_immersive_button'),
            onPressed: onToggleImmersive,
            icon: Icon(
              immersive
                  ? Icons.view_agenda_rounded
                  : Icons.smart_display_rounded,
            ),
          ),
        ),
        Tooltip(
          message: 'Creator invite',
          child: IconButton.filledTonal(
            key: const ValueKey('p12_open_capture_link_button'),
            onPressed: onOpenCaptureLink,
            icon: const Icon(Icons.link_rounded),
          ),
        ),
        Tooltip(
          message: 'Wallet',
          child: IconButton(
            key: const ValueKey('p6_open_wallet_button'),
            onPressed: onOpenWallet,
            icon: const Icon(Icons.account_balance_wallet_rounded),
          ),
        ),
        Tooltip(
          message: 'Data rights',
          child: IconButton(
            key: const ValueKey('p7_open_data_rights_button'),
            onPressed: onOpenDataRights,
            icon: const Icon(Icons.verified_user_outlined),
          ),
        ),
        Tooltip(
          message: 'Campaigns',
          child: IconButton(
            key: const ValueKey('p8_open_campaigns_button'),
            onPressed: onOpenCampaigns,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ),
        Tooltip(
          message: 'AI search settings',
          child: IconButton(
            key: const ValueKey('p22_open_ai_search_settings_button'),
            onPressed: onOpenSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}

ImmersiveFeedItemView _mapImmersiveItem(FeedItem item) {
  return ImmersiveFeedItemView(
    id: item.tile.contentId,
    creatorId: item.tile.creatorId,
    title: item.tile.title,
    creatorName: item.tile.creatorName,
    summary: item.tile.summary,
    posterRef: item.tile.thumbnailRef,
    providerLabel: item.providerLabel,
    reason: item.explanation.summary,
  );
}

class _DiscoverySearchPage extends StatelessWidget {
  const _DiscoverySearchPage({
    required this.controller,
    required this.onBack,
    required this.onOpenSearchPanel,
    required this.onOpenContent,
    required this.onOpenCreator,
    required this.onOpenExternal,
  });

  final DiscoveryController controller;
  final VoidCallback onBack;
  final VoidCallback onOpenSearchPanel;
  final ValueChanged<String>? onOpenContent;
  final ValueChanged<String>? onOpenCreator;
  final ValueChanged<AiSearchItem>? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListView(
          key: const ValueKey('p0_search_results_page'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  key: const ValueKey('p0_search_back_button'),
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    key: const ValueKey('p0_search_query_bar'),
                    onTap: onOpenSearchPanel,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: LoomColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: LoomColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.searchQuery.isEmpty
                                  ? 'Search creators, topics, summaries'
                                  : controller.searchQuery,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.searchLoading)
              const DataDashboardRow(
                key: ValueKey('p23_ai_search_loading'),
                icon: Icons.manage_search_rounded,
                title: 'Running search',
                subtitle:
                    'Checking your connected agent and matching creator plus external sources.',
              )
            else if (controller.searchErrorMessage != null)
              LoomErrorState(
                title: 'Search could not run',
                body: controller.searchErrorMessage!,
                onRetry: () => controller.search(controller.searchQuery),
              )
            else if (controller.aiSearchResult != null)
              _AiSearchResults(
                result: controller.aiSearchResult!,
                onOpenContent: onOpenContent,
                onOpenCreator: onOpenCreator,
                onOpenExternal: onOpenExternal,
              )
            else if (controller.searchResults.isNotEmpty)
              _SearchResults(
                results: controller.searchResults,
                onOpenContent: onOpenContent,
                onOpenCreator: onOpenCreator,
              )
            else
              const LoomEmptyState(
                icon: Icons.search_rounded,
                title: 'Start a search',
                body:
                    'Use the search bar to find creators, topics, summaries, and external matches when your AI agent is connected.',
              ),
          ],
        );
      },
    );
  }
}

class _SearchPanel extends StatefulWidget {
  const _SearchPanel({required this.initialQuery, required this.onSearch});

  final String initialQuery;
  final ValueChanged<String> onSearch;

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: Column(
        key: const ValueKey('p0_search_panel'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: LoomColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Search Loom',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('p3_search_field'),
            controller: _textController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSearch,
            decoration: InputDecoration(
              hintText: 'Search creators, topics, summaries',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                key: const ValueKey('p0_search_sheet_submit'),
                tooltip: 'Run search',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => widget.onSearch(_textController.text),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in const [
                'gaming retakes',
                'solar recipes',
                'fermentation',
              ])
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => widget.onSearch(suggestion),
                ),
            ],
          ),
        ],
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

class _RecommendationTypeRow extends StatelessWidget {
  const _RecommendationTypeRow({required this.controller, required this.onTap});

  final DiscoveryController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = controller.sessionIntent;
    final fallbackTile = controller.startupTiles.isEmpty
        ? null
        : controller.startupTiles.first;
    final label = session?.label ?? fallbackTile?.label ?? 'For you';
    final description =
        session?.disclosure.body ??
        fallbackTile?.description ??
        'Creator-led posts ranked with visible signals.';

    return InkWell(
      key: const ValueKey('p0_recommendation_type_row'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: LoomColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LoomColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendation Type: $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.controller,
    required this.onOpenSettings,
  });

  final DiscoveryController controller;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: SingleChildScrollView(
        key: const ValueKey('p0_recommendation_panel'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: LoomColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Recommendation Type',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the feed engine and ranking controls for this session.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: LoomColors.mutedInk),
            ),
            const SizedBox(height: 16),
            _IntentRail(controller: controller),
            const SizedBox(height: 14),
            ByoAgentToggle(
              enabled: controller.rankPreference?.summaryFirst ?? false,
              onChanged: controller.setSummaryFirst,
            ),
            if (controller.rankPreference?.summaryFirst ?? false) ...[
              const SizedBox(height: 10),
              _SummaryRankNote(
                candidateCount: controller.summaryRankCandidateCount ?? 0,
              ),
            ],
            if (controller.sessionIntent != null) ...[
              const SizedBox(height: 14),
              _DisclosureCard(sessionIntent: controller.sessionIntent!),
            ],
            const SizedBox(height: 14),
            ListTile(
              key: const ValueKey('p0_recommendation_ai_settings_button'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_search_rounded),
              title: const Text('AI search settings'),
              subtitle: const Text(
                'Connect an agent and choose external sources for search.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onOpenSettings,
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
  const _SearchResults({
    required this.results,
    this.onOpenContent,
    this.onOpenCreator,
  });

  final List<SearchResult> results;
  final ValueChanged<String>? onOpenContent;
  final ValueChanged<String>? onOpenCreator;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('p23_neutral_search_results'),
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
              onTap: () => onOpenContent?.call(result.tile.contentId),
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
              trailing: IconButton(
                tooltip: 'Open creator',
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => onOpenCreator?.call(result.tile.creatorId),
              ),
            ),
        ],
      ),
    );
  }
}

class _AiSearchResults extends StatelessWidget {
  const _AiSearchResults({
    required this.result,
    required this.onOpenContent,
    required this.onOpenCreator,
    required this.onOpenExternal,
  });

  final AiSearchResult result;
  final ValueChanged<String>? onOpenContent;
  final ValueChanged<String>? onOpenCreator;
  final ValueChanged<AiSearchItem>? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('p23_ai_search_results'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiRankDisclosure(
          title: 'Ranked by your AI search agent',
          subtitle: result.neutralityLabel,
          receiptLabel: 'Search receipt ${result.searchReceiptId}',
        ),
        const SizedBox(height: 10),
        for (final item in result.items.take(6)) ...[
          AiResultTile(
            resultKey: _aiResultKey(item),
            title: _aiResultTitle(item),
            summary: _aiResultSummary(item),
            thumbnailRef: item.thumbnailRef,
            sourceLabel: item.sourceAttribution,
            rankReason: item.rankReason,
            isExternal: item.type == AiSearchItemType.external,
            accurateMatchLabel: item.accurateMatchLabel,
            originalTitle: item.originalTitle,
            creatorName: item.creatorTile?.creatorName,
            titleRiskSignals: item.titleRiskSignals,
            onOpen: () {
              final tile = item.creatorTile;
              if (tile != null) {
                final openContent = onOpenContent;
                if (openContent != null) {
                  openContent(tile.contentId);
                } else {
                  onOpenCreator?.call(tile.creatorId);
                }
                return;
              }
              final openExternal = onOpenExternal;
              if (openExternal != null) {
                openExternal(item);
                return;
              }
              _showExternalPreviewSheet(context, item);
            },
            onWhy: () => _showAiWhySheet(context, item),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

String _aiResultKey(AiSearchItem item) {
  final prefix = item.type == AiSearchItemType.external
      ? 'p23_ai_external'
      : 'p23_ai_creator';
  return '${prefix}_${item.id}';
}

String _aiResultTitle(AiSearchItem item) {
  if (item.type == AiSearchItemType.external) {
    return item.originalTitle;
  }
  return item.summary;
}

String _aiResultSummary(AiSearchItem item) {
  if (item.type == AiSearchItemType.external) {
    return item.summary;
  }
  return 'Creator-owned result. Original title: ${item.originalTitle}';
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
    this.onRecordDiscovery,
    super.key,
  });

  final FeedItem item;
  final VoidCallback onWhy;
  final VoidCallback onOpen;
  final VoidCallback? onOpenCreator;
  final ValueChanged<FeedbackAction> onFeedback;
  final VoidCallback? onRecordDiscovery;

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
                        if (item.providerLabel != 'Loom native graph') ...[
                          const SizedBox(height: 5),
                          Container(
                            key: ValueKey(
                              'p8_recommendation_disclosure_${item.tile.contentId}',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF8F5),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFCDEBE4),
                              ),
                            ),
                            child: Text(
                              item.providerLabel,
                              style: const TextStyle(
                                color: Color(0xFF167A55),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
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
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  if (onRecordDiscovery != null)
                    Tooltip(
                      message: 'Record discovery receipt',
                      child: IconButton(
                        key: ValueKey(
                          'p8_record_discovery_${item.tile.contentId}',
                        ),
                        onPressed: onRecordDiscovery,
                        icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      ),
                    ),
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
    final palette = _posterGradientFor(item.tile.thumbnailRef);
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

void _showAiWhySheet(BuildContext context, AiSearchItem item) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SingleChildScrollView(
      key: ValueKey('p23_ai_why_sheet_${item.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this ranked',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(item.rankReason),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.source_rounded),
              title: Text(item.sourceAttribution),
              subtitle: Text(
                item.type == AiSearchItemType.external
                    ? 'External public result. Original title and thumbnail are preserved.'
                    : 'Creator-owned Loom result. Summary is used as the lead label.',
              ),
            ),
            if (item.titleRiskSignals.isNotEmpty)
              for (final signal in item.titleRiskSignals)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check_rounded),
                  title: Text(signal),
                ),
          ],
        ),
      ),
    ),
  );
}

void _showExternalPreviewSheet(BuildContext context, AiSearchItem item) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      key: ValueKey('p23_external_preview_${item.id}'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.accurateMatchLabel ?? 'External match',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            item.originalTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoomColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(item.summary),
          const SizedBox(height: 14),
          DataDashboardRow(
            icon: Icons.public_rounded,
            title: item.sourceAttribution,
            subtitle:
                'Phase 23 previews external matches. Embedded playback is added in Phase 24.',
          ),
        ],
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

List<Color> _posterGradientFor(String seed) {
  final hash = seed.codeUnits.fold<int>(0, (sum, codeUnit) => sum + codeUnit);
  final palettes = const [
    [Color(0xFF183A37), Color(0xFFE9C46A)],
    [Color(0xFF283044), Color(0xFF78A1BB)],
    [Color(0xFF4A2C2A), Color(0xFFE07A5F)],
    [Color(0xFF1E3A5F), Color(0xFF90BE6D)],
  ];
  return palettes[hash % palettes.length];
}
