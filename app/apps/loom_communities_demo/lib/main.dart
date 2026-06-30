import 'package:flutter/material.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const bool _preloadExampleCommunities = bool.fromEnvironment(
  'LOOM_PRELOAD_EXAMPLE_COMMUNITIES',
);

void main() {
  runApp(const LoomCommunitiesDemoApp());
}

class LoomCommunitiesDemoApp extends StatelessWidget {
  const LoomCommunitiesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loom Communities Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff246b62)),
        scaffoldBackgroundColor: const Color(0xfffbfffd),
        useMaterial3: true,
      ),
      home: const LoomCommunitiesHome(),
    );
  }
}

class LoomCommunitiesHome extends StatefulWidget {
  const LoomCommunitiesHome({super.key});

  @override
  State<LoomCommunitiesHome> createState() => _LoomCommunitiesHomeState();
}

class _LoomCommunitiesHomeState extends State<LoomCommunitiesHome> {
  late final LocalInAppBackend _backend;
  late final Map<String, List<String>> _importedSeedFilesByCommunityId;
  String? _lastLocalImportMessage;

  @override
  void initState() {
    super.initState();
    _backend = LocalInAppBackend(
      snapshot: _preloadExampleCommunities
          ? _preloadedExampleCommunitiesSnapshot()
          : null,
    );
    _importedSeedFilesByCommunityId = _preloadExampleCommunities
        ? _preloadedSeedFilesByCommunityId()
        : {};
    _lastLocalImportMessage = _preloadExampleCommunities
        ? 'Loaded ${loomEvidenceTargets.length} example communities'
        : null;
  }

