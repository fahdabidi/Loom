part of '../loom_communities_app_shell.dart';

class _CommunityWorkflowSection {
  const _CommunityWorkflowSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.workflows,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<LoomWorkflowDefinition> workflows;
}

List<_CommunityWorkflowSection> _communitySectionsFor(
  LoomExperienceDefinition experience,
) {
  final groups = <String, List<LoomWorkflowDefinition>>{};
  for (final workflow in experience.workflows) {
    groups.putIfAbsent(_sectionTitleFor(workflow), () => []).add(workflow);
  }
  return [
    for (final title in _orderedSectionTitles)
      if ((groups[title] ?? const []).isNotEmpty)
        _CommunityWorkflowSection(
          title: title,
          subtitle: _sectionSubtitleFor(title, experience),
          icon: _sectionIconFor(title),
          workflows: groups[title]!,
        ),
  ];
}

List<_CommunityWorkflowSection> _communitySectionsForTab({
  required LoomExperienceDefinition experience,
  required LoomAppShellTabSpec tab,
}) {
  if (tab.tabId == 'home') {
    return _communitySectionsFor(experience);
  }
  final matchingWorkflows = [
    for (final workflow in experience.workflows)
      if (tab.matchesWorkflow(
        extensionId: experience.extensionId,
        workflow: workflow,
      ))
        workflow,
  ];
  final pinned = {
    for (final workflow in matchingWorkflows)
      if (tab.pinnedWorkflowIds.contains(workflow.workflowId)) workflow,
  };
  final orderedWorkflows = [
    ...pinned,
    for (final workflow in matchingWorkflows)
      if (!pinned.contains(workflow)) workflow,
  ];
  final groups = <String, List<LoomWorkflowDefinition>>{};
  for (final workflow in orderedWorkflows) {
    groups.putIfAbsent(_sectionTitleFor(workflow), () => []).add(workflow);
  }
  return [
    for (final title in _orderedSectionTitles)
      if ((groups[title] ?? const []).isNotEmpty)
        _CommunityWorkflowSection(
          title: title,
          subtitle: _sectionSubtitleFor(title, experience),
          icon: _sectionIconFor(title),
          workflows: groups[title]!,
        ),
  ];
}

const List<String> _orderedSectionTitles = [
  'Announcements',
  'Upcoming events',
  'Knowledge and search',
  'Sponsored placement',
  'Ad-free account',
  'Giving',
  'Care and volunteers',
  'Requests and approvals',
  'Documents and data',
  'Messages and connections',
  'Member tools',
];

IconData _communityIconFor(String extensionId) {
  switch (extensionId) {
    case 'ext_garden_club':
      return Icons.local_florist_outlined;
    case 'ext_book_club':
      return Icons.menu_book_outlined;
    case 'ext_youth_soccer':
      return Icons.sports_soccer_outlined;
    case 'ext_hoa':
      return Icons.apartment_outlined;
    case 'ext_mosque':
      return Icons.volunteer_activism_outlined;
    case 'ext_chess_club':
      return Icons.extension_outlined;
    case 'ext_camera_club':
      return Icons.photo_camera_outlined;
    case 'ext_platform_social':
      return Icons.forum_outlined;
    case 'ext_ad_off':
      return Icons.block_outlined;
    case 'ext_export_migration':
      return Icons.import_export_outlined;
  }
  return Icons.groups_outlined;
}

String _sectionTitleFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  final title = workflow.title.toLowerCase();
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return 'Knowledge and search';
  }
  if (id.contains('in-stream-ad') ||
      id.contains('top-banner') ||
      id.contains('no-fill') ||
      id.contains('sensitive-no-fill') ||
      id.contains('sponsor')) {
    return 'Sponsored placement';
  }
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification') ||
      id.contains('reminder')) {
    return 'Announcements';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('schedule') ||
      title.contains('event') ||
      title.contains('photo-walk')) {
    return 'Upcoming events';
  }
  if (id.contains('ad-off')) {
    return 'Ad-free account';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      title.contains('receipt') ||
      title.contains('reservation')) {
    return 'Giving';
  }
  if (id.contains('care') ||
      id.contains('volunteer') ||
      id.contains('signup') ||
      id.contains('submission') ||
      id.contains('exchange')) {
    return 'Care and volunteers';
  }
  if (id.contains('approval') ||
      id.contains('decision') ||
      id.contains('review') ||
      id.contains('request')) {
    return 'Requests and approvals';
  }
  if (id.contains('document') ||
      id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('redaction') ||
      id.contains('checksum')) {
    return 'Documents and data';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite') ||
      id.contains('blocked')) {
    return 'Messages and connections';
  }
  return 'Member tools';
}

String _sectionSubtitleFor(String title, LoomExperienceDefinition experience) {
  switch (title) {
    case 'Announcements':
      return 'Updates, reminders, and member notices for ${experience.displayName}.';
    case 'Upcoming events':
      return 'Dates, capacity, and attendance actions.';
    case 'Giving':
      return 'Payments, donations, receipts, and member preferences.';
    case 'Knowledge and search':
      return 'Cited answers, source visibility, and saved digests.';
    case 'Sponsored placement':
      return 'Reserved ad slots, disclosures, no-fill state, and member controls.';
    case 'Care and volunteers':
      return 'Private requests, volunteer shifts, and member support.';
    case 'Requests and approvals':
      return 'Requests that need a decision or member follow-up.';
    case 'Documents and data':
      return 'Documents, exports, imports, and transfer records.';
    case 'Messages and connections':
      return 'Member communication and relationship controls.';
  }
  return 'Useful actions for this community.';
}

IconData _sectionIconFor(String title) {
  switch (title) {
    case 'Announcements':
      return Icons.campaign_outlined;
    case 'Upcoming events':
      return Icons.event_outlined;
    case 'Giving':
      return Icons.volunteer_activism_outlined;
    case 'Knowledge and search':
      return Icons.manage_search_outlined;
    case 'Sponsored placement':
      return Icons.campaign_outlined;
    case 'Care and volunteers':
      return Icons.handshake_outlined;
    case 'Requests and approvals':
      return Icons.task_alt_outlined;
    case 'Documents and data':
      return Icons.folder_open_outlined;
    case 'Messages and connections':
      return Icons.forum_outlined;
  }
  return Icons.apps_outlined;
}

class _CommunitySectionHeader extends StatelessWidget {
  const _CommunitySectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.modernTheme,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = modernTheme?.resolvedHeading ?? Colors.white;
    final fill = modernTheme?.resolvedFill ?? accent;
    final body = modernTheme?.resolvedBody ?? foreground.withValues(alpha: 0.88);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: modernTheme != null
            ? Border.all(color: modernTheme!.resolvedBorder)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
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

