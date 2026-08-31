part of '../loom_communities_app_shell.dart';

// ignore_for_file: unused_element, unused_element_parameter

class _CommunityBottomTabBar extends StatelessWidget {
  const _CommunityBottomTabBar({
    required this.tabs,
    required this.selectedTabId,
    required this.accent,
    required this.onSelected,
  });

  final List<LoomAppShellTabSpec> tabs;
  final String selectedTabId;
  final Color accent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final background = Color.alphaBlend(
      accent.withValues(alpha: 0.12),
      Theme.of(context).colorScheme.surface,
    );
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.24)),
          ),
        ),
        child: SizedBox(
          height: 76,
          child: ListView.separated(
            key: const ValueKey('community-bottom-tabs'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final selected = tab.tabId == selectedTabId;
              return Semantics(
                selected: selected,
                button: true,
                label: '${tab.label} tab',
                child: InkWell(
                  key: ValueKey('community-tab-${tab.tabId}'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelected(tab.tabId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(minWidth: 94),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : Colors.white.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? accent
                            : accent.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab.icon,
                          size: 21,
                          color: selected ? Colors.white : accent,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: selected ? Colors.white : accent,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemCount: tabs.length,
          ),
        ),
      ),
    );
  }
}

class _SelectedTabHeader extends StatelessWidget {
  const _SelectedTabHeader({
    required this.tab,
    required this.accent,
    required this.actorIdentity,
    this.modernTheme,
  });

  final LoomAppShellTabSpec tab;
  final Color accent;
  final LoomActorIdentity actorIdentity;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent.withValues(alpha: 0.90);
    final body =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.88);
    return DecoratedBox(
      key: ValueKey('selected-tab-${tab.tabId}'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Icon(tab.icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    tab.descriptionFor(actorIdentity),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: body),
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

/// Real, interactive Messages tab — inbox list, thread detail, composer.
/// Replaces the old static `_MessagesTabSurface` mock entirely.
class _MessagesTabSurface extends StatefulWidget {
  const _MessagesTabSurface({
    required this.experience,
    required this.actorIdentity,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomActorIdentity actorIdentity;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_MessagesTabSurface> createState() => _MessagesTabSurfaceState();
}

class _MessagesTabSurfaceState extends State<_MessagesTabSurface> {
  static final _stores = <String, _MessagesEngineStore>{};

  late final _MessagesEngineStore _store;
  final _composerController = TextEditingController();
  WorkflowInstance? _selectedThread;
  var _loaded = false;
  var _visibleThreadCount = 0;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _store = _stores.putIfAbsent(
      widget.experience.extensionId,
      () => _MessagesEngineStore(
        communityId: widget.experience.extensionId,
        seedThreads: widget.experience.threads,
      ),
    );
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_MessagesTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.actorIdentity.roleId != widget.actorIdentity.roleId ||
        oldWidget.actorIdentity.accountId != widget.actorIdentity.accountId)) {
      _selectedThread = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    try {
      await _store.ensureReady();
      final threads = await _store.threadsFor(widget.actorIdentity.fanId);
      if (!mounted) return;
      setState(() {
        _visibleThreadCount = threads.length;
        _loaded = true;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loaded = true;
      });
    }
  }

  Future<void> _toggleThread(WorkflowInstance thread) async {
    if (_selectedThread?.instanceId == thread.instanceId) {
      setState(() => _selectedThread = null);
      return;
    }
    await _store.markRead(thread: thread, fanId: widget.actorIdentity.fanId);
    if (mounted) setState(() => _selectedThread = thread);
  }

  Future<void> _sendReply() async {
    final text = _composerController.text.trim();
    final thread = _selectedThread;
    if (text.isEmpty || thread == null) return;
    await _store.postMessage(
      thread: thread,
      body: text,
      fanId: widget.actorIdentity.fanId,
    );
    _composerController.clear();
    final refreshed = await _store.threadById(
      thread.instanceId,
      widget.actorIdentity.fanId,
    );
    if (mounted && refreshed != null)
      setState(() => _selectedThread = refreshed);
  }

  Future<void> _toggleMute(WorkflowInstance thread) async {
    await _store.setMuted(
      thread: thread,
      muted: !_store.isMuted(thread),
      fanId: widget.actorIdentity.fanId,
    );
    final refreshed = await _store.threadById(
      thread.instanceId,
      widget.actorIdentity.fanId,
    );
    if (mounted && refreshed != null)
      setState(() => _selectedThread = refreshed);
  }

  Future<void> _toggleArchive(WorkflowInstance thread) async {
    await _store.setArchived(
      thread: thread,
      archived: !_store.isArchived(thread),
      fanId: widget.actorIdentity.fanId,
    );
    if (mounted) setState(() => _selectedThread = null);
    await _load();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Text(_loadError!, key: const ValueKey('messages-load-error'));
    }
    final selectedThread = _selectedThread;
    if (selectedThread != null) {
      final thread = _store.toThread(selectedThread);
      return _ThreadDetailView(
        thread: thread,
        foreground: foreground,
        accent: widget.accent,
        modernTheme: widget.modernTheme,
        fanId: widget.actorIdentity.fanId,
        composerController: _composerController,
        muted: _store.isMuted(selectedThread),
        onSend: _sendReply,
        onBack: () => setState(() => _selectedThread = null),
        onToggleMute: () => unawaited(_toggleMute(selectedThread)),
        onToggleArchive: () => unawaited(_toggleArchive(selectedThread)),
      );
    }
    if (_visibleThreadCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, color: foreground, size: 56),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.experience.displayName} hasn\'t published any threads for ${widget.actorIdentity.label} yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.86),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final inboxFill = widget.modernTheme?.resolvedFill ?? widget.accent;
    final inboxBorder =
        widget.modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    return Column(
      key: const ValueKey('messages-tab-surface'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: inboxFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: inboxBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.forum_outlined, color: foreground, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.experience.displayName} inbox',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$_visibleThreadCount thread${_visibleThreadCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        RepeaterSurface.live(
          key: ValueKey('messages-repeater-${widget.actorIdentity.fanId}'),
          refreshInterval: const Duration(milliseconds: 50),
          querySource: RepeaterQuerySource(
            engine: _store.engine,
            workflowType: _MessagesEngineStore.workflowType,
            fanId: widget.actorIdentity.fanId,
            tabId: 'messages',
          ),
          listShrinkWrap: true,
          listScrollable: false,
          itemBuilder: (context, item) {
            final instance = item as WorkflowInstance;
            final thread = _store.toThread(instance);
            if (!_store.isVisibleTo(instance, widget.actorIdentity.fanId) ||
                _store.isArchived(instance)) {
              return const SizedBox.shrink();
            }
            final unread = _store.isUnread(
              instance,
              widget.actorIdentity.fanId,
            );
            final preview = _store.lastPreview(instance);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: InkWell(
                key: ValueKey('messages-inbox-item-${thread.threadId}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => unawaited(_toggleThread(instance)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: foreground.withValues(alpha: 0.14),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: foreground.withValues(alpha: 0.14),
                      child: Icon(
                        _store.isMuted(instance)
                            ? Icons.volume_off_outlined
                            : Icons.mark_chat_unread_outlined,
                        color: foreground,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        if (unread) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  widget.modernTheme?.accent ?? widget.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            thread.subject,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      preview,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.80),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '${thread.messages.length}',
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Expanded thread detail view with chronological message bubbles
/// and a working composer at the bottom.
class _ThreadDetailView extends StatelessWidget {
  const _ThreadDetailView({
    required this.thread,
    required this.foreground,
    required this.accent,
    this.modernTheme,
    required this.fanId,
    required this.composerController,
    required this.muted,
    required this.onSend,
    required this.onBack,
    required this.onToggleMute,
    required this.onToggleArchive,
  });

  final LoomMessageThread thread;
  final Color foreground;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final String fanId;
  final TextEditingController composerController;
  final bool muted;
  final VoidCallback onSend;
  final VoidCallback onBack;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final headerFill = modernTheme?.resolvedFill ?? accent;
    final headerBorder =
        modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18);
    return Column(
      key: ValueKey('messages-thread-detail-${thread.threadId}'),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: headerFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: headerBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: foreground,
                  onPressed: onBack,
                  tooltip: 'Back to inbox',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thread.subject,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        '${thread.messages.length} message${thread.messages.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    muted ? Icons.volume_up : Icons.volume_off,
                    size: 20,
                  ),
                  color: foreground,
                  tooltip: muted ? 'Unmute' : 'Mute',
                  onPressed: onToggleMute,
                ),
                IconButton(
                  icon: const Icon(Icons.archive_outlined, size: 20),
                  color: foreground,
                  tooltip: 'Archive',
                  onPressed: onToggleArchive,
                ),
              ],
            ),
          ),
        ),
        // Unrolled message list (no Expanded/ListView — parent is
        // SingleChildScrollView via _TabNativeRenderer)
        for (final message in thread.messages) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Align(
              alignment: message.senderFanId == fanId
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: message.senderFanId == fanId
                      ? (modernTheme?.accent ?? accent).withValues(alpha: 0.18)
                      : foreground.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.body,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: foreground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.64),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: foreground.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('messages-composer-field'),
                    controller: composerController,
                    style: TextStyle(color: foreground),
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      hintStyle: TextStyle(
                        color: foreground.withValues(alpha: 0.60),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  key: const ValueKey('messages-send-button'),
                  icon: const Icon(Icons.send),
                  color: foreground,
                  tooltip: 'Send',
                  onPressed: onSend,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatMessageTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class _MessagesEngineStore {
  _MessagesEngineStore({
    required this.communityId,
    List<LoomMessageThread>? seedThreads,
  }) : _seedThreads = seedThreads ?? _tabletopSeedThreads;

  static const workflowType = 'discussion-thread';
  static const messageWorkflowType = 'discussion-message';
  // Real per-account ids (see part30_local_auth_api.dart's
  // _seedTabletopAccounts) -- not the two generic role ids. Seed
  // threads must list actual accounts as participants so an individually
  // signed-in member's own threadsFor(fanId) query (which checks
  // participantFanIds.contains(fanId) against the real signed-in
  // account id, not the role) actually finds them.
  static const _allTabletopAccountIds = [
    'tabletop-organizer',
    'tabletop-member-03',
    'tabletop-member-04',
    'tabletop-member-05',
    'tabletop-member-06',
    'tabletop-member-07',
    'tabletop-member-08',
    'tabletop-member-09',
    'tabletop-member-10',
    'tabletop-member-11',
    'tabletop-member-12',
    'tabletop-member-13',
    'tabletop-member-14',
  ];
  static final _tabletopSeedThreads = <LoomMessageThread>[
    LoomMessageThread(
      threadId: 'tabletop-campaign-night',
      subject: 'Campaign night: table assignments',
      participantFanIds: _allTabletopAccountIds,
      messages: [
        LoomMessage(
          messageId: 'tabletop-1',
          senderFanId: 'tabletop-organizer',
          body: 'Tables are set for Friday. Please confirm your seat.',
          timestamp: DateTime(2026, 7, 10, 18),
        ),
      ],
    ),
    LoomMessageThread(
      threadId: 'tabletop-library',
      subject: 'Library game suggestions',
      participantFanIds: _allTabletopAccountIds,
      messages: [
        LoomMessage(
          messageId: 'tabletop-2',
          senderFanId: 'tabletop-member-03',
          body: 'I would love to try Cascadia next month.',
          timestamp: DateTime(2026, 7, 9, 16, 30),
        ),
      ],
    ),
    LoomMessageThread(
      threadId: 'tabletop-volunteers',
      subject: 'Teach-a-game volunteer sign-up',
      participantFanIds: _allTabletopAccountIds,
      messages: [
        LoomMessage(
          messageId: 'tabletop-3',
          senderFanId: 'tabletop-organizer',
          body: 'Thanks for helping new members learn a game.',
          timestamp: DateTime(2026, 7, 8, 12),
        ),
      ],
    ),
  ];

  final String communityId;
  final List<LoomMessageThread> _seedThreads;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: communityId,
  );
  Future<void>? _readyFuture;
  var _ready = false;

  WorkflowEngineApi get engine => _engine;

  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _readyFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _engine.registerDefinition(_machine);
    _engine.registerDefinition(_messageMachine);
    for (final thread in _seedThreads) {
      await _engine.createInstance(
        workflowType: workflowType,
        fanId: thread.messages.firstOrNull?.senderFanId ?? 'tabletop-organizer',
        initialInstanceData: {
          'threadId': thread.threadId,
          'subject': thread.subject,
          'participantFanIds': thread.participantFanIds,
          'messages': [
            for (final message in thread.messages)
              {
                'messageId': message.messageId,
                'senderFanId': message.senderFanId,
                'body': message.body,
                'timestamp': message.timestamp.toUtc().toIso8601String(),
              },
          ],
          'readByFanIds': const <String>[],
          'muted': thread.muted,
          'archived': thread.archived,
          'draftBody': '',
        },
      );
      for (final message in thread.messages) {
        await _engine.createInstance(
          workflowType: messageWorkflowType,
          fanId: message.senderFanId,
          initialInstanceData: {
            'threadId': thread.threadId,
            'messageId': message.messageId,
            'senderFanId': message.senderFanId,
            'body': message.body,
            'timestamp': message.timestamp.toUtc().toIso8601String(),
          },
        );
      }
    }
    _ready = true;
  }

  Future<List<WorkflowInstance>> threadsFor(String fanId) async {
    await ensureReady();
    final page = await _engine.queryInstances(
      tabId: 'messages',
      fanId: fanId,
      limit: 1000,
      query: const SurfaceQuery(sort: SortSpec(key: 'subject')),
    );
    return page.items
        .where(
          (thread) =>
              thread.workflowType == workflowType &&
              isVisibleTo(thread, fanId) &&
              !isArchived(thread),
        )
        .toList(growable: false);
  }

  Future<WorkflowInstance?> threadById(String instanceId, String fanId) async {
    final page = await _engine.queryInstances(
      tabId: 'messages',
      fanId: fanId,
      limit: 1000,
    );
    for (final thread in page.items) {
      if (thread.instanceId == instanceId) return thread;
    }
    return null;
  }

  Future<void> markRead({
    required WorkflowInstance thread,
    required String fanId,
  }) => _engine.applyTransition(
    workflowType: workflowType,
    instanceId: thread.instanceId,
    transitionId: 'mark-read',
    fanId: fanId,
  );

  Future<void> postMessage({
    required WorkflowInstance thread,
    required String body,
    required String fanId,
  }) async {
    await _engine.updateInstanceFields(
      workflowType: workflowType,
      instanceId: thread.instanceId,
      fieldUpdates: {'draftBody': body},
      fanId: fanId,
    );
    await _engine.applyTransition(
      workflowType: workflowType,
      instanceId: thread.instanceId,
      transitionId: 'post-message',
      fanId: fanId,
    );
  }

  Future<void> setMuted({
    required WorkflowInstance thread,
    required bool muted,
    required String fanId,
  }) => _engine.updateInstanceFields(
    workflowType: workflowType,
    instanceId: thread.instanceId,
    fieldUpdates: {'muted': muted},
    fanId: fanId,
  );

  Future<void> setArchived({
    required WorkflowInstance thread,
    required bool archived,
    required String fanId,
  }) => _engine.updateInstanceFields(
    workflowType: workflowType,
    instanceId: thread.instanceId,
    fieldUpdates: {'archived': archived},
    fanId: fanId,
  );

  bool isVisibleTo(WorkflowInstance thread, String fanId) =>
      (thread.instanceData['participantFanIds'] as List? ?? const []).contains(
        fanId,
      );
  bool isMuted(WorkflowInstance thread) => thread.instanceData['muted'] == true;
  bool isArchived(WorkflowInstance thread) =>
      thread.instanceData['archived'] == true;
  bool isUnread(WorkflowInstance thread, String fanId) =>
      !(thread.instanceData['readByFanIds'] as List? ?? const []).contains(
        fanId,
      );
  String lastPreview(WorkflowInstance thread) {
    final messages = _messages(thread);
    final text = messages.isEmpty ? '' : messages.last.body;
    return text.length > 60 ? '${text.substring(0, 57)}...' : text;
  }

  LoomMessageThread toThread(WorkflowInstance thread) => LoomMessageThread(
    threadId: thread.instanceId,
    subject: '${thread.instanceData['subject'] ?? ''}',
    participantFanIds: [
      for (final id
          in thread.instanceData['participantFanIds'] as List? ?? const [])
        '$id',
    ],
    messages: _messages(thread),
    muted: isMuted(thread),
    archived: isArchived(thread),
  );

  List<LoomMessage> _messages(WorkflowInstance thread) => [
    for (final raw in thread.instanceData['messages'] as List? ?? const [])
      if (raw is Map)
        LoomMessage(
          messageId: '${raw['messageId'] ?? ''}',
          senderFanId: '${raw['senderFanId'] ?? ''}',
          body: '${raw['body'] ?? ''}',
          timestamp:
              DateTime.tryParse('${raw['timestamp'] ?? ''}')?.toLocal() ??
              DateTime.fromMillisecondsSinceEpoch(0),
        ),
  ];

  static final _machine = const LoomWorkflowStateMachine(
    workflowType: workflowType,
    initialState: 'open',
    states: const {
      'open': LoomWorkflowState(
        label: 'Open',
        editableFields: ['draftBody', 'muted', 'archived'],
      ),
    },
    transitions: const [
      LoomWorkflowTransition(
        id: 'mark-read',
        label: 'Mark read',
        from: ['open'],
        to: 'open',
        effects: [
          WorkflowEffect(
            op: 'appendUnique',
            key: 'readByFanIds',
            value: r'$actor',
          ),
        ],
      ),
      LoomWorkflowTransition(
        id: 'post-message',
        label: 'Post message',
        from: ['open'],
        to: 'open',
        effects: [
          WorkflowEffect(
            op: 'append',
            key: 'messages',
            value: {
              'messageId': r'$timestamp-$actor',
              'senderFanId': r'$actor',
              'body': '{draftBody}',
              'timestamp': r'$timestamp',
            },
          ),
          WorkflowEffect(
            op: 'createInstance',
            workflowType: messageWorkflowType,
            fields: {
              'threadId': '{threadId}',
              'messageId': r'$timestamp-$actor',
              'senderFanId': r'$actor',
              'body': '{draftBody}',
              'timestamp': r'$timestamp',
            },
          ),
          WorkflowEffect(op: 'set', key: 'draftBody', value: ''),
        ],
      ),
    ],
    renderBindings: const [
      RenderBinding(
        states: ['open'],
        role: 'any',
        tabId: 'messages',
        cardSurfaceFamily: 'discussionThread',
        bindingKind: 'primary',
      ),
    ],
    instanceDataSchema: const {
      'threadId': InstanceDataField(type: 'string', required: true),
      'subject': InstanceDataField(
        type: 'text',
        required: true,
        searchable: true,
        sortable: true,
      ),
      'participantFanIds': InstanceDataField(type: 'fanId[]', required: true),
      'messages': InstanceDataField(type: 'list', writableBy: 'effect'),
      'readByFanIds': InstanceDataField(type: 'fanId[]', writableBy: 'effect'),
      'muted': InstanceDataField(type: 'boolean'),
      'archived': InstanceDataField(type: 'boolean'),
      'draftBody': InstanceDataField(type: 'text'),
    },
  );

  static final _messageMachine = const LoomWorkflowStateMachine(
    workflowType: messageWorkflowType,
    initialState: 'posted',
    states: const {'posted': LoomWorkflowState(label: 'Posted')},
    transitions: const [],
    instanceDataSchema: const {
      'threadId': InstanceDataField(type: 'string', required: true),
      'messageId': InstanceDataField(type: 'string', required: true),
      'senderFanId': InstanceDataField(type: 'fanId', required: true),
      'body': InstanceDataField(type: 'text', required: true, searchable: true),
      'timestamp': InstanceDataField(type: 'text', required: true),
    },
  );
}

typedef _WorkflowSurfaceBuilder =
    Widget Function(
      LoomWorkflowDefinition workflow,
      SurfacePresentationState state,
    );

class _TabNativeRenderer extends StatelessWidget {
  const _TabNativeRenderer({
    super.key,
    required this.experience,
    required this.actorIdentity,
    required this.selectedTab,
    required this.sections,
    required this.focusedWorkflowId,
    required this.expandedWorkflowId,
    required this.accent,
    required this.theme,
    required this.workflowBuilder,
    this.reminderEnabledWorkflowIds = const {},
    this.onToggleReminder,
    this.onSelectCalendarDate,
    this.onConfirmWorkflow,
    this.onInstanceScopedCreate,
    this.onFocusedInstanceChanged,
    this.completedWorkflowIds = const {},
  });

  final LoomExperienceDefinition experience;
  final LoomActorIdentity actorIdentity;
  final LoomAppShellTabSpec selectedTab;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final LoomSurfaceTheme theme;
  final _WorkflowSurfaceBuilder workflowBuilder;
  final Set<String> reminderEnabledWorkflowIds;
  final ValueChanged<String>? onToggleReminder;
  final ValueChanged<String>? onSelectCalendarDate;
  final ValueChanged<LoomWorkflowDefinition>? onConfirmWorkflow;
  final EngineNativeInstanceScopedCreate? onInstanceScopedCreate;
  final ValueChanged<WorkflowInstance?>? onFocusedInstanceChanged;
  final Set<String> completedWorkflowIds;

  @override
  Widget build(BuildContext context) {
    final rendererId = selectedTab.rendererContract.rendererId;
    final modernTheme = theme.usesModernCardTheme ? theme.tabCard : null;
    // Renderer selection has already reconciled this tab's bindings. A
    // renderer case never reinterprets the community-owned tab id.
    switch (rendererId) {
      case 'CalendarTabSurface':
        return EngineNativeCalendarSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          tabId: selectedTab.tabId,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceScopedCreate: onInstanceScopedCreate,
          onFocusedInstanceChanged: onFocusedInstanceChanged,
        );
      case 'NotificationDedicatedTabSurface':
        return _NotificationDedicatedTabSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'MessagesTabSurface':
        return EngineNativeListSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          tabId: selectedTab.tabId,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceScopedCreate: onInstanceScopedCreate,
        );
      case 'EngineNativeGenericListSurface':
        return EngineNativeListSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          tabId: selectedTab.tabId,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceScopedCreate: onInstanceScopedCreate,
        );
      case 'MarketplaceTabSurface':
        return EngineNativeMarketplaceSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          tabId: selectedTab.tabId,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'PaymentGivingTabSurface':
        return EngineNativeListSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          tabId: selectedTab.tabId,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceScopedCreate: onInstanceScopedCreate,
        );
      case 'DocumentsTabSurface':
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'WorkflowStatusSurface':
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'CareVolunteerTabSurface':
        // These domain tabs render via placeholder until their data is declared
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'AdminReviewComposeTabSurface':
        return EngineNativeListSurface(
          experience: experience,
          actorIdentity: actorIdentity,
          tabId: selectedTab.tabId,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceScopedCreate: onInstanceScopedCreate,
          rolesForInstance: (instance, viewerFanId) {
            final definitions = experience.workflowDefinitions;
            if (definitions == null) return const <String>[];
            final machine = definitions[instance.workflowType];
            if (machine == null) return const <String>[];
            return deriveInstanceRoles(
              machine,
              instance,
              viewerFanId: viewerFanId,
              viewerRoleId: actorIdentity.roleId,
            );
          },
        );
    }
    return _HomeTabSurfaceStack(
      experience: experience,
      sections: sections,
      focusedWorkflowId: focusedWorkflowId,
      expandedWorkflowId: expandedWorkflowId,
      accent: accent,
      theme: theme,
      workflowBuilder: workflowBuilder,
    );
  }
}

