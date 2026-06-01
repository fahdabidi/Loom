import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorChannelHomeScreen extends StatefulWidget {
  const CreatorChannelHomeScreen({
    required this.channelId,
    required this.onOpenContent,
    required this.onBack,
    this.passportId = 'passport_demo_fan',
    super.key,
  });

  final String channelId;
  final String passportId;
  final ValueChanged<String> onOpenContent;
  final VoidCallback onBack;

  @override
  State<CreatorChannelHomeScreen> createState() =>
      _CreatorChannelHomeScreenState();
}

class _CreatorChannelHomeScreenState extends State<CreatorChannelHomeScreen> {
  late final CreatorMetadataApi _metadataApi;
  late final FanPassportApi _passportApi;
  ChannelHome? _home;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _metadataApi = resolveCreatorMetadataApi();
    _passportApi = resolveFanPassportApi();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final home = await _metadataApi.getChannelHome(
      channelId: widget.channelId,
      passportId: widget.passportId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _home = home;
      _loading = false;
    });
  }

  Future<void> _follow() async {
    await _passportApi.createFollow(
      passportId: widget.passportId,
      creatorId: widget.channelId,
      visibility: FollowVisibility.public,
      idempotencyKey: 'p4-follow-${widget.passportId}-${widget.channelId}',
    );
    await _load();
  }

  Future<void> _unfollow() async {
    await _passportApi.unfollow(
      passportId: widget.passportId,
      creatorId: widget.channelId,
      idempotencyKey: 'p4-unfollow-${widget.passportId}-${widget.channelId}',
    );
    await _load();
  }

  Future<void> _block() async {
    await _passportApi.blockCreator(
      passportId: widget.passportId,
      creatorId: widget.channelId,
      idempotencyKey: 'p4-block-${widget.passportId}-${widget.channelId}',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _home == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final home = _home!;
    final videos = home.content
        .where((content) => content.contentType == ContentType.video)
        .toList(growable: false);
    final posts = home.content
        .where((content) => content.contentType == ContentType.post)
        .toList(growable: false);

    return ListView(
      key: const ValueKey('p4_channel_home'),
      padding: EdgeInsets.zero,
      children: [
        CreatorChannelHeader(
          displayName: home.displayName,
          handle: home.handle,
          vertical: home.vertical,
          isFollowed: home.isFollowed,
          isBlocked: home.isBlocked,
          onFollow: _follow,
          onUnfollow: _unfollow,
          onBlock: _block,
          onBack: widget.onBack,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdPolicyNote(policy: home.adPolicy),
              const SizedBox(height: 18),
              _Section(
                title: 'Videos',
                items: videos,
                onOpenContent: widget.onOpenContent,
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Posts',
                items: posts,
                onOpenContent: widget.onOpenContent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdPolicyNote extends StatelessWidget {
  const _AdPolicyNote({required this.policy});

  final CreatorAdPolicy? policy;

  @override
  Widget build(BuildContext context) {
    final allowed = policy?.allowedCategories.join(', ') ?? 'contextual';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoomColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ads on this channel are contextual only. Allowed: $allowed. Blocked categories stay blocked.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LoomColors.mutedInk,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.onOpenContent,
  });

  final String title;
  final List<ContentSummaryView> items;
  final ValueChanged<String> onOpenContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        for (final item in items) ...[
          FeedCard(
            child: ListTile(
              key: ValueKey(
                item.contentType == ContentType.video
                    ? 'p4_content_video_${item.id}'
                    : 'p4_content_post_${item.id}',
              ),
              onTap: () => onOpenContent(item.id),
              leading: Icon(
                item.contentType == ContentType.video
                    ? Icons.play_circle_outline_rounded
                    : Icons.article_outlined,
              ),
              title: Text(item.title),
              subtitle: Text(item.summary, maxLines: 2),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