  Future<void> _showLocalPackageLoader() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _LocalPackageLoaderDialog(onInstall: _installLocalPackagePair);
      },
    );
  }

  String? _installLocalPackagePair({
    required String extensionPackagePath,
    required String initializationPackagePath,
  }) {
    late final LocalBackendImportReport report;
    try {
      report = _backend.installLocalPackagePairFromFiles(
        extensionPackagePath: extensionPackagePath,
        initializationPackagePath: initializationPackagePath,
      );
    } on StateError catch (error) {
      return error.message;
    }
    setState(() {
      _importedSeedFilesByCommunityId[report.community.communityId] =
          report.importedSeedFiles;
      _lastLocalImportMessage = reportMessage(
        communityName: report.community.displayName,
        created: report.created,
      );
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final communities = _backend.listCommunities();
    return Scaffold(
      appBar: AppBar(title: const Text('Loom Communities')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-community-button'),
        onPressed: _showLocalPackageLoader,
        icon: const Icon(Icons.add),
        label: const Text('Add Community'),
      ),
      body: communities.isEmpty
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyCommunityState(
                    onAddCommunity: _showLocalPackageLoader,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                if (_lastLocalImportMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: MaterialBanner(
                      key: const ValueKey('local-import-status'),
                      content: Text(_lastLocalImportMessage!),
                      leading: const Icon(Icons.check_circle_outline),
                      actions: const [SizedBox.shrink()],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey('community-list'),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                    itemCount: communities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      final experience = experienceForExtensionId(
                        community.extensionId,
                        displayName: community.displayName,
                      );
                      return Card(
                        child: ListTile(
                          key: ValueKey(
                            'community-card-${community.communityId}',
                          ),
                          title: Text(community.displayName),
                          subtitle: Text(experience.tagline),
                          leading: CircleAvatar(
                            key: ValueKey(
                              'community-card-identity-${community.communityId}',
                            ),
                            backgroundColor: Color(
                              experience.accentColor,
                            ).withValues(alpha: 0.18),
                            child: Icon(
                              _communityIconFor(experience.extensionId),
                              color: Color(experience.accentColor),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (context) => _LocalExtensionScreen(
                                  community: community,
                                  seedDataFiles:
                                      _importedSeedFilesByCommunityId[community
                                          .communityId] ??
                                      const [],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String reportMessage({required String communityName, required bool created}) {
    return created
        ? 'Installed $communityName from local packages'
        : 'Updated $communityName from local packages';
  }
}

class _LocalExtensionScreen extends StatefulWidget {
  const _LocalExtensionScreen({
    required this.community,
    required this.seedDataFiles,
  });

  final LocalInstalledCommunity community;
  final List<String> seedDataFiles;

  @override
  State<_LocalExtensionScreen> createState() => _LocalExtensionScreenState();
}

class _LocalExtensionScreenState extends State<_LocalExtensionScreen> {
  final Set<String> _completedWorkflowIds = {};
  final Set<String> _receivedWorkflowPersonaKeys = {};
  String? _selectedPersonaId;

  LocalInstalledCommunity get community => widget.community;
  List<String> get seedDataFiles => widget.seedDataFiles;
  String get _route => 'local:${community.extensionId}@latest';

  LoomPersonaDefinition _activePersona(LoomExperienceDefinition experience) {
    final personas = personasForExtensionId(experience.extensionId);
    final selectedPersonaId = _selectedPersonaId;
    if (selectedPersonaId != null) {
      for (final persona in personas) {
        if (persona.personaId == selectedPersonaId) {
          return persona;
        }
      }
    }
    return personas.first;
  }

  Future<void> _confirmWorkflow(LoomWorkflowDefinition workflow) async {
    final contract = productionWorkflowContractFor(
      extensionId: community.extensionId,
      workflow: workflow,
    );
    final confirmed =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            fullscreenDialog: true,
            builder: (context) => _WorkflowActionSurface(
              key: ValueKey('workflow-action-surface-${workflow.workflowId}'),
              workflow: workflow,
              contract: contract,
              actionLabel: contract.primaryActionLabel,
              confirmButtonKey: ValueKey(
                'workflow-action-submit-${workflow.workflowId}',
              ),
              isReceiverSurface: false,
            ),
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    setState(() {
      _completedWorkflowIds.add(workflow.workflowId);
    });
  }

  Future<void> _receiveWorkflow({
    required LoomWorkflowDefinition workflow,
    required LoomPersonaDefinition persona,
    required LoomWorkflowPersonaPolicy policy,
  }) async {
    final contract = productionWorkflowContractFor(
      extensionId: community.extensionId,
      workflow: workflow,
    );
    final confirmed =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            fullscreenDialog: true,
            builder: (context) => _WorkflowActionSurface(
              key: ValueKey('workflow-receive-surface-${workflow.workflowId}'),
              workflow: workflow,
              contract: contract,
              actionLabel: _receiverActionLabel(
                workflow: workflow,
                policy: policy,
              ),
              confirmButtonKey: ValueKey(
                'workflow-receive-submit-${workflow.workflowId}',
              ),
              isReceiverSurface: true,
            ),
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    setState(() {
      _receivedWorkflowPersonaKeys.add(
        workflowPersonaReceiptKey(
          workflowId: workflow.workflowId,
          personaId: persona.personaId,
        ),
      );
    });
  }

  Future<void> _showPersonaPicker(
    LoomExperienceDefinition experience,
    LoomPersonaDefinition activePersona,
  ) async {
    final personas = personasForExtensionId(experience.extensionId);
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          key: const ValueKey('persona-picker-dialog'),
          title: const Text('Choose persona'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Preview the community experience for each member role.',
                  ),
                  const SizedBox(height: 8),
                  for (final persona in personas)
                    ListTile(
                      key: ValueKey('persona-option-${persona.personaId}'),
                      selected: persona.personaId == activePersona.personaId,
                      leading: Icon(
                        persona.personaId == activePersona.personaId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(persona.label),
                      subtitle: Text(
                        '${persona.roleLabel} - ${persona.description}',
                      ),
                      onTap: () => Navigator.of(context).pop(persona.personaId),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedPersonaId = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
    );
    final activePersona = _activePersona(experience);
    final textTheme = Theme.of(context).textTheme;
    final accent = Color(experience.accentColor);
    final background = _screenBackgroundFor(accent);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(community.displayName),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const ValueKey('messages-button'),
            tooltip: 'Messages',
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            key: const ValueKey('persona-picker-button'),
            tooltip: 'Personas',
            onPressed: () => _showPersonaPicker(experience, activePersona),
            icon: const Icon(Icons.people_outline),
          ),
        ],
      ),
      body: ListView(
        key: ValueKey('local-extension-${community.extensionId}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.campaign_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No sponsored message right now.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        key: ValueKey(
                          'opened-community-identity-${community.communityId}',
                        ),
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: Icon(
                          _communityIconFor(experience.extensionId),
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.displayName,
                              key: ValueKey(
                                'opened-community-${community.communityId}',
                              ),
                              style: textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              experience.tagline,
                              key: ValueKey(
                                'experience-tagline-${community.extensionId}',
                              ),
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _PersonaStatusStrip(
                    persona: activePersona,
                    personaCount: personasForExtensionId(
                      experience.extensionId,
                    ).length,
                    foreground: Colors.white,
                  ),
                  Offstage(
                    child: Text(
                      _route,
                      key: ValueKey('opened-route-${community.extensionId}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          for (final section in _communitySectionsFor(experience)) ...[
            _CommunitySectionHeader(
              title: section.title,
              subtitle: section.subtitle,
              icon: section.icon,
              accent: accent,
            ),
            const SizedBox(height: 8),
            for (final workflow in section.workflows)
              Builder(
                builder: (context) {
                  final policy = personaPolicyForWorkflow(
                    experience.extensionId,
                    workflow.workflowId,
                  );
                  final view = personaWorkflowViewFor(
                    extensionId: experience.extensionId,
                    workflow: workflow,
                    personaId: activePersona.personaId,
                    completedWorkflowIds: _completedWorkflowIds,
                    receivedWorkflowPersonaKeys: _receivedWorkflowPersonaKeys,
                  );
                  return _WorkflowTile(
                    extensionId: experience.extensionId,
                    workflow: workflow,
                    view: view,
                    onPressed: () => _confirmWorkflow(workflow),
                    onReceivePressed: () => _receiveWorkflow(
                      workflow: workflow,
                      persona: activePersona,
                      policy: policy,
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 24),
          ExpansionTile(
            title: const Text('Local package details'),
            leading: const Icon(Icons.inventory_2_outlined),
            collapsedTextColor: Colors.white,
            collapsedIconColor: Colors.white,
            textColor: Colors.white,
            iconColor: Colors.white,
            children: [
              _ExtensionInfoTile(
                icon: Icons.extension_outlined,
                title: 'Package',
                value: community.extensionId,
              ),
              _ExtensionInfoTile(
                icon: Icons.palette_outlined,
                title: 'Accent',
                value: community.accentColor,
              ),
              _ExtensionInfoTile(
                icon: Icons.image_outlined,
                title: 'Card image',
                value: community.cardImageAssetId ?? 'generated fallback',
              ),
              if (seedDataFiles.isEmpty)
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.description_outlined),
                  title: Text('No seed files recorded.'),
                )
              else
                for (final seedDataFile in seedDataFiles)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(seedDataFile),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

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

const List<String> _orderedSectionTitles = [
  'Announcements',
  'Upcoming events',
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
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification') ||
      id.contains('reminder') ||
      id.contains('digest') ||
      id.contains('search-ai')) {
    return 'Announcements';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('schedule') ||
      title.contains('event') ||
      title.contains('photo-walk')) {
    return 'Upcoming events';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off') ||
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
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

class _WorkflowTile extends StatelessWidget {
  const _WorkflowTile({
    required this.extensionId,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final String extensionId;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final complete = view.completed || view.received;
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    final metadata = _domainMetadataFor(contract.category, workflow);
    final scheme = Theme.of(context).colorScheme;
    final accent = _categoryAccentColor(contract.category, scheme);
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                  complete
                      ? Icons.check_circle_outline
                      : view.state == LoomPersonaWorkflowState.receiver
                      ? Icons.notifications_none
                      : view.state == LoomPersonaWorkflowState.actor
                      ? Icons.radio_button_unchecked
                      : view.state == LoomPersonaWorkflowState.readOnly
                      ? Icons.visibility_outlined
                      : Icons.radio_button_unchecked,
                  color: foreground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayTitleFor(workflow),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _domainSummaryFor(contract.category, workflow, view),
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final detail in metadata)
                            _SurfaceFactPill(
                              icon: _metadataIconFor(detail),
                              label: detail,
                              foreground: foreground,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _InteractionModelSummary(
                        contract: contract,
                        foreground: foreground,
                      ),
                      Offstage(
                        child: Text(
                          view.personaRationale,
                          key: ValueKey(
                            'workflow-persona-state-${workflow.workflowId}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: contract.successTitle,
                body:
                    '${contract.resultSummary} ${contract.receiverStateSummary}',
                icon: contract.icon,
                accent: accent,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: contract.receiverSurfaceTitle,
                body:
                    '${_receiverBodyFor(contract.category)} ${contract.receiverStateSummary}',
                icon: Icons.inbox_outlined,
                accent: accent,
              )
            else
              _WorkflowAction(
                contract: contract,
                workflow: workflow,
                view: view,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            if (view.completed)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-complete-${workflow.workflowId}'),
                  icon: Icons.done,
                  label: contract.successChipLabel,
                  foreground: foreground,
                ),
              ),
            if (view.received)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-received-${workflow.workflowId}'),
                  icon: Icons.mark_email_read_outlined,
                  label: 'Received',
                  foreground: foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _foregroundFor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

Color _screenBackgroundFor(Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.42), Colors.black);
}

class _InteractionModelSummary extends StatelessWidget {
  const _InteractionModelSummary({
    required this.contract,
    required this.foreground,
  });

  final LoomProductionWorkflowContract contract;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contract.decisionSummary,
              style: textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SurfaceFactPill(
                  icon: Icons.compare_arrows_outlined,
                  label: contract.alternateActionLabel,
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

class _SurfaceFactPill extends StatelessWidget {
  const _SurfaceFactPill({
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayTitleFor(LoomWorkflowDefinition workflow) {
  switch (workflow.workflowId) {
    case 'hoa-committee-decision':
      return 'Committee decision';
    case 'hoa-export-evidence':
      return 'HOA export';
    case 'ad-off-receipt-evidence':
      return 'Receipt history';
    case 'export-checksum-evidence':
      return 'Checksum record';
    case 'platform-messages-entry':
      return 'Messages';
    case 'platform-connections-entry':
      return 'Connections';
    case 'platform-in-stream-ad':
      return 'Sponsored message';
    case 'platform-top-banner-no-fill':
      return 'Top banner status';
    case 'platform-sensitive-no-fill':
      return 'Sensitive page ad status';
    case 'chess-route-home':
      return 'Chess Club home';
  }

  var title = workflow.title
      .replaceAll(RegExp(r'\bworkflow\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\bevidence\b', caseSensitive: false), 'record')
      .replaceAll(RegExp(r'\bsurface\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (title.isEmpty) {
    title = 'Community item';
  }
  return title.substring(0, 1).toUpperCase() + title.substring(1);
}

String _domainSummaryFor(
  String category,
  LoomWorkflowDefinition workflow,
  LoomPersonaWorkflowView view,
) {
  if (view.waitingForPrerequisite) {
    return _waitingSummaryFor(category);
  }
  if (view.state == LoomPersonaWorkflowState.disabled) {
    return 'Another community role manages this item.';
  }
  if (view.state == LoomPersonaWorkflowState.readOnly) {
    return 'You can review the current details without changing them.';
  }
  if (view.state == LoomPersonaWorkflowState.receiver) {
    switch (category) {
      case 'Event':
        return 'An event update is ready with your attendance status.';
      case 'Payment':
        return 'A receipt or giving preference is ready to review.';
      case 'Publishing':
        return 'A community update is ready in your inbox.';
      case 'Approval':
        return 'A decision update is ready with next steps.';
      case 'Portability':
        return 'A data package update is ready to inspect.';
      case 'Platform':
        return 'A member communication or preference update is ready.';
      case 'Form':
        return 'A submitted member form is ready for review and follow-up.';
    }
    return 'A community update is ready to review.';
  }

  final id = workflow.workflowId;
  if (id.contains('announcement')) {
    return 'Draft message includes audience, timing, and delivery details.';
  }
  if (id.contains('notification')) {
    return 'Notification includes sender, audience, timestamp, message body, and receiver inbox state.';
  }
  if (id.contains('rsvp') || id.contains('event')) {
    return 'Event details include date, location, capacity, RSVP action, and attendance result.';
  }
  if (id.contains('practice') || id.contains('schedule')) {
    return 'Practice details include date, location, capacity, RSVP action, and confirmed result.';
  }
  if (id.contains('donation')) {
    return 'Record a 50.00 USD donation with receipt and privacy choices.';
  }
  if (id.contains('dues') || id.contains('payment')) {
    return 'Payment details include amount, payer, and receipt destination.';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'Volunteer details include shift, availability, and protected contact.';
  }
  if (id.contains('care')) {
    return 'Care request keeps private details protected for the care team.';
  }
  if (id.contains('request') || id.contains('approval')) {
    return 'Submitted details are ready for a decision and member follow-up.';
  }
  if (id.contains('minor-redaction') || id.contains('redaction')) {
    return 'Protected youth roster profile includes minor-data redaction, guardian visibility, and coach-only details.';
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('checksum')) {
    return 'Data package includes scope, protected fields, and handoff status.';
  }
  if (id.contains('document')) {
    return 'Community Rules document file is a PDF updated for members with access state.';
  }
  if (id.contains('no-fill')) {
    return 'Ad slot disclosure shows a no-fill state with no sponsored message overlapping content.';
  }
  if (id.contains('message') || id.contains('connection')) {
    return 'Member communication stays scoped to the community relationship.';
  }
  if (id.contains('ad')) {
    return 'Ad preference and sponsored-message behavior are ready to review.';
  }
  return 'Member form captures labeled details, privacy choices, and reviewer handoff.';
}

String _waitingSummaryFor(String category) {
  switch (category) {
    case 'Event':
      return 'Waiting for the organizer to publish the event update.';
    case 'Payment':
      return 'Waiting for the member payment or preference to be saved.';
    case 'Publishing':
      return 'Waiting for the announcement to be sent.';
    case 'Approval':
      return 'Waiting for the request to be submitted first.';
    case 'Portability':
      return 'Waiting for the export package to be prepared.';
    case 'Platform':
      return 'Waiting for the related member action.';
    case 'Form':
      return 'Waiting for the member form to be submitted.';
  }
  return 'Waiting for the first community action.';
}

List<String> _domainMetadataFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  final id = workflow.workflowId;
  if (id.contains('announcement')) {
    return const ['Members', 'Today', 'From admin', 'Inbox + push'];
  }
  if (id.contains('notification')) {
    return const ['From admin', 'Members', 'Today', 'Inbox + push'];
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('schedule')) {
    return const [
      'This week',
      'Community venue',
      'Capacity tracked',
      'RSVP available',
    ];
  }
  if (id.contains('donation')) {
    return const ['50.00 USD', 'Receipt saved', 'Private option'];
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return const ['Open shift', 'Contact protected', 'Coordinator notified'];
  }
  if (id.contains('care')) {
    return const ['Private details', 'Care team', 'Consent checked'];
  }
  if (id.contains('minor-redaction') || id.contains('redaction')) {
    return const ['Minor profile', 'Guardian visibility', 'Coach-only details'];
  }
  if (id.contains('document')) {
    return const ['Members access', 'PDF updated', 'File metadata'];
  }
  if (id.contains('no-fill')) {
    return const ['No-fill state', 'Ad disclosure', 'No sponsored'];
  }
  if (id.contains('ad')) {
    return const ['No ad shown', 'Preference saved', 'Receipt ready'];
  }

  switch (category) {
    case 'Event':
      return const ['This week', 'Community venue', 'Capacity tracked'];
    case 'Payment':
      return const ['Amount ready', 'Receipt saved', 'Member-owned'];
    case 'Publishing':
      return const ['Members', 'Today', 'From admin', 'Inbox + push'];
    case 'Approval':
      return const ['Needs decision', 'Private notes', 'Member notified'];
    case 'Portability':
      return const ['Redacted copy', 'Checksum ready', 'Exportable'];
    case 'Platform':
      return const ['Private by default', 'Membership scoped', 'Ready'];
    case 'Form':
      return const ['Labeled fields', 'Privacy checked', 'Review handoff'];
  }
  return const ['Labeled fields', 'Privacy checked', 'Review handoff'];
}

IconData _metadataIconFor(String detail) {
  final lower = detail.toLowerCase();
  if (lower.contains('receipt') || lower.contains('usd')) {
    return Icons.receipt_long_outlined;
  }
  if (lower.contains('private') ||
      lower.contains('protected') ||
      lower.contains('consent')) {
    return Icons.verified_user_outlined;
  }
  if (lower.contains('week') ||
      lower.contains('today') ||
      lower.contains('venue') ||
      lower.contains('shift')) {
    return Icons.event_outlined;
  }
  if (lower.contains('inbox') ||
      lower.contains('notified') ||
      lower.contains('members')) {
    return Icons.notifications_outlined;
  }
  if (lower.contains('export') ||
      lower.contains('checksum') ||
      lower.contains('copy')) {
    return Icons.folder_open_outlined;
  }
  return Icons.check_circle_outline;
}

String _receiverBodyFor(String category) {
  switch (category) {
    case 'Event':
      return 'Your attendance status and event details are saved.';
    case 'Payment':
      return 'The receipt or preference is available in your records.';
    case 'Publishing':
      return 'The update is now available in the member inbox.';
    case 'Approval':
      return 'The decision is available with the next step for the member.';
    case 'Portability':
      return 'The package status is available with redaction details.';
    case 'Platform':
      return 'The member communication state is up to date.';
  }
  return 'The community update is saved for this member.';
}

String _reviewDetailFor(String category) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee details are ready.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt details are ready.';
    case 'Publishing':
      return 'Message, audience, preview, and send timing are ready.';
    case 'Approval':
      return 'Request details, decision, and member follow-up are ready.';
    case 'Portability':
      return 'Data scope, protected fields, and handoff details are ready.';
    case 'Platform':
      return 'Member communication and preference details are ready.';
  }
  return 'Required details are ready.';
}

String _reviewCheckFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Receipt and privacy settings will be saved with the payment.';
    case 'Publishing':
      return 'Audience and delivery settings will be checked before sending.';
    case 'Portability':
      return 'Protected fields and checksum details will be checked.';
    case 'Platform':
      return 'Membership and privacy settings will be respected.';
  }
  return 'Required details will be checked before submission.';
}

String _reviewResultFor(String category) {
  switch (category) {
    case 'Event':
      return 'Attendance status will be updated.';
    case 'Payment':
      return 'A receipt will be saved.';
    case 'Publishing':
      return 'Members will receive the update.';
    case 'Approval':
      return 'The member will receive the decision.';
    case 'Portability':
      return 'The data package status will be updated.';
    case 'Platform':
      return 'The member setting will be updated.';
  }
  return 'The community record will be saved.';
}

String _reviewTrustFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Payment records stay tied to the member account and receipt history.';
    case 'Publishing':
      return 'Only the selected audience receives this update.';
    case 'Portability':
      return 'Protected data stays redacted before sharing.';
    case 'Platform':
      return 'Private member relationships stay scoped to this community.';
  }
  return 'Private member details stay protected.';
}

class _WorkflowAction extends StatelessWidget {
  const _WorkflowAction({
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _categoryAccentColor(contract.category, scheme);
    final foreground = _foregroundFor(accent);
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: foreground.withValues(alpha: 0.14),
      foregroundColor: foreground,
      iconColor: foreground,
      side: BorderSide(color: foreground.withValues(alpha: 0.28)),
    );
    if (view.waitingForPrerequisite) {
      return Align(
        alignment: Alignment.centerRight,
        child: _StateBadge(
          key: ValueKey('workflow-waiting-${workflow.workflowId}'),
          icon: Icons.schedule,
          label: view.waitingText,
          foreground: foreground,
        ),
      );
    }
    if (view.state == LoomPersonaWorkflowState.actor) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: ValueKey('workflow-button-${workflow.workflowId}'),
            onPressed: onPressed,
            style: buttonStyle,
            icon: Icon(contract.icon, size: 18),
            label: Text(view.actionText, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (view.state == LoomPersonaWorkflowState.receiver) {
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            key: ValueKey('workflow-receive-button-${workflow.workflowId}'),
            onPressed: onReceivePressed,
            style: buttonStyle,
            icon: const Icon(Icons.inbox_outlined, size: 18),
            label: Text(view.actionText, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (view.state == LoomPersonaWorkflowState.readOnly) {
      return Align(
        alignment: Alignment.centerRight,
        child: _StateBadge(
          key: ValueKey('workflow-read-only-${workflow.workflowId}'),
          icon: Icons.visibility_outlined,
          label: 'Read only',
          foreground: foreground,
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: _StateBadge(
        key: ValueKey('workflow-disabled-${workflow.workflowId}'),
        icon: Icons.block,
        label: view.actionText,
        foreground: foreground,
      ),
    );
  }
}

class _WorkflowActionSurface extends StatelessWidget {
  const _WorkflowActionSurface({
    super.key,
    required this.workflow,
    required this.contract,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final LoomProductionWorkflowContract contract;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _categoryAccentColor(contract.category, scheme);
    final foreground = _foregroundFor(accent);
    final metadata = _domainMetadataFor(contract.category, workflow);
    final title = isReceiverSurface
        ? contract.receiverSurfaceTitle
        : contract.screenTitle;

    return Scaffold(
      backgroundColor: _screenBackgroundFor(accent),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(contract.icon, color: scheme.onPrimary, size: 34),
                  const SizedBox(height: 14),
                  Text(
                    _domainSurfaceTitleFor(contract.category, workflow),
                    style: textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _domainSurfaceLeadFor(
                      contract.category,
                      workflow,
                      isReceiverSurface: isReceiverSurface,
                    ),
                    style: textTheme.bodyLarge?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final detail in metadata)
                        _SurfaceFactPill(
                          icon: _metadataIconFor(detail),
                          label: detail,
                          foreground: scheme.onPrimary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ActionSurfaceDetailStack(
            accent: accent,
            rows: [
              _ActionSurfaceDetail(
                icon: Icons.rule_folder_outlined,
                title: 'Decision',
                body: contract.decisionSummary,
              ),
              _ActionSurfaceDetail(
                icon: Icons.edit_note_outlined,
                title: 'Details',
                body:
                    '${contract.inputSummary} ${_surfaceInputFor(contract.category, workflow)}',
              ),
              _ActionSurfaceDetail(
                icon: Icons.compare_arrows_outlined,
                title: 'Other option',
                body:
                    '${contract.alternateActionLabel} is available before this is saved.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.task_alt_outlined,
                title: 'Member outcome',
                body: isReceiverSurface
                    ? _receiverBodyFor(contract.category)
                    : _surfaceOutcomeFor(contract.category, workflow),
              ),
              _ActionSurfaceDetail(
                icon: Icons.verified_user_outlined,
                title: 'Privacy boundary',
                body: _reviewTrustFor(contract.category),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(contract.alternateActionLabel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: confirmButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(contract.icon, size: 18),
                label: Text(actionLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSurfaceDetail {
  const _ActionSurfaceDetail({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ActionSurfaceDetailStack extends StatelessWidget {
  const _ActionSurfaceDetailStack({required this.accent, required this.rows});

  final Color accent;
  final List<_ActionSurfaceDetail> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final surface = Color.alphaBlend(
      accent.withValues(alpha: 0.86),
      Colors.black,
    );
    final foreground = _foregroundFor(surface);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: foreground.withValues(alpha: 0.12),
                    child: Icon(rows[index].icon, size: 20, color: foreground),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[index].title,
                          style: textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rows[index].body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.90),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index != rows.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: foreground.withValues(alpha: 0.18)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkflowResultPanel extends StatelessWidget {
  const _WorkflowResultPanel({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final surface = Color.alphaBlend(
      accent.withValues(alpha: 0.86),
      Colors.black,
    );
    final foreground = _foregroundFor(surface);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.90),
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

class _PersonaStatusStrip extends StatelessWidget {
  const _PersonaStatusStrip({
    required this.persona,
    required this.personaCount,
    required this.foreground,
  });

  final LoomPersonaDefinition persona;
  final int personaCount;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('active-persona-card'),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Icon(Icons.people_outline, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.label,
                    key: ValueKey('active-persona-${persona.personaId}'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${persona.roleLabel} - ${persona.description}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              key: const ValueKey('active-persona-count'),
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  '$personaCount personas',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
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

class _ExtensionInfoTile extends StatelessWidget {
  const _ExtensionInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _LocalPackageLoaderDialog extends StatefulWidget {
  const _LocalPackageLoaderDialog({required this.onInstall});

  final String? Function({
    required String extensionPackagePath,
    required String initializationPackagePath,
  })
  onInstall;

  @override
  State<_LocalPackageLoaderDialog> createState() =>
      _LocalPackageLoaderDialogState();
}

class _LocalPackageLoaderDialogState extends State<_LocalPackageLoaderDialog> {
  late final TextEditingController _extensionPathController;
  late final TextEditingController _initializationPathController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _extensionPathController = TextEditingController(
      text:
          '/data/user/0/com.example.loom_communities_demo/files/book-club.loom-extension.zip',
    );
    _initializationPathController = TextEditingController(
      text:
          '/data/user/0/com.example.loom_communities_demo/files/book-club.loom-init.zip',
    );
  }

  @override
  void dispose() {
    _extensionPathController.dispose();
    _initializationPathController.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.onInstall(
      extensionPackagePath: _extensionPathController.text,
      initializationPackagePath: _initializationPathController.text,
    );
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add local community'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Point to the extension package and initialization package in the emulator file system.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('extension-package-path-field'),
              controller: _extensionPathController,
              decoration: const InputDecoration(
                labelText: 'Extension package',
                helperText: '.loom-extension.zip',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('initialization-package-path-field'),
              controller: _initializationPathController,
              decoration: const InputDecoration(
                labelText: 'Initialization package',
                helperText: '.loom-init.zip',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                key: const ValueKey('local-loader-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('load-local-community-button'),
          onPressed: _submit,
          icon: const Icon(Icons.upload_file),
          label: const Text('Validate and install'),
        ),
      ],
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState({required this.onAddCommunity});

  final VoidCallback onAddCommunity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'No communities installed',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Use Add Community to load a local extension package and initialization package.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('empty-add-community-button'),
          onPressed: onAddCommunity,
          icon: const Icon(Icons.add),
          label: const Text('Add Community'),
        ),
      ],
    );
  }
}

class LoomWorkflowDefinition {
  const LoomWorkflowDefinition({
    required this.workflowId,
    required this.title,
    required this.entryText,
    required this.actionText,
    required this.resultText,
  });

  final String workflowId;
  final String title;
  final String entryText;
  final String actionText;
  final String resultText;
}

class LoomProductionWorkflowContract {
  const LoomProductionWorkflowContract({
    required this.workflowId,
    required this.category,
    required this.surfaceLabel,
    required this.objectLabel,
    required this.screenTitle,
    required this.primaryActionLabel,
    required this.alternateActionLabel,
    required this.decisionSummary,
    required this.inputSummary,
    required this.validationSummary,
    required this.resultSummary,
    required this.receiverStateSummary,
    required this.successTitle,
    required this.successChipLabel,
    required this.receiverSurfaceTitle,
    required this.trustSummary,
    required this.icon,
  });

  final String workflowId;
  final String category;
  final String surfaceLabel;
  final String objectLabel;
  final String screenTitle;
  final String primaryActionLabel;
  final String alternateActionLabel;
  final String decisionSummary;
  final String inputSummary;
  final String validationSummary;
  final String resultSummary;
  final String receiverStateSummary;
  final String successTitle;
  final String successChipLabel;
  final String receiverSurfaceTitle;
  final String trustSummary;
  final IconData icon;
}

class LoomExperienceDefinition {
  const LoomExperienceDefinition({
    required this.extensionId,
    required this.displayName,
    required this.tagline,
    required this.accentColor,
    required this.workflows,
  });

  final String extensionId;
  final String displayName;
  final String tagline;
  final int accentColor;
  final List<LoomWorkflowDefinition> workflows;
}

class LoomEvidenceTarget {
  const LoomEvidenceTarget({
    required this.phase,
    required this.communityId,
    required this.communityName,
    required this.handle,
    required this.extensionId,
    required this.accentColor,
    required this.seedDataFiles,
  });

  final String phase;
  final String communityId;
  final String communityName;
  final String handle;
  final String extensionId;
  final String accentColor;
  final List<String> seedDataFiles;
}

class LoomPersonaDefinition {
  const LoomPersonaDefinition({
    required this.personaId,
    required this.label,
    required this.roleLabel,
    required this.description,
  });

  final String personaId;
  final String label;
  final String roleLabel;
  final String description;
}

enum LoomPersonaWorkflowState { actor, receiver, readOnly, disabled }

class LoomWorkflowPersonaPolicy {
  const LoomWorkflowPersonaPolicy({
    required this.actorPersonaIds,
    this.receiverPersonaIds = const [],
    this.readOnlyPersonaIds = const [],
    this.prerequisiteWorkflowId,
    this.receiverEntryText,
    this.receiverActionText,
    this.receiverResultText,
    this.readOnlyText,
    this.disabledReason = 'Not available for this persona',
  });

  final List<String> actorPersonaIds;
  final List<String> receiverPersonaIds;
  final List<String> readOnlyPersonaIds;
  final String? prerequisiteWorkflowId;
  final String? receiverEntryText;
  final String? receiverActionText;
  final String? receiverResultText;
  final String? readOnlyText;
  final String disabledReason;
}

class LoomPersonaWorkflowView {
  const LoomPersonaWorkflowView({
    required this.state,
    required this.completed,
    required this.received,
    required this.waitingForPrerequisite,
    required this.entryText,
    required this.actionText,
    required this.resultText,
    required this.personaRationale,
    required this.waitingText,
  });

  final LoomPersonaWorkflowState state;
  final bool completed;
  final bool received;
  final bool waitingForPrerequisite;
  final String entryText;
  final String actionText;
  final String resultText;
  final String personaRationale;
  final String waitingText;
}

class LoomPersonaWorkflowMatrixRow {
  const LoomPersonaWorkflowMatrixRow({
    required this.extensionId,
    required this.workflowId,
    required this.personaId,
    required this.state,
    required this.rationale,
    this.prerequisiteWorkflowId,
  });

  final String extensionId;
  final String workflowId;
  final String personaId;
  final LoomPersonaWorkflowState state;
  final String rationale;
  final String? prerequisiteWorkflowId;
}

class LoomWorkflowDependency {
  const LoomWorkflowDependency({
    required this.extensionId,
    required this.workflowId,
    required this.actorPersonaId,
    required this.receiverPersonaId,
    required this.prerequisiteWorkflowId,
  });

  final String extensionId;
  final String workflowId;
  final String actorPersonaId;
  final String receiverPersonaId;
  final String prerequisiteWorkflowId;
}

List<LoomPersonaDefinition> personasForExtensionId(String extensionId) {
  return _personasByExtensionId[extensionId] ?? _fallbackPersonas;
}

LoomWorkflowPersonaPolicy personaPolicyForWorkflow(
  String extensionId,
  String workflowId,
) {
  switch (extensionId) {
    case 'ext_garden_club':
      return _gardenPolicy(workflowId);
    case 'ext_book_club':
      return _bookPolicy(workflowId);
    case 'ext_youth_soccer':
      return _soccerPolicy(workflowId);
    case 'ext_hoa':
      return _hoaPolicy(workflowId);
    case 'ext_mosque':
      return _mosquePolicy(workflowId);
    case 'ext_chess_club':
      return _chessPolicy(workflowId);
    case 'ext_camera_club':
      return _cameraPolicy(workflowId);
    case 'ext_platform_social':
      return _platformPolicy(workflowId);
    case 'ext_ad_off':
      return _adOffPolicy(workflowId);
    case 'ext_export_migration':
      return _exportPolicy(workflowId);
  }
  return const LoomWorkflowPersonaPolicy(
    actorPersonaIds: ['local-owner'],
    receiverPersonaIds: ['local-member'],
    receiverEntryText: 'A local community update is available.',
    receiverActionText: 'Receive',
    receiverResultText: 'Local community update received.',
  );
}

LoomPersonaWorkflowState personaWorkflowStateFor({
  required String extensionId,
  required String workflowId,
  required String personaId,
}) {
  final policy = personaPolicyForWorkflow(extensionId, workflowId);
  if (policy.actorPersonaIds.contains(personaId)) {
    return LoomPersonaWorkflowState.actor;
  }
  if (policy.receiverPersonaIds.contains(personaId)) {
    return LoomPersonaWorkflowState.receiver;
  }
  if (policy.readOnlyPersonaIds.contains(personaId)) {
    return LoomPersonaWorkflowState.readOnly;
  }
  return LoomPersonaWorkflowState.disabled;
}

LoomPersonaWorkflowView personaWorkflowViewFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
  required String personaId,
  required Set<String> completedWorkflowIds,
  required Set<String> receivedWorkflowPersonaKeys,
}) {
  final policy = personaPolicyForWorkflow(extensionId, workflow.workflowId);
  final state = personaWorkflowStateFor(
    extensionId: extensionId,
    workflowId: workflow.workflowId,
    personaId: personaId,
  );
  final workflowCompleted = completedWorkflowIds.contains(workflow.workflowId);
  final completed =
      workflowCompleted && state == LoomPersonaWorkflowState.actor;
  final received = receivedWorkflowPersonaKeys.contains(
    workflowPersonaReceiptKey(
      workflowId: workflow.workflowId,
      personaId: personaId,
    ),
  );
  final actorWaiting =
      state == LoomPersonaWorkflowState.actor &&
      policy.prerequisiteWorkflowId != null &&
      !completedWorkflowIds.contains(policy.prerequisiteWorkflowId);
  final receiverPrerequisite =
      policy.prerequisiteWorkflowId ?? workflow.workflowId;
  final receiverWaiting =
      state == LoomPersonaWorkflowState.receiver &&
      !completedWorkflowIds.contains(receiverPrerequisite);
  final waitingForPrerequisite =
      !completed && !received && (actorWaiting || receiverWaiting);
  final entryText = _entryTextForState(
    state: state,
    workflow: workflow,
    policy: policy,
    waiting: waitingForPrerequisite,
  );
  return LoomPersonaWorkflowView(
    state: state,
    completed: completed,
    received: received,
    waitingForPrerequisite: waitingForPrerequisite,
    entryText: entryText,
    actionText: _actionTextForState(state, policy, workflow),
    resultText: _resultTextForState(workflow, policy, state),
    personaRationale: _rationaleForState(state, policy),
    waitingText: 'Waiting',
  );
}

List<LoomPersonaWorkflowMatrixRow> personaWorkflowMatrixForExtensionId(
  String extensionId,
) {
  final experience = experienceForExtensionId(extensionId);
  final personas = personasForExtensionId(extensionId);
  return [
    for (final workflow in experience.workflows)
      for (final persona in personas)
        LoomPersonaWorkflowMatrixRow(
          extensionId: extensionId,
          workflowId: workflow.workflowId,
          personaId: persona.personaId,
          state: personaWorkflowStateFor(
            extensionId: extensionId,
            workflowId: workflow.workflowId,
            personaId: persona.personaId,
          ),
          rationale: _rationaleForState(
            personaWorkflowStateFor(
              extensionId: extensionId,
              workflowId: workflow.workflowId,
              personaId: persona.personaId,
            ),
            personaPolicyForWorkflow(extensionId, workflow.workflowId),
          ),
          prerequisiteWorkflowId: personaPolicyForWorkflow(
            extensionId,
            workflow.workflowId,
          ).prerequisiteWorkflowId,
        ),
  ];
}

List<LoomWorkflowDependency> workflowDependenciesForExtensionId(
  String extensionId,
) {
  final experience = experienceForExtensionId(extensionId);
  return [
    for (final workflow in experience.workflows)
      for (final receiverPersonaId in personaPolicyForWorkflow(
        extensionId,
        workflow.workflowId,
      ).receiverPersonaIds)
        LoomWorkflowDependency(
          extensionId: extensionId,
          workflowId: workflow.workflowId,
          actorPersonaId: personaPolicyForWorkflow(
            extensionId,
            workflow.workflowId,
          ).actorPersonaIds.first,
          receiverPersonaId: receiverPersonaId,
          prerequisiteWorkflowId:
              personaPolicyForWorkflow(
                extensionId,
                workflow.workflowId,
              ).prerequisiteWorkflowId ??
              workflow.workflowId,
        ),
  ];
}

String workflowPersonaReceiptKey({
  required String workflowId,
  required String personaId,
}) {
  return '$workflowId::$personaId';
}

LoomProductionWorkflowContract productionWorkflowContractFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) {
  final category = _workflowCategoryFor(workflow);
  final objectLabel = _objectLabelFor(workflow);
  return LoomProductionWorkflowContract(
    workflowId: workflow.workflowId,
    category: category,
    surfaceLabel: _surfaceLabelFor(category),
    objectLabel: objectLabel,
    screenTitle: _screenTitleFor(category, workflow),
    primaryActionLabel: _primaryActionLabelFor(workflow),
    alternateActionLabel: _alternateActionLabelFor(workflow),
    decisionSummary: _decisionSummaryFor(category, workflow),
    inputSummary: _inputSummaryFor(category, workflow),
    validationSummary: _validationSummaryFor(category),
    resultSummary: _successBodyFor(category, workflow),
    receiverStateSummary: _receiverStateSummaryFor(category, workflow),
    successTitle: _successTitleFor(category, workflow),
    successChipLabel: _successChipLabelFor(category),
    receiverSurfaceTitle: _receiverTitleFor(category, objectLabel),
    trustSummary: _trustSummaryFor(category),
    icon: _iconFor(category),
  );
}

List<String> productionUxGenericCopyViolations() {
  const banned = [
    'Community workflows',
    'Complete workflow',
    'Can perform this workflow',
    'Action available for this role',
    'Receives the result',
    'Uses ',
    ' surface',
    'App Shell',
    'Shell-owned',
    'Workflow result',
    'workflow evidence',
    'evidence',
    'Workflow checklist',
    'local route',
    'workflow route',
  ];
  LoomPersonaWorkflowView viewFor(
    LoomPersonaWorkflowState state, {
    bool waiting = false,
  }) {
    return LoomPersonaWorkflowView(
      state: state,
      completed: false,
      received: false,
      waitingForPrerequisite: waiting,
      entryText: '',
      actionText: '',
      resultText: '',
      personaRationale: '',
      waitingText: '',
    );
  }

  final surfaces = <String>[
    for (final title in _orderedSectionTitles) title,
    for (final target in loomEvidenceTargets)
      for (final section in _communitySectionsFor(
        experienceForExtensionId(target.extensionId),
      )) ...[
        section.title,
        section.subtitle,
        for (final workflow in section.workflows) ...[
          _displayTitleFor(workflow),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.actor),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.receiver),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.readOnly),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.disabled),
          ),
          _domainSummaryFor(
            _workflowCategoryFor(workflow),
            workflow,
            viewFor(LoomPersonaWorkflowState.actor, waiting: true),
          ),
          ..._domainMetadataFor(_workflowCategoryFor(workflow), workflow),
          _reviewDetailFor(_workflowCategoryFor(workflow)),
          _reviewCheckFor(_workflowCategoryFor(workflow)),
          _reviewResultFor(_workflowCategoryFor(workflow)),
          _reviewTrustFor(_workflowCategoryFor(workflow)),
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).surfaceLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).screenTitle,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).primaryActionLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).alternateActionLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).decisionSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).inputSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).validationSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).resultSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).receiverStateSummary,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).successTitle,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).successChipLabel,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).receiverSurfaceTitle,
          productionWorkflowContractFor(
            extensionId: target.extensionId,
            workflow: workflow,
          ).trustSummary,
        ],
      ],
    _rationaleForState(
      LoomPersonaWorkflowState.actor,
      const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
    ),
    _rationaleForState(
      LoomPersonaWorkflowState.receiver,
      const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
    ),
    _rationaleForState(
      LoomPersonaWorkflowState.readOnly,
      const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
    ),
    _entryTextForState(
      state: LoomPersonaWorkflowState.readOnly,
      workflow: experienceForExtensionId('unknown').workflows.first,
      policy: const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
      waiting: false,
    ),
    _entryTextForState(
      state: LoomPersonaWorkflowState.actor,
      workflow: experienceForExtensionId('unknown').workflows.first,
      policy: const LoomWorkflowPersonaPolicy(actorPersonaIds: ['actor']),
      waiting: true,
    ),
  ];
  return [
    for (final surface in surfaces)
      for (final bannedText in banned)
        if (surface.toLowerCase().contains(bannedText.toLowerCase()))
          '$bannedText -> $surface',
  ];
}

String _entryTextForState({
  required LoomPersonaWorkflowState state,
  required LoomWorkflowDefinition workflow,
  required LoomWorkflowPersonaPolicy policy,
  required bool waiting,
}) {
  if (waiting) {
    return 'Waiting for the required prior action.';
  }
  if (state == LoomPersonaWorkflowState.receiver) {
    return policy.receiverEntryText ??
        'A completed result is ready for this role.';
  }
  if (state == LoomPersonaWorkflowState.readOnly) {
    return policy.readOnlyText ??
        'This role can review the current record without editing.';
  }
  if (state == LoomPersonaWorkflowState.disabled) {
    return policy.disabledReason;
  }
  return workflow.entryText;
}

String _actionTextForState(
  LoomPersonaWorkflowState state,
  LoomWorkflowPersonaPolicy policy,
  LoomWorkflowDefinition workflow,
) {
  if (state == LoomPersonaWorkflowState.receiver) {
    return _receiverActionLabel(workflow: workflow, policy: policy);
  }
  if (state == LoomPersonaWorkflowState.readOnly) {
    return 'View only';
  }
  if (state == LoomPersonaWorkflowState.disabled) {
    return 'Not available';
  }
  return _primaryActionLabelFor(workflow);
}

String _resultTextForState(
  LoomWorkflowDefinition workflow,
  LoomWorkflowPersonaPolicy policy,
  LoomPersonaWorkflowState state,
) {
  if (state == LoomPersonaWorkflowState.receiver) {
    return policy.receiverResultText ?? 'Community update received.';
  }
  return workflow.resultText;
}

String _rationaleForState(
  LoomPersonaWorkflowState state,
  LoomWorkflowPersonaPolicy policy,
) {
  switch (state) {
    case LoomPersonaWorkflowState.actor:
      return 'You can manage this item.';
    case LoomPersonaWorkflowState.receiver:
      return 'This item is ready after the first action is finished.';
    case LoomPersonaWorkflowState.readOnly:
      return 'You can review this item without editing it.';
    case LoomPersonaWorkflowState.disabled:
      return policy.disabledReason;
  }
}

String _receiverActionLabel({
  required LoomWorkflowDefinition workflow,
  required LoomWorkflowPersonaPolicy policy,
}) {
  final label = policy.receiverActionText;
  if (label == null || label == 'Receive') {
    return 'Open ${_objectLabelFor(workflow)}';
  }
  if (label == 'Review') {
    return 'Review ${_objectLabelFor(workflow)}';
  }
  return label;
}

String _workflowCategoryFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  final title = workflow.title.toLowerCase();
  if (id.contains('rsvp') ||
      title.contains('event') ||
      title.contains('schedule') ||
      title.contains('photo-walk')) {
    return 'Event';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off') ||
      title.contains('receipt') ||
      title.contains('reservation')) {
    return 'Payment';
  }
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification') ||
      id.contains('digest') ||
      id.contains('search-ai')) {
    return 'Publishing';
  }
  if (id.contains('approval') ||
      id.contains('decision') ||
      id.contains('review')) {
    return 'Approval';
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('redaction') ||
      id.contains('checksum')) {
    return 'Portability';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('ad') ||
      id.contains('banner') ||
      id.contains('blocked') ||
      id.contains('stream')) {
    return 'Platform';
  }
  return 'Form';
}

String _surfaceLabelFor(String category) {
  switch (category) {
    case 'Event':
      return 'Event details';
    case 'Payment':
      return 'Payment details';
    case 'Publishing':
      return 'Member update';
    case 'Approval':
      return 'Request review';
    case 'Portability':
      return 'Data package';
    case 'Platform':
      return 'Community setting';
  }
  return 'Member form';
}

String _objectLabelFor(LoomWorkflowDefinition workflow) {
  var title = _displayTitleFor(workflow).toLowerCase();
  title = title
      .replaceAll(' and ', ' ')
      .replaceAll(',', '')
      .replaceAll('protected ', '')
      .trim();
  if (title.length > 34) {
    return title.substring(0, 34).trim();
  }
  return title;
}

String _primaryActionLabelFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('plant-exchange')) {
    return 'Offer plant';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Record match result';
  }
  if (id.contains('rsvp')) {
    return 'RSVP to event';
  }
  if (id.contains('payment') || id.contains('dues')) {
    return 'Pay and save receipt';
  }
  if (id.contains('donation')) {
    return 'Record donation';
  }
  if (id.contains('checkout')) {
    return 'Buy ad-off';
  }
  if (id.contains('announcement')) {
    return 'Publish announcement';
  }
  if (id.contains('publish') || id.contains('selection')) {
    return 'Publish announcement';
  }
  if (id.contains('schedule')) {
    return 'Publish schedule';
  }
  if (id.contains('reminder')) {
    return 'Send reminder';
  }
  if (id.contains('notification')) {
    return 'Send notification';
  }
  if (id.contains('approval') || id.contains('decision')) {
    return 'Approve request';
  }
  if (id.contains('export')) {
    return 'Generate export';
  }
  if (id.contains('import')) {
    return 'Preview import';
  }
  if (id.contains('transfer-verification')) {
    return 'Verify transfer';
  }
  if (id.contains('rollback')) {
    return 'Run rollback';
  }
  if (id.contains('search') || id.contains('digest')) {
    return 'Generate cited answer';
  }
  if (id.contains('invite')) {
    return 'Send invite';
  }
  if (id.contains('messages')) {
    return 'Reply';
  }
  if (id.contains('connections')) {
    return 'Connect';
  }
  if (id.contains('blocked')) {
    return 'Check blocked state';
  }
  if (id.contains('ad') || id.contains('banner')) {
    return 'Review ad state';
  }
  if (id.contains('vote')) {
    return 'Record vote';
  }
  if (id.contains('nomination')) {
    return 'Submit nomination';
  }
  if (id.contains('message')) {
    return 'Send message';
  }
  if (id.contains('request')) {
    return 'Submit request';
  }
  if (id.contains('signup')) {
    return 'Submit signup';
  }
  if (id.contains('submission')) {
    return 'Submit';
  }
  if (id.contains('reservation')) {
    return 'Reserve and pay';
  }
  if (id.contains('document')) {
    return 'Open document';
  }
  if (id.contains('roster')) {
    return 'Open roster';
  }
  if (id.contains('redaction')) {
    return 'Preview redaction';
  }
  if (id.contains('visibility')) {
    return 'Save visibility';
  }
  if (id.contains('route') || id.contains('open')) {
    return 'Open community home';
  }
  final action = workflow.actionText.replaceAll(RegExp(r'\.$'), '');
  return action.length <= 36 ? action : 'Start ${_objectLabelFor(workflow)}';
}

String _alternateActionLabelFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('announcement')) {
    return 'Preview announcement';
  }
  if (id.contains('publish') || id.contains('selection')) {
    return 'Save draft';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'Change response';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return 'Change amount';
  }
  if (id.contains('document')) {
    return 'Save document';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('decision')) {
    return 'Request changes';
  }
  if (id.contains('care')) {
    return 'Update privacy';
  }
  if (id.contains('gear')) {
    return 'Change request';
  }
  if (id.contains('plant-exchange')) {
    return 'Edit offer';
  }
  if (id.contains('critique')) {
    return 'Edit critique';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Edit score';
  }
  if (id.contains('invite')) {
    return 'Decline invite';
  }
  if (id.contains('message') || id.contains('connection')) {
    return 'Archive thread';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Change scope';
  }
  if (id.contains('request')) {
    return 'Edit request';
  }
  return 'Edit response';
}

String _decisionSummaryFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('announcement') || id.contains('publish')) {
    return 'Decide whether this message is ready for members, who receives it, and whether to preview or save a draft first.';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'Decide if you are going, maybe, or not attending after checking date, time, location, and capacity.';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return 'Decide the amount, payer context, visibility, receipt destination, and whether to edit or manage the payment.';
  }
  if (id.contains('document')) {
    return 'Decide whether to open, download, save, share, or request access to this document.';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request')) {
    return 'Decide whether the request should be approved, rejected, revised, or sent back for changes.';
  }
  if (id.contains('care')) {
    return 'Decide what care details to share, who receives them, and whether privacy should be updated before sending.';
  }
  if (id.contains('gear')) {
    return 'Decide whether to claim, decline, change, or return the gear after checking owner, pickup, and due details.';
  }
  if (id.contains('plant-exchange')) {
    return 'Decide whether to claim, offer, edit, or cancel the plant exchange after checking variety, pickup, and contact details.';
  }
  if (id.contains('critique')) {
    return 'Decide whether to submit, edit, withdraw, or resubmit the critique after reviewing the image and comments.';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Decide whether to save, edit, correct, or dispute the match result after checking opponent, round, and score.';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite')) {
    return 'Decide whether to reply, send, accept, decline, mute, archive, or block this member communication.';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Decide the scope, redaction, checksum, destination, and whether to retry, roll back, or change scope.';
  }
  return 'Decide what to save, what to change, and what status or next step should remain visible afterward.';
}

String _receiverStateSummaryFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  final id = workflow.workflowId;
  if (id.contains('announcement') || id.contains('publish')) {
    return 'Members see it later in the inbox, notification list, and read state.';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'The calendar, attendee roster, and member status remain visible after the response.';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return 'Receipt history, donor or member account status, and entitlement state remain available.';
  }
  if (id.contains('document')) {
    return 'Members keep access, read-only viewer state, and download history where allowed.';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request') ||
      id.contains('care')) {
    return 'Reviewer, owner, committee, notification, and request status are visible after submission.';
  }
  if (id.contains('gear') || id.contains('plant-exchange')) {
    return 'Owner, borrower, contact, pickup, and handoff status stay visible.';
  }
  if (id.contains('critique')) {
    return 'Reviewer feedback, comments, and member follow-up stay visible.';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Opponent, standings, next pairing, and recorded result remain visible.';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite')) {
    return 'Recipient inbox, thread, and connection state remain visible.';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Provider, destination, rollback, audit, and transfer status remain visible.';
  }
  return 'History, receiver status, and next step remain visible.';
}

String _screenTitleFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Event details';
    case 'Payment':
      return 'Payment checkout';
    case 'Publishing':
      return 'Announcement composer';
    case 'Approval':
      return 'Decision desk';
    case 'Portability':
      return 'Data package';
    case 'Platform':
      return 'Member setting';
  }
  return '${_objectLabelFor(workflow).substring(0, 1).toUpperCase()}${_objectLabelFor(workflow).substring(1)} details';
}

Color _categoryAccentColor(String category, ColorScheme scheme) {
  switch (category) {
    case 'Event':
      return const Color(0xff2f6f9f);
    case 'Payment':
      return const Color(0xff7b4f9d);
    case 'Publishing':
      return const Color(0xff00796b);
    case 'Approval':
      return const Color(0xff8a5a00);
    case 'Portability':
      return const Color(0xff4556a4);
    case 'Platform':
      return const Color(0xff7a5c00);
    case 'Form':
      return const Color(0xff3f7f4c);
  }
  return scheme.primary;
}

String _domainSurfaceTitleFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  switch (category) {
    case 'Event':
      return 'Coordinate attendance';
    case 'Payment':
      return 'Record payment';
    case 'Publishing':
      return 'Send community notice';
    case 'Approval':
      return 'Resolve member request';
    case 'Portability':
      return 'Prepare export handoff';
    case 'Platform':
      return 'Update member channel';
    case 'Form':
      return 'Submit member form';
  }
  return _displayTitleFor(workflow);
}

String _domainSurfaceLeadFor(
  String category,
  LoomWorkflowDefinition workflow, {
  required bool isReceiverSurface,
}) {
  if (isReceiverSurface) {
    switch (category) {
      case 'Event':
        return 'Member attendance and event changes are shown in one place.';
      case 'Payment':
        return 'The member can inspect the receipt, privacy choice, and amount.';
      case 'Publishing':
        return 'The member sees the message, audience, and delivery channel.';
      case 'Approval':
        return 'The member sees the decision and the next action.';
      case 'Portability':
        return 'The member can inspect scope, status, and protected-data handling.';
      case 'Platform':
        return 'The member sees the channel or relationship change.';
      case 'Form':
        return 'The reviewer can inspect the submitted details and follow-up path.';
    }
  }
  switch (category) {
    case 'Event':
      return 'Use this surface to publish event details, capacity, and attendance state.';
    case 'Payment':
      return 'Use this surface to capture the amount, receipt, and privacy setting.';
    case 'Publishing':
      return 'Use this surface to send a scoped announcement to the selected audience.';
    case 'Approval':
      return 'Use this surface to record the decision and member follow-up.';
    case 'Portability':
      return 'Use this surface to package export scope, redaction, and handoff status.';
    case 'Platform':
      return 'Use this surface to change a member communication or relationship setting.';
    case 'Form':
      return 'Use this surface to submit structured member details.';
  }
  return workflow.entryText;
}

String _surfaceInputFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee state are included.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt destination are included.';
    case 'Publishing':
      return 'Message, audience, preview, and delivery channel are included.';
    case 'Approval':
      return 'Request details, decision, and follow-up note are included.';
    case 'Portability':
      return 'Scope, redaction, checksum, and handoff destination are included.';
    case 'Platform':
      return 'Member channel, relationship, and preference details are included.';
    case 'Form':
      return 'Required fields, privacy choices, and reviewer handoff are included.';
  }
  return _domainSummaryFor(
    category,
    workflow,
    LoomPersonaWorkflowView(
      state: LoomPersonaWorkflowState.actor,
      completed: false,
      received: false,
      waitingForPrerequisite: false,
      entryText: workflow.entryText,
      actionText: workflow.actionText,
      resultText: workflow.resultText,
      personaRationale: 'Actor may complete this action.',
      waitingText: '',
    ),
  );
}

String _surfaceOutcomeFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Attendance, capacity, and reminders update for the community.';
    case 'Payment':
      return 'The payment record and receipt become available to the right member.';
    case 'Publishing':
      return 'The announcement appears in the member inbox and notification channel.';
    case 'Approval':
      return 'The decision is saved with the next step visible to the member.';
    case 'Portability':
      return 'The export package can be inspected with redaction and checksum details.';
    case 'Platform':
      return 'The communication or relationship setting changes for this community.';
    case 'Form':
      return 'The submission is routed to the reviewer with protected details preserved.';
  }
  return _successBodyFor(category, workflow);
}

String _inputSummaryFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee details are ready.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt details are ready.';
    case 'Publishing':
      return 'Message, audience, preview, and send timing are ready.';
    case 'Approval':
      return 'Request details, decision, and follow-up are ready.';
    case 'Portability':
      return 'Data scope, redaction, checksum, and handoff details are ready.';
    case 'Platform':
      return 'Member communication and preference details are ready.';
  }
  if (workflow.workflowId.contains('care')) {
    return 'Public summary, private details, and consent choices are ready.';
  }
  return 'Required details are ready.';
}

String _validationSummaryFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Receipt and privacy settings are saved with the payment.';
    case 'Publishing':
      return 'Audience, citation, and notification scope are reviewed before send.';
    case 'Portability':
      return 'Protected fields, redaction, and checksums are verified.';
    case 'Platform':
      return 'Membership and privacy settings are respected.';
  }
  return 'Required details are checked before submission.';
}

