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
    required this.persona,
    this.modernTheme,
  });

  final LoomAppShellTabSpec tab;
  final Color accent;
  final LoomPersonaDefinition persona;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent.withValues(alpha: 0.90);
    final body = modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.88);
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
                    tab.descriptionFor(persona),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: body,
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

/// Real, interactive Messages tab — inbox list, thread detail, composer.
/// Replaces the old static `_MessagesTabSurface` mock entirely.
class _MessagesTabSurface extends StatefulWidget {
  const _MessagesTabSurface({
    required this.experience,
    required this.persona,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_MessagesTabSurface> createState() => _MessagesTabSurfaceState();
}

class _MessagesTabSurfaceState extends State<_MessagesTabSurface> {
  final _composerController = TextEditingController();
  String? _selectedThreadId;
  final _readMessageIds = <String>{};
  final _mutedThreadIds = <String>{};
  final _archivedThreadIds = <String>{};
  // Locally-authored replies keyed by threadId
  final _localReplies = <String, List<LoomMessage>>{};

  List<LoomMessageThread> get _threads =>
      widget.experience.threads ?? const [];

  List<LoomMessageThread> get _visibleThreads {
    return _threads
        .where((thread) =>
            thread.participantPersonaIds.contains(widget.persona.personaId) &&
            !_archivedThreadIds.contains(thread.threadId))
        .toList();
  }

  LoomMessageThread? get _selectedThread {
    if (_selectedThreadId == null) return null;
    try {
      final base = _threads.firstWhere(
        (thread) => thread.threadId == _selectedThreadId,
      );
      final replies = _localReplies[_selectedThreadId] ?? const [];
      return base.copyWith(messages: [...base.messages, ...replies]);
    } catch (_) {
      return null;
    }
  }

  bool _isUnread(String threadId) {
    final thread = _threads.firstWhere((thread) => thread.threadId == threadId);
    return thread.messages.any(
      (message) => !_readMessageIds.contains(message.messageId),
    );
  }

  String _lastPreview(String threadId) {
    final thread = _threads.firstWhere((thread) => thread.threadId == threadId);
    final last = thread.messages.isNotEmpty ? thread.messages.last.body : '';
    return last.length > 60 ? '${last.substring(0, 57)}...' : last;
  }

  void _toggleThread(String threadId) {
    setState(() {
      if (_selectedThreadId == threadId) {
        _selectedThreadId = null;
      } else {
        _selectedThreadId = threadId;
        // Mark all messages as read
        final thread = _threads.firstWhere((thread) => thread.threadId == threadId);
        for (final message in thread.messages) {
          _readMessageIds.add(message.messageId);
        }
        final replies = _localReplies[threadId];
        if (replies != null) {
          for (final message in replies) {
            _readMessageIds.add(message.messageId);
          }
        }
      }
    });
  }

  void _sendReply() {
    final text = _composerController.text.trim();
    if (text.isEmpty || _selectedThreadId == null) return;
    final message = LoomMessage(
      messageId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderPersonaId: widget.persona.personaId,
      body: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _localReplies.update(
        _selectedThreadId!,
        (list) => [...list, message],
        ifAbsent: () => [message],
      );
      _readMessageIds.add(message.messageId);
      _composerController.clear();
    });
  }

  void _toggleMute(String threadId) {
    setState(() {
      if (_mutedThreadIds.contains(threadId)) {
        _mutedThreadIds.remove(threadId);
      } else {
        _mutedThreadIds.add(threadId);
      }
    });
  }

  void _toggleArchive(String threadId) {
    setState(() {
      if (_archivedThreadIds.contains(threadId)) {
        _archivedThreadIds.remove(threadId);
      } else {
        _archivedThreadIds.add(threadId);
        if (_selectedThreadId == threadId) {
          _selectedThreadId = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.modernTheme?.resolvedHeading ??
        _foregroundFor(widget.accent);
    final visibleThreads = _visibleThreads;
    if (_selectedThread != null) {
      return _ThreadDetailView(
        thread: _selectedThread!,
        foreground: foreground,
        accent: widget.accent,
        modernTheme: widget.modernTheme,
        personaId: widget.persona.personaId,
        composerController: _composerController,
        muted: _mutedThreadIds.contains(_selectedThreadId!),
        onSend: _sendReply,
        onBack: () => setState(() => _selectedThreadId = null),
        onToggleMute: () => _toggleMute(_selectedThreadId!),
        onToggleArchive: () => _toggleArchive(_selectedThreadId!),
      );
    }
    if (visibleThreads.isEmpty) {
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
                '${widget.experience.displayName} hasn\'t published any threads for ${widget.persona.label} yet.',
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
    final inboxBorder = widget.modernTheme?.resolvedBorder ??
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
                    '${visibleThreads.length} thread${visibleThreads.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Unrolled inbox list (no Expanded/ListView — parent is
        // SingleChildScrollView via _TabNativeRenderer)
        for (final thread in visibleThreads) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: InkWell(
              key: ValueKey('messages-inbox-item-${thread.threadId}'),
              borderRadius: BorderRadius.circular(14),
              onTap: () => _toggleThread(thread.threadId),
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
                      _mutedThreadIds.contains(thread.threadId)
                          ? Icons.volume_off_outlined
                          : Icons.mark_chat_unread_outlined,
                      color: foreground,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      if (_isUnread(thread.threadId)) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.modernTheme?.accent ?? widget.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          thread.subject,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: _isUnread(thread.threadId)
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
                    _lastPreview(thread.threadId),
                    style: TextStyle(color: foreground.withValues(alpha: 0.80)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${thread.messages.length}',
                    style: TextStyle(color: foreground.withValues(alpha: 0.72)),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    required this.personaId,
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
  final String personaId;
  final TextEditingController composerController;
  final bool muted;
  final VoidCallback onSend;
  final VoidCallback onBack;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final headerFill = modernTheme?.resolvedFill ?? accent;
    final headerBorder = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              alignment:
                  message.senderPersonaId == personaId
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
                  color:
                      message.senderPersonaId == personaId
                          ? (modernTheme?.accent ?? accent)
                              .withValues(alpha: 0.18)
                          : foreground.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.body,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foreground,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMessageTime(message.timestamp),
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
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

typedef _WorkflowSurfaceBuilder =
    Widget Function(
      LoomWorkflowDefinition workflow,
      SurfacePresentationState state,
    );

class _TabNativeRenderer extends StatelessWidget {
  const _TabNativeRenderer({
    required this.experience,
    required this.persona,
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
    this.completedWorkflowIds = const {},
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
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
  final Set<String> completedWorkflowIds;

  @override
  Widget build(BuildContext context) {
    final rendererId = selectedTab.rendererContract.rendererId;
    final modernTheme = theme.usesModernCardTheme ? theme.tabCard : null;
    // Messages and Home are the only present-by-default domain tabs.
    // Marketplace and Giving are data-driven: real UI when data declared,
    // placeholder otherwise. Other domain tabs stay placeholder-only.
    switch (rendererId) {
      case 'CalendarTabSurface':
        if (_isGardenEngineExperience(experience)) {
          return _GardenClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isCameraEngineExperience(experience)) {
          return _CameraClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isBookEngineExperience(experience)) {
          return _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isChessEngineExperience(experience)) {
          return _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        return _CalendarTabSurface(
          experience: experience,
          communityId: experience.extensionId,
          persona: persona,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
          reminderEnabledWorkflowIds: reminderEnabledWorkflowIds,
          onToggleReminder: onToggleReminder,
          onSelectCalendarDate: onSelectCalendarDate,
        );
      case 'MessagesTabSurface':
        if (_isCameraEngineExperience(experience)) {
          return _CameraClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isBookEngineExperience(experience)) {
          return _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isChessEngineExperience(experience)) {
          return _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        return _MessagesTabSurface(
          experience: experience,
          persona: persona,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'MarketplaceTabSurface':
        if (_isGardenEngineExperience(experience)) {
          return _GardenClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isCameraEngineExperience(experience)) {
          return _CameraClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isBookEngineExperience(experience)) {
          return _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isChessEngineExperience(experience)) {
          return _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        final listings = experience.marketplaceListings;
        if (listings != null && listings.isNotEmpty) {
          return _MarketplaceBrowseSurface(
            listings: listings,
            communityId: experience.extensionId,
            marketplaceTemplate: experience.marketplaceTemplate,
            workflows: experience.workflows,
            persona: persona,
            completedWorkflowIds: completedWorkflowIds,
            accent: accent,
            modernTheme: modernTheme,
            onConfirmWorkflow: onConfirmWorkflow,
          );
        }
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'PaymentGivingTabSurface':
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        // Find the first workflow in the Giving tab's sections whose
        // givingPayment is declared, to gate between real UI and placeholder.
        LoomWorkflowDefinition? givingWorkflow;
        for (final workflow in experience.workflows) {
          if (workflow.givingPayment != null) {
            givingWorkflow = workflow;
            break;
          }
        }
        if (givingWorkflow != null) {
          return _GivingTabSurface(
            givingPayment: givingWorkflow.givingPayment!,
            communityId: experience.extensionId,
            workflowId: givingWorkflow.workflowId,
            workflow: givingWorkflow,
            personaId: persona.personaId,
            personaLabel: persona.label,
            allowedPersonaIds: experience
                    .personaPolicies?[givingWorkflow.workflowId]
                    ?.actorPersonaIds ??
                [persona.personaId],
            accent: accent,
            modernTheme: modernTheme,
            onConfirmWorkflow: onConfirmWorkflow,
            paid: completedWorkflowIds.contains(givingWorkflow.workflowId),
          );
        }
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'DocumentsTabSurface':
        if (_isBookEngineExperience(experience)) {
          return _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isChessEngineExperience(experience)) {
          return _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isGardenEngineExperience(experience)) {
          return _GardenClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (experience.workflows.any((workflow) => workflow.documentLibrary != null)) {
          return _DocumentsTabSurface(
            experience: experience,
            persona: persona,
            sections: sections,
            focusedWorkflowId: focusedWorkflowId,
            expandedWorkflowId: expandedWorkflowId,
            accent: accent,
            modernTheme: modernTheme,
            workflowBuilder: workflowBuilder,
          );
        }
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'WorkflowStatusSurface':
        if (_isCameraEngineExperience(experience)) {
          return _CameraClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isBookEngineExperience(experience)) {
          return _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isChessEngineExperience(experience)) {
          return _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (experience.workflows.any(
          (workflow) => workflow.architecturalRequest != null,
        )) {
          return _ArchitecturalRequestTabSurface(
            experience: experience,
            persona: persona,
            boardMode: false,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'CareVolunteerTabSurface':
        if (_isGardenEngineExperience(experience)) {
          return _GardenClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (experience.workflows.any(
          (workflow) => workflow.architecturalRequest != null,
        )) {
          return _ArchitecturalRequestTabSurface(
            experience: experience,
            persona: persona,
            boardMode: true,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        // These domain tabs render via placeholder until their data is declared
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'AdminReviewComposeTabSurface':
        if (_isCameraEngineExperience(experience)) {
          return _CameraClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isBookEngineExperience(experience)) {
          return _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isYouthSoccerEngineExperience(experience)) {
          return _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (_isChessEngineExperience(experience)) {
          return _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        if (experience.workflows.any(
          (workflow) => workflow.architecturalRequest != null,
        )) {
          return _ArchitecturalRequestTabSurface(
            experience: experience,
            persona: persona,
            boardMode: true,
            accent: accent,
            modernTheme: modernTheme,
          );
        }
        // These domain tabs render via placeholder until their data is declared
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
        );
    }
    if (_isGardenEngineExperience(experience)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GardenClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 12),
          _HomeTabSurfaceStack(
            experience: experience,
            sections: sections,
            focusedWorkflowId: focusedWorkflowId,
            expandedWorkflowId: expandedWorkflowId,
            accent: accent,
            theme: theme,
            workflowBuilder: workflowBuilder,
          ),
        ],
      );
    }
    if (_isCameraEngineExperience(experience)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CameraClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 12),
          _HomeTabSurfaceStack(
            experience: experience,
            sections: sections,
            focusedWorkflowId: focusedWorkflowId,
            expandedWorkflowId: expandedWorkflowId,
            accent: accent,
            theme: theme,
            workflowBuilder: workflowBuilder,
          ),
        ],
      );
    }
    if (_isBookEngineExperience(experience)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BookClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 12),
          _HomeTabSurfaceStack(
            experience: experience,
            sections: sections,
            focusedWorkflowId: focusedWorkflowId,
            expandedWorkflowId: expandedWorkflowId,
            accent: accent,
            theme: theme,
            workflowBuilder: workflowBuilder,
          ),
        ],
      );
    }
    if (_isYouthSoccerEngineExperience(experience)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _YouthSoccerEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 12),
          _HomeTabSurfaceStack(
            experience: experience,
            sections: sections,
            focusedWorkflowId: focusedWorkflowId,
            expandedWorkflowId: expandedWorkflowId,
            accent: accent,
            theme: theme,
            workflowBuilder: workflowBuilder,
          ),
        ],
      );
    }
    if (_isChessEngineExperience(experience)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChessClubEngineTabSurface(
            experience: experience,
            persona: persona,
            tabId: selectedTab.tabId,
            accent: accent,
            modernTheme: modernTheme,
          ),
          const SizedBox(height: 12),
          _HomeTabSurfaceStack(
            experience: experience,
            sections: sections,
            focusedWorkflowId: focusedWorkflowId,
            expandedWorkflowId: expandedWorkflowId,
            accent: accent,
            theme: theme,
            workflowBuilder: workflowBuilder,
          ),
        ],
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

bool _isGardenEngineExperience(LoomExperienceDefinition experience) {
  final ids = experience.workflows.map((workflow) => workflow.workflowId).toSet();
  return ids.contains('garden-event-rsvp') &&
      ids.contains('plant-exchange-submission') &&
      ids.contains('garden-tool-loan') &&
      ids.contains('garden-volunteer-shift') &&
      ids.contains('garden-export-custom-schemas');
}

bool _isCameraEngineExperience(LoomExperienceDefinition experience) {
  final ids = experience.workflows.map((workflow) => workflow.workflowId).toSet();
  return ids.contains('photo-walk-rsvp') &&
      ids.contains('critique-submission') &&
      ids.contains('gear-loan-request') &&
      ids.contains('camera-validation-report');
}

bool _isBookEngineExperience(LoomExperienceDefinition experience) {
  final ids = experience.workflows.map((workflow) => workflow.workflowId).toSet();
  return ids.contains('book-nomination') &&
      ids.contains('book-vote') &&
      ids.contains('book-meeting-rsvp') &&
      ids.contains('book-discussion-message') &&
      ids.contains('book-selection-publish') &&
      ids.contains('book-search-ai-digest');
}

bool _isYouthSoccerEngineExperience(LoomExperienceDefinition experience) {
  if (experience.extensionId == 'ext_youth_soccer') return true;
  final ids = experience.workflows.map((workflow) => workflow.workflowId).toSet();
  return ids.contains('soccer-guardian-join-approval') &&
      ids.contains('soccer-team-roster') &&
      ids.contains('soccer-practice-schedule') &&
      ids.contains('soccer-registration-payment');
}

bool _isChessEngineExperience(LoomExperienceDefinition experience) {
  if (experience.extensionId == 'ext_chess_club') return true;
  final ids = experience.workflows.map((workflow) => workflow.workflowId).toSet();
  return ids.contains('chess-match-meetup') &&
      ids.contains('chess-match-result') &&
      ids.contains('chess-rankings-table') &&
      ids.contains('chess-club-night');
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
              'A personalized community home with prioritized surfaces, theme tokens, and minimized/medium/expanded presentation.',
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

class _CalendarTabSurface extends StatefulWidget {
  const _CalendarTabSurface({
    required this.experience,
    required this.communityId,
    required this.persona,
    required this.sections,
    required this.focusedWorkflowId,
    required this.expandedWorkflowId,
    required this.accent,
    this.modernTheme,
    required this.workflowBuilder,
    this.reminderEnabledWorkflowIds = const {},
    this.onToggleReminder,
    this.onSelectCalendarDate,
  });

  final LoomExperienceDefinition experience;
  final String communityId;
  final LoomPersonaDefinition persona;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final _WorkflowSurfaceBuilder workflowBuilder;
  final Set<String> reminderEnabledWorkflowIds;
  final ValueChanged<String>? onToggleReminder;
  final ValueChanged<String>? onSelectCalendarDate;

  @override
  State<_CalendarTabSurface> createState() => _CalendarTabSurfaceState();
}

class _CalendarTabSurfaceState extends State<_CalendarTabSurface> {
  static const _eventRsvpResponseModel = {
    'kind': 'simpleRsvp',
    'responseMapField': 'rsvpByPersona',
    'audienceScopeField': 'audienceScope',
    'audienceMemberField': 'invitedPersonaIds',
    'capacityField': 'capacity',
    'goingListField': 'goingPersonaIds',
    'waitlistField': 'waitlistedPersonaIds',
    'waitlistPolicy': 'whenGoingCountReachesCapacity',
  };

  late final WorkflowDatabase _database;
  late final LocalWorkflowEngineApi _engine;
  final _machinesByWorkflowId = <String, LoomWorkflowStateMachine>{};
  final _instancesByWorkflowId = <String, WorkflowInstance>{};
  var _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _database = WorkflowDatabase.memory();
    _engine = LocalWorkflowEngineApi(
      db: _database,
      communityId: widget.communityId,
    );
    unawaited(_seedAndLoad());
  }

  @override
  void didUpdateWidget(_CalendarTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.communityId != widget.communityId ||
        oldWidget.persona.personaId != widget.persona.personaId) {
      _instancesByWorkflowId.clear();
      _machinesByWorkflowId.clear();
      _initialLoadComplete = false;
      unawaited(_seedAndLoad());
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _seedAndLoad() async {
    final workflows = _workflowsFromSections(widget.sections)
        .where((workflow) => workflow.calendarItem != null)
        .toList();
    final seededInstances = <String, WorkflowInstance>{};
    for (final workflow in workflows) {
      final machine = _machineForEvent(workflow);
      _machinesByWorkflowId[workflow.workflowId] = machine;
      _engine.registerDefinition(machine);
      final initialInstanceData = _initialEventInstanceData(workflow);
      final instanceId = await _engine.createInstance(
        workflowType: machine.workflowType,
        initialInstanceData: initialInstanceData,
        personaId: widget.persona.personaId,
      );
      seededInstances[workflow.workflowId] = WorkflowInstance(
        instanceId: instanceId,
        workflowType: machine.workflowType,
        currentState: machine.initialState,
        instanceData: initialInstanceData,
        createdByPersonaId: widget.persona.personaId,
      );
    }
    final page = await _engine.queryInstances(
      tabId: 'calendar',
      personaId: widget.persona.personaId,
      query: SurfaceQuery(
        sort: const SortSpec(key: 'eventDate'),
        audienceMemberField: _eventRsvpResponseModel['audienceMemberField']!,
        audienceScopeField: _eventRsvpResponseModel['audienceScopeField']!,
      ),
      limit: 100,
    );
    if (!mounted) return;
    setState(() {
      _instancesByWorkflowId
        ..clear()
        ..addAll(seededInstances)
        ..addEntries(
          page.items.map(
            (instance) => MapEntry(
              '${instance.instanceData['workflowId']}',
              instance,
            ),
          ),
        );
      _initialLoadComplete = true;
    });
  }

  Future<void> _applyTransition(
    WorkflowInstance instance,
    String transitionId,
  ) async {
    final result = await _engine.applyTransition(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    if (!mounted) return;
    setState(() {
      _instancesByWorkflowId['${instance.instanceData['workflowId']}'] =
          WorkflowInstance(
        instanceId: instance.instanceId,
        workflowType: instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: instance.createdByPersonaId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final workflows = _workflowsFromSections(widget.sections);
    if (workflows.isEmpty) {
      return _TabEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No upcoming dates',
        body:
            '${widget.experience.displayName} has no visible calendar items for this persona.',
        accent: widget.accent,
        modernTheme: widget.modernTheme,
      );
    }
    final selected = workflows.firstWhere(
      (workflow) => workflow.workflowId == widget.focusedWorkflowId,
      orElse: () => workflows.first,
    );
    final datedWorkflows =
        [
          for (final workflow in workflows)
            if (workflow.calendarItem != null) workflow,
        ]..sort(
          (a, b) =>
              a.calendarItem!.dateTime.compareTo(b.calendarItem!.dateTime),
        );

    if (datedWorkflows.isEmpty) {
      // No package-declared calendar data for this tab: preserve the
      // existing placeholder rendering rather than showing an empty/broken
      // date strip for catalog-driven communities that predate this field.
      return Column(
        key: const ValueKey('calendar-tab-surface'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekDateStrip(accent: widget.accent, modernTheme: widget.modernTheme),
          const SizedBox(height: 12),
          _TabNativeSummary(
            icon: Icons.event_available_outlined,
            title: _displayTitleFor(selected),
            body:
                'Agenda detail includes date, time, location, host, capacity, response choices, reminders, and linked workflow state.',
            accent: widget.accent,
            modernTheme: widget.modernTheme,
            facts: const ['Week view', 'Agenda', 'Event detail', 'Reminder'],
          ),
          const SizedBox(height: 12),
          for (final workflow in workflows)
            widget.workflowBuilder(
              workflow,
              _presentationStateForWorkflow(
                workflowId: workflow.workflowId,
                focusedWorkflowId: widget.focusedWorkflowId,
                expandedWorkflowId: widget.expandedWorkflowId,
              ),
            ),
        ],
      );
    }

    if (!_initialLoadComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedDated = datedWorkflows.firstWhere(
      (workflow) => workflow.workflowId == widget.focusedWorkflowId,
      orElse: () => datedWorkflows.first,
    );
    // Group dated workflows by date string (ISO date YYYY-MM-DD)
    final groupedByDate = <String, List<LoomWorkflowDefinition>>{};
    for (final wf in datedWorkflows) {
      final dateKey = _isoDateKey(wf.calendarItem!.dateTime);
      groupedByDate.putIfAbsent(dateKey, () => []).add(wf);
    }
    final dateKeys = groupedByDate.keys.toList()..sort();

    // Dedupe date-strip items by date key (one chip per date)
    final stripItems = <String, LoomWorkflowDefinition>{};
    for (final wf in datedWorkflows) {
      stripItems.putIfAbsent(_isoDateKey(wf.calendarItem!.dateTime), () => wf);
    }
    return Column(
      key: const ValueKey('calendar-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal quick-jump date strip — one chip per date, not per workflow
        _CalendarAgendaDateStrip(
          accent: widget.accent,
          modernTheme: widget.modernTheme,
          items: stripItems.values.toList()
            ..sort((a, b) => a.calendarItem!.dateTime.compareTo(b.calendarItem!.dateTime)),
          selectedWorkflowId: selectedDated.workflowId,
          onSelectWorkflow: widget.onSelectCalendarDate,
        ),
        const SizedBox(height: 12),
        // Vertical date-grouped agenda (unrolled — no Expanded/ListView
        // since _TabNativeRenderer's output lives inside a SingleChildScrollView)
        for (final dateKey in dateKeys) ...[
          Builder(builder: (context) {
            final events = groupedByDate[dateKey]!;
            final date = events.first.calendarItem!.dateTime;
            final foreground =
                widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date group header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          widget.modernTheme?.resolvedFill ??
                          widget.accent.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            widget.modernTheme?.resolvedBorder ??
                            widget.accent.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        '${_monthLabel(date.month)} ${date.day}',
                        key: ValueKey(
                          'calendar-agenda-date-group-$dateKey',
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
                // Event cards under this date
                for (final workflow in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CalendarEventCard(
                      workflow: workflow,
                      accent: widget.accent,
                      modernTheme: widget.modernTheme,
                      isFocused:
                          workflow.workflowId == selectedDated.workflowId,
                      reminderEnabled: widget.reminderEnabledWorkflowIds.contains(
                        workflow.workflowId,
                      ),
                      instance: _instancesByWorkflowId[workflow.workflowId],
                      machine: _machinesByWorkflowId[workflow.workflowId],
                      personaId: widget.persona.personaId,
                      onTransitionApplied: _applyTransition,
                      onTap: widget.onSelectCalendarDate == null
                          ? null
                          : () =>
                              widget.onSelectCalendarDate!(workflow.workflowId),
                      onToggleReminder: widget.onToggleReminder == null
                          ? null
                          : () =>
                              widget.onToggleReminder!(workflow.workflowId),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
        const SizedBox(height: 12),
        for (final workflow in workflows)
          widget.workflowBuilder(
            workflow,
            _presentationStateForWorkflow(
              workflowId: workflow.workflowId,
              focusedWorkflowId: widget.focusedWorkflowId,
              expandedWorkflowId: widget.expandedWorkflowId,
            ),
          ),
      ],
    );
  }

  LoomWorkflowStateMachine _machineForEvent(LoomWorkflowDefinition workflow) {
    final transitions = <LoomWorkflowTransition>[
      ..._responseTransitionsFor(workflow),
      const LoomWorkflowTransition(
        id: 'cancel-event',
        label: 'Cancel event',
        icon: 'cancel',
        tone: 'destructive',
        from: ['open'],
        to: 'cancelled',
        guard: WorkflowGuard(
          allowedPersonaIds: ['tabletop-organizer'],
        ),
      ),
    ];
    return LoomWorkflowStateMachine(
      workflowType: workflow.workflowId,
      initialState: 'open',
      states: const {
        'open': LoomWorkflowState(
          label: 'RSVP open',
          tone: 'positive',
          editableFields: [
            'title',
            'eventDate',
            'eventTime',
            'location',
            'capacity',
            'audienceScope',
            'invitedPersonaIds',
          ],
        ),
        'cancelled': LoomWorkflowState(
          label: 'Cancelled',
          tone: 'negative',
          isTerminal: true,
        ),
      },
      transitions: transitions,
      renderBindings: const [
        RenderBinding(
          states: ['open'],
          role: 'receiver',
          tabId: 'calendar',
          cardSurfaceFamily: 'event-rsvp',
          bindingKind: 'primary',
          audienceMemberField: 'invitedPersonaIds',
        ),
      ],
      instanceDataSchema: const {
        'workflowId': InstanceDataField(type: 'string', required: true),
        'title': InstanceDataField(
          type: 'text',
          required: true,
          searchable: true,
          sortable: true,
        ),
        'eventDate': InstanceDataField(type: 'date', required: true, sortable: true),
        'eventTime': InstanceDataField(type: 'time', required: true),
        'eventDateTime': InstanceDataField(type: 'text'),
        'host': InstanceDataField(type: 'text'),
        'location': InstanceDataField(type: 'text', required: true),
        'capacity': InstanceDataField(type: 'integer', required: true),
        'capacityLabel': InstanceDataField(type: 'text'),
        'audienceScope': InstanceDataField(type: 'audienceSelector', required: true),
        'invitedPersonaIds': InstanceDataField(type: 'personaId[]'),
        'rsvpByPersona': InstanceDataField(type: 'personaResponseMap'),
        'goingPersonaIds': InstanceDataField(type: 'personaId[]'),
        'waitlistedPersonaIds': InstanceDataField(type: 'personaId[]'),
      },
    );
  }

  List<LoomWorkflowTransition> _responseTransitionsFor(
    LoomWorkflowDefinition workflow,
  ) {
    final choices = workflow.responseChoices ?? const [
      LoomWorkflowResponseChoice(responseId: 'going', label: 'Going'),
      LoomWorkflowResponseChoice(responseId: 'maybe', label: 'Maybe'),
      LoomWorkflowResponseChoice(
        responseId: 'not-going',
        label: 'Not going',
        isDestructive: true,
      ),
    ];
    final result = <LoomWorkflowTransition>[
      for (final choice in choices)
        _transitionForResponseChoice(choice),
    ];
    if (!choices.any((choice) => choice.responseId == 'waitlist') &&
        _isCapacityFull(workflow.calendarItem?.capacityLabel)) {
      result.add(
        _transitionForResponseChoice(
          const LoomWorkflowResponseChoice(
            responseId: 'waitlist',
            label: 'Join waitlist',
          ),
        ),
      );
    }
    return result;
  }

  LoomWorkflowTransition _transitionForResponseChoice(
    LoomWorkflowResponseChoice choice,
  ) {
    final responseId = choice.responseId;
    return LoomWorkflowTransition(
      id: responseId,
      label: choice.label,
      icon: _iconNameForResponseId(responseId, choice.isDestructive),
      tone: choice.isDestructive
          ? 'destructive'
          : responseId == 'going'
              ? 'primary'
              : 'secondary',
      from: const ['open'],
      guard: const WorkflowGuard(
        allowedPersonaIds: ['tabletop-member', 'tabletop-member-owner'],
      ),
      effects: _effectsForResponse(responseId),
    );
  }

  List<WorkflowEffect> _effectsForResponse(String responseId) {
    return switch (responseId) {
      'going' => const [
          WorkflowEffect(op: 'set', key: r'rsvpByPersona.$actor', value: 'going'),
          WorkflowEffect(op: 'appendUnique', key: 'goingPersonaIds', value: r'$actor'),
          WorkflowEffect(op: 'removeValue', key: 'waitlistedPersonaIds', value: r'$actor'),
        ],
      'waitlist' => const [
          WorkflowEffect(op: 'set', key: r'rsvpByPersona.$actor', value: 'waitlist'),
          WorkflowEffect(op: 'appendUnique', key: 'waitlistedPersonaIds', value: r'$actor'),
          WorkflowEffect(op: 'removeValue', key: 'goingPersonaIds', value: r'$actor'),
        ],
      'not-going' => const [
          WorkflowEffect(op: 'set', key: r'rsvpByPersona.$actor', value: 'not-going'),
          WorkflowEffect(op: 'removeValue', key: 'goingPersonaIds', value: r'$actor'),
          WorkflowEffect(op: 'removeValue', key: 'waitlistedPersonaIds', value: r'$actor'),
        ],
      _ => [
          WorkflowEffect(op: 'set', key: r'rsvpByPersona.$actor', value: responseId),
          const WorkflowEffect(op: 'removeValue', key: 'goingPersonaIds', value: r'$actor'),
          const WorkflowEffect(op: 'removeValue', key: 'waitlistedPersonaIds', value: r'$actor'),
        ],
    };
  }

  Map<String, dynamic> _initialEventInstanceData(
    LoomWorkflowDefinition workflow,
  ) {
    final item = workflow.calendarItem!;
    final capacity = _capacityFromLabel(item.capacityLabel) ?? 20;
    final goingCount = _goingCountFromLabel(item.capacityLabel);
    final goingPersonaIds = [
      for (var i = 1; i <= goingCount; i++) 'seed-attendee-$i',
    ];
    return {
      'workflowId': workflow.workflowId,
      'title': _displayTitleFor(workflow),
      'eventDate': _isoDateKey(item.dateTime),
      'eventTime':
          '${item.dateTime.hour.toString().padLeft(2, '0')}:${item.dateTime.minute.toString().padLeft(2, '0')}',
      'eventDateTime': _formatEventDateTime(item.dateTime),
      'host': item.host ?? '',
      'location': item.location ?? '',
      'capacity': capacity,
      'capacityLabel': _capacityLabel(goingPersonaIds.length, capacity),
      'audienceScope': 'all',
      'invitedPersonaIds': <String>[],
      'rsvpByPersona': <String, dynamic>{},
      'goingPersonaIds': goingPersonaIds,
      'waitlistedPersonaIds': <String>[],
    };
  }
}

/// Compact event card for the date-grouped vertical agenda.
/// When focused, renders the full _CalendarEventDetail; otherwise
/// a tappable summary row. Tapping an unfocused card sets the
/// selection which expands it in-place.
class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.workflow,
    required this.accent,
    this.modernTheme,
    required this.isFocused,
    required this.reminderEnabled,
    this.instance,
    this.machine,
    required this.personaId,
    required this.onTransitionApplied,
    this.onTap,
    this.onToggleReminder,
  });

  final LoomWorkflowDefinition workflow;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final bool isFocused;
  final bool reminderEnabled;
  final WorkflowInstance? instance;
  final LoomWorkflowStateMachine? machine;
  final String personaId;
  final Future<void> Function(WorkflowInstance instance, String transitionId)
      onTransitionApplied;
  final VoidCallback? onTap;
  final VoidCallback? onToggleReminder;

  @override
  Widget build(BuildContext context) {
    if (isFocused) {
      return _CalendarEventDetail(
        accent: accent,
        modernTheme: modernTheme,
        workflow: workflow,
        instance: instance,
        machine: machine,
        personaId: personaId,
        reminderEnabled: reminderEnabled,
        onTransitionApplied: onTransitionApplied,
        onToggleReminder: onToggleReminder,
      );
    }
    final foreground =
        modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final item = workflow.calendarItem!;
    return InkWell(
      key: ValueKey('calendar-event-card-${workflow.workflowId}'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: foreground.withValues(alpha: 0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.event_outlined, color: foreground, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayTitleFor(workflow),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatEventDateTime(item.dateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.location != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: foreground.withValues(alpha: 0.60),
                    size: 18,
                  ),
                ),
              Icon(Icons.chevron_right, color: foreground, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

String _isoDateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _monthLabel(int month) {
  const labels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return labels[(month - 1).clamp(0, 11)];
}

class _CalendarAgendaDateStrip extends StatelessWidget {
  const _CalendarAgendaDateStrip({
    required this.accent,
    this.modernTheme,
    required this.items,
    required this.selectedWorkflowId,
    this.onSelectWorkflow,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final List<LoomWorkflowDefinition> items;
  final String selectedWorkflowId;
  final ValueChanged<String>? onSelectWorkflow;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final selectedFill = modernTheme?.accent ?? accent;
    final unselectedFill = modernTheme?.resolvedFill ??
        Colors.white.withValues(alpha: 0.72);
    final stripBorder = modernTheme?.resolvedBorder ??
        accent.withValues(alpha: 0.22);
    return SizedBox(
      key: const ValueKey('calendar-agenda-date-strip'),
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final workflow = items[index];
          final date = workflow.calendarItem!.dateTime;
          final selected = workflow.workflowId == selectedWorkflowId;
          return Semantics(
            key: ValueKey('calendar-agenda-date-${workflow.workflowId}'),
            selected: selected,
            button: onSelectWorkflow != null,
            label: '${_weekdayLabel(date.weekday)} ${date.day}',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onSelectWorkflow == null
                  ? null
                  : () => onSelectWorkflow!(workflow.workflowId),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? selectedFill : unselectedFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: stripBorder),
                ),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekdayLabel(date.weekday),
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(
                          color: selected ? foreground : accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: selected ? foreground : accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarEventDetail extends StatefulWidget {
  const _CalendarEventDetail({
    required this.accent,
    this.modernTheme,
    required this.workflow,
    this.instance,
    this.machine,
    required this.personaId,
    this.reminderEnabled = false,
    required this.onTransitionApplied,
    this.onToggleReminder,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final LoomWorkflowDefinition workflow;
  final WorkflowInstance? instance;
  final LoomWorkflowStateMachine? machine;
  final String personaId;
  final bool reminderEnabled;
  final Future<void> Function(WorkflowInstance instance, String transitionId)
      onTransitionApplied;
  final VoidCallback? onToggleReminder;

  @override
  State<_CalendarEventDetail> createState() => _CalendarEventDetailState();
}

class _CalendarEventDetailState extends State<_CalendarEventDetail> {
  var _transitionInFlight = false;

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final fill = widget.modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.08), widget.accent);
    final border = widget.modernTheme?.resolvedBorder ??
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
              onTransitionPressed:
                  _transitionInFlight ? null : _applyEngineTransition,
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
    final responseId = _responseIdForPersona(data, widget.personaId);
    final responseLabel = responseId == null ? '' : _labelForResponse(responseId);
    final goingPersonaIds = _stringList(data['goingPersonaIds']);
    final waitlistedPersonaIds = _stringList(data['waitlistedPersonaIds']);
    final capacity = _intData(data['capacity']) ??
        _capacityFromLabel(item.capacityLabel) ??
        goingPersonaIds.length;
    return {
      'eventDate': data['eventDate'] ?? _formatEventDate(item.dateTime),
      'eventDateTime': data['eventDateTime'] ?? _formatEventDateTime(item.dateTime),
      'host': data['host'] ?? item.host ?? '',
      'location': data['location'] ?? item.location ?? '',
      'capacityLabel': _capacityLabel(goingPersonaIds.length, capacity),
      'rsvpStatus': responseLabel,
      'waitlistedPersonaIds': waitlistedPersonaIds,
      'reminderState': widget.reminderEnabled ? 'Reminder set' : '',
    };
  }

  List<WorkflowActionButtonTransition> _eventRsvpTransitions(
    WorkflowInstance? instance,
  ) {
    final machine = widget.machine;
    if (machine == null || instance == null) return const [];
    final currentResponseId =
        _responseIdForPersona(instance.instanceData, widget.personaId);
    final transitions = machine.transitionsFrom(instance.currentState)
        .where(
          (transition) => evaluateGuard(
            transition.guard,
            widget.personaId,
            instance.instanceData,
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

String? _responseIdForPersona(
  Map<String, dynamic> instanceData,
  String personaId,
) {
  final responseMap = instanceData['rsvpByPersona'];
  if (responseMap is Map) {
    final response = responseMap[personaId];
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

int _goingCountFromLabel(String? label) {
  if (label == null) return 0;
  final match = RegExp(r'(\d+)\s+of\s+\d+').firstMatch(label);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}

int? _capacityFromLabel(String? label) {
  if (label == null) return null;
  final match = RegExp(r'\d+\s+of\s+(\d+)').firstMatch(label);
  return int.tryParse(match?.group(1) ?? '');
}

bool _isCapacityFull(String? label) {
  if (label == null) return false;
  final match = RegExp(r'(\d+)\s+of\s+(\d+)').firstMatch(label);
  if (match == null) return false;
  final used = int.tryParse(match.group(1) ?? '');
  final capacity = int.tryParse(match.group(2) ?? '');
  return used != null && capacity != null && used >= capacity;
}

String _capacityLabel(int goingCount, int capacity) {
  return '$goingCount of $capacity seats filled';
}

String _iconNameForResponseId(String responseId, bool destructive) {
  switch (responseId) {
    case 'going':
      return 'event_available';
    case 'maybe':
      return 'help_outline';
    case 'waitlist':
      return 'groups';
    case 'not-going':
      return 'event_busy';
    default:
      return destructive ? 'event_busy' : 'event_available';
  }
}

WorkflowActionTone _toneForEventTransition(LoomWorkflowTransition transition) {
  return switch (transition.tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };
}

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[(weekday - 1).clamp(0, 6)];
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
class _MarketplaceBrowseSurface extends StatefulWidget {
  const _MarketplaceBrowseSurface({
    required this.listings,
    required this.communityId,
    required this.accent,
    this.modernTheme,
    this.onConfirmWorkflow,
    this.marketplaceTemplate,
    this.workflows = const [],
    required this.persona,
    this.completedWorkflowIds = const {},
    this.pageSize = 10,
  });

  final List<LoomMarketplaceListing> listings;
  final String communityId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final ValueChanged<LoomWorkflowDefinition>? onConfirmWorkflow;
  final LoomListingStateMachine? marketplaceTemplate;
  final List<LoomWorkflowDefinition> workflows;
  final LoomPersonaDefinition persona;
  final Set<String> completedWorkflowIds;
  final int pageSize;

  @override
  State<_MarketplaceBrowseSurface> createState() =>
      _MarketplaceBrowseSurfaceState();
}

class _MarketplaceBrowseSurfaceState extends State<_MarketplaceBrowseSurface> {
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedInstanceId;
  late final WorkflowDatabase _database;
  late final LocalWorkflowEngineApi _engine;
  final _machinesByType = <String, LoomWorkflowStateMachine>{};
  final _visibleInstances = <WorkflowInstance>[];
  Set<String> _completedWorkflowIds = const {};
  var _initialLoadComplete = false;
  var _loadingPage = false;
  var _hasMore = false;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _database = WorkflowDatabase.memory();
    _engine = LocalWorkflowEngineApi(
      db: _database,
      communityId: widget.communityId,
    );
    unawaited(_seedAndLoad());
  }

  @override
  void didUpdateWidget(_MarketplaceBrowseSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedWorkflowIds != widget.completedWorkflowIds) {
      unawaited(_syncDuesCompletionFromShell());
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _syncDuesCompletionFromShell() async {
    final duesWorkflow = _duesWorkflow;
    if (duesWorkflow == null ||
        !widget.completedWorkflowIds.contains(duesWorkflow.workflowId)) {
      return;
    }
    final page = await _engine.queryInstances(
      tabId: 'giving',
      personaId: widget.persona.personaId,
      limit: 50,
    );
    for (final instance in page.items) {
      if (instance.workflowType == duesWorkflow.workflowId &&
          instance.currentState != 'paid') {
        await _engine.applyTransition(
          workflowType: instance.workflowType,
          instanceId: instance.instanceId,
          transitionId: 'pay',
          personaId: widget.persona.personaId,
        );
      }
    }
    final completed =
        await _engine.completedWorkflowIdsForPersona(widget.persona.personaId);
    if (!mounted) return;
    setState(() => _completedWorkflowIds = completed);
  }

  Future<void> _seedAndLoad() async {
    final duesWorkflow = _duesWorkflow;
    if (duesWorkflow != null) {
      final machine = _duesMachineFor(duesWorkflow);
      _machinesByType[machine.workflowType] = machine;
      _engine.registerDefinition(machine);
      await _engine.createInstance(
        workflowType: machine.workflowType,
        initialInstanceData: _duesInstanceDataFor(duesWorkflow),
        personaId: widget.persona.personaId,
      );
      if (widget.completedWorkflowIds.contains(duesWorkflow.workflowId)) {
        final page = await _engine.queryInstances(
          tabId: 'giving',
          personaId: widget.persona.personaId,
          limit: 50,
        );
        final duesInstance = page.items.firstWhere(
          (instance) => instance.workflowType == machine.workflowType,
        );
        await _engine.applyTransition(
          workflowType: duesInstance.workflowType,
          instanceId: duesInstance.instanceId,
          transitionId: 'pay',
          personaId: widget.persona.personaId,
        );
      }
    }
    for (final listing in widget.listings) {
      final machine = _machineForListing(listing);
      _machinesByType[machine.workflowType] = machine;
      _engine.registerDefinition(machine);
      await _engine.createInstance(
        workflowType: machine.workflowType,
        initialInstanceData: _instanceDataForListing(listing),
        personaId: widget.persona.personaId,
      );
    }
    _completedWorkflowIds =
        await _engine.completedWorkflowIdsForPersona(widget.persona.personaId);
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_loadingPage) return;
    setState(() => _loadingPage = true);
    final page = await _engine.queryInstances(
      tabId: 'marketplace',
      personaId: widget.persona.personaId,
      limit: widget.pageSize,
      cursor: _nextCursor,
    );
    if (!mounted) return;
    setState(() {
      _visibleInstances.addAll(page.items.where(
        (instance) => instance.workflowType.startsWith('marketplace_'),
      ));
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      _loadingPage = false;
      _initialLoadComplete = true;
    });
  }

  List<WorkflowInstance> get _filteredListings {
    var listings = _visibleInstances.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      listings = listings.where((listing) {
        return _stringData(listing, 'title').toLowerCase().contains(q) ||
            _stringData(listing, 'description').toLowerCase().contains(q);
      }).toList();
    }
    if (_selectedCategory != null) {
      listings = listings
          .where((listing) => _stringData(listing, 'category') == _selectedCategory)
          .toList();
    }
    return listings;
  }

  WorkflowInstance? get _selectedListing {
    final selectedId = _selectedInstanceId;
    if (selectedId == null) return null;
    for (final instance in _visibleInstances) {
      if (instance.instanceId == selectedId) return instance;
    }
    return null;
  }

  LoomWorkflowDefinition? _resolveWorkflow(String workflowId) {
    try {
      return widget.workflows.firstWhere((w) => w.workflowId == workflowId);
    } catch (_) {
      return null;
    }
  }

  List<WorkflowActionButtonTransition> _actionsFor(WorkflowInstance listing) {
    final machine = _machinesByType[listing.workflowType];
    if (machine == null) return const [];
    final actions = <WorkflowActionButtonTransition>[];
    for (final transition in machine.transitionsFrom(listing.currentState)) {
      final allowed = evaluateGuard(
        transition.guard,
        widget.persona.personaId,
        listing.instanceData,
        completedWorkflowIds: _completedWorkflowIds,
      );
      final guardWithoutPrerequisites = WorkflowGuard(
        allowedPersonaIds: transition.guard.allowedPersonaIds,
        actorInList: transition.guard.actorInList,
        instanceDataEquals: transition.guard.instanceDataEquals,
      );
      final waiting = !allowed &&
          (transition.guard.requiresWorkflowsComplete?.isNotEmpty ?? false) &&
          evaluateGuard(
            guardWithoutPrerequisites,
            widget.persona.personaId,
            listing.instanceData,
          );
      if (!allowed && !waiting) continue;
      actions.add(
        WorkflowActionButtonTransition(
          id: transition.id,
          label: transition.label,
          iconName: transition.icon,
          tone: _actionToneFor(transition),
          waitingForPrerequisite: waiting,
          waitingText: 'Waiting',
        ),
      );
    }
    return actions;
  }

  Future<void> _applyTransition(
    WorkflowInstance listing,
    String transitionId,
  ) async {
    final machine = _machinesByType[listing.workflowType];
    if (machine == null) return;
    final transition = machine.transitions.firstWhere(
      (candidate) =>
          candidate.id == transitionId &&
          candidate.from.contains(listing.currentState),
    );
    final result = await _engine.applyTransition(
      workflowType: listing.workflowType,
      instanceId: listing.instanceId,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    final removeFromGrid = transition.effects.any(
      (effect) => effect.op == 'removeFromTileGrid',
    );
    if (!mounted) return;
    setState(() {
      if (removeFromGrid) {
        _visibleInstances.removeWhere(
          (instance) => instance.instanceId == listing.instanceId,
        );
        _selectedInstanceId = null;
        return;
      }
      final replacement = WorkflowInstance(
        instanceId: listing.instanceId,
        workflowType: listing.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: listing.createdByPersonaId,
      );
      final index = _visibleInstances.indexWhere(
        (instance) => instance.instanceId == listing.instanceId,
      );
      if (index != -1) {
        _visibleInstances[index] = replacement;
      }
    });

    final linkedWorkflowId = transition.linkedWorkflowId;
    final workflow =
        linkedWorkflowId == null ? null : _resolveWorkflow(linkedWorkflowId);
    if (workflow != null) {
      widget.onConfirmWorkflow?.call(workflow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final listing = _selectedListing;
    if (listing != null) {
      final actions = _actionsFor(listing);
      final machine = _machinesByType[listing.workflowType]!;
      final surfaceFamily = _surfaceFamilyFor(machine);
      return _WorkflowMarketplaceListingDetailView(
        listing: listing,
        machine: machine,
        foreground: foreground,
        accent: widget.accent,
        modernTheme: widget.modernTheme,
        surfaceFamily: surfaceFamily,
        instanceDataSchema: _factPillSchemaFor(surfaceFamily),
        onBack: () => setState(() => _selectedInstanceId = null),
        engineActions: actions,
        onTransitionApplied: (transitionId) =>
            unawaited(_applyTransition(listing, transitionId)),
      );
    }
    if (!_initialLoadComplete) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filteredListings;
    final categories = <String>{
      for (final listing in _visibleInstances)
        if (_stringData(listing, 'category').isNotEmpty)
          _stringData(listing, 'category'),
    };
    final border = widget.modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    return Column(
      key: const ValueKey('marketplace-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            key: const ValueKey('marketplace-search-field'),
            style: TextStyle(color: foreground),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: foreground),
              hintText: 'Search available items',
              hintStyle: TextStyle(color: foreground.withValues(alpha: 0.60)),
              filled: true,
              fillColor: foreground.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: widget.modernTheme?.accent ?? widget.accent,
                ),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories)
                  InkWell(
                    key: ValueKey('marketplace-filter-$cat'),
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() {
                      _selectedCategory =
                          _selectedCategory == cat ? null : cat;
                    }),
                    child: Chip(
                      label: Text(cat),
                      backgroundColor: _selectedCategory == cat
                          ? (widget.modernTheme?.accent ?? widget.accent)
                          : foreground.withValues(alpha: 0.10),
                      labelStyle: TextStyle(
                        color: _selectedCategory == cat
                            ? Colors.white
                            : foreground,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: _selectedCategory == cat
                            ? (widget.modernTheme?.accent ?? widget.accent)
                            : border,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No listings match your search',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: foreground.withValues(alpha: 0.80),
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 380;
              final crossAxisCount = wide ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - (crossAxisCount - 1) * 10) /
                      crossAxisCount;
              final itemHeight = itemWidth / 0.72;
              final rows = (filtered.length / crossAxisCount).ceil();
              final gridHeight = rows * (itemHeight + 10) - 10;
              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final machine = _machinesByType[item.workflowType]!;
                    final surfaceFamily = _surfaceFamilyFor(machine);
                    return _WorkflowMarketplaceListingCard(
                      listing: item,
                      machine: machine,
                      foreground: foreground,
                      border: border,
                      accent: widget.accent,
                      modernTheme: widget.modernTheme,
                      surfaceFamily: surfaceFamily,
                      instanceDataSchema: _factPillSchemaFor(surfaceFamily),
                      onTap: () =>
                          setState(() => _selectedInstanceId = item.instanceId),
                    );
                  },
                ),
              );
            },
          ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              key: const ValueKey('marketplace-load-more'),
              onPressed: _loadingPage ? null : () => unawaited(_loadNextPage()),
              icon: const Icon(Icons.expand_more),
              label: const Text('Load more'),
            ),
          ),
      ],
    );
  }

  LoomWorkflowStateMachine _machineForListing(LoomMarketplaceListing listing) {
    final legacy = listing.stateMachine ??
        widget.marketplaceTemplate ??
        _defaultLoanMarketplaceTemplate(listing);
    final initialState = _initialStateFor(listing, legacy);
    final surfaceFamily = _surfaceFamilyForListing(listing, legacy);
    return LoomWorkflowStateMachine(
      workflowType: 'marketplace_${listing.listingId}',
      initialState: initialState,
      states: {
        for (final entry in legacy.states.entries)
          entry.key: LoomWorkflowState(
            label: entry.value.label,
            tone: entry.value.tone,
          ),
      },
      transitions: [
        for (final transition in legacy.transitions)
          _engineTransitionFromLegacy(transition),
      ],
      renderBindings: [
        RenderBinding(
          states: legacy.states.keys.toList(),
          role: 'any',
          tabId: 'marketplace',
          cardSurfaceFamily: surfaceFamily,
          bindingKind: 'primary',
        ),
      ],
      instanceDataSchema: _engineSchemaFor(surfaceFamily),
    );
  }

  LoomWorkflowTransition _engineTransitionFromLegacy(
    LoomListingTransition transition,
  ) {
    return LoomWorkflowTransition(
      id: transition.id,
      label: transition.label,
      icon: _transitionIconName(transition.id),
      tone: _transitionToneName(transition.id),
      from: transition.fromStates,
      to: transition.to,
      linkedWorkflowId: transition.linkedWorkflowId,
      guard: WorkflowGuard(
        allowedPersonaIds: transition.allowedPersonaIds,
        requiresWorkflowsComplete: transition.requiresWorkflowsComplete,
        actorInList: transition.requiresActorInQueue
            ? const ListMembershipGuard(
                key: 'queuedPersonaIds',
                present: true,
              )
            : transition.requiresActorNotInQueue
                ? const ListMembershipGuard(
                    key: 'queuedPersonaIds',
                    present: false,
                  )
                : null,
      ),
      effects: [
        if (transition.setsHolderToActor)
          const WorkflowEffect(
            op: 'set',
            key: 'holderPersonaId',
            value: '\$actor',
          ),
        if (transition.clearsHolder)
          const WorkflowEffect(op: 'set', key: 'holderPersonaId'),
        if (transition.addsActorToQueue || transition.incrementsQueue)
          const WorkflowEffect(
            op: 'appendUnique',
            key: 'queuedPersonaIds',
            value: '\$actor',
          ),
        if (transition.removesActorFromQueue || transition.decrementsQueue)
          const WorkflowEffect(
            op: 'removeValue',
            key: 'queuedPersonaIds',
            value: '\$actor',
          ),
        if (transition.removesFromList)
          const WorkflowEffect(op: 'removeFromTileGrid'),
      ],
    );
  }

  Map<String, dynamic> _instanceDataForListing(LoomMarketplaceListing listing) {
    return {
      'listingId': listing.listingId,
      'title': listing.title,
      if (listing.category != null) 'category': listing.category,
      if (listing.condition != null) 'condition': listing.condition,
      if (listing.currentHolderLabel != null)
        'holderPersonaId': listing.currentHolderLabel,
      if (listing.description != null) 'description': listing.description,
      if (listing.dueLabel != null) 'dueDate': listing.dueLabel,
      if (listing.linkedWorkflowId != null)
        'linkedWorkflowId': listing.linkedWorkflowId,
      'queuedPersonaIds': listing.queuedPersonaIds.isNotEmpty
          ? listing.queuedPersonaIds
          : [
              for (var i = 0; i < listing.queueLength; i += 1)
                'queued-placeholder-${listing.listingId}-$i',
            ],
    };
  }

  String _initialStateFor(
    LoomMarketplaceListing listing,
    LoomListingStateMachine machine,
  ) {
    final declared = listing.state ?? listing.availability;
    if (machine.states.containsKey(declared)) return declared;
    return machine.initialState;
  }

  String _surfaceFamilyForListing(
    LoomMarketplaceListing listing,
    LoomListingStateMachine machine,
  ) {
    if (listing.availability == 'giveaway') return 'equipment-giveaway';
    if (machine.transitions.any((transition) => transition.id == 'claim')) {
      return 'equipment-giveaway';
    }
    return 'equipment-loan';
  }

  String _surfaceFamilyFor(LoomWorkflowStateMachine machine) {
    return machine.renderBindings.isEmpty
        ? 'equipment-loan'
        : machine.renderBindings.first.cardSurfaceFamily;
  }

  Map<String, WorkflowFactPillFieldSchema> _factPillSchemaFor(String family) {
    return family == 'equipment-giveaway'
        ? equipmentGiveawayDefaultInstanceDataSchema
        : equipmentLoanDefaultInstanceDataSchema;
  }

  Map<String, InstanceDataField> _engineSchemaFor(String family) {
    final source = _factPillSchemaFor(family);
    return {
      for (final entry in source.entries)
        entry.key: InstanceDataField(
          type: entry.key == 'queuedPersonaIds' ? 'array' : 'string',
          displayIcon: entry.value.displayIcon,
          labelTemplate: entry.value.labelTemplate,
          displayContexts: entry.value.displayContexts,
          hideWhenEmpty: entry.value.hideWhenEmpty,
          sortable: entry.key == 'title',
          searchable: entry.key == 'title' || entry.key == 'category',
        ),
      'listingId': const InstanceDataField(type: 'string', required: true),
      'description': const InstanceDataField(type: 'string', searchable: true),
      'linkedWorkflowId': const InstanceDataField(type: 'string'),
    };
  }

  LoomListingStateMachine _defaultLoanMarketplaceTemplate(
    LoomMarketplaceListing listing,
  ) {
    return LoomListingStateMachine(
      initialState: listing.availability == 'onLoan' ? 'onLoan' : 'available',
      states: const {
        'available': LoomListingState(label: 'Available', tone: 'positive'),
        'onLoan': LoomListingState(label: 'On loan', tone: 'warning'),
      },
      transitions: const [
        LoomListingTransition(
          id: 'borrow',
          label: 'Request loan',
          fromStates: ['available'],
          to: 'onLoan',
          allowedPersonaIds: ['tabletop-member'],
          linkedWorkflowId: 'tabletop-game-loan',
          setsHolderToActor: true,
        ),
        LoomListingTransition(
          id: 'return',
          label: 'Return',
          fromStates: ['onLoan'],
          to: 'available',
          allowedPersonaIds: ['tabletop-member', 'tabletop-organizer'],
          clearsHolder: true,
        ),
      ],
    );
  }

  LoomWorkflowDefinition? get _duesWorkflow {
    for (final workflow in widget.workflows) {
      if (workflow.givingPayment != null) return workflow;
    }
    return null;
  }

  LoomWorkflowStateMachine _duesMachineFor(LoomWorkflowDefinition workflow) {
    return LoomWorkflowStateMachine(
      workflowType: workflow.workflowId,
      initialState: 'unpaid',
      states: const {
        'unpaid': LoomWorkflowState(label: 'Unpaid', tone: 'warning'),
        'paid': LoomWorkflowState(
          label: 'Paid',
          tone: 'positive',
          isTerminal: true,
        ),
      },
      transitions: const [
        LoomWorkflowTransition(
          id: 'pay',
          label: 'Pay dues',
          icon: 'payments_outlined',
          tone: 'primary',
          from: ['unpaid'],
          to: 'paid',
          guard: WorkflowGuard(
            allowedPersonaIds: ['tabletop-member', 'tabletop-organizer'],
          ),
          effects: [
            WorkflowEffect(op: 'set', key: 'receiptStatus', value: 'complete'),
          ],
        ),
      ],
      instanceDataSchema: const {
        'workflowId': InstanceDataField(type: 'string', required: true),
        'completionWorkflowId': InstanceDataField(type: 'string'),
        'receiptStatus': InstanceDataField(type: 'string'),
      },
    );
  }

  Map<String, dynamic> _duesInstanceDataFor(LoomWorkflowDefinition workflow) {
    return {
      'workflowId': workflow.workflowId,
      'completionWorkflowId': 'tabletop-membership-dues-current',
      'receiptStatus': '',
    };
  }

  String _stringData(WorkflowInstance listing, String key) {
    return (listing.instanceData[key] as String?) ?? '';
  }

  String _transitionIconName(String transitionId) {
    return switch (transitionId) {
      'borrow' => 'arrow_forward',
      'join-queue' => 'add_circle_outline',
      'leave-queue' => 'remove_circle_outline',
      'return' => 'keyboard_return',
      'claim' => 'check_circle_outline',
      _ => 'label_outline',
    };
  }

  String _transitionToneName(String transitionId) {
    return switch (transitionId) {
      'return' => 'destructive',
      'leave-queue' => 'secondary',
      _ => 'primary',
    };
  }

  WorkflowActionTone _actionToneFor(LoomWorkflowTransition transition) {
    return switch (transition.tone) {
      'secondary' => WorkflowActionTone.secondary,
      'destructive' => WorkflowActionTone.destructive,
      _ => WorkflowActionTone.primary,
    };
  }
}

class _WorkflowMarketplaceListingCard extends StatelessWidget {
  const _WorkflowMarketplaceListingCard({
    required this.listing,
    required this.machine,
    required this.foreground,
    required this.border,
    required this.accent,
    required this.surfaceFamily,
    required this.instanceDataSchema,
    required this.onTap,
    this.modernTheme,
  });

  final WorkflowInstance listing;
  final LoomWorkflowStateMachine machine;
  final Color foreground;
  final Color border;
  final Color accent;
  final String surfaceFamily;
  final Map<String, WorkflowFactPillFieldSchema> instanceDataSchema;
  final VoidCallback onTap;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final listingId = listing.instanceData['listingId'] as String;
    final state = machine.states[listing.currentState];
    final statusColor = state?.tone == 'positive'
        ? Colors.green
        : state?.tone == 'warning'
            ? Colors.orange
            : foreground.withValues(alpha: 0.70);
    return InkWell(
      key: ValueKey('marketplace-listing-$listingId'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state?.label ?? listing.currentState,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              WorkflowCardSurfaceTemplateRenderer(
                surfaceFamily: surfaceFamily,
                instanceData: listing.instanceData,
                instanceDataSchema: instanceDataSchema,
                availableTransitions: const [],
                displayContext: 'tile',
                foreground: foreground,
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowMarketplaceListingDetailView extends StatelessWidget {
  const _WorkflowMarketplaceListingDetailView({
    required this.listing,
    required this.machine,
    required this.foreground,
    required this.accent,
    required this.surfaceFamily,
    required this.instanceDataSchema,
    required this.onBack,
    required this.engineActions,
    required this.onTransitionApplied,
    this.modernTheme,
  });

  final WorkflowInstance listing;
  final LoomWorkflowStateMachine machine;
  final Color foreground;
  final Color accent;
  final String surfaceFamily;
  final Map<String, WorkflowFactPillFieldSchema> instanceDataSchema;
  final VoidCallback onBack;
  final List<WorkflowActionButtonTransition> engineActions;
  final ValueChanged<String> onTransitionApplied;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final listingId = listing.instanceData['listingId'] as String;
    final title = listing.instanceData['title'] as String;
    final headerFill = modernTheme?.resolvedFill ?? accent;
    final headerBorder = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    return Column(
      key: ValueKey('marketplace-listing-detail-$listingId'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  tooltip: 'Back to browse',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SurfaceFactPill(
          icon: Icons.label_outline,
          label: machine.states[listing.currentState]?.label ??
              listing.currentState,
          foreground: foreground,
        ),
        const SizedBox(height: 12),
        WorkflowCardSurfaceTemplateRenderer(
          surfaceFamily: surfaceFamily,
          instanceData: listing.instanceData,
          instanceDataSchema: instanceDataSchema,
          availableTransitions: engineActions,
          displayContext: 'detail',
          foreground: foreground,
          accent: accent,
          actionSurfaceKey: 'marketplace',
          onTransitionPressed: onTransitionApplied,
        ),
        if (listing.instanceData['description'] case final String description)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground.withValues(alpha: 0.88),
                  ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
/// Compact listing card for the marketplace grid.
class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.foreground,
    required this.fill,
    required this.border,
    required this.accent,
    this.modernTheme,
    required this.onTap,
  });

  final LoomMarketplaceListing listing;
  final Color foreground;
  final Color fill;
  final Color border;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedState = listing.stateMachine?.states[listing.state ?? listing.availability];
    final statusLabel = resolvedState?.label ?? switch (listing.availability) {
      'onLoan' => 'On loan',
      'queued' => 'Queued',
      _ => 'Available',
    };
    final statusColor = resolvedState != null
        ? resolvedState.tone == 'positive'
            ? Colors.green
            : resolvedState.tone == 'warning'
                ? Colors.orange
                : foreground.withValues(alpha: 0.70)
        : listing.availability == 'available'
            ? Colors.green
            : listing.availability == 'queued'
                ? Colors.orange
                : foreground.withValues(alpha: 0.70);
    return InkWell(
      key: ValueKey('marketplace-listing-${listing.listingId}'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                listing.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (listing.category != null) ...[
                const SizedBox(height: 2),
                Text(
                  listing.category!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.72),
                  ),
                ),
              ],
              if (listing.currentHolderLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Holder: ${listing.currentHolderLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.70),
                  ),
                ),
              ],
              if (listing.queueLength > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Queue: ${listing.queueLength}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              if (listing.dueLabel != null)
                Text(
                  listing.dueLabel!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.64),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full listing detail with description, condition, holder/queue info,
/// and engine-derived action buttons (GAP B: resolves real workflows).
class _ListingDetailView extends StatelessWidget {
  const _ListingDetailView({
    required this.listing,
    required this.foreground,
    required this.accent,
    this.modernTheme,
    required this.onBack,
    this.onConfirmWorkflow,
    this.resolveWorkflow,
    this.engineActions = const [],
    this.onTransitionApplied,
  });

  final LoomMarketplaceListing listing;
  final Color foreground;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final VoidCallback onBack;
  final ValueChanged<LoomWorkflowDefinition>? onConfirmWorkflow;
  final LoomWorkflowDefinition? Function(String workflowId)? resolveWorkflow;
  final List<LoomListingTransition> engineActions;
  final ValueChanged<LoomListingTransition>? onTransitionApplied;

  @override
  Widget build(BuildContext context) {
    final headerFill = modernTheme?.resolvedFill ?? accent;
    final headerBorder = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final factFill = modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.06), accent);
    return Column(
      key: ValueKey('marketplace-listing-detail-${listing.listingId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with back button
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
                  tooltip: 'Back to browse',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    listing.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Facts
        DecoratedBox(
          decoration: BoxDecoration(
            color: factFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: foreground.withValues(alpha: 0.14),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (listing.condition != null)
                  _SurfaceFactPill(
                    icon: Icons.verified_outlined,
                    label: listing.condition!,
                    foreground: foreground,
                  ),
                _SurfaceFactPill(
                  icon: Icons.label_outline,
                  label: listing.stateMachine?.states[listing.state ?? listing.availability]?.label ??
                      (listing.availability == 'available'
                          ? 'Available'
                          : listing.availability == 'onLoan'
                              ? 'On loan'
                              : 'Queued'),
                  foreground: foreground,
                ),
                if (listing.category != null)
                  _SurfaceFactPill(
                    icon: Icons.category_outlined,
                    label: listing.category!,
                    foreground: foreground,
                  ),
                if (listing.currentHolderLabel != null)
                  _SurfaceFactPill(
                    icon: Icons.person_outline,
                    label: 'Holder: ${listing.currentHolderLabel}',
                    foreground: foreground,
                  ),
                if (listing.queueLength > 0)
                  _SurfaceFactPill(
                    icon: Icons.queue_outlined,
                    label: 'Queue: ${listing.queueLength}',
                    foreground: foreground,
                  ),
                if (listing.dueLabel != null)
                  _SurfaceFactPill(
                    icon: Icons.schedule_outlined,
                    label: listing.dueLabel!,
                    foreground: foreground,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Description
        if (listing.description != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              listing.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
          ),
        // Engine-derived action buttons (GAP C: all states get actions)
        if (engineActions.isNotEmpty) ...[
          for (final transition in engineActions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: ValueKey('marketplace-action-${transition.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        modernTheme?.primaryButton?.resolvedFill ?? accent,
                    foregroundColor:
                        modernTheme?.primaryButton?.resolvedForeground ??
                            Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // GAP B: resolve the real workflow from the transition
                    final workflowId = transition.linkedWorkflowId;
                    final workflow = workflowId != null
                        ? resolveWorkflow?.call(workflowId)
                        : null;
                    if (workflow != null && onConfirmWorkflow != null) {
                      onConfirmWorkflow!(workflow);
                    }
                    // GAP A: apply the transition's effects to mutable state
                    onTransitionApplied?.call(transition);
                  },
                  icon: Icon(
                    transition.id == 'borrow'
                        ? Icons.swap_horiz
                        : transition.id == 'join-queue'
                            ? Icons.queue_outlined
                            : transition.id == 'return'
                                ? Icons.assignment_return_outlined
                                : Icons.arrow_forward,
                  ),
                  label: Text(transition.label),
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DocumentsTabSurface extends StatelessWidget {
  const _DocumentsTabSurface({
    required this.experience,
    required this.persona,
    required this.sections,
    required this.focusedWorkflowId,
    required this.expandedWorkflowId,
    required this.accent,
    this.modernTheme,
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final _WorkflowSurfaceBuilder workflowBuilder;

  @override
  Widget build(BuildContext context) {
    final libraries = experience.workflows
        .where((workflow) => workflow.documentLibrary != null)
        .toList();
    if (libraries.isEmpty) {
      return _TabEmptyState(
        icon: Icons.folder_open_outlined,
        title: 'No documents visible',
        body:
            'Documents, external links, versions, and access requests for ${experience.displayName} will appear here.',
        accent: accent,
        modernTheme: modernTheme,
      );
    }
    return Column(
      key: const ValueKey('documents-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentLibraryHeader(accent: accent, modernTheme: modernTheme),
        const SizedBox(height: 12),
        for (final workflow in libraries)
          _DocumentLibraryWorkflowSurface(
            workflow: workflow,
            persona: persona,
            accent: accent,
            modernTheme: modernTheme,
          ),
        if (_workflowsFromSections(sections)
            .where((workflow) => workflow.documentLibrary == null)
            .isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final workflow in _workflowsFromSections(sections)
              .where((workflow) => workflow.documentLibrary == null))
            workflowBuilder(
              workflow,
              _presentationStateForWorkflow(
                workflowId: workflow.workflowId,
                focusedWorkflowId: focusedWorkflowId,
                expandedWorkflowId: expandedWorkflowId,
              ),
            ),
        ],
      ],
    );
  }
}

class _DocumentLibraryWorkflowSurface extends StatefulWidget {
  const _DocumentLibraryWorkflowSurface({
    required this.workflow,
    required this.persona,
    required this.accent,
    this.modernTheme,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaDefinition persona;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_DocumentLibraryWorkflowSurface> createState() =>
      _DocumentLibraryWorkflowSurfaceState();
}

class _DocumentLibraryWorkflowSurfaceState
    extends State<_DocumentLibraryWorkflowSurface> {
  String? _selectedCategory;
  String? _selectedDocumentId;
  late final WorkflowDatabase _database;
  late final LocalWorkflowEngineApi _engine;
  final _instancesByDocumentId = <String, WorkflowInstance>{};
  var _engineLoaded = false;

  LoomDocumentLibrary get _library => widget.workflow.documentLibrary!;

  @override
  void initState() {
    super.initState();
    _database = WorkflowDatabase.memory();
    _engine = LocalWorkflowEngineApi(
      db: _database,
      communityId: widget.workflow.workflowId,
    );
    _selectedCategory = _library.categories.firstOrNull;
    final first = _documentsForCategory(_selectedCategory).firstOrNull;
    _selectedDocumentId = first?.documentId;
    unawaited(_seedAndLoad());
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDocument = _selectedDocument;
    final selectedInstance = selectedDocument == null
        ? null
        : _instancesByDocumentId[selectedDocument.documentId];
    return DecoratedBox(
      key: ValueKey('document-library-${widget.workflow.workflowId}'),
      decoration: BoxDecoration(
        color: widget.modernTheme?.resolvedFill ?? Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              widget.modernTheme?.resolvedBorder ??
              widget.accent.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.workflow.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(widget.workflow.entryText),
            if (!_engineLoaded) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in _library.categories)
                  ChoiceChip(
                    key: ValueKey('documents-category-$category'),
                    label: Text(category),
                    selected: category == _selectedCategory,
                    onSelected: (_) => setState(() {
                      _selectedCategory = category;
                      _selectedDocumentId =
                          _documentsForCategory(category).firstOrNull?.documentId;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final document in _documentsForCategory(_selectedCategory))
              Card(
                key: ValueKey('document-row-${document.documentId}'),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(document.title),
                  subtitle: Text('${document.version} - ${document.updatedLabel}'),
                  trailing: Text(_accessStateFor(document)),
                  selected: document.documentId == _selectedDocumentId,
                  onTap: () =>
                      setState(() => _selectedDocumentId = document.documentId),
                ),
              ),
            if (selectedDocument != null && selectedInstance != null) ...[
              const SizedBox(height: 12),
              _DocumentDetailCard(
                document: selectedDocument,
                accessState: _accessStateFor(selectedDocument),
                currentState: selectedInstance.currentState,
                persona: widget.persona,
                accent: widget.accent,
                onEmbeddedOpen: () => _applyDocumentTransition(
                  selectedDocument,
                  'open-embedded',
                ),
                onExternalOpen: () => _applyDocumentTransition(
                  selectedDocument,
                  'open-external',
                ),
                onAcknowledge: () => _applyDocumentTransition(
                  selectedDocument,
                  'acknowledge',
                ),
                onRequestAccess: () => _applyDocumentTransition(
                  selectedDocument,
                  'request-access',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Audit trail',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            if (_auditEntriesForSelected.isEmpty)
              const Text('No document audit entries yet.')
            else
              for (final entry in _auditEntriesForSelected)
                Text(
                  entry,
                  key: ValueKey(
                    'document-audit-${entry.hashCode.toUnsigned(32)}',
                  ),
                ),
          ],
        ),
      ),
    );
  }

  List<LoomDocumentItem> _documentsForCategory(String? category) {
    return _library.documents
        .where((document) => category == null || document.category == category)
        .toList();
  }

  LoomDocumentItem? get _selectedDocument {
    for (final document in _library.documents) {
      if (document.documentId == _selectedDocumentId) return document;
    }
    return _library.documents.firstOrNull;
  }

  String _accessStateFor(LoomDocumentItem document) {
    final instance = _instancesByDocumentId[document.documentId];
    final accessState = instance?.instanceData['accessState'];
    return accessState is String ? accessState : document.accessState;
  }

  List<String> get _auditEntriesForSelected {
    final selectedDocument = _selectedDocument;
    if (selectedDocument == null) return const [];
    final auditTrail =
        _instancesByDocumentId[selectedDocument.documentId]
            ?.instanceData['auditTrail'];
    if (auditTrail is! List) return const [];
    return [for (final entry in auditTrail) if (entry is String) entry];
  }

  Future<void> _seedAndLoad() async {
    _engine.registerDefinition(_documentMachineFor(widget.workflow.workflowId));
    for (final document in _library.documents) {
      await _engine.createInstance(
        workflowType: widget.workflow.workflowId,
        initialInstanceData: {
          'documentId': document.documentId,
          'title': document.title,
          'category': document.category,
          'version': document.version,
          'updatedLabel': document.updatedLabel,
          'accessState': document.accessState,
          'actorLabel': widget.persona.label,
          'auditTrail': <String>[],
        },
        personaId: widget.persona.personaId,
      );
    }
    await _reloadDocumentInstances();
  }

  Future<void> _applyDocumentTransition(
    LoomDocumentItem document,
    String transitionId,
  ) async {
    final instance = _instancesByDocumentId[document.documentId];
    if (instance == null) return;
    await _engine.applyTransition(
      workflowType: widget.workflow.workflowId,
      instanceId: instance.instanceId,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    await _reloadDocumentInstances();
  }

  Future<void> _reloadDocumentInstances() async {
    final page = await _engine.queryInstances(
      tabId: 'documents',
      personaId: widget.persona.personaId,
      limit: 100,
      query: const SurfaceQuery(sort: SortSpec(key: 'title')),
    );
    final next = <String, WorkflowInstance>{};
    for (final instance in page.items) {
      if (instance.workflowType != widget.workflow.workflowId) continue;
      final documentId = instance.instanceData['documentId'];
      if (documentId is String) {
        next[documentId] = instance;
      }
    }
    if (!mounted) return;
    setState(() {
      _instancesByDocumentId
        ..clear()
        ..addAll(next);
      _engineLoaded = true;
    });
  }

  LoomWorkflowStateMachine _documentMachineFor(String workflowType) {
    const allDocumentStates = [
      'available',
      'read',
      'acknowledged',
      'access-requested',
    ];
    final guard = WorkflowGuard(
      allowedPersonaIds: [widget.persona.personaId],
    );
    return LoomWorkflowStateMachine(
      workflowType: workflowType,
      initialState: 'available',
      states: const {
        'available': LoomWorkflowState(label: 'Available'),
        'read': LoomWorkflowState(label: 'Read'),
        'acknowledged': LoomWorkflowState(
          label: 'Acknowledged',
          isTerminal: true,
        ),
        'access-requested': LoomWorkflowState(
          label: 'Access requested',
          isTerminal: true,
        ),
      },
      instanceDataSchema: const {
        'documentId': InstanceDataField(type: 'string', required: true),
        'title': InstanceDataField(type: 'string', required: true),
        'category': InstanceDataField(type: 'string', required: true),
        'version': InstanceDataField(type: 'string', required: true),
        'updatedLabel': InstanceDataField(type: 'string', required: true),
        'accessState': InstanceDataField(type: 'string', required: true),
        'actorLabel': InstanceDataField(type: 'string', required: true),
        'auditTrail': InstanceDataField(type: 'list'),
      },
      renderBindings: const [
        RenderBinding(
          states: allDocumentStates,
          role: 'any',
          tabId: 'documents',
          cardSurfaceFamily: 'documentLibrary',
          bindingKind: 'primary',
        ),
      ],
      transitions: [
        LoomWorkflowTransition(
          id: 'open-embedded',
          label: 'Open embedded',
          icon: 'open_in_browser',
          tone: 'primary',
          from: const ['available', 'read'],
          to: 'read',
          guard: guard,
          effects: const [
            WorkflowEffect(
              op: 'set',
              key: 'accessState',
              value: 'read',
            ),
            WorkflowEffect(
              op: 'append',
              key: 'auditTrail',
              value: '{actorLabel} at \$timestamp opened {title} embedded',
            ),
          ],
        ),
        LoomWorkflowTransition(
          id: 'open-external',
          label: 'Open external',
          icon: 'open_in_new',
          tone: 'secondary',
          from: const ['available', 'read'],
          to: 'read',
          guard: guard,
          effects: const [
            WorkflowEffect(
              op: 'set',
              key: 'accessState',
              value: 'read',
            ),
            WorkflowEffect(
              op: 'append',
              key: 'auditTrail',
              value: '{actorLabel} at \$timestamp opened {title} external',
            ),
          ],
        ),
        LoomWorkflowTransition(
          id: 'acknowledge',
          label: 'Acknowledge',
          icon: 'fact_check',
          tone: 'primary',
          from: const ['available', 'read'],
          to: 'acknowledged',
          guard: guard,
          effects: const [
            WorkflowEffect(
              op: 'set',
              key: 'accessState',
              value: 'acknowledged',
            ),
            WorkflowEffect(
              op: 'append',
              key: 'auditTrail',
              value: '{actorLabel} at \$timestamp acknowledged {title}',
            ),
          ],
        ),
        LoomWorkflowTransition(
          id: 'request-access',
          label: 'Request access',
          icon: 'lock_open',
          tone: 'secondary',
          from: const ['available', 'read'],
          to: 'access-requested',
          guard: guard,
          effects: const [
            WorkflowEffect(
              op: 'set',
              key: 'accessState',
              value: 'access-requested',
            ),
            WorkflowEffect(
              op: 'append',
              key: 'auditTrail',
              value: '{actorLabel} at \$timestamp requested access to {title}',
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentDetailCard extends StatelessWidget {
  const _DocumentDetailCard({
    required this.document,
    required this.accessState,
    required this.currentState,
    required this.persona,
    required this.accent,
    required this.onEmbeddedOpen,
    required this.onExternalOpen,
    required this.onAcknowledge,
    required this.onRequestAccess,
  });

  final LoomDocumentItem document;
  final String accessState;
  final String currentState;
  final LoomPersonaDefinition persona;
  final Color accent;
  final VoidCallback onEmbeddedOpen;
  final VoidCallback onExternalOpen;
  final VoidCallback onAcknowledge;
  final VoidCallback onRequestAccess;

  @override
  Widget build(BuildContext context) {
    final hasAccess = accessState != 'restricted';
    final canTransition = currentState != 'acknowledged' &&
        currentState != 'access-requested';
    return DecoratedBox(
      key: ValueKey('document-detail-${document.documentId}'),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              document.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (document.summary case final summary?) ...[
              const SizedBox(height: 4),
              Text(summary),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.history_outlined,
                  label: 'Version: ${document.version}',
                  foreground: accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.verified_user_outlined,
                  label: 'Access: $accessState',
                  foreground: accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.update_outlined,
                  label: document.updatedLabel,
                  foreground: accent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: ValueKey('document-open-embedded-${document.documentId}'),
                  onPressed: hasAccess && canTransition ? onEmbeddedOpen : null,
                  icon: const Icon(Icons.open_in_browser_outlined),
                  label: Text(document.embeddedLabel),
                ),
                OutlinedButton.icon(
                  key: ValueKey('document-open-external-${document.documentId}'),
                  onPressed: hasAccess && canTransition ? onExternalOpen : null,
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: Text(document.externalLabel),
                ),
                if (hasAccess && canTransition)
                  OutlinedButton.icon(
                    key: ValueKey('document-acknowledge-${document.documentId}'),
                    onPressed: onAcknowledge,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(document.acknowledgeLabel),
                  ),
                if (!hasAccess || accessState == 'access-requested')
                  OutlinedButton.icon(
                    key: ValueKey('document-request-access-${document.documentId}'),
                    onPressed:
                        accessState == 'access-requested' || !canTransition
                            ? null
                            : onRequestAccess,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: Text(
                      accessState == 'access-requested'
                          ? 'Access requested'
                          : document.requestAccessLabel,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchitecturalRequestTabSurface extends StatefulWidget {
  const _ArchitecturalRequestTabSurface({
    required this.experience,
    required this.persona,
    required this.boardMode,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final bool boardMode;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_ArchitecturalRequestTabSurface> createState() =>
      _ArchitecturalRequestTabSurfaceState();
}

class _ArchitecturalRequestTabSurfaceState
    extends State<_ArchitecturalRequestTabSurface> {
  static final _stores = <String, _ArchitecturalRequestStore>{};

  late final LoomWorkflowDefinition _workflow;
  late final LoomArchitecturalRequest _requestSpec;
  late final _ArchitecturalRequestStore _store;
  late final TextEditingController _projectController;
  late final TextEditingController _addressController;
  late final TextEditingController _dateController;
  late final TextEditingController _attachmentsController;
  List<WorkflowInstance> _instances = const [];
  String? _selectedInstanceId;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _workflow = widget.experience.workflows.firstWhere(
      (workflow) => workflow.architecturalRequest != null,
    );
    _requestSpec = _workflow.architecturalRequest!;
    _store = _stores.putIfAbsent(
      '${widget.experience.extensionId}:${_workflow.workflowId}',
      () => _ArchitecturalRequestStore(
        communityId: widget.experience.extensionId,
        workflowId: _workflow.workflowId,
      ),
    );
    _projectController = TextEditingController(
      text: _requestSpec.defaultProjectDescription,
    );
    _addressController = TextEditingController(
      text: _requestSpec.defaultPropertyAddress,
    );
    _dateController = TextEditingController(
      text: _requestSpec.defaultRequestedCompletionDate,
    );
    _attachmentsController = TextEditingController(
      text: _requestSpec.defaultAttachments,
    );
    unawaited(_load());
  }

  @override
  void dispose() {
    _projectController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _attachmentsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _store.ensureReady();
    final instances = await _store.instancesFor(widget.persona.personaId);
    if (!mounted) return;
    setState(() {
      _instances = instances;
      _selectedInstanceId ??= instances.firstOrNull?.instanceId;
      _loaded = true;
    });
  }

  Future<void> _submit() async {
    final instance = await _store.submit(
      personaId: widget.persona.personaId,
      ownerLabel: widget.persona.label,
      projectDescription: _projectController.text,
      propertyAddress: _addressController.text,
      requestedCompletionDate: _dateController.text,
      attachments: _attachmentsController.text,
    );
    if (!mounted) return;
    setState(() {
      _selectedInstanceId = instance.instanceId;
    });
    await _load();
  }

  Future<void> _transition(WorkflowInstance instance, String transitionId) async {
    await _store.apply(
      instance: instance,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final selected = _selectedInstance;
    return Column(
      key: ValueKey(
        widget.boardMode
            ? 'hoa-board-request-dashboard'
            : 'hoa-homeowner-request-surface',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.boardMode && _canEditSelectedRequest(selected))
          _buildForm(context),
        if (!widget.boardMode && _canEditSelectedRequest(selected))
          const SizedBox(height: 12),
        if (widget.boardMode) _buildDashboard(context),
        if (widget.boardMode) const SizedBox(height: 12),
        if (selected == null)
          _TabEmptyState(
            icon: Icons.fact_check_outlined,
            title: widget.boardMode
                ? 'No architectural requests pending'
                : 'No architectural request submitted',
            body: widget.boardMode
                ? 'Submitted owner requests will appear in the board queue.'
                : 'Submit an architectural request to open the status timeline.',
            accent: widget.accent,
            modernTheme: widget.modernTheme,
          )
        else
          _buildTimeline(context, selected),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('hoa-request-form-entry'),
      decoration: _requestBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Architectural request form',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const ValueKey('hoa-request-project-type'),
              initialValue: _requestSpec.projectTypes.first,
              items: [
                for (final type in _requestSpec.projectTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: 'Project type'),
            ),
            TextField(
              key: const ValueKey('hoa-request-project-description'),
              controller: _projectController,
              decoration: const InputDecoration(labelText: 'Project description'),
            ),
            TextField(
              key: const ValueKey('hoa-request-property-address'),
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Property address'),
            ),
            TextField(
              key: const ValueKey('hoa-request-completion-date'),
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Requested completion date',
              ),
            ),
            TextField(
              key: const ValueKey('hoa-request-attachments'),
              controller: _attachmentsController,
              decoration: const InputDecoration(labelText: 'Attachments'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('hoa-request-submit'),
              onPressed: _submit,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit architectural request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('hoa-board-dashboard'),
      decoration: _requestBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Decision queue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            if (_instances.isEmpty)
              const Text('No pending architectural requests.')
            else
              for (final instance in _instances)
                Card(
                  key: ValueKey(
                    "hoa-board-queue-${instance.instanceData['ownerPersonaId']}",
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text('${instance.instanceData['projectDescription']}'),
                    subtitle: Text(
                      '${instance.instanceData['ownerLabel']} - ${_labelForState(instance.currentState)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    selected: instance.instanceId == _selectedInstanceId,
                    onTap: () =>
                        setState(() => _selectedInstanceId = instance.instanceId),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, WorkflowInstance instance) {
    final transitions = _store.availableTransitions(
      instance: instance,
      personaId: widget.persona.personaId,
    );
    final history = instance.instanceData['history'];
    final historyItems = history is List
        ? [for (final entry in history) if (entry is String) entry]
        : const <String>[];
    return DecoratedBox(
      key: const ValueKey('hoa-request-timeline'),
      decoration: _requestBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.boardMode
                  ? 'Committee decision card'
                  : 'Architectural request status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.flag_outlined,
                  label: 'State: ${_labelForState(instance.currentState)}',
                  foreground: widget.accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.home_work_outlined,
                  label: '${instance.instanceData['propertyAddress']}',
                  foreground: widget.accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.person_outline,
                  label: '${instance.instanceData['ownerLabel']}',
                  foreground: widget.accent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Project: ${instance.instanceData['projectDescription']}'),
            Text('Requested date: ${instance.instanceData['requestedCompletionDate']}'),
            Text('Attachments: ${instance.instanceData['attachments']}'),
            if (instance.instanceData['reviewerNote'] case final note?)
              Text('Reviewer note: $note'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final transition in transitions)
                  OutlinedButton(
                    key: ValueKey(
                      'hoa-request-action-${transition.id}',
                    ),
                    onPressed: () => _transition(instance, transition.id),
                    child: Text(transition.label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Status history',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            for (final entry in historyItems)
              Text(entry, key: ValueKey('hoa-request-history-${entry.hashCode}')),
          ],
        ),
      ),
    );
  }

  BoxDecoration get _requestBoxDecoration => BoxDecoration(
        color: widget.modernTheme?.resolvedFill ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.modernTheme?.resolvedBorder ??
              widget.accent.withValues(alpha: 0.2),
        ),
      );

  WorkflowInstance? get _selectedInstance {
    for (final instance in _instances) {
      if (instance.instanceId == _selectedInstanceId) return instance;
    }
    return _instances.firstOrNull;
  }

  bool _canEditSelectedRequest(WorkflowInstance? selected) {
    if (selected == null) return true;
    return selected.currentState == 'submitted' ||
        selected.currentState == 'changes-needed';
  }
}

class _ArchitecturalRequestStore {
  _ArchitecturalRequestStore({
    required this.communityId,
    required this.workflowId,
  });

  final String communityId;
  final String workflowId;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: communityId,
  );
  var _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    _engine.registerDefinition(_machine);
    _ready = true;
  }

  Future<WorkflowInstance> submit({
    required String personaId,
    required String ownerLabel,
    required String projectDescription,
    required String propertyAddress,
    required String requestedCompletionDate,
    required String attachments,
  }) async {
    await ensureReady();
    final data = {
      'projectDescription': projectDescription,
      'propertyAddress': propertyAddress,
      'requestedCompletionDate': requestedCompletionDate,
      'attachments': attachments,
      'ownerPersonaId': personaId,
      'ownerLabel': ownerLabel,
      'reviewerNote': '',
      'history': [
        '$ownerLabel at ${DateTime.now().toUtc().toIso8601String()} submitted architectural request',
      ],
    };
    final instanceId = await _engine.createInstance(
      workflowType: workflowId,
      initialInstanceData: data,
      personaId: personaId,
    );
    return WorkflowInstance(
      instanceId: instanceId,
      workflowType: workflowId,
      currentState: 'submitted',
      instanceData: data,
      createdByPersonaId: personaId,
    );
  }

  Future<List<WorkflowInstance>> instancesFor(String personaId) async {
    await ensureReady();
    final page = await _engine.queryInstances(
      tabId: 'requests',
      personaId: personaId,
      limit: 100,
      query: const SurfaceQuery(sort: SortSpec(key: 'projectDescription')),
    );
    return page.items
        .where((instance) => instance.workflowType == workflowId)
        .toList(growable: false);
  }

  List<LoomWorkflowTransition> availableTransitions({
    required WorkflowInstance instance,
    required String personaId,
  }) {
    return _engine.availableTransitions(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      currentState: instance.currentState,
      instanceData: instance.instanceData,
      personaId: personaId,
    );
  }

  Future<void> apply({
    required WorkflowInstance instance,
    required String transitionId,
    required String personaId,
  }) async {
    await _engine.applyTransition(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      transitionId: transitionId,
      personaId: personaId,
    );
  }

  LoomWorkflowStateMachine get _machine => LoomWorkflowStateMachine(
        workflowType: workflowId,
        initialState: 'submitted',
        states: const {
          'submitted': LoomWorkflowState(
            label: 'Submitted',
            editableFields: [
              'projectDescription',
              'propertyAddress',
              'requestedCompletionDate',
              'attachments',
            ],
          ),
          'under-review': LoomWorkflowState(label: 'Under review'),
          'changes-needed': LoomWorkflowState(
            label: 'Changes needed',
            editableFields: [
              'projectDescription',
              'propertyAddress',
              'requestedCompletionDate',
              'attachments',
            ],
          ),
          'approved': LoomWorkflowState(label: 'Approved'),
          'denied': LoomWorkflowState(label: 'Denied'),
          'reopened': LoomWorkflowState(label: 'Reopened'),
          'withdrawn': LoomWorkflowState(label: 'Withdrawn', isTerminal: true),
        },
        renderBindings: const [
          RenderBinding(
            states: [
              'submitted',
              'under-review',
              'changes-needed',
              'approved',
              'denied',
              'reopened',
              'withdrawn',
            ],
            role: 'actor',
            tabId: 'requests',
            cardSurfaceFamily: 'statusTimeline',
            bindingKind: 'primary',
          ),
          RenderBinding(
            states: [
              'submitted',
              'under-review',
              'changes-needed',
              'reopened',
            ],
            role: 'receiver',
            tabId: 'admin',
            cardSurfaceFamily: 'dashboard',
            bindingKind: 'summary',
          ),
          RenderBinding(
            states: [
              'submitted',
              'under-review',
              'changes-needed',
              'approved',
              'denied',
              'reopened',
            ],
            role: 'receiver',
            tabId: 'admin',
            cardSurfaceFamily: 'statusTimeline',
            bindingKind: 'primary',
          ),
        ],
        instanceDataSchema: const {
          'projectDescription': InstanceDataField(
            type: 'text',
            required: true,
          ),
          'propertyAddress': InstanceDataField(type: 'text', required: true),
          'requestedCompletionDate': InstanceDataField(
            type: 'date',
            required: true,
          ),
          'attachments': InstanceDataField(type: 'text', required: true),
          'ownerPersonaId': InstanceDataField(type: 'string', required: true),
          'ownerLabel': InstanceDataField(type: 'string', required: true),
          'reviewerNote': InstanceDataField(type: 'text'),
          'history': InstanceDataField(type: 'list'),
        },
        transitions: [
          _transition(
            id: 'start-review',
            label: 'Start review',
            from: const ['submitted', 'reopened'],
            to: 'under-review',
            personas: const ['hoa-board'],
            history: 'HOA Board at \$timestamp started review',
          ),
          _transition(
            id: 'request-changes',
            label: 'Request changes',
            from: const ['submitted', 'under-review', 'reopened'],
            to: 'changes-needed',
            personas: const ['hoa-board'],
            reviewerNote: 'Please revise the color sample and setback diagram.',
            history: 'HOA Board at \$timestamp requested changes',
          ),
          _transition(
            id: 'approve',
            label: 'Approve request',
            from: const ['submitted', 'under-review', 'changes-needed', 'reopened'],
            to: 'approved',
            personas: const ['hoa-board'],
            reviewerNote: 'Approved with standard construction-hour conditions.',
            history: 'HOA Board at \$timestamp approved request',
          ),
          _transition(
            id: 'reject',
            label: 'Reject request',
            from: const ['submitted', 'under-review', 'changes-needed', 'reopened'],
            to: 'denied',
            personas: const ['hoa-board'],
            reviewerNote: 'Rejected; proposal conflicts with current covenants.',
            history: 'HOA Board at \$timestamp rejected request',
          ),
          _transition(
            id: 'resubmit',
            label: 'Retry submission',
            from: const ['changes-needed'],
            to: 'submitted',
            personas: const ['hoa-homeowner'],
            history: '{ownerLabel} at \$timestamp retried submission',
          ),
          _transition(
            id: 'reopen',
            label: 'Reopen request',
            from: const ['approved', 'denied', 'changes-needed'],
            to: 'reopened',
            personas: const ['hoa-homeowner'],
            history: '{ownerLabel} at \$timestamp reopened request',
          ),
          _transition(
            id: 'appeal',
            label: 'Appeal decision',
            from: const ['denied'],
            to: 'reopened',
            personas: const ['hoa-homeowner'],
            history: '{ownerLabel} at \$timestamp appealed decision',
          ),
          _transition(
            id: 'withdraw',
            label: 'Withdraw request',
            from: const ['submitted', 'changes-needed', 'reopened'],
            to: 'withdrawn',
            personas: const ['hoa-homeowner'],
            history: '{ownerLabel} at \$timestamp withdrew request',
          ),
        ],
      );
}

class _GardenClubEngineTabSurface extends StatefulWidget {
  const _GardenClubEngineTabSurface({
    required this.experience,
    required this.persona,
    required this.tabId,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final String tabId;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_GardenClubEngineTabSurface> createState() =>
      _GardenClubEngineTabSurfaceState();
}

class _GardenClubEngineTabSurfaceState
    extends State<_GardenClubEngineTabSurface> {
  static final _stores = <String, _GardenClubEngineStore>{};

  late final _GardenClubEngineStore _store;
  List<WorkflowInstance> _instances = const [];
  final Map<String, TextEditingController> _controllers = {};
  String? _loadError;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _store = _stores.putIfAbsent(
      widget.experience.extensionId,
      () => _GardenClubEngineStore(communityId: widget.experience.extensionId),
    );
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_GardenClubEngineTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persona.personaId != widget.persona.personaId ||
        oldWidget.tabId != widget.tabId) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _store.ensureReady().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw StateError('garden ensureReady timeout'),
      );
      final instances = await _store.instancesFor(
        tabId: widget.tabId,
        personaId: widget.persona.personaId,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw StateError('garden instancesFor timeout (${widget.tabId})'),
      );
      _syncControllers(instances);
      if (!mounted) return;
      setState(() {
        _instances = instances;
        _loadError = null;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loaded = true;
      });
    }
  }

  Future<void> _transition(WorkflowInstance instance, String transitionId) async {
    await _store.apply(
      instance: instance,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  Future<void> _saveEditableFields(WorkflowInstance instance) async {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    final updates = <String, dynamic>{
      for (final field in fields)
        field: _controllerFor(instance.instanceId, field).text,
    };
    await _store.updateFields(
      instance: instance,
      fieldUpdates: updates,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Text(
          _loadError!,
          key: ValueKey('garden-load-error-${widget.tabId}'),
        ),
      );
    }
    if (widget.tabId == 'home') {
      return _buildHomePins(context);
    }
    return Column(
      key: ValueKey('garden-engine-${widget.tabId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tabId == 'calendar')
          _gardenWorkflowCard(
            context,
            _instance('garden-event-rsvp'),
            title: 'Spring Planting Workshop',
            subtitle: 'Calendar RSVP',
            icon: Icons.event_available_outlined,
          ),
        if (widget.tabId == 'marketplace') ...[
          _gardenWorkflowCard(
            context,
            _instance('garden-tool-loan'),
            title: 'Broadfork',
            subtitle: 'Shared equipment',
            icon: Icons.handyman_outlined,
          ),
          const SizedBox(height: 12),
          _gardenWorkflowCard(
            context,
            _instance('plant-exchange-submission'),
            title: 'Plant exchange listing',
            subtitle: 'Plant offer and claim',
            icon: Icons.local_florist_outlined,
          ),
        ],
        if (widget.tabId == 'care')
          _gardenWorkflowCard(
            context,
            _instance('garden-volunteer-shift'),
            title: 'Saturday bed prep',
            subtitle: 'Volunteer roster',
            icon: Icons.volunteer_activism_outlined,
          ),
        if (widget.tabId == 'documents')
          _gardenWorkflowCard(
            context,
            _instance('garden-export-custom-schemas'),
            title: 'Garden custom-schema export',
            subtitle: 'Export wizard',
            icon: Icons.ios_share_outlined,
          ),
      ],
    );
  }

  WorkflowInstance? _instance(String workflowType) {
    for (final instance in _instances) {
      if (instance.workflowType == workflowType) return instance;
    }
    return null;
  }

  void _syncControllers(List<WorkflowInstance> instances) {
    for (final instance in instances) {
      final fields = _store.editableFieldsFor(
        workflowType: instance.workflowType,
        state: instance.currentState,
      );
      for (final field in fields) {
        final controller = _controllerFor(instance.instanceId, field);
        controller.text = '${instance.instanceData[field] ?? ''}';
      }
    }
  }

  TextEditingController _controllerFor(String instanceId, String field) {
    final key = '$instanceId::$field';
    return _controllers.putIfAbsent(key, TextEditingController.new);
  }

  Widget _buildHomePins(BuildContext context) {
    final event = _instance('garden-event-rsvp');
    final tool = _instance('garden-tool-loan');
    final plant = _instance('plant-exchange-submission');
    final shift = _instance('garden-volunteer-shift');
    final export = _instance('garden-export-custom-schemas');
    return Column(
      key: const ValueKey('garden-engine-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _gardenHomePin(
          context,
          key: const ValueKey('garden-home-activity'),
          title: "This week's activity",
          icon: Icons.event_note_outlined,
          body:
              '${event?.instanceData['eventTitle'] ?? 'Workshop'} · ${event?.instanceData['eventDateTime'] ?? ''}\n'
              '${shift?.instanceData['shiftTitle'] ?? 'Shift'} · ${shift?.instanceData['openSpots'] ?? 0} open spots',
        ),
        const SizedBox(height: 12),
        _gardenHomePin(
          context,
          key: const ValueKey('garden-home-exchange'),
          title: 'Help and exchange needed',
          icon: Icons.storefront_outlined,
          body:
              '${tool?.instanceData['itemTitle'] ?? 'Tool'} · ${_gardenStateLabel(tool?.currentState ?? 'available')}\n'
              '${plant?.instanceData['plantType'] ?? 'Plant listing'} · ${_gardenStateLabel(plant?.currentState ?? 'draft')}',
        ),
        const SizedBox(height: 12),
        _gardenHomePin(
          context,
          key: const ValueKey('garden-home-records'),
          title: 'Records available',
          icon: Icons.folder_open_outlined,
          body:
              '${export?.instanceData['downloadStatus'] ?? 'Not generated'}\n'
              '${export?.instanceData['checksum'] ?? ''}',
        ),
      ],
    );
  }

  Widget _gardenHomePin(
    BuildContext context, {
    required Key key,
    required String title,
    required IconData icon,
    required String body,
  }) {
    return DecoratedBox(
      key: key,
      decoration: _gardenBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: widget.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gardenWorkflowCard(
    BuildContext context,
    WorkflowInstance? instance, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    if (instance == null) {
      return _TabEmptyState(
        icon: icon,
        title: '$title unavailable',
        body: 'No engine instance is available for this Garden Club surface.',
        accent: widget.accent,
        modernTheme: widget.modernTheme,
      );
    }
    final transitions = _store.availableTransitions(
      instance: instance,
      personaId: widget.persona.personaId,
    );
    final machine = _store.machineFor(instance.workflowType);
    final data = instance.instanceData;
    final historyItems = _historyItems(data);
    final queue = data['queuePersonaIds'];
    final queueCount = queue is List ? queue.length : 0;
    return DecoratedBox(
      key: ValueKey('garden-card-${instance.workflowType}'),
      decoration: _gardenBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: widget.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.flag_outlined,
                  label:
                      'State: ${machine.states[instance.currentState]?.label ?? _gardenStateLabel(instance.currentState)}',
                  foreground: widget.accent,
                ),
                for (final pill in _factPills(machine, data)) pill,
                if (queueCount > 0)
                  _SurfaceFactPill(
                    icon: Icons.people_alt_outlined,
                    label: 'Queue: $queueCount',
                    foreground: widget.accent,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (data['eventTitle'] case final value?) Text('$value'),
            if (data['itemTitle'] case final value?) Text('$value'),
            if (data['plantType'] case final value?) Text('$value'),
            if (data['shiftTitle'] case final value?) Text('$value'),
            if (instance.workflowType == 'garden-export-custom-schemas')
              _buildExportReview(data),
            if (_store.editableFieldsFor(
                  workflowType: instance.workflowType,
                  state: instance.currentState,
                ).isNotEmpty)
              _buildEditableFields(instance),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final transition in transitions)
                  OutlinedButton.icon(
                    key: ValueKey('garden-action-${transition.id}'),
                    style: _gardenButtonStyle(transition),
                    onPressed: () => _transition(instance, transition.id),
                    icon: Icon(_gardenIconForTransition(transition.icon)),
                    label: Text(transition.label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Garden timeline',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            for (final item in historyItems)
              Text(item, key: ValueKey('garden-history-${item.hashCode}')),
          ],
        ),
      ),
    );
  }

  List<Widget> _factPills(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> data,
  ) {
    final pills = <Widget>[];
    for (final entry in machine.instanceDataSchema.entries) {
      final field = entry.value;
      final iconName = field.displayIcon;
      if (iconName == null) continue;
      final value = data[entry.key];
      final isEmpty = value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty);
      if (field.hideWhenEmpty && isEmpty) continue;
      final label = _renderGardenLabel(field.labelTemplate, value);
      if (label.isEmpty) continue;
      pills.add(
        _SurfaceFactPill(
          icon: _gardenFactIcon(iconName),
          label: label,
          foreground: widget.accent,
        ),
      );
    }
    return pills;
  }

  Widget _buildEditableFields(WorkflowInstance instance) {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    return Column(
      key: ValueKey('garden-edit-form-${instance.workflowType}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        for (final field in fields)
          TextField(
            key: ValueKey('garden-edit-$field'),
            controller: _controllerFor(instance.instanceId, field),
            decoration: InputDecoration(labelText: _gardenFieldLabel(field)),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: ValueKey('garden-save-edit-${instance.workflowType}'),
          onPressed: () => _saveEditableFields(instance),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save edits'),
        ),
      ],
    );
  }

  Widget _buildExportReview(Map<String, dynamic> data) {
    final schemas = data['schemas'];
    final schemaItems = schemas is List
        ? [for (final item in schemas) if (item is String) item]
        : const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 2),
        const Text('Review and confirm export scope'),
        if (schemaItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final schema in schemaItems)
                Chip(label: Text(schema), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      ],
    );
  }

  List<String> _historyItems(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      if (!entry.key.toLowerCase().contains('history')) continue;
      final value = entry.value;
      if (value is List) {
        return [for (final item in value) if (item is String) item];
      }
    }
    return const <String>[];
  }

  ButtonStyle _gardenButtonStyle(LoomWorkflowTransition transition) {
    final destructive = transition.tone == 'destructive' ||
        transition.id.contains('cancel') ||
        transition.id.contains('withdraw');
    final primary = transition.tone == 'primary' ||
        transition.id.contains('submit') ||
        transition.id.contains('request') ||
        transition.id.contains('claim') ||
        transition.id.contains('sign-up') ||
        transition.id.contains('generate');
    return OutlinedButton.styleFrom(
      foregroundColor: destructive
          ? Colors.red.shade800
          : primary
              ? Colors.white
              : widget.accent,
      backgroundColor: primary ? widget.accent : null,
      side: BorderSide(
        color: destructive ? Colors.red.shade800 : widget.accent,
      ),
    );
  }

  IconData _gardenIconForTransition(String? icon) {
    switch (icon) {
      case 'event_available':
        return Icons.event_available_outlined;
      case 'playlist_add':
        return Icons.playlist_add_outlined;
      case 'event_busy':
        return Icons.event_busy_outlined;
      case 'cancel':
        return Icons.cancel_outlined;
      case 'queue':
        return Icons.people_alt_outlined;
      case 'undo':
        return Icons.undo_outlined;
      case 'handshake':
        return Icons.handshake_outlined;
      case 'assignment_return':
        return Icons.assignment_return_outlined;
      case 'report':
        return Icons.report_outlined;
      case 'local_florist':
        return Icons.local_florist_outlined;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'volunteer_activism':
        return Icons.volunteer_activism_outlined;
      case 'lock':
        return Icons.lock_outline;
      case 'download':
        return Icons.ios_share_outlined;
    }
    return Icons.fact_check_outlined;
  }

  IconData _gardenFactIcon(String iconName) {
    switch (iconName) {
      case 'schedule':
        return Icons.schedule_outlined;
      case 'location_on':
        return Icons.location_on_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'inventory':
        return Icons.inventory_2_outlined;
      case 'person':
        return Icons.person_outline;
      case 'place':
        return Icons.place_outlined;
      case 'privacy_tip':
        return Icons.privacy_tip_outlined;
      case 'schema':
        return Icons.account_tree_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'verified':
        return Icons.verified_outlined;
      case 'cloud_upload':
        return Icons.cloud_upload_outlined;
      case 'track_changes':
        return Icons.track_changes_outlined;
      case 'download':
        return Icons.download_outlined;
    }
    return Icons.label_outline;
  }

  String _renderGardenLabel(String? template, dynamic value) {
    if (template == null) return '';
    return template
        .replaceAll('{value.length}', value is List ? '${value.length}' : '0')
        .replaceAll('{value}', value is List ? value.join(', ') : '${value ?? ''}');
  }

  String _gardenFieldLabel(String field) {
    switch (field) {
      case 'plantType':
        return 'Plant type';
      case 'quantity':
        return 'Quantity';
      case 'pickupNotes':
        return 'Pickup notes';
      case 'privacyNote':
        return 'Privacy note';
    }
    return field;
  }

  BoxDecoration get _gardenBoxDecoration => BoxDecoration(
        color: widget.modernTheme?.resolvedFill ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.modernTheme?.resolvedBorder ??
              widget.accent.withValues(alpha: 0.2),
        ),
      );
}

class _GardenClubEngineStore {
  _GardenClubEngineStore({required this.communityId});

  final String communityId;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: communityId,
  );
  _GardenFixtureBundle? _fixture;
  Future<void>? _readyFuture;
  var _ready = false;

  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _readyFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _fixture ??= await _GardenFixtureBundle.load().timeout(
      const Duration(seconds: 3),
      onTimeout: () => throw StateError('garden fixture load timeout'),
    );
    for (final machine in _fixture!.machines.values) {
      _engine.registerDefinition(machine);
    }
    await _seedInstances().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError('garden seed timeout'),
    );
    _ready = true;
  }

  Future<void> _seedInstances() async {
    for (final instance in _fixture!.instances) {
      final instanceId = await _engine.createInstance(
        workflowType: instance.workflowType,
        initialInstanceData: instance.instanceData,
        personaId: instance.createdByPersonaId,
      );
      if (instance.workflowType == 'gear-loan-request' &&
          instance.currentState == 'giveaway') {
        await _engine.applyTransition(
          workflowType: instance.workflowType,
          instanceId: instanceId,
          transitionId: 'offer-giveaway',
          personaId: instance.createdByPersonaId,
        );
      }
    }
  }

  Future<List<WorkflowInstance>> instancesFor({
    required String tabId,
    required String personaId,
  }) async {
    await ensureReady();
    final sortKey = switch (tabId) {
      'calendar' => 'eventTitle',
      'marketplace' => 'itemTitle',
      'care' => 'shiftTitle',
      'documents' => 'checksum',
      'home' => 'eventTitle',
      _ => 'eventTitle',
    };
    final page = await _engine.queryInstances(
      tabId: tabId,
      personaId: personaId,
      limit: 100,
      query: SurfaceQuery(sort: SortSpec(key: sortKey)),
    );
    final allowed = switch (tabId) {
      'calendar' => const {'garden-event-rsvp'},
      'marketplace' => const {'garden-tool-loan', 'plant-exchange-submission'},
      'care' => const {'garden-volunteer-shift'},
      'documents' => const {'garden-export-custom-schemas'},
      'home' => const {
          'garden-event-rsvp',
          'garden-tool-loan',
          'plant-exchange-submission',
          'garden-volunteer-shift',
          'garden-export-custom-schemas',
        },
      _ => const <String>{},
    };
    return page.items
        .where((instance) => allowed.contains(instance.workflowType))
        .toList(growable: false);
  }

  List<LoomWorkflowTransition> availableTransitions({
    required WorkflowInstance instance,
    required String personaId,
  }) {
    return _engine.availableTransitions(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      currentState: instance.currentState,
      instanceData: instance.instanceData,
      personaId: personaId,
    );
  }

  Future<void> apply({
    required WorkflowInstance instance,
    required String transitionId,
    required String personaId,
  }) async {
    await _engine.applyTransition(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      transitionId: transitionId,
      personaId: personaId,
    );
  }

  Future<void> updateFields({
    required WorkflowInstance instance,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) async {
    await _engine.updateInstanceFields(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      fieldUpdates: fieldUpdates,
      personaId: personaId,
    );
  }

  LoomWorkflowStateMachine machineFor(String workflowType) {
    return _fixture!.machines[workflowType]!;
  }

  List<String> editableFieldsFor({
    required String workflowType,
    required String state,
  }) {
    return machineFor(workflowType).states[state]?.editableFields ?? const [];
  }
}

class _GardenFixtureBundle {
  _GardenFixtureBundle({
    required this.machines,
    required this.instances,
  });

  final Map<String, LoomWorkflowStateMachine> machines;
  final List<_GardenSeedInstance> instances;

  static Future<_GardenFixtureBundle> load() async {
    final content = _gardenBundledFixtureJsonc;
    final json = jsonDecode(_stripGardenJsoncComments(content))
        as Map<String, dynamic>;
    final definitions =
        json['workflowDefinitions'] as Map<String, dynamic>? ?? const {};
    final machines = <String, LoomWorkflowStateMachine>{};
    for (final entry in definitions.entries) {
      machines[entry.key] = LoomWorkflowStateMachine.fromJson(
        _normalizeGardenMachineJson(entry.value as Map<String, dynamic>),
        entry.key,
      );
    }
    final rawInstances = json['workflowInstances'] as List<dynamic>? ?? const [];
    final instances = [
      for (final item in rawInstances)
        _GardenSeedInstance.fromJson(item as Map<String, dynamic>),
    ];
    return _GardenFixtureBundle(machines: machines, instances: instances);
  }
}

class _GardenSeedInstance {
  const _GardenSeedInstance({
    required this.instanceId,
    required this.workflowType,
    required this.currentState,
    required this.createdByPersonaId,
    required this.instanceData,
  });

  final String instanceId;
  final String workflowType;
  final String currentState;
  final String createdByPersonaId;
  final Map<String, dynamic> instanceData;

  factory _GardenSeedInstance.fromJson(Map<String, dynamic> json) {
    return _GardenSeedInstance(
      instanceId: json['instanceId'] as String,
      workflowType: json['workflowType'] as String,
      currentState: json['currentState'] as String,
      createdByPersonaId: json['createdByPersonaId'] as String,
      instanceData: Map<String, dynamic>.from(
        json['instanceData'] as Map<String, dynamic>,
      ),
    );
  }
}

Map<String, dynamic> _normalizeGardenMachineJson(Map<String, dynamic> json) {
  final next = Map<String, dynamic>.from(json);
  final transitions = (json['transitions'] as List<dynamic>? ?? const [])
      .map((transition) {
        final map = Map<String, dynamic>.from(transition as Map<String, dynamic>);
        final effects = (map['effects'] as List<dynamic>? ?? const []).map((effect) {
          final effectMap = Map<String, dynamic>.from(effect as Map<String, dynamic>);
          final value = effectMap['value'];
          if (value is String) {
            effectMap['value'] = value
                .replaceAll('{actorLabel}', r'$actor')
                .replaceAll('{actor}', r'$actor');
          }
          return effectMap;
        }).toList();
        map['effects'] = effects;
        return map;
      })
      .toList();
  next['transitions'] = transitions;
  return next;
}

String _stripGardenJsoncComments(String content) {
  final output = StringBuffer();
  var inString = false;
  var escaped = false;
  var inLineComment = false;
  var inBlockComment = false;
  for (var index = 0; index < content.length; index += 1) {
    final char = content[index];
    final next = index + 1 < content.length ? content[index + 1] : '';
    if (inLineComment) {
      if (char == '\n') {
        inLineComment = false;
        output.write(char);
      }
      continue;
    }
    if (inBlockComment) {
      if (char == '*' && next == '/') {
        inBlockComment = false;
        index += 1;
      }
      continue;
    }
    if (!inString && char == '/' && next == '/') {
      inLineComment = true;
      index += 1;
      continue;
    }
    if (!inString && char == '/' && next == '*') {
      inBlockComment = true;
      index += 1;
      continue;
    }
    output.write(char);
    if (char == '"' && !escaped) {
      inString = !inString;
    }
    escaped = char == '\\' && !escaped;
    if (char != '\\') {
      escaped = false;
    }
  }
  return output.toString();
}

const _gardenBundledFixtureJsonc = r'''
{
  "personas": ["garden-member", "garden-coordinator"],
  "templates": {
    "calendarAgenda": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "formEntry": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow", "WorkflowFormFieldList"] },
    "stateMachineGrid": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "volunteerRoster": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "exportWizard": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] }
  },
  "workflowDefinitions": {
    "garden-event-rsvp": {
      "initialState": "open",
      "states": {
        "open": { "label": "Open" },
        "rsvped": { "label": "RSVPed" },
        "waitlisted": { "label": "Waitlisted" },
        "cancelled": { "label": "Cancelled", "isTerminal": true }
      },
      "transitions": [
        { "id": "rsvp-going", "label": "RSVP going", "icon": "event_available", "tone": "primary", "from": ["open", "waitlisted"], "to": "rsvped", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "rsvpStatus", "value": "Going" }, { "op": "append", "key": "eventHistory", "value": "{eventTitle} RSVP changed to Going at $timestamp" }] },
        { "id": "join-waitlist", "label": "Join waitlist", "icon": "playlist_add", "tone": "secondary", "from": ["open"], "to": "waitlisted", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "rsvpStatus", "value": "Waitlisted" }, { "op": "append", "key": "eventHistory", "value": "{eventTitle} waitlist joined at $timestamp" }] },
        { "id": "cancel-rsvp", "label": "Cancel RSVP", "icon": "event_busy", "tone": "destructive", "from": ["rsvped", "waitlisted"], "to": "open", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "rsvpStatus", "value": "" }, { "op": "append", "key": "eventHistory", "value": "{eventTitle} RSVP cancelled at $timestamp" }] },
        { "id": "cancel-event", "label": "Cancel event", "icon": "cancel", "tone": "destructive", "from": ["open", "rsvped", "waitlisted"], "to": "cancelled", "guard": { "allowedPersonaIds": ["garden-coordinator"] }, "effects": [{ "op": "append", "key": "eventHistory", "value": "{eventTitle} cancelled by coordinator at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["open", "rsvped", "waitlisted", "cancelled"], "role": "actor", "tabId": "calendar", "cardSurfaceFamily": "calendarAgenda", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "eventTitle": { "type": "text", "required": true, "displayContexts": ["tile", "detail"] },
        "eventDateTime": { "type": "text", "required": true, "displayIcon": "schedule", "labelTemplate": "{value}" },
        "location": { "type": "text", "required": true, "displayIcon": "location_on", "labelTemplate": "{value}" },
        "capacityLabel": { "type": "text", "displayIcon": "groups", "labelTemplate": "{value}" },
        "rsvpStatus": { "type": "text", "writableBy": "effect" },
        "eventHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "garden-tool-loan": {
      "initialState": "available",
      "states": {
        "available": { "label": "Available" },
        "queued": { "label": "Queued" },
        "loaned": { "label": "Loaned" },
        "returned": { "label": "Returned", "isTerminal": true },
        "lost": { "label": "Lost", "isTerminal": true }
      },
      "transitions": [
        { "id": "request-loan", "label": "Request loan", "icon": "handshake", "tone": "primary", "from": ["available"], "to": "loaned", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "{actorLabel}" }, { "op": "append", "key": "custodyHistory", "value": "{actorLabel} borrowed {itemTitle} at $timestamp" }] },
        { "id": "join-queue", "label": "Join queue", "icon": "queue", "tone": "secondary", "from": ["loaned"], "to": "queued", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "append", "key": "queuePersonaIds", "value": "{actor}" }] },
        { "id": "leave-queue", "label": "Leave queue", "icon": "undo", "tone": "secondary", "from": ["queued"], "to": "loaned", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "removeValue", "key": "queuePersonaIds", "value": "{actor}" }] },
        { "id": "return-tool", "label": "Return tool", "icon": "assignment_return", "tone": "primary", "from": ["loaned", "queued"], "to": "returned", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} returned at $timestamp" }] },
        { "id": "report-lost", "label": "Report lost", "icon": "report", "tone": "destructive", "from": ["loaned", "queued"], "to": "lost", "guard": { "allowedPersonaIds": ["garden-member", "garden-coordinator"] }, "effects": [{ "op": "append", "key": "custodyHistory", "value": "{itemTitle} reported lost at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["available", "queued", "loaned", "returned", "lost"], "role": "any", "tabId": "marketplace", "cardSurfaceFamily": "stateMachineGrid", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "itemTitle": { "type": "text", "required": true, "displayContexts": ["tile", "detail"] },
        "mode": { "type": "text", "required": true, "displayIcon": "inventory_2", "labelTemplate": "{value}" },
        "currentHolder": { "type": "text", "writableBy": "effect", "displayIcon": "person", "labelTemplate": "Holder: {value}", "hideWhenEmpty": true },
        "queuePersonaIds": { "type": "list", "writableBy": "effect" },
        "custodyHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "plant-exchange-submission": {
      "initialState": "draft",
      "states": {
        "draft": { "label": "Draft", "editableFields": ["plantType", "quantity", "pickupNotes", "privacyNote"] },
        "submitted": { "label": "Submitted" },
        "claimed": { "label": "Claimed" },
        "withdrawn": { "label": "Withdrawn", "isTerminal": true }
      },
      "transitions": [
        { "id": "submit-listing", "label": "Submit listing", "icon": "local_florist", "tone": "primary", "from": ["draft"], "to": "submitted", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "append", "key": "exchangeHistory", "value": "{plantType} submitted at $timestamp" }] },
        { "id": "claim", "label": "Claim", "icon": "check_circle", "tone": "primary", "from": ["submitted"], "to": "claimed", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "claimantPersonaId", "value": "{actor}" }, { "op": "append", "key": "exchangeHistory", "value": "{plantType} claimed at $timestamp" }] },
        { "id": "cancel-claim", "label": "Cancel claim", "icon": "undo", "tone": "secondary", "from": ["claimed"], "to": "submitted", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "set", "key": "claimantPersonaId", "value": "" }, { "op": "append", "key": "exchangeHistory", "value": "{plantType} claim cancelled at $timestamp" }] },
        { "id": "withdraw", "label": "Withdraw", "icon": "delete", "tone": "destructive", "from": ["draft", "submitted", "claimed"], "to": "withdrawn", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "append", "key": "exchangeHistory", "value": "{plantType} withdrawn at $timestamp" }] }
      ],
      "renderBindings": [
        { "states": ["draft"], "role": "actor", "tabId": "marketplace", "cardSurfaceFamily": "formEntry", "bindingKind": "primary" },
        { "states": ["submitted", "claimed", "withdrawn"], "role": "any", "tabId": "marketplace", "cardSurfaceFamily": "stateMachineGrid", "bindingKind": "primary" }
      ],
      "instanceDataSchema": {
        "plantType": { "type": "text", "required": true, "writableBy": "formEntry", "displayContexts": ["tile", "detail"] },
        "quantity": { "type": "text", "required": true, "writableBy": "formEntry", "displayIcon": "inventory", "labelTemplate": "{value}" },
        "pickupNotes": { "type": "text", "writableBy": "formEntry", "displayIcon": "place", "labelTemplate": "{value}" },
        "privacyNote": { "type": "text", "writableBy": "formEntry", "displayIcon": "privacy_tip", "labelTemplate": "{value}" },
        "claimantPersonaId": { "type": "text", "writableBy": "effect" },
        "exchangeHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "garden-volunteer-shift": {
      "initialState": "open",
      "states": {
        "open": { "label": "Open" },
        "signed-up": { "label": "Signed up" }
      },
      "transitions": [
        { "id": "sign-up", "label": "Sign up", "icon": "volunteer_activism", "tone": "primary", "from": ["open"], "to": "signed-up", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "append", "key": "signedUpPersonaIds", "value": "{actor}" }] },
        { "id": "cancel-signup", "label": "Cancel signup", "icon": "undo", "tone": "secondary", "from": ["signed-up"], "to": "open", "guard": { "allowedPersonaIds": ["garden-member"] }, "effects": [{ "op": "append", "key": "shiftHistory", "value": "{actorLabel} cancelled at $timestamp" }] },
        { "id": "close-shift", "label": "Close shift", "icon": "lock", "tone": "destructive", "from": ["open", "signed-up"], "to": "closed", "guard": { "allowedPersonaIds": ["garden-coordinator"] }, "effects": [{ "op": "append", "key": "shiftHistory", "value": "{shiftTitle} closed at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["open", "signed-up", "closed"], "role": "any", "tabId": "care", "cardSurfaceFamily": "volunteerRoster", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "shiftTitle": { "type": "text", "required": true, "displayContexts": ["tile", "detail"] },
        "openSpots": { "type": "number", "required": true, "displayIcon": "groups", "labelTemplate": "Open spots: {value}" },
        "signedUpPersonaIds": { "type": "list", "writableBy": "effect" },
        "shiftHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "garden-export-custom-schemas": {
      "initialState": "ready",
      "states": {
        "ready": { "label": "Ready" },
        "generated": { "label": "Generated" },
        "rolled-back": { "label": "Rolled back", "isTerminal": true }
      },
      "transitions": [
        { "id": "generate-export", "label": "Generate export", "icon": "download", "tone": "primary", "from": ["ready"], "to": "generated", "guard": { "allowedPersonaIds": ["garden-coordinator"] }, "effects": [{ "op": "set", "key": "downloadStatus", "value": "Download ready" }, { "op": "append", "key": "exportHistory", "value": "Garden export generated at $timestamp" }] },
        { "id": "rollback-export", "label": "Rollback export", "icon": "undo", "tone": "destructive", "from": ["generated"], "to": "rolled-back", "guard": { "allowedPersonaIds": ["garden-coordinator"] }, "effects": [{ "op": "set", "key": "downloadStatus", "value": "Rolled back" }, { "op": "append", "key": "exportHistory", "value": "Garden export rolled back at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["ready", "generated", "rolled-back"], "role": "actor", "tabId": "documents", "cardSurfaceFamily": "exportWizard", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "schemas": { "type": "list", "required": true, "displayIcon": "schema", "labelTemplate": "{value.length} schemas selected" },
        "redactionPreview": { "type": "text", "required": true, "displayIcon": "shield", "labelTemplate": "{value}" },
        "checksum": { "type": "text", "required": true, "displayIcon": "verified", "labelTemplate": "Checksum: {value}" },
        "destination": { "type": "text", "required": true, "displayIcon": "cloud_upload", "labelTemplate": "Destination: {value}" },
        "changeScope": { "type": "text", "required": true, "displayIcon": "track_changes", "labelTemplate": "Scope: {value}" },
        "downloadStatus": { "type": "text", "writableBy": "effect" },
        "exportHistory": { "type": "list", "writableBy": "effect" }
      }
    }
  },
  "workflowInstances": [
    { "instanceId": "garden-event-spring-planting", "workflowType": "garden-event-rsvp", "currentState": "open", "createdByPersonaId": "garden-coordinator", "instanceData": { "eventTitle": "Spring Planting Workshop", "eventDateTime": "Saturday, Apr 18 at 10:00 AM", "location": "Riverside Greenhouse", "capacityLabel": "18 of 24 spots", "rsvpStatus": "", "eventHistory": [] } },
    { "instanceId": "garden-tool-broadfork", "workflowType": "garden-tool-loan", "currentState": "available", "createdByPersonaId": "garden-member", "instanceData": { "itemTitle": "Broadfork", "mode": "Loan", "currentHolder": "", "queuePersonaIds": [], "custodyHistory": [] } },
    { "instanceId": "garden-plant-basil", "workflowType": "plant-exchange-submission", "currentState": "draft", "createdByPersonaId": "garden-member", "instanceData": { "plantType": "Sweet Genovese basil", "quantity": "6 starter pots", "pickupNotes": "Pickup Sat 1-3 PM", "privacyNote": "Contact after claim", "claimantPersonaId": "", "exchangeHistory": [] } },
    { "instanceId": "garden-shift-bed-prep", "workflowType": "garden-volunteer-shift", "currentState": "open", "createdByPersonaId": "garden-coordinator", "instanceData": { "shiftTitle": "Saturday bed prep", "openSpots": 4, "signedUpPersonaIds": [], "shiftHistory": [] } },
    { "instanceId": "garden-export-package", "workflowType": "garden-export-custom-schemas", "currentState": "ready", "createdByPersonaId": "garden-coordinator", "instanceData": { "schemas": ["garden_event", "plant_exchange"], "redactionPreview": "Protected contact fields redacted", "checksum": "8F4A-PLANT", "destination": "Garden archive package", "changeScope": "Season-to-date activity", "downloadStatus": "Not generated", "exportHistory": [] } }
  ]
}
''';

class _CameraClubEngineTabSurface extends StatefulWidget {
  const _CameraClubEngineTabSurface({
    required this.experience,
    required this.persona,
    required this.tabId,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final String tabId;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_CameraClubEngineTabSurface> createState() =>
      _CameraClubEngineTabSurfaceState();
}

class _CameraClubEngineTabSurfaceState
    extends State<_CameraClubEngineTabSurface> {
  static final _stores = <String, _CameraClubEngineStore>{};

  late final _CameraClubEngineStore _store;
  List<WorkflowInstance> _instances = const [];
  final Map<String, TextEditingController> _controllers = {};
  String? _loadError;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _store = _stores.putIfAbsent(
      widget.experience.extensionId,
      () => _CameraClubEngineStore(communityId: widget.experience.extensionId),
    );
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_CameraClubEngineTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persona.personaId != widget.persona.personaId ||
        oldWidget.tabId != widget.tabId) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _store.ensureReady().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw StateError('camera ensureReady timeout'),
      );
      final instances = await _store.instancesFor(
        tabId: widget.tabId,
        personaId: widget.persona.personaId,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw StateError('camera instancesFor timeout (${widget.tabId})'),
      );
      _syncControllers(instances);
      if (!mounted) return;
      setState(() {
        _instances = instances;
        _loadError = null;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loaded = true;
      });
    }
  }

  Future<void> _transition(WorkflowInstance instance, String transitionId) async {
    await _store.apply(
      instance: instance,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  Future<void> _saveEditableFields(WorkflowInstance instance) async {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    final updates = <String, dynamic>{
      for (final field in fields)
        field: _controllerFor(instance.instanceId, field).text,
    };
    await _store.updateFields(
      instance: instance,
      fieldUpdates: updates,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Text(
          _loadError!,
          key: ValueKey('camera-load-error-${widget.tabId}'),
        ),
      );
    }
    if (widget.tabId == 'home') {
      return _buildHomePins(context);
    }
    return Column(
      key: ValueKey('camera-engine-${widget.tabId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tabId == 'calendar')
          _cameraWorkflowCard(
            context,
            _firstInstance('photo-walk-rsvp'),
            title: 'Warehouse District golden-hour walk',
            subtitle: 'Route, capacity, and RSVP state',
            icon: Icons.camera_alt_outlined,
          ),
        if (widget.tabId == 'critique') ...[
          _cameraWorkflowCard(
            context,
            _firstInstance('critique-submission'),
            title: 'Rain reflections critique',
            subtitle: 'Submission form and image-forward grid',
            icon: Icons.photo_camera_back_outlined,
          ),
          const SizedBox(height: 12),
          _cameraThreadCard(context, _firstInstance('critique-submission')),
        ],
        if (widget.tabId == 'marketplace')
          for (final instance in _instances)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _cameraWorkflowCard(
                context,
                instance,
                title: '${instance.instanceData['itemTitle'] ?? 'Gear'}',
                subtitle: '${instance.instanceData['mode'] ?? 'Loan'} listing',
                icon: Icons.camera_outdoor_outlined,
              ),
            ),
        if (widget.tabId == 'messages')
          _cameraThreadCard(context, _firstInstance('critique-submission')),
        if (widget.tabId == 'admin')
          _cameraWorkflowCard(
            context,
            _firstInstance('camera-validation-report'),
            title: 'Validation and completion report',
            subtitle: 'Organizer-only status timeline',
            icon: Icons.admin_panel_settings_outlined,
          ),
      ],
    );
  }

  WorkflowInstance? _firstInstance(String workflowType) {
    for (final instance in _instances) {
      if (instance.workflowType == workflowType) return instance;
    }
    return null;
  }

  void _syncControllers(List<WorkflowInstance> instances) {
    for (final instance in instances) {
      final fields = _store.editableFieldsFor(
        workflowType: instance.workflowType,
        state: instance.currentState,
      );
      for (final field in fields) {
        final controller = _controllerFor(instance.instanceId, field);
        controller.text = '${instance.instanceData[field] ?? ''}';
      }
    }
  }

  TextEditingController _controllerFor(String instanceId, String field) {
    final key = '$instanceId::$field';
    return _controllers.putIfAbsent(key, TextEditingController.new);
  }

  Widget _buildHomePins(BuildContext context) {
    final walk = _firstInstance('photo-walk-rsvp');
    final critique = _firstInstance('critique-submission');
    final gear = _firstInstance('gear-loan-request');
    final report = _firstInstance('camera-validation-report');
    return Column(
      key: const ValueKey('camera-engine-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cameraHomePin(
          context,
          key: const ValueKey('camera-home-walk'),
          title: 'Next photo walk',
          icon: Icons.route_outlined,
          body:
              '${walk?.instanceData['routeName'] ?? 'Route'}\n'
              '${walk?.instanceData['eventDateTime'] ?? ''} · ${walk?.instanceData['location'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _cameraHomePin(
          context,
          key: const ValueKey('camera-home-critique'),
          title: 'Critique queue',
          icon: Icons.photo_library_outlined,
          body:
              '${critique?.instanceData['photoTitle'] ?? 'Photo'} · ${_cameraStateLabel(critique?.currentState ?? 'draft')}\n'
              '${critique?.instanceData['thumbnailLabel'] ?? 'Thumbnail ready'}',
        ),
        const SizedBox(height: 12),
        _cameraHomePin(
          context,
          key: const ValueKey('camera-home-gear'),
          title: 'Gear and validation',
          icon: Icons.camera_outdoor_outlined,
          body:
              '${gear?.instanceData['itemTitle'] ?? 'Gear'} · ${_cameraStateLabel(gear?.currentState ?? 'available')}\n'
              '${report?.instanceData['passState'] ?? 'Validation pending'}',
        ),
      ],
    );
  }

  Widget _cameraHomePin(
    BuildContext context, {
    required Key key,
    required String title,
    required IconData icon,
    required String body,
  }) {
    return DecoratedBox(
      key: key,
      decoration: _cameraBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: widget.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraThreadCard(BuildContext context, WorkflowInstance? instance) {
    final comments = instance?.instanceData['critiqueComments'];
    final items = comments is List
        ? [for (final item in comments) if (item is String) item]
        : const <String>[];
    return DecoratedBox(
      key: const ValueKey('camera-critique-thread'),
      decoration: _cameraBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Attached critique thread',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Text(item, key: ValueKey('camera-thread-${item.hashCode}')),
          ],
        ),
      ),
    );
  }

  Widget _cameraWorkflowCard(
    BuildContext context,
    WorkflowInstance? instance, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    if (instance == null) {
      return _TabEmptyState(
        icon: icon,
        title: '$title unavailable',
        body: 'No engine instance is available for this Camera Club surface.',
        accent: widget.accent,
        modernTheme: widget.modernTheme,
      );
    }
    final transitions = _store.availableTransitions(
      instance: instance,
      personaId: widget.persona.personaId,
    );
    final machine = _store.machineFor(instance.workflowType);
    final data = instance.instanceData;
    final queue = data['queuePersonaIds'];
    final queueCount = queue is List ? queue.length : 0;
    return DecoratedBox(
      key: ValueKey('camera-card-${instance.workflowType}-${instance.instanceId}'),
      decoration: _cameraBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: widget.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.flag_outlined,
                  label:
                      'State: ${machine.states[instance.currentState]?.label ?? _cameraStateLabel(instance.currentState)}',
                  foreground: widget.accent,
                ),
                for (final pill in _factPills(machine, data)) pill,
                if (queueCount > 0)
                  _SurfaceFactPill(
                    icon: Icons.people_alt_outlined,
                    label: 'Queue: $queueCount',
                    foreground: widget.accent,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final field in const [
              'routeName',
              'photoTitle',
              'thumbnailLabel',
              'itemTitle',
              'currentHolder',
              'passState',
            ])
              if (data[field] case final value?) Text('$value'),
            if (instance.workflowType == 'critique-submission')
              const Text(
                'Image-forward critique grid',
                key: ValueKey('camera-critique-grid'),
              ),
            if (instance.workflowType == 'camera-validation-report')
              _buildValidationReport(data),
            if (_store.editableFieldsFor(
                  workflowType: instance.workflowType,
                  state: instance.currentState,
                ).isNotEmpty)
              _buildEditableFields(instance),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final transition in transitions)
                  OutlinedButton.icon(
                    key: ValueKey('camera-action-${transition.id}'),
                    style: _cameraButtonStyle(transition),
                    onPressed: () => _transition(instance, transition.id),
                    icon: Icon(_cameraIconForTransition(transition.icon)),
                    label: Text(transition.label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in _historyItems(data))
              Text(item, key: ValueKey('camera-history-${item.hashCode}')),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFields(WorkflowInstance instance) {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    return Column(
      key: ValueKey('camera-edit-form-${instance.workflowType}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        for (final field in fields)
          TextField(
            key: ValueKey('camera-edit-$field'),
            controller: _controllerFor(instance.instanceId, field),
            decoration: InputDecoration(labelText: _cameraFieldLabel(field)),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: ValueKey('camera-save-edit-${instance.workflowType}'),
          onPressed: () => _saveEditableFields(instance),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save edits'),
        ),
      ],
    );
  }

  Widget _buildValidationReport(Map<String, dynamic> data) {
    final requested = data['requestedWorkflows'];
    final paths = data['packagePaths'];
    return Column(
      key: const ValueKey('camera-admin-validation-status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text('Requested workflows: ${requested is List ? requested.join(', ') : requested ?? ''}'),
        Text('Package paths: ${paths is List ? paths.join(', ') : paths ?? ''}'),
      ],
    );
  }

  List<Widget> _factPills(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> data,
  ) {
    final pills = <Widget>[];
    for (final entry in machine.instanceDataSchema.entries) {
      final field = entry.value;
      final iconName = field.displayIcon;
      if (iconName == null) continue;
      final value = data[entry.key];
      final isEmpty = value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty);
      if (field.hideWhenEmpty && isEmpty) continue;
      final label = _renderCameraLabel(field.labelTemplate, value);
      if (label.isEmpty) continue;
      pills.add(
        _SurfaceFactPill(
          icon: _cameraFactIcon(iconName),
          label: label,
          foreground: widget.accent,
        ),
      );
    }
    return pills;
  }

  List<String> _historyItems(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      if (!entry.key.toLowerCase().contains('history')) continue;
      final value = entry.value;
      if (value is List) {
        return [for (final item in value) if (item is String) item];
      }
    }
    return const <String>[];
  }

  String _renderCameraLabel(String? template, dynamic value) {
    if (template == null) return '';
    return template
        .replaceAll('{value.length}', value is List ? '${value.length}' : '0')
        .replaceAll('{value}', value is List ? value.join(', ') : '${value ?? ''}');
  }

  ButtonStyle _cameraButtonStyle(LoomWorkflowTransition transition) {
    final destructive = transition.tone == 'destructive' ||
        transition.id.contains('withdraw') ||
        transition.id.contains('leave') ||
        transition.id.contains('pause') ||
        transition.id.contains('delist');
    final primary = transition.tone == 'primary' ||
        transition.id.contains('submit') ||
        transition.id.contains('request') ||
        transition.id.contains('claim') ||
        transition.id.contains('validated') ||
        transition.id.contains('rsvp');
    return OutlinedButton.styleFrom(
      foregroundColor: destructive
          ? Colors.red.shade800
          : primary
              ? Colors.white
              : widget.accent,
      backgroundColor: primary ? widget.accent : null,
      side: BorderSide(
        color: destructive ? Colors.red.shade800 : widget.accent,
      ),
    );
  }

  IconData _cameraIconForTransition(String? icon) {
    switch (icon) {
      case 'event_available':
        return Icons.event_available_outlined;
      case 'edit':
        return Icons.edit_outlined;
      case 'upload':
        return Icons.cloud_upload_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'queue':
        return Icons.people_alt_outlined;
      case 'undo':
        return Icons.undo_outlined;
      case 'handshake':
        return Icons.handshake_outlined;
      case 'assignment_return':
        return Icons.assignment_return_outlined;
      case 'redeem':
        return Icons.redeem_outlined;
      case 'verified':
        return Icons.verified_outlined;
    }
    return Icons.photo_camera_outlined;
  }

  IconData _cameraFactIcon(String iconName) {
    switch (iconName) {
      case 'schedule':
        return Icons.schedule_outlined;
      case 'location_on':
        return Icons.location_on_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'photo':
        return Icons.photo_outlined;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'person':
        return Icons.person_outline;
      case 'verified':
        return Icons.verified_outlined;
      case 'route':
        return Icons.route_outlined;
    }
    return Icons.label_outline;
  }

  String _cameraFieldLabel(String field) {
    switch (field) {
      case 'photoTitle':
        return 'Photo title';
      case 'critiquePrompt':
        return 'Critique prompt';
      case 'consentNote':
        return 'Consent note';
      case 'itemTitle':
        return 'Gear title';
      case 'condition':
        return 'Condition';
      case 'pickupWindow':
        return 'Pickup window';
    }
    return field;
  }

  BoxDecoration get _cameraBoxDecoration => BoxDecoration(
        color: widget.modernTheme?.resolvedFill ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.modernTheme?.resolvedBorder ??
              widget.accent.withValues(alpha: 0.2),
        ),
      );
}

class _CameraClubEngineStore {
  _CameraClubEngineStore({required this.communityId});

  final String communityId;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: communityId,
  );
  _CameraFixtureBundle? _fixture;
  Future<void>? _readyFuture;
  var _ready = false;

  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _readyFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _fixture ??= await _CameraFixtureBundle.load();
    for (final machine in _fixture!.machines.values) {
      _engine.registerDefinition(machine);
    }
    for (final instance in _fixture!.instances) {
      await _engine.createInstance(
        workflowType: instance.workflowType,
        initialInstanceData: instance.instanceData,
        personaId: instance.createdByPersonaId,
      );
    }
    _ready = true;
  }

  Future<List<WorkflowInstance>> instancesFor({
    required String tabId,
    required String personaId,
  }) async {
    await ensureReady();
    final rows = await _database.queryInstancesKeyset(
      communityId: communityId,
      limit: 100,
      sortKey: 'title',
    );
    final allowed = switch (tabId) {
      'calendar' => const {'photo-walk-rsvp'},
      'critique' => const {'critique-submission'},
      'marketplace' => const {'gear-loan-request'},
      'messages' => const {'critique-submission'},
      'admin' => const {'camera-validation-report'},
      'home' => const {
          'photo-walk-rsvp',
          'critique-submission',
          'gear-loan-request',
          'camera-validation-report',
        },
      _ => const <String>{},
    };
    return rows
        .map((row) {
          final data = jsonDecode(row.instanceData) as Map<String, dynamic>;
          return WorkflowInstance(
            instanceId: row.instanceId,
            workflowType: row.workflowType,
            currentState: row.currentState,
            instanceData: data,
            createdByPersonaId: row.createdByPersonaId,
          );
        })
        .where((instance) => allowed.contains(instance.workflowType))
        .toList(growable: false);
  }

  List<LoomWorkflowTransition> availableTransitions({
    required WorkflowInstance instance,
    required String personaId,
  }) {
    return _engine.availableTransitions(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      currentState: instance.currentState,
      instanceData: instance.instanceData,
      personaId: personaId,
    );
  }

  Future<void> apply({
    required WorkflowInstance instance,
    required String transitionId,
    required String personaId,
  }) async {
    await _engine.applyTransition(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      transitionId: transitionId,
      personaId: personaId,
    );
  }

  Future<void> updateFields({
    required WorkflowInstance instance,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) async {
    await _engine.updateInstanceFields(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      fieldUpdates: fieldUpdates,
      personaId: personaId,
    );
  }

  LoomWorkflowStateMachine machineFor(String workflowType) {
    return _fixture!.machines[workflowType]!;
  }

  List<String> editableFieldsFor({
    required String workflowType,
    required String state,
  }) {
    return machineFor(workflowType).states[state]?.editableFields ?? const [];
  }
}

class _CameraFixtureBundle {
  _CameraFixtureBundle({required this.machines, required this.instances});

  final Map<String, LoomWorkflowStateMachine> machines;
  final List<_GardenSeedInstance> instances;

  static Future<_CameraFixtureBundle> load() async {
    final json = jsonDecode(_stripGardenJsoncComments(_cameraBundledFixtureJsonc))
        as Map<String, dynamic>;
    final definitions =
        json['workflowDefinitions'] as Map<String, dynamic>? ?? const {};
    final machines = <String, LoomWorkflowStateMachine>{};
    for (final entry in definitions.entries) {
      machines[entry.key] = LoomWorkflowStateMachine.fromJson(
        _normalizeGardenMachineJson(entry.value as Map<String, dynamic>),
        entry.key,
      );
    }
    final rawInstances = json['workflowInstances'] as List<dynamic>? ?? const [];
    final instances = [
      for (final item in rawInstances)
        _GardenSeedInstance.fromJson(item as Map<String, dynamic>),
    ];
    return _CameraFixtureBundle(machines: machines, instances: instances);
  }
}

const _cameraBundledFixtureJsonc = r'''
{
  "personas": ["camera-member", "camera-organizer"],
  "templates": {
    "dashboard": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "calendarAgenda": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "formEntry": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow", "WorkflowFormFieldList"] },
    "stateMachineGrid": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "discussionThread": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "statusTimeline": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] }
  },
  "workflowDefinitions": {
    "photo-walk-rsvp": {
      "initialState": "open",
      "states": {
        "open": { "label": "Open" },
        "going": { "label": "Going" },
        "maybe": { "label": "Maybe" },
        "not-going": { "label": "Not going" }
      },
      "transitions": [
        { "id": "rsvp-going", "label": "RSVP going", "icon": "event_available", "tone": "primary", "from": ["open", "maybe", "not-going"], "to": "going", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "rsvpStatus", "value": "Going" }, { "op": "append", "key": "walkHistory", "value": "{routeName} RSVP changed to Going at $timestamp" }] },
        { "id": "rsvp-maybe", "label": "RSVP maybe", "icon": "edit", "tone": "secondary", "from": ["open", "going", "not-going"], "to": "maybe", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "rsvpStatus", "value": "Maybe" }, { "op": "append", "key": "walkHistory", "value": "{routeName} RSVP changed to Maybe at $timestamp" }] },
        { "id": "rsvp-not-going", "label": "RSVP not going", "icon": "undo", "tone": "destructive", "from": ["open", "going", "maybe"], "to": "not-going", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "rsvpStatus", "value": "Not going" }, { "op": "append", "key": "walkHistory", "value": "{routeName} RSVP changed to Not going at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["open", "going", "maybe", "not-going"], "role": "any", "tabId": "calendar", "cardSurfaceFamily": "calendarAgenda", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "routeName": { "type": "text", "required": true, "displayContexts": ["tile", "detail"], "displayIcon": "route", "labelTemplate": "{value}" },
        "eventDateTime": { "type": "text", "required": true, "displayIcon": "schedule", "labelTemplate": "{value}" },
        "location": { "type": "text", "required": true, "displayIcon": "location_on", "labelTemplate": "{value}" },
        "capacityLabel": { "type": "text", "displayIcon": "groups", "labelTemplate": "{value}" },
        "rsvpStatus": { "type": "text", "writableBy": "effect" },
        "walkHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "critique-submission": {
      "initialState": "draft",
      "states": {
        "draft": { "label": "Draft", "editableFields": ["photoTitle", "critiquePrompt", "consentNote"] },
        "submitted": { "label": "Submitted" },
        "reviewed": { "label": "Reviewed" },
        "withdrawn": { "label": "Withdrawn", "isTerminal": true }
      },
      "transitions": [
        { "id": "submit-critique", "label": "Submit critique", "icon": "upload", "tone": "primary", "from": ["draft"], "to": "submitted", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "append", "key": "critiqueHistory", "value": "{photoTitle} submitted at $timestamp" }] },
        { "id": "edit-critique", "label": "Edit critique", "icon": "edit", "tone": "secondary", "from": ["submitted"], "to": "draft", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "append", "key": "critiqueHistory", "value": "{photoTitle} reopened for edit at $timestamp" }] },
        { "id": "mark-reviewed", "label": "Mark reviewed", "icon": "verified", "tone": "primary", "from": ["submitted"], "to": "reviewed", "guard": { "allowedPersonaIds": ["camera-organizer"] }, "effects": [{ "op": "append", "key": "critiqueComments", "value": "Organizer review completed at $timestamp" }] },
        { "id": "withdraw-critique", "label": "Withdraw critique", "icon": "delete", "tone": "destructive", "from": ["draft", "submitted", "reviewed"], "to": "withdrawn", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "append", "key": "critiqueHistory", "value": "{photoTitle} withdrawn at $timestamp" }] }
      ],
      "renderBindings": [
        { "states": ["draft"], "role": "actor", "tabId": "critique", "cardSurfaceFamily": "formEntry", "bindingKind": "primary" },
        { "states": ["submitted", "reviewed", "withdrawn"], "role": "any", "tabId": "critique", "cardSurfaceFamily": "stateMachineGrid", "bindingKind": "primary" },
        { "states": ["submitted", "reviewed"], "role": "any", "tabId": "critique", "cardSurfaceFamily": "discussionThread", "bindingKind": "attached" },
        { "states": ["submitted", "reviewed"], "role": "any", "tabId": "messages", "cardSurfaceFamily": "discussionThread", "bindingKind": "primary" }
      ],
      "instanceDataSchema": {
        "photoTitle": { "type": "text", "required": true, "writableBy": "formEntry", "displayContexts": ["tile", "detail"], "displayIcon": "photo", "labelTemplate": "{value}" },
        "thumbnailLabel": { "type": "text", "required": true, "displayIcon": "photo", "labelTemplate": "{value}" },
        "critiquePrompt": { "type": "text", "required": true, "writableBy": "formEntry" },
        "consentNote": { "type": "text", "required": true, "writableBy": "formEntry" },
        "critiqueComments": { "type": "list", "writableBy": "effect" },
        "critiqueHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "gear-loan-request": {
      "initialState": "available",
      "states": {
        "available": { "label": "Available", "editableFields": ["itemTitle", "condition", "pickupWindow"] },
        "loaned": { "label": "Loaned" },
        "queued": { "label": "Queued" },
        "returned": { "label": "Returned", "isTerminal": true },
        "giveaway": { "label": "Giveaway" },
        "claimed": { "label": "Claimed", "isTerminal": true },
        "paused": { "label": "Paused" },
        "delisted": { "label": "Delisted", "isTerminal": true }
      },
      "transitions": [
        { "id": "request-loan", "label": "Request loan", "icon": "handshake", "tone": "primary", "from": ["available"], "to": "loaned", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "{actorLabel}" }, { "op": "append", "key": "custodyHistory", "value": "{actorLabel} borrowed {itemTitle} at $timestamp" }] },
        { "id": "offer-giveaway", "label": "Offer as giveaway", "icon": "redeem", "tone": "secondary", "from": ["available"], "to": "giveaway", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "mode", "value": "Giveaway" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} offered as giveaway at $timestamp" }] },
        { "id": "join-queue", "label": "Join queue", "icon": "queue", "tone": "secondary", "from": ["loaned"], "to": "queued", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "append", "key": "queuePersonaIds", "value": "{actor}" }] },
        { "id": "leave-queue", "label": "Leave queue", "icon": "undo", "tone": "secondary", "from": ["queued"], "to": "loaned", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "removeValue", "key": "queuePersonaIds", "value": "{actor}" }] },
        { "id": "return-gear", "label": "Return gear", "icon": "assignment_return", "tone": "primary", "from": ["loaned", "queued"], "to": "returned", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} returned at $timestamp" }] },
        { "id": "pause-listing", "label": "Pause listing", "icon": "undo", "tone": "secondary", "from": ["available"], "to": "paused", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "append", "key": "custodyHistory", "value": "{itemTitle} paused at $timestamp" }] },
        { "id": "delist-gear", "label": "Delist gear", "icon": "delete", "tone": "destructive", "from": ["available", "paused"], "to": "delisted", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "append", "key": "custodyHistory", "value": "{itemTitle} delisted at $timestamp" }] },
        { "id": "claim-giveaway", "label": "Claim giveaway", "icon": "redeem", "tone": "primary", "from": ["giveaway"], "to": "claimed", "guard": { "allowedPersonaIds": ["camera-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "{actorLabel}" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} ownership transferred at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["available", "loaned", "queued", "returned", "giveaway", "claimed", "paused", "delisted"], "role": "any", "tabId": "marketplace", "cardSurfaceFamily": "stateMachineGrid", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "itemTitle": { "type": "text", "required": true, "writableBy": "formEntry", "displayContexts": ["tile", "detail"], "displayIcon": "inventory_2", "labelTemplate": "{value}" },
        "mode": { "type": "text", "required": true, "displayIcon": "inventory_2", "labelTemplate": "{value}" },
        "condition": { "type": "text", "required": true, "writableBy": "formEntry", "displayIcon": "verified", "labelTemplate": "{value}" },
        "pickupWindow": { "type": "text", "writableBy": "formEntry", "displayIcon": "schedule", "labelTemplate": "{value}" },
        "currentHolder": { "type": "text", "writableBy": "effect", "displayIcon": "person", "labelTemplate": "Holder: {value}", "hideWhenEmpty": true },
        "queuePersonaIds": { "type": "list", "writableBy": "effect" },
        "custodyHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "camera-validation-report": {
      "initialState": "pending",
      "states": {
        "pending": { "label": "Pending" },
        "validated": { "label": "Validated", "isTerminal": true }
      },
      "transitions": [
        { "id": "mark-validated", "label": "Mark validated", "icon": "verified", "tone": "primary", "from": ["pending"], "to": "validated", "guard": { "allowedPersonaIds": ["camera-organizer"] }, "effects": [{ "op": "set", "key": "passState", "value": "Validated" }, { "op": "append", "key": "validationHistory", "value": "Camera Club validation marked complete at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["pending", "validated"], "role": "actor", "tabId": "admin", "cardSurfaceFamily": "statusTimeline", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "requestedWorkflows": { "type": "list", "required": true, "displayIcon": "groups", "labelTemplate": "{value.length} requested workflows" },
        "implementedWorkflows": { "type": "list", "required": true, "displayIcon": "verified", "labelTemplate": "{value.length} implemented workflows" },
        "packagePaths": { "type": "list", "required": true },
        "passState": { "type": "text", "required": true, "displayIcon": "verified", "labelTemplate": "{value}" },
        "validationHistory": { "type": "list", "writableBy": "effect" }
      }
    }
  },
  "workflowInstances": [
    { "instanceId": "camera-walk-warehouse", "workflowType": "photo-walk-rsvp", "currentState": "open", "createdByPersonaId": "camera-organizer", "instanceData": { "routeName": "Warehouse District golden-hour walk", "eventDateTime": "Friday, May 8 at 6:30 PM", "location": "Pier 3 mural route", "capacityLabel": "12 of 16 spots", "rsvpStatus": "", "walkHistory": [] } },
    { "instanceId": "camera-critique-rain", "workflowType": "critique-submission", "currentState": "draft", "createdByPersonaId": "camera-member", "instanceData": { "photoTitle": "Rain reflections", "thumbnailLabel": "Street reflection thumbnail", "critiquePrompt": "Help me choose the strongest crop.", "consentNote": "Model consent captured for club critique.", "critiqueComments": ["Reviewer queue: composition and crop"], "critiqueHistory": [] } },
    { "instanceId": "camera-gear-lens", "workflowType": "gear-loan-request", "currentState": "available", "createdByPersonaId": "camera-member", "instanceData": { "itemTitle": "35mm prime lens", "mode": "Loan", "condition": "Excellent", "pickupWindow": "Thu 5-7 PM", "currentHolder": "", "queuePersonaIds": [], "custodyHistory": [] } },
    { "instanceId": "camera-gear-tripod", "workflowType": "gear-loan-request", "currentState": "giveaway", "createdByPersonaId": "camera-member", "instanceData": { "itemTitle": "Travel tripod", "mode": "Giveaway", "condition": "Good", "pickupWindow": "Sat morning", "currentHolder": "", "queuePersonaIds": [], "custodyHistory": [] } },
    { "instanceId": "camera-validation", "workflowType": "camera-validation-report", "currentState": "pending", "createdByPersonaId": "camera-organizer", "instanceData": { "requestedWorkflows": ["photo-walk RSVP", "critique composition", "gear loan/giveaway"], "implementedWorkflows": ["Calendar", "Critique", "Gear", "Messages", "Admin", "Home"], "packagePaths": ["ext_camera_club", "Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc"], "passState": "Pending validation", "validationHistory": [] } }
  ]
}
''';


class _ChessClubEngineTabSurface extends StatefulWidget {
  const _ChessClubEngineTabSurface({required this.experience, required this.persona, required this.tabId, required this.accent, this.modernTheme});
  final LoomExperienceDefinition experience; final LoomPersonaDefinition persona; final String tabId; final Color accent; final LoomCardTheme? modernTheme;
  @override State<_ChessClubEngineTabSurface> createState()=>_ChessClubEngineTabSurfaceState();
}

class _ChessClubEngineTabSurfaceState extends State<_ChessClubEngineTabSurface> {
  static final _stores=<String,_ChessClubEngineStore>{}; late final _ChessClubEngineStore _store;
  List<WorkflowInstance> _instances=const []; final _controllers=<String,TextEditingController>{}; String? _error; var _loaded=false;
  @override void initState(){super.initState(); _store=_stores.putIfAbsent(widget.experience.extensionId,()=>_ChessClubEngineStore(communityId: widget.experience.extensionId)); unawaited(_load());}
  @override void didUpdateWidget(_ChessClubEngineTabSurface old){super.didUpdateWidget(old); if(old.persona.personaId!=widget.persona.personaId||old.tabId!=widget.tabId) unawaited(_load());}
  @override void dispose(){for(final c in _controllers.values){c.dispose();} super.dispose();}
  Future<void> _load() async {try{await _store.ensureReady(); final rows=await _store.instancesFor(tabId: widget.tabId, personaId: widget.persona.personaId); _sync(rows); if(!mounted)return; setState((){_instances=rows; _error=null; _loaded=true;});}catch(e){if(!mounted)return; setState((){_error='$e'; _loaded=true;});}}
  Future<void> _transition(WorkflowInstance i,String t) async {await _store.apply(instance:i,transitionId:t,personaId:widget.persona.personaId); await _load();}
  Future<void> _save(WorkflowInstance i) async {final fields=_store.editableFieldsFor(workflowType:i.workflowType,state:i.currentState).where((f)=>f!='rankingRows'&&f!='lastUpdated'); await _store.updateFields(instance:i, fieldUpdates:{for(final f in fields) f: f=='board' ? (int.tryParse(_controller(i.instanceId,f).text)??_controller(i.instanceId,f).text) : _controller(i.instanceId,f).text}, personaId:widget.persona.personaId); await _load();}
  @override Widget build(BuildContext context){if(!_loaded)return const Center(child:CircularProgressIndicator()); if(_error!=null)return Text(_error!,key:ValueKey('chess-load-error-${widget.tabId}')); if(widget.tabId=='home')return _home(context); return Column(key:ValueKey('chess-engine-${widget.tabId}'),crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    if(widget.tabId=='matches')...[_card(context,_first('chess-match-meetup'),'Board 1 ladder match','Form entry to timeline to confirmed calendar event',Icons.sports_esports_outlined),const SizedBox(height:12),_card(context,_first('chess-match-result'),'Board 1 result','Result timeline with correction and dispute path',Icons.scoreboard_outlined)],
    if(widget.tabId=='calendar')...[_card(context,_first('chess-match-meetup'),'Confirmed match calendar','The match meetup instance becomes a calendarAgenda card once confirmed',Icons.event_available_outlined),const SizedBox(height:12),_card(context,_first('chess-club-night'),'Thursday Ladder Night','Club night, tournament pairing, and reminder',Icons.calendar_month_outlined)],
    if(widget.tabId=='rankings') _card(context,_first('chess-rankings-table'),'Live ladder rankings','Table archetype with rankingMode rows updated by result effects',Icons.leaderboard_outlined,extra:_rankings(_first('chess-rankings-table'))),
    if(widget.tabId=='admin')...[_card(context,_first('chess-pairing-queue'),'Pairing queue','Organizer dashboard for outstanding pairings',Icons.groups_outlined),const SizedBox(height:12),_card(context,_first('chess-match-result'),'Result disputes','Organizer status timeline for disputed results',Icons.report_problem_outlined),const SizedBox(height:12),_card(context,_first('chess-export-package'),'Chess records export','Export wizard for matches, rankings, and documents',Icons.ios_share_outlined)],
    if(widget.tabId=='documents') _card(context,_first('chess-rules-documents'),'Club rules and ladder policy','Document library with embedded, external, and download actions',Icons.description_outlined),
    if(widget.tabId=='messages') _card(context,_first('chess-discussion-thread'),'Thursday pairings thread','Discussion thread for club-night coordination',Icons.forum_outlined),
  ]);}
  Widget _home(BuildContext context){final m=_first('chess-match-meetup'), q=_first('chess-pairing-queue'), r=_first('chess-rankings-table'); return Column(key:const ValueKey('chess-engine-home'),crossAxisAlignment:CrossAxisAlignment.stretch,children:[_pin(context,const ValueKey('chess-home-next-match'),'Next match',Icons.event_available_outlined,'${m?.instanceData['opponent']??'Opponent'} on ${m?.instanceData['matchTime']??'time pending'}'),const SizedBox(height:12),_pin(context,const ValueKey('chess-home-pairing'),'Open challenge',Icons.groups_outlined,'${q?.instanceData['queueTitle']??'Queue'} - ${q?.instanceData['waitingPlayers'] is List ? (q!.instanceData['waitingPlayers'] as List).length : 0} waiting'),const SizedBox(height:12),_pin(context,const ValueKey('chess-home-standings'),'Standings snippet',Icons.leaderboard_outlined,_top(r))]);}
  Widget _pin(BuildContext c,Key k,String title,IconData icon,String body)=>DecoratedBox(key:k,decoration:_box,child:Padding(padding:const EdgeInsets.all(16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:widget.accent),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(body)]))])));
  Widget _card(BuildContext c,WorkflowInstance? i,String title,String sub,IconData icon,{Widget? extra}){if(i==null)return _TabEmptyState(icon:icon,title:'$title unavailable',body:'No engine instance is available for this Chess Club surface.',accent:widget.accent,modernTheme:widget.modernTheme); final machine=_store.machineFor(i.workflowType); final transitions=_store.availableTransitions(instance:i,personaId:widget.persona.personaId); return DecoratedBox(key:ValueKey('chess-card-${i.workflowType}-${i.instanceId}'),decoration:_box,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Icon(icon,color:widget.accent),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),Text(sub)]))]),const SizedBox(height:10),Wrap(spacing:8,runSpacing:8,children:[_SurfaceFactPill(icon:Icons.flag_outlined,label:'State: ${machine.states[i.currentState]?.label??i.currentState}',foreground:widget.accent),for(final w in _pills(machine,i.instanceData)) w]),const SizedBox(height:10),for(final f in const ['opponent','matchTime','place','board','whitePlayer','blackPlayer','round','score','resultSummary','eventTitle','eventTime','location','pairing','queueTitle','exportScope','checksum','documentTitle','threadTitle']) if(i.instanceData[f] case final v?) Text('$v'),_edit(i),if(extra!=null)extra,const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[for(final t in transitions) OutlinedButton.icon(key:ValueKey('chess-action-${t.id}'),style:_style(t),onPressed:()=>_transition(i,t.id),icon:Icon(_icon(t.icon)),label:Text(t.label))]),const SizedBox(height:12),for(final entry in _history(i.instanceData).asMap().entries) Text(entry.value,key:ValueKey('chess-history-${i.instanceId}-${entry.key}-${entry.value.hashCode}'))])));}
  Widget _edit(WorkflowInstance i){final fields=_store.editableFieldsFor(workflowType:i.workflowType,state:i.currentState).where((f)=>f!='rankingRows'&&f!='lastUpdated').toList(); if(fields.isEmpty)return const SizedBox.shrink(); return Column(key:ValueKey('chess-edit-form-${i.workflowType}'),crossAxisAlignment:CrossAxisAlignment.stretch,children:[const SizedBox(height:8),for(final f in fields) TextField(key:ValueKey('chess-edit-$f'),controller:_controller(i.instanceId,f),decoration:InputDecoration(labelText:f)),const SizedBox(height:12),FilledButton.icon(key:ValueKey('chess-save-edit-${i.workflowType}'),onPressed:()=>_save(i),icon:const Icon(Icons.save_outlined),label:const Text('Save edits'))]);}
  Widget? _rankings(WorkflowInstance? i){if(i==null)return null; final rows=_rows(i); return Column(key:const ValueKey('chess-rankings-table'),crossAxisAlignment:CrossAxisAlignment.stretch,children:[const SizedBox(height:8),for(final r in rows) Text('${r['rank']}. ${r['player']} - ${r['score']} (${r['delta']})',key:ValueKey('chess-ranking-${r['player']}'))]);}
  List<Widget> _pills(LoomWorkflowStateMachine m,Map<String,dynamic>d)=>[for(final e in m.instanceDataSchema.entries) if(e.value.displayIcon!=null && !(e.value.hideWhenEmpty && (d[e.key]==null || d[e.key] is List && (d[e.key] as List).isEmpty || d[e.key] is String && (d[e.key] as String).isEmpty))) _SurfaceFactPill(icon:_fact(e.value.displayIcon!),label:(e.value.labelTemplate??'{value}').replaceAll('{value.length}',d[e.key] is List?'${(d[e.key] as List).length}':'0').replaceAll('{value}',d[e.key] is List?(d[e.key] as List).join(', '):'${d[e.key]??''}'),foreground:widget.accent)];
  List<String> _history(Map<String,dynamic>d){final out=<String>[]; for(final e in d.entries){if(e.key.toLowerCase().contains('history')||e.key.toLowerCase().contains('messages')){if(e.value is List)out.addAll([for(final x in e.value as List) if(x is String) x]);}} return out;}
  void _sync(List<WorkflowInstance> rows){for(final i in rows){for(final f in _store.editableFieldsFor(workflowType:i.workflowType,state:i.currentState)){if(f!='rankingRows')_controller(i.instanceId,f).text='${i.instanceData[f]??''}';}}}
  TextEditingController _controller(String id,String f)=>_controllers.putIfAbsent('$id::$f',TextEditingController.new);
  WorkflowInstance? _first(String type){for(final i in _instances){if(i.workflowType==type)return i;}return null;}
  List<Map<String,dynamic>> _rows(WorkflowInstance i)=>i.instanceData['rankingRows'] is List ? [for(final r in i.instanceData['rankingRows'] as List) if(r is Map) Map<String,dynamic>.from(r)] : const [];
  String _top(WorkflowInstance? i){if(i==null)return 'Rankings unavailable'; final rows=_rows(i); return rows.isEmpty?'No rankings yet':'${rows.first['player']} leads with ${rows.first['score']}';}
  ButtonStyle _style(LoomWorkflowTransition t){final destructive=t.tone=='destructive'; final primary=t.tone=='primary'; return OutlinedButton.styleFrom(foregroundColor:destructive?Colors.red.shade800:primary?Colors.white:widget.accent,backgroundColor:primary?widget.accent:null,side:BorderSide(color:destructive?Colors.red.shade800:widget.accent));}
  IconData _icon(String? i)=>switch(i){'send'=>Icons.send_outlined,'check'=>Icons.check_circle_outline,'close'=>Icons.close_outlined,'schedule'=>Icons.schedule_outlined,'delete'=>Icons.delete_outline,'event_available'=>Icons.event_available_outlined,'scoreboard'=>Icons.scoreboard_outlined,'edit'=>Icons.edit_outlined,'report'=>Icons.report_problem_outlined,'verified'=>Icons.verified_outlined,'publish'=>Icons.publish_outlined,'notifications'=>Icons.notifications_outlined,'groups'=>Icons.groups_outlined,'download'=>Icons.download_outlined,'undo'=>Icons.undo_outlined,'open_in_browser'=>Icons.open_in_browser_outlined,'open_in_new'=>Icons.open_in_new_outlined,'reply'=>Icons.reply_outlined,_=>Icons.sports_esports_outlined};
  IconData _fact(String i)=>switch(i){'person'=>Icons.person_outline,'schedule'=>Icons.schedule_outlined,'location_on'=>Icons.location_on_outlined,'table_bar'=>Icons.table_bar_outlined,'history'=>Icons.history_outlined,'flag'=>Icons.flag_outlined,'scoreboard'=>Icons.scoreboard_outlined,'leaderboard'=>Icons.leaderboard_outlined,'event'=>Icons.event_outlined,'groups'=>Icons.groups_outlined,'notifications'=>Icons.notifications_outlined,'description'=>Icons.description_outlined,'verified'=>Icons.verified_outlined,'forum'=>Icons.forum_outlined,_=>Icons.label_outline};
  BoxDecoration get _box=>BoxDecoration(color:widget.modernTheme?.resolvedFill??Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:widget.modernTheme?.resolvedBorder??widget.accent.withValues(alpha:0.2)));
}

class _ChessClubEngineStore {
  _ChessClubEngineStore({required this.communityId}); final String communityId; late final WorkflowDatabase _database=WorkflowDatabase.memory(); late final LocalWorkflowEngineApi _engine=LocalWorkflowEngineApi(db:_database,communityId:communityId); _ChessFixtureBundle? _fixture; Future<void>? _readyFuture; var _ready=false;
  Future<void> ensureReady(){if(_ready)return Future.value(); return _readyFuture??=_init();}
  Future<void> _init() async {_fixture??=await _ChessFixtureBundle.load(); for(final m in _fixture!.machines.values){_engine.registerDefinition(m);} for(final i in _fixture!.instances){await _engine.createInstance(workflowType:i.workflowType,initialInstanceData:i.instanceData,personaId:i.createdByPersonaId);} _ready=true;}
  Future<List<WorkflowInstance>> instancesFor({required String tabId,required String personaId}) async {await ensureReady(); final page=await _engine.queryInstances(tabId:tabId,personaId:personaId,limit:100,query:const SurfaceQuery()); final allowed=switch(tabId){'matches'=>const {'chess-match-meetup','chess-match-result'},'calendar'=>const {'chess-match-meetup','chess-club-night'},'rankings'=>const {'chess-rankings-table'},'admin'=>const {'chess-pairing-queue','chess-match-result','chess-export-package'},'documents'=>const {'chess-rules-documents'},'messages'=>const {'chess-discussion-thread'},'home'=>const {'chess-match-meetup','chess-pairing-queue','chess-rankings-table'},_=>const <String>{}}; return page.items.where((i)=>allowed.contains(i.workflowType)).toList(growable:false);}
  List<LoomWorkflowTransition> availableTransitions({required WorkflowInstance instance,required String personaId})=>_engine.availableTransitions(workflowType:instance.workflowType,instanceId:instance.instanceId,currentState:instance.currentState,instanceData:instance.instanceData,personaId:personaId);
  Future<void> apply({required WorkflowInstance instance,required String transitionId,required String personaId}) async {final result=await _engine.applyTransition(workflowType:instance.workflowType,instanceId:instance.instanceId,transitionId:transitionId,personaId:personaId); if(instance.workflowType=='chess-match-result'&&(transitionId=='submit-result'||transitionId=='correct-result')) await _rankingsEffect(matchData:result.newInstanceData,transitionId:transitionId,personaId:personaId);}
  Future<void> _rankingsEffect({required Map<String,dynamic> matchData,required String transitionId,required String personaId}) async {final white='${matchData['whitePlayer']??''}'.trim(); final black='${matchData['blackPlayer']??''}'.trim(); final score='${matchData['score']??''}'.trim(); if(white.isEmpty||black.isEmpty||score.isEmpty)return; final deltas=_rankingDeltas(score, transitionId=='correct-result'?12:16); final page=await _engine.queryInstances(tabId:'rankings',personaId:'chess-organizer',limit:100,query:const SurfaceQuery()); final ranking=page.items.firstWhere((i)=>i.workflowType=='chess-rankings-table'); final rows=[for(final r in ranking.instanceData['rankingRows'] as List) Map<String,dynamic>.from(r as Map)]; void applyDelta(String player,int delta){var row=rows.cast<Map<String,dynamic>?>().firstWhere((r)=>r?['player']==player,orElse:()=>null); if(row==null){row={'rank':rows.length+1,'player':player,'score':1450,'delta':0}; rows.add(row);} final current=row['score'] is int ? row['score'] as int : int.tryParse('${row['score']}')??1450; row['score']=current+delta; row['delta']=delta>0?'+$delta':'$delta';} applyDelta(white,deltas.$1); applyDelta(black,deltas.$2); rows.sort((a,b)=>(b['score'] as int).compareTo(a['score'] as int)); for(var i=0;i<rows.length;i++){rows[i]['rank']=i+1;} await _engine.updateInstanceFields(workflowType:ranking.workflowType,instanceId:ranking.instanceId,fieldUpdates:{'rankingRows':rows,'lastUpdated':'Updated from ${transitionId=='correct-result'?'corrected':'submitted'} result: $white vs $black $score'},personaId:personaId);}
  (int,int) _rankingDeltas(String score,int magnitude){final normalized=score.replaceAll(' ', '').toLowerCase(); if(normalized=='1-0')return (magnitude,-magnitude); if(normalized=='0-1')return (-magnitude,magnitude); if(normalized=='1/2-1/2'||normalized=='0.5-0.5'||normalized=='draw')return (0,0); return (0,0);}
  Future<void> updateFields({required WorkflowInstance instance,required Map<String,dynamic> fieldUpdates,required String personaId})=>_engine.updateInstanceFields(workflowType:instance.workflowType,instanceId:instance.instanceId,fieldUpdates:fieldUpdates,personaId:personaId);
  LoomWorkflowStateMachine machineFor(String workflowType)=>_fixture!.machines[workflowType]!;
  List<String> editableFieldsFor({required String workflowType,required String state})=>machineFor(workflowType).states[state]?.editableFields??const [];
}

class _ChessFixtureBundle { _ChessFixtureBundle({required this.machines,required this.instances}); final Map<String,LoomWorkflowStateMachine> machines; final List<_GardenSeedInstance> instances; static Future<_ChessFixtureBundle> load() async {final json=jsonDecode(_stripGardenJsoncComments(_chessBundledFixtureJsonc)) as Map<String,dynamic>; final defs=json['workflowDefinitions'] as Map<String,dynamic>; final machines=<String,LoomWorkflowStateMachine>{}; for(final e in defs.entries){machines[e.key]=LoomWorkflowStateMachine.fromJson(_normalizeGardenMachineJson(e.value as Map<String,dynamic>),e.key);} final instances=[for(final item in (json['workflowInstances'] as List<dynamic>)) _GardenSeedInstance.fromJson(item as Map<String,dynamic>)]; return _ChessFixtureBundle(machines:machines,instances:instances);} }

const _chessBundledFixtureJsonc = r'''
{
  "personas": [
    "chess-player",
    "chess-organizer"
  ],
  "templates": {
    "dashboard": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "formEntry": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow",
        "WorkflowFormFieldList"
      ]
    },
    "statusTimeline": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "calendarAgenda": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "table": {
      "rankingMode": true,
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ],
      "columns": [
        {
          "key": "rank",
          "sortable": true
        },
        {
          "key": "player",
          "sortable": true
        },
        {
          "key": "score",
          "sortable": true
        },
        {
          "key": "delta",
          "sortable": true
        }
      ]
    },
    "exportWizard": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "documentLibrary": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "discussionThread": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    }
  },
  "workflowDefinitions": {
    "chess-match-meetup": {
      "initialState": "draft",
      "states": {
        "draft": {
          "label": "Draft",
          "editableFields": [
            "opponent",
            "matchTime",
            "place",
            "board"
          ]
        },
        "proposed": {
          "label": "Proposed"
        },
        "rescheduled": {
          "label": "Rescheduled"
        },
        "accepted": {
          "label": "Accepted"
        },
        "confirmed": {
          "label": "Confirmed",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "propose-match",
          "label": "Propose match",
          "icon": "send",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "proposed",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "matchHistory",
              "value": "Match proposed with {opponent}"
            }
          ]
        },
        {
          "id": "decline-match",
          "label": "Decline",
          "icon": "close",
          "tone": "secondary",
          "from": [
            "proposed",
            "rescheduled"
          ],
          "to": "proposed",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "matchHistory",
              "value": "Decline recorded; challenge remains open"
            }
          ]
        },
        {
          "id": "suggest-new-time",
          "label": "Suggest new time",
          "icon": "schedule",
          "tone": "secondary",
          "from": [
            "proposed",
            "accepted"
          ],
          "to": "rescheduled",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "matchTime",
              "value": "Friday 7:30 PM"
            },
            {
              "op": "append",
              "key": "matchHistory",
              "value": "New time suggested for Friday 7:30 PM"
            }
          ]
        },
        {
          "id": "cancel-match",
          "label": "Cancel",
          "icon": "delete",
          "tone": "destructive",
          "from": [
            "proposed",
            "rescheduled",
            "accepted"
          ],
          "to": "proposed",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "matchHistory",
              "value": "Cancellation noted; organizer can rematch if needed"
            }
          ]
        },
        {
          "id": "accept-match",
          "label": "Accept",
          "icon": "check",
          "tone": "primary",
          "from": [
            "proposed",
            "rescheduled"
          ],
          "to": "accepted",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "matchHistory",
              "value": "Invite accepted"
            }
          ]
        },
        {
          "id": "confirm-match",
          "label": "Confirm calendar event",
          "icon": "event_available",
          "tone": "primary",
          "from": [
            "accepted"
          ],
          "to": "confirmed",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "matchHistory",
              "value": "Confirmed on calendar"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft"
          ],
          "role": "actor",
          "tabId": "matches",
          "cardSurfaceFamily": "formEntry",
          "bindingKind": "primary"
        },
        {
          "states": [
            "proposed",
            "rescheduled",
            "accepted"
          ],
          "role": "any",
          "tabId": "matches",
          "cardSurfaceFamily": "statusTimeline",
          "bindingKind": "primary"
        },
        {
          "states": [
            "confirmed"
          ],
          "role": "any",
          "tabId": "matches",
          "cardSurfaceFamily": "calendarAgenda",
          "bindingKind": "primary"
        },
        {
          "states": [
            "confirmed"
          ],
          "role": "any",
          "tabId": "calendar",
          "cardSurfaceFamily": "calendarAgenda",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "opponent": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Opponent: {value}"
        },
        "matchTime": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "schedule",
          "labelTemplate": "{value}"
        },
        "place": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "location_on",
          "labelTemplate": "{value}"
        },
        "board": {
          "type": "number",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "table_bar",
          "labelTemplate": "Board {value}"
        },
        "matchHistory": {
          "type": "list",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "history",
          "labelTemplate": "Updates: {value.length}"
        }
      }
    },
    "chess-match-result": {
      "initialState": "draft",
      "states": {
        "draft": {
          "label": "Draft",
          "editableFields": [
            "whitePlayer",
            "blackPlayer",
            "round",
            "score",
            "resultSummary"
          ]
        },
        "submitted": {
          "label": "Submitted"
        },
        "corrected": {
          "label": "Corrected"
        },
        "disputed": {
          "label": "Disputed"
        },
        "resolved": {
          "label": "Resolved",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "submit-result",
          "label": "Submit result",
          "icon": "scoreboard",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "submitted",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "rankingRows",
              "value": "Maya Patel:1496:+16"
            },
            {
              "op": "append",
              "key": "resultHistory",
              "value": "Result submitted: {score}"
            }
          ]
        },
        {
          "id": "correct-result",
          "label": "Correct result",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "submitted"
          ],
          "to": "corrected",
          "guard": {
            "allowedPersonaIds": [
              "chess-player"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "rankingRows",
              "value": "Maya Patel:1492:+12"
            },
            {
              "op": "append",
              "key": "resultHistory",
              "value": "Correction saved"
            }
          ]
        },
        {
          "id": "dispute-result",
          "label": "Dispute result",
          "icon": "report",
          "tone": "destructive",
          "from": [
            "submitted",
            "corrected"
          ],
          "to": "disputed",
          "guard": {
            "allowedPersonaIds": [
              "chess-player",
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "resultHistory",
              "value": "Dispute opened for organizer review"
            }
          ]
        },
        {
          "id": "resolve-dispute",
          "label": "Resolve dispute",
          "icon": "verified",
          "tone": "primary",
          "from": [
            "disputed"
          ],
          "to": "resolved",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "resultHistory",
              "value": "Dispute resolved by organizer"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft",
            "submitted",
            "corrected",
            "disputed",
            "resolved"
          ],
          "role": "any",
          "tabId": "matches",
          "cardSurfaceFamily": "statusTimeline",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "whitePlayer": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "White: {value}"
        },
        "blackPlayer": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Black: {value}"
        },
        "round": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "flag",
          "labelTemplate": "{value}"
        },
        "score": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "scoreboard",
          "labelTemplate": "Score: {value}"
        },
        "resultSummary": {
          "type": "text",
          "writableBy": "formEntry"
        },
        "rankingRows": {
          "type": "text",
          "writableBy": "effect"
        },
        "resultHistory": {
          "type": "list",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "history",
          "labelTemplate": "Result updates: {value.length}"
        }
      }
    },
    "chess-rankings-table": {
      "initialState": "current",
      "states": {
        "current": {
          "label": "Current",
          "editableFields": [
            "rankingRows",
            "lastUpdated"
          ]
        }
      },
      "transitions": [
        {
          "id": "publish-rankings",
          "label": "Publish rankings",
          "icon": "publish",
          "tone": "secondary",
          "from": [
            "current"
          ],
          "to": "current",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "lastUpdated",
              "value": "Published"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "current"
          ],
          "role": "any",
          "tabId": "rankings",
          "cardSurfaceFamily": "table",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "rankingRows": {
          "type": "list",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "leaderboard",
          "labelTemplate": "Rows: {value.length}",
          "sortable": true
        },
        "lastUpdated": {
          "type": "text",
          "writableBy": "formEntry",
          "displayIcon": "schedule",
          "labelTemplate": "Updated: {value}",
          "sortable": true
        },
        "rank": {
          "type": "number",
          "writableBy": "formEntry",
          "sortable": true
        },
        "player": {
          "type": "text",
          "writableBy": "formEntry",
          "sortable": true
        },
        "score": {
          "type": "number",
          "writableBy": "formEntry",
          "sortable": true
        },
        "delta": {
          "type": "text",
          "writableBy": "formEntry",
          "sortable": true
        }
      }
    },
    "chess-club-night": {
      "initialState": "scheduled",
      "states": {
        "scheduled": {
          "label": "Scheduled"
        },
        "reminded": {
          "label": "Reminder sent",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "send-reminder",
          "label": "Send reminder",
          "icon": "notifications",
          "tone": "secondary",
          "from": [
            "scheduled"
          ],
          "to": "reminded",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "reminderStatus",
              "value": "Reminder sent"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "scheduled",
            "reminded"
          ],
          "role": "any",
          "tabId": "calendar",
          "cardSurfaceFamily": "calendarAgenda",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "eventTitle": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "event",
          "labelTemplate": "{value}"
        },
        "eventTime": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "schedule",
          "labelTemplate": "{value}"
        },
        "location": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "location_on",
          "labelTemplate": "{value}"
        },
        "pairing": {
          "type": "text",
          "writableBy": "formEntry",
          "displayIcon": "groups",
          "labelTemplate": "Pairing: {value}"
        },
        "reminderStatus": {
          "type": "text",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "notifications",
          "labelTemplate": "{value}"
        }
      }
    },
    "chess-pairing-queue": {
      "initialState": "open",
      "states": {
        "open": {
          "label": "Open"
        },
        "assigned": {
          "label": "Assigned",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "assign-pairing",
          "label": "Assign pairing",
          "icon": "groups",
          "tone": "primary",
          "from": [
            "open"
          ],
          "to": "assigned",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "pairingHistory",
              "value": "Pairing assigned by organizer"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "open",
            "assigned"
          ],
          "role": "actor",
          "tabId": "admin",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "queueTitle": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "groups",
          "labelTemplate": "{value}"
        },
        "waitingPlayers": {
          "type": "list",
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Waiting: {value.length}"
        },
        "pairingHistory": {
          "type": "list",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "history",
          "labelTemplate": "Assignments: {value.length}"
        }
      }
    },
    "chess-export-package": {
      "initialState": "ready",
      "states": {
        "ready": {
          "label": "Ready"
        },
        "generated": {
          "label": "Generated"
        },
        "rolledBack": {
          "label": "Rolled back",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "generate-export",
          "label": "Generate export",
          "icon": "download",
          "tone": "primary",
          "from": [
            "ready"
          ],
          "to": "generated",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "checksum",
              "value": "sha256-chess-2026"
            }
          ]
        },
        {
          "id": "rollback-export",
          "label": "Rollback export",
          "icon": "undo",
          "tone": "destructive",
          "from": [
            "generated"
          ],
          "to": "rolledBack",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "exportStatus",
              "value": "Rolled back"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "ready",
            "generated",
            "rolledBack"
          ],
          "role": "actor",
          "tabId": "admin",
          "cardSurfaceFamily": "exportWizard",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "exportScope": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "checksum": {
          "type": "text",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "verified",
          "labelTemplate": "{value}"
        },
        "exportStatus": {
          "type": "text",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "history",
          "labelTemplate": "{value}"
        }
      }
    },
    "chess-rules-documents": {
      "initialState": "available",
      "states": {
        "available": {
          "label": "Available"
        },
        "embeddedOpened": {
          "label": "Embedded opened"
        },
        "externalOpened": {
          "label": "External opened"
        },
        "downloaded": {
          "label": "Downloaded",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "open-embedded",
          "label": "Open in app",
          "icon": "open_in_browser",
          "tone": "primary",
          "from": [
            "available",
            "externalOpened"
          ],
          "to": "embeddedOpened",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "documentHistory",
              "value": "Rules opened in app"
            }
          ]
        },
        {
          "id": "open-external",
          "label": "Open external",
          "icon": "open_in_new",
          "tone": "secondary",
          "from": [
            "available",
            "embeddedOpened"
          ],
          "to": "externalOpened",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "documentHistory",
              "value": "Rules opened externally"
            }
          ]
        },
        {
          "id": "download-document",
          "label": "Download",
          "icon": "download",
          "tone": "primary",
          "from": [
            "available",
            "embeddedOpened",
            "externalOpened"
          ],
          "to": "downloaded",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "documentHistory",
              "value": "Rules downloaded"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "available",
            "embeddedOpened",
            "externalOpened",
            "downloaded"
          ],
          "role": "actor",
          "tabId": "documents",
          "cardSurfaceFamily": "documentLibrary",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "documentTitle": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "documentHistory": {
          "type": "list",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "history",
          "labelTemplate": "Opens: {value.length}"
        }
      }
    },
    "chess-discussion-thread": {
      "initialState": "open",
      "states": {
        "open": {
          "label": "Open"
        },
        "replied": {
          "label": "Replied"
        },
        "archived": {
          "label": "Archived",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "reply-thread",
          "label": "Reply",
          "icon": "reply",
          "tone": "primary",
          "from": [
            "open"
          ],
          "to": "replied",
          "guard": {
            "allowedPersonaIds": [
              "chess-player",
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "threadMessages",
              "value": "See you at club night"
            }
          ]
        },
        {
          "id": "archive-thread",
          "label": "Archive",
          "icon": "delete",
          "tone": "secondary",
          "from": [
            "replied"
          ],
          "to": "archived",
          "guard": {
            "allowedPersonaIds": [
              "chess-organizer"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "threadMessages",
              "value": "Thread archived"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "open",
            "replied",
            "archived"
          ],
          "role": "any",
          "tabId": "messages",
          "cardSurfaceFamily": "discussionThread",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "threadTitle": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "forum",
          "labelTemplate": "{value}"
        },
        "threadMessages": {
          "type": "list",
          "writableBy": "effect",
          "hideWhenEmpty": true,
          "displayIcon": "forum",
          "labelTemplate": "Messages: {value.length}"
        }
      }
    }
  },
  "workflowInstances": [
    {
      "workflowType": "chess-match-meetup",
      "createdByPersonaId": "chess-player",
      "instanceData": {
        "opponent": "Noah Kim",
        "matchTime": "Thursday 6:30 PM",
        "place": "Library Room B",
        "board": 1,
        "matchHistory": []
      },
      "instanceId": "chess-01-chess-match-meetup",
      "currentState": "draft"
    },
    {
      "workflowType": "chess-match-result",
      "createdByPersonaId": "chess-player",
      "instanceData": {
        "whitePlayer": "Maya Patel",
        "blackPlayer": "Noah Kim",
        "round": "Ladder Round 4",
        "score": "1-0",
        "resultSummary": "Maya won on Board 1",
        "rankingRows": "",
        "resultHistory": []
      },
      "instanceId": "chess-02-chess-match-result",
      "currentState": "draft"
    },
    {
      "workflowType": "chess-rankings-table",
      "createdByPersonaId": "chess-organizer",
      "instanceData": {
        "instanceKey": "rankings-main",
        "rankingRows": [
          {
            "rank": 1,
            "player": "Noah Kim",
            "score": 1510,
            "delta": 0
          },
          {
            "rank": 2,
            "player": "Maya Patel",
            "score": 1480,
            "delta": 0
          },
          {
            "rank": 3,
            "player": "Ari Stone",
            "score": 1460,
            "delta": 0
          }
        ],
        "lastUpdated": "Seed rankings"
      },
      "instanceId": "chess-03-chess-rankings-table",
      "currentState": "current"
    },
    {
      "workflowType": "chess-club-night",
      "createdByPersonaId": "chess-organizer",
      "instanceData": {
        "eventTitle": "Thursday Ladder Night",
        "eventTime": "Thursday 7:00 PM",
        "location": "Community Center",
        "pairing": "Board 1: Maya vs Noah",
        "reminderStatus": ""
      },
      "instanceId": "chess-04-chess-club-night",
      "currentState": "scheduled"
    },
    {
      "workflowType": "chess-pairing-queue",
      "createdByPersonaId": "chess-organizer",
      "instanceData": {
        "queueTitle": "Open challenge queue",
        "waitingPlayers": [
          "Maya Patel",
          "Ari Stone"
        ],
        "pairingHistory": []
      },
      "instanceId": "chess-05-chess-pairing-queue",
      "currentState": "open"
    },
    {
      "workflowType": "chess-export-package",
      "createdByPersonaId": "chess-organizer",
      "instanceData": {
        "exportScope": "Matches, rankings, documents",
        "checksum": "",
        "exportStatus": "Ready"
      },
      "instanceId": "chess-06-chess-export-package",
      "currentState": "ready"
    },
    {
      "workflowType": "chess-rules-documents",
      "createdByPersonaId": "chess-organizer",
      "instanceData": {
        "documentTitle": "Club rules and ladder policy",
        "documentHistory": []
      },
      "instanceId": "chess-07-chess-rules-documents",
      "currentState": "available"
    },
    {
      "workflowType": "chess-discussion-thread",
      "createdByPersonaId": "chess-player",
      "instanceData": {
        "threadTitle": "Thursday pairings",
        "threadMessages": [
          "Bring clocks for boards 1-4"
        ]
      },
      "instanceId": "chess-08-chess-discussion-thread",
      "currentState": "open"
    }
  ]
}
''';

class _BookClubEngineTabSurface extends StatefulWidget {
  const _BookClubEngineTabSurface({
    required this.experience,
    required this.persona,
    required this.tabId,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final String tabId;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_BookClubEngineTabSurface> createState() =>
      _BookClubEngineTabSurfaceState();
}

class _BookClubEngineTabSurfaceState extends State<_BookClubEngineTabSurface> {
  static final _stores = <String, _BookClubEngineStore>{};

  late final _BookClubEngineStore _store;
  List<WorkflowInstance> _instances = const [];
  final Map<String, TextEditingController> _controllers = {};
  String? _loadError;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _store = _stores.putIfAbsent(
      widget.experience.extensionId,
      () => _BookClubEngineStore(communityId: widget.experience.extensionId),
    );
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_BookClubEngineTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persona.personaId != widget.persona.personaId ||
        oldWidget.tabId != widget.tabId) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _store.ensureReady();
      final instances = await _store.instancesFor(
        tabId: widget.tabId,
        personaId: widget.persona.personaId,
      );
      _syncControllers(instances);
      if (!mounted) return;
      setState(() {
        _instances = instances;
        _loadError = null;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = '$error';
        _loaded = true;
      });
    }
  }

  Future<void> _transition(WorkflowInstance instance, String transitionId) async {
    await _store.apply(
      instance: instance,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  Future<void> _saveEditableFields(WorkflowInstance instance) async {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    final updates = <String, dynamic>{
      for (final field in fields)
        field: _controllerFor(instance.instanceId, field).text,
    };
    await _store.updateFields(
      instance: instance,
      fieldUpdates: updates,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Text(_loadError!, key: ValueKey('book-load-error-${widget.tabId}')),
      );
    }
    if (widget.tabId == 'home') return _buildHome(context);
    return Column(
      key: ValueKey('book-engine-${widget.tabId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tabId == 'books') ...[
          _bookWorkflowCard(
            context,
            _firstInstance('book-nomination'),
            title: 'Nominate the next book',
            subtitle: 'Form entry with title, author, reason, and cover',
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: 12),
          _bookVotePollCard(context, _firstInstance('book-vote')),
          const SizedBox(height: 12),
          _bookWorkflowCard(
            context,
            _firstInstance('book-selection-publish'),
            title: 'Selection announcement',
            subtitle: 'Notification inbox publish and receive',
            icon: Icons.campaign_outlined,
          ),
        ],
        if (widget.tabId == 'calendar')
          _bookWorkflowCard(
            context,
            _firstInstance('book-meeting-rsvp'),
            title: 'March discussion meeting',
            subtitle: 'Calendar RSVP and attendance',
            icon: Icons.event_available_outlined,
          ),
        if (widget.tabId == 'library')
          for (final instance in _instances.where(
            (item) => item.workflowType == 'book-library-item',
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _bookWorkflowCard(
                context,
                instance,
                title: '${instance.instanceData['itemTitle'] ?? 'Library item'}',
                subtitle: '${instance.instanceData['format'] ?? 'Book'} shared item',
                icon: Icons.local_library_outlined,
              ),
            ),
        if (widget.tabId == 'discussions')
          _bookDiscussionCard(context, _firstInstance('book-discussion-message')),
        if (widget.tabId == 'documents')
          _bookWorkflowCard(
            context,
            _firstInstance('book-reading-material'),
            title: 'Reading guide and author links',
            subtitle: 'Document library open, external, and download',
            icon: Icons.description_outlined,
          ),
        if (widget.tabId == 'search')
          _bookWorkflowCard(
            context,
            _firstInstance('book-search-ai-digest'),
            title: 'Cited book-club search',
            subtitle: 'Search answer with reading-guide citations',
            icon: Icons.manage_search_outlined,
          ),
        if (widget.tabId == 'admin') ...[
          _bookWorkflowCard(
            context,
            _firstInstance('book-selection-publish'),
            title: 'Publish selected book',
            subtitle: 'Organizer composer and member receiver state',
            icon: Icons.campaign_outlined,
          ),
          const SizedBox(height: 12),
          _bookWorkflowCard(
            context,
            _firstInstance('book-export-metadata'),
            title: 'Book records export',
            subtitle: 'Export scope, checksum, and audit',
            icon: Icons.ios_share_outlined,
          ),
        ],
      ],
    );
  }

  Widget _buildHome(BuildContext context) {
    final nomination = _firstInstance('book-nomination');
    final vote = _firstInstance('book-vote');
    final meeting = _firstInstance('book-meeting-rsvp');
    return Column(
      key: const ValueKey('book-engine-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _bookHomePin(
          context,
          key: const ValueKey('book-home-selection'),
          title: 'Current selection',
          icon: Icons.auto_stories_outlined,
          body:
              '${nomination?.instanceData['title'] ?? 'Current title'} by ${nomination?.instanceData['author'] ?? 'Author'}',
        ),
        const SizedBox(height: 12),
        _bookHomePin(
          context,
          key: const ValueKey('book-home-ballot'),
          title: 'Open ballot',
          icon: Icons.how_to_vote_outlined,
          body:
              '${vote?.instanceData['deadline'] ?? 'Deadline'} - ${_bookStateLabel(vote?.currentState ?? 'open')}',
        ),
        const SizedBox(height: 12),
        _bookHomePin(
          context,
          key: const ValueKey('book-home-meeting'),
          title: 'Next meeting',
          icon: Icons.event_note_outlined,
          body:
              '${meeting?.instanceData['meetingTitle'] ?? 'Meeting'}\n${meeting?.instanceData['eventDateTime'] ?? ''}',
        ),
      ],
    );
  }

  Widget _bookHomePin(
    BuildContext context, {
    required Key key,
    required String title,
    required IconData icon,
    required String body,
  }) {
    return DecoratedBox(
      key: key,
      decoration: _bookBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: widget.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookVotePollCard(BuildContext context, WorkflowInstance? instance) {
    return _bookWorkflowCard(
      context,
      instance,
      title: 'Monthly selection ballot',
      subtitle: 'Vote poll with live totals, winner, and tie state',
      icon: Icons.how_to_vote_outlined,
      extra: instance == null
          ? null
          : Column(
              key: const ValueKey('book-vote-poll-results'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text('Parable: ${instance.instanceData['parableVotes'] ?? 0}'),
                Text('Left Hand: ${instance.instanceData['leftHandVotes'] ?? 0}'),
                Text('Winner: ${instance.instanceData['winnerTitle'] ?? 'Pending'}'),
              ],
            ),
    );
  }

  Widget _bookDiscussionCard(BuildContext context, WorkflowInstance? instance) {
    final replies = instance?.instanceData['replies'];
    final items = replies is List
        ? [for (final item in replies) if (item is String) item]
        : const <String>[];
    return _bookWorkflowCard(
      context,
      instance,
      title: 'Parable discussion thread',
      subtitle: 'Replies, edits, deletion, and organizer moderation',
      icon: Icons.forum_outlined,
      extra: Column(
        key: const ValueKey('book-discussion-thread'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          for (final item in items)
            Text(item, key: ValueKey('book-discussion-reply-${item.hashCode}')),
        ],
      ),
    );
  }

  Widget _bookWorkflowCard(
    BuildContext context,
    WorkflowInstance? instance, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? extra,
  }) {
    if (instance == null) {
      return _TabEmptyState(
        icon: icon,
        title: '$title unavailable',
        body: 'No engine instance is available for this Book Club surface.',
        accent: widget.accent,
        modernTheme: widget.modernTheme,
      );
    }
    final transitions = _store.availableTransitions(
      instance: instance,
      personaId: widget.persona.personaId,
    );
    final machine = _store.machineFor(instance.workflowType);
    final data = instance.instanceData;
    final queue = data['queuePersonaIds'];
    final queueCount = queue is List ? queue.length : 0;
    return DecoratedBox(
      key: ValueKey('book-card-${instance.workflowType}-${instance.instanceId}'),
      decoration: _bookBoxDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: widget.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.flag_outlined,
                  label:
                      'State: ${machine.states[instance.currentState]?.label ?? _bookStateLabel(instance.currentState)}',
                  foreground: widget.accent,
                ),
                for (final pill in _factPills(machine, data)) pill,
                if (queueCount > 0)
                  _SurfaceFactPill(
                    icon: Icons.people_alt_outlined,
                    label: 'Queue: $queueCount',
                    foreground: widget.accent,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final field in const [
              'title',
              'author',
              'meetingTitle',
              'itemTitle',
              'currentHolder',
              'materialTitle',
              'answer',
              'announcementTitle',
              'downloadStatus',
            ])
              if (data[field] case final value?) Text('$value'),
            if (_store.editableFieldsFor(
                  workflowType: instance.workflowType,
                  state: instance.currentState,
                ).isNotEmpty)
              _buildEditableFields(instance),
            if (extra != null) extra,
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final transition in transitions)
                  OutlinedButton.icon(
                    key: ValueKey('book-action-${transition.id}'),
                    style: _bookButtonStyle(transition),
                    onPressed: () => _transition(instance, transition.id),
                    icon: Icon(_bookIconForTransition(transition.icon)),
                    label: Text(transition.label),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in _historyItems(data))
              Text(item, key: ValueKey('book-history-${item.hashCode}')),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFields(WorkflowInstance instance) {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    return Column(
      key: ValueKey('book-edit-form-${instance.workflowType}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        for (final field in fields)
          TextField(
            key: ValueKey('book-edit-$field'),
            controller: _controllerFor(instance.instanceId, field),
            decoration: InputDecoration(labelText: _bookFieldLabel(field)),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: ValueKey('book-save-edit-${instance.workflowType}'),
          onPressed: () => _saveEditableFields(instance),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save edits'),
        ),
      ],
    );
  }

  List<Widget> _factPills(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> data,
  ) {
    final pills = <Widget>[];
    for (final entry in machine.instanceDataSchema.entries) {
      final field = entry.value;
      final iconName = field.displayIcon;
      if (iconName == null) continue;
      final value = data[entry.key];
      final isEmpty = value == null ||
          (value is String && value.isEmpty) ||
          (value is List && value.isEmpty);
      if (field.hideWhenEmpty && isEmpty) continue;
      final label = _renderBookLabel(field.labelTemplate, value);
      if (label.isEmpty) continue;
      pills.add(
        _SurfaceFactPill(
          icon: _bookFactIcon(iconName),
          label: label,
          foreground: widget.accent,
        ),
      );
    }
    return pills;
  }

  List<String> _historyItems(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      if (!entry.key.toLowerCase().contains('history')) continue;
      final value = entry.value;
      if (value is List) {
        return [for (final item in value) if (item is String) item];
      }
    }
    return const <String>[];
  }

  void _syncControllers(List<WorkflowInstance> instances) {
    for (final instance in instances) {
      final fields = _store.editableFieldsFor(
        workflowType: instance.workflowType,
        state: instance.currentState,
      );
      for (final field in fields) {
        _controllerFor(instance.instanceId, field).text =
            '${instance.instanceData[field] ?? ''}';
      }
    }
  }

  TextEditingController _controllerFor(String instanceId, String field) {
    final key = '$instanceId::$field';
    return _controllers.putIfAbsent(key, TextEditingController.new);
  }

  WorkflowInstance? _firstInstance(String workflowType) {
    for (final instance in _instances) {
      if (instance.workflowType == workflowType) return instance;
    }
    return null;
  }

  String _renderBookLabel(String? template, dynamic value) {
    if (template == null) return '';
    return template
        .replaceAll('{value.length}', value is List ? '${value.length}' : '0')
        .replaceAll('{value}', value is List ? value.join(', ') : '${value ?? ''}');
  }

  ButtonStyle _bookButtonStyle(LoomWorkflowTransition transition) {
    final destructive = transition.tone == 'destructive' ||
        transition.id.contains('withdraw') ||
        transition.id.contains('clear') ||
        transition.id.contains('delete') ||
        transition.id.contains('lost') ||
        transition.id.contains('delist');
    final primary = transition.tone == 'primary' ||
        transition.id.contains('submit') ||
        transition.id.contains('cast') ||
        transition.id.contains('request') ||
        transition.id.contains('claim') ||
        transition.id.contains('publish') ||
        transition.id.contains('open') ||
        transition.id.contains('reply');
    return OutlinedButton.styleFrom(
      foregroundColor: destructive
          ? Colors.red.shade800
          : primary
              ? Colors.white
              : widget.accent,
      backgroundColor: primary ? widget.accent : null,
      side: BorderSide(color: destructive ? Colors.red.shade800 : widget.accent),
    );
  }

  IconData _bookIconForTransition(String? icon) {
    switch (icon) {
      case 'edit':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'event_available':
        return Icons.event_available_outlined;
      case 'queue':
        return Icons.people_alt_outlined;
      case 'undo':
        return Icons.undo_outlined;
      case 'download':
        return Icons.download_outlined;
      case 'search':
        return Icons.manage_search_outlined;
      case 'publish':
        return Icons.campaign_outlined;
      case 'vote':
        return Icons.how_to_vote_outlined;
      case 'reply':
        return Icons.reply_outlined;
    }
    return Icons.menu_book_outlined;
  }

  IconData _bookFactIcon(String iconName) {
    switch (iconName) {
      case 'schedule':
        return Icons.schedule_outlined;
      case 'location_on':
        return Icons.location_on_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'person':
        return Icons.person_outline;
      case 'verified':
        return Icons.verified_outlined;
      case 'search':
        return Icons.manage_search_outlined;
      case 'description':
        return Icons.description_outlined;
    }
    return Icons.label_outline;
  }

  String _bookFieldLabel(String field) {
    switch (field) {
      case 'title':
        return 'Title';
      case 'author':
        return 'Author';
      case 'reason':
        return 'Reason';
      case 'coverImage':
        return 'Cover image';
      case 'messageBody':
        return 'Message';
      case 'itemTitle':
        return 'Item title';
      case 'condition':
        return 'Condition';
    }
    return field;
  }

  BoxDecoration get _bookBoxDecoration => BoxDecoration(
        color: widget.modernTheme?.resolvedFill ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              widget.modernTheme?.resolvedBorder ??
              widget.accent.withValues(alpha: 0.2),
        ),
      );
}

class _BookClubEngineStore {
  _BookClubEngineStore({required this.communityId});

  final String communityId;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: communityId,
  );
  _BookFixtureBundle? _fixture;
  Future<void>? _readyFuture;
  var _ready = false;

  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _readyFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    _fixture ??= await _BookFixtureBundle.load();
    for (final machine in _fixture!.machines.values) {
      _engine.registerDefinition(machine);
    }
    for (final instance in _fixture!.instances) {
      await _engine.createInstance(
        workflowType: instance.workflowType,
        initialInstanceData: instance.instanceData,
        personaId: instance.createdByPersonaId,
      );
    }
    _ready = true;
  }

  Future<List<WorkflowInstance>> instancesFor({
    required String tabId,
    required String personaId,
  }) async {
    await ensureReady();
    final page = await _engine.queryInstances(
      tabId: tabId,
      personaId: personaId,
      limit: 100,
      query: const SurfaceQuery(),
    );
    final allowed = switch (tabId) {
      'books' => const {
          'book-nomination',
          'book-vote',
          'book-selection-publish',
        },
      'calendar' => const {'book-meeting-rsvp'},
      'library' => const {'book-library-item'},
      'discussions' => const {'book-discussion-message'},
      'documents' => const {'book-reading-material'},
      'search' => const {'book-search-ai-digest'},
      'admin' => const {'book-selection-publish', 'book-export-metadata'},
      'home' => const {
          'book-nomination',
          'book-vote',
          'book-meeting-rsvp',
          'book-selection-publish',
        },
      _ => const <String>{},
    };
    return page.items
        .where((instance) => allowed.contains(instance.workflowType))
        .toList(growable: false);
  }

  List<LoomWorkflowTransition> availableTransitions({
    required WorkflowInstance instance,
    required String personaId,
  }) {
    return _engine.availableTransitions(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      currentState: instance.currentState,
      instanceData: instance.instanceData,
      personaId: personaId,
    );
  }

  Future<void> apply({
    required WorkflowInstance instance,
    required String transitionId,
    required String personaId,
  }) async {
    await _engine.applyTransition(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      transitionId: transitionId,
      personaId: personaId,
    );
  }

  Future<void> updateFields({
    required WorkflowInstance instance,
    required Map<String, dynamic> fieldUpdates,
    required String personaId,
  }) async {
    await _engine.updateInstanceFields(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      fieldUpdates: fieldUpdates,
      personaId: personaId,
    );
  }

  LoomWorkflowStateMachine machineFor(String workflowType) {
    return _fixture!.machines[workflowType]!;
  }

  List<String> editableFieldsFor({
    required String workflowType,
    required String state,
  }) {
    return machineFor(workflowType).states[state]?.editableFields ?? const [];
  }
}

class _BookFixtureBundle {
  _BookFixtureBundle({required this.machines, required this.instances});

  final Map<String, LoomWorkflowStateMachine> machines;
  final List<_GardenSeedInstance> instances;

  static Future<_BookFixtureBundle> load() async {
    final json = jsonDecode(_stripGardenJsoncComments(_bookBundledFixtureJsonc))
        as Map<String, dynamic>;
    final definitions =
        json['workflowDefinitions'] as Map<String, dynamic>? ?? const {};
    final machines = <String, LoomWorkflowStateMachine>{};
    for (final entry in definitions.entries) {
      machines[entry.key] = LoomWorkflowStateMachine.fromJson(
        _normalizeGardenMachineJson(entry.value as Map<String, dynamic>),
        entry.key,
      );
    }
    final rawInstances = json['workflowInstances'] as List<dynamic>? ?? const [];
    final instances = [
      for (final item in rawInstances)
        _GardenSeedInstance.fromJson(item as Map<String, dynamic>),
    ];
    return _BookFixtureBundle(machines: machines, instances: instances);
  }
}

const _bookBundledFixtureJsonc = r'''
{
  "personas": ["book-member", "book-organizer"],
  "templates": {
    "dashboard": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "formEntry": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow", "WorkflowFormFieldList"] },
    "votePoll": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "notificationInbox": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "calendarAgenda": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "stateMachineGrid": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "discussionThread": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "documentLibrary": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "searchAiAnswer": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] },
    "exportWizard": { "slots": ["WorkflowFactPillRow", "WorkflowActionButtonRow"] }
  },
  "workflowDefinitions": {
    "book-nomination": {
      "initialState": "draft",
      "states": {
        "draft": { "label": "Draft", "editableFields": ["title", "author", "reason", "coverImage"] },
        "submitted": { "label": "Submitted" },
        "selected": { "label": "Selected", "isTerminal": true },
        "withdrawn": { "label": "Withdrawn", "isTerminal": true }
      },
      "transitions": [
        { "id": "submit-nomination", "label": "Submit nomination", "icon": "book", "tone": "primary", "from": ["draft"], "to": "submitted", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "nominationHistory", "value": "{title} nominated at $timestamp" }] },
        { "id": "edit-nomination", "label": "Edit nomination", "icon": "edit", "tone": "secondary", "from": ["submitted"], "to": "draft", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "nominationHistory", "value": "{title} reopened for edit at $timestamp" }] },
        { "id": "select-nomination", "label": "Select nomination", "icon": "verified", "tone": "primary", "from": ["submitted"], "to": "selected", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "append", "key": "nominationHistory", "value": "{title} selected at $timestamp" }] },
        { "id": "withdraw-nomination", "label": "Withdraw nomination", "icon": "delete", "tone": "destructive", "from": ["draft", "submitted"], "to": "withdrawn", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "nominationHistory", "value": "{title} withdrawn at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["draft", "submitted", "selected", "withdrawn"], "role": "any", "tabId": "books", "cardSurfaceFamily": "formEntry", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "title": { "type": "text", "required": true, "writableBy": "formEntry", "displayIcon": "book", "labelTemplate": "{value}" },
        "author": { "type": "text", "required": true, "writableBy": "formEntry", "displayIcon": "person", "labelTemplate": "{value}" },
        "reason": { "type": "text", "writableBy": "formEntry" },
        "coverImage": { "type": "text", "writableBy": "formEntry" },
        "nominationHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-vote": {
      "initialState": "open",
      "states": {
        "open": { "label": "Open" },
        "cast": { "label": "Vote cast" },
        "winner": { "label": "Winner selected" },
        "tie": { "label": "Tie", "isTerminal": true }
      },
      "transitions": [
        { "id": "cast-vote", "label": "Cast vote", "icon": "vote", "tone": "primary", "from": ["open"], "to": "cast", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "memberVote", "value": "Parable of the Sower" }, { "op": "set", "key": "parableVotes", "value": 7 }, { "op": "append", "key": "voteHistory", "value": "Vote cast at $timestamp" }] },
        { "id": "change-vote", "label": "Change vote", "icon": "edit", "tone": "secondary", "from": ["cast"], "to": "cast", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "memberVote", "value": "The Left Hand of Darkness" }, { "op": "set", "key": "leftHandVotes", "value": 7 }, { "op": "append", "key": "voteHistory", "value": "Vote changed at $timestamp" }] },
        { "id": "clear-vote", "label": "Clear vote", "icon": "delete", "tone": "destructive", "from": ["cast"], "to": "open", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "memberVote", "value": "" }, { "op": "append", "key": "voteHistory", "value": "Vote cleared at $timestamp" }] },
        { "id": "close-winner", "label": "Close with winner", "icon": "verified", "tone": "primary", "from": ["cast", "open"], "to": "winner", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "set", "key": "winnerTitle", "value": "Parable of the Sower" }, { "op": "append", "key": "voteHistory", "value": "Ballot closed with winner at $timestamp" }] },
        { "id": "mark-tie", "label": "Mark tie", "icon": "vote", "tone": "secondary", "from": ["winner"], "to": "tie", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "set", "key": "winnerTitle", "value": "Tie: Parable / Left Hand" }, { "op": "append", "key": "voteHistory", "value": "Ballot marked tie at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["open", "cast", "winner", "tie"], "role": "any", "tabId": "books", "cardSurfaceFamily": "votePoll", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "deadline": { "type": "text", "displayIcon": "schedule", "labelTemplate": "{value}" },
        "candidates": { "type": "list", "displayIcon": "book", "labelTemplate": "{value.length} candidates" },
        "memberVote": { "type": "text", "writableBy": "effect" },
        "parableVotes": { "type": "number", "writableBy": "effect" },
        "leftHandVotes": { "type": "number", "writableBy": "effect" },
        "winnerTitle": { "type": "text", "writableBy": "effect", "displayIcon": "verified", "labelTemplate": "Winner: {value}" },
        "voteHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-meeting-rsvp": {
      "initialState": "open",
      "states": { "open": { "label": "Open" }, "going": { "label": "Going" }, "maybe": { "label": "Maybe" }, "not-going": { "label": "Not going" } },
      "transitions": [
        { "id": "rsvp-going", "label": "RSVP going", "icon": "event_available", "tone": "primary", "from": ["open", "maybe", "not-going"], "to": "going", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "meetingHistory", "value": "RSVP going at $timestamp" }] },
        { "id": "rsvp-maybe", "label": "RSVP maybe", "icon": "edit", "tone": "secondary", "from": ["open", "going", "not-going"], "to": "maybe", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "meetingHistory", "value": "RSVP maybe at $timestamp" }] },
        { "id": "cancel-rsvp", "label": "Cancel RSVP", "icon": "undo", "tone": "destructive", "from": ["going", "maybe"], "to": "not-going", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "meetingHistory", "value": "RSVP cancelled at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["open", "going", "maybe", "not-going"], "role": "actor", "tabId": "calendar", "cardSurfaceFamily": "calendarAgenda", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "meetingTitle": { "type": "text", "displayIcon": "book", "labelTemplate": "{value}" },
        "eventDateTime": { "type": "text", "displayIcon": "schedule", "labelTemplate": "{value}" },
        "location": { "type": "text", "displayIcon": "location_on", "labelTemplate": "{value}" },
        "attendance": { "type": "list", "displayIcon": "groups", "labelTemplate": "{value.length} attending" },
        "meetingHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-library-item": {
      "initialState": "available",
      "states": { "available": { "label": "Available", "editableFields": ["itemTitle", "condition"] }, "borrowed": { "label": "Borrowed" }, "queued": { "label": "Queued" }, "returned": { "label": "Returned" }, "giveaway": { "label": "Giveaway" }, "given": { "label": "Given", "isTerminal": true }, "lost": { "label": "Lost", "isTerminal": true }, "delisted": { "label": "Delisted", "isTerminal": true } },
      "transitions": [
        { "id": "request-loan", "label": "Request loan", "icon": "book", "tone": "primary", "from": ["available"], "to": "borrowed", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "{actorLabel}" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} borrowed at $timestamp" }] },
        { "id": "join-waitlist", "label": "Join waitlist", "icon": "queue", "tone": "secondary", "from": ["borrowed"], "to": "queued", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "queuePersonaIds", "value": "{actor}" }] },
        { "id": "leave-waitlist", "label": "Leave waitlist", "icon": "undo", "tone": "secondary", "from": ["queued"], "to": "borrowed", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "removeValue", "key": "queuePersonaIds", "value": "{actor}" }] },
        { "id": "return-item", "label": "Return item", "icon": "undo", "tone": "primary", "from": ["borrowed", "queued"], "to": "returned", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} returned at $timestamp" }] },
        { "id": "offer-giveaway", "label": "Offer giveaway", "icon": "book", "tone": "secondary", "from": ["returned"], "to": "giveaway", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "mode", "value": "Giveaway" }] },
        { "id": "claim-giveaway", "label": "Claim giveaway", "icon": "verified", "tone": "primary", "from": ["giveaway"], "to": "given", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "set", "key": "currentHolder", "value": "{actorLabel}" }, { "op": "append", "key": "custodyHistory", "value": "{itemTitle} given at $timestamp" }] },
        { "id": "report-lost", "label": "Report lost", "icon": "delete", "tone": "destructive", "from": ["borrowed", "queued"], "to": "lost", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "custodyHistory", "value": "{itemTitle} reported lost at $timestamp" }] },
        { "id": "delist-item", "label": "Delist item", "icon": "delete", "tone": "destructive", "from": ["available", "returned"], "to": "delisted", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "custodyHistory", "value": "{itemTitle} delisted at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["available", "borrowed", "queued", "returned", "giveaway", "given", "lost", "delisted"], "role": "any", "tabId": "library", "cardSurfaceFamily": "stateMachineGrid", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "itemTitle": { "type": "text", "writableBy": "formEntry", "displayIcon": "book", "labelTemplate": "{value}" },
        "format": { "type": "text", "displayIcon": "inventory_2", "labelTemplate": "{value}" },
        "condition": { "type": "text", "writableBy": "formEntry", "displayIcon": "verified", "labelTemplate": "{value}" },
        "mode": { "type": "text", "writableBy": "effect", "displayIcon": "inventory_2", "labelTemplate": "{value}" },
        "currentHolder": { "type": "text", "writableBy": "effect", "displayIcon": "person", "labelTemplate": "Holder: {value}", "hideWhenEmpty": true },
        "queuePersonaIds": { "type": "list", "writableBy": "effect" },
        "custodyHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-discussion-message": {
      "initialState": "open",
      "states": { "open": { "label": "Open", "editableFields": ["messageBody"] }, "replied": { "label": "Replied" }, "moderated": { "label": "Moderated", "isTerminal": true }, "deleted": { "label": "Deleted", "isTerminal": true } },
      "transitions": [
        { "id": "reply", "label": "Reply", "icon": "reply", "tone": "primary", "from": ["open"], "to": "replied", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "replies", "value": "{actorLabel} replied at $timestamp" }] },
        { "id": "edit-reply", "label": "Edit reply", "icon": "edit", "tone": "secondary", "from": ["replied"], "to": "open", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "discussionHistory", "value": "Reply edited at $timestamp" }] },
        { "id": "delete-reply", "label": "Delete reply", "icon": "delete", "tone": "destructive", "from": ["replied"], "to": "deleted", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "discussionHistory", "value": "Reply deleted at $timestamp" }] },
        { "id": "moderate-thread", "label": "Moderate thread", "icon": "verified", "tone": "primary", "from": ["replied"], "to": "moderated", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "append", "key": "discussionHistory", "value": "Thread moderated at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["open", "replied", "moderated", "deleted"], "role": "any", "tabId": "discussions", "cardSurfaceFamily": "discussionThread", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "prompt": { "type": "text", "displayIcon": "book", "labelTemplate": "{value}" },
        "messageBody": { "type": "text", "writableBy": "formEntry" },
        "replies": { "type": "list", "writableBy": "effect" },
        "discussionHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-reading-material": {
      "initialState": "available",
      "states": { "available": { "label": "Available" }, "embedded-opened": { "label": "Embedded opened" }, "external-opened": { "label": "External opened" }, "downloaded": { "label": "Downloaded", "isTerminal": true } },
      "transitions": [
        { "id": "open-embedded", "label": "Open embedded", "icon": "book", "tone": "primary", "from": ["available"], "to": "embedded-opened", "guard": { "allowedPersonaIds": ["book-member", "book-organizer"] }, "effects": [{ "op": "append", "key": "documentHistory", "value": "Embedded guide opened at $timestamp" }] },
        { "id": "open-external", "label": "Open external", "icon": "book", "tone": "secondary", "from": ["embedded-opened"], "to": "external-opened", "guard": { "allowedPersonaIds": ["book-member", "book-organizer"] }, "effects": [{ "op": "append", "key": "documentHistory", "value": "Author link opened at $timestamp" }] },
        { "id": "download-material", "label": "Download", "icon": "download", "tone": "primary", "from": ["external-opened"], "to": "downloaded", "guard": { "allowedPersonaIds": ["book-member", "book-organizer"] }, "effects": [{ "op": "append", "key": "documentHistory", "value": "Guide downloaded at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["available", "embedded-opened", "external-opened", "downloaded"], "role": "any", "tabId": "documents", "cardSurfaceFamily": "documentLibrary", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "materialTitle": { "type": "text", "displayIcon": "description", "labelTemplate": "{value}" },
        "sourceCount": { "type": "number", "displayIcon": "book", "labelTemplate": "{value} sources" },
        "documentHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-selection-publish": {
      "initialState": "draft",
      "states": { "draft": { "label": "Draft" }, "preview": { "label": "Preview" }, "scheduled": { "label": "Scheduled" }, "sent": { "label": "Sent" }, "read": { "label": "Read", "isTerminal": true } },
      "transitions": [
        { "id": "preview-selection", "label": "Preview selection", "icon": "edit", "tone": "secondary", "from": ["draft"], "to": "preview", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "append", "key": "publishHistory", "value": "Selection previewed at $timestamp" }] },
        { "id": "schedule-selection", "label": "Schedule selection", "icon": "schedule", "tone": "secondary", "from": ["preview"], "to": "scheduled", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "append", "key": "publishHistory", "value": "Selection scheduled at $timestamp" }] },
        { "id": "publish-selection", "label": "Publish selection", "icon": "publish", "tone": "primary", "from": ["scheduled"], "to": "sent", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "append", "key": "publishHistory", "value": "Selection published at $timestamp" }] },
        { "id": "read-selection", "label": "Mark read", "icon": "verified", "tone": "primary", "from": ["sent"], "to": "read", "guard": { "allowedPersonaIds": ["book-member"] }, "effects": [{ "op": "append", "key": "publishHistory", "value": "Selection read at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["draft", "preview", "scheduled", "sent", "read"], "role": "any", "tabId": "books", "cardSurfaceFamily": "notificationInbox", "bindingKind": "primary" }, { "states": ["draft", "preview", "scheduled", "sent", "read"], "role": "actor", "tabId": "admin", "cardSurfaceFamily": "notificationInbox", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "announcementTitle": { "type": "text", "displayIcon": "book", "labelTemplate": "{value}" },
        "audience": { "type": "text", "displayIcon": "groups", "labelTemplate": "{value}" },
        "publishHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-search-ai-digest": {
      "initialState": "ready",
      "states": { "ready": { "label": "Ready" }, "answered": { "label": "Answered", "isTerminal": true } },
      "transitions": [
        { "id": "generate-answer", "label": "Generate answer", "icon": "search", "tone": "primary", "from": ["ready"], "to": "answered", "guard": { "allowedPersonaIds": ["book-member", "book-organizer"] }, "effects": [{ "op": "set", "key": "answer", "value": "Cited answer generated from discussion notes and reading guide." }, { "op": "append", "key": "searchHistory", "value": "Cited digest generated at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["ready", "answered"], "role": "any", "tabId": "search", "cardSurfaceFamily": "searchAiAnswer", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "query": { "type": "text", "displayIcon": "search", "labelTemplate": "{value}" },
        "answer": { "type": "text", "writableBy": "effect" },
        "citations": { "type": "list", "displayIcon": "description", "labelTemplate": "{value.length} citations" },
        "searchHistory": { "type": "list", "writableBy": "effect" }
      }
    },
    "book-export-metadata": {
      "initialState": "ready",
      "states": { "ready": { "label": "Ready" }, "generated": { "label": "Generated" }, "rolled-back": { "label": "Rolled back", "isTerminal": true } },
      "transitions": [
        { "id": "generate-export", "label": "Generate export", "icon": "download", "tone": "primary", "from": ["ready"], "to": "generated", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "set", "key": "downloadStatus", "value": "Download ready" }, { "op": "append", "key": "exportHistory", "value": "Book export generated at $timestamp" }] },
        { "id": "rollback-export", "label": "Rollback export", "icon": "undo", "tone": "destructive", "from": ["generated"], "to": "rolled-back", "guard": { "allowedPersonaIds": ["book-organizer"] }, "effects": [{ "op": "set", "key": "downloadStatus", "value": "Rolled back" }, { "op": "append", "key": "exportHistory", "value": "Book export rolled back at $timestamp" }] }
      ],
      "renderBindings": [{ "states": ["ready", "generated", "rolled-back"], "role": "actor", "tabId": "admin", "cardSurfaceFamily": "exportWizard", "bindingKind": "primary" }],
      "instanceDataSchema": {
        "schemas": { "type": "list", "displayIcon": "description", "labelTemplate": "{value.length} schemas" },
        "checksum": { "type": "text", "displayIcon": "verified", "labelTemplate": "Checksum: {value}" },
        "downloadStatus": { "type": "text", "writableBy": "effect" },
        "exportHistory": { "type": "list", "writableBy": "effect" }
      }
    }
  },
  "workflowInstances": [
    { "instanceId": "book-nomination-parable", "workflowType": "book-nomination", "currentState": "draft", "createdByPersonaId": "book-member", "instanceData": { "title": "Parable of the Sower", "author": "Octavia Butler", "reason": "Timely climate and community themes.", "coverImage": "parable-cover", "nominationHistory": [] } },
    { "instanceId": "book-vote-march", "workflowType": "book-vote", "currentState": "open", "createdByPersonaId": "book-organizer", "instanceData": { "deadline": "Voting closes Friday", "candidates": ["Parable of the Sower", "The Left Hand of Darkness"], "memberVote": "", "parableVotes": 6, "leftHandVotes": 5, "winnerTitle": "Pending", "voteHistory": [] } },
    { "instanceId": "book-meeting-march", "workflowType": "book-meeting-rsvp", "currentState": "open", "createdByPersonaId": "book-member", "instanceData": { "meetingTitle": "March discussion: Parable", "eventDateTime": "Sunday, Mar 22 at 4:00 PM", "location": "Library room B and video link", "attendance": [], "meetingHistory": [] } },
    { "instanceId": "book-library-parable", "workflowType": "book-library-item", "currentState": "available", "createdByPersonaId": "book-member", "instanceData": { "itemTitle": "Parable paperback", "format": "Book", "condition": "Good", "mode": "Loan", "currentHolder": "", "queuePersonaIds": [], "custodyHistory": [] } },
    { "instanceId": "book-discussion-parable", "workflowType": "book-discussion-message", "currentState": "open", "createdByPersonaId": "book-member", "instanceData": { "prompt": "What does community resilience mean in chapter 4?", "messageBody": "I want to compare the neighborhood scenes.", "replies": ["Prompt seeded for current selection"], "discussionHistory": [] } },
    { "instanceId": "book-reading-guide", "workflowType": "book-reading-material", "currentState": "available", "createdByPersonaId": "book-organizer", "instanceData": { "materialTitle": "Parable reading guide", "sourceCount": 3, "documentHistory": [] } },
    { "instanceId": "book-selection-march", "workflowType": "book-selection-publish", "currentState": "draft", "createdByPersonaId": "book-organizer", "instanceData": { "announcementTitle": "March selection: Parable of the Sower", "audience": "All book-club members", "publishHistory": [] } },
    { "instanceId": "book-search-parable", "workflowType": "book-search-ai-digest", "currentState": "ready", "createdByPersonaId": "book-member", "instanceData": { "query": "What themes did members raise about resilience?", "answer": "", "citations": ["Reading guide", "Discussion prompt", "Meeting notes"], "searchHistory": [] } },
    { "instanceId": "book-export", "workflowType": "book-export-metadata", "currentState": "ready", "createdByPersonaId": "book-organizer", "instanceData": { "schemas": ["book_nomination", "book_vote"], "checksum": "B00K-CLUB", "downloadStatus": "Not generated", "exportHistory": [] } }
  ]
}
''';

String _bookStateLabel(String state) {
  final label = state.replaceAll('-', ' ');
  if (label.isEmpty) return label;
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

String _cameraStateLabel(String state) {
  final label = state.replaceAll('-', ' ');
  if (label.isEmpty) return label;
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

String _gardenStateLabel(String state) {
  final label = state.replaceAll('-', ' ');
  if (label.isEmpty) return label;
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

LoomWorkflowTransition _transition({
  required String id,
  required String label,
  required List<String> from,
  required String to,
  required List<String> personas,
  required String history,
  String? reviewerNote,
}) {
  return LoomWorkflowTransition(
    id: id,
    label: label,
    icon: 'fact_check',
    tone: id == 'reject' || id == 'withdraw' ? 'destructive' : 'primary',
    from: from,
    to: to,
    guard: WorkflowGuard(allowedPersonaIds: personas),
    effects: [
      if (reviewerNote != null)
        WorkflowEffect(op: 'set', key: 'reviewerNote', value: reviewerNote),
      WorkflowEffect(op: 'append', key: 'history', value: history),
    ],
  );
}

String _labelForState(String state) {
  switch (state) {
    case 'submitted':
      return 'Submitted';
    case 'under-review':
      return 'Under review';
    case 'changes-needed':
      return 'Changes needed';
    case 'approved':
      return 'Approved';
    case 'denied':
      return 'Denied';
    case 'reopened':
      return 'Reopened';
    case 'withdrawn':
      return 'Withdrawn';
  }
  return state;
}

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
class _GivingTabSurface extends StatefulWidget {
  const _GivingTabSurface({
    required this.givingPayment,
    required this.communityId,
    required this.workflowId,
    required this.workflow,
    required this.personaId,
    required this.personaLabel,
    required this.allowedPersonaIds,
    required this.accent,
    this.modernTheme,
    this.onConfirmWorkflow,
    required this.paid,
  });

  final LoomGivingPayment givingPayment;
  final String communityId;
  final String workflowId;
  final LoomWorkflowDefinition workflow;
  final String personaId;
  final String personaLabel;
  final List<String> allowedPersonaIds;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final ValueChanged<LoomWorkflowDefinition>? onConfirmWorkflow;
  final bool paid;

  @override
  State<_GivingTabSurface> createState() => _GivingTabSurfaceState();
}

class _GivingTabSurfaceState extends State<_GivingTabSurface> {
  late final WorkflowDatabase _database;
  late final LocalWorkflowEngineApi _engine;
  late final LoomWorkflowStateMachine _machine;
  WorkflowInstance? _instance;
  var _seedComplete = false;
  var _applyingCompletion = false;

  @override
  void initState() {
    super.initState();
    _database = WorkflowDatabase.memory();
    _engine = LocalWorkflowEngineApi(
      db: _database,
      communityId: widget.communityId,
    );
    _machine = _paymentMachineFor(widget.workflowId);
    _engine.registerDefinition(_machine);
    unawaited(_seed());
  }

  @override
  void didUpdateWidget(_GivingTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.paid && widget.paid) {
      unawaited(_completePaymentIfNeeded());
    }
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _seed() async {
    final data = _paymentInstanceData();
    final instanceId = await _engine.createInstance(
      workflowType: _machine.workflowType,
      initialInstanceData: data,
      personaId: widget.personaId,
    );
    if (!mounted) return;
    setState(() {
      _instance = WorkflowInstance(
        instanceId: instanceId,
        workflowType: _machine.workflowType,
        currentState: _machine.initialState,
        instanceData: data,
        createdByPersonaId: widget.personaId,
      );
      _seedComplete = true;
    });
    if (widget.paid) {
      await _completePaymentIfNeeded();
    }
  }

  Future<void> _completePaymentIfNeeded() async {
    final instance = _instance;
    if (instance == null ||
        instance.currentState == 'paid' ||
        _applyingCompletion) {
      return;
    }
    _applyingCompletion = true;
    final result = await _engine.applyTransition(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      transitionId: 'pay',
      personaId: widget.personaId,
    );
    _applyingCompletion = false;
    if (!mounted) return;
    setState(() {
      _instance = WorkflowInstance(
        instanceId: instance.instanceId,
        workflowType: instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: instance.createdByPersonaId,
      );
    });
  }

  Map<String, dynamic> _paymentInstanceData() {
    return {
      'workflowId': widget.workflowId,
      'amountLabel': widget.givingPayment.amountLabel,
      'purpose': widget.givingPayment.purpose ?? '',
      'recipient': widget.givingPayment.recipient ?? 'Tabletop Club treasury',
      'payerLabel': widget.personaLabel,
      'cadence': widget.givingPayment.cadence ?? '',
      'entitlement': widget.givingPayment.entitlement ?? '',
      'receiptStatus': '',
      'paymentHistory': const <String>[],
    };
  }

  List<WorkflowActionButtonTransition> _paymentActions() {
    final instance = _instance;
    if (instance == null || instance.currentState == 'paid') return const [];
    return _machine
        .transitionsFrom(instance.currentState)
        .where(
          (transition) => evaluateGuard(
            transition.guard,
            widget.personaId,
            instance.instanceData,
          ),
        )
        .map(
          (transition) => WorkflowActionButtonTransition(
            id: transition.id,
            label: transition.label,
            iconName: transition.icon,
            tone: _toneForEventTransition(transition),
          ),
        )
        .toList(growable: false);
  }

  LoomWorkflowStateMachine _paymentMachineFor(String workflowId) {
    return LoomWorkflowStateMachine(
      workflowType: workflowId,
      initialState: 'unpaid',
      states: const {
        'unpaid': LoomWorkflowState(label: 'Unpaid', tone: 'warning'),
        'paid': LoomWorkflowState(
          label: 'Paid',
          tone: 'positive',
          isTerminal: true,
        ),
      },
      transitions: [
        LoomWorkflowTransition(
          id: 'pay',
          label: 'Pay ${widget.givingPayment.amountLabel}',
          icon: 'payments_outlined',
          tone: 'primary',
          from: const ['unpaid'],
          to: 'paid',
          guard: WorkflowGuard(
            allowedPersonaIds: widget.allowedPersonaIds,
          ),
          effects: const [
            WorkflowEffect(op: 'set', key: 'receiptStatus', value: 'complete'),
            WorkflowEffect(
              op: 'append',
              key: 'paymentHistory',
              value: 'Payment completed at \$timestamp',
            ),
          ],
          linkedWorkflowId: workflowId,
        ),
      ],
      renderBindings: const [
        RenderBinding(
          states: ['unpaid', 'paid'],
          role: 'actor',
          tabId: 'giving',
          cardSurfaceFamily: 'paymentCheckout',
          bindingKind: 'primary',
        ),
      ],
      instanceDataSchema: const {
        'workflowId': InstanceDataField(type: 'string', required: true),
        'amountLabel': InstanceDataField(
          type: 'text',
          required: true,
          displayIcon: 'payments_outlined',
          labelTemplate: '{value}',
        ),
        'purpose': InstanceDataField(
          type: 'text',
          displayIcon: 'receipt_long',
          labelTemplate: '{value}',
        ),
        'recipient': InstanceDataField(
          type: 'text',
          displayIcon: 'account_balance_outlined',
          labelTemplate: 'Recipient: {value}',
        ),
        'payerLabel': InstanceDataField(
          type: 'text',
          displayIcon: 'person_outline',
          labelTemplate: 'Payer: {value}',
        ),
        'cadence': InstanceDataField(
          type: 'text',
          displayIcon: 'repeat',
          labelTemplate: '{value}',
        ),
        'entitlement': InstanceDataField(
          type: 'text',
          displayIcon: 'verified_outlined',
          labelTemplate: '{value}',
        ),
        'receiptStatus': InstanceDataField(type: 'text'),
        'paymentHistory': InstanceDataField(type: 'list'),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final fill = widget.modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.08), widget.accent);
    final border = widget.modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final bodyColor = widget.modernTheme?.resolvedBody ??
        foreground.withValues(alpha: 0.88);
    final instance = _instance;
    if (!_seedComplete || instance == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final paid = instance.currentState == 'paid';
    final paymentActions = _paymentActions();
    final paymentHistory = instance.instanceData['paymentHistory'];
    final paymentHistoryItems = paymentHistory is List
        ? [
            for (final entry in paymentHistory)
              if (entry is String) entry,
          ]
        : const <String>[];

    return Column(
      key: const ValueKey('giving-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Amount and purpose summary
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              key: const ValueKey('giving-amount-summary'),
              children: [
                Row(
                  children: [
                    Icon(
                      paid ? Icons.receipt_long : Icons.payment_outlined,
                      color: foreground,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.givingPayment.amountLabel,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (widget.givingPayment.purpose != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.givingPayment.purpose!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: bodyColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Payer: ${widget.personaLabel}',
                            key: ValueKey('giving-payer-${widget.workflowId}'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: bodyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (paid)
                      const _SurfaceFactPill(
                        icon: Icons.check_circle,
                        label: 'Paid',
                        foreground: Colors.green,
                      ),
                  ],
                ),
                WorkflowCardSurfaceTemplateRenderer(
                  surfaceFamily: 'paymentCheckout',
                  actionSurfaceKey: 'giving',
                  displayContext: 'detail',
                  foreground: foreground,
                  accent: widget.accent,
                  instanceData: instance.instanceData,
                  instanceDataSchema: paymentCheckoutDefaultInstanceDataSchema,
                  availableTransitions: paymentActions,
                  onTransitionPressed: (transitionId) {
                    final transition = _machine.transitions.firstWhere(
                      (candidate) => candidate.id == transitionId,
                    );
                    final linkedWorkflowId = transition.linkedWorkflowId;
                    if (linkedWorkflowId == widget.workflow.workflowId) {
                      widget.onConfirmWorkflow?.call(widget.workflow);
                    }
                  },
                ),
                if (paid && paymentHistoryItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Payment history',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  for (final entry in paymentHistoryItems)
                    Text(
                      entry,
                      key: ValueKey('giving-payment-history-${entry.hashCode}'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: bodyColor,
                          ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Checkout button (unpaid) or receipt card (paid)
        if (paid)
          DecoratedBox(
            key: ValueKey('giving-receipt-${widget.workflowId}'),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.givingPayment.amountLabel} — complete',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: bodyColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (paymentActions.isNotEmpty)
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              key: ValueKey('giving-checkout-${widget.workflowId}'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    widget.modernTheme?.primaryButton?.resolvedFill ?? widget.accent,
                foregroundColor:
                    widget.modernTheme?.primaryButton?.resolvedForeground ??
                        Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => widget.onConfirmWorkflow?.call(widget.workflow),
              icon: const Icon(Icons.payment),
              label: Text('Pay ${widget.givingPayment.amountLabel}'),
            ),
          )
        else
          DecoratedBox(
            key: ValueKey('giving-readonly-${widget.workflowId}'),
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Read-only ledger view. Payment actions are available to the payer.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

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
    final fill = modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.08), accent);
    final border = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final bodyColor = modernTheme?.resolvedBody ??
        foreground.withValues(alpha: 0.90);
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: bodyColor,
                        ),
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
    final border = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final bodyColor = modernTheme?.resolvedBody ??
        foreground.withValues(alpha: 0.90);
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: bodyColor,
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
    final border = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final bodyColor = modernTheme?.resolvedBody ??
        foreground.withValues(alpha: 0.86);
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: bodyColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({required this.accent, this.modernTheme});

  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final selectedFill = modernTheme?.accent ?? accent;
    final unselectedFill = modernTheme?.resolvedFill ??
        Colors.white.withValues(alpha: 0.72);
    final stripBorder = modernTheme?.resolvedBorder ??
        accent.withValues(alpha: 0.22);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SizedBox(
      key: const ValueKey('calendar-week-strip'),
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == 5;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? selectedFill : unselectedFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stripBorder),
            ),
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? foreground : accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${12 + index}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? foreground : accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentLibraryHeader extends StatelessWidget {
  const _DocumentLibraryHeader({required this.accent, this.modernTheme});

  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('documents-library-header'),
      decoration: BoxDecoration(
        color: modernTheme?.resolvedFill ?? Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: modernTheme?.resolvedBorder ?? accent.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SurfaceFactPill(
              icon: Icons.folder_outlined,
              label: 'Library',
              foreground: accent,
            ),
            _SurfaceFactPill(
              icon: Icons.open_in_browser_outlined,
              label: 'Embedded open',
              foreground: accent,
            ),
            _SurfaceFactPill(
              icon: Icons.open_in_new_outlined,
              label: 'External app',
              foreground: accent,
            ),
            _SurfaceFactPill(
              icon: Icons.history_outlined,
              label: 'Versions',
              foreground: accent,
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
    final body = modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.92);
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: body,
                        ),
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
