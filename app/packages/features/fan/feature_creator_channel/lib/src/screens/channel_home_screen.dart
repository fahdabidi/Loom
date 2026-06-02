import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class CreatorChannelHomeScreen extends StatefulWidget {
  const CreatorChannelHomeScreen({
    required this.channelId,
    required this.onOpenContent,
    required this.onBack,
    this.onAskArchive,
    this.passportId = 'passport_demo_fan',
    super.key,
  });

  final String channelId;
  final String passportId;
  final ValueChanged<String> onOpenContent;
  final VoidCallback onBack;
  final ValueChanged<String>? onAskArchive;

  @override
  State<CreatorChannelHomeScreen> createState() =>
      _CreatorChannelHomeScreenState();
}

class _CreatorChannelHomeScreenState extends State<CreatorChannelHomeScreen> {
  late final CreatorMetadataApi _metadataApi;
  late final FanPassportApi _passportApi;
  late final CreatorExperienceApi _experienceApi;
  ChannelHome? _home;
  CreatorExperienceConfig? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _metadataApi = resolveCreatorMetadataApi();
    _passportApi = resolveFanPassportApi();
    _experienceApi = resolveCreatorExperienceApi();
    _load();
  }

  @override
  void didUpdateWidget(CreatorChannelHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId ||
        oldWidget.passportId != widget.passportId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final homeFuture = _metadataApi.getChannelHome(
      channelId: widget.channelId,
      passportId: widget.passportId,
    );
    final configFuture = _experienceApi.getExperienceConfig(
      channelId: widget.channelId,
    );
    final home = await homeFuture;
    final config = await configFuture;
    if (!mounted) {
      return;
    }
    setState(() {
      _home = home;
      _config = config;
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
    if (_loading || _home == null || _config == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final home = _home!;
    final config = _config!;
    final theme = _toLoomTheme(config.theme);
    final modules =
        config.surfaceModules
            .where((module) => module.enabled)
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.background),
      child: ListView(
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
            channelTheme: theme,
            bannerRef: config.bannerRef,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdPolicyNote(
                  policy: home.adPolicy,
                  posture: config.adPosture,
                  theme: theme,
                ),
                if (widget.onAskArchive != null) ...[
                  const SizedBox(height: 12),
                  _ArchivePersonaEntry(
                    persona: config.aiPersona,
                    theme: theme,
                    onPressed: () => widget.onAskArchive?.call(home.creatorId),
                  ),
                ],
                const SizedBox(height: 18),
                for (final module in modules) ...[
                  KeyedSubtree(
                    key: ValueKey(
                      'p16_module_${home.creatorId}_${module.moduleId}',
                    ),
                    child: _buildModule(
                      context,
                      module: module,
                      config: config,
                      home: home,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModule(
    BuildContext context, {
    required SurfaceModule module,
    required CreatorExperienceConfig config,
    required ChannelHome home,
    required LoomChannelTheme theme,
  }) {
    switch (module.kind) {
      case 'hero':
        return ChannelSurfaceModule(
          title: module.title,
          subtitle: 'Theme: ${config.theme.name}',
          icon: Icons.travel_explore_rounded,
          theme: theme,
          child: Text(
            '${config.aiPersona}\nAd posture: ${config.adPosture}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: theme.text, height: 1.28),
          ),
        );
      case 'content':
        return ChannelSurfaceModule(
          title: module.title,
          subtitle: 'Creator-owned posts and videos',
          icon: Icons.video_library_rounded,
          theme: theme,
          child: _ContentRail(
            items: home.content,
            onOpenContent: widget.onOpenContent,
          ),
        );
      case 'extension':
        final install = _installedExtensionFor(config, module.extensionId);
        return ChannelSurfaceModule(
          title: module.title,
          subtitle: install == null
              ? 'Extension slot'
              : '${install.name} is approved for ${install.surfaces.join(', ')}',
          icon: Icons.extension_rounded,
          theme: theme,
          child: ExtensionSlot(
            name: install?.name ?? module.title,
            surface: module.surface,
            version: install?.version ?? 'pending',
            theme: theme,
            summary: _extensionSummary(module),
          ),
        );
    }
    return ChannelSurfaceModule(
      title: module.title,
      subtitle: 'Safe placeholder',
      icon: Icons.widgets_rounded,
      theme: theme,
      child: Text(
        'This module type is not active yet. The channel renderer kept the surface stable.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: theme.text, height: 1.25),
      ),
    );
  }
}

class _ArchivePersonaEntry extends StatelessWidget {
  const _ArchivePersonaEntry({
    required this.persona,
    required this.theme,
    required this.onPressed,
  });

  final String persona;
  final LoomChannelTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const ValueKey('p5_open_archive_qa_button'),
      onPressed: onPressed,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: Text(persona, maxLines: 2, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _AdPolicyNote extends StatelessWidget {
  const _AdPolicyNote({
    required this.policy,
    required this.posture,
    required this.theme,
  });

  final CreatorAdPolicy? policy;
  final String posture;
  final LoomChannelTheme theme;

  @override
  Widget build(BuildContext context) {
    final allowed = policy?.allowedCategories.join(', ') ?? 'contextual';
    return Container(
      key: const ValueKey('p16_ad_posture_note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withAlpha(44)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: theme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ads: $posture. Allowed: $allowed. Blocked categories stay blocked.',
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

class _ContentRail extends StatelessWidget {
  const _ContentRail({required this.items, required this.onOpenContent});

  final List<ContentSummaryView> items;
  final ValueChanged<String> onOpenContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items.take(5)) ...[
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

InstalledExtensionRef? _installedExtensionFor(
  CreatorExperienceConfig config,
  String? extensionId,
) {
  if (extensionId == null) {
    return null;
  }
  return config.installedExtensions
      .where((install) => install.extensionId == extensionId)
      .firstOrNull;
}

String _extensionSummary(SurfaceModule module) {
  return module.config['cta'] ??
      module.config['question'] ??
      module.config['quest'] ??
      module.config['prompt'] ??
      module.config['goal'] ??
      'This certified extension is installed and ready for the next interactive phase.';
}

LoomChannelTheme _toLoomTheme(ChannelTheme theme) {
  return LoomChannelTheme.fromHex(
    themeId: theme.themeId,
    name: theme.name,
    primaryHex: theme.primaryHex,
    secondaryHex: theme.secondaryHex,
    backgroundHex: theme.backgroundHex,
    surfaceHex: theme.surfaceHex,
    textHex: theme.textHex,
    accentHex: theme.accentHex,
  );
}