String _successTitleFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('message')) {
    return 'Message sent';
  }
  if (id.contains('connection') || id.contains('invite')) {
    return 'Connection accepted';
  }
  if (id.contains('announcement')) {
    return 'Announcement posted';
  }
  if (id.contains('rsvp')) {
    return 'RSVP confirmed';
  }
  if (id.contains('donation')) {
    return 'Donation recorded';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'Signup saved';
  }
  if (id.contains('care')) {
    return 'Care request sent';
  }
  switch (category) {
    case 'Payment':
      return 'Receipt saved';
    case 'Publishing':
      return 'Update sent';
    case 'Approval':
      return 'Decision saved';
    case 'Portability':
      return 'Data package ready';
    case 'Platform':
      return 'Setting saved';
    case 'Event':
      return 'Event updated';
  }
  return 'Record saved';
}

String _successBodyFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('message')) {
    return 'The message is sent and received in the community thread.';
  }
  if (id.contains('connection') || id.contains('invite')) {
    return 'The member connection is accepted and visible in the community network.';
  }
  if (id.contains('announcement')) {
    return 'Members can now read the announcement in their community inbox.';
  }
  if (id.contains('rsvp')) {
    return 'Attendance, capacity, and confirmation details are up to date.';
  }
  if (id.contains('donation')) {
    return 'The donation and receipt are saved with the selected privacy choice.';
  }
  if (id.contains('volunteer') || id.contains('signup')) {
    return 'The coordinator can review the signup and protected contact details.';
  }
  if (id.contains('care')) {
    return 'The care team can review the private request details.';
  }
  switch (category) {
    case 'Event':
      return 'Event details and attendance records are up to date.';
    case 'Payment':
      return 'The receipt is saved and available to the member.';
    case 'Publishing':
      return 'The update is available to the selected audience.';
    case 'Approval':
      return 'The decision is saved and ready for member follow-up.';
    case 'Portability':
      return 'The data package is ready with protected fields handled.';
    case 'Platform':
      return 'The member setting is up to date.';
  }
  return 'The community record is saved.';
}