SurfacePresentationState _presentationStateForWorkflow({
  required String workflowId,
  required String? focusedWorkflowId,
  required String? expandedWorkflowId,
}) {
  if (expandedWorkflowId == workflowId) {
    return SurfacePresentationState.expanded;
  }
  if (focusedWorkflowId == workflowId) {
    return SurfacePresentationState.medium;
  }
  return SurfacePresentationState.minimized;
}

List<LoomWorkflowDefinition> _workflowsFromSections(
  List<_CommunityWorkflowSection> sections,
) {
  return [
    for (final section in sections)
      for (final workflow in section.workflows) workflow,
  ];
}

class _HomeTabSurfaceStack extends StatelessWidget {
  const _HomeTabSurfaceStack({
    required this.experience,
    required this.sections,
    required this.focusedWorkflowId,
    required this.expandedWorkflowId,
    required this.accent,
    required this.theme,
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final LoomSurfaceTheme theme;
  final _WorkflowSurfaceBuilder workflowBuilder;

  @override
  Widget build(BuildContext context) {
    final modernTheme = theme.usesModernCardTheme ? theme.tabCard : null;
    if (sections.isEmpty) {
      return _TabEmptyState(
        icon: Icons.home_outlined,
        title: 'Nothing is pinned yet',
        body:
            '${experience.displayName} does not have Home surfaces assigned yet.',
        accent: accent,
        modernTheme: modernTheme,
      );
    }
    return Column(
      key: const ValueKey('home-tab-surface-stack'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabNativeSummary(
          icon: Icons.home_outlined,
          title: '${experience.displayName} home',
          body:
              'A person'
              'alized community home with curated surfaces, theme tokens, and minimized/medium/expanded presentation.',
          accent: accent,
          modernTheme: modernTheme,
          facts: [
            '${sections.length} sections',
            theme.imageTreatment,
            theme.density,
          ],
        ),
        const SizedBox(height: 12),
        for (final section in sections) ...[
          _CommunitySectionHeader(
            title: section.title,
            subtitle: section.subtitle,
            icon: section.icon,
            accent: accent,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 8),
          for (final workflow in section.workflows)
            workflowBuilder(
              workflow,
              _presentationStateForWorkflow(
                workflowId: workflow.workflowId,
                focusedWorkflowId: focusedWorkflowId,
                expandedWorkflowId: expandedWorkflowId,
              ),
            ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

String _isoDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[(month - 1).clamp(0, 11)];
}

class CalendarEventDetail extends StatefulWidget {
  const CalendarEventDetail({
    required this.accent,
    this.modernTheme,
    required this.workflow,
    this.instance,
    this.machine,
    required this.fanId,
    required this.roleId,
    this.reminderEnabled = false,
    required this.onTransitionApplied,
    this.onToggleReminder,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final LoomWorkflowDefinition workflow;
  final WorkflowInstance? instance;
  final LoomWorkflowStateMachine? machine;
  final String fanId;
  final String roleId;
  final bool reminderEnabled;
  final Future<void> Function(WorkflowInstance instance, String transitionId)
  onTransitionApplied;
  final VoidCallback? onToggleReminder;

  @override
  State<CalendarEventDetail> createState() => _CalendarEventDetailState();
}

class _CalendarEventDetailState extends State<CalendarEventDetail> {
  var _transitionInFlight = false;

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final fill =
        widget.modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.08), widget.accent);
    final border =
        widget.modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final item = widget.workflow.calendarItem!;
    return DecoratedBox(
      key: ValueKey('calendar-event-detail-${widget.workflow.workflowId}'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: foreground,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _displayTitleFor(widget.workflow),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (widget.onToggleReminder != null)
                  IconButton(
                    key: ValueKey(
                      'calendar-reminder-toggle-${widget.workflow.workflowId}',
                    ),
                    tooltip: widget.reminderEnabled
                        ? 'Turn off reminder'
                        : 'Remind me',
                    onPressed: widget.onToggleReminder,
                    icon: Icon(
                      widget.reminderEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_none_outlined,
                      color: foreground,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            WorkflowCardSurfaceTemplateRenderer(
              surfaceFamily: 'event-rsvp',
              actionSurfaceKey: 'calendar',
              displayContext: 'detail',
              foreground: foreground,
              accent: widget.accent,
              instanceData: _eventRsvpInstanceData(item, widget.instance),
              instanceDataSchema: eventRsvpDefaultInstanceDataSchema,
              availableTransitions: _eventRsvpTransitions(widget.instance),
              onTransitionPressed: _transitionInFlight
                  ? null
                  : _applyEngineTransition,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyEngineTransition(String transitionId) async {
    final instance = widget.instance;
    if (instance == null) return;
    setState(() => _transitionInFlight = true);
    await widget.onTransitionApplied(instance, transitionId);
    if (!mounted) return;
    setState(() => _transitionInFlight = false);
  }

  Map<String, dynamic> _eventRsvpInstanceData(
    LoomCalendarItem item,
    WorkflowInstance? instance,
  ) {
    final data = instance?.instanceData ?? const <String, dynamic>{};
    final responseId = _responseIdForFan(data, widget.fanId);
    final responseLabel = responseId == null
        ? ''
        : _labelForResponse(responseId);
    final goingFanIds = _stringList(data['goingFanIds']);
    final waitlistedFanIds = _stringList(data['waitlistedFanIds']);
    final capacity =
        _intData(data['capacity']) ??
        _capacityFromLabel(item.capacityLabel) ??
        goingFanIds.length;
    return {
      'eventDate': data['eventDate'] ?? _formatEventDate(item.dateTime),
      'eventDateTime':
          data['eventDateTime'] ?? _formatEventDateTime(item.dateTime),
      'host': data['host'] ?? item.host ?? '',
      'location': data['location'] ?? item.location ?? '',
      'capacityLabel': _capacityLabel(goingFanIds.length, capacity),
      'rsvpStatus': responseLabel,
      'waitlistedFanIds': waitlistedFanIds,
      'reminderState': widget.reminderEnabled ? 'Reminder set' : '',
    };
  }

  List<WorkflowActionButtonTransition> _eventRsvpTransitions(
    WorkflowInstance? instance,
  ) {
    final machine = widget.machine;
    if (machine == null || instance == null) return const [];
    final currentResponseId = _responseIdForFan(
      instance.instanceData,
      widget.fanId,
    );
    final transitions = machine
        .transitionsFrom(instance.currentState)
        .where(
          (transition) => evaluateGuard(
            transition.guard,
            widget.fanId,
            instance.instanceData,
            roleId: widget.roleId,
          ),
        )
        .where((transition) => transition.id != 'cancel-event')
        .toList();
    return [
      for (final transition in transitions)
        WorkflowActionButtonTransition(
          id: transition.id,
          label: currentResponseId == transition.id
              ? '${transition.label} selected'
              : transition.label,
          iconName: transition.icon,
          tone: _toneForEventTransition(transition),
        ),
    ];
  }

  String _labelForResponse(String responseId) {
    final choices = widget.workflow.responseChoices;
    if (choices != null) {
      for (final choice in choices) {
        if (choice.responseId == responseId) return choice.label;
      }
    }
    switch (responseId) {
      case 'going':
        return 'Going';
      case 'maybe':
        return 'Maybe';
      case 'waitlist':
        return 'Join waitlist';
      case 'not-going':
        return 'Not going';
      default:
        return responseId;
    }
  }
}

String? _responseIdForFan(Map<String, dynamic> instanceData, String fanId) {
  final responseMap = instanceData['rsvpByFan'];
  if (responseMap is Map) {
    final response = responseMap[fanId];
    if (response is String && response.trim().isNotEmpty) {
      return response;
    }
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value.map((item) => '$item').toList(growable: false);
  }
  return const [];
}

int? _intData(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int? _capacityFromLabel(String? label) {
  if (label == null) return null;
  final match = RegExp(r'\d+\s+of\s+(\d+)').firstMatch(label);
  return int.tryParse(match?.group(1) ?? '');
}

String _capacityLabel(int goingCount, int capacity) {
  return '$goingCount of $capacity seats filled';
}

WorkflowActionTone _toneForEventTransition(LoomWorkflowTransition transition) {
  return switch (transition.tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };
}

String _formatEventDate(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[(dateTime.month - 1).clamp(0, 11)];
  return '$month ${dateTime.day}';
}

String _formatEventDateTime(DateTime dateTime) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[(dateTime.month - 1).clamp(0, 11)];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$month ${dateTime.day}, $hour:$minute $period';
}

/// Real, interactive Marketplace tab — search, category filter, responsive
/// grid, listing detail, and loan/queue action wired via onConfirmWorkflow.
class _WorkflowStatusTabSurface extends StatelessWidget {
  const _WorkflowStatusTabSurface({
    required this.experience,
    required this.sections,
    required this.focusedWorkflowId,
    required this.expandedWorkflowId,
    required this.accent,
    this.modernTheme,
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final _WorkflowSurfaceBuilder workflowBuilder;

  @override
  Widget build(BuildContext context) {
    final workflows = _workflowsFromSections(sections);
    if (workflows.isEmpty) {
      return _TabEmptyState(
        icon: Icons.timeline_outlined,
        title: 'No active requests',
        body:
            'Submitted, under-review, feedback-needed, payment-needed, and completed requests will appear here.',
        accent: accent,
        modernTheme: modernTheme,
      );
    }
    return Column(
      key: const ValueKey('workflow-status-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusTimelinePreview(accent: accent, modernTheme: modernTheme),
        const SizedBox(height: 12),
        for (final workflow in workflows)
          workflowBuilder(
            workflow,
            _presentationStateForWorkflow(
              workflowId: workflow.workflowId,
              focusedWorkflowId: focusedWorkflowId,
              expandedWorkflowId: expandedWorkflowId,
            ),
          ),
      ],
    );
  }
}

class _PaymentGivingTabSurface extends _WorkflowStatusTabSurface {
  const _PaymentGivingTabSurface({
    required super.experience,
    required super.sections,
    required super.focusedWorkflowId,
    required super.expandedWorkflowId,
    required super.accent,
    super.modernTheme,
    required super.workflowBuilder,
  });
}

/// Real Giving tab — amount/purpose summary, checkout CTA (→ action surface
/// via the resolved real giving workflow), receipt after payment, failure/
/// retry, and conditional recurring/entitlement rows.
class _CareVolunteerTabSurface extends _WorkflowStatusTabSurface {
  const _CareVolunteerTabSurface({
    required super.experience,
    required super.sections,
    required super.focusedWorkflowId,
    required super.expandedWorkflowId,
    required super.accent,
    super.modernTheme,
    required super.workflowBuilder,
  });
}

class _AdminReviewComposeTabSurface extends _WorkflowStatusTabSurface {
  const _AdminReviewComposeTabSurface({
    required super.experience,
    required super.sections,
    required super.focusedWorkflowId,
    required super.expandedWorkflowId,
    required super.accent,
    super.modernTheme,
    required super.workflowBuilder,
  });
}

class _TabNativeSummary extends StatelessWidget {
  const _TabNativeSummary({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    this.modernTheme,
    required this.facts,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill =
        modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.08), accent);
    final border =
        modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18);
    final bodyColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: bodyColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fact in facts)
                  _SurfaceFactPill(
                    icon: Icons.check_circle_outline,
                    label: fact,
                    foreground: foreground,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    this.modernTheme,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent.withValues(alpha: 0.82);
    final border =
        modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18);
    final bodyColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.90);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: bodyColor),
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

/// Empty-state placeholder shown when a community has declared a domain tab
/// (e.g. Marketplace, Documents, Care, Admin) but hasn't yet populated its
/// data. Replaces the old mock renderers with an honest "coming soon" card
/// themed to the community accent.
class _TabPlaceholderSurface extends StatelessWidget {
  const _TabPlaceholderSurface({
    required this.tabLabel,
    required this.communityName,
    required this.tabIcon,
    required this.accent,
    this.modernTheme,
  });

  final String tabLabel;
  final String communityName;
  final IconData tabIcon;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent.withValues(alpha: 0.82);
    final border =
        modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18);
    final bodyColor =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.86);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tabIcon, color: foreground, size: 56),
            const SizedBox(height: 20),
            Text(
              '$tabLabel is coming to $communityName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'This tab will light up when $communityName publishes '
                  '${tabLabel.toLowerCase()} content. Check back soon.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: bodyColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTimelinePreview extends StatelessWidget {
  const _StatusTimelinePreview({required this.accent, this.modernTheme});

  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent;
    final body =
        modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.92);
    const steps = ['Submitted', 'Review', 'Changes', 'Approved'];
    return DecoratedBox(
      key: const ValueKey('workflow-status-timeline-preview'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      i < 2
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      color: foreground,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: body),
                      ),
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

class _InboxPreviewCard extends StatelessWidget {
  const _InboxPreviewCard({
    required this.accent,
    this.modernTheme,
    required this.title,
    required this.sender,
    required this.preview,
    required this.timestamp,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final String title;
  final String sender;
  final String preview;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    return DecoratedBox(
      key: const ValueKey('messages-inbox-preview'),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: foreground.withValues(alpha: 0.14),
          child: Icon(Icons.mark_chat_unread_outlined, color: foreground),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '$sender - $preview',
          style: TextStyle(color: foreground.withValues(alpha: 0.90)),
        ),
        trailing: Text(
          timestamp,
          style: TextStyle(color: foreground.withValues(alpha: 0.82)),
        ),
      ),
    );
  }
}

class _ThreadComposerPreview extends StatelessWidget {
  const _ThreadComposerPreview({required this.accent, this.modernTheme});

  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    return DecoratedBox(
      key: const ValueKey('messages-thread-composer-preview'),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Write a reply or start a thread',
                style: TextStyle(color: foreground.withValues(alpha: 0.84)),
              ),
            ),
            Icon(Icons.attach_file_outlined, color: foreground),
            const SizedBox(width: 12),
            Icon(Icons.send_outlined, color: foreground),
          ],
        ),
      ),
    );
  }
}
