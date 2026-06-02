import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_design_system/loom_design_system.dart';

class ExtensionRuntimeModule extends StatefulWidget {
  const ExtensionRuntimeModule({
    required this.channelId,
    required this.passportId,
    required this.module,
    required this.theme,
    super.key,
  });

  final String channelId;
  final String passportId;
  final SurfaceModule module;
  final LoomChannelTheme theme;

  @override
  State<ExtensionRuntimeModule> createState() => _ExtensionRuntimeModuleState();
}

class _ExtensionRuntimeModuleState extends State<ExtensionRuntimeModule> {
  late final ExtensionRuntimeApi _runtimeApi;
  late final FanWalletApi _walletApi;
  ExtensionSession? _session;
  ExtensionStateExport? _state;
  Wallet? _wallet;
  String _status = 'Starting extension session...';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _runtimeApi = resolveExtensionRuntimeApi();
    _walletApi = resolveFanWalletApi();
    _load();
  }

  @override
  void didUpdateWidget(ExtensionRuntimeModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId ||
        oldWidget.passportId != widget.passportId ||
        oldWidget.module.moduleId != widget.module.moduleId ||
        oldWidget.module.extensionId != widget.module.extensionId) {
      _load();
    }
  }

  Future<void> _load() async {
    final extensionId = widget.module.extensionId;
    if (extensionId == null) {
      setState(() => _status = 'Extension install is missing.');
      return;
    }
    setState(() => _busy = true);
    final session = await _runtimeApi.createExtensionSession(
      channelId: widget.channelId,
      extensionId: extensionId,
      surface: widget.module.surface,
      fanId: widget.passportId,
      idempotencyKey:
          'p17-session-${widget.passportId}-${widget.channelId}-${widget.module.moduleId}',
    );
    final export = await _runtimeApi.createExtensionStateExport(
      channelId: widget.channelId,
      fanId: null,
    );
    final wallet = extensionId == 'ext_hypewars'
        ? await _walletApi.getWallet(widget.passportId)
        : _wallet;
    if (!mounted) {
      return;
    }
    setState(() {
      _session = session;
      _state = export;
      _wallet = wallet;
      _status = 'Session ${session.sessionId} active.';
      _busy = false;
    });
  }

  Future<void> _submit(
    String type,
    Map<String, String> payload, {
    String? idempotencyKey,
  }) async {
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() => _busy = true);
    await _runtimeApi.submitExtensionEvent(
      sessionId: session.sessionId,
      type: type,
      payload: payload,
      idempotencyKey:
          idempotencyKey ??
          'p17-$type-${session.sessionId}-${DateTime.now().microsecondsSinceEpoch}',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final extensionId = widget.module.extensionId;
    if (extensionId == null) {
      return const LoomErrorState(
        title: 'Extension unavailable',
        body: 'This module is missing an installed extension reference.',
      );
    }
    if (_busy && (_session == null || _state == null)) {
      return const LoadingSkeleton(rows: 3, title: 'Starting extension');
    }
    if (_session == null || _state == null) {
      return LoomErrorState(
        title: 'Extension unavailable',
        body: _status,
        onRetry: _load,
      );
    }
    switch (extensionId) {
      case 'ext_clip_arena':
        return ClipArenaModule(
          seasonLabel: _moduleConfig('season', 'Season ladder'),
          prompt: _moduleConfig('cta', 'Vote the best creator clip'),
          entries: _clipEntries(),
          theme: widget.theme,
          statusLabel: _status,
          onSubmitClip: _submitClip,
          onVoteLeader: _voteLeader,
        );
      case 'ext_pickem':
        return PickEmModule(
          question: _moduleConfig('question', 'Creator prediction'),
          options: _pickOptions(),
          selectedPick: _selectedPick(),
          standings: _pickStandings(),
          theme: widget.theme,
          statusLabel: _status,
          onPick: _makePick,
        );
      case 'ext_hypewars':
        return HypeWarsModule(
          goalLabel: _moduleConfig('goal', 'Community hype goal'),
          totalCents: _hypeTotalCents(),
          goalCents: _moduleInt('goalCents', 10000),
          walletBalanceCents: _wallet?.simulatedBalanceCents ?? 0,
          theme: widget.theme,
          statusLabel: _status,
          onSendHype: _sendHype,
        );
      case 'ext_quest_log':
        return QuestLogModule(
          questTitle: _moduleConfig('quest', 'Creator quest'),
          questDescription: _moduleConfig(
            'description',
            'Complete the creator challenge and earn a badge.',
          ),
          badges: _questBadges(),
          completions: _questCompletions(),
          theme: widget.theme,
          statusLabel: _status,
          onCompleteQuest: _completeQuest,
        );
      case 'ext_build_showcase':
        return BuildShowcaseModule(
          prompt: _moduleConfig('prompt', 'Submit your best fan build.'),
          submissions: _buildSubmissions(),
          theme: widget.theme,
          statusLabel: _status,
          onSubmitBuild: _submitBuild,
          onVoteFeatured: _voteFeaturedBuild,
        );
      case 'ext_guild_quest':
        return GuildQuestModule(
          goalLabel: _moduleConfig('goal', 'Shared guild objective'),
          current: _guildCurrent(),
          target: _moduleInt('target', 25),
          milestones: _guildMilestones(),
          theme: widget.theme,
          statusLabel: _status,
          onContribute: _contributeGuild,
        );
    }
    return ExtensionSlot(
      name: widget.module.title,
      surface: widget.module.surface,
      version: _session?.version ?? '1.0.0',
      theme: widget.theme,
      summary: 'This certified extension is waiting for its runtime module.',
    );
  }

  Future<void> _submitClip() async {
    final clipId = 'clip_${DateTime.now().microsecondsSinceEpoch}';
    await _submit('clip_submitted', {
      'clipId': clipId,
      'title': _moduleConfig('seedHeadline', 'Fan clutch clip'),
      'submitter': 'You',
      'season': _moduleConfig('season', 'Current season'),
    });
  }

  Future<void> _voteLeader() async {
    final leader = _clipEntries().firstOrNull;
    if (leader == null) {
      return;
    }
    await _submit('clip_vote', {
      'clipId': leader.clipId,
      'title': leader.title,
      'season': _moduleConfig('season', 'Current season'),
      'rewardCode': 'clip_arena_vote_badge',
    });
  }

  Future<void> _makePick(String pick) async {
    await _submit(
      'pick_made',
      {
        'name': 'You',
        'pick': pick,
        'points': '10',
        'question': _moduleConfig('question', 'Creator prediction'),
        'rewardCode': 'pickem_ladder_points',
      },
      idempotencyKey:
          'p17-pick-${widget.passportId}-${widget.channelId}-${widget.module.moduleId}',
    );
  }

  Future<void> _sendHype() async {
    final intent = await _walletApi.createPaymentIntent(
      passportId: widget.passportId,
      kind: PurchaseKind.extensionHype,
      creatorId: widget.channelId,
      idempotencyKey:
          'p17-hype-intent-${widget.passportId}-${widget.channelId}-${DateTime.now().microsecondsSinceEpoch}',
    );
    final confirmed = await _walletApi.confirmPaymentIntent(
      paymentIntentId: intent.id,
      idempotencyKey: 'p17-hype-confirm-${intent.id}',
    );
    await _submit('hype_sent', {
      'amountCents': '${confirmed.amountCents}',
      'paymentIntentId': confirmed.id,
      'goal': _moduleConfig('goal', 'Community hype goal'),
      'rewardCode': 'hypewars_boost',
    });
  }

  Future<void> _completeQuest() async {
    final questId = _moduleConfig('questId', 'main');
    await _submit(
      'quest_completed',
      {
        'questId': questId,
        'title': _moduleConfig('quest', 'Creator quest'),
        'badge': _moduleConfig('badge', 'Quest badge'),
        'rewardCode': 'quest_badge_$questId',
      },
      idempotencyKey:
          'p18-quest-${widget.passportId}-${widget.channelId}-${widget.module.moduleId}-$questId',
    );
  }

  Future<void> _submitBuild() async {
    final buildId = 'build_${DateTime.now().microsecondsSinceEpoch}';
    await _submit('build_submitted', {
      'buildId': buildId,
      'title': _moduleConfig('seedHeadline', 'Fan showcase build'),
      'submitter': 'You',
    });
  }

  Future<void> _voteFeaturedBuild() async {
    final leader = _buildSubmissions().firstOrNull;
    if (leader == null) {
      return;
    }
    await _submit('build_vote', {
      'buildId': leader.submissionId,
      'title': leader.title,
      'featured': 'true',
      'rewardCode': 'build_showcase_featured_vote',
    });
  }

  Future<void> _contributeGuild() async {
    await _submit('guild_contributed', {
      'amount': _moduleConfig('contribution', '5'),
      'target': '${_moduleInt('target', 25)}',
      'milestone': _moduleConfig('milestone', 'Community milestone'),
      'rewardCode': 'guild_quest_progress',
    });
  }

  List<ClipArenaEntry> _clipEntries() {
    final entries = _entriesForCurrentExtension()
        .where((entry) => entry.key.startsWith('clip:'))
        .map(
          (entry) => ClipArenaEntry(
            clipId: entry.value['clipId'] ?? entry.key.substring(5),
            title: entry.value['title'] ?? 'Fan clip',
            submitter: entry.value['submitter'] ?? 'Demo fan',
            votes: _parseInt(entry.value['votes'], 0),
          ),
        )
        .toList(growable: false);
    if (entries.isNotEmpty) {
      return entries;
    }
    return [
      ClipArenaEntry(
        clipId: 'seed_leader',
        title: _moduleConfig('seedHeadline', 'Featured clip'),
        submitter: 'Seeded fan',
        votes: 7,
      ),
      const ClipArenaEntry(
        clipId: 'seed_runner_up',
        title: 'Late-round save',
        submitter: 'Community pick',
        votes: 4,
      ),
    ];
  }

  List<PickEmStanding> _pickStandings() {
    final standings = _entriesForCurrentExtension()
        .where((entry) => entry.key.startsWith('pick:'))
        .map(
          (entry) => PickEmStanding(
            name: entry.value['name'] ?? 'Fan',
            pick: entry.value['pick'] ?? 'Undecided',
            points: _parseInt(entry.value['points'], 0),
          ),
        )
        .toList(growable: false);
    if (standings.isNotEmpty) {
      return standings;
    }
    final options = _pickOptions();
    return [
      PickEmStanding(name: 'NovaStack', pick: options.first, points: 18),
      PickEmStanding(
        name: 'RouteReader',
        pick: options.length > 1 ? options[1] : options.first,
        points: 12,
      ),
    ];
  }

  String? _selectedPick() {
    return _entriesForCurrentExtension()
        .where((entry) => entry.key == 'pick:${widget.passportId}')
        .firstOrNull
        ?.value['pick'];
  }

  int _hypeTotalCents() {
    final state = _entriesForCurrentExtension()
        .where((entry) => entry.key == 'hype_meter')
        .firstOrNull;
    return _parseInt(state?.value['totalCents'], 0);
  }

  int _questCompletions() {
    final questId = _moduleConfig('questId', 'main');
    final state = _entriesForCurrentExtension()
        .where((entry) => entry.key == 'quest:$questId')
        .firstOrNull;
    return _parseInt(state?.value['completions'], 0);
  }

  List<String> _questBadges() {
    final badges = _entriesForCurrentExtension()
        .where((entry) => entry.key.startsWith('badge:${widget.passportId}:'))
        .map((entry) => entry.value['badge'] ?? 'Quest badge')
        .toList(growable: false);
    if (badges.isNotEmpty) {
      return badges;
    }
    return [_moduleConfig('badge', 'Ready badge')];
  }

  List<ShowcaseSubmission> _buildSubmissions() {
    final submissions = _entriesForCurrentExtension()
        .where((entry) => entry.key.startsWith('build:'))
        .map(
          (entry) => ShowcaseSubmission(
            submissionId: entry.value['buildId'] ?? entry.key.substring(6),
            title: entry.value['title'] ?? 'Fan build',
            submitter: entry.value['submitter'] ?? 'Demo fan',
            votes: _parseInt(entry.value['votes'], 0),
            featured: entry.value['featured'] == 'true',
          ),
        )
        .toList(growable: false);
    if (submissions.isNotEmpty) {
      return submissions..sort((a, b) {
        if (a.featured != b.featured) {
          return a.featured ? -1 : 1;
        }
        return b.votes.compareTo(a.votes);
      });
    }
    return [
      ShowcaseSubmission(
        submissionId: 'seed_showcase',
        title: _moduleConfig('seedHeadline', 'Featured build'),
        submitter: 'Seeded fan',
        votes: 5,
        featured: true,
      ),
      const ShowcaseSubmission(
        submissionId: 'seed_gallery',
        title: 'Community gallery pick',
        submitter: 'Builder crew',
        votes: 3,
        featured: false,
      ),
    ];
  }

  int _guildCurrent() {
    final state = _entriesForCurrentExtension()
        .where((entry) => entry.key == 'guild_progress')
        .firstOrNull;
    return _parseInt(state?.value['current'], 0);
  }

  List<String> _guildMilestones() {
    final raw = _moduleConfig('milestones', '');
    final values = raw
        .split('|')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (values.isNotEmpty) {
      return values;
    }
    return const ['First milestone', 'Final reward'];
  }

  List<ExtensionStateEntry> _entriesForCurrentExtension() {
    final extensionId = widget.module.extensionId;
    final state = _state;
    if (state == null || extensionId == null) {
      return const [];
    }
    final aggregateScope = 'channel:${widget.channelId}:extension:$extensionId';
    return state.entries
        .where((entry) => entry.scopeKey == aggregateScope)
        .toList(growable: false);
  }

  List<String> _pickOptions() {
    final raw = _moduleConfig('options', '');
    final values = raw
        .split('|')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (values.isNotEmpty) {
      return values;
    }
    return const ['Creator wins', 'Rival wins', 'Overtime'];
  }

  String _moduleConfig(String key, String fallback) {
    final value = widget.module.config[key];
    return value == null || value.trim().isEmpty ? fallback : value;
  }

  int _moduleInt(String key, int fallback) {
    return _parseInt(widget.module.config[key], fallback);
  }
}

int _parseInt(String? value, int fallback) {
  return int.tryParse(value ?? '') ?? fallback;
}