String _receiverTitleFor(String category, String objectLabel) {
  switch (category) {
    case 'Event':
      return 'Event update ready';
    case 'Payment':
      return 'Receipt ready';
    case 'Publishing':
      return 'Update ready';
    case 'Approval':
      return 'Decision ready';
    case 'Portability':
      return 'Data package ready';
    case 'Platform':
      return 'Member update ready';
  }
  return '${objectLabel.substring(0, 1).toUpperCase()}${objectLabel.substring(1)} ready';
}

String _successChipLabelFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Receipt';
    case 'Publishing':
      return 'Sent';
    case 'Approval':
      return 'Decided';
    case 'Portability':
      return 'Ready';
    case 'Platform':
      return 'Verified';
    case 'Event':
      return 'Going';
  }
  return 'Saved';
}

String _trustSummaryFor(String category) {
  switch (category) {
    case 'Payment':
      return 'Payments and receipts stay tied to the member account.';
    case 'Publishing':
      return 'Only the selected audience receives the update.';
    case 'Portability':
      return 'Protected data stays redacted before sharing.';
    case 'Platform':
      return 'Private member relationships stay scoped to this community.';
  }
  return 'Private member details stay protected.';
}

IconData _iconFor(String category) {
  switch (category) {
    case 'Event':
      return Icons.event_available_outlined;
    case 'Payment':
      return Icons.receipt_long_outlined;
    case 'Publishing':
      return Icons.campaign_outlined;
    case 'Approval':
      return Icons.task_alt_outlined;
    case 'Portability':
      return Icons.file_download_outlined;
    case 'Platform':
      return Icons.hub_outlined;
  }
  return Icons.assignment_outlined;
}

