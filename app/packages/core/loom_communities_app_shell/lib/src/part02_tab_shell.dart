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
      case 'CareVolunteerTabSurface':
      case 'AdminReviewComposeTabSurface':
        // These domain tabs render via placeholder until their data is declared
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
      'cadence': widget.givingPayment.cadence ?? '',
      'entitlement': widget.givingPayment.entitlement ?? '',
      'receiptStatus': '',
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
          guard: const WorkflowGuard(
            allowedPersonaIds: ['tabletop-member', 'tabletop-organizer'],
          ),
          effects: const [
            WorkflowEffect(op: 'set', key: 'receiptStatus', value: 'complete'),
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
                  availableTransitions: _paymentActions(),
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
        else
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
