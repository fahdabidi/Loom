import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class ExternalPlaybackScreen extends StatefulWidget {
  const ExternalPlaybackScreen({
    required this.initialItem,
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    this.enableLiveYoutubePlayer = true,
    this.launchExternalUrl,
    this.onOpenContent,
    super.key,
  });

  final AiSearchItem initialItem;
  final VoidCallback onBack;
  final String passportId;
  final bool enableLiveYoutubePlayer;
  final ExternalUrlLauncher? launchExternalUrl;
  final ValueChanged<String>? onOpenContent;

  @override
  State<ExternalPlaybackScreen> createState() => _ExternalPlaybackScreenState();
}

class _ExternalPlaybackScreenState extends State<ExternalPlaybackScreen> {
  late AiSearchItem _item;
  AiSearchResult? _nextResult;
  bool _loadingNext = true;
  String? _nextError;
  String? _externalOpenMessage;

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _loadNext();
    if (!_isYoutube(_item)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openExternal());
    }
  }

  Future<void> _loadNext() async {
    setState(() {
      _loadingNext = true;
      _nextError = null;
    });
    try {
      final result = await resolveAiGatewayApi().runAiSearch(
        passportId: widget.passportId,
        query: _item.accurateMatchLabel ?? _item.originalTitle,
        limit: 8,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _nextResult = result;
        _loadingNext = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _nextError = '$error';
        _loadingNext = false;
      });
    }
  }

  Future<void> _openExternal() async {
    final uri = _externalUri(_item);
    if (uri == null) {
      setState(() => _externalOpenMessage = 'No external URL is available.');
      return;
    }
    final launcher = widget.launchExternalUrl;
    if (launcher == null) {
      setState(
        () => _externalOpenMessage = 'External launcher is not configured.',
      );
      return;
    }
    final opened = await launcher(uri);
    if (!mounted) {
      return;
    }
    setState(
      () => _externalOpenMessage = opened
          ? 'External source opened.'
          : 'External source could not be opened.',
    );
  }

  void _openNext(AiNextRailItemView view) {
    final nextItem = _nextResult?.items.firstWhere(
      (item) => item.id == view.id,
      orElse: () => _item,
    );
    if (nextItem == null || nextItem.id == _item.id) {
      return;
    }
    final tile = nextItem.creatorTile;
    if (tile != null) {
      widget.onOpenContent?.call(tile.contentId);
      return;
    }
    setState(() {
      _item = nextItem;
      _nextResult = null;
      _externalOpenMessage = null;
    });
    _loadNext();
    if (!_isYoutube(nextItem)) {
      _openExternal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYoutube = _isYoutube(_item);
    final sourceUrl = _externalUri(_item);

    return ListView(
      key: const ValueKey('p24_external_playback_screen'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('p24_external_back_button'),
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                _item.sourceAttribution,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ExternalSourceBanner(
          title: _item.accurateMatchLabel ?? _item.originalTitle,
          originalTitle: _item.originalTitle,
          sourceLabel: _item.sourceAttribution,
          summary: _item.summary,
          accurateMatchLabel: _item.accurateMatchLabel,
        ),
        const SizedBox(height: 14),
        if (isYoutube)
          YoutubeEmbedPlayer(
            videoId: _item.embedDescriptor!.externalId,
            enabled: widget.enableLiveYoutubePlayer,
            fallbackLabel: 'Official YouTube IFrame player',
          )
        else
          LoomErrorState(
            title: 'Open external source',
            body:
                'This source opens in the OS browser or native app. Loom does not embed or re-syndicate it.',
            onRetry: sourceUrl == null ? null : _openExternal,
          ),
        const SizedBox(height: 12),
        const DataDashboardRow(
          key: ValueKey('p24_no_loom_ads_over_embed'),
          icon: Icons.verified_user_rounded,
          title: 'Official player, unobscured',
          subtitle:
              'Loom controls, ads, and next recommendations stay outside the embedded player frame.',
        ),
        if (_externalOpenMessage != null) ...[
          const SizedBox(height: 12),
          DataDashboardRow(
            key: const ValueKey('p24_external_open_status'),
            icon: Icons.open_in_new_rounded,
            title: _externalOpenMessage!,
            subtitle: sourceUrl?.toString() ?? 'No URL',
          ),
        ],
        const SizedBox(height: 18),
        AiNextRail(
          items: _nextItems(),
          loading: _loadingNext,
          errorMessage: _nextError,
          onOpenItem: _openNext,
        ),
      ],
    );
  }

  List<AiNextRailItemView> _nextItems() {
    final result = _nextResult;
    if (result == null) {
      return const [];
    }
    return result.items
        .where((item) => item.id != _item.id)
        .take(6)
        .map(_mapNextItem)
        .toList(growable: false);
  }
}

AiNextRailItemView _mapNextItem(AiSearchItem item) {
  final isExternal = item.type == AiSearchItemType.external;
  return AiNextRailItemView(
    id: item.id,
    title: isExternal
        ? item.accurateMatchLabel ?? item.originalTitle
        : item.summary,
    subtitle: isExternal ? item.originalTitle : item.sourceAttribution,
    sourceLabel: item.sourceAttribution,
    thumbnailRef: item.thumbnailRef,
    isExternal: isExternal,
  );
}

bool _isYoutube(AiSearchItem item) {
  final descriptor = item.embedDescriptor;
  return descriptor != null &&
      descriptor.kind == EmbedKind.youtubeIframe &&
      descriptor.externalId.isNotEmpty;
}

Uri? _externalUri(AiSearchItem item) {
  final descriptor = item.embedDescriptor;
  if (descriptor == null) {
    return null;
  }
  if (descriptor.sourceUrl.isNotEmpty) {
    return Uri.tryParse(descriptor.sourceUrl);
  }
  if (descriptor.kind == EmbedKind.youtubeIframe) {
    return Uri.parse(
      'https://www.youtube.com/watch?v=${descriptor.externalId}',
    );
  }
  return null;
}