LoomExperienceDefinition experienceForExtensionId(
  String extensionId, {
  String? displayName,
}) {
  final known = _experienceByExtensionId[extensionId];
  if (known != null) {
    return known;
  }
  return LoomExperienceDefinition(
    extensionId: extensionId,
    displayName: displayName ?? 'Local Community',
    tagline: 'Local community tools and member actions.',
    accentColor: 0xff246b62,
    workflows: const [
      LoomWorkflowDefinition(
        workflowId: 'local-home-open',
        title: 'Open local home',
        entryText: 'Local community home is available from the installed card.',
        actionText: 'Open the local community home.',
        resultText: 'Local home opened with community tools available.',
      ),
    ],
  );
}

const List<LoomEvidenceTarget> loomEvidenceTargets = [
  LoomEvidenceTarget(
    phase: 'B13',
    communityId: 'community_garden_club',
    communityName: 'Garden Club',
    handle: 'garden-club',
    extensionId: 'ext_garden_club',
    accentColor: '#3A7D44',
    seedDataFiles: [
      'seed/community.json',
      'seed/workflows.json',
      'seed/events.json',
    ],
  ),
  LoomEvidenceTarget(
    phase: 'B14',
    communityId: 'community_book_club',
    communityName: 'Neighborhood Book Club',
    handle: 'book-club',
    extensionId: 'ext_book_club',
    accentColor: '#246B62',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
  ),
  LoomEvidenceTarget(
    phase: 'B14',
    communityId: 'community_youth_soccer',
    communityName: 'Riverside Youth Soccer',
    handle: 'youth-soccer',
    extensionId: 'ext_youth_soccer',
    accentColor: '#1F7A5C',
    seedDataFiles: [
      'seed/community.json',
      'seed/workflows.json',
      'seed/events.json',
    ],
  ),
  LoomEvidenceTarget(
    phase: 'B14',
    communityId: 'community_hoa',
    communityName: 'Cedar Commons HOA',
    handle: 'cedar-hoa',
    extensionId: 'ext_hoa',
    accentColor: '#3E6B8F',
    seedDataFiles: [
      'seed/community.json',
      'seed/workflows.json',
      'seed/documents.json',
    ],
  ),
  LoomEvidenceTarget(
    phase: 'B14',
    communityId: 'community_mosque',
    communityName: 'Masjid Nur',
    handle: 'masjid-nur',
    extensionId: 'ext_mosque',
    accentColor: '#2D6A4F',
    seedDataFiles: [
      'seed/community.json',
      'seed/workflows.json',
      'seed/events.json',
    ],
  ),
  LoomEvidenceTarget(
    phase: 'B15',
    communityId: 'community_chess_club',
    communityName: 'Chess Club',
    handle: 'chess-club',
    extensionId: 'ext_chess_club',
    accentColor: '#58432F',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
  ),
  LoomEvidenceTarget(
    phase: 'B15',
    communityId: 'community_camera_club',
    communityName: 'Camera Club',
    handle: 'camera-club',
    extensionId: 'ext_camera_club',
    accentColor: '#465C7B',
    seedDataFiles: [
      'seed/community.json',
      'seed/workflows.json',
      'seed/events.json',
    ],
  ),
  LoomEvidenceTarget(
    phase: 'B16',
    communityId: 'community_platform_social',
    communityName: 'Member Social Space',
    handle: 'platform-social',
    extensionId: 'ext_platform_social',
    accentColor: '#315C8A',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
  ),
  LoomEvidenceTarget(
    phase: 'B16',
    communityId: 'community_ad_off',
    communityName: 'Ad-Free Community',
    handle: 'ad-off-demo',
    extensionId: 'ext_ad_off',
    accentColor: '#5B5F97',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
  ),
  LoomEvidenceTarget(
    phase: 'B16',
    communityId: 'community_export_migration',
    communityName: 'Data Portability Community',
    handle: 'portability-demo',
    extensionId: 'ext_export_migration',
    accentColor: '#536878',
    seedDataFiles: [
      'seed/community.json',
      'seed/workflows.json',
      'seed/export.json',
    ],
  ),
];

