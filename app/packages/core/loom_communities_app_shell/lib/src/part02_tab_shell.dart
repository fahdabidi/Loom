part of '../loom_communities_app_shell.dart';

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
        Expanded(
          child: ListView.builder(
            itemCount: visibleThreads.length,
            itemBuilder: (context, index) {
              final thread = visibleThreads[index];
              final unread = _isUnread(thread.threadId);
              final muted = _mutedThreadIds.contains(thread.threadId);
              return Padding(
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
                          muted
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
                                color: widget.modernTheme?.accent ??
                                    widget.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              thread.subject,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight:
                                        unread ? FontWeight.w800 : FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        _lastPreview(thread.threadId),
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            itemCount: thread.messages.length,
            itemBuilder: (context, index) {
              final message = thread.messages[index];
              final isMe = message.senderPersonaId == personaId;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                    color: isMe
                        ? (modernTheme?.accent ?? accent).withValues(alpha: 0.18)
                        : foreground.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                        ),
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
              );
            },
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    final rendererId = selectedTab.rendererContract.rendererId;
    final modernTheme = theme.usesModernCardTheme ? theme.tabCard : null;
    // Messages and Home are the only present-by-default domain tabs.
    // Marketplace and Giving are data-driven: real UI when data declared,
    // placeholder otherwise. Other domain tabs stay placeholder-only.
    switch (rendererId) {
      case 'CalendarTabSurface':
        return _CalendarTabSurface(
          experience: experience,
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
        return _MessagesTabSurface(
          experience: experience,
          persona: persona,
          accent: accent,
          modernTheme: modernTheme,
        );
      case 'MarketplaceTabSurface':
        final listings = experience.marketplaceListings;
        if (listings != null && listings.isNotEmpty) {
          return _MarketplaceBrowseSurface(
            listings: listings,
            marketplaceTemplate: experience.marketplaceTemplate,
            workflows: experience.workflows,
            personaId: persona.personaId,
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
      case 'DocumentsTabSurface':
      case 'WorkflowStatusSurface':
      case 'PaymentGivingTabSurface':
      case 'CareVolunteerTabSurface':
      case 'AdminReviewComposeTabSurface':
        // These domain tabs render via placeholder until their data is declared
        // in experience JSON (M5: giving payment, etc.)
        return _TabPlaceholderSurface(
          tabLabel: selectedTab.label,
          communityName: experience.displayName,
          tabIcon: selectedTab.icon,
          accent: accent,
          modernTheme: modernTheme,
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

class _CalendarTabSurface extends StatelessWidget {
  const _CalendarTabSurface({
    required this.experience,
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
  Widget build(BuildContext context) {
    final workflows = _workflowsFromSections(sections);
    if (workflows.isEmpty) {
      return _TabEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No upcoming dates',
        body:
            '${experience.displayName} has no visible calendar items for this persona.',
        accent: accent,
        modernTheme: modernTheme,
      );
    }
    final selected = workflows.firstWhere(
      (workflow) => workflow.workflowId == focusedWorkflowId,
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
          _WeekDateStrip(accent: accent, modernTheme: modernTheme),
          const SizedBox(height: 12),
          _TabNativeSummary(
            icon: Icons.event_available_outlined,
            title: _displayTitleFor(selected),
            body:
                'Agenda detail includes date, time, location, host, capacity, response choices, reminders, and linked workflow state.',
            accent: accent,
            modernTheme: modernTheme,
            facts: const ['Week view', 'Agenda', 'Event detail', 'Reminder'],
          ),
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

    final selectedDated = datedWorkflows.firstWhere(
      (workflow) => workflow.workflowId == focusedWorkflowId,
      orElse: () => datedWorkflows.first,
    );
    // Group dated workflows by date string (ISO date YYYY-MM-DD)
    final groupedByDate = <String, List<LoomWorkflowDefinition>>{};
    for (final wf in datedWorkflows) {
      final dateKey = _isoDateKey(wf.calendarItem!.dateTime);
      groupedByDate.putIfAbsent(dateKey, () => []).add(wf);
    }
    final dateKeys = groupedByDate.keys.toList()..sort();

    return Column(
      key: const ValueKey('calendar-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Horizontal quick-jump date strip (preserved)
        _CalendarAgendaDateStrip(
          accent: accent,
          modernTheme: modernTheme,
          items: datedWorkflows,
          selectedWorkflowId: selectedDated.workflowId,
          onSelectWorkflow: onSelectCalendarDate,
        ),
        const SizedBox(height: 12),
        // Vertical date-grouped agenda (unrolled — no Expanded/ListView
        // since _TabNativeRenderer's output lives inside a SingleChildScrollView)
        for (final dateKey in dateKeys) ...[
          Builder(builder: (context) {
            final events = groupedByDate[dateKey]!;
            final date = events.first.calendarItem!.dateTime;
            final foreground =
                modernTheme?.resolvedHeading ?? _foregroundFor(accent);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date group header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          modernTheme?.resolvedFill ??
                          accent.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            modernTheme?.resolvedBorder ??
                            accent.withValues(alpha: 0.20),
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
                      accent: accent,
                      modernTheme: modernTheme,
                      isFocused:
                          workflow.workflowId == selectedDated.workflowId,
                      reminderEnabled: reminderEnabledWorkflowIds.contains(
                        workflow.workflowId,
                      ),
                      onTap: onSelectCalendarDate == null
                          ? null
                          : () =>
                              onSelectCalendarDate!(workflow.workflowId),
                      onToggleReminder: onToggleReminder == null
                          ? null
                          : () =>
                              onToggleReminder!(workflow.workflowId),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
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
    this.onTap,
    this.onToggleReminder,
  });

  final LoomWorkflowDefinition workflow;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final bool isFocused;
  final bool reminderEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onToggleReminder;

  @override
  Widget build(BuildContext context) {
    if (isFocused) {
      return _CalendarEventDetail(
        accent: accent,
        modernTheme: modernTheme,
        workflow: workflow,
        reminderEnabled: reminderEnabled,
        onToggleReminder: onToggleReminder,
      );
    }
    final foreground =
        modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final item = workflow.calendarItem!;
    return InkWell(
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

class _CalendarEventDetail extends StatelessWidget {
  const _CalendarEventDetail({
    required this.accent,
    this.modernTheme,
    required this.workflow,
    this.reminderEnabled = false,
    this.onToggleReminder,
  });

  final Color accent;
  final LoomCardTheme? modernTheme;
  final LoomWorkflowDefinition workflow;
  final bool reminderEnabled;
  final VoidCallback? onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ??
        Color.alphaBlend(foreground.withValues(alpha: 0.08), accent);
    final border = modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    final item = workflow.calendarItem!;
    final facts = <String>[
      _formatEventDateTime(item.dateTime),
      if (item.host != null) item.host!,
      if (item.location != null) item.location!,
      if (item.capacityLabel != null) item.capacityLabel!,
    ];
    return DecoratedBox(
      key: ValueKey('calendar-event-detail-${workflow.workflowId}'),
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
                    _displayTitleFor(workflow),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onToggleReminder != null)
                  IconButton(
                    key: ValueKey(
                      'calendar-reminder-toggle-${workflow.workflowId}',
                    ),
                    tooltip: reminderEnabled
                        ? 'Turn off reminder'
                        : 'Remind me',
                    onPressed: onToggleReminder,
                    icon: Icon(
                      reminderEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_none_outlined,
                      color: foreground,
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
                if (reminderEnabled)
                  _SurfaceFactPill(
                    icon: Icons.notifications_active,
                    label: 'Reminder set',
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

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[(weekday - 1).clamp(0, 6)];
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
    required this.accent,
    this.modernTheme,
    this.onConfirmWorkflow,
    this.marketplaceTemplate,
    this.workflows = const [],
    this.personaId = 'tabletop-member',
  });

  final List<LoomMarketplaceListing> listings;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final ValueChanged<LoomWorkflowDefinition>? onConfirmWorkflow;
  final LoomListingStateMachine? marketplaceTemplate;
  final List<LoomWorkflowDefinition> workflows;
  final String personaId;

  @override
  State<_MarketplaceBrowseSurface> createState() =>
      _MarketplaceBrowseSurfaceState();
}

class _MarketplaceBrowseSurfaceState extends State<_MarketplaceBrowseSurface> {
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedListingId;
  late final Map<String, LoomMarketplaceListing> _mutableListings;

  @override
  void initState() {
    super.initState();
    _mutableListings = {
      for (final l in widget.listings) l.listingId: l,
    };
  }

  List<LoomMarketplaceListing> get _filteredListings {
    var listings = _mutableListings.values.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      listings =
          listings
              .where(
                (l) => l.title.toLowerCase().contains(q) ||
                    (l.description?.toLowerCase().contains(q) ?? false),
              )
              .toList();
    }
    if (_selectedCategory != null) {
      listings =
          listings
              .where((l) => l.category == _selectedCategory)
              .toList();
    }
    return listings;
  }

  LoomMarketplaceListing? get _selectedListing {
    if (_selectedListingId == null) return null;
    return _mutableListings[_selectedListingId];
  }

  LoomWorkflowDefinition? _resolveWorkflow(String workflowId) {
    try {
      return widget.workflows.firstWhere((w) => w.workflowId == workflowId);
    } catch (_) {
      return null;
    }
  }

  List<LoomListingTransition> _actionsFor(LoomMarketplaceListing listing) {
    // Resolve per-listing: listing's own stateMachine → community template
    final machine = listing.stateMachine ?? widget.marketplaceTemplate;
    if (machine == null) return [];
    final currentState = listing.state ?? listing.availability;
    return machine.availableActions(currentState, widget.personaId);
  }

  void _applyTransition(LoomMarketplaceListing listing, LoomListingTransition transition) {
    final current = _mutableListings[listing.listingId];
    if (current == null) return;
    var updated = current;

    if (transition.to != null) {
      updated = updated.copyWith(availability: transition.to!);
    }
    if (transition.setsHolderToActor) {
      updated = updated.copyWith(currentHolderLabel: 'You (Member)');
    }
    if (transition.clearsHolder) {
      updated = updated.copyWith(currentHolderLabel: null);
    }
    if (transition.incrementsQueue) {
      updated = updated.copyWith(queueLength: current.queueLength + 1);
    }
    if (transition.decrementsQueue) {
      updated = updated.copyWith(queueLength: (current.queueLength - 1).clamp(0, 999));
    }
    if (transition.removesFromList) {
      setState(() => _mutableListings.remove(listing.listingId));
      return;
    }
    setState(() => _mutableListings[listing.listingId] = updated);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final listing = _selectedListing;
    if (listing != null) {
      final actions = _actionsFor(listing);
      return _ListingDetailView(
        listing: listing,
        foreground: foreground,
        accent: widget.accent,
        modernTheme: widget.modernTheme,
        onBack: () => setState(() => _selectedListingId = null),
        onConfirmWorkflow: widget.onConfirmWorkflow,
        resolveWorkflow: _resolveWorkflow,
        engineActions: actions,
        onTransitionApplied: (transition) => _applyTransition(listing, transition),
      );
    }
    final filtered = _filteredListings;
    final categories = <String>{
      for (final l in _mutableListings.values)
        if (l.category != null) l.category!,
    };
    final fill = widget.modernTheme?.resolvedFill ?? widget.accent;
    final border = widget.modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    return Column(
      key: const ValueKey('marketplace-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            key: const ValueKey('marketplace-search-field'),
            style: TextStyle(color: foreground),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: foreground),
              hintText: 'Search available items',
              hintStyle: TextStyle(
                color: foreground.withValues(alpha: 0.60),
              ),
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
        // Category filter chips
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
                      backgroundColor:
                          _selectedCategory == cat
                              ? (widget.modernTheme?.accent ?? widget.accent)
                              : foreground.withValues(alpha: 0.10),
                      labelStyle: TextStyle(
                        color:
                            _selectedCategory == cat
                                ? Colors.white
                                : foreground,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color:
                            _selectedCategory == cat
                                ? (widget.modernTheme?.accent ??
                                    widget.accent)
                                : border,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        // Grid — uses a fixed height via LayoutBuilder so it works inside
        // the community SingleChildScrollView as well as standalone.
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
              // Compute needed height from item count + spacing.
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
                    return _ListingCard(
                      listing: item,
                      foreground: foreground,
                      fill: fill,
                      border: border,
                      accent: widget.accent,
                      modernTheme: widget.modernTheme,
                      onTap: () =>
                          setState(() => _selectedListingId = item.listingId),
                    );
                  },
                ),
              );
            },
          ),
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
        _TabNativeSummary(
          icon: Icons.description_outlined,
          title: '${experience.displayName} document library',
          body:
              'Library categories, document details, embedded open, external open, versions, and access state are grouped here.',
          accent: accent,
          modernTheme: modernTheme,
          facts: const [
            'Library',
            'Embedded open',
            'External open',
            'Versions',
          ],
        ),
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

