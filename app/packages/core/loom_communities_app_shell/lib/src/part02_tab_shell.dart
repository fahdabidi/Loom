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

class _MessagesTabSurface extends StatelessWidget {
  const _MessagesTabSurface({
    required this.experience,
    required this.persona,
    required this.accent,
    this.modernTheme,
    this.sections = const [],
    this.workflowBuilder,
    this.focusedWorkflowId,
    this.expandedWorkflowId,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final List<_CommunityWorkflowSection> sections;
  final _WorkflowSurfaceBuilder? workflowBuilder;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;

  @override
  Widget build(BuildContext context) {
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final fill = modernTheme?.resolvedFill ?? accent;
    final body = modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.92);
    final messageWorkflows = [
      for (final section in sections)
        for (final workflow in section.workflows) workflow,
    ];
    return DecoratedBox(
      key: const ValueKey('messages-tab-surface'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_outlined, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${experience.displayName} messages',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${persona.label} can continue community threads, member messages, and connection invites for ${experience.displayName}.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: body,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.mark_chat_unread_outlined,
                  label: 'Threads',
                  foreground: foreground,
                ),
                _SurfaceFactPill(
                  icon: Icons.people_alt_outlined,
                  label: 'Connections',
                  foreground: foreground,
                ),
                _SurfaceFactPill(
                  icon: Icons.notifications_active_outlined,
                  label: 'Unread state',
                  foreground: foreground,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InboxPreviewCard(
              accent: accent,
              modernTheme: modernTheme,
              title: '${experience.displayName} coordination',
              sender: persona.label,
              preview:
                  'Unread updates, replies, invites, and action follow-up stay in one conversation surface.',
              timestamp: 'Today',
            ),
            const SizedBox(height: 12),
            _ThreadComposerPreview(accent: accent, modernTheme: modernTheme),
            if (messageWorkflows.isNotEmpty && workflowBuilder != null) ...[
              const SizedBox(height: 14),
              for (final workflow in messageWorkflows)
                workflowBuilder!(
                  workflow,
                  _presentationStateForWorkflow(
                    workflowId: workflow.workflowId,
                    focusedWorkflowId: focusedWorkflowId,
                    expandedWorkflowId: expandedWorkflowId,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final rendererId = selectedTab.rendererContract.rendererId;
    final modernTheme = theme.usesModernCardTheme ? theme.tabCard : null;
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
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          workflowBuilder: workflowBuilder,
        );
      case 'MarketplaceTabSurface':
        return _MarketplaceTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
        );
      case 'DocumentsTabSurface':
        return _DocumentsTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
        );
      case 'WorkflowStatusSurface':
        return _WorkflowStatusTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
        );
      case 'PaymentGivingTabSurface':
        return _PaymentGivingTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
        );
      case 'CareVolunteerTabSurface':
        return _CareVolunteerTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
        );
      case 'AdminReviewComposeTabSurface':
        return _AdminReviewComposeTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          modernTheme: modernTheme,
          workflowBuilder: workflowBuilder,
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
    return Column(
      key: const ValueKey('calendar-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarAgendaDateStrip(
          accent: accent,
          modernTheme: modernTheme,
          items: datedWorkflows,
          selectedWorkflowId: selectedDated.workflowId,
          onSelectWorkflow: onSelectCalendarDate,
        ),
        const SizedBox(height: 12),
        _CalendarEventDetail(
          accent: accent,
          modernTheme: modernTheme,
          workflow: selectedDated,
          reminderEnabled: reminderEnabledWorkflowIds.contains(
            selectedDated.workflowId,
          ),
          onToggleReminder: onToggleReminder == null
              ? null
              : () => onToggleReminder!(selectedDated.workflowId),
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

class _MarketplaceTabSurface extends StatelessWidget {
  const _MarketplaceTabSurface({
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
        icon: Icons.storefront_outlined,
        title: 'No listings yet',
        body:
            'Listings, loans, queues, and giveaways for ${experience.displayName} will appear here.',
        accent: accent,
        modernTheme: modernTheme,
      );
    }
    return Column(
      key: const ValueKey('marketplace-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MarketplaceSearchHeader(accent: accent, modernTheme: modernTheme),
        const SizedBox(height: 12),
        _TabNativeSummary(
          icon: Icons.inventory_2_outlined,
          title: '${experience.displayName} marketplace',
          body:
              'Browse available items, inspect listing details, join a queue, see current-holder state, or list an item.',
          accent: accent,
          modernTheme: modernTheme,
          facts: const ['Browse', 'Search', 'List item', 'Queue', 'Holder'],
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

class _MarketplaceSearchHeader extends StatelessWidget {
  const _MarketplaceSearchHeader({required this.accent, this.modernTheme});

  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      key: const ValueKey('marketplace-browse-search'),
      decoration: BoxDecoration(
        color: modernTheme?.resolvedFill ?? Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: modernTheme?.resolvedBorder ?? accent.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: accent),
                hintText: 'Search available items',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SurfaceFactPill(
                  icon: Icons.inventory_2_outlined,
                  label: 'Available',
                  foreground: accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.schedule_outlined,
                  label: 'Queue',
                  foreground: accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.person_pin_circle_outlined,
                  label: 'Current holder',
                  foreground: accent,
                ),
                _SurfaceFactPill(
                  icon: Icons.add_box_outlined,
                  label: 'List item',
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