LocalBackendSnapshot _preloadedExampleCommunitiesSnapshot() {
  return LocalBackendSnapshot(
    communities: [
      for (final target in loomEvidenceTargets)
        LocalInstalledCommunity(
          communityId: target.communityId,
          displayName: target.communityName,
          extensionId: target.extensionId,
          logoAssetId: 'seed/assets/${target.handle}-logo.png',
          cardImageAssetId: 'seed/assets/${target.handle}-card.png',
          heroImageAssetId: 'seed/assets/${target.handle}-hero.png',
          accentColor: target.accentColor,
        ),
    ],
    loadedExtensionIds: [
      for (final target in loomEvidenceTargets) target.extensionId,
    ],
  );
}

Map<String, List<String>> _preloadedSeedFilesByCommunityId() {
  return {
    for (final target in loomEvidenceTargets)
      target.communityId: target.seedDataFiles,
  };
}

const List<LoomPersonaDefinition> _fallbackPersonas = [
  LoomPersonaDefinition(
    personaId: 'local-owner',
    label: 'Local Owner',
    roleLabel: 'Owner',
    description: 'Manages local community setup and member actions.',
  ),
  LoomPersonaDefinition(
    personaId: 'local-member',
    label: 'Local Member',
    roleLabel: 'Member',
    description: 'Uses local community member tools.',
  ),
];

const Map<String, List<LoomPersonaDefinition>> _personasByExtensionId = {
  'ext_garden_club': [
    LoomPersonaDefinition(
      personaId: 'garden-coordinator',
      label: 'Garden Coordinator',
      roleLabel: 'Coordinator',
      description: 'Reviews events, exchanges, and garden exports.',
    ),
    LoomPersonaDefinition(
      personaId: 'garden-member',
      label: 'Garden Member',
      roleLabel: 'Member',
      description: 'RSVPs to garden events and submits exchange offers.',
    ),
  ],
  'ext_book_club': [
    LoomPersonaDefinition(
      personaId: 'book-organizer',
      label: 'Book Organizer',
      roleLabel: 'Organizer',
      description: 'Publishes selections and manages club records.',
    ),
    LoomPersonaDefinition(
      personaId: 'book-member',
      label: 'Book Member',
      roleLabel: 'Member',
      description: 'Nominates, votes, attends, and discusses books.',
    ),
  ],
  'ext_youth_soccer': [
    LoomPersonaDefinition(
      personaId: 'soccer-coach',
      label: 'Coach',
      roleLabel: 'Team staff',
      description: 'Approves guardians and publishes team operations.',
    ),
    LoomPersonaDefinition(
      personaId: 'soccer-guardian',
      label: 'Guardian',
      roleLabel: 'Guardian',
      description: 'Handles player registration, payments, and reminders.',
    ),
  ],
  'ext_hoa': [
    LoomPersonaDefinition(
      personaId: 'hoa-board',
      label: 'HOA Board',
      roleLabel: 'Board',
      description: 'Reviews requests, sends decisions, and exports records.',
    ),
    LoomPersonaDefinition(
      personaId: 'hoa-homeowner',
      label: 'Homeowner',
      roleLabel: 'Member',
      description: 'Pays dues, reserves facilities, and submits requests.',
    ),
  ],
  'ext_mosque': [
    LoomPersonaDefinition(
      personaId: 'mosque-admin',
      label: 'Masjid Admin',
      roleLabel: 'Admin',
      description: 'Publishes announcements and sends neutral notifications.',
    ),
    LoomPersonaDefinition(
      personaId: 'mosque-member',
      label: 'Community Member',
      roleLabel: 'Member',
      description:
          'Receives announcements, RSVPs, volunteers, gives, and requests care.',
    ),
  ],
  'ext_chess_club': [
    LoomPersonaDefinition(
      personaId: 'chess-organizer',
      label: 'Chess Organizer',
      roleLabel: 'Organizer',
      description: 'Reviews community homes and match records.',
    ),
    LoomPersonaDefinition(
      personaId: 'chess-player',
      label: 'Chess Player',
      roleLabel: 'Member',
      description: 'Opens club routes and records match results.',
    ),
  ],
  'ext_camera_club': [
    LoomPersonaDefinition(
      personaId: 'camera-organizer',
      label: 'Camera Organizer',
      roleLabel: 'Organizer',
      description: 'Reviews RSVPs, critiques, and gear-loan requests.',
    ),
    LoomPersonaDefinition(
      personaId: 'camera-member',
      label: 'Camera Member',
      roleLabel: 'Member',
      description: 'RSVPs, submits critiques, and requests shared gear.',
    ),
  ],
  'ext_platform_social': [
    LoomPersonaDefinition(
      personaId: 'platform-member',
      label: 'Platform Member',
      roleLabel: 'Member',
      description: 'Uses allowed messages, connections, and ad preferences.',
    ),
    LoomPersonaDefinition(
      personaId: 'platform-moderator',
      label: 'Moderator',
      roleLabel: 'Moderator',
      description: 'Reviews prevention and sensitive-page behavior.',
    ),
    LoomPersonaDefinition(
      personaId: 'platform-blocked-member',
      label: 'Blocked Member',
      roleLabel: 'Restricted',
      description: 'Confirms blocked social capabilities stay unavailable.',
    ),
  ],
  'ext_ad_off': [
    LoomPersonaDefinition(
      personaId: 'ad-off-member',
      label: 'Ad-Off Member',
      roleLabel: 'Member',
      description: 'Purchases and verifies member ad-off entitlement.',
    ),
    LoomPersonaDefinition(
      personaId: 'ad-off-admin',
      label: 'Community Admin',
      roleLabel: 'Admin',
      description: 'Purchases community ad-off and audits settlement.',
    ),
    LoomPersonaDefinition(
      personaId: 'ad-off-viewer',
      label: 'Ad-Free Viewer',
      roleLabel: 'Viewer',
      description: 'Receives entitlement effects without checkout ownership.',
    ),
  ],
  'ext_export_migration': [
    LoomPersonaDefinition(
      personaId: 'export-owner',
      label: 'Data Owner',
      roleLabel: 'Owner',
      description: 'Runs import, export, redaction, and checksum actions.',
    ),
    LoomPersonaDefinition(
      personaId: 'export-member',
      label: 'Export Member',
      roleLabel: 'Member',
      description: 'Inspects redacted data without accessing protected values.',
    ),
    LoomPersonaDefinition(
      personaId: 'export-provider',
      label: 'Receiving Provider',
      roleLabel: 'Provider',
      description: 'Verifies transfer and rollback outcomes.',
    ),
  ],
};

LoomWorkflowPersonaPolicy _gardenPolicy(String workflowId) {
  switch (workflowId) {
    case 'garden-event-rsvp':
    case 'plant-exchange-submission':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['garden-member'],
        receiverPersonaIds: ['garden-coordinator'],
        receiverEntryText: 'A member garden submission is ready for review.',
        receiverActionText: 'Review',
        receiverResultText:
            'Garden coordinator received the member submission.',
      );
    case 'garden-export-custom-schemas':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['garden-coordinator'],
        readOnlyPersonaIds: ['garden-member'],
        readOnlyText: 'Members can inspect that their garden records export.',
      );
  }
  return const LoomWorkflowPersonaPolicy(
    actorPersonaIds: ['garden-coordinator'],
  );
}

LoomWorkflowPersonaPolicy _bookPolicy(String workflowId) {
  switch (workflowId) {
    case 'book-nomination':
    case 'book-vote':
    case 'book-meeting-rsvp':
    case 'book-discussion-message':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['book-member'],
        receiverPersonaIds: ['book-organizer'],
        receiverEntryText:
            'A member book-club contribution is ready for organizer review.',
        receiverActionText: 'Review',
        receiverResultText:
            'Organizer received the member book-club contribution.',
      );
    case 'book-selection-publish':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['book-organizer'],
        receiverPersonaIds: ['book-member'],
        receiverEntryText:
            'The published monthly selection is ready to receive.',
        receiverActionText: 'Receive selection',
        receiverResultText: 'Member received the selected-book announcement.',
      );
    case 'book-search-ai-digest':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['book-member', 'book-organizer'],
      );
    case 'book-export-metadata':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['book-organizer'],
        readOnlyPersonaIds: ['book-member'],
        readOnlyText:
            'Members can inspect export metadata without creating it.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['book-organizer']);
}

LoomWorkflowPersonaPolicy _soccerPolicy(String workflowId) {
  switch (workflowId) {
    case 'soccer-guardian-join-approval':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['soccer-coach'],
        receiverPersonaIds: ['soccer-guardian'],
        receiverEntryText: 'Guardian approval is ready to receive.',
        receiverActionText: 'Receive approval',
        receiverResultText: 'Guardian received active membership approval.',
      );
    case 'soccer-team-roster':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['soccer-coach', 'soccer-guardian'],
      );
    case 'soccer-minor-redaction':
    case 'soccer-registration-payment':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['soccer-guardian'],
        readOnlyPersonaIds: ['soccer-coach'],
        readOnlyText: 'Coach sees only permission-safe evidence.',
      );
    case 'soccer-practice-schedule':
    case 'soccer-reminder-notification':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['soccer-coach'],
        receiverPersonaIds: ['soccer-guardian'],
        receiverEntryText: 'Team update is ready for guardian receipt.',
        receiverActionText: 'Receive update',
        receiverResultText: 'Guardian received the team update.',
      );
    case 'soccer-export-metadata':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['soccer-coach'],
        readOnlyPersonaIds: ['soccer-guardian'],
        readOnlyText: 'Guardian can inspect protected export coverage.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['soccer-coach']);
}

LoomWorkflowPersonaPolicy _hoaPolicy(String workflowId) {
  switch (workflowId) {
    case 'hoa-dues-payment':
    case 'hoa-member-document':
    case 'hoa-facility-reservation':
    case 'hoa-architectural-request':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['hoa-homeowner'],
        receiverPersonaIds: ['hoa-board'],
        receiverEntryText: 'A homeowner action is ready for board review.',
        receiverActionText: 'Review',
        receiverResultText: 'Board received the homeowner workflow result.',
      );
    case 'hoa-committee-decision':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['hoa-board'],
        receiverPersonaIds: ['hoa-homeowner'],
        prerequisiteWorkflowId: 'hoa-architectural-request',
        receiverEntryText: 'The committee decision is ready for the homeowner.',
        receiverActionText: 'Receive decision',
        receiverResultText: 'Homeowner received the architectural decision.',
      );
    case 'hoa-owner-notification':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['hoa-board'],
        receiverPersonaIds: ['hoa-homeowner'],
        prerequisiteWorkflowId: 'hoa-committee-decision',
        receiverEntryText: 'The owner notification is ready to receive.',
        receiverActionText: 'Receive notice',
        receiverResultText: 'Homeowner received the owner notification.',
      );
    case 'hoa-export-evidence':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['hoa-board'],
        readOnlyPersonaIds: ['hoa-homeowner'],
        readOnlyText: 'Homeowners can inspect export evidence.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['hoa-board']);
}

LoomWorkflowPersonaPolicy _mosquePolicy(String workflowId) {
  switch (workflowId) {
    case 'mosque-announcement':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-admin'],
        receiverPersonaIds: ['mosque-member'],
        receiverEntryText: 'A public announcement is ready to receive.',
        receiverActionText: 'Receive announcement',
        receiverResultText: 'Member received the public announcement.',
      );
    case 'mosque-event-rsvp':
    case 'mosque-volunteer-signup':
    case 'mosque-donor-visibility':
    case 'mosque-donation-payment':
    case 'mosque-care-request':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-member'],
        receiverPersonaIds: ['mosque-admin'],
        receiverEntryText:
            'A member workflow result is ready for admin review.',
        receiverActionText: 'Review',
        receiverResultText: 'Admin received the member workflow result.',
      );
    case 'mosque-neutral-notification':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-admin'],
        receiverPersonaIds: ['mosque-member'],
        prerequisiteWorkflowId: 'mosque-care-request',
        receiverEntryText: 'A neutral care notification is ready to receive.',
        receiverActionText: 'Receive notice',
        receiverResultText: 'Member received the neutral care notification.',
      );
    case 'mosque-search-ai-citation':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-admin', 'mosque-member'],
        prerequisiteWorkflowId: 'mosque-announcement',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['mosque-admin']);
}

LoomWorkflowPersonaPolicy _chessPolicy(String workflowId) {
  switch (workflowId) {
    case 'chess-local-install-open':
    case 'chess-route-home':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['chess-organizer', 'chess-player'],
      );
    case 'chess-match-result':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['chess-player'],
        receiverPersonaIds: ['chess-organizer'],
        receiverEntryText: 'A match result is ready for organizer review.',
        receiverActionText: 'Review result',
        receiverResultText: 'Organizer received the chess match result.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['chess-organizer']);
}

LoomWorkflowPersonaPolicy _cameraPolicy(String workflowId) {
  switch (workflowId) {
    case 'photo-walk-rsvp':
    case 'critique-submission':
    case 'gear-loan-request':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['camera-member'],
        receiverPersonaIds: ['camera-organizer'],
        receiverEntryText: 'A member camera-club action is ready for review.',
        receiverActionText: 'Review',
        receiverResultText: 'Camera organizer received the member action.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['camera-organizer']);
}

LoomWorkflowPersonaPolicy _platformPolicy(String workflowId) {
  switch (workflowId) {
    case 'platform-messages-entry':
    case 'platform-connections-entry':
    case 'platform-message-stream':
    case 'platform-in-stream-ad':
    case 'platform-top-banner-no-fill':
    case 'platform-sensitive-no-fill':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['platform-member', 'platform-moderator'],
        readOnlyPersonaIds: ['platform-blocked-member'],
        readOnlyText:
            'Blocked persona can inspect shell state but cannot initiate social actions.',
      );
    case 'platform-connection-invite':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['platform-member'],
        receiverPersonaIds: ['platform-moderator'],
        disabledReason:
            'Blocked or moderator personas do not send this member invite.',
        receiverEntryText:
            'A member invite attempt is ready for moderation review.',
        receiverActionText: 'Review invite',
        receiverResultText:
            'Moderator received the connection invite evidence.',
      );
    case 'platform-blocked-target':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['platform-moderator'],
        receiverPersonaIds: ['platform-member'],
        disabledReason: 'Blocked persona remains unable to receive invites.',
        receiverEntryText: 'Blocked-target prevention result is ready.',
        receiverActionText: 'Receive prevention',
        receiverResultText:
            'Member received blocked-target prevention evidence.',
      );
  }
  return const LoomWorkflowPersonaPolicy(
    actorPersonaIds: ['platform-moderator'],
  );
}

LoomWorkflowPersonaPolicy _adOffPolicy(String workflowId) {
  switch (workflowId) {
    case 'ad-off-member-checkout':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['ad-off-member'],
        receiverPersonaIds: ['ad-off-viewer'],
        receiverEntryText: 'Member ad-off entitlement is ready to observe.',
        receiverActionText: 'Receive entitlement',
        receiverResultText:
            'Ad-free viewer received member entitlement evidence.',
      );
    case 'ad-off-community-checkout':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['ad-off-admin'],
        receiverPersonaIds: ['ad-off-member', 'ad-off-viewer'],
        receiverEntryText: 'Community ad-off entitlement is ready to receive.',
        receiverActionText: 'Receive entitlement',
        receiverResultText:
            'Persona received community ad-off entitlement evidence.',
      );
    case 'ad-off-entitlement-status':
    case 'ad-off-receipt-evidence':
    case 'ad-off-ad-suppression':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['ad-off-member', 'ad-off-admin', 'ad-off-viewer'],
      );
    case 'ad-off-settlement-utility':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['ad-off-admin'],
        readOnlyPersonaIds: ['ad-off-member', 'ad-off-viewer'],
        readOnlyText:
            'Non-admin personas can inspect economics without recalculating settlement.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['ad-off-admin']);
}

LoomWorkflowPersonaPolicy _exportPolicy(String workflowId) {
  switch (workflowId) {
    case 'export-import-preview':
    case 'export-import-replay':
    case 'export-protected-redaction':
    case 'export-schema-listing':
    case 'export-redacted-bundle':
    case 'export-checksum-evidence':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['export-owner'],
        readOnlyPersonaIds: ['export-member', 'export-provider'],
        readOnlyText:
            'Non-owner personas inspect redacted portability evidence.',
      );
    case 'export-full-bundle':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['export-owner'],
        receiverPersonaIds: ['export-provider'],
        readOnlyPersonaIds: ['export-member'],
        receiverEntryText:
            'Export bundle is ready for receiving-provider validation.',
        receiverActionText: 'Receive bundle',
        receiverResultText: 'Receiving provider received the export bundle.',
      );
    case 'export-transfer-verification':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['export-provider'],
        receiverPersonaIds: ['export-owner'],
        readOnlyPersonaIds: ['export-member'],
        prerequisiteWorkflowId: 'export-full-bundle',
        receiverEntryText: 'Provider verification is ready for the data owner.',
        receiverActionText: 'Receive verification',
        receiverResultText:
            'Data owner received provider transfer verification.',
      );
    case 'export-transfer-rollback':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['export-provider'],
        receiverPersonaIds: ['export-owner'],
        readOnlyPersonaIds: ['export-member'],
        prerequisiteWorkflowId: 'export-checksum-evidence',
        receiverEntryText:
            'Provider rollback result is ready for the data owner.',
        receiverActionText: 'Receive rollback',
        receiverResultText: 'Data owner received provider rollback result.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['export-owner']);
}

const Map<String, LoomExperienceDefinition> _experienceByExtensionId = {
  'ext_garden_club': LoomExperienceDefinition(
    extensionId: 'ext_garden_club',
    displayName: 'Garden Club',
    tagline: 'Coordinate garden events and plant exchange requests.',
    accentColor: 0xff3a7d44,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'garden-event-rsvp',
        title: 'Garden event RSVP',
        entryText: 'Spring planting workshop is open for member RSVP.',
        actionText:
            'RSVP to the spring planting workshop through the Garden Club UI.',
        resultText: 'RSVP recorded for Spring planting workshop.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'plant-exchange-submission',
        title: 'Plant exchange submission',
        entryText: 'Members can offer seedlings and request exchange matches.',
        actionText:
            'Submit a basil seedling offer to the plant exchange workflow.',
        resultText: 'Plant exchange record created for basil seedlings.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'garden-export-custom-schemas',
        title: 'Garden export custom schemas',
        entryText: 'Garden event and plant exchange schemas are exportable.',
        actionText: 'Generate Garden Club export evidence for custom schemas.',
        resultText: 'Export includes garden_event and plant_exchange schemas.',
      ),
    ],
  ),
  'ext_book_club': LoomExperienceDefinition(
    extensionId: 'ext_book_club',
    displayName: 'Neighborhood Book Club',
    tagline: 'Nominate, vote, meet, discuss, and digest club selections.',
    accentColor: 0xff246b62,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'book-nomination',
        title: 'Book nomination',
        entryText: 'Nomination form is ready for the next monthly selection.',
        actionText: 'Submit Parable of the Sower as the member nomination.',
        resultText: 'Nomination saved for Parable of the Sower.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'book-vote',
        title: 'Book vote',
        entryText: 'Monthly poll accepts member votes.',
        actionText: 'Record one vote for Parable of the Sower.',
        resultText: 'Vote count updated for Parable of the Sower.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'book-meeting-rsvp',
        title: 'Meeting event RSVP',
        entryText: 'Discussion event has available capacity.',
        actionText: 'RSVP to Discuss Parable of the Sower.',
        resultText: 'Meeting RSVP ticket issued.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'book-discussion-message',
        title: 'Discussion message',
        entryText: 'Book discussion thread is open.',
        actionText: 'Post a discussion-prep message to the thread.',
        resultText: 'Discussion message posted to book_discussion.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'book-selection-publish',
        title: 'Selected-book publishing',
        entryText: 'Owner can publish the monthly winning selection.',
        actionText: 'Publish January selection for Parable of the Sower.',
        resultText: 'Selected-book announcement published.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'book-search-ai-digest',
        title: 'Search, AI answer, and digest',
        entryText: 'Public selection content is indexable for cited summaries.',
        actionText: 'Generate a cited digest for the Parable selection.',
        resultText: 'Digest generated with citation evidence.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'book-export-metadata',
        title: 'Book export metadata',
        entryText: 'Nomination and vote schemas are exportable.',
        actionText: 'Create export metadata for Book Club custom data.',
        resultText: 'Export includes book_nomination and book_vote schemas.',
      ),
    ],
  ),
  'ext_youth_soccer': LoomExperienceDefinition(
    extensionId: 'ext_youth_soccer',
    displayName: 'Riverside Youth Soccer',
    tagline: 'Manage guardian flows, teams, privacy, payments, and schedules.',
    accentColor: 0xff1f7a5c,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'soccer-guardian-join-approval',
        title: 'Guardian join and approval',
        entryText: 'Guardian membership request is waiting for approval.',
        actionText: 'Approve the guardian membership request.',
        resultText: 'Guardian membership is active.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'soccer-team-roster',
        title: 'Team and roster view',
        entryText: 'U10 Falcons team space is ready for roster display.',
        actionText: 'Open the U10 Falcons team roster.',
        resultText: 'Roster view displays U10 Falcons.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'soccer-minor-redaction',
        title: 'Protected minor-data redaction',
        entryText: 'Minor birthdate is stored behind protected permissions.',
        actionText: 'Read protected minor data through permission-gated UI.',
        resultText: 'Minor birthdate renders as redacted value 2***.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'soccer-registration-payment',
        title: 'Registration payment',
        entryText: 'Registration checkout is owned by Loom payment surface.',
        actionText: 'Pay the 125.00 USD registration dues.',
        resultText: 'Registration payment receipt recorded.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'soccer-practice-schedule',
        title: 'Practice schedule',
        entryText: 'Saturday practice event has capacity for the team.',
        actionText: 'Publish Saturday practice to the schedule.',
        resultText: 'Practice event scheduled with capacity 18.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'soccer-reminder-notification',
        title: 'Reminder notification',
        entryText: 'Practice reminder can be delivered to guardians.',
        actionText: 'Send Practice starts at 9 AM reminder.',
        resultText: 'Practice reminder delivered once.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'soccer-export-metadata',
        title: 'Youth soccer export metadata',
        entryText: 'Registration and roster schemas are exportable.',
        actionText: 'Generate protected export metadata for youth soccer.',
        resultText: 'Export metadata includes registration and roster schemas.',
      ),
    ],
  ),
  'ext_hoa': LoomExperienceDefinition(
    extensionId: 'ext_hoa',
    displayName: 'Cedar Commons HOA',
    tagline: 'Run dues, documents, facilities, reviews, and exports.',
    accentColor: 0xff3e6b8f,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'hoa-dues-payment',
        title: 'Dues payment',
        entryText: 'Quarterly dues checkout is ready.',
        actionText: 'Record a 450.00 USD HOA dues payment.',
        resultText: 'Dues payment receipt recorded.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-member-document',
        title: 'Member-visible document',
        entryText: 'Community Rules document is visible to members.',
        actionText: 'Open the member-visible governing document.',
        resultText: 'Community Rules document displayed.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-facility-reservation',
        title: 'Facility reservation and payment',
        entryText: 'Clubhouse Room A can be reserved with payment.',
        actionText: 'Reserve Clubhouse Room A and pay reservation fee.',
        resultText: 'Facility reservation held with payment.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-architectural-request',
        title: 'Architectural request',
        entryText: 'Fence color request is ready for workflow review.',
        actionText: 'Submit architectural request for committee review.',
        resultText: 'Architectural request case opened.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-committee-decision',
        title: 'Committee workflow decision',
        entryText: 'Committee review step is waiting.',
        actionText: 'Approve the architectural review workflow.',
        resultText: 'Workflow completed with approved decision.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-owner-notification',
        title: 'Owner notification',
        entryText: 'Owner notification can be delivered after decision.',
        actionText: 'Notify owner that the architectural request was approved.',
        resultText: 'Owner notification delivered.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-export-evidence',
        title: 'HOA export evidence',
        entryText: 'Documents, facilities, wallet, receipts, and cases export.',
        actionText: 'Generate HOA export coverage evidence.',
        resultText: 'Export includes HOA document and operational components.',
      ),
    ],
  ),
  'ext_mosque': LoomExperienceDefinition(
    extensionId: 'ext_mosque',
    displayName: 'Masjid Nur',
    tagline: 'Coordinate announcements, events, volunteers, giving, and care.',
    accentColor: 0xff2d6a4f,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'mosque-announcement',
        title: 'Public announcement',
        entryText: 'Ramadan community night announcement is ready.',
        actionText: 'Publish Ramadan community night announcement.',
        resultText: 'Public announcement published.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-event-rsvp',
        title: 'Community event RSVP',
        entryText: 'Community iftar event has available capacity.',
        actionText: 'RSVP to the community iftar.',
        resultText: 'Community iftar RSVP ticket issued.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-volunteer-signup',
        title: 'Volunteer signup',
        entryText: 'Iftar volunteer form protects contact details.',
        actionText: 'Submit setup shift with protected phone field.',
        resultText: 'Volunteer signup saved and phone field protected.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-donor-visibility',
        title: 'Anonymous donor visibility',
        entryText: 'Donation visibility preference is member-owned.',
        actionText: 'Set donor visibility to anonymous.',
        resultText: 'Donor visibility preference saved as anonymous.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-donation-payment',
        title: 'Donation payment and receipt',
        entryText: 'Donation checkout is available through Loom wallet.',
        actionText: 'Record a 50.00 USD donation.',
        resultText: 'Donation payment receipt recorded.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-care-request',
        title: 'Protected care request',
        entryText:
            'Care request form separates public summary and private details.',
        actionText:
            'Submit a meal-support care request with protected details.',
        resultText: 'Care request saved with protected details redacted.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-neutral-notification',
        title: 'Neutral care notification',
        entryText:
            'Care request acknowledgement avoids sensitive detail leakage.',
        actionText: 'Send neutral care-request receipt notification.',
        resultText: 'Neutral care-request notification delivered.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'mosque-search-ai-citation',
        title: 'Announcement search and AI citation',
        entryText: 'Public announcement can be searched and cited.',
        actionText: 'Ask for iftar information from indexed announcements.',
        resultText: 'AI answer includes public announcement citation.',
      ),
    ],
  ),
  'ext_chess_club': LoomExperienceDefinition(
    extensionId: 'ext_chess_club',
    displayName: 'Chess Club',
    tagline: 'Open the club home and record friendly match results.',
    accentColor: 0xff58432f,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'chess-local-install-open',
        title: 'Arbitrary install and open',
        entryText: 'Chess Club was loaded from arbitrary package contents.',
        actionText: 'Confirm parsed branding and local latest route.',
        resultText: 'Chess Club arbitrary package opened locally.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'chess-route-home',
        title: 'Route-defined home',
        entryText: 'Chess Club route renders a domain-specific home.',
        actionText: 'Open the Chess Club home workflow route.',
        resultText: 'Chess Club home route rendered.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'chess-match-result',
        title: 'Match result record',
        entryText: 'Members can record a friendly match result.',
        actionText: 'Record a match result for Board 1.',
        resultText: 'Chess match result saved for Board 1.',
      ),
    ],
  ),
  'ext_camera_club': LoomExperienceDefinition(
    extensionId: 'ext_camera_club',
    displayName: 'Camera Club',
    tagline: 'Plan photo walks, critique work, and loan gear.',
    accentColor: 0xff465c7b,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'photo-walk-rsvp',
        title: 'Photo-walk RSVP',
        entryText: 'Downtown photo walk is accepting member RSVPs.',
        actionText: 'RSVP to the next photo walk.',
        resultText: 'Photo-walk RSVP recorded.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'critique-submission',
        title: 'Critique submission',
        entryText: 'Critique board accepts new photo submissions.',
        actionText: 'Submit a street portrait for critique.',
        resultText: 'Critique submission saved.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'gear-loan-request',
        title: 'Gear-loan request',
        entryText: 'Members can request shared gear loans.',
        actionText: 'Request the 35mm prime lens loan.',
        resultText: 'Gear-loan request created and pending review.',
      ),
    ],
  ),
  'ext_platform_social': LoomExperienceDefinition(
    extensionId: 'ext_platform_social',
    displayName: 'Member Social Space',
    tagline: 'Manage messages, connections, and sponsored-message settings.',
    accentColor: 0xff315c8a,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'platform-messages-entry',
        title: 'Messages entry',
        entryText: 'Shell-owned Messages surface is visible.',
        actionText: 'Open Messages entry from the app bar.',
        resultText: 'Messages entry is reachable.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-connections-entry',
        title: 'Connections entry',
        entryText: 'Shell-owned Connections surface is visible.',
        actionText: 'Open Connections entry from the app bar.',
        resultText: 'Connections entry is reachable.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-connection-invite',
        title: 'Connection invite',
        entryText: 'Member can invite an unblocked owner connection.',
        actionText: 'Send connection invite.',
        resultText: 'Connection invite state is invited.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-blocked-target',
        title: 'Blocked-target prevention',
        entryText: 'Blocked target cannot receive a connection invite.',
        actionText: 'Attempt blocked-target invite.',
        resultText: 'Blocked-target invite prevented.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-message-stream',
        title: 'Message stream rendering',
        entryText: 'Community general thread has messages.',
        actionText: 'Render the community message stream.',
        resultText: 'Message stream renders two messages.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-in-stream-ad',
        title: 'In-stream ad disclosure',
        entryText: 'In-stream ad slot can fill with disclosure.',
        actionText: 'Render sponsored in-stream ad item.',
        resultText: 'Sponsored disclosure is visible.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-top-banner-no-fill',
        title: 'Top-banner fill and no-fill',
        entryText: 'Required top banner ad slot is preserved.',
        actionText: 'Evaluate top banner fill and no-fill states.',
        resultText: 'Top banner records required no-fill state.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-sensitive-no-fill',
        title: 'Sensitive-context no-fill',
        entryText: 'Sensitive contexts suppress ad fills.',
        actionText: 'Request ad decision in sensitive context.',
        resultText: 'Sensitive-context ad decision is no-fill.',
      ),
    ],
  ),
  'ext_ad_off': LoomExperienceDefinition(
    extensionId: 'ext_ad_off',
    displayName: 'Ad-Free Community',
    tagline: 'Manage ad-free options, receipts, and member benefits.',
    accentColor: 0xff5b5f97,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'ad-off-member-checkout',
        title: 'Member ad-off checkout',
        entryText: 'Member ad-off purchase is shell-owned.',
        actionText: 'Complete member ad-off checkout.',
        resultText: 'Member ad-off entitlement active.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-community-checkout',
        title: 'Community ad-off checkout',
        entryText: 'Community-wide ad-off purchase is shell-owned.',
        actionText: 'Complete community ad-off checkout.',
        resultText: 'Community ad-off entitlement active.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-entitlement-status',
        title: 'Entitlement status',
        entryText: 'Ad-off entitlement can be restored and checked.',
        actionText: 'Verify member and community entitlement status.',
        resultText: 'Entitlement status shows active.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-receipt-evidence',
        title: 'Receipt evidence',
        entryText: 'Ad-off purchases link to receipt ledger records.',
        actionText: 'Open ad-off receipt evidence.',
        resultText: 'Ad-off receipt evidence displayed.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-ad-suppression',
        title: 'Ad suppression',
        entryText: 'Ad decision changes after entitlement.',
        actionText: 'Evaluate ad decision after ad-off purchase.',
        resultText: 'Ads suppressed by ad-off entitlement.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-settlement-utility',
        title: 'Settlement and utility allocation',
        entryText: 'Ad-off economics produce auditable settlement records.',
        actionText: 'Calculate settlement and utility allocation.',
        resultText: 'Settlement and utility allocation recorded.',
      ),
    ],
  ),
  'ext_export_migration': LoomExperienceDefinition(
    extensionId: 'ext_export_migration',
    displayName: 'Data Portability Community',
    tagline: 'Move community data with redaction and transfer checks.',
    accentColor: 0xff536878,
    workflows: [
      LoomWorkflowDefinition(
        workflowId: 'export-import-preview',
        title: 'Import preview',
        entryText: 'Legacy import can be previewed for sensitive fields.',
        actionText: 'Preview legacy CSV import.',
        resultText: 'Import preview reports one sensitive field.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-import-replay',
        title: 'Import replay and idempotency',
        entryText: 'Import replay should reuse the committed import result.',
        actionText: 'Replay import with the same idempotency key.',
        resultText: 'Import replay returns the existing import result.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-protected-redaction',
        title: 'Protected field routing and redaction',
        entryText: 'Imported phone number routes to protected vault.',
        actionText: 'Open protected field redaction evidence.',
        resultText: 'Protected phone field renders redacted.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-schema-listing',
        title: 'Exportable custom-schema listing',
        entryText: 'Custom member note schema is exportable.',
        actionText: 'List exportable extension schemas.',
        resultText: 'custom_member_note appears in exportable schema list.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-full-bundle',
        title: 'Full export bundle',
        entryText: 'Full export includes documents and receipts.',
        actionText: 'Create full export bundle.',
        resultText: 'Full export bundle includes document and receipt IDs.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-redacted-bundle',
        title: 'Redacted export bundle',
        entryText: 'Redacted export excludes protected raw values.',
        actionText: 'Create redacted export bundle.',
        resultText: 'Redacted export marks protected vault as redacted.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-checksum-evidence',
        title: 'Checksum evidence',
        entryText: 'Export bundle should carry checksum evidence.',
        actionText: 'Verify export checksum.',
        resultText: 'Export checksum evidence recorded.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-transfer-verification',
        title: 'Provider transfer verification',
        entryText: 'Provider transfer can be verified after export.',
        actionText: 'Verify provider transfer.',
        resultText: 'Provider transfer verified.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'export-transfer-rollback',
        title: 'Provider transfer rollback',
        entryText: 'Failed target checksum can trigger rollback.',
        actionText: 'Rollback provider transfer after checksum mismatch.',
        resultText: 'Provider transfer rolled back.',
      ),
    ],
  ),
};
