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
  late final ScrollController _communityScrollController;
  String? _lastLocalImportMessage;
  String? _focusedCommunityId;

  @override
  void initState() {
    super.initState();
    _communityScrollController = ScrollController()
      ..addListener(_updateFocusedCommunityFromScroll);
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

  @override
  void dispose() {
    _communityScrollController
      ..removeListener(_updateFocusedCommunityFromScroll)
      ..dispose();
    super.dispose();
  }

  void _updateFocusedCommunityFromScroll() {
    if (!_communityScrollController.hasClients) {
      return;
    }
    final communities = _backend.listCommunities();
    if (communities.isEmpty) {
      return;
    }
    final estimatedIndex = (_communityScrollController.offset / 132)
        .round()
        .clamp(0, communities.length - 1);
    final nextFocused = communities[estimatedIndex].communityId;
    if (nextFocused != _focusedCommunityId && mounted) {
      setState(() => _focusedCommunityId = nextFocused);
    }
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
    final focusedCommunityId =
        _focusedCommunityId ??
        (communities.isNotEmpty ? communities.first.communityId : null);
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
                    controller: _communityScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                    itemCount: communities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      final experience = experienceForExtensionId(
                        community.extensionId,
                        displayName: community.displayName,
                      );
                      final presentationState =
                          community.communityId == focusedCommunityId
                          ? _SurfacePresentationState.medium
                          : _SurfacePresentationState.minimized;
                      return _CommunityLaunchCard(
                        key: ValueKey(
                          'community-card-${community.communityId}',
                        ),
                        community: community,
                        experience: experience,
                        state: presentationState,
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

enum _SurfacePresentationState { minimized, medium, expanded }

class _CommunityLaunchCard extends StatelessWidget {
  const _CommunityLaunchCard({
    super.key,
    required this.community,
    required this.experience,
    required this.state,
    required this.onTap,
  });

  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
  final _SurfacePresentationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(experience.accentColor);
    final textTheme = Theme.of(context).textTheme;
    final isFocused = state == _SurfacePresentationState.medium;
    final background = isFocused
        ? Color.alphaBlend(accent.withValues(alpha: 0.10), Colors.white)
        : Color.alphaBlend(accent.withValues(alpha: 0.05), Colors.white);
    final logoRadius = isFocused ? 34.0 : 26.0;

    return Semantics(
      button: true,
      selected: isFocused,
      label: '${community.displayName} community card',
      child: Card(
        elevation: isFocused ? 3 : 1,
        margin: EdgeInsets.zero,
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isFocused ? 18 : 14),
          side: BorderSide(
            color: accent.withValues(alpha: isFocused ? 0.18 : 0.08),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(isFocused ? 18 : 14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              isFocused ? 18 : 14,
              isFocused ? 18 : 12,
              isFocused ? 18 : 14,
              isFocused ? 18 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  key: ValueKey(
                    'community-card-identity-${community.communityId}',
                  ),
                  radius: logoRadius,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  child: Icon(
                    _communityIconFor(experience.extensionId),
                    size: isFocused ? 34 : 25,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.displayName,
                        maxLines: isFocused ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (isFocused
                                    ? textTheme.headlineSmall
                                    : textTheme.titleLarge)
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xff172421),
                                ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        experience.tagline,
                        maxLines: isFocused ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          color: const Color(0xff43534f),
                          height: 1.28,
                        ),
                      ),
                      if (isFocused) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SurfaceFactPill(
                              icon: Icons.home_outlined,
                              label: 'Open community',
                              foreground: accent,
                            ),
                            _SurfaceFactPill(
                              icon: Icons.palette_outlined,
                              label: 'Theme applied',
                              foreground: accent,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isFocused) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: accent, size: 30),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
  final Map<String, String> _selectedTabIdByPersonaId = {};
  final Map<String, String> _focusedWorkflowIdByPersonaTab = {};
  final Map<String, GlobalKey> _workflowSurfaceKeysById = {};
  late final ScrollController _surfaceScrollController;
  List<String> _visibleWorkflowIds = const [];
  String? _activeSurfaceFocusKey;
  String? _expandedWorkflowId;
  String? _selectedPersonaId;

  LocalInstalledCommunity get community => widget.community;
  List<String> get seedDataFiles => widget.seedDataFiles;
  String get _route => 'local:${community.extensionId}@latest';

  String _routeForSelectedSurface({
    required LoomExperienceDefinition experience,
    required LoomAppShellTabSpec selectedTab,
    required String? focusedWorkflowId,
  }) {
    if (focusedWorkflowId == null) {
      return '$_route/tabs/${selectedTab.tabId}';
    }
    LoomWorkflowDefinition? workflow;
    for (final candidate in experience.workflows) {
      if (candidate.workflowId == focusedWorkflowId) {
        workflow = candidate;
        break;
      }
    }
    if (workflow == null) {
      return '$_route/tabs/${selectedTab.tabId}';
    }
    final registry = cardSurfaceRegistryEntryFor(
      extensionId: experience.extensionId,
      workflow: workflow,
    );
    return '$_route${registry.routeTemplate.replaceAll(':workflowId', workflow.workflowId)}';
  }

  @override
  void initState() {
    super.initState();
    _surfaceScrollController = ScrollController()
      ..addListener(_updateFocusedSurfaceFromScroll);
  }

  @override
  void dispose() {
    _surfaceScrollController
      ..removeListener(_updateFocusedSurfaceFromScroll)
      ..dispose();
    super.dispose();
  }

  void _updateFocusedSurfaceFromScroll() {
    final focusKey = _activeSurfaceFocusKey;
    if (focusKey == null ||
        _visibleWorkflowIds.isEmpty ||
        !_surfaceScrollController.hasClients) {
      return;
    }
    final viewportHeight = MediaQuery.maybeOf(context)?.size.height ?? 0;
    final topBound = MediaQuery.maybeOf(context)?.padding.top ?? 0;
    final bottomBound =
        viewportHeight -
        (MediaQuery.maybeOf(context)?.padding.bottom ?? 0) -
        96;
    var nextFocused = _visibleWorkflowIds.first;
    var largestVisibleExtent = -1.0;
    for (final workflowId in _visibleWorkflowIds) {
      final key = _workflowSurfaceKeysById[workflowId];
      final keyContext = key?.currentContext;
      if (keyContext == null) {
        continue;
      }
      final renderObject = keyContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final top = topLeft.dy;
      final bottom = top + renderObject.size.height;
      final visibleExtent =
          bottom.clamp(topBound, bottomBound) -
          top.clamp(topBound, bottomBound);
      if (visibleExtent > largestVisibleExtent) {
        largestVisibleExtent = visibleExtent;
        nextFocused = workflowId;
      }
    }
    if (_focusedWorkflowIdByPersonaTab[focusKey] != nextFocused && mounted) {
      setState(() {
        _focusedWorkflowIdByPersonaTab[focusKey] = nextFocused;
        if (_expandedWorkflowId != null &&
            !_visibleWorkflowIds.contains(_expandedWorkflowId)) {
          _expandedWorkflowId = null;
        }
      });
    }
  }

  GlobalKey _surfaceKeyForWorkflow(String workflowId) {
    return _workflowSurfaceKeysById.putIfAbsent(workflowId, GlobalKey.new);
  }

  void _expandWorkflowSurface({
    required String workflowId,
    required String focusKey,
  }) {
    setState(() {
      _focusedWorkflowIdByPersonaTab[focusKey] = workflowId;
      _expandedWorkflowId = workflowId;
    });
  }

  void _collapseWorkflowSurface(String workflowId) {
    if (_expandedWorkflowId == workflowId) {
      setState(() => _expandedWorkflowId = null);
    }
  }

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
    _focusWorkflowAfterAction(
      workflow,
      mutateState: () => _completedWorkflowIds.add(workflow.workflowId),
    );
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
    _focusWorkflowAfterAction(
      workflow,
      mutateState: () => _receivedWorkflowPersonaKeys.add(
        workflowPersonaReceiptKey(
          workflowId: workflow.workflowId,
          personaId: persona.personaId,
        ),
      ),
    );
  }

  void _focusWorkflowAfterAction(
    LoomWorkflowDefinition workflow, {
    required VoidCallback mutateState,
  }) {
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
    );
    final activePersona = _activePersona(experience);
    final tabSpecs = appShellTabsFor(
      experience: experience,
      personaId: activePersona.personaId,
      appShellConfiguration: community.appShellConfiguration,
    );
    final targetTab = tabSpecs.firstWhere(
      (tab) => tab.matchesWorkflow(
        extensionId: experience.extensionId,
        workflow: workflow,
      ),
      orElse: () => tabSpecs.first,
    );
    final focusKey = '${activePersona.personaId}:${targetTab.tabId}';
    setState(() {
      mutateState();
      _selectedTabIdByPersonaId[activePersona.personaId] = targetTab.tabId;
      _focusedWorkflowIdByPersonaTab[focusKey] = workflow.workflowId;
      _expandedWorkflowId = workflow.workflowId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final surfaceContext = _surfaceKeyForWorkflow(
        workflow.workflowId,
      ).currentContext;
      if (surfaceContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        surfaceContext,
        alignment: 0.16,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
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
          title: const Text('Account role and permissions'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your memberships determine which community actions are available. Choose the role you want to use in this community.',
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
      _selectedTabIdByPersonaId.putIfAbsent(selected, () => 'home');
    });
  }

  Widget _workflowPresenterFor({
    required LoomExperienceDefinition experience,
    required LoomPersonaDefinition activePersona,
    required LoomWorkflowDefinition workflow,
    required _SurfacePresentationState state,
    required Color accent,
    required String focusKey,
  }) {
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
    final workflowTile = _WorkflowTile(
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
    return KeyedSubtree(
      key: _surfaceKeyForWorkflow(workflow.workflowId),
      child: _WorkflowSurfacePresenter(
        extensionId: experience.extensionId,
        workflow: workflow,
        view: view,
        state: state,
        accent: accent,
        child: workflowTile,
        onPressed: () => _confirmWorkflow(workflow),
        onReceivePressed: () => _receiveWorkflow(
          workflow: workflow,
          persona: activePersona,
          policy: policy,
        ),
        onExpand: () => _expandWorkflowSurface(
          workflowId: workflow.workflowId,
          focusKey: focusKey,
        ),
        onCollapse: () => _collapseWorkflowSurface(workflow.workflowId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
    );
    final activePersona = _activePersona(experience);
    final tabSpecs = appShellTabsFor(
      experience: experience,
      personaId: activePersona.personaId,
      appShellConfiguration: community.appShellConfiguration,
    );
    final selectedTabId = _selectedTabIdFor(
      personaId: activePersona.personaId,
      tabs: tabSpecs,
    );
    final selectedTab = tabSpecs.firstWhere(
      (tab) => tab.tabId == selectedTabId,
    );
    final selectedSections = _communitySectionsForTab(
      experience: experience,
      tab: selectedTab,
    );
    final visibleWorkflowIds = [
      for (final section in selectedSections)
        for (final workflow in section.workflows) workflow.workflowId,
    ];
    final shellSpec = CommunityAppShellCustomizationSpec.fromSelection(
      experience: experience,
      persona: activePersona,
      tabs: tabSpecs,
      selectedTab: selectedTab,
      visibleWorkflowIds: visibleWorkflowIds,
      focusedWorkflowId:
          _focusedWorkflowIdByPersonaTab['${activePersona.personaId}:${selectedTab.tabId}'] ??
          (visibleWorkflowIds.isNotEmpty ? visibleWorkflowIds.first : null),
      expandedWorkflowId: _expandedWorkflowId,
    );
    final focusKey = shellSpec.focusKey;
    _activeSurfaceFocusKey = focusKey;
    _visibleWorkflowIds = shellSpec.visibleWorkflowIds;
    final focusedWorkflowId = shellSpec.focusedWorkflowId;
    final currentRoute = _routeForSelectedSurface(
      experience: experience,
      selectedTab: selectedTab,
      focusedWorkflowId: focusedWorkflowId,
    );
    final textTheme = Theme.of(context).textTheme;
    final accent = shellSpec.theme.accent;
    final background = shellSpec.theme.background;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        toolbarHeight: 88,
        title: Text(
          community.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const ValueKey('messages-button'),
            tooltip: 'Messages',
            onPressed: () => setState(() {
              _selectedTabIdByPersonaId[activePersona.personaId] = 'messages';
            }),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            key: const ValueKey('persona-picker-button'),
            tooltip: 'Switch role',
            onPressed: () => _showPersonaPicker(experience, activePersona),
            icon: const Icon(Icons.people_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        key: ValueKey('local-extension-${community.extensionId}'),
        controller: _surfaceScrollController,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          shellSpec.theme.tabHeight + 48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        key: ValueKey(
                          'opened-base-route-${community.extensionId}',
                        ),
                      ),
                    ),
                    Offstage(
                      child: Text(
                        currentRoute,
                        key: ValueKey('opened-route-${community.extensionId}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SelectedTabHeader(
              tab: selectedTab,
              accent: accent,
              persona: activePersona,
            ),
            const SizedBox(height: 10),
            _TabNativeRenderer(
              experience: experience,
              persona: activePersona,
              selectedTab: selectedTab,
              sections: selectedSections,
              focusedWorkflowId: focusedWorkflowId,
              expandedWorkflowId: _expandedWorkflowId,
              accent: accent,
              theme: shellSpec.theme,
              workflowBuilder: (workflow, state) => _workflowPresenterFor(
                experience: experience,
                activePersona: activePersona,
                workflow: workflow,
                state: state,
                accent: accent,
                focusKey: focusKey,
              ),
            ),
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
      ),
      bottomNavigationBar: _CommunityBottomTabBar(
        tabs: tabSpecs,
        selectedTabId: selectedTabId,
        accent: accent,
        onSelected: (tabId) => setState(() {
          _selectedTabIdByPersonaId[activePersona.personaId] = tabId;
        }),
      ),
    );
  }

  String _selectedTabIdFor({
    required String personaId,
    required List<LoomAppShellTabSpec> tabs,
  }) {
    final selected = _selectedTabIdByPersonaId[personaId] ?? 'home';
    if (tabs.any((tab) => tab.tabId == selected)) {
      return selected;
    }
    return tabs.first.tabId;
  }
}

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
  });

  final LoomAppShellTabSpec tab;
  final Color accent;
  final LoomPersonaDefinition persona;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      key: ValueKey('selected-tab-${tab.tabId}'),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
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
                      color: foreground.withValues(alpha: 0.88),
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
    this.sections = const [],
    this.workflowBuilder,
    this.focusedWorkflowId,
    this.expandedWorkflowId,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final Color accent;
  final List<_CommunityWorkflowSection> sections;
  final _WorkflowSurfaceBuilder? workflowBuilder;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final messageWorkflows = [
      for (final section in sections)
        for (final workflow in section.workflows) workflow,
    ];
    return DecoratedBox(
      key: const ValueKey('messages-tab-surface'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
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
                color: foreground.withValues(alpha: 0.92),
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
              title: '${experience.displayName} coordination',
              sender: persona.label,
              preview:
                  'Unread updates, replies, invites, and action follow-up stay in one conversation surface.',
              timestamp: 'Today',
            ),
            const SizedBox(height: 12),
            _ThreadComposerPreview(accent: accent),
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
      _SurfacePresentationState state,
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
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final LoomAppShellTabSpec selectedTab;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final LoomThemeCustomizationTokens theme;
  final _WorkflowSurfaceBuilder workflowBuilder;

  @override
  Widget build(BuildContext context) {
    final rendererId = selectedTab.rendererContract.rendererId;
    switch (rendererId) {
      case 'CalendarTabSurface':
        return _CalendarTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          workflowBuilder: workflowBuilder,
        );
      case 'MessagesTabSurface':
        return _MessagesTabSurface(
          experience: experience,
          persona: persona,
          accent: accent,
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
          workflowBuilder: workflowBuilder,
        );
      case 'DocumentsTabSurface':
        return _DocumentsTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          workflowBuilder: workflowBuilder,
        );
      case 'WorkflowStatusSurface':
        return _WorkflowStatusTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          workflowBuilder: workflowBuilder,
        );
      case 'PaymentGivingTabSurface':
        return _PaymentGivingTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          workflowBuilder: workflowBuilder,
        );
      case 'CareVolunteerTabSurface':
        return _CareVolunteerTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
          workflowBuilder: workflowBuilder,
        );
      case 'AdminReviewComposeTabSurface':
        return _AdminReviewComposeTabSurface(
          experience: experience,
          sections: sections,
          focusedWorkflowId: focusedWorkflowId,
          expandedWorkflowId: expandedWorkflowId,
          accent: accent,
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

_SurfacePresentationState _presentationStateForWorkflow({
  required String workflowId,
  required String? focusedWorkflowId,
  required String? expandedWorkflowId,
}) {
  if (expandedWorkflowId == workflowId) {
    return _SurfacePresentationState.expanded;
  }
  if (focusedWorkflowId == workflowId) {
    return _SurfacePresentationState.medium;
  }
  return _SurfacePresentationState.minimized;
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
  final LoomThemeCustomizationTokens theme;
  final _WorkflowSurfaceBuilder workflowBuilder;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return _TabEmptyState(
        icon: Icons.home_outlined,
        title: 'Nothing is pinned yet',
        body:
            '${experience.displayName} does not have Home surfaces assigned yet.',
        accent: accent,
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
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
  final _WorkflowSurfaceBuilder workflowBuilder;

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
      );
    }
    final selected = workflows.firstWhere(
      (workflow) => workflow.workflowId == focusedWorkflowId,
      orElse: () => workflows.first,
    );
    return Column(
      key: const ValueKey('calendar-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekDateStrip(accent: accent),
        const SizedBox(height: 12),
        _TabNativeSummary(
          icon: Icons.event_available_outlined,
          title: _displayTitleFor(selected),
          body:
              'Agenda detail includes date, time, location, host, capacity, response choices, reminders, and linked workflow state.',
          accent: accent,
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
}

class _MarketplaceTabSurface extends StatelessWidget {
  const _MarketplaceTabSurface({
    required this.experience,
    required this.sections,
    required this.focusedWorkflowId,
    required this.expandedWorkflowId,
    required this.accent,
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
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
      );
    }
    return Column(
      key: const ValueKey('marketplace-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MarketplaceSearchHeader(accent: accent),
        const SizedBox(height: 12),
        _TabNativeSummary(
          icon: Icons.inventory_2_outlined,
          title: '${experience.displayName} marketplace',
          body:
              'Browse available items, inspect listing details, join a queue, see current-holder state, or list an item.',
          accent: accent,
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
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
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
      );
    }
    return Column(
      key: const ValueKey('documents-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DocumentLibraryHeader(accent: accent),
        const SizedBox(height: 12),
        _TabNativeSummary(
          icon: Icons.description_outlined,
          title: '${experience.displayName} document library',
          body:
              'Library categories, document details, embedded open, external open, versions, and access state are grouped here.',
          accent: accent,
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
    required this.workflowBuilder,
  });

  final LoomExperienceDefinition experience;
  final List<_CommunityWorkflowSection> sections;
  final String? focusedWorkflowId;
  final String? expandedWorkflowId;
  final Color accent;
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
      );
    }
    return Column(
      key: const ValueKey('workflow-status-tab-surface'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusTimelinePreview(accent: accent),
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
    required super.workflowBuilder,
  });
}

class _TabNativeSummary extends StatelessWidget {
  const _TabNativeSummary({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.facts,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(foreground.withValues(alpha: 0.08), accent),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
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
                          color: foreground.withValues(alpha: 0.90),
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
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
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

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
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
              color: selected ? accent : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
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
  const _MarketplaceSearchHeader({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      key: const ValueKey('marketplace-browse-search'),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
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
  const _DocumentLibraryHeader({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('documents-library-header'),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
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
  const _StatusTimelinePreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    const steps = ['Submitted', 'Review', 'Changes', 'Approved'];
    return DecoratedBox(
      key: const ValueKey('workflow-status-timeline-preview'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
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
                          color: foreground.withValues(alpha: 0.92),
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
    required this.title,
    required this.sender,
    required this.preview,
    required this.timestamp,
  });

  final Color accent;
  final String title;
  final String sender;
  final String preview;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
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
  const _ThreadComposerPreview({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
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

class _RichFact {
  const _RichFact({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

enum _RichWorkflowLayout {
  standard,
  eventDetail,
  formSubmission,
  paymentReceipt,
  rosterProfile,
  requestReview,
  searchAnswer,
  exportWizard,
  messageThread,
  noticeDetail,
  clubScoreboard,
  mediaReview,
  adEntitlement,
}

class _RichWorkflowSpec {
  const _RichWorkflowSpec({
    this.layout = _RichWorkflowLayout.standard,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.facts,
    required this.actionSurfaceTitle,
    required this.actionHeroSubtitle,
    required this.actionHeroBody,
    required this.actionPanelTitle,
    required this.actionPanelBody,
    required this.alternateActionLabel,
    required this.detailTitle,
    required this.detailRows,
    required this.stateTitle,
    required this.stateRows,
    required this.completeTitle,
    required this.completeBody,
    required this.receivedTitle,
    required this.receivedBody,
    required this.completeLabel,
  });

  final _RichWorkflowLayout layout;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final List<_RichFact> facts;
  final String actionSurfaceTitle;
  final String actionHeroSubtitle;
  final String actionHeroBody;
  final String actionPanelTitle;
  final String actionPanelBody;
  final String alternateActionLabel;
  final String detailTitle;
  final List<_ActionSurfaceDetail> detailRows;
  final String stateTitle;
  final List<_ActionSurfaceDetail> stateRows;
  final String completeTitle;
  final String completeBody;
  final String receivedTitle;
  final String receivedBody;
  final String completeLabel;
}

_RichWorkflowSpec? _richWorkflowSpecFor(String workflowId) {
  switch (workflowId) {
    case 'garden-export-custom-schemas':
      return const _RichWorkflowSpec(
        accent: Color(0xff376f57),
        icon: Icons.folder_zip_outlined,
        title: 'Garden data export package',
        subtitle: 'Choose event and plant-exchange data before download.',
        body:
            'Export scope includes garden_event and plant_exchange schemas with protected contact fields redacted.',
        facts: [
          _RichFact(icon: Icons.dataset_outlined, label: '2 schemas selected'),
          _RichFact(
            icon: Icons.visibility_off_outlined,
            label: 'Redaction preview',
          ),
          _RichFact(icon: Icons.verified_outlined, label: 'Checksum verified'),
          _RichFact(icon: Icons.download_outlined, label: 'Download ready'),
        ],
        actionSurfaceTitle: 'Garden export package',
        actionHeroSubtitle: 'garden_event + plant_exchange',
        actionHeroBody:
            'Confirm selected data, protected-field redaction, checksum, and destination before generating the export.',
        actionPanelTitle: 'Export package checkpoint',
        actionPanelBody:
            'The package will include event attendance, plant offers, redacted member contact fields, and an audit checksum.',
        alternateActionLabel: 'Change scope',
        detailTitle: 'Package contents',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.dataset_outlined,
            title: 'Scope',
            body:
                'Selected data: garden_event, plant_exchange, RSVP choice, offer status, and export metadata.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Redaction preview',
            body:
                'Member phone, address, and private pickup notes are protected before transfer.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Checksum',
            body:
                'Checksum 8F4A-PLANT verifies the package and appears in the audit trail.',
          ),
        ],
        stateTitle: 'Transfer record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.download_outlined,
            title: 'Destination',
            body:
                'Download to owner device first; provider transfer remains disabled until owner confirms.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Rollback',
            body:
                'Change scope or cancel export before the package is generated.',
          ),
        ],
        completeTitle: 'Export generated',
        completeBody:
            'Garden Club export is ready with redaction preview, checksum 8F4A-PLANT, and download progress.',
        receivedTitle: 'Export progress ready',
        receivedBody:
            'The owner can open export scope, redaction, checksum, and transfer progress.',
        completeLabel: 'Exported',
      );
    case 'book-nomination':
      return const _RichWorkflowSpec(
        accent: Color(0xff5f4b8b),
        icon: Icons.menu_book_outlined,
        title: 'Nominate Parable of the Sower',
        subtitle: 'Octavia E. Butler - February reading cycle.',
        body:
            'Share why this title belongs on the ballot and how it fits the upcoming discussion.',
        facts: [
          _RichFact(icon: Icons.title_outlined, label: 'Book title entered'),
          _RichFact(icon: Icons.person_outline, label: 'Author confirmed'),
          _RichFact(icon: Icons.forum_outlined, label: 'Discussion reason'),
          _RichFact(icon: Icons.how_to_vote_outlined, label: 'Ballot eligible'),
        ],
        actionSurfaceTitle: 'Book nomination',
        actionHeroSubtitle: 'Parable of the Sower by Octavia E. Butler',
        actionHeroBody:
            'Confirm the title, author, member rationale, genre, and meeting cycle before submitting the nomination.',
        actionPanelTitle: 'Nomination details',
        actionPanelBody:
            'The nomination will be visible to members for the February vote and tied to the discussion meeting.',
        alternateActionLabel: 'Edit nomination',
        detailTitle: 'Nomination details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.title_outlined,
            title: 'Title and author',
            body: 'Parable of the Sower - Octavia E. Butler.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.lightbulb_outline,
            title: 'Member rationale',
            body:
                'Chosen for a timely discussion on resilience, community, and care.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.event_outlined,
            title: 'Meeting cycle',
            body: 'February vote, March living-room discussion.',
          ),
        ],
        stateTitle: 'Ballot record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.how_to_vote_outlined,
            title: 'Vote connection',
            body:
                'After submission, members can compare nominations and cast one vote.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.edit_note_outlined,
            title: 'Change option',
            body:
                'Edit nomination details before voting opens or withdraw if the title is no longer available.',
          ),
        ],
        completeTitle: 'Nomination submitted',
        completeBody:
            'Parable of the Sower is on the February ballot with title, author, rationale, and meeting context.',
        receivedTitle: 'Nomination ready',
        receivedBody:
            'Members can read the nomination, compare vote options, and prepare for discussion.',
        completeLabel: 'Submitted',
      );
    case 'book-vote':
      return const _RichWorkflowSpec(
        accent: Color(0xff4e5fa8),
        icon: Icons.how_to_vote_outlined,
        title: 'February book ballot',
        subtitle: 'Vote between three member nominations.',
        body:
            'Parable of the Sower is leading the ballot for the next monthly discussion.',
        facts: [
          _RichFact(icon: Icons.menu_book_outlined, label: '3 nominations'),
          _RichFact(icon: Icons.schedule_outlined, label: 'Closes Jan 20'),
          _RichFact(icon: Icons.how_to_vote_outlined, label: '1 member vote'),
          _RichFact(icon: Icons.star_outline, label: 'Leading title'),
        ],
        actionSurfaceTitle: 'Cast book vote',
        actionHeroSubtitle: 'February selection ballot',
        actionHeroBody:
            'Compare nominated books, confirm your vote, and keep the chosen discussion book visible after voting.',
        actionPanelTitle: 'Ballot choice',
        actionPanelBody:
            'Your vote will count once for Parable of the Sower and can be changed before the ballot closes.',
        alternateActionLabel: 'Change vote',
        detailTitle: 'Ballot options',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Parable of the Sower',
            body: 'Current leader with 9 votes and a member discussion note.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'The Memory Police',
            body: 'Second place with 6 votes.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Braiding Sweetgrass',
            body: 'Third place with 5 votes.',
          ),
        ],
        stateTitle: 'Vote saved',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Vote state',
            body: 'Your selected book and vote timestamp remain visible.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.swap_horiz_outlined,
            title: 'Change option',
            body: 'Change vote remains available until Jan 20 at 8 PM.',
          ),
        ],
        completeTitle: 'Vote confirmed',
        completeBody:
            'Your vote for Parable of the Sower is confirmed, status is saved, and it can be changed before the ballot closes.',
        receivedTitle: 'Vote result ready',
        receivedBody:
            'The selected book, vote count, and meeting context are visible to members.',
        completeLabel: 'Voted',
      );
    case 'book-meeting-rsvp':
      return const _RichWorkflowSpec(
        accent: Color(0xff2f6f9f),
        icon: Icons.event_available_outlined,
        title: 'Parable discussion night',
        subtitle: 'Thu, Feb 15 at 7:00 PM - Maya\'s living room.',
        body:
            'Reserve a seat for the discussion and see host, location, capacity, and reminder status.',
        facts: [
          _RichFact(icon: Icons.calendar_today_outlined, label: 'Thu, Feb 15'),
          _RichFact(icon: Icons.schedule_outlined, label: '7:00 PM'),
          _RichFact(icon: Icons.place_outlined, label: 'Maya\'s living room'),
          _RichFact(icon: Icons.group_outlined, label: '10 of 14 spots'),
        ],
        actionSurfaceTitle: 'Book meeting RSVP',
        actionHeroSubtitle: 'Parable of the Sower discussion',
        actionHeroBody:
            'Confirm the meeting title, date, venue, host, capacity, and current RSVP before saving your response.',
        actionPanelTitle: 'Choose attendance',
        actionPanelBody:
            'Going reserves a seat and sends a reminder. Maybe keeps the meeting on your calendar without taking capacity.',
        alternateActionLabel: 'Change response',
        detailTitle: 'Meeting details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Host',
            body: 'Maya Chen hosts the February discussion.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Selected book',
            body: 'Parable of the Sower by Octavia E. Butler.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.group_outlined,
            title: 'Capacity',
            body: '10 attending, 4 seats open, waitlist starts at 14.',
          ),
        ],
        stateTitle: 'Response options',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Going',
            body: 'Reserve a seat and add a reminder to your inbox.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.help_outline,
            title: 'Maybe or not attending',
            body: 'Change response or release your seat before the meeting.',
          ),
        ],
        completeTitle: 'RSVP confirmed',
        completeBody:
            'You are going to the Parable discussion; seat count, reminder, and change response stay visible.',
        receivedTitle: 'Meeting update ready',
        receivedBody:
            'The meeting page shows book, date, venue, capacity, and your RSVP choice.',
        completeLabel: 'Going',
      );
    case 'book-discussion-message':
      return const _RichWorkflowSpec(
        accent: Color(0xff6f4e7c),
        icon: Icons.forum_outlined,
        title: 'Discussion thread',
        subtitle: 'Prompt: What does community care require?',
        body:
            'Reply to the Parable discussion with a note scoped to club members.',
        facts: [
          _RichFact(icon: Icons.person_outline, label: 'From Jordan'),
          _RichFact(icon: Icons.group_outlined, label: 'Members only'),
          _RichFact(icon: Icons.mark_email_unread_outlined, label: '3 unread'),
          _RichFact(icon: Icons.lock_outline, label: 'Club scoped'),
        ],
        actionSurfaceTitle: 'Reply to discussion',
        actionHeroSubtitle: 'Parable discussion thread',
        actionHeroBody:
            'Read the prompt, sender, audience, and member replies before posting your discussion note.',
        actionPanelTitle: 'Message delivery',
        actionPanelBody:
            'Your reply will appear in the club thread and stay scoped to current members.',
        alternateActionLabel: 'Archive thread',
        detailTitle: 'Thread context',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.question_answer_outlined,
            title: 'Prompt',
            body: 'What does community care require when resources are scarce?',
          ),
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Latest sender',
            body: 'Jordan posted a discussion-prep message this morning.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.message_outlined,
            title: 'Message body',
            body: 'Bring one quote that changed how you read the ending.',
          ),
        ],
        stateTitle: 'Conversation record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.reply_outlined,
            title: 'Reply option',
            body: 'Reply, mute, archive, or return later without losing place.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.lock_outline,
            title: 'Privacy',
            body: 'Only active book club members can read or reply.',
          ),
        ],
        completeTitle: 'Reply sent',
        completeBody:
            'Your discussion message is posted to the Parable thread with sender and member scope.',
        receivedTitle: 'Thread updated',
        receivedBody:
            'Members see sender, message body, unread receipt, and reply action.',
        completeLabel: 'Sent',
      );
    case 'book-selection-publish':
      return const _RichWorkflowSpec(
        accent: Color(0xff286b5f),
        icon: Icons.campaign_outlined,
        title: 'Publish February selection',
        subtitle: 'Parable of the Sower won the member vote.',
        body:
            'Send the selected-book announcement with audience, author, message body, and delivery timing.',
        facts: [
          _RichFact(icon: Icons.group_outlined, label: 'Audience: members'),
          _RichFact(icon: Icons.person_outline, label: 'From organizer'),
          _RichFact(icon: Icons.today_outlined, label: 'Today 5:00 PM'),
          _RichFact(icon: Icons.inbox_outlined, label: 'Inbox + push'),
        ],
        actionSurfaceTitle: 'Selection announcement',
        actionHeroSubtitle: 'February book: Parable of the Sower',
        actionHeroBody:
            'Preview the announcement body, sender, audience, delivery time, and member inbox preview before publishing.',
        actionPanelTitle: 'Announcement publish details',
        actionPanelBody:
            'Members will receive the selected book, meeting date, and discussion prompt in their inbox.',
        alternateActionLabel: 'Save draft',
        detailTitle: 'Announcement preview',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Sender',
            body: 'From Maya, Book Club Organizer.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.message_outlined,
            title: 'Message body',
            body:
                'February selection: Parable of the Sower. Meeting details and reading prompt are ready.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.schedule_outlined,
            title: 'Delivery',
            body: 'Send today at 5:00 PM to all active members.',
          ),
        ],
        stateTitle: 'Member inbox result',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.inbox_outlined,
            title: 'Member inbox',
            body:
                'Members can read the selection and jump to RSVP or discussion.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.edit_note_outlined,
            title: 'Draft option',
            body: 'Preview announcement or save draft before publishing.',
          ),
        ],
        completeTitle: 'Selection published',
        completeBody:
            'Members received the February selection announcement with book, sender, timing, and next steps.',
        receivedTitle: 'Selection ready',
        receivedBody:
            'The member inbox shows the selected book, meeting date, and discussion prompt.',
        completeLabel: 'Published',
      );
    case 'book-search-ai-digest':
      return const _RichWorkflowSpec(
        layout: _RichWorkflowLayout.searchAnswer,
        accent: Color(0xff3f5f8f),
        icon: Icons.manage_search_outlined,
        title: 'Reading guide answer',
        subtitle: 'Query: "What should we discuss before chapter 6?"',
        body:
            'Confirm the AI answer, quoted source snippets, citation list, and follow-up prompts before saving it to the club digest.',
        facts: [
          _RichFact(icon: Icons.search_outlined, label: 'Question asked'),
          _RichFact(icon: Icons.auto_awesome_outlined, label: 'AI summary'),
          _RichFact(icon: Icons.format_quote_outlined, label: '3 citations'),
          _RichFact(icon: Icons.bookmark_border_outlined, label: 'Save digest'),
        ],
        actionSurfaceTitle: 'Reading guide answer',
        actionHeroSubtitle:
            'Parable of the Sower reading guide with cited sources',
        actionHeroBody:
            'Confirm the query, answer summary, citation snippets, source titles, and follow-up action before saving the digest.',
        actionPanelTitle: 'Reading guide save details',
        actionPanelBody:
            'The digest will save the answer, source citations, and suggested discussion prompts for members.',
        alternateActionLabel: 'Ask follow-up',
        detailTitle: 'Answer and citations',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.auto_awesome_outlined,
            title: 'Answer summary',
            body:
                'Focus the chapter 6 discussion on mutual aid, scarcity, and Lauren\'s journal voice.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.format_quote_outlined,
            title: 'Source snippets',
            body:
                'Cites member notes, the February nomination rationale, and the March discussion prompt.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.library_books_outlined,
            title: 'Citation detail',
            body:
                'Each citation shows source title, author or member, and why it is visible to this member.',
          ),
        ],
        stateTitle: 'Digest state',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.bookmark_border_outlined,
            title: 'Saved guide',
            body:
                'Members can reopen the cited answer, share it to the discussion, or ask a follow-up.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Source visibility',
            body:
                'Private member notes stay hidden; visible citations show permission-safe source labels.',
          ),
        ],
        completeTitle: 'Guide saved',
        completeBody:
            'The reading guide now shows query, answer, citations, source visibility, save state, and follow-up prompts.',
        receivedTitle: 'Guide ready',
        receivedBody:
            'Members can read the AI summary, open citations, and open the discussion prompt.',
        completeLabel: 'Saved',
      );
    case 'book-export-metadata':
      return const _RichWorkflowSpec(
        layout: _RichWorkflowLayout.exportWizard,
        accent: Color(0xff536878),
        icon: Icons.folder_zip_outlined,
        title: 'Book club export package',
        subtitle: 'Nominations, votes, RSVPs, threads, and reading schedule.',
        body:
            'Select book-club data, member-message redaction, checksum, download, and audit history before exporting.',
        facts: [
          _RichFact(icon: Icons.menu_book_outlined, label: 'Books + ballots'),
          _RichFact(icon: Icons.forum_outlined, label: 'Threads redacted'),
          _RichFact(icon: Icons.verified_outlined, label: 'Checksum BC-042'),
          _RichFact(icon: Icons.download_outlined, label: 'Download ready'),
        ],
        actionSurfaceTitle: 'Book club export package',
        actionHeroSubtitle: 'Portable reading-club archive',
        actionHeroBody:
            'Confirm nominations, ballots, meeting RSVPs, discussion threads, redaction preview, checksum, and download destination.',
        actionPanelTitle: 'Archive package',
        actionPanelBody:
            'The archive includes book nominations, vote history, meeting RSVPs, reading schedule, discussion messages, and redacted member contact fields.',
        alternateActionLabel: 'Change export scope',
        detailTitle: 'Archive contents',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.menu_book_outlined,
            title: 'Reading data',
            body:
                'Nominations, selected books, ballot counts, reading schedule, and meeting RSVP records.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Redaction preview',
            body:
                'Member email, phone, and private thread metadata are redacted unless the owner has consent.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Checksum and audit',
            body:
                'Checksum BC-042 and export timestamp are written to the owner audit history.',
          ),
        ],
        stateTitle: 'Archive record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.file_download_outlined,
            title: 'Download',
            body:
                'Owner can download the archive after checksum verification succeeds.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Rollback',
            body:
                'Change scope or cancel before export generation; previous exports stay in audit history.',
          ),
        ],
        completeTitle: 'Book archive generated',
        completeBody:
            'Book club export shows reading data, redaction preview, checksum BC-042, download progress, and audit trail.',
        receivedTitle: 'Export archive ready',
        receivedBody:
            'Owner can open the archive contents, checksum, and redaction evidence.',
        completeLabel: 'Exported',
      );
    case 'mosque-announcement':
      return const _RichWorkflowSpec(
        accent: Color(0xff2d6a4f),
        icon: Icons.campaign_outlined,
        title: 'Ramadan community night',
        subtitle: 'Announcement composer for Masjid Nur members.',
        body:
            'Confirm the message body, selected audience, sender, delivery timing, and member inbox preview before publishing.',
        facts: [
          _RichFact(icon: Icons.group_outlined, label: 'Audience: members'),
          _RichFact(icon: Icons.person_outline, label: 'From Masjid Admin'),
          _RichFact(icon: Icons.schedule_outlined, label: 'Today 6:00 PM'),
          _RichFact(icon: Icons.inbox_outlined, label: 'Inbox + push'),
        ],
        actionSurfaceTitle: 'Publish announcement',
        actionHeroSubtitle: 'Ramadan community night - Friday after Maghrib',
        actionHeroBody:
            'Send a respectful community update with event time, volunteer note, audience, and delivery channel.',
        actionPanelTitle: 'Publish details',
        actionPanelBody:
            'Members will receive the announcement in their inbox and notification list with read receipt.',
        alternateActionLabel: 'Preview announcement',
        detailTitle: 'Announcement preview',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.message_outlined,
            title: 'Message body',
            body:
                'Join Ramadan community night after Maghrib. Iftar setup volunteers arrive at 5:30 PM.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Sender',
            body: 'Masjid Admin, community announcements.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.group_outlined,
            title: 'Audience',
            body: 'All active members; donors and care volunteers included.',
          ),
        ],
        stateTitle: 'Delivery and member inbox',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.schedule_outlined,
            title: 'Delivery',
            body: 'Send today at 6:00 PM through inbox and push notification.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.mark_email_read_outlined,
            title: 'Member inbox preview',
            body:
                'Members can read the posted announcement and see it as received.',
          ),
        ],
        completeTitle: 'Announcement posted',
        completeBody:
            'Members can read the Ramadan community night update in their inbox with sender, audience, and delivery time.',
        receivedTitle: 'Update ready',
        receivedBody:
            'The member inbox shows sender, message body, audience, delivery timing, and read receipt.',
        completeLabel: 'Sent',
      );
    case 'mosque-event-rsvp':
      return const _RichWorkflowSpec(
        accent: Color(0xff2f6f9f),
        icon: Icons.event_available_outlined,
        title: 'Community iftar RSVP',
        subtitle: 'Fri, Mar 14 at 6:45 PM - Fellowship hall.',
        body:
            'Reserve a seat after checking event time, location, host, capacity, and reminder details.',
        facts: [
          _RichFact(icon: Icons.calendar_today_outlined, label: 'Fri, Mar 14'),
          _RichFact(icon: Icons.schedule_outlined, label: '6:45 PM'),
          _RichFact(icon: Icons.place_outlined, label: 'Fellowship hall'),
          _RichFact(icon: Icons.group_outlined, label: '86 of 120 spots'),
        ],
        actionSurfaceTitle: 'Iftar RSVP',
        actionHeroSubtitle: 'Ramadan community iftar',
        actionHeroBody:
            'Confirm the date, time, location, capacity, and family attendance before saving your response.',
        actionPanelTitle: 'Choose RSVP response',
        actionPanelBody:
            'Going reserves a spot; maybe keeps the event visible without taking capacity; not attending releases your seat.',
        alternateActionLabel: 'Change response',
        detailTitle: 'Event details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.person_outline,
            title: 'Host',
            body: 'Masjid Nur community team.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.group_outlined,
            title: 'Capacity',
            body: '86 attending, 34 spots available.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.place_outlined,
            title: 'Location',
            body: 'Fellowship hall, west entrance after Maghrib.',
          ),
        ],
        stateTitle: 'Response options',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Going',
            body: 'Reserve a seat and receive a reminder before Maghrib.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.swap_horiz_outlined,
            title: 'Change later',
            body: 'Change response or release your seat if plans change.',
          ),
        ],
        completeTitle: 'RSVP confirmed',
        completeBody:
            'Your iftar RSVP is confirmed with date, time, location, capacity, and reminder state visible.',
        receivedTitle: 'Iftar update ready',
        receivedBody:
            'The event page shows attendance choice, capacity, and any schedule changes.',
        completeLabel: 'Going',
      );
    case 'mosque-volunteer-signup':
      return const _RichWorkflowSpec(
        accent: Color(0xff3f7f4c),
        icon: Icons.volunteer_activism_outlined,
        title: 'Iftar setup shift',
        subtitle: 'Friday 4:30 PM - tables, check-in, and meal handoff.',
        body:
            'Choose the role, confirm shift time, protect contact details, and confirm coordinator follow-up.',
        facts: [
          _RichFact(
            icon: Icons.volunteer_activism_outlined,
            label: 'Setup role',
          ),
          _RichFact(icon: Icons.schedule_outlined, label: '4:30-6:30 PM shift'),
          _RichFact(icon: Icons.phone_outlined, label: 'Phone protected'),
          _RichFact(icon: Icons.group_outlined, label: '2 spots open'),
        ],
        actionSurfaceTitle: 'Volunteer signup',
        actionHeroSubtitle: 'Iftar setup team',
        actionHeroBody:
            'Confirm shift role, time, location, contact preference, and coordinator handoff before signing up.',
        actionPanelTitle: 'Shift signup details',
        actionPanelBody:
            'Your protected phone is shared only with the volunteer coordinator after confirmation.',
        alternateActionLabel: 'Edit availability',
        detailTitle: 'Shift details',
        detailRows: [
          _ActionSurfaceDetail(
            icon: Icons.task_alt_outlined,
            title: 'Volunteer task',
            body: 'Set up tables, check-in labels, and meal handoff station.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.schedule_outlined,
            title: 'Time and place',
            body: 'Friday 4:30-6:30 PM, fellowship hall west entrance.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.phone_outlined,
            title: 'Protected contact',
            body: 'Phone is visible only to the volunteer coordinator.',
          ),
        ],
        stateTitle: 'Signup record',
        stateRows: [
          _ActionSurfaceDetail(
            icon: Icons.check_circle_outline,
            title: 'Confirmation',
            body:
                'Coordinator receives your signup and protected contact preference.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.edit_note_outlined,
            title: 'Change option',
            body: 'Edit availability or cancel the shift if plans change.',
          ),
        ],
        completeTitle: 'Volunteer signup confirmed',
        completeBody:
            'You are signed up for iftar setup with protected phone, shift time, role, and coordinator follow-up.',
        receivedTitle: 'Volunteer update ready',
        receivedBody:
            'The coordinator sees role, shift, protected contact state, and signup confirmation.',
        completeLabel: 'Signed up',
      );
  }
  return _fallbackRichWorkflowSpecFor(workflowId);
}

_RichWorkflowSpec _fallbackRichWorkflowSpecFor(String workflowId) {
  final id = workflowId.toLowerCase();
  if (id.startsWith('soccer-')) {
    return _soccerRichSpecFor(id);
  }
  if (id.startsWith('hoa-')) {
    return _hoaRichSpecFor(id);
  }
  if (id.startsWith('mosque-')) {
    return _mosqueRichSpecFor(id);
  }
  if (id.startsWith('book-') && id.contains('export')) {
    return _exportRichSpecFor(id);
  }
  if (id.startsWith('chess-')) {
    return _chessRichSpecFor(id);
  }
  if (id.startsWith('photo-') ||
      id.startsWith('critique-') ||
      id.startsWith('gear-')) {
    return _cameraRichSpecFor(id);
  }
  if (id.startsWith('platform-')) {
    return _platformRichSpecFor(id);
  }
  if (id.startsWith('ad-off-')) {
    return _adOffRichSpecFor(id);
  }
  if (id.startsWith('export-')) {
    return _exportRichSpecFor(id);
  }
  return _richSurface(
    accent: const Color(0xff246b62),
    icon: Icons.apps_outlined,
    title: 'Community item',
    subtitle: 'Details, action, and result are ready.',
    body:
        'Confirm the community item, decision details, available changes, and final progress before saving.',
    facts: const [
      _RichFact(icon: Icons.assignment_outlined, label: 'Details ready'),
      _RichFact(icon: Icons.edit_note_outlined, label: 'Editable'),
      _RichFact(icon: Icons.verified_outlined, label: 'State saved'),
    ],
    detailTitle: 'Activity details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.assignment_outlined,
        title: 'Context',
        body: 'The member sees the object, owner, status, and current values.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.edit_note_outlined,
        title: 'Change option',
        body: 'The member can save, edit, cancel, or return later.',
      ),
    ],
    stateTitle: 'Saved details',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.task_alt_outlined,
        title: 'Result',
        body: 'The saved details remain visible with next steps.',
      ),
    ],
  );
}

_RichWorkflowSpec _soccerRichSpecFor(String id) {
  if (id.contains('guardian-join')) {
    return _richSurface(
      accent: const Color(0xff1f7a5c),
      icon: Icons.family_restroom_outlined,
      title: 'Guardian approval desk',
      subtitle: 'Mia Rivera requests access for U10 Falcons.',
      body:
          'Confirm guardian identity, player connection, emergency-contact status, and approval notes before activating membership.',
      facts: const [
        _RichFact(icon: Icons.person_outline, label: 'Mia Rivera'),
        _RichFact(icon: Icons.sports_soccer_outlined, label: 'U10 Falcons'),
        _RichFact(
          icon: Icons.health_and_safety_outlined,
          label: 'Emergency contact',
        ),
        _RichFact(icon: Icons.task_alt_outlined, label: 'Approve or reject'),
      ],
      actionPanelTitle: 'Coach approval details',
      actionPanelBody:
          'Approve guardian access, request changes, or reject with a private note that the guardian can read.',
      alternateActionLabel: 'Request changes',
      detailTitle: 'Guardian request',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Guardian',
          body:
              'Mia Rivera, parent of Leo Rivera, requested U10 Falcons access today.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.shield_outlined,
          title: 'Safety info',
          body:
              'Emergency contact and pickup authorization are present for coach action.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.comment_outlined,
          title: 'Decision note',
          body:
              'Coach can approve, reject, or ask for a missing waiver before activation.',
        ),
      ],
      stateTitle: 'Decision recorded',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.verified_user_outlined,
          title: 'Membership state',
          body:
              'Approved guardians see team schedule, roster, fees, and reminders.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.history_outlined,
          title: 'Outcome history',
          body: 'The request keeps reviewer, timestamp, and decision history.',
        ),
      ],
      completeTitle: 'Guardian approved',
      completeBody:
          'Mia Rivera is active for U10 Falcons with player link, emergency-contact status, and decision history visible.',
      completeLabel: 'Approved',
    );
  }
  if (id.contains('team-roster')) {
    return _richSurface(
      accent: const Color(0xff276f8f),
      icon: Icons.groups_outlined,
      title: 'U10 Falcons roster',
      subtitle: '12 players, 9 guardians, 2 missing waivers.',
      body:
          'Open player names, guardian visibility, protected minor fields, and coach notes without exposing sensitive details.',
      facts: const [
        _RichFact(icon: Icons.group_outlined, label: '12 players'),
        _RichFact(icon: Icons.assignment_late_outlined, label: '2 waivers due'),
        _RichFact(
          icon: Icons.visibility_off_outlined,
          label: 'Birthdates protected',
        ),
        _RichFact(icon: Icons.mail_outline, label: 'Guardian contacts'),
      ],
      actionPanelTitle: 'Roster ready to open',
      actionPanelBody:
          'Open roster details, update team notes, message guardians, or export a protected team sheet.',
      alternateActionLabel: 'Message guardians',
      detailTitle: 'Roster details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Featured player',
          body:
              'Leo Rivera, jersey 14, guardian Mia Rivera, waiver due before Saturday.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.lock_outline,
          title: 'Protected fields',
          body:
              'Birthdates and medical notes are redacted unless the coach has permission.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.sports_soccer_outlined,
          title: 'Team context',
          body: 'U10 Falcons practice Saturday at Riverside Field 3.',
        ),
      ],
      stateTitle: 'Coach actions',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.edit_note_outlined,
          title: 'Update roster',
          body:
              'Coach can add notes, track missing waivers, and export a protected roster.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.notifications_outlined,
          title: 'Guardian follow-up',
          body: 'Message only guardians with incomplete forms.',
        ),
      ],
      completeTitle: 'Roster opened',
      completeBody:
          'The U10 Falcons roster shows players, guardians, waiver status, and protected-field handling.',
      completeLabel: 'Opened',
    );
  }
  if (id.contains('payment')) {
    return _richSurface(
      accent: const Color(0xff6d4aa2),
      icon: Icons.receipt_long_outlined,
      title: 'Season registration fee',
      subtitle: '125.00 USD for Leo Rivera - U10 Falcons.',
      body:
          'Confirm payer, player, season fee, receipt destination, retry option, and scholarship note before payment.',
      facts: const [
        _RichFact(icon: Icons.attach_money, label: '125.00 USD'),
        _RichFact(icon: Icons.person_outline, label: 'Leo Rivera'),
        _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt saved'),
        _RichFact(icon: Icons.privacy_tip_outlined, label: 'Private payer'),
      ],
      actionPanelTitle: 'Payment summary',
      actionPanelBody:
          'Pay dues, change payer details, retry a failed payment, or open the receipt after confirmation.',
      alternateActionLabel: 'Change payer',
      detailTitle: 'Payment details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.sports_soccer_outlined,
          title: 'Registration',
          body: 'U10 Falcons spring season registration for Leo Rivera.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          body:
              'Receipt goes to guardian account and appears in payment history.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.help_outline,
          title: 'Support',
          body: 'Scholarship note can be reviewed before checkout.',
        ),
      ],
      stateTitle: 'Receipt created',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.check_circle_outline,
          title: 'Entitlement',
          body: 'Player registration status changes to paid and active.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.refresh_outlined,
          title: 'Retry option',
          body: 'Failed payments can be retried without losing form state.',
        ),
      ],
      completeTitle: 'Registration paid',
      completeBody:
          'Leo Rivera registration is paid with receipt, payer, season, and status visible.',
      completeLabel: 'Paid',
    );
  }
  return _richSurface(
    accent: const Color(0xff1f7a5c),
    icon: id.contains('schedule') || id.contains('reminder')
        ? Icons.event_available_outlined
        : Icons.privacy_tip_outlined,
    title: id.contains('schedule')
        ? 'Saturday practice schedule'
        : id.contains('reminder')
        ? 'Guardian practice reminder'
        : id.contains('export')
        ? 'Protected soccer export'
        : 'Youth privacy record',
    subtitle: id.contains('schedule')
        ? 'Sat 9:00 AM - Riverside Field 3, U10 Falcons.'
        : id.contains('reminder')
        ? 'Practice starts at 9:00 AM, field and gear note included.'
        : 'Roster and registration data with minor protection.',
    body: id.contains('schedule')
        ? 'Publish team schedule details with time, field, capacity, guardian inbox preview, and confirmed attendance result.'
        : id.contains('reminder')
        ? 'Send the reminder message body with sender, guardian audience, timestamp, and inbox channel.'
        : id.contains('export')
        ? 'Show protected roster scope, redaction preview, checksum verification, transfer progress, and guardian or coach visibility.'
        : 'Show protected minor data, redaction result, export scope, and permission boundaries for coaches and guardians.',
    facts: const [
      _RichFact(icon: Icons.schedule_outlined, label: 'Saturday 9 AM'),
      _RichFact(icon: Icons.place_outlined, label: 'Field 3'),
      _RichFact(icon: Icons.event_available_outlined, label: 'RSVP available'),
      _RichFact(icon: Icons.visibility_off_outlined, label: 'Protected data'),
      _RichFact(icon: Icons.verified_outlined, label: 'Checksum verified'),
    ],
    actionPanelTitle: 'Publish details',
    actionPanelBody:
        'Confirm time, field, recipient guardians, protected details, and inbox preview before saving.',
    alternateActionLabel: 'Edit details',
    detailTitle: 'Team details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.sports_soccer_outlined,
        title: 'Team',
        body: 'U10 Falcons, coach Jordan Patel, 12-player roster.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.schedule_outlined,
        title: 'Schedule',
        body:
            'Saturday practice at 9:00 AM on Riverside Field 3 with RSVP and attendance result visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.visibility_off_outlined,
        title: 'Privacy',
        body:
            'Minor profile fields are redacted for guardians and visible to coaches only where permitted.',
      ),
    ],
    stateTitle: 'Recipient result',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.notifications_outlined,
        title: 'Guardian update',
        body:
            'Guardians receive schedule, roster-safe details, reminder message body, timestamp, and inbox channel.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.file_download_outlined,
        title: 'Export state',
        body:
            'Protected export includes roster metadata, redaction preview, checksum verification, and transfer progress.',
      ),
    ],
    completeTitle: 'Team update saved',
    completeBody:
        'The soccer update shows RSVP choice, reminder body, checksum or saved result, inbox preview, and protected data handling.',
    completeLabel: 'Saved',
  );
}

_RichWorkflowSpec _hoaRichSpecFor(String id) {
  final isPayment = id.contains('dues') || id.contains('facility');
  final isDocument = id.contains('document');
  final isApproval =
      id.contains('architectural') ||
      id.contains('committee') ||
      id.contains('notification');
  if (id.contains('notification')) {
    return _richSurface(
      layout: _RichWorkflowLayout.noticeDetail,
      accent: const Color(0xff3e6b8f),
      icon: Icons.mark_email_read_outlined,
      title: 'Owner decision notice',
      subtitle: 'Lot 42 fence request - approved with conditions.',
      body:
          'Send the owner notice with board sender, decision summary, required paint condition, delivery time, and owner inbox state.',
      facts: const [
        _RichFact(icon: Icons.home_outlined, label: 'Lot 42'),
        _RichFact(icon: Icons.person_outline, label: 'From HOA Board'),
        _RichFact(icon: Icons.schedule_outlined, label: 'Today 4:15 PM'),
        _RichFact(icon: Icons.inbox_outlined, label: 'Owner inbox'),
      ],
      actionSurfaceTitle: 'Send owner notice',
      actionHeroSubtitle: 'Avery Brooks - architectural decision',
      actionHeroBody:
          'Confirm sender, recipient, decision body, condition, timestamp, and homeowner inbox preview before sending.',
      actionPanelTitle: 'Owner notification details',
      actionPanelBody:
          'The owner receives the board decision, condition, appeal/reopen option, and message timestamp in their inbox.',
      alternateActionLabel: 'Edit notice',
      detailTitle: 'Notice message',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Sender and recipient',
          body:
              'From Cedar Commons HOA Board to Avery Brooks, homeowner for Lot 42.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.message_outlined,
          title: 'Message body',
          body:
              'Your slate gray fence repaint is approved if trim remains cedar and work starts within 30 days.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.schedule_outlined,
          title: 'Delivery',
          body: 'Send today at 4:15 PM to owner inbox and email receipt.',
        ),
      ],
      stateTitle: 'Homeowner inbox preview',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.inbox_outlined,
          title: 'Owner inbox',
          body:
              'Owner sees decision, sender, message body, timestamp, condition, and appeal option.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.undo_outlined,
          title: 'Follow-up',
          body:
              'Owner can appeal, request clarification, or reopen with a revised color sample.',
        ),
      ],
      completeTitle: 'Owner notified',
      completeBody:
          'Owner notice shows sender, recipient, body, timestamp, decision condition, inbox receipt, and follow-up option.',
      receivedTitle: 'Decision notice received',
      receivedBody:
          'The homeowner inbox shows the board sender, decision body, timestamp, condition, and appeal option.',
      completeLabel: 'Notice sent',
    );
  }
  return _richSurface(
    accent: const Color(0xff3e6b8f),
    icon: isPayment
        ? Icons.receipt_long_outlined
        : isDocument
        ? Icons.description_outlined
        : isApproval
        ? Icons.fact_check_outlined
        : Icons.folder_zip_outlined,
    title: id.contains('dues')
        ? 'Quarterly HOA dues'
        : id.contains('facility')
        ? 'Clubhouse Room A reservation'
        : id.contains('document')
        ? 'Community Rules document'
        : id.contains('architectural')
        ? 'Fence color request'
        : id.contains('committee')
        ? 'Architectural committee decision'
        : id.contains('notification')
        ? 'Owner decision notice'
        : 'HOA records export',
    subtitle: id.contains('dues')
        ? '450.00 USD due Jul 1, receipt to homeowner ledger.'
        : id.contains('facility')
        ? 'Room A, Saturday 2-5 PM, reservation fee attached.'
        : id.contains('document')
        ? 'Version 2026.3, members can open and acknowledge.'
        : id.contains('architectural')
        ? 'Lot 42 fence repaint, slate gray, decision due Friday.'
        : id.contains('committee')
        ? 'Board decision, conditions, comments, and owner follow-up.'
        : id.contains('notification')
        ? 'Approved with conditions, sent to owner inbox.'
        : 'Documents, receipts, facilities, and case history.',
    body: id.contains('dues') || id.contains('facility')
        ? 'Amount, owner, reservation or dues item, receipt destination, retry option, and status are visible.'
        : id.contains('document')
        ? 'Open the governing document with version, access state, acknowledgement, and download history.'
        : isApproval
        ? 'Request materials, committee note, approve/reject/request changes, and homeowner notification are visible.'
        : 'Prepare HOA records with documents, cases, receipts, redaction, checksum, and transfer progress.',
    facts: const [
      _RichFact(icon: Icons.home_outlined, label: 'Cedar Commons'),
      _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt/audit'),
      _RichFact(icon: Icons.description_outlined, label: 'Documents'),
      _RichFact(icon: Icons.event_available_outlined, label: 'Availability'),
      _RichFact(icon: Icons.task_alt_outlined, label: 'Outcome history'),
    ],
    actionPanelTitle: isApproval
        ? 'Committee decision'
        : isDocument
        ? 'Document access'
        : 'Reservation details',
    actionPanelBody: isApproval
        ? 'Approve, reject, request changes, comment, or reopen with a visible owner notification state.'
        : isDocument
        ? 'Open, download, acknowledge, request access, or view version history.'
        : 'Confirm the amount or scope, change details, retry if needed, and keep the receipt or export progress visible.',
    alternateActionLabel: isApproval
        ? 'Request changes'
        : isDocument
        ? 'Download PDF'
        : 'Change details',
    detailTitle: isApproval
        ? 'Request details'
        : isDocument
        ? 'Document details'
        : 'HOA details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.home_outlined,
        title: 'Property',
        body:
            'Lot 42, homeowner Avery Brooks, Cedar Commons HOA; sender is the HOA board.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.description_outlined,
        title: 'Record',
        body:
            'Community Rules, Room A reservation, dues receipt, or architectural case.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.history_outlined,
        title: 'History',
        body:
            'Status, reviewer, receipt, version, timestamp, availability, and notification history remain visible.',
      ),
    ],
    stateTitle: 'Member result',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.inbox_outlined,
        title: 'Owner inbox',
        body:
            'Homeowner sees receipt, decision, document, reservation availability, sender, timestamp, and status.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.undo_outlined,
        title: 'Change option',
        body:
            'Cancel reservation, request changes, retry payment, or reopen where policy allows.',
      ),
    ],
    completeTitle: isApproval
        ? 'Request outcome saved'
        : isDocument
        ? 'Document viewed'
        : 'HOA record saved',
    completeBody: isDocument
        ? 'The document is viewed and acknowledged with access state, version history, and member download option visible.'
        : 'The homeowner record now shows owner, amount or decision, status history, and member next steps.',
    completeLabel: isApproval
        ? 'Outcome recorded'
        : isDocument
        ? 'Opened'
        : 'Saved',
  );
}

_RichWorkflowSpec _mosqueRichSpecFor(String id) {
  return _richSurface(
    accent: const Color(0xff2d6a4f),
    icon: id.contains('donation') || id.contains('donor')
        ? Icons.receipt_long_outlined
        : id.contains('care')
        ? Icons.volunteer_activism_outlined
        : Icons.search_outlined,
    title: id.contains('donor')
        ? 'Anonymous donor preference'
        : id.contains('donation')
        ? 'Sadaqah donation receipt'
        : id.contains('care')
        ? 'Private care request'
        : id.contains('notification')
        ? 'Neutral care receipt'
        : 'Iftar announcement answer',
    subtitle: id.contains('donation')
        ? '50.00 USD, anonymous option, receipt saved.'
        : id.contains('care')
        ? 'Meal support request with public summary and protected details.'
        : 'Member-safe update with respectful language and privacy boundaries.',
    body: id.contains('care')
        ? 'Submit or update care support without exposing sensitive details in notifications or public views.'
        : id.contains('donation') || id.contains('donor')
        ? 'Amount, donor visibility, receipt destination, and giving history are visible before saving.'
        : 'Search public announcement content with citations, sender, delivery timing, and member inbox preview.',
    facts: const [
      _RichFact(icon: Icons.favorite_outline, label: 'Community care'),
      _RichFact(icon: Icons.privacy_tip_outlined, label: 'Privacy checked'),
      _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt record'),
      _RichFact(icon: Icons.inbox_outlined, label: 'Member inbox'),
    ],
    actionPanelTitle: 'Save details',
    actionPanelBody:
        'Member-visible summary, protected details, receipt or citation, and recipient preview stay visible before sending.',
    alternateActionLabel: 'Update privacy',
    detailTitle: 'Masjid details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.message_outlined,
        title: 'Public summary',
        body:
            'Member-facing text stays neutral and does not reveal sensitive care details.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.lock_outline,
        title: 'Protected details',
        body:
            'Private notes are visible only to the care team or donor account owner.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.receipt_long_outlined,
        title: 'Record',
        body:
            'Donation receipt, care status, or citation evidence remains available.',
      ),
    ],
    stateTitle: 'Recipient result',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.mark_email_read_outlined,
        title: 'Member update',
        body:
            'Members see the safe notification, receipt, or cited answer in context.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.edit_note_outlined,
        title: 'Change option',
        body:
            'Update privacy, edit request, withdraw, or open receipt where allowed.',
      ),
    ],
    completeTitle: 'Masjid preference confirmed',
    completeBody:
        'Members see the privacy-safe update, receipt history or citation, confirmed status, current progress, and clear next step.',
    completeLabel: 'Saved',
  );
}

_RichWorkflowSpec _chessRichSpecFor(String id) {
  return _richSurface(
    layout: _RichWorkflowLayout.clubScoreboard,
    accent: const Color(0xff58432f),
    icon: Icons.grid_4x4_outlined,
    title: id.contains('match') ? 'Board 1 match result' : 'Chess Club home',
    subtitle: id.contains('match')
        ? 'Ava 1-0 Liam, Round 3 ladder match.'
        : 'Tonight ladder, pairings, standings, and next match.',
    body: id.contains('match')
        ? 'Record opponent, board, result, correction option, standings impact, and next pairing.'
        : 'Open a real club home with upcoming matches, active ladder, and member standings.',
    facts: const [
      _RichFact(icon: Icons.grid_4x4_outlined, label: 'Board 1'),
      _RichFact(icon: Icons.emoji_events_outlined, label: 'Round 3'),
      _RichFact(icon: Icons.group_outlined, label: '12 players'),
      _RichFact(icon: Icons.edit_note_outlined, label: 'Correction option'),
    ],
    actionPanelTitle: id.contains('match')
        ? 'Score details'
        : 'Club home details',
    actionPanelBody:
        'Confirm player names, round, board, result, edit option, and standings update before saving.',
    alternateActionLabel: 'Edit score',
    detailTitle: 'Match context',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Players',
        body: 'Ava vs Liam, Board 1, friendly ladder night.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.emoji_events_outlined,
        title: 'Result',
        body: 'Ava wins 1-0; standings and next pairing will update.',
      ),
    ],
    stateTitle: 'Club record',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.leaderboard_outlined,
        title: 'Standings',
        body: 'Players can see updated ladder position and next match.',
      ),
    ],
    completeTitle: 'Chess result saved',
    completeBody:
        'Chess Club shows board, players, result, correction option, standings impact, and next pairing.',
    completeLabel: 'Saved',
  );
}

_RichWorkflowSpec _cameraRichSpecFor(String id) {
  if (id.contains('photo-walk')) {
    return _richSurface(
      accent: const Color(0xff2f6f9f),
      icon: Icons.route_outlined,
      title: 'Downtown photo walk RSVP',
      subtitle: 'Sat 4:30 PM - Dock 4 to the riverfront pier.',
      body:
          'Choose Going, Maybe, or Not going after checking the route, host, meetup time, capacity, and gear reminder.',
      facts: const [
        _RichFact(icon: Icons.calendar_today_outlined, label: 'Sat, 4:30 PM'),
        _RichFact(icon: Icons.place_outlined, label: 'Dock 4 meetup'),
        _RichFact(icon: Icons.group_outlined, label: '12 going / 4 open'),
        _RichFact(icon: Icons.camera_alt_outlined, label: '35mm or phone'),
      ],
      actionSurfaceTitle: 'Photo walk RSVP',
      actionHeroSubtitle: 'Riverfront golden-hour route',
      actionHeroBody:
          'Confirm the walk route, host note, rain plan, attendee count, and reminder before saving your RSVP.',
      actionPanelTitle: 'Choose attendance',
      actionPanelBody:
          'Going reserves a spot; Maybe keeps the route in your inbox; Not going releases capacity for another member.',
      alternateActionLabel: 'Change response',
      detailTitle: 'Walk details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.route_outlined,
          title: 'Route',
          body: 'Dock 4, mural loop, riverfront pier, 75-minute walk.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Host',
          body: 'Avery Kim hosts and shares the rain-plan update.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.group_outlined,
          title: 'Capacity',
          body: '12 going, 4 spots open, waitlist opens at 16.',
        ),
      ],
      stateTitle: 'Response record',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.check_circle_outline,
          title: 'Going / maybe / not going',
          body: 'Response can be changed until Saturday noon.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.notifications_outlined,
          title: 'Reminder',
          body: 'Member inbox keeps route, gear note, and weather update.',
        ),
      ],
      completeTitle: 'Photo walk RSVP confirmed',
      completeBody:
          'Your photo walk attendance is confirmed with status, route, host, capacity, reminder, and change-response option visible.',
      receivedTitle: 'Photo walk update ready',
      receivedBody:
          'The member sees route, time, capacity, RSVP state, and reminder details.',
      completeLabel: 'RSVP saved',
    );
  }
  if (id.contains('critique')) {
    return _richSurface(
      accent: const Color(0xff6b5b95),
      icon: Icons.rate_review_outlined,
      title: 'Street portrait critique',
      subtitle: 'Evening Reflection - consent note and reviewer queue.',
      body:
          'Submit a photo for critique with title, prompt, visibility, reviewer, edit option, and comment result.',
      facts: const [
        _RichFact(icon: Icons.image_outlined, label: 'Evening Reflection'),
        _RichFact(icon: Icons.privacy_tip_outlined, label: 'Member visible'),
        _RichFact(icon: Icons.rate_review_outlined, label: 'Avery reviews'),
        _RichFact(icon: Icons.comment_outlined, label: 'Comments open'),
      ],
      actionSurfaceTitle: 'Critique submission',
      actionHeroSubtitle: 'Street portrait: Evening Reflection',
      actionHeroBody:
          'Confirm the image title, prompt, consent note, member visibility, and critique assignment before submitting.',
      actionPanelTitle: 'Critique details',
      actionPanelBody:
          'Submission enters Avery\'s queue; you can edit caption, replace image, or withdraw before comments.',
      alternateActionLabel: 'Edit critique',
      detailTitle: 'Submission details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.image_outlined,
          title: 'Image and title',
          body: 'Evening Reflection, street portrait, uploaded by Mina.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.question_answer_outlined,
          title: 'Prompt',
          body: 'Ask for feedback on composition, light, and crop.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.privacy_tip_outlined,
          title: 'Visibility',
          body: 'Visible to camera club members; consent note is attached.',
        ),
      ],
      stateTitle: 'Decision progress',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.rate_review_outlined,
          title: 'Reviewer queue',
          body: 'Avery receives the image, prompt, and visibility state.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.swap_horiz_outlined,
          title: 'Change option',
          body: 'Edit caption, replace image, withdraw, or resubmit.',
        ),
      ],
      completeTitle: 'Critique submitted',
      completeBody:
          'The critique shows image, prompt, consent, reviewer queue, edit option, and comment state.',
      receivedTitle: 'Critique result ready',
      receivedBody:
          'The member can read reviewer comments and follow up on the submitted image.',
      completeLabel: 'Submitted',
    );
  }
  return _richSurface(
    accent: const Color(0xff5a6f45),
    icon: Icons.camera_alt_outlined,
    title: '35mm prime lens loan',
    subtitle: 'Sam lends the lens Friday; return due Sunday evening.',
    body:
        'Request shared gear with owner, pickup time, borrower count, contact privacy, waitlist, and return state.',
    facts: const [
      _RichFact(icon: Icons.camera_outdoor_outlined, label: '35mm lens'),
      _RichFact(icon: Icons.person_outline, label: 'Owner: Sam'),
      _RichFact(icon: Icons.people_outline, label: '2 waiting'),
      _RichFact(icon: Icons.keyboard_return_outlined, label: 'Return Sunday'),
    ],
    actionSurfaceTitle: 'Gear loan request',
    actionHeroSubtitle: '35mm prime lens from Sam',
    actionHeroBody:
        'Confirm pickup, borrower queue, protected contact reveal, due date, and return option before requesting the loan.',
    actionPanelTitle: 'Gear request details',
    actionPanelBody:
        'Decision pending: the lender reviews borrower name, pickup window, contact preference, and cancel/return option.',
    alternateActionLabel: 'Cancel request',
    detailTitle: 'Loan details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.camera_outdoor_outlined,
        title: 'Item',
        body: '35mm prime lens, clean condition, filter included.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.schedule_outlined,
        title: 'Pickup and return',
        body: 'Pickup Friday 5 PM; return Sunday by 6 PM.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.privacy_tip_outlined,
        title: 'Contact',
        body: 'Phone is revealed only after owner approves the loan.',
      ),
    ],
    stateTitle: 'Borrower record',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.people_outline,
        title: 'Roster',
        body:
            'Borrower list, waitlist position, availability, and owner decision are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.keyboard_return_outlined,
        title: 'Return option',
        body: 'Mark returned, change pickup, or cancel request.',
      ),
    ],
    completeTitle: 'Gear loan requested',
    completeBody:
        'The loan request status shows item, owner, borrower queue, pickup, protected contact, and return option.',
    receivedTitle: 'Gear request ready',
    receivedBody:
        'The lender sees borrower, pickup, privacy, pending approval decision, and return plan.',
    completeLabel: 'Requested',
  );
}

_RichWorkflowSpec _platformRichSpecFor(String id) {
  if (id.contains('ad') || id.contains('banner') || id.contains('no-fill')) {
    final sensitive = id.contains('sensitive');
    final banner = id.contains('banner');
    return _richSurface(
      layout: _RichWorkflowLayout.adEntitlement,
      accent: sensitive
          ? const Color(0xff6b4f78)
          : banner
          ? const Color(0xff406d5a)
          : const Color(0xff7a5a2f),
      icon: sensitive
          ? Icons.shield_outlined
          : banner
          ? Icons.web_asset_off_outlined
          : Icons.campaign_outlined,
      title: sensitive
          ? 'Sensitive page ad guard'
          : banner
          ? 'Top banner no-fill'
          : 'Sponsored stream message',
      subtitle: sensitive
          ? 'Protected context blocks ad delivery and click tracking.'
          : banner
          ? 'Reserved banner space stays stable without sponsor fill.'
          : 'Sponsor disclosure, placement, impression, and member context.',
      body: sensitive
          ? 'Show the member why ads are suppressed, preserve layout, and avoid leaking protected context.'
          : banner
          ? 'Show a clear no-sponsored-message state with reserved space, disclosure, and no overlap.'
          : 'Show sponsor, disclosure, message copy, impression state, and dismiss/report alternatives.',
      facts: [
        if (!sensitive)
          const _RichFact(icon: Icons.campaign_outlined, label: 'Disclosure'),
        if (banner)
          const _RichFact(
            icon: Icons.web_asset_outlined,
            label: 'Slot reserved',
          ),
        if (sensitive)
          const _RichFact(icon: Icons.shield_outlined, label: 'Protected page'),
        const _RichFact(icon: Icons.visibility_outlined, label: 'No overlap'),
        const _RichFact(icon: Icons.analytics_outlined, label: 'Audit state'),
        const _RichFact(icon: Icons.block_outlined, label: 'Dismiss/report'),
      ],
      actionSurfaceTitle: sensitive
          ? 'Sensitive ad decision'
          : banner
          ? 'Top banner slot'
          : 'Sponsored message details',
      actionHeroSubtitle: sensitive
          ? 'Protected care context'
          : banner
          ? 'No sponsor available right now'
          : 'Local sponsor: community newsletter',
      actionHeroBody: sensitive
          ? 'The page records a no-fill reason without revealing protected member context or enabling click tracking.'
          : banner
          ? 'Reserved space remains stable and tells members why no sponsored message is displayed.'
          : 'Confirm the sponsor label, disclosure, placement, content, impression, and report option.',
      actionPanelTitle: sensitive
          ? 'Protected no-fill ready'
          : banner
          ? 'No-fill state ready'
          : 'Sponsored message ready',
      actionPanelBody: sensitive
          ? 'Ad delivery is suppressed, no click is recorded, and the member sees a privacy-safe reason.'
          : banner
          ? 'The banner stays reserved, avoids content jump, and records the no-fill reason.'
          : 'The member can dismiss, report, or continue; impression is recorded only for filled ads.',
      alternateActionLabel: sensitive
          ? 'Policy details'
          : banner
          ? 'Refresh slot'
          : 'Report sponsor',
      detailTitle: sensitive
          ? 'Privacy guard details'
          : banner
          ? 'Banner slot details'
          : 'Sponsored message details',
      detailRows: [
        _ActionSurfaceDetail(
          icon: sensitive
              ? Icons.shield_outlined
              : banner
              ? Icons.web_asset_outlined
              : Icons.storefront_outlined,
          title: sensitive
              ? 'Sensitive context'
              : banner
              ? 'Reserved placement'
              : 'Sponsor',
          body: sensitive
              ? 'Care/protected content suppresses ad targeting and click tracking.'
              : banner
              ? 'Top banner slot remains visible with no sponsored message right now.'
              : 'Disclosure: Sponsored by Neighborhood Newsletter.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.info_outline,
          title: 'Reason',
          body: sensitive
              ? 'No fill: sensitive context.'
              : banner
              ? 'No fill: no eligible sponsor for this community moment.'
              : 'Filled ad: eligible community stream placement.',
        ),
        const _ActionSurfaceDetail(
          icon: Icons.report_outlined,
          title: 'Member control',
          body:
              'Dismiss, report, or continue without losing place in the stream.',
        ),
      ],
      stateTitle: 'Ad delivery record',
      stateRows: [
        _ActionSurfaceDetail(
          icon: Icons.analytics_outlined,
          title: sensitive || banner ? 'No impression' : 'Impression recorded',
          body: sensitive || banner
              ? 'No impression/click is recorded because the slot is not filled.'
              : 'Impression is recorded with sponsor disclosure and audit trail.',
        ),
        const _ActionSurfaceDetail(
          icon: Icons.visibility_outlined,
          title: 'Layout',
          body: 'Reserved space prevents overlap, crowding, and content jumps.',
        ),
      ],
      completeTitle: sensitive
          ? 'Sensitive no-fill recorded'
          : banner
          ? 'Banner no-fill recorded'
          : 'Sponsored message details',
      completeBody: sensitive
          ? 'Protected context, no-fill reason, layout preservation, and no-click state remain visible.'
          : banner
          ? 'No sponsored message is shown, reserved space remains stable, and no-fill reason is recorded.'
          : 'Sponsor, disclosure, impression, report option, and stream placement remain visible.',
      receivedTitle: 'Ad state ready',
      receivedBody:
          'The member can see disclosure/no-fill reason, reserved layout, and any available control.',
      completeLabel: sensitive || banner ? 'No fill' : 'Reviewed',
    );
  }
  if (id.contains('message')) {
    return _richSurface(
      layout: _RichWorkflowLayout.messageThread,
      accent: const Color(0xff315c8a),
      icon: Icons.chat_bubble_outline,
      title: 'Community message thread',
      subtitle: 'Maya Chen to Jordan Lee - unread member thread.',
      body:
          'Read sender, recipient, timestamp, message preview, unread receipt, reply option, mute, and archive controls.',
      facts: const [
        _RichFact(icon: Icons.person_outline, label: 'Maya -> Jordan'),
        _RichFact(icon: Icons.mark_email_unread_outlined, label: 'Unread'),
        _RichFact(icon: Icons.reply_outlined, label: 'Reply available'),
        _RichFact(icon: Icons.archive_outlined, label: 'Archive option'),
      ],
      actionSurfaceTitle: 'Message thread',
      actionHeroSubtitle: 'Community message from Maya',
      actionHeroBody:
          'Open the thread, confirm sender and body, reply, mute, archive, or block if needed.',
      actionPanelTitle: 'Reply details',
      actionPanelBody:
          'Reply keeps the thread member-scoped and preserves read/unread receipt.',
      alternateActionLabel: 'Archive thread',
      detailTitle: 'Thread details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Sender and recipient',
          body: 'Maya Chen -> Jordan Lee, members of the same community.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.message_outlined,
          title: 'Message body',
          body: 'Can you bring the sign-in sheets before the meetup?',
        ),
        _ActionSurfaceDetail(
          icon: Icons.schedule_outlined,
          title: 'Timestamp',
          body: 'Today 9:12 AM, unread until opened.',
        ),
      ],
      stateTitle: 'Conversation record',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.reply_outlined,
          title: 'Actions',
          body: 'Reply, mute, archive, or block remain available.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.mark_email_read_outlined,
          title: 'Recipient result',
          body: 'Thread updates to read with reply history after action.',
        ),
      ],
      completeTitle: 'Message sent',
      completeBody:
          'The thread shows the sent message, receiver read status, timestamp, reply option, receipt history, and archive/block controls.',
      receivedTitle: 'Message received',
      receivedBody:
          'The receiver sees sender, message body, timestamp, unread/read receipt, and reply action.',
      completeLabel: 'Thread updated',
    );
  }
  if (id.contains('blocked')) {
    return _richSurface(
      layout: _RichWorkflowLayout.messageThread,
      accent: const Color(0xff7a4e4e),
      icon: Icons.block_outlined,
      title: 'Blocked connection guard',
      subtitle: 'Maya cannot send an invite to blocked member Jordan.',
      body:
          'Show sender, protected recipient, attempted invite body, disabled send option, safety reason, appeal/unblock option, and audit timestamp.',
      facts: const [
        _RichFact(icon: Icons.block_outlined, label: 'Blocked'),
        _RichFact(icon: Icons.person_outline, label: 'Maya -> Jordan'),
        _RichFact(icon: Icons.message_outlined, label: 'Invite blocked'),
        _RichFact(icon: Icons.security_outlined, label: 'Safety audit'),
      ],
      actionSurfaceTitle: 'Connection safety guard',
      actionHeroSubtitle: 'Invite body blocked before delivery',
      actionHeroBody:
          'Confirm sender Maya, protected recipient Jordan, attempted invite text, block reason, disabled delivery, and unblock/appeal option.',
      actionPanelTitle: 'Safety details',
      actionPanelBody:
          'The member cannot send the invite while the block is active; the attempted message body stays in audit, not in Jordan\'s inbox.',
      alternateActionLabel: 'Open block details',
      detailTitle: 'Safety details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Sender and protected recipient',
          body:
              'Maya Chen attempted to invite Jordan Lee; Jordan remains protected by an active block.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.message_outlined,
          title: 'Attempted invite body',
          body:
              'Invite text: "Join my community circle for Saturday event planning."',
        ),
        _ActionSurfaceDetail(
          icon: Icons.article_outlined,
          title: 'Community safety record',
          body: 'Safety note from moderator Alex, updated today at 10:30 AM.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.block_outlined,
          title: 'Disabled action',
          body:
              'Send invite is disabled; unblock or appeal is required before contact.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.history_outlined,
          title: 'Audit',
          body:
              'Audit records sender, blocked target, attempted body, timestamp, and moderator action.',
        ),
      ],
      stateTitle: 'Decision recorded',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.security_outlined,
          title: 'Receiver protection',
          body: 'The protected member does not receive unsafe contact.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.undo_outlined,
          title: 'Continuation',
          body: 'Moderator can unblock or keep the guard active.',
        ),
      ],
      completeTitle: 'Blocked state confirmed',
      completeBody:
          'The community safety record shows sender, protected recipient, attempted body, disabled action, audit timestamp, and appeal/unblock option.',
      receivedTitle: 'Prevention received',
      receivedBody:
          'The member sees a safe explanation, no unsafe invite is delivered, and unblock/appeal option remains visible.',
      completeLabel: 'Blocked',
    );
  }
  final isConnectionsEntry = id.contains('connections-entry');
  return _richSurface(
    layout: _RichWorkflowLayout.messageThread,
    accent: const Color(0xff315c8a),
    icon: isConnectionsEntry
        ? Icons.people_alt_outlined
        : Icons.person_add_alt_outlined,
    title: isConnectionsEntry
        ? 'Connections inbox'
        : 'Member connection invite',
    subtitle: isConnectionsEntry
        ? 'Pending invite from Maya, accepted contacts, and blocked-state summary.'
        : 'Maya invites Jordan with accept/decline, cancel, and block options.',
    body: isConnectionsEntry
        ? 'Manage connection requests with sender, message body, timestamp, mutual community, accept/decline choices, and blocked-contact status.'
        : 'Send a connection invite with sender, recipient, invite message body, timestamp, accept/decline option, and inbox state.',
    facts: const [
      _RichFact(icon: Icons.person_outline, label: 'Maya -> Jordan'),
      _RichFact(icon: Icons.message_outlined, label: 'Invite message'),
      _RichFact(icon: Icons.check_circle_outline, label: 'Accept/decline'),
      _RichFact(icon: Icons.schedule_outlined, label: 'Today 9:12 AM'),
    ],
    actionSurfaceTitle: isConnectionsEntry
        ? 'Connections inbox'
        : 'Connection invite',
    actionHeroSubtitle: isConnectionsEntry
        ? 'Pending and active community connections'
        : 'Invite Jordan to connect',
    actionHeroBody: isConnectionsEntry
        ? 'Open sender, invite body, timestamp, accept/decline buttons, active contacts, and blocked state.'
        : 'Confirm recipient Jordan, sender Maya, invite body, timestamp, and the recipient inbox preview before sending.',
    actionPanelTitle: 'Invite details',
    actionPanelBody:
        'Recipient sees the invite text, sender, timestamp, mutual community, accept, decline, block, and thread-continuation options.',
    alternateActionLabel: 'Cancel invite',
    detailTitle: 'Invite details',
    detailRows: const [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Sender and recipient',
        body: 'Maya Chen invites Jordan Lee to connect inside the community.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.message_outlined,
        title: 'Invite body',
        body:
            'Message: "Want to coordinate the Saturday welcome table together?"',
      ),
      _ActionSurfaceDetail(
        icon: Icons.schedule_outlined,
        title: 'Timestamp',
        body: 'Today 9:12 AM, expires in 7 days if unanswered.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.person_add_alt_outlined,
        title: 'Invite record',
        body: 'Pending invite can be accepted, declined, canceled, or blocked.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.inbox_outlined,
        title: 'Receiver inbox',
        body: 'Recipient inbox shows sender, context, and decision buttons.',
      ),
    ],
    stateTitle: 'Relationship record',
    stateRows: const [
      _ActionSurfaceDetail(
        icon: Icons.check_circle_outline,
        title: 'Accepted',
        body: 'Accepted invites open a thread and connection history.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.close_outlined,
        title: 'Declined or canceled',
        body: 'Decline/cancel keeps history without opening a thread.',
      ),
    ],
    completeTitle: 'Connection invite sent',
    completeBody:
        'The invite shows sender, recipient, message body, timestamp, accept/decline state, cancel option, and inbox continuation.',
    receivedTitle: 'Connection invite ready',
    receivedBody:
        'The receiver sees sender, invite body, timestamp, mutual community, and can accept, decline, block, or open the related thread.',
    completeLabel: 'Invite sent',
  );
}

_RichWorkflowSpec _adOffRichSpecFor(String id) {
  final receipt = id.contains('receipt');
  final suppression = id.contains('suppression');
  final settlement = id.contains('settlement');
  final entitlement = id.contains('entitlement');
  final community = id.contains('community');
  if (receipt) {
    return _richSurface(
      accent: const Color(0xff5b5f97),
      icon: Icons.receipt_long_outlined,
      title: 'Ad-off receipt history',
      subtitle: 'Receipt ADO-1042 - 4.99 USD monthly member plan.',
      body:
          'Open receipt evidence with payer, amount, date, entitlement scope, payment state, refund option, and exportable audit record.',
      facts: const [
        _RichFact(icon: Icons.receipt_long_outlined, label: 'ADO-1042'),
        _RichFact(icon: Icons.payments_outlined, label: '4.99 USD'),
        _RichFact(icon: Icons.person_outline, label: 'Member payer'),
        _RichFact(icon: Icons.download_outlined, label: 'Export receipt'),
      ],
      actionSurfaceTitle: 'Receipt evidence',
      actionHeroSubtitle: 'Member ad-off receipt',
      actionHeroBody:
          'Amount, payer, scope, payment progress, refund/retry option, and audit metadata are visible before sharing or exporting.',
      actionPanelTitle: 'Receipt details',
      actionPanelBody:
          'Receipt record, history, support, export, refund questions, and entitlement restore stay visible.',
      alternateActionLabel: 'Export receipt',
      detailTitle: 'Receipt details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          body: 'ADO-1042, paid today at 2:10 PM, card ending 4242.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.workspace_premium_outlined,
          title: 'Entitlement',
          body: 'Member ad-free entitlement active through Aug 30.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          body: 'Refund/retry/support history is linked to this receipt.',
        ),
      ],
      stateTitle: 'Receipt record',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.download_outlined,
          title: 'Export',
          body: 'Receipt can be exported with checksum and audit trail.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.restore_outlined,
          title: 'Restore',
          body: 'Restore purchase uses this receipt and payer context.',
        ),
      ],
      completeTitle: 'Receipt opened',
      completeBody:
          'Receipt status is confirmed with amount, payer, scope, entitlement, export option, and support history.',
      receivedTitle: 'Receipt ready',
      receivedBody:
          'The member can open receipt history, entitlement record, and export support evidence.',
      completeLabel: 'Receipt',
    );
  }
  if (suppression) {
    return _richSurface(
      accent: const Color(0xff4f6f5b),
      icon: Icons.visibility_off_outlined,
      title: 'Ad suppression proof',
      subtitle: 'Sponsored slots suppressed by active ad-off entitlement.',
      body:
          'Verify the 4.99 USD monthly ad-free plan, which ad slots are suppressed, why no ad rendered, what entitlement applies, and how to restore or audit the decision.',
      facts: const [
        _RichFact(icon: Icons.visibility_off_outlined, label: 'Ads hidden'),
        _RichFact(icon: Icons.verified_user_outlined, label: 'Entitled'),
        _RichFact(icon: Icons.campaign_outlined, label: '2 slots checked'),
        _RichFact(icon: Icons.history_outlined, label: 'Audit trail'),
      ],
      actionSurfaceTitle: 'Suppression decision',
      actionHeroSubtitle: 'No sponsored message due to ad-off',
      actionHeroBody:
          'Confirm the 4.99 USD entitlement, slot list, no-fill reason, restoration option, and settlement utility audit.',
      actionPanelTitle: 'Suppression proof',
      actionPanelBody:
          'Confirm ad suppression status, 4.99 USD plan amount, each eligible slot, no impression, and the entitlement that caused it.',
      alternateActionLabel: 'Restore ads',
      detailTitle: 'Suppressed slots',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.web_asset_outlined,
          title: 'Top banner',
          body:
              'Suppressed: member ad-off entitlement active on the 4.99 USD monthly plan.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.dynamic_feed_outlined,
          title: 'In-stream placement',
          body: 'Suppressed: no impression or click recorded.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.restore_outlined,
          title: 'Restore option',
          body: 'Member can restore ads or manage subscription.',
        ),
      ],
      stateTitle: 'After suppression',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.analytics_outlined,
          title: 'No impression',
          body: 'Analytics records suppression, not an ad impression.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Evidence',
          body: 'Receipt and entitlement link explain the suppression.',
        ),
      ],
      completeTitle: 'Suppression verified',
      completeBody:
          'Ad suppression status is confirmed with suppressed slots, entitlement, no-impression history, restore option, and audit evidence.',
      receivedTitle: 'Ad-free state ready',
      receivedBody:
          'The member sees suppression history, which slots were hidden, and how to manage or restore ads.',
      completeLabel: 'Suppressed',
    );
  }
  if (settlement) {
    return _richSurface(
      accent: const Color(0xff6a6d3f),
      icon: Icons.account_balance_outlined,
      title: 'Ad-off settlement allocation',
      subtitle: 'Community utility allocation from ad-off revenue.',
      body:
          'Confirm monthly revenue, platform fee, community utility allocation, settlement status, and audit/rollback option.',
      facts: const [
        _RichFact(icon: Icons.payments_outlined, label: '120.00 USD'),
        _RichFact(icon: Icons.account_balance_outlined, label: 'Utility fund'),
        _RichFact(icon: Icons.schedule_outlined, label: 'Month end'),
        _RichFact(icon: Icons.verified_outlined, label: 'Audit ready'),
      ],
      actionSurfaceTitle: 'Settlement utility',
      actionHeroSubtitle: 'June ad-off utility allocation',
      actionHeroBody:
          'Confirm allocation, settlement destination, audit trail, and correction option before marking utility ready.',
      actionPanelTitle: 'Settlement details',
      actionPanelBody:
          'Admins see amount, destination, settlement status, receipt linkage, and rollback/correction option.',
      alternateActionLabel: 'Open allocation',
      detailTitle: 'Settlement details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.account_balance_outlined,
          title: 'Destination',
          body: 'Community utility fund receives June ad-off allocation.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.payments_outlined,
          title: 'Amount',
          body: '120.00 USD community plan, 96.00 USD utility allocation.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.history_outlined,
          title: 'Audit',
          body: 'Receipt, entitlement, and settlement run are linked.',
        ),
      ],
      stateTitle: 'Settlement state',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.verified_outlined,
          title: 'Ready',
          body: 'Settlement is ready for owner action and export.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.undo_outlined,
          title: 'Correction option',
          body: 'Admin can correct allocation before final settlement.',
        ),
      ],
      completeTitle: 'Settlement recorded',
      completeBody:
          'The settlement surface shows amount, destination, audit, correction option, and utility status.',
      receivedTitle: 'Settlement state ready',
      receivedBody:
          'Admins can open amount, destination, audit trail, and correction option.',
      completeLabel: 'Reviewed',
    );
  }
  if (entitlement) {
    return _richSurface(
      accent: const Color(0xff4d668f),
      icon: Icons.verified_user_outlined,
      title: 'Ad-off entitlement record',
      subtitle: 'Active member entitlement through Aug 30.',
      body:
          'Open entitlement scope, 4.99 USD monthly amount, expiration, subscription state, restore option, receipt link, and ad-free member view.',
      facts: const [
        _RichFact(icon: Icons.verified_user_outlined, label: 'Active'),
        _RichFact(icon: Icons.calendar_today_outlined, label: 'Aug 30'),
        _RichFact(icon: Icons.restore_outlined, label: 'Restore option'),
        _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt linked'),
      ],
      actionSurfaceTitle: 'Entitlement record',
      actionHeroSubtitle: 'Member ad-free entitlement',
      actionHeroBody:
          'Confirm scope, 4.99 USD renewal amount, expiration, restore, receipt, and ad-slot member view.',
      actionPanelTitle: 'Entitlement details',
      actionPanelBody:
          'Confirm subscription record, 4.99 USD plan amount, manage subscription, restore purchase, open receipt, or verify suppressed ad slots.',
      alternateActionLabel: 'Manage plan',
      detailTitle: 'Entitlement details',
      detailRows: const [
        _ActionSurfaceDetail(
          icon: Icons.person_outline,
          title: 'Scope',
          body:
              'Member-level ad-off for current account and communities at 4.99 USD monthly.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.calendar_today_outlined,
          title: 'Expiration',
          body: 'Active through Aug 30, renews monthly.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.receipt_long_outlined,
          title: 'Receipt',
          body: 'Receipt ADO-1042 proves payer and entitlement state.',
        ),
      ],
      stateTitle: 'Member result',
      stateRows: const [
        _ActionSurfaceDetail(
          icon: Icons.visibility_off_outlined,
          title: 'Ad-free slots',
          body: 'Eligible sponsored slots are suppressed while active.',
        ),
        _ActionSurfaceDetail(
          icon: Icons.restore_outlined,
          title: 'Restore',
          body: 'Restore purchase and manage plan remain available.',
        ),
      ],
      completeTitle: 'Entitlement checked',
      completeBody:
          'Subscription status is confirmed with entitlement scope, expiration, receipt, restore option, and ad-free slot history.',
      receivedTitle: 'Entitlement ready',
      receivedBody:
          'The member can verify active ad-off subscription, receipt history, and suppressed ad status.',
      completeLabel: 'Active',
    );
  }
  return _richSurface(
    accent: const Color(0xff5b5f97),
    icon: Icons.workspace_premium_outlined,
    title: community ? 'Community ad-off checkout' : 'Member ad-off checkout',
    subtitle: community
        ? '120.00 USD monthly community ad-free plan.'
        : '4.99 USD monthly member ad-free plan.',
    body:
        'Confirm payer, amount, entitlement scope, payment method, renewal, receipt, and restore/manage option before checkout.',
    facts: [
      _RichFact(
        icon: Icons.credit_card_outlined,
        label: community ? '120.00 USD' : '4.99 USD',
      ),
      _RichFact(
        icon: Icons.person_outline,
        label: community ? 'Community pays' : 'Member pays',
      ),
      const _RichFact(icon: Icons.receipt_long_outlined, label: 'Receipt'),
      const _RichFact(icon: Icons.visibility_off_outlined, label: 'Ads hidden'),
    ],
    actionSurfaceTitle: community
        ? 'Community ad-off checkout'
        : 'Member ad-off checkout',
    actionHeroSubtitle: community
        ? 'Ad-free for all eligible community members'
        : 'Ad-free for this member account',
    actionHeroBody: community
        ? 'Confirm payer, amount, renewal, utility settlement, receipt, and receiver entitlement before checkout.'
        : 'Confirm payer, amount, renewal, receipt, restore option, and suppressed ad slots before checkout.',
    actionPanelTitle: 'Payment summary',
    actionPanelBody:
        'Confirm checkout status; purchase creates receipt evidence, activates entitlement, and leaves manage/cancel/restore actions available.',
    alternateActionLabel: 'Change plan',
    detailTitle: 'Checkout details',
    detailRows: [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Payer and scope',
        body: community
            ? 'Community admin pays 120.00 USD/month for eligible members.'
            : 'Member pays 4.99 USD/month for their account.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.credit_card_outlined,
        title: 'Payment',
        body: community
            ? 'Payment method, renewal, utility allocation, and fee details are shown.'
            : 'Payment method, renewal, receipt, retry, and cancellation are shown.',
      ),
      const _ActionSurfaceDetail(
        icon: Icons.visibility_off_outlined,
        title: 'Ad-free result',
        body: 'Eligible sponsored slots become suppressed after payment.',
      ),
    ],
    stateTitle: 'Checkout result',
    stateRows: [
      _ActionSurfaceDetail(
        icon: Icons.verified_outlined,
        title: 'Entitlement',
        body: community
            ? 'Community entitlement activates for eligible members.'
            : 'Member entitlement activates immediately.',
      ),
      const _ActionSurfaceDetail(
        icon: Icons.restore_outlined,
        title: 'Manage',
        body: 'Manage subscription, cancel, restore, retry, or open receipt.',
      ),
    ],
    completeTitle: community
        ? 'Community ad-off purchased'
        : 'Member ad-off purchased',
    completeBody:
        'Checkout status is complete with payer, amount, scope, receipt, entitlement, manage option, and suppressed ad result.',
    receivedTitle: 'Ad-off entitlement ready',
    receivedBody:
        'The receiver sees entitlement record, receipt history, suppressed ad slots, and manage/restore next step.',
    completeLabel: 'Purchased',
  );
}

_RichWorkflowSpec _exportRichSpecFor(String id) {
  final isImport =
      id.contains('import-preview') || id.contains('import-replay');
  final isTransfer = id.contains('transfer-verification');
  final isRedaction = id.contains('protected-redaction');
  final isRollback = id.contains('transfer-rollback');
  final isSchema = id.contains('schema-listing');
  final isChecksum = id.contains('checksum');
  final title = isImport
      ? 'Legacy import preview'
      : isRedaction
      ? 'Protected redaction preview'
      : isSchema
      ? 'Exportable schema catalog'
      : isChecksum
      ? 'Checksum evidence record'
      : isRollback
      ? 'Provider rollback plan'
      : isTransfer
      ? 'Provider transfer verification'
      : 'Full export bundle';
  final subtitle = isImport
      ? 'Preview rows, conflicts, replay checkpoint, and rollback marker.'
      : isRedaction
      ? 'Mask protected fields with policy reasons before export.'
      : isSchema
      ? 'List schemas, field classes, custom records, and history.'
      : isChecksum
      ? 'Verify digest, file count, byte size, and integrity receipt.'
      : isRollback
      ? 'Recover from provider mismatch using the last good snapshot.'
      : isTransfer
      ? 'Verify destination provider, handshake, receipt, and audit trail.'
      : 'Generate a downloadable package with scope, redaction, and checksum.';
  final body = isImport
      ? 'Open imported member, document, and receipt rows; resolve duplicates; and confirm replay checkpoint before importing.'
      : isRedaction
      ? 'Open protected youth roster fields, guardian-visible profile details, coach-only notes, masked phone, care, vault, and payment fields with policy reasons and reveal permissions.'
      : isSchema
      ? 'Open every exportable table, field classification, custom schema, version history, and include/exclude decision.'
      : isChecksum
      ? 'Compare source checksum, package checksum, byte size, and integrity receipt before marking the export verified.'
      : isRollback
      ? 'Choose retry, cancel, or rollback after a destination mismatch and keep the recovery audit visible.'
      : isTransfer
      ? 'Confirm source hash, destination hash, provider ID, transfer timestamp, and receipt before closing transfer.'
      : 'Generate the full export bundle with selected records, redaction preview, checksum, download state, and audit trail.';
  final actionPanelTitle = isImport
      ? 'Import replay checkpoint'
      : isRedaction
      ? 'Redaction policy checkpoint'
      : isSchema
      ? 'Schema scope checkpoint'
      : isChecksum
      ? 'Checksum verification checkpoint'
      : isRollback
      ? 'Transfer rollback checkpoint'
      : isTransfer
      ? 'Transfer verification checkpoint'
      : 'Export bundle checkpoint';
  final actionPanelBody = isImport
      ? 'Resolve duplicate rows, confirm checkpoint I-118, then replay the import with retry and rollback available.'
      : isRedaction
      ? 'Apply the protected-field mask and keep before/after preview, policy reason, and reveal permission visible.'
      : isSchema
      ? 'Confirm which schemas are included and whether custom records need version history.'
      : isChecksum
      ? 'Run verification, compare digests, and store the integrity receipt with export scope.'
      : isRollback
      ? 'Restore the last good snapshot or retry destination transfer after reviewing mismatch details.'
      : isTransfer
      ? 'Compare destination provider receipt with source package hash before confirming transfer.'
      : 'Generate the package after confirming scope, redaction preview, destination, and audit history.';
  final alternateLabel = isImport
      ? 'Skip duplicate'
      : isRedaction
      ? 'Reveal field'
      : isSchema
      ? 'Exclude schema'
      : isChecksum
      ? 'Verify again'
      : isRollback
      ? 'Retry transfer'
      : isTransfer
      ? 'Hold transfer'
      : 'Change scope';
  final detailRows = isImport
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.preview_outlined,
            title: 'Rows preview',
            body:
                '48 members, 22 documents, 12 receipts, and three duplicate records are visible.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.warning_amber_outlined,
            title: 'Conflict choices',
            body:
                'Duplicates can be accepted, skipped, or held for owner decision.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Replay checkpoint',
            body:
                'Checkpoint I-118 lets the owner retry or roll back the import.',
          ),
        ]
      : isRedaction
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Protected values',
            body:
                'Protected youth profile, minor roster phone, care, vault, payment, and private notes are masked.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.rule_outlined,
            title: 'Policy reason',
            body:
                'Each masked field shows guardian or coach visibility policy and the persona allowed to reveal it.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.preview_outlined,
            title: 'Before/after',
            body:
                'Owner compares source label, exported safe value, and redaction count.',
          ),
        ]
      : isSchema
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.schema_outlined,
            title: 'Schema list',
            body:
                'community, member, receipt, document, message, task, event, and custom tables.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.key_outlined,
            title: 'Field classes',
            body:
                'Public, member, protected, payment, audit, and custom field classes are shown.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Version history',
            body:
                'Each schema row includes version, owner, and last export progress.',
          ),
        ]
      : isChecksum
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Digest',
            body:
                'Checksum 9A7F-PORT, file count 84, size 18.4 MB, SHA-256 verified.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.compare_arrows_outlined,
            title: 'Comparison',
            body:
                'Source package hash and destination package hash must match.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.receipt_long_outlined,
            title: 'Integrity receipt',
            body:
                'Receipt links checksum, scope, timestamp, and verifier identity.',
          ),
        ]
      : isRollback
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.error_outline,
            title: 'Mismatch',
            body:
                'Destination provider hash differs from source package checksum.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Rollback checkpoint',
            body: 'Snapshot E-204 is the last good state and can be restored.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Recovery audit',
            body:
                'Audit logs who started rollback, time, scope, and restored status.',
          ),
        ]
      : isTransfer
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.cloud_sync_outlined,
            title: 'Destination',
            body: 'Provider Cloud HOA receives bundle E-204 after handshake.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.verified_outlined,
            title: 'Hash match',
            body:
                'Source hash and provider receipt hash match before closeout.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.receipt_long_outlined,
            title: 'Receipt',
            body: 'Transfer receipt shows provider ID, timestamp, and status.',
          ),
        ]
      : const [
          _ActionSurfaceDetail(
            icon: Icons.folder_zip_outlined,
            title: 'Bundle contents',
            body:
                'Members, receipts, documents, messages, custom records, and export metadata.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.visibility_off_outlined,
            title: 'Redaction',
            body: 'Protected fields are counted and masked before download.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.file_download_outlined,
            title: 'Download',
            body:
                'Owner sees file size, checksum, download progress, and next transfer step.',
          ),
        ];
  final stateRows = isImport
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.playlist_add_check_outlined,
            title: 'Import state',
            body:
                'Replay status, duplicate decisions, and rollback marker remain visible.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.undo_outlined,
            title: 'Undo option',
            body: 'Owner can stop replay or roll back to checkpoint I-118.',
          ),
        ]
      : isRollback
      ? const [
          _ActionSurfaceDetail(
            icon: Icons.restore_outlined,
            title: 'Restored state',
            body:
                'Records return to snapshot E-204 and destination status is marked rolled back.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.refresh_outlined,
            title: 'Retry option',
            body:
                'Owner can retry transfer after provider mismatch is resolved.',
          ),
        ]
      : const [
          _ActionSurfaceDetail(
            icon: Icons.file_download_outlined,
            title: 'Owner artifact',
            body:
                'Owner can download or transfer only after required verification succeeds.',
          ),
          _ActionSurfaceDetail(
            icon: Icons.history_outlined,
            title: 'Audit trail',
            body:
                'Scope, decision, timestamp, checksum, and actor are preserved.',
          ),
        ];
  return _richSurface(
    layout: _RichWorkflowLayout.exportWizard,
    accent: const Color(0xff536878),
    icon: isImport
        ? Icons.preview_outlined
        : isRedaction
        ? Icons.visibility_off_outlined
        : isSchema
        ? Icons.schema_outlined
        : isChecksum
        ? Icons.verified_outlined
        : isRollback
        ? Icons.undo_outlined
        : isTransfer
        ? Icons.cloud_sync_outlined
        : Icons.folder_zip_outlined,
    title: title,
    subtitle: subtitle,
    body: body,
    facts: [
      _RichFact(
        icon: isSchema ? Icons.schema_outlined : Icons.dataset_outlined,
        label: isSchema ? '8 schemas listed' : 'Scope selected',
      ),
      _RichFact(
        icon: isRedaction
            ? Icons.visibility_off_outlined
            : isImport
            ? Icons.warning_amber_outlined
            : Icons.verified_outlined,
        label: isRedaction
            ? 'Policy masks'
            : isImport
            ? '3 conflicts'
            : 'Verified',
      ),
      _RichFact(
        icon: isRollback ? Icons.restore_outlined : Icons.receipt_long_outlined,
        label: isRollback ? 'Checkpoint E-204' : 'Audit receipt',
      ),
      _RichFact(
        icon: isTransfer
            ? Icons.cloud_done_outlined
            : Icons.file_download_outlined,
        label: isTransfer ? 'Provider receipt' : 'Owner artifact',
      ),
    ],
    actionPanelTitle: actionPanelTitle,
    actionPanelBody: actionPanelBody,
    alternateActionLabel: alternateLabel,
    detailTitle: isSchema
        ? 'Schema details'
        : isImport
        ? 'Import details'
        : isRollback
        ? 'Recovery details'
        : isTransfer
        ? 'Transfer details'
        : 'Package details',
    detailRows: detailRows,
    stateTitle: isRollback
        ? 'Recovery state'
        : isImport
        ? 'Replay state'
        : 'Verification state',
    stateRows: stateRows,
    completeTitle: isImport
        ? 'Import replay ready'
        : isRedaction
        ? 'Redaction applied'
        : isSchema
        ? 'Schema scope saved'
        : isChecksum
        ? 'Checksum verified'
        : isRollback
        ? 'Rollback planned'
        : isTransfer
        ? 'Transfer verified'
        : 'Export bundle generated',
    completeBody: isImport
        ? 'Import preview shows row counts, duplicate decisions, checkpoint, retry, and rollback state.'
        : isRedaction
        ? 'Protected redaction shows youth profile and roster details, guardian or coach visibility, masked fields, policy reasons, before/after preview, and audit evidence.'
        : isSchema
        ? 'Schema catalog shows exportable tables, field classes, history, and include/exclude scope.'
        : isChecksum
        ? 'Checksum evidence shows digest, file count, byte size, verification status, and integrity receipt.'
        : isRollback
        ? 'Rollback plan shows mismatch reason, checkpoint, restore action, retry option, and recovery audit.'
        : isTransfer
        ? 'Transfer verification shows provider, hash match, receipt, timestamp, and closeout state.'
        : 'Full export bundle shows contents, redaction, checksum, file size, download progress, and audit trail.',
    completeLabel: isRollback
        ? 'Rollback ready'
        : isTransfer
        ? 'Verified'
        : isChecksum
        ? 'Verified'
        : isImport
        ? 'Previewed'
        : 'Ready',
  );
}

_RichWorkflowSpec _richSurface({
  _RichWorkflowLayout? layout,
  required Color accent,
  required IconData icon,
  required String title,
  required String subtitle,
  required String body,
  required List<_RichFact> facts,
  required String detailTitle,
  required List<_ActionSurfaceDetail> detailRows,
  required String stateTitle,
  required List<_ActionSurfaceDetail> stateRows,
  String? actionSurfaceTitle,
  String? actionHeroSubtitle,
  String? actionHeroBody,
  String? actionPanelTitle,
  String? actionPanelBody,
  String? alternateActionLabel,
  String? completeTitle,
  String? completeBody,
  String? receivedTitle,
  String? receivedBody,
  String? completeLabel,
}) {
  return _RichWorkflowSpec(
    layout: layout ?? _inferredRichWorkflowLayout(title, subtitle, detailTitle),
    accent: accent,
    icon: icon,
    title: title,
    subtitle: subtitle,
    body: body,
    facts: facts,
    actionSurfaceTitle: actionSurfaceTitle ?? title,
    actionHeroSubtitle: actionHeroSubtitle ?? subtitle,
    actionHeroBody: actionHeroBody ?? body,
    actionPanelTitle: actionPanelTitle ?? 'Task details',
    actionPanelBody:
        actionPanelBody ??
        'Key fields, status, available edits, and the next visible outcome stay together on this community surface.',
    alternateActionLabel: alternateActionLabel ?? 'Edit details',
    detailTitle: detailTitle,
    detailRows: detailRows,
    stateTitle: stateTitle,
    stateRows: stateRows,
    completeTitle: completeTitle ?? 'Saved',
    completeBody:
        completeBody ?? '$title is saved with visible result and next steps.',
    receivedTitle: receivedTitle ?? '$title ready',
    receivedBody:
        receivedBody ??
        'The recipient can read the saved details, understand what changed, and continue from the next step.',
    completeLabel: completeLabel ?? 'Saved',
  );
}

_RichWorkflowLayout _inferredRichWorkflowLayout(
  String title,
  String subtitle,
  String detailTitle,
) {
  final text = '$title $subtitle $detailTitle'.toLowerCase();
  if (text.contains('export') ||
      text.contains('import') ||
      text.contains('transfer') ||
      text.contains('redaction') ||
      text.contains('checksum') ||
      text.contains('schema')) {
    return _RichWorkflowLayout.exportWizard;
  }
  if (text.contains('search') ||
      text.contains('citation') ||
      text.contains('digest') ||
      text.contains('answer')) {
    return _RichWorkflowLayout.searchAnswer;
  }
  if (text.contains('message') ||
      text.contains('thread') ||
      text.contains('connection') ||
      text.contains('invite') ||
      text.contains('blocked')) {
    return _RichWorkflowLayout.messageThread;
  }
  if (text.contains('announcement') ||
      text.contains('notification') ||
      text.contains('notice') ||
      text.contains('publish')) {
    return _RichWorkflowLayout.noticeDetail;
  }
  if (text.contains('rsvp') ||
      text.contains('event') ||
      text.contains('schedule') ||
      text.contains('reservation') ||
      text.contains('facility') ||
      text.contains('practice') ||
      text.contains('meeting') ||
      text.contains('walk')) {
    return _RichWorkflowLayout.eventDetail;
  }
  if (text.contains('payment') ||
      text.contains('donation') ||
      text.contains('dues') ||
      text.contains('checkout') ||
      text.contains('receipt') ||
      text.contains('settlement') ||
      text.contains('fee')) {
    if (text.contains('ad-off') || text.contains('ad-free')) {
      return _RichWorkflowLayout.adEntitlement;
    }
    return _RichWorkflowLayout.paymentReceipt;
  }
  if (text.contains('ad-off') ||
      text.contains('ad-free') ||
      text.contains('suppression') ||
      text.contains('entitlement')) {
    return _RichWorkflowLayout.adEntitlement;
  }
  if (text.contains('roster') ||
      text.contains('minor') ||
      text.contains('guardian') ||
      text.contains('team')) {
    return _RichWorkflowLayout.rosterProfile;
  }
  if (text.contains('request') ||
      text.contains('approval') ||
      text.contains('decision') ||
      text.contains('committee') ||
      text.contains('review')) {
    return _RichWorkflowLayout.requestReview;
  }
  if (text.contains('critique') ||
      text.contains('camera') ||
      text.contains('photo')) {
    return _RichWorkflowLayout.mediaReview;
  }
  if (text.contains('volunteer') ||
      text.contains('plant') ||
      text.contains('gear') ||
      text.contains('loan') ||
      text.contains('offer') ||
      text.contains('form') ||
      text.contains('care')) {
    return _RichWorkflowLayout.formSubmission;
  }
  if (text.contains('book') ||
      text.contains('vote') ||
      text.contains('nomination') ||
      text.contains('chess') ||
      text.contains('match')) {
    return _RichWorkflowLayout.clubScoreboard;
  }
  return _RichWorkflowLayout.standard;
}

Widget? _domainPreviewPanelFor(
  String workflowId, {
  required Color accent,
  required Color foreground,
}) {
  if (workflowId == 'book-search-ai-digest') {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'AI answer with citations',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.search_outlined,
          title: 'Query',
          body: 'What should we discuss before chapter 6?',
        ),
        _DomainPreviewRow(
          icon: Icons.auto_awesome_outlined,
          title: 'Answer summary',
          body:
              'Mutual aid, scarcity, and Lauren\'s journal voice are the strongest discussion threads.',
        ),
        _DomainPreviewRow(
          icon: Icons.format_quote_outlined,
          title: 'Cited sources',
          body:
              'Member notes, nomination rationale, and March prompt show source labels and visibility.',
        ),
      ],
    );
  }
  if (workflowId == 'book-export-metadata') {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Book club archive',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.menu_book_outlined,
          title: 'Reading records',
          body:
              'Nominations, ballots, selected books, meeting RSVPs, and reading schedule are included.',
        ),
        _DomainPreviewRow(
          icon: Icons.forum_outlined,
          title: 'Discussion redaction',
          body:
              'Private thread metadata and member contact fields are redacted before download.',
        ),
        _DomainPreviewRow(
          icon: Icons.verified_outlined,
          title: 'Checksum BC-042',
          body:
              'Owner sees checksum, export timestamp, download progress, and audit history.',
        ),
      ],
    );
  }
  if (workflowId.contains('photo-walk')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Photo walk details',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.route_outlined,
          title: 'Riverfront golden-hour route',
          body: 'Meet at Dock 4, walk the mural loop, finish at the pier.',
        ),
        _DomainPreviewRow(
          icon: Icons.groups_outlined,
          title: '12 going, 4 spots left',
          body: 'Maybe and Not going stay available until Saturday noon.',
        ),
        _DomainPreviewRow(
          icon: Icons.camera_alt_outlined,
          title: 'Bring 35mm or phone camera',
          body: 'Reminder includes rain plan, gear note, and host contact.',
        ),
      ],
    );
  }
  if (workflowId.contains('critique')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Critique submission',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.image_outlined,
          title: 'Street portrait: â€œEvening Reflectionâ€',
          body: 'Prompt, consent note, and visibility are reviewed together.',
        ),
        _DomainPreviewRow(
          icon: Icons.rate_review_outlined,
          title: 'Reviewer queue',
          body:
              'Avery reviews composition; comments and edit option remain open.',
        ),
        _DomainPreviewRow(
          icon: Icons.swap_horiz_outlined,
          title: 'Edit or withdraw',
          body:
              'Member can update caption, replace image, or withdraw before comments.',
        ),
      ],
    );
  }
  if (workflowId.contains('gear')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: 'Gear loan roster',
      rows: const [
        _DomainPreviewRow(
          icon: Icons.camera_outdoor_outlined,
          title: '35mm prime lens',
          body: 'Owned by Sam; pickup Friday 5 PM and return Sunday evening.',
        ),
        _DomainPreviewRow(
          icon: Icons.people_outline,
          title: '2 borrowers waiting',
          body: 'Borrower list is visible after owner approves the loan.',
        ),
        _DomainPreviewRow(
          icon: Icons.keyboard_return_outlined,
          title: 'Return and cancel option',
          body: 'Member can cancel request, update pickup, or mark returned.',
        ),
      ],
    );
  }
  if (workflowId.startsWith('platform-')) {
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: workflowId.contains('sensitive')
          ? 'Privacy-safe ad suppression'
          : workflowId.contains('banner')
          ? 'Top banner reserved space'
          : workflowId.contains('ad') || workflowId.contains('no-fill')
          ? 'Sponsored message placement'
          : workflowId.contains('blocked')
          ? 'Connection safety guard'
          : 'Member conversation',
      rows: [
        if (workflowId.contains('ad') ||
            workflowId.contains('no-fill')) ...const [
          _DomainPreviewRow(
            icon: Icons.campaign_outlined,
            title: 'Sponsored disclosure',
            body: 'Reserved slot shows sponsor, disclosure, or no-fill reason.',
          ),
          _DomainPreviewRow(
            icon: Icons.visibility_off_outlined,
            title: 'Sensitive context protected',
            body: 'Ad click is hidden when content is protected or suppressed.',
          ),
          _DomainPreviewRow(
            icon: Icons.analytics_outlined,
            title: 'Impression state',
            body:
                'Impression/click is recorded only when an ad is actually filled.',
          ),
        ] else ...const [
          _DomainPreviewRow(
            icon: Icons.person_outline,
            title: 'Maya Chen -> Jordan Lee',
            body:
                'Visible sender, recipient, Today 9:12 AM timestamp, and community relationship.',
          ),
          _DomainPreviewRow(
            icon: Icons.message_outlined,
            title: 'Message body',
            body:
                'Invite says: "Want to coordinate the Saturday welcome table together?"',
          ),
          _DomainPreviewRow(
            icon: Icons.block_outlined,
            title: 'Decision and safety options',
            body:
                'Accept, decline, cancel, mute, archive, block, or unblock remain visible where allowed.',
          ),
        ],
      ],
    );
  }
  if (workflowId.startsWith('ad-off-')) {
    final title = workflowId.contains('receipt')
        ? 'Receipt history'
        : workflowId.contains('suppression')
        ? 'Ad suppression proof'
        : workflowId.contains('entitlement')
        ? 'Subscription status'
        : workflowId.contains('settlement')
        ? 'Settlement allocation'
        : workflowId.contains('community')
        ? 'Community checkout'
        : 'Member checkout';
    final rows = workflowId.contains('receipt')
        ? const [
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Receipt ADO-1042',
              body:
                  'Amount, payer, paid date, scope, refund support, and export trail are visible.',
            ),
            _DomainPreviewRow(
              icon: Icons.download_outlined,
              title: 'Export and support',
              body:
                  'Member can export the receipt or open support history without returning to checkout.',
            ),
            _DomainPreviewRow(
              icon: Icons.verified_user_outlined,
              title: 'Linked entitlement',
              body:
                  'Receipt links directly to current ad-free entitlement and restore option.',
            ),
          ]
        : workflowId.contains('suppression')
        ? const [
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Suppressed top banner',
              body:
                  'No ad rendered; no impression or click recorded for the active entitlement.',
            ),
            _DomainPreviewRow(
              icon: Icons.dynamic_feed_outlined,
              title: 'Suppressed stream slot',
              body:
                  'The stream explains why sponsored content is hidden without exposing private data.',
            ),
            _DomainPreviewRow(
              icon: Icons.restore_outlined,
              title: 'Restore/manage option',
              body:
                  'Member can restore ads or manage ad-off from the same proof screen.',
            ),
          ]
        : workflowId.contains('entitlement')
        ? const [
            _DomainPreviewRow(
              icon: Icons.verified_user_outlined,
              title: 'Active through Aug 30',
              body:
                  'Subscription state, renewal, receipt, and plan scope are visible.',
            ),
            _DomainPreviewRow(
              icon: Icons.restore_outlined,
              title: 'Manage or restore',
              body:
                  'Member can manage plan, restore purchase, or open receipt history.',
            ),
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Ad-free member view',
              body: 'Eligible banner and stream slots remain suppressed.',
            ),
          ]
        : workflowId.contains('settlement')
        ? const [
            _DomainPreviewRow(
              icon: Icons.account_balance_outlined,
              title: 'Utility allocation',
              body:
                  'Community utility fund destination, amount, and month-end status are visible.',
            ),
            _DomainPreviewRow(
              icon: Icons.history_outlined,
              title: 'Audit trail',
              body:
                  'Settlement run, receipts, and rollback/correction option are linked.',
            ),
            _DomainPreviewRow(
              icon: Icons.verified_outlined,
              title: 'Owner action',
              body:
                  'Owner can verify or correct allocation before final settlement.',
            ),
          ]
        : const [
            _DomainPreviewRow(
              icon: Icons.payments_outlined,
              title: 'Plan details',
              body:
                  'Payer, amount, payment method, renewal, and scope are confirmed before purchase.',
            ),
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Receipt after checkout',
              body:
                  'Purchase creates receipt evidence and immediate entitlement record.',
            ),
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Ads hidden after payment',
              body:
                  'Eligible sponsored slots show a suppressed state with manage/restore controls.',
            ),
          ];
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: title,
      rows: rows,
    );
  }
  if (workflowId.startsWith('export-')) {
    final title =
        workflowId.contains('import-preview') ||
            workflowId.contains('import-replay')
        ? 'Legacy import preview'
        : workflowId.contains('full-bundle') ||
              workflowId.contains('redacted-bundle')
        ? 'Downloadable export bundle'
        : workflowId.contains('transfer-verification')
        ? 'Provider transfer verification'
        : workflowId.contains('protected-redaction')
        ? 'Protected-field redaction'
        : workflowId.contains('transfer-rollback')
        ? 'Rollback and recovery'
        : workflowId.contains('schema-listing')
        ? 'Exportable schema catalog'
        : workflowId.contains('checksum')
        ? 'Checksum evidence'
        : 'Portability task';
    final rows =
        workflowId.contains('import-preview') ||
            workflowId.contains('import-replay')
        ? const [
            _DomainPreviewRow(
              icon: Icons.preview_outlined,
              title: 'Import rows',
              body:
                  'Preview 48 member rows, 22 documents, and 12 receipts before replay.',
            ),
            _DomainPreviewRow(
              icon: Icons.warning_amber_outlined,
              title: 'Conflict check',
              body:
                  'Three duplicate records are flagged with accept/skip choices.',
            ),
            _DomainPreviewRow(
              icon: Icons.history_outlined,
              title: 'Replay log',
              body:
                  'Owner sees import checkpoint, retry option, and rollback marker.',
            ),
          ]
        : workflowId.contains('transfer-verification')
        ? const [
            _DomainPreviewRow(
              icon: Icons.cloud_sync_outlined,
              title: 'Destination provider',
              body:
                  'Provider receives bundle E-204 after checksum and scope match.',
            ),
            _DomainPreviewRow(
              icon: Icons.verified_outlined,
              title: 'Handshake',
              body:
                  'Source hash, destination hash, and received timestamp must match.',
            ),
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Transfer receipt',
              body:
                  'Owner gets receipt, provider ID, audit log, and next action.',
            ),
          ]
        : workflowId.contains('protected-redaction')
        ? const [
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Protected fields',
              body:
                  'Care notes, phone numbers, and private vault values are masked.',
            ),
            _DomainPreviewRow(
              icon: Icons.rule_outlined,
              title: 'Policy reason',
              body:
                  'Each redaction lists the policy and the persona allowed to reveal it.',
            ),
            _DomainPreviewRow(
              icon: Icons.preview_outlined,
              title: 'Before/after preview',
              body:
                  'Owner compares raw labels with exported safe values before download.',
            ),
          ]
        : workflowId.contains('transfer-rollback')
        ? const [
            _DomainPreviewRow(
              icon: Icons.undo_outlined,
              title: 'Rollback checkpoint',
              body:
                  'Last good snapshot is retained until destination provider confirms.',
            ),
            _DomainPreviewRow(
              icon: Icons.error_outline,
              title: 'Mismatch reason',
              body:
                  'Destination checksum mismatch triggers retry, cancel, or rollback.',
            ),
            _DomainPreviewRow(
              icon: Icons.history_outlined,
              title: 'Recovery audit',
              body:
                  'Owner sees who started rollback, timestamp, and restored scope.',
            ),
          ]
        : workflowId.contains('schema-listing')
        ? const [
            _DomainPreviewRow(
              icon: Icons.schema_outlined,
              title: 'Schema catalog',
              body:
                  'community, member, receipt, document, message, and custom tables are listed.',
            ),
            _DomainPreviewRow(
              icon: Icons.key_outlined,
              title: 'Field classes',
              body:
                  'Each schema shows public, member, protected, payment, and audit fields.',
            ),
            _DomainPreviewRow(
              icon: Icons.download_outlined,
              title: 'Export coverage',
              body:
                  'Owner can include, exclude, or open schema history before export.',
            ),
          ]
        : workflowId.contains('checksum')
        ? const [
            _DomainPreviewRow(
              icon: Icons.verified_outlined,
              title: 'Checksum 9A7F-PORT',
              body:
                  'SHA-256 digest, file count, and byte size are visible before delivery.',
            ),
            _DomainPreviewRow(
              icon: Icons.compare_arrows_outlined,
              title: 'Verify again',
              body: 'Owner can rerun verification after transfer or download.',
            ),
            _DomainPreviewRow(
              icon: Icons.receipt_long_outlined,
              title: 'Integrity receipt',
              body: 'Checksum receipt links to export scope and audit history.',
            ),
          ]
        : const [
            _DomainPreviewRow(
              icon: Icons.folder_zip_outlined,
              title: 'Bundle contents',
              body:
                  'Members, receipts, documents, messages, and custom records are packaged.',
            ),
            _DomainPreviewRow(
              icon: Icons.visibility_off_outlined,
              title: 'Redaction preview',
              body:
                  'Protected fields are masked and counted before bundle generation.',
            ),
            _DomainPreviewRow(
              icon: Icons.file_download_outlined,
              title: 'Download state',
              body:
                  'Owner sees size, checksum, download progress, and next transfer step.',
            ),
          ];
    return _DomainPreviewPanel(
      accent: accent,
      foreground: foreground,
      title: title,
      rows: rows,
    );
  }
  return null;
}

class _DomainPreviewRow {
  const _DomainPreviewRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _DomainPreviewPanel extends StatelessWidget {
  const _DomainPreviewPanel({
    required this.accent,
    required this.foreground,
    required this.title,
    required this.rows,
  });

  final Color accent;
  final Color foreground;
  final String title;
  final List<_DomainPreviewRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.icon, color: foreground, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.body,
                          style: textTheme.bodyMedium?.copyWith(
                            color: foreground.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (row != rows.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkflowSurfacePresenter extends StatelessWidget {
  const _WorkflowSurfacePresenter({
    required this.extensionId,
    required this.workflow,
    required this.view,
    required this.state,
    required this.accent,
    required this.child,
    required this.onPressed,
    required this.onReceivePressed,
    required this.onExpand,
    required this.onCollapse,
  });

  final String extensionId;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final _SurfacePresentationState state;
  final Color accent;
  final Widget child;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    final foreground = _foregroundFor(accent);
    final isExpanded = state == _SurfacePresentationState.expanded;
    final isMedium = state == _SurfacePresentationState.medium;
    final radius = isExpanded ? 18.0 : 12.0;

    if (state == _SurfacePresentationState.minimized) {
      return _MinimizedWorkflowSurface(
        key: ValueKey('workflow-${workflow.workflowId}'),
        workflow: workflow,
        view: view,
        contract: contract,
        accent: accent,
        onExpand: onExpand,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }

    return Semantics(
      selected: isMedium,
      expanded: isExpanded,
      label:
          '${_displayTitleFor(workflow)} ${isExpanded ? 'expanded' : 'in focus'} surface',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: foreground.withValues(alpha: isExpanded ? 0.34 : 0.18),
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isExpanded ? 0.26 : 0.16),
              blurRadius: isExpanded ? 26 : 14,
              offset: Offset(0, isExpanded ? 12 : 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Color.alphaBlend(
                  foreground.withValues(alpha: 0.08),
                  accent,
                ),
                child: InkWell(
                  key: ValueKey('workflow-expand-${workflow.workflowId}'),
                  onTap: isExpanded ? onCollapse : onExpand,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExpanded
                              ? Icons.fullscreen_exit_outlined
                              : Icons.center_focus_strong_outlined,
                          color: foreground,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isExpanded
                                ? 'Expanded product surface'
                                : 'In-focus product surface',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Text(
                          isExpanded ? 'Collapse' : 'Expand',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimizedWorkflowSurface extends StatelessWidget {
  const _MinimizedWorkflowSurface({
    super.key,
    required this.workflow,
    required this.view,
    required this.contract,
    required this.accent,
    required this.onExpand,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final LoomProductionWorkflowContract contract;
  final Color accent;
  final VoidCallback onExpand;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return Semantics(
      button: true,
      label: '${_displayTitleFor(workflow)} minimized surface',
      child: Card(
        margin: EdgeInsets.zero,
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.84),
          Colors.black.withValues(alpha: 0.08),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: foreground.withValues(alpha: 0.16)),
        ),
        child: InkWell(
          onTap: onExpand,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(contract.icon, color: foreground, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayTitleFor(workflow),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            complete
                                ? view.completed
                                      ? contract.successTitle
                                      : contract.receiverSurfaceTitle
                                : _domainSummaryFor(
                                    contract.category,
                                    workflow,
                                    view,
                                  ),
                            key: complete
                                ? ValueKey(
                                    view.completed
                                        ? 'workflow-result-${workflow.workflowId}'
                                        : 'workflow-received-result-${workflow.workflowId}',
                                  )
                                : null,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: foreground.withValues(alpha: 0.90),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StateBadge(
                      key: complete
                          ? ValueKey(
                              view.completed
                                  ? 'workflow-complete-${workflow.workflowId}'
                                  : 'workflow-received-${workflow.workflowId}',
                            )
                          : null,
                      icon: complete
                          ? Icons.done
                          : Icons.center_focus_strong_outlined,
                      label: complete ? contract.successChipLabel : 'Minimized',
                      foreground: foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SurfaceFactPill(
                      icon: Icons.unfold_more_outlined,
                      label: 'Tap for expanded view',
                      foreground: foreground,
                    ),
                    _SurfaceFactPill(
                      icon: Icons.layers_outlined,
                      label: _surfaceLabelFor(contract.category),
                      foreground: foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      key: ValueKey('workflow-expand-${workflow.workflowId}'),
                      onPressed: onExpand,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        side: BorderSide(
                          color: foreground.withValues(alpha: 0.34),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_full_outlined, size: 18),
                      label: const Text('Expand'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WorkflowAction(
                        contract: contract,
                        workflow: workflow,
                        view: view,
                        onPressed: onPressed,
                        onReceivePressed: onReceivePressed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    if (extensionId == 'ext_garden_club' &&
        workflow.workflowId == 'garden-event-rsvp') {
      return _GardenEventRsvpTile(
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    if (extensionId == 'ext_garden_club' &&
        workflow.workflowId == 'plant-exchange-submission') {
      return _GardenPlantExchangeTile(
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    final richSpec = _richWorkflowSpecFor(workflow.workflowId);
    if (richSpec != null) {
      return _RichWorkflowTile(
        extensionId: extensionId,
        spec: richSpec,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
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

class _RichWorkflowTile extends StatelessWidget {
  const _RichWorkflowTile({
    required this.extensionId,
    required this.spec,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final String extensionId;
  final _RichWorkflowSpec spec;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    final domainPreview = _domainPreviewPanelFor(
      workflow.workflowId,
      accent: spec.accent,
      foreground: foreground,
    );
    if (spec.layout != _RichWorkflowLayout.standard) {
      return _RichProductSurfaceTile(
        extensionId: extensionId,
        spec: spec,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      );
    }
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: spec.accent.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: foreground.withValues(alpha: 0.13),
                  child: Icon(spec.icon, color: foreground),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        spec.subtitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.94),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        complete ? spec.completeBody : spec.body,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fact in spec.facts)
                  _SurfaceFactPill(
                    icon: fact.icon,
                    label: fact.label,
                    foreground: foreground,
                  ),
              ],
            ),
            if (domainPreview != null) ...[
              const SizedBox(height: 12),
              domainPreview,
            ],
            const SizedBox(height: 12),
            _InteractionModelSummary(
              contract: contract,
              foreground: foreground,
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: foreground.withValues(alpha: 0.20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? spec.stateTitle : spec.actionPanelTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      complete ? spec.completeBody : spec.actionPanelBody,
                      style: textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.90),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SurfaceFactPill(
                      icon: Icons.compare_arrows_outlined,
                      label: spec.alternateActionLabel,
                      foreground: foreground,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: spec.completeTitle,
                body: spec.completeBody,
                icon: spec.icon,
                accent: spec.accent,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: spec.receivedTitle,
                body: spec.receivedBody,
                icon: Icons.inbox_outlined,
                accent: spec.accent,
              )
            else
              _WorkflowAction(
                contract: contract,
                workflow: workflow,
                view: view,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            Offstage(
              child: Text(
                view.personaRationale,
                key: ValueKey('workflow-persona-state-${workflow.workflowId}'),
              ),
            ),
            if (view.completed)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey('workflow-complete-${workflow.workflowId}'),
                  icon: Icons.done,
                  label: spec.completeLabel,
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

class _RichProductSurfaceTile extends StatelessWidget {
  const _RichProductSurfaceTile({
    required this.extensionId,
    required this.spec,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final String extensionId;
  final _RichWorkflowSpec spec;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final contract = productionWorkflowContractFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    return KeyedSubtree(
      key: ValueKey('workflow-${workflow.workflowId}'),
      child: _ProductSurfaceFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
    );
  }
}

class _ProductSurfaceFrame extends StatelessWidget {
  const _ProductSurfaceFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    return switch (spec.layout) {
      _RichWorkflowLayout.eventDetail => _EventProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.exportWizard => _WizardProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.paymentReceipt => _ReceiptProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.adEntitlement => _AdFreeProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.messageThread ||
      _RichWorkflowLayout.noticeDetail ||
      _RichWorkflowLayout.searchAnswer => _FeedProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.rosterProfile => _RosterProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.clubScoreboard => _ScoreboardProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _RichWorkflowLayout.formSubmission ||
      _RichWorkflowLayout.requestReview ||
      _RichWorkflowLayout.mediaReview => _FormProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
      _ => _DefaultProductFrame(
        spec: spec,
        contract: contract,
        workflow: workflow,
        view: view,
        onPressed: onPressed,
        onReceivePressed: onReceivePressed,
      ),
    };
  }
}

class _EventProductFrame extends StatelessWidget {
  const _EventProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: foreground.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(spec.icon, color: foreground, size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        complete ? spec.completeBody : spec.body,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _EventDetailPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormProductFrame extends StatelessWidget {
  const _FormProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(spec.icon, color: foreground, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spec.title,
                    style: textTheme.headlineSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              spec.subtitle,
              style: textTheme.bodyLarge?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 14),
            _FormSubmissionPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptProductFrame extends StatelessWidget {
  const _ReceiptProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              style: textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              spec.body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 14),
            _PaymentReceiptPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdFreeProductFrame extends StatelessWidget {
  const _AdFreeProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = spec.accent;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: spec.accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(spec.icon, color: spec.accent, size: 30),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        spec.body,
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AdEntitlementPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _WizardProductFrame extends StatelessWidget {
  const _WizardProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.title,
          style: textTheme.headlineSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          spec.subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: foreground.withValues(alpha: 0.90),
          ),
        ),
        const SizedBox(height: 12),
        _ExportWizardPreview(spec: spec),
        const SizedBox(height: 12),
        _SurfaceActionOrResult(
          spec: spec,
          contract: contract,
          workflow: workflow,
          view: view,
          onPressed: onPressed,
          onReceivePressed: onReceivePressed,
        ),
      ],
    );
  }
}

class _FeedProductFrame extends StatelessWidget {
  const _FeedProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductSurfacePreview(spec: spec),
            const SizedBox(height: 12),
            Text(
              spec.title,
              style: textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterProductFrame extends StatelessWidget {
  const _RosterProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              style: textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              spec.body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 12),
            _RosterProfilePreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreboardProductFrame extends StatelessWidget {
  const _ScoreboardProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spec.title,
              style: textTheme.headlineMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _ClubScoreboardPreview(spec: spec),
            const SizedBox(height: 12),
            _SurfaceActionOrResult(
              spec: spec,
              contract: contract,
              workflow: workflow,
              view: view,
              onPressed: onPressed,
              onReceivePressed: onReceivePressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultProductFrame extends StatelessWidget {
  const _DefaultProductFrame({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductDetailPreview(spec: spec),
        const SizedBox(height: 12),
        _SurfaceActionOrResult(
          spec: spec,
          contract: contract,
          workflow: workflow,
          view: view,
          onPressed: onPressed,
          onReceivePressed: onReceivePressed,
        ),
      ],
    );
  }
}

class _SurfaceActionOrResult extends StatelessWidget {
  const _SurfaceActionOrResult({
    required this.spec,
    required this.contract,
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final _RichWorkflowSpec spec;
  final LoomProductionWorkflowContract contract;
  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    if (view.completed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WorkflowResultPanel(
            key: ValueKey('workflow-result-${workflow.workflowId}'),
            title: spec.completeTitle,
            body: spec.completeBody,
            icon: spec.icon,
            accent: spec.accent,
          ),
          const SizedBox(height: 10),
          _LifecycleFollowUpPanel(spec: spec, received: false),
          const SizedBox(height: 10),
          _StateBadge(
            key: ValueKey('workflow-complete-${workflow.workflowId}'),
            icon: Icons.done,
            label: spec.completeLabel,
            foreground: foreground,
          ),
        ],
      );
    }
    if (view.received) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _WorkflowResultPanel(
            key: ValueKey('workflow-received-result-${workflow.workflowId}'),
            title: spec.receivedTitle,
            body: spec.receivedBody,
            icon: Icons.inbox_outlined,
            accent: spec.accent,
          ),
          const SizedBox(height: 10),
          _LifecycleFollowUpPanel(spec: spec, received: true),
          const SizedBox(height: 10),
          _StateBadge(
            key: ValueKey('workflow-received-${workflow.workflowId}'),
            icon: Icons.mark_email_read_outlined,
            label: 'Received',
            foreground: foreground,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductSurfaceStatusPanel(spec: spec),
        const SizedBox(height: 12),
        _WorkflowAction(
          contract: contract,
          workflow: workflow,
          view: view,
          onPressed: onPressed,
          onReceivePressed: onReceivePressed,
        ),
        Offstage(
          child: Text(
            view.personaRationale,
            key: ValueKey('workflow-persona-state-${workflow.workflowId}'),
          ),
        ),
      ],
    );
  }
}

class _LifecycleFollowUpPanel extends StatelessWidget {
  const _LifecycleFollowUpPanel({required this.spec, required this.received});

  final _RichWorkflowSpec spec;
  final bool received;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final labels = _followUpActionLabelsFor(spec, received: received);
    final rows = spec.stateRows.take(2).toList();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              received ? 'Receiver next steps' : _followUpTitleFor(spec.layout),
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              received
                  ? spec.receivedBody
                  : 'The saved result keeps status, history, and change actions visible for this community task.',
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.88),
              ),
            ),
            if (rows.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final row in rows)
                _ProductPreviewLine(
                  icon: row.icon,
                  title: row.title,
                  body: row.body,
                ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in labels)
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foreground,
                      side: BorderSide(
                        color: foreground.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<String> _followUpActionLabelsFor(
  _RichWorkflowSpec spec, {
  required bool received,
}) {
  if (received) {
    return const ['Open inbox', 'Reply', 'Archive'];
  }
  return switch (spec.layout) {
    _RichWorkflowLayout.eventDetail => const [
      'Change RSVP',
      'Add to calendar',
      'Invite member',
    ],
    _RichWorkflowLayout.formSubmission => const [
      'Edit request',
      'Withdraw',
      'View status',
    ],
    _RichWorkflowLayout.paymentReceipt => const [
      'Open receipt',
      'Retry payment',
      'Request refund',
    ],
    _RichWorkflowLayout.rosterProfile => const [
      'Edit visibility',
      'Message team',
      'Export roster',
    ],
    _RichWorkflowLayout.requestReview => const [
      'Request changes',
      'Reopen',
      'View history',
    ],
    _RichWorkflowLayout.searchAnswer => const [
      'Ask follow-up',
      'Open sources',
      'Share answer',
    ],
    _RichWorkflowLayout.exportWizard => const [
      'Download file',
      'Verify checksum',
      'Rollback',
    ],
    _RichWorkflowLayout.messageThread => const [
      'Reply',
      'Mute thread',
      'Archive',
    ],
    _RichWorkflowLayout.noticeDetail => const [
      'Edit notice',
      'View delivery',
      'Send follow-up',
    ],
    _RichWorkflowLayout.clubScoreboard => const [
      'Edit result',
      'Dispute',
      'Open standings',
    ],
    _RichWorkflowLayout.mediaReview => const [
      'Edit submission',
      'Request feedback',
      'Withdraw',
    ],
    _RichWorkflowLayout.adEntitlement => const [
      'Manage plan',
      'Open receipt',
      'Restore',
    ],
    _ => [spec.alternateActionLabel, 'View history', 'Open details'],
  };
}

class _ProductSurfacePreview extends StatelessWidget {
  const _ProductSurfacePreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return switch (spec.layout) {
      _RichWorkflowLayout.eventDetail => _EventDetailPreview(spec: spec),
      _RichWorkflowLayout.formSubmission => _FormSubmissionPreview(spec: spec),
      _RichWorkflowLayout.paymentReceipt => _PaymentReceiptPreview(spec: spec),
      _RichWorkflowLayout.rosterProfile => _RosterProfilePreview(spec: spec),
      _RichWorkflowLayout.requestReview => _RequestReviewPreview(spec: spec),
      _RichWorkflowLayout.searchAnswer => _SearchAnswerPreview(spec: spec),
      _RichWorkflowLayout.exportWizard => _ExportWizardPreview(spec: spec),
      _RichWorkflowLayout.messageThread => _MessageThreadPreview(spec: spec),
      _RichWorkflowLayout.noticeDetail => _NoticeDetailPreview(spec: spec),
      _RichWorkflowLayout.clubScoreboard => _ClubScoreboardPreview(spec: spec),
      _RichWorkflowLayout.mediaReview => _MediaReviewPreview(spec: spec),
      _RichWorkflowLayout.adEntitlement => _AdEntitlementPreview(spec: spec),
      _ => _ProductDetailPreview(spec: spec),
    };
  }
}

class _ProductSurfaceStatusPanel extends StatelessWidget {
  const _ProductSurfaceStatusPanel({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _surfaceStatusTitleFor(spec.layout),
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              spec.actionPanelBody,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 10),
            _SurfaceFactPill(
              icon: Icons.compare_arrows_outlined,
              label: spec.alternateActionLabel,
              foreground: foreground,
            ),
          ],
        ),
      ),
    );
  }
}

String _surfaceStatusTitleFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => 'Response choices',
    _RichWorkflowLayout.formSubmission => 'Submission handoff',
    _RichWorkflowLayout.paymentReceipt => 'Receipt and next steps',
    _RichWorkflowLayout.rosterProfile => 'Roster visibility',
    _RichWorkflowLayout.requestReview => 'Request queue',
    _RichWorkflowLayout.searchAnswer => 'Reading guide',
    _RichWorkflowLayout.exportWizard => 'Package progress',
    _RichWorkflowLayout.messageThread => 'Conversation actions',
    _RichWorkflowLayout.noticeDetail => 'Delivery details',
    _RichWorkflowLayout.clubScoreboard => 'Club board',
    _RichWorkflowLayout.mediaReview => 'Critique details',
    _RichWorkflowLayout.adEntitlement => 'Ad-free controls',
    _ => 'Next step',
  };
}

class _EventDetailPreview extends StatelessWidget {
  const _EventDetailPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final rows = spec.detailRows.isEmpty ? spec.stateRows : spec.detailRows;
    return _ProductPreviewCard(
      spec: spec,
      title: 'Event details',
      children: [
        for (final row in rows.take(4))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in spec.facts.take(3))
              _SurfaceFactPill(
                icon: fact.icon,
                label: fact.label,
                foreground: _foregroundFor(spec.accent),
              ),
          ],
        ),
      ],
    );
  }
}

class _FormSubmissionPreview extends StatelessWidget {
  const _FormSubmissionPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Submitted details',
      children: [
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(2))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _PaymentReceiptPreview extends StatelessWidget {
  const _PaymentReceiptPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    return _ProductPreviewCard(
      spec: spec,
      title: 'Payment summary',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in spec.facts.take(4))
              _SurfaceFactPill(
                icon: fact.icon,
                label: fact.label,
                foreground: foreground,
              ),
          ],
        ),
        for (final row in [
          ...spec.detailRows.take(2),
          ...spec.stateRows.take(2),
        ])
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _RosterProfilePreview extends StatelessWidget {
  const _RosterProfilePreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Roster and visibility',
      children: [
        for (final row in spec.detailRows.take(4))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _RequestReviewPreview extends StatelessWidget {
  const _RequestReviewPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final rows = [...spec.detailRows.take(3), ...spec.stateRows.take(2)];
    return _ProductPreviewCard(
      spec: spec,
      title: 'Decision queue',
      children: [
        for (var index = 0; index < rows.length; index++)
          _WizardStepLine(
            index: index + 1,
            icon: rows[index].icon,
            title: rows[index].title,
            body: rows[index].body,
          ),
      ],
    );
  }
}

class _SearchAnswerPreview extends StatelessWidget {
  const _SearchAnswerPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Answer with sources',
      children: [
        _ProductPreviewLine(
          icon: Icons.search_outlined,
          title: 'Query',
          body: spec.subtitle,
        ),
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ExportWizardPreview extends StatelessWidget {
  const _ExportWizardPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final rows = [...spec.detailRows.take(3), ...spec.stateRows.take(2)];
    return _ProductPreviewCard(
      spec: spec,
      title: 'Export steps',
      children: [
        for (var index = 0; index < rows.length; index++)
          _WizardStepLine(
            index: index + 1,
            icon: rows[index].icon,
            title: rows[index].title,
            body: rows[index].body,
          ),
      ],
    );
  }
}

class _MessageThreadPreview extends StatelessWidget {
  const _MessageThreadPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Conversation',
      children: [
        for (final row in spec.detailRows.take(3))
          _ChatBubbleLine(
            icon: row.icon,
            title: row.title,
            body: row.body,
            alignRight: row.title.toLowerCase().contains('body'),
          ),
        for (final row in spec.stateRows.take(1))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _NoticeDetailPreview extends StatelessWidget {
  const _NoticeDetailPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Notice preview',
      children: [
        for (final row in spec.detailRows.take(4))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(1))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ClubScoreboardPreview extends StatelessWidget {
  const _ClubScoreboardPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: 'Club board',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in spec.facts)
              _SurfaceFactPill(
                icon: fact.icon,
                label: fact.label,
                foreground: _foregroundFor(spec.accent),
              ),
          ],
        ),
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _MediaReviewPreview extends StatelessWidget {
  const _MediaReviewPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    return _ProductPreviewCard(
      spec: spec,
      title: 'Photo critique',
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: foreground.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      Icons.photo_camera_back_outlined,
                      color: foreground,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Golden hour bridge study',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member photo, critique prompt, consent, comment thread, edit/withdraw, and reviewer result are visible.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(2))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _AdEntitlementPreview extends StatelessWidget {
  const _AdEntitlementPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final title = spec.title.toLowerCase();
    final account =
        title.contains('ad-off') ||
        title.contains('ad-free') ||
        title.contains('settlement') ||
        title.contains('entitlement') ||
        title.contains('receipt');
    final sponsored =
        !account &&
        !title.contains('no-fill') &&
        !title.contains('guard') &&
        !title.contains('suppression');
    return _ProductPreviewCard(
      spec: spec,
      title: sponsored
          ? 'In-stream placement'
          : account
          ? 'Ad-free account'
          : 'Ad slot state',
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: foreground.withValues(alpha: 0.24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sponsored
                          ? Icons.campaign_outlined
                          : Icons.web_asset_off_outlined,
                      color: foreground,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sponsored
                            ? 'Sponsored by Neighborhood Newsletter'
                            : account
                            ? 'Ad-free status active'
                            : 'No sponsored message right now',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sponsored
                      ? 'Disclosure, sponsor creative, impression state, dismiss, report, and manage-ad controls sit inside the stream.'
                      : account
                      ? 'Entitlement, receipt, renewal, restore action, and affected ad slots stay together without payment-screen context.'
                      : 'Reserved slot, no-fill reason, privacy-safe suppression, and manage-ad controls preserve layout without covering content.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final row in spec.detailRows.take(2))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
        for (final row in spec.stateRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ProductDetailPreview extends StatelessWidget {
  const _ProductDetailPreview({required this.spec});

  final _RichWorkflowSpec spec;

  @override
  Widget build(BuildContext context) {
    return _ProductPreviewCard(
      spec: spec,
      title: spec.detailTitle,
      children: [
        for (final row in spec.detailRows.take(3))
          _ProductPreviewLine(icon: row.icon, title: row.title, body: row.body),
      ],
    );
  }
}

class _ProductPreviewCard extends StatelessWidget {
  const _ProductPreviewCard({
    required this.spec,
    required this.title,
    required this.children,
  });

  final _RichWorkflowSpec spec;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPreviewLine extends StatelessWidget {
  const _ProductPreviewLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color ?? Colors.white;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: foreground.withValues(alpha: 0.92)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardStepLine extends StatelessWidget {
  const _WizardStepLine({
    required this.index,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color ?? Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: foreground.withValues(alpha: 0.18),
            child: Text(
              '$index',
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProductPreviewLine(icon: icon, title: title, body: body),
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleLine extends StatelessWidget {
  const _ChatBubbleLine({
    required this.icon,
    required this.title,
    required this.body,
    required this.alignRight,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color ?? Colors.white;
    final textTheme = Theme.of(context).textTheme;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: alignRight ? 0.20 : 0.11),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: bubble,
        ),
      ),
    );
  }
}

class _GardenEventRsvpTile extends StatelessWidget {
  const _GardenEventRsvpTile({
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff2f6f9f);
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: foreground.withValues(alpha: 0.13),
                  child: Icon(
                    Icons.event_available_outlined,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spring Planting Workshop',
                        style: textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Hands-on bed prep, seedling swap, and seasonal planning with Garden Club members.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GardenFactPill(
                  icon: Icons.calendar_today_outlined,
                  label: 'Sat, Apr 18',
                ),
                _GardenFactPill(
                  icon: Icons.schedule_outlined,
                  label: '10:00 AM',
                ),
                _GardenFactPill(
                  icon: Icons.place_outlined,
                  label: 'Riverside Greenhouse',
                ),
                _GardenFactPill(
                  icon: Icons.group_outlined,
                  label: '18 of 24 spots',
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: foreground.withValues(alpha: 0.20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Your RSVP: Going' : 'Your RSVP',
                      style: textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? 'A reminder is set for Saturday morning. You can still change your response before capacity closes.'
                          : 'Choose Going, Maybe, or Not going after checking the schedule, location, host, and capacity.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: 'RSVP confirmed',
                body:
                    'You are going to Spring Planting Workshop. Calendar, attendee count, and reminder status stay visible.',
                icon: Icons.event_available_outlined,
                accent: accent,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: 'Event update ready',
                body:
                    'The event page shows your attendance choice, capacity, and any schedule changes.',
                icon: Icons.inbox_outlined,
                accent: accent,
              )
            else
              _WorkflowAction(
                contract: productionWorkflowContractFor(
                  extensionId: 'ext_garden_club',
                  workflow: workflow,
                ),
                workflow: workflow,
                view: view,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            if (complete)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey(
                    view.completed
                        ? 'workflow-complete-${workflow.workflowId}'
                        : 'workflow-received-${workflow.workflowId}',
                  ),
                  icon: view.completed
                      ? Icons.done
                      : Icons.mark_email_read_outlined,
                  label: view.completed ? 'Going' : 'Received',
                  foreground: foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GardenPlantExchangeTile extends StatelessWidget {
  const _GardenPlantExchangeTile({
    required this.workflow,
    required this.view,
    required this.onPressed,
    required this.onReceivePressed,
  });

  final LoomWorkflowDefinition workflow;
  final LoomPersonaWorkflowView view;
  final VoidCallback onPressed;
  final VoidCallback onReceivePressed;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff3f7f4c);
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final complete = view.completed || view.received;
    return DecoratedBox(
      key: ValueKey('workflow-${workflow.workflowId}'),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: foreground.withValues(alpha: 0.13),
                  child: Icon(Icons.local_florist_outlined, color: foreground),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basil seedlings offer',
                        style: textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Offer six Sweet Genovese starter pots, choose pickup details, and control what contact info is shared.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.90),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: foreground.withValues(alpha: 0.20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _GardenFactPill(
                          icon: Icons.grass_outlined,
                          label: 'Sweet Genovese basil',
                        ),
                        _GardenFactPill(
                          icon: Icons.inventory_2_outlined,
                          label: '6 starter pots',
                        ),
                        _GardenFactPill(
                          icon: Icons.schedule_outlined,
                          label: 'Pickup Sat 1-3 PM',
                        ),
                        _GardenFactPill(
                          icon: Icons.verified_user_outlined,
                          label: 'Contact after claim',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      complete
                          ? 'Offer posted to the plant exchange board.'
                          : 'Members will see the plant variety, pickup window, privacy note, and how to claim the offer.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: foreground.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (view.completed)
              _WorkflowResultPanel(
                key: ValueKey('workflow-result-${workflow.workflowId}'),
                title: 'Offer posted',
                body:
                    'Basil seedlings are listed with pickup details and contact sharing limited until a member claims them.',
                icon: Icons.local_florist_outlined,
                accent: accent,
              )
            else if (view.received)
              _WorkflowResultPanel(
                key: ValueKey(
                  'workflow-received-result-${workflow.workflowId}',
                ),
                title: 'Plant offer ready',
                body:
                    'Members can confirm the variety, pickup details, and contact privacy before claiming.',
                icon: Icons.inbox_outlined,
                accent: accent,
              )
            else
              _WorkflowAction(
                contract: productionWorkflowContractFor(
                  extensionId: 'ext_garden_club',
                  workflow: workflow,
                ),
                workflow: workflow,
                view: view,
                onPressed: onPressed,
                onReceivePressed: onReceivePressed,
              ),
            if (complete)
              Align(
                alignment: Alignment.centerRight,
                child: _StateBadge(
                  key: ValueKey(
                    view.completed
                        ? 'workflow-complete-${workflow.workflowId}'
                        : 'workflow-received-${workflow.workflowId}',
                  ),
                  icon: view.completed
                      ? Icons.done
                      : Icons.mark_email_read_outlined,
                  label: view.completed ? 'Posted' : 'Received',
                  foreground: foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GardenFactPill extends StatelessWidget {
  const _GardenFactPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _SurfaceFactPill(icon: icon, label: label, foreground: Colors.white);
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

Color _actionScreenBackgroundFor(Color accent) {
  return _screenBackgroundFor(accent);
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
      return 'Top banner slot';
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
    return 'You can read the current details without changing them.';
  }
  if (view.state == LoomPersonaWorkflowState.receiver) {
    switch (category) {
      case 'Event':
        return 'An event update is ready with your attendance choice.';
      case 'Payment':
        return 'A receipt or giving preference is ready to open.';
      case 'Publishing':
        return 'A community update is ready in your inbox.';
      case 'Approval':
        return 'A decision update is ready with next steps.';
      case 'Portability':
        return 'A data package update is ready to inspect.';
      case 'Platform':
        return 'A member communication or preference update is ready.';
      case 'Form':
        return 'A submitted member form is ready for action and follow-up.';
    }
    return 'A community update is ready to open.';
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
    return 'Ad slot disclosure shows a no-fill result with no sponsored message overlapping content.';
  }
  if (id.contains('message') || id.contains('connection')) {
    return 'Member communication stays scoped to the community relationship.';
  }
  if (id.contains('ad')) {
    return 'Ad preference and sponsored-message behavior are ready to open.';
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
      return const ['Labeled fields', 'Privacy checked', 'Handoff ready'];
  }
  return const ['Labeled fields', 'Privacy checked', 'Handoff ready'];
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
      return 'Your attendance choice and event details are saved.';
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
            label: Text(
              contract.primaryActionLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
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
            label: Text(
              view.actionText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
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
    if (workflow.workflowId == 'garden-event-rsvp') {
      return _GardenEventRsvpActionSurface(
        workflow: workflow,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    if (workflow.workflowId == 'plant-exchange-submission') {
      return _GardenPlantExchangeActionSurface(
        workflow: workflow,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    final richSpec = _richWorkflowSpecFor(workflow.workflowId);
    if (richSpec != null) {
      return _RichWorkflowActionSurface(
        workflow: workflow,
        contract: contract,
        spec: richSpec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = _categoryAccentColor(contract.category, scheme);
    final foreground = _foregroundFor(accent);
    final metadata = _domainMetadataFor(contract.category, workflow);
    final title = isReceiverSurface
        ? contract.receiverSurfaceTitle
        : contract.screenTitle;

    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(accent),
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
                title: 'Open',
                body: contract.decisionSummary,
              ),
              _ActionSurfaceDetail(
                icon: Icons.edit_note_outlined,
                title: 'Form details',
                body:
                    '${contract.inputSummary} ${_surfaceInputFor(contract.category, workflow)}',
              ),
              _ActionSurfaceDetail(
                icon: Icons.compare_arrows_outlined,
                title: 'Alternate option',
                body:
                    '${contract.alternateActionLabel} is available before this is saved.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.task_alt_outlined,
                title: 'Visible result',
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
          const SizedBox(height: 16),
          _InlineActionBar(
            accent: accent,
            alternateLabel: contract.alternateActionLabel,
            actionLabel: actionLabel,
            actionIcon: contract.icon,
            confirmButtonKey: confirmButtonKey,
          ),
        ],
      ),
    );
  }
}

class _RichWorkflowActionSurface extends StatelessWidget {
  const _RichWorkflowActionSurface({
    required this.workflow,
    required this.contract,
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final LoomProductionWorkflowContract contract;
  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final domainPreview = _domainPreviewPanelFor(
      workflow.workflowId,
      accent: spec.accent,
      foreground: foreground,
    );
    if (spec.layout != _RichWorkflowLayout.standard) {
      return _RichProductActionSurface(
        workflow: workflow,
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
        isReceiverSurface: isReceiverSurface,
      );
    }
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(spec.accent),
      appBar: AppBar(
        title: Text(
          isReceiverSurface ? spec.receivedTitle : spec.actionSurfaceTitle,
        ),
        backgroundColor: spec.accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _GardenHeroPanel(
            accent: spec.accent,
            icon: spec.icon,
            title: spec.title,
            subtitle: spec.actionHeroSubtitle,
            body: isReceiverSurface ? spec.receivedBody : spec.actionHeroBody,
          ),
          if (domainPreview != null) ...[
            const SizedBox(height: 14),
            domainPreview,
          ],
          const SizedBox(height: 14),
          _InteractionModelSummary(contract: contract, foreground: foreground),
          const SizedBox(height: 14),
          _RichInlineActionPanel(
            accent: spec.accent,
            facts: spec.facts,
            title: isReceiverSurface
                ? spec.receivedTitle
                : spec.actionPanelTitle,
            body: isReceiverSurface ? spec.receivedBody : spec.actionPanelBody,
            alternateLabel: spec.alternateActionLabel,
            actionLabel: actionLabel,
            actionIcon: spec.icon,
            confirmButtonKey: confirmButtonKey,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: spec.accent,
            title: spec.detailTitle,
            rows: spec.detailRows,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: spec.accent,
            title: spec.stateTitle,
            rows: spec.stateRows,
          ),
        ],
      ),
    );
  }
}

class _RichProductActionSurface extends StatelessWidget {
  const _RichProductActionSurface({
    required this.workflow,
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(spec.accent),
      appBar: AppBar(
        title: Text(
          isReceiverSurface ? spec.receivedTitle : spec.actionSurfaceTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        toolbarHeight: 88,
        backgroundColor: spec.accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: _actionSurfaceChildren(
          spec: spec,
          isReceiverSurface: isReceiverSurface,
          actionLabel: actionLabel,
          confirmButtonKey: confirmButtonKey,
        ),
      ),
    );
  }
}

List<Widget> _actionSurfaceChildren({
  required _RichWorkflowSpec spec,
  required bool isReceiverSurface,
  required String actionLabel,
  required Key confirmButtonKey,
}) {
  final actionBar = _InlineActionBar(
    accent: spec.accent,
    alternateLabel: spec.alternateActionLabel,
    actionLabel: actionLabel,
    actionIcon: spec.icon,
    confirmButtonKey: confirmButtonKey,
  );
  final hero = _GardenHeroPanel(
    accent: spec.accent,
    icon: spec.icon,
    title: spec.title,
    subtitle: spec.actionHeroSubtitle,
    body: isReceiverSurface ? spec.receivedBody : spec.actionHeroBody,
  );
  final details = _GardenDetailCard(
    accent: spec.accent,
    title: spec.detailTitle,
    rows: spec.detailRows,
  );
  final followUp = _GardenDetailCard(
    accent: spec.accent,
    title: _followUpTitleFor(spec.layout),
    rows: spec.stateRows,
  );
  final preview = _ProductSurfacePreview(spec: spec);
  return switch (spec.layout) {
    _RichWorkflowLayout.exportWizard => [
      _ExportWizardPreview(spec: spec),
      const SizedBox(height: 16),
      _ExportActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.adEntitlement => [
      _AdEntitlementPreview(spec: spec),
      const SizedBox(height: 16),
      _AdEntitlementActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.paymentReceipt => [
      _PaymentReceiptPreview(spec: spec),
      const SizedBox(height: 16),
      _PaymentActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.messageThread ||
    _RichWorkflowLayout.noticeDetail ||
    _RichWorkflowLayout.searchAnswer => [
      preview,
      const SizedBox(height: 16),
      _CommunicationActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
      const SizedBox(height: 16),
      details,
    ],
    _RichWorkflowLayout.eventDetail => [
      _EventDetailPreview(spec: spec),
      const SizedBox(height: 16),
      _EventActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.rosterProfile => [
      _RosterProfilePreview(spec: spec),
      const SizedBox(height: 16),
      _RosterActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
      const SizedBox(height: 16),
      details,
    ],
    _RichWorkflowLayout.clubScoreboard => [
      _ClubScoreboardPreview(spec: spec),
      const SizedBox(height: 16),
      _ClubActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _RichWorkflowLayout.formSubmission ||
    _RichWorkflowLayout.requestReview ||
    _RichWorkflowLayout.mediaReview => [
      preview,
      const SizedBox(height: 16),
      _FormActionConsole(
        spec: spec,
        actionLabel: actionLabel,
        confirmButtonKey: confirmButtonKey,
      ),
    ],
    _ => [
      hero,
      const SizedBox(height: 14),
      preview,
      const SizedBox(height: 16),
      actionBar,
      const SizedBox(height: 16),
      details,
      const SizedBox(height: 16),
      followUp,
    ],
  };
}

String _followUpTitleFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => 'After you respond',
    _RichWorkflowLayout.formSubmission => 'After submission',
    _RichWorkflowLayout.paymentReceipt => 'Receipt and account',
    _RichWorkflowLayout.rosterProfile => 'Role visibility',
    _RichWorkflowLayout.requestReview => 'Request outcome',
    _RichWorkflowLayout.searchAnswer => 'Saved answer',
    _RichWorkflowLayout.exportWizard => 'After export',
    _RichWorkflowLayout.messageThread => 'After message',
    _RichWorkflowLayout.noticeDetail => 'After delivery',
    _RichWorkflowLayout.clubScoreboard => 'Club record',
    _RichWorkflowLayout.mediaReview => 'After critique',
    _RichWorkflowLayout.adEntitlement => 'Ad-free account',
    _ => 'Next steps',
  };
}

String _resultTitleFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => 'Attendance saved',
    _RichWorkflowLayout.formSubmission => 'Submitted request',
    _RichWorkflowLayout.paymentReceipt => 'Receipt saved',
    _RichWorkflowLayout.rosterProfile => 'Visibility updated',
    _RichWorkflowLayout.requestReview => 'Request updated',
    _RichWorkflowLayout.searchAnswer => 'Answer saved',
    _RichWorkflowLayout.exportWizard => 'Export progress',
    _RichWorkflowLayout.messageThread => 'Thread updated',
    _RichWorkflowLayout.noticeDetail => 'Message delivered',
    _RichWorkflowLayout.clubScoreboard => 'Club result saved',
    _RichWorkflowLayout.mediaReview => 'Critique state',
    _RichWorkflowLayout.adEntitlement => 'Ad setting saved',
    _ => 'Result and next step',
  };
}

List<_ActionSurfaceDetail> _actionProofRowsFor(_RichWorkflowLayout layout) {
  return switch (layout) {
    _RichWorkflowLayout.eventDetail => const [
      _ActionSurfaceDetail(
        icon: Icons.event_outlined,
        title: 'Event details',
        body:
            'Title, date, time, location, host, capacity, and current attendance are visible before responding.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.how_to_reg_outlined,
        title: 'Attendance options',
        body:
            'Going, Maybe, Not going, and Change response remain available while the event is open.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.notifications_active_outlined,
        title: 'Member reminder',
        body:
            'The saved response keeps calendar, reminder, and capacity status visible.',
      ),
    ],
    _RichWorkflowLayout.paymentReceipt => const [
      _ActionSurfaceDetail(
        icon: Icons.payments_outlined,
        title: 'Payment context',
        body:
            'Amount, payer, recipient, method, visibility, and retry/refund path are visible before checkout.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.receipt_long_outlined,
        title: 'Receipt',
        body:
            'Receipt destination, payment status, entitlement, and history are kept after payment.',
      ),
    ],
    _RichWorkflowLayout.exportWizard => const [
      _ActionSurfaceDetail(
        icon: Icons.inventory_2_outlined,
        title: 'Export scope',
        body:
            'Selected records, redaction choices, destination, file size, and checksum are shown as export steps.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.verified_outlined,
        title: 'Verification and recovery',
        body:
            'Download, retry, cancel, rollback, and audit status stay visible after the export action.',
      ),
    ],
    _RichWorkflowLayout.messageThread ||
    _RichWorkflowLayout.noticeDetail => const [
      _ActionSurfaceDetail(
        icon: Icons.person_outline,
        title: 'Sender and receiver',
        body:
            'Sender, recipient or audience, timestamp, body, and delivery channel are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.forum_outlined,
        title: 'Conversation state',
        body:
            'Reply, read/unread, archive, mute, block, draft, or resend actions match the message state.',
      ),
    ],
    _RichWorkflowLayout.searchAnswer => const [
      _ActionSurfaceDetail(
        icon: Icons.search_outlined,
        title: 'Query and answer',
        body:
            'The user sees the query, answer, citations, source visibility, and follow-up options.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.bookmark_border_outlined,
        title: 'Saved citation state',
        body:
            'Save, share, refine, and stale-source handling are visible after opening the result.',
      ),
    ],
    _RichWorkflowLayout.adEntitlement => const [
      _ActionSurfaceDetail(
        icon: Icons.block_outlined,
        title: 'Ad-free account',
        body:
            'Entitlement scope, renewal or expiry, receipt link, restore/manage action, and affected ad slots are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Receipt or settlement',
        body:
            'Payment receipt, settlement ID, utility allocation, audit status, correction, and rollback path remain visible where applicable.',
      ),
    ],
    _RichWorkflowLayout.rosterProfile => const [
      _ActionSurfaceDetail(
        icon: Icons.groups_outlined,
        title: 'Roster records',
        body:
            'Member names, roles, counts, status, and protected fields are visible according to persona.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.privacy_tip_outlined,
        title: 'Protected visibility',
        body:
            'Hidden, redacted, filter, message, and export actions follow the role policy.',
      ),
    ],
    _RichWorkflowLayout.clubScoreboard => const [
      _ActionSurfaceDetail(
        icon: Icons.how_to_vote_outlined,
        title: 'Choice and standing',
        body:
            'Nominations, ballot options, selected title, match result, or standings are visible before saving.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.timeline_outlined,
        title: 'Open result',
        body:
            'Change vote, dispute score, view results, and next meeting or round stay available.',
      ),
    ],
    _RichWorkflowLayout.mediaReview => const [
      _ActionSurfaceDetail(
        icon: Icons.image_outlined,
        title: 'Submission artifact',
        body:
            'Image, caption, consent, prompt, reviewer, and comment status are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.rate_review_outlined,
        title: 'Critique path',
        body:
            'Edit, withdraw, request feedback, and reviewer result remain attached to the image.',
      ),
    ],
    _RichWorkflowLayout.formSubmission ||
    _RichWorkflowLayout.requestReview => const [
      _ActionSurfaceDetail(
        icon: Icons.edit_note_outlined,
        title: 'Submitted fields',
        body:
            'Labeled fields, privacy indicators, attachments, assignee, and status are visible.',
      ),
      _ActionSurfaceDetail(
        icon: Icons.rule_outlined,
        title: 'Review path',
        body:
            'Edit, withdraw, approve, reject, request changes, reopen, or appeal actions match the state.',
      ),
    ],
    _ => const [
      _ActionSurfaceDetail(
        icon: Icons.info_outline,
        title: 'Task context',
        body:
            'The screen shows the object, useful details, available actions, and saved result for this community task.',
      ),
    ],
  };
}

class _EventActionConsole extends StatelessWidget {
  const _EventActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Choose attendance',
      body:
          'Event date, capacity, location, host note, and reminders are visible before choosing Going, Maybe, or Not going.',
      primaryLabel: actionLabel,
      alternateLabels: const ['Maybe', 'Not going', 'Change later'],
      primaryIcon: Icons.event_available_outlined,
      leadingRows: spec.detailRows.take(3).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _FormActionConsole extends StatelessWidget {
  const _FormActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final labels = spec.layout == _RichWorkflowLayout.mediaReview
        ? const ['Edit submission', 'Withdraw', 'Request feedback']
        : const ['Edit details', 'Save draft', 'Cancel request'];
    return _DomainActionConsole(
      spec: spec,
      title: spec.layout == _RichWorkflowLayout.mediaReview
          ? 'Submission review'
          : 'Submitted request',
      body:
          'Labeled fields, privacy handling, assignee, and status are visible before submitting or editing.',
      primaryLabel: actionLabel,
      alternateLabels: labels,
      primaryIcon: spec.icon,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _PaymentActionConsole extends StatelessWidget {
  const _PaymentActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Checkout and receipt',
      body:
          'Payer, amount, privacy choice, entitlement, receipt destination, and retry/refund options are visible.',
      primaryLabel: actionLabel,
      alternateLabels: const ['Change amount', 'Use another method', 'Cancel'],
      primaryIcon: Icons.receipt_long_outlined,
      leadingRows: spec.detailRows.take(3).toList(),
      resultRows: spec.stateRows.take(4).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _AdEntitlementActionConsole extends StatelessWidget {
  const _AdEntitlementActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final text = '${spec.title} ${spec.subtitle}'.toLowerCase();
    final settlement = text.contains('settlement');
    final account =
        text.contains('ad-off') ||
        text.contains('ad-free') ||
        text.contains('entitlement') ||
        text.contains('receipt') ||
        settlement;
    return _DomainActionConsole(
      spec: spec,
      title: settlement
          ? 'Settlement and audit'
          : account
          ? 'Ad-free account controls'
          : 'Sponsored-message controls',
      body: settlement
          ? 'Review funded amount, settlement ID, utility impact, audit status, and correction or rollback path.'
          : account
          ? 'Review entitlement, renewal, receipt, restore/manage action, and affected ad slots.'
          : 'Review reserved slot behavior, disclosure, no-fill reason, entitlement, receipt, and restore option.',
      primaryLabel: actionLabel,
      alternateLabels: settlement
          ? const ['Correct allocation', 'Rollback', 'Export audit']
          : account
          ? const ['Manage subscription', 'Restore purchase', 'Open receipt']
          : const ['Manage entitlement', 'Report ad issue', 'Restore receipt'],
      primaryIcon: Icons.block_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(4).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _ExportActionConsole extends StatelessWidget {
  const _ExportActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final text = '${spec.title} ${spec.subtitle}'.toLowerCase();
    final alternates = text.contains('rollback')
        ? const ['Start rollback', 'Retry transfer', 'Keep current']
        : text.contains('checksum')
        ? const ['Verify checksum', 'Download receipt', 'Retry']
        : text.contains('schema')
        ? const ['Exclude schema', 'Open fields', 'Keep selected']
        : const ['Change scope', 'Preview redaction', 'Retry export'];
    return _DomainActionConsole(
      spec: spec,
      title: 'Export workspace',
      body:
          'Scope, redaction, checksum, destination, transfer status, rollback, and audit evidence are visible.',
      primaryLabel: actionLabel,
      alternateLabels: alternates,
      primaryIcon: Icons.folder_zip_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(4).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _CommunicationActionConsole extends StatelessWidget {
  const _CommunicationActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final notice = spec.layout == _RichWorkflowLayout.noticeDetail;
    final search = spec.layout == _RichWorkflowLayout.searchAnswer;
    return _DomainActionConsole(
      spec: spec,
      title: search
          ? 'Answer actions'
          : notice
          ? 'Delivery actions'
          : 'Thread actions',
      body: search
          ? 'Open cited sources, save the answer, refine the query, or share it with members.'
          : notice
          ? 'Review audience, sender, message body, timing, and receiver state before sending.'
          : 'Read sender, body, timestamp, and choose reply, mute, archive, or block.',
      primaryLabel: actionLabel,
      alternateLabels: search
          ? const ['Open sources', 'Refine query', 'Save for later']
          : notice
          ? const ['Preview', 'Save draft', 'Change audience']
          : const ['Reply', 'Mute', 'Archive'],
      primaryIcon: spec.icon,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _RosterActionConsole extends StatelessWidget {
  const _RosterActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Roster visibility',
      body:
          'Review member names, role-filtered details, protected fields, and who can see each item.',
      primaryLabel: actionLabel,
      alternateLabels: const [
        'Filter roster',
        'Hide protected fields',
        'Export list',
      ],
      primaryIcon: Icons.people_alt_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _ClubActionConsole extends StatelessWidget {
  const _ClubActionConsole({
    required this.spec,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    return _DomainActionConsole(
      spec: spec,
      title: 'Club record',
      body:
          'Review players, round, score, result, standings impact, and next club action.',
      primaryLabel: actionLabel,
      alternateLabels: const ['Edit score', 'Dispute result', 'Open standings'],
      primaryIcon: Icons.emoji_events_outlined,
      leadingRows: spec.detailRows.take(4).toList(),
      resultRows: spec.stateRows.take(3).toList(),
      confirmButtonKey: confirmButtonKey,
    );
  }
}

class _DomainActionConsole extends StatelessWidget {
  const _DomainActionConsole({
    required this.spec,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.alternateLabels,
    required this.primaryIcon,
    required this.leadingRows,
    required this.resultRows,
    required this.confirmButtonKey,
  });

  final _RichWorkflowSpec spec;
  final String title;
  final String body;
  final String primaryLabel;
  final List<String> alternateLabels;
  final IconData primaryIcon;
  final List<_ActionSurfaceDetail> leadingRows;
  final List<_ActionSurfaceDetail> resultRows;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(spec.accent);
    final textTheme = Theme.of(context).textTheme;
    final proofRows = _actionProofRowsFor(spec.layout);
    final outlined = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: foreground.withValues(alpha: 0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(
                  color: foreground.withValues(alpha: 0.88),
                ),
              ),
              const SizedBox(height: 12),
              for (final row in proofRows)
                _ProductPreviewLine(
                  icon: row.icon,
                  title: row.title,
                  body: row.body,
                ),
              const SizedBox(height: 4),
              for (final row in leadingRows)
                _ProductPreviewLine(
                  icon: row.icon,
                  title: row.title,
                  body: row.body,
                ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in alternateLabels.take(3))
                    OutlinedButton(
                      onPressed: () {},
                      style: outlined,
                      child: Text(label),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: confirmButtonKey,
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(primaryIcon, size: 18),
                  label: Text(primaryLabel, textAlign: TextAlign.center),
                ),
              ),
              if (resultRows.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  _resultTitleFor(spec.layout),
                  style: textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final row in resultRows)
                  _ProductPreviewLine(
                    icon: row.icon,
                    title: row.title,
                    body: row.body,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenEventRsvpActionSurface extends StatelessWidget {
  const _GardenEventRsvpActionSurface({
    required this.workflow,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff2f6f9f);
    final foreground = _foregroundFor(accent);
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(accent),
      appBar: AppBar(
        title: Text(isReceiverSurface ? 'Event update' : 'Spring Workshop'),
        backgroundColor: accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _GardenHeroPanel(
            accent: accent,
            icon: Icons.event_available_outlined,
            title: 'Spring Planting Workshop',
            subtitle: 'Saturday, Apr 18 at 10:00 AM - Riverside Greenhouse',
            body:
                'Join the club for bed prep, seedling setup, and a shared planning session before the spring exchange opens.',
          ),
          const SizedBox(height: 14),
          _GardenRsvpChoicePanel(
            accent: accent,
            actionLabel: actionLabel,
            confirmButtonKey: confirmButtonKey,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Event details',
            rows: const [
              _ActionSurfaceDetail(
                icon: Icons.person_outline,
                title: 'Host',
                body: 'Maya Chen, Garden Club coordinator',
              ),
              _ActionSurfaceDetail(
                icon: Icons.group_outlined,
                title: 'Capacity',
                body: '18 members going, 6 spots left, waitlist opens at 24.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.place_outlined,
                title: 'Location',
                body:
                    'Riverside Greenhouse, north entrance. Bring gloves and a labeled seed tray.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Your response',
            rows: [
              const _ActionSurfaceDetail(
                icon: Icons.check_circle_outline,
                title: 'Going',
                body:
                    'Reserve your spot and receive the morning reminder in your community inbox.',
              ),
              const _ActionSurfaceDetail(
                icon: Icons.help_outline,
                title: 'Maybe',
                body:
                    'Keep the event on your calendar without taking a capacity spot yet.',
              ),
              const _ActionSurfaceDetail(
                icon: Icons.swap_horiz_outlined,
                title: 'Change later',
                body:
                    'You can change response before Saturday; the attendee count updates for everyone.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GardenPlantExchangeActionSurface extends StatelessWidget {
  const _GardenPlantExchangeActionSurface({
    required this.workflow,
    required this.actionLabel,
    required this.confirmButtonKey,
    required this.isReceiverSurface,
  });

  final LoomWorkflowDefinition workflow;
  final String actionLabel;
  final Key confirmButtonKey;
  final bool isReceiverSurface;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xff3f7f4c);
    final foreground = _foregroundFor(accent);
    return Scaffold(
      backgroundColor: _actionScreenBackgroundFor(accent),
      appBar: AppBar(
        title: Text(isReceiverSurface ? 'Plant offer' : 'Offer a plant'),
        backgroundColor: accent,
        foregroundColor: foreground,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _GardenHeroPanel(
            accent: accent,
            icon: Icons.local_florist_outlined,
            title: 'Basil seedlings',
            subtitle: 'Sweet Genovese - 6 starter pots',
            body:
                'Share healthy starts with nearby members and choose exactly what contact details are visible after a claim.',
          ),
          const SizedBox(height: 14),
          _GardenInlineActionPanel(
            accent: accent,
            title: 'Marketplace listing',
            body:
                'Confirm the variety, pickup window, and privacy note before the offer appears on the plant exchange board.',
            alternateLabel: 'Edit offer',
            actionLabel: actionLabel,
            actionIcon: Icons.local_florist_outlined,
            confirmButtonKey: confirmButtonKey,
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Offer preview',
            rows: const [
              _ActionSurfaceDetail(
                icon: Icons.grass_outlined,
                title: 'Plant details',
                body:
                    'Sweet Genovese basil, six starter pots, rooted and ready for transplant this week.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.schedule_outlined,
                title: 'Pickup',
                body:
                    'Saturday 1-3 PM at the community shed, with porch pickup available if weather changes.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.person_outline,
                title: 'Shared with claimants',
                body:
                    'First name and in-app contact only. Phone and address stay private until you confirm.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GardenDetailCard(
            accent: accent,
            title: 'Member marketplace state',
            rows: const [
              _ActionSurfaceDetail(
                icon: Icons.storefront_outlined,
                title: 'Board placement',
                body:
                    'Appears under Available plants with variety, quantity, pickup window, and claim status.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.edit_note_outlined,
                title: 'Edit or cancel',
                body:
                    'You can edit quantity, pickup time, or cancel if all seedlings are claimed elsewhere.',
              ),
              _ActionSurfaceDetail(
                icon: Icons.verified_user_outlined,
                title: 'Privacy',
                body:
                    'Claim requests are routed through Loom so contact details remain protected.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GardenRsvpChoicePanel extends StatelessWidget {
  const _GardenRsvpChoicePanel({
    required this.accent,
    required this.actionLabel,
    required this.confirmButtonKey,
  });

  final Color accent;
  final String actionLabel;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: foreground.withValues(alpha: 0.30)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your response',
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your RSVP updates the attendee count and leaves a reminder in your community inbox.',
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GardenFactPill(icon: Icons.group_outlined, label: '18 going'),
                _GardenFactPill(
                  icon: Icons.event_seat_outlined,
                  label: '6 spots left',
                ),
                _GardenFactPill(
                  icon: Icons.lock_open_outlined,
                  label: 'RSVP open',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Going'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: buttonStyle,
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Maybe'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: buttonStyle,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Not going'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Maybe later'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: confirmButtonKey,
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.event_available_outlined, size: 18),
                    label: Text(actionLabel, textAlign: TextAlign.center),
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

class _GardenInlineActionPanel extends StatelessWidget {
  const _GardenInlineActionPanel({
    required this.accent,
    required this.title,
    required this.body,
    required this.alternateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.confirmButtonKey,
  });

  final Color accent;
  final String title;
  final String body;
  final String alternateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GardenFactPill(
                  icon: Icons.verified_user_outlined,
                  label: 'Contact after claim',
                ),
                _GardenFactPill(
                  icon: Icons.lock_outline,
                  label: 'Phone/address private',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: confirmButtonKey,
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(actionIcon, size: 18),
                  label: Text(
                    actionLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: foreground,
                    side: BorderSide(color: foreground.withValues(alpha: 0.28)),
                  ),
                  icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                  label: Text(
                    alternateLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _RichInlineActionPanel extends StatelessWidget {
  const _RichInlineActionPanel({
    required this.accent,
    required this.facts,
    required this.title,
    required this.body,
    required this.alternateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.confirmButtonKey,
  });

  final Color accent;
  final List<_RichFact> facts;
  final String title;
  final String body;
  final String alternateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fact in facts)
                  _SurfaceFactPill(
                    icon: fact.icon,
                    label: fact.label,
                    foreground: foreground,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final primary = FilledButton.icon(
                  key: confirmButtonKey,
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: compact
                      ? const SizedBox.shrink()
                      : Icon(actionIcon, size: 18),
                  label: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                );
                final secondary = TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    alternateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primary,
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: secondary),
                    ],
                  );
                }
                return Row(
                  children: [
                    secondary,
                    const SizedBox(width: 12),
                    Expanded(child: primary),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineActionBar extends StatelessWidget {
  const _InlineActionBar({
    required this.accent,
    required this.alternateLabel,
    required this.actionLabel,
    required this.actionIcon,
    required this.confirmButtonKey,
  });

  final Color accent;
  final String alternateLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Key confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(alternateLabel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: confirmButtonKey,
                onPressed: () => Navigator.of(context).pop(true),
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenHeroPanel extends StatelessWidget {
  const _GardenHeroPanel({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  @override
  Widget build(BuildContext context) {
    final foreground = _foregroundFor(accent);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(14),
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
            CircleAvatar(
              radius: 26,
              backgroundColor: foreground.withValues(alpha: 0.14),
              child: Icon(icon, color: foreground, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.titleMedium?.copyWith(
                color: foreground.withValues(alpha: 0.92),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: textTheme.bodyLarge?.copyWith(
                color: foreground.withValues(alpha: 0.90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenDetailCard extends StatelessWidget {
  const _GardenDetailCard({
    required this.accent,
    required this.title,
    required this.rows,
  });

  final Color accent;
  final String title;
  final List<_ActionSurfaceDetail> rows;

  @override
  Widget build(BuildContext context) {
    final surface = Color.alphaBlend(
      accent.withValues(alpha: 0.84),
      Colors.black,
    );
    final foreground = _foregroundFor(surface);
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _ActionSurfaceDetailStack(accent: accent, rows: rows),
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
                  '$personaCount roles',
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
    required this.cardSurfaceFamily,
    required this.apiContract,
    required this.requiredInteractions,
    required this.primaryActions,
    required this.alternateActions,
    required this.rendererTarget,
    required this.fakeBackendSupport,
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
  final String cardSurfaceFamily;
  final String apiContract;
  final List<String> requiredInteractions;
  final List<String> primaryActions;
  final List<String> alternateActions;
  final String rendererTarget;
  final String fakeBackendSupport;
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

class LoomWorkflowCardSurfaceRegistryEntry {
  const LoomWorkflowCardSurfaceRegistryEntry({
    required this.workflowId,
    required this.cardSurfaceFamily,
    required this.apiContract,
    required this.requiredInteractions,
    required this.primaryActions,
    required this.alternateActions,
    required this.rendererTarget,
    required this.fakeBackendSupport,
    this.routeTemplate = '/workflows/:workflowId',
  });

  final String workflowId;
  final String cardSurfaceFamily;
  final String apiContract;
  final List<String> requiredInteractions;
  final List<String> primaryActions;
  final List<String> alternateActions;
  final String rendererTarget;
  final String fakeBackendSupport;
  final String routeTemplate;
}

class LoomTabRendererContract {
  const LoomTabRendererContract({
    required this.rendererId,
    required this.label,
    required this.tabIds,
    required this.surfaceFamilies,
    required this.requiredAnatomy,
    required this.requiredInteractions,
    required this.requiredStates,
    required this.evidenceRequirements,
    required this.fallbackPolicy,
  });

  final String rendererId;
  final String label;
  final List<String> tabIds;
  final List<String> surfaceFamilies;
  final List<String> requiredAnatomy;
  final List<String> requiredInteractions;
  final List<String> requiredStates;
  final List<String> evidenceRequirements;
  final String fallbackPolicy;

  bool supportsSurfaceFamily(String family) {
    return surfaceFamilies.contains(family);
  }
}

class LoomAppShellTabSpec {
  const LoomAppShellTabSpec({
    required this.tabId,
    required this.label,
    required this.icon,
    required this.description,
    this.rendererContractId = 'home-surface-stack',
    this.pinningPolicy = 'none',
    this.pinningPolicyRationale =
        'No pinned surface is needed for this tab; users should scan the tab content in order.',
    this.sectionTitles = const [],
    this.cardSurfaceFamilies = const [],
    this.pinnedWorkflowIds = const [],
    this.visiblePersonaIds = const [],
    this.requiredPermission = 'community.surface.navigation.read',
  });

  final String tabId;
  final String label;
  final IconData icon;
  final String description;
  final String rendererContractId;
  final String pinningPolicy;
  final String pinningPolicyRationale;
  final List<String> sectionTitles;
  final List<String> cardSurfaceFamilies;
  final List<String> pinnedWorkflowIds;
  final List<String> visiblePersonaIds;
  final String requiredPermission;

  bool isVisibleFor(String personaId) {
    return visiblePersonaIds.isEmpty || visiblePersonaIds.contains(personaId);
  }

  bool matchesWorkflow({
    required String extensionId,
    required LoomWorkflowDefinition workflow,
  }) {
    if (tabId == 'home') {
      return true;
    }
    if (tabId == 'messages') {
      return false;
    }
    if (pinnedWorkflowIds.contains(workflow.workflowId)) {
      return true;
    }
    final sectionTitle = _sectionTitleFor(workflow);
    if (sectionTitles.contains(sectionTitle)) {
      return true;
    }
    final registry = cardSurfaceRegistryEntryFor(
      extensionId: extensionId,
      workflow: workflow,
    );
    return cardSurfaceFamilies.contains(registry.cardSurfaceFamily);
  }

  String descriptionFor(LoomPersonaDefinition persona) {
    if (visiblePersonaIds.isEmpty) {
      return description;
    }
    return '$description Tuned for ${persona.label}.';
  }

  bool get declaresPinnedSurfaces => pinnedWorkflowIds.isNotEmpty;

  bool get hasExplicitPinningPolicy =>
      pinningPolicy.trim().isNotEmpty &&
      pinningPolicyRationale.trim().length >= 12;

  LoomTabRendererContract get rendererContract =>
      tabRendererContractFor(rendererContractId);
}

class LoomDeclarativeTabSpec {
  const LoomDeclarativeTabSpec({
    required this.tabId,
    required this.label,
    required this.iconKey,
    required this.description,
    required this.rendererContractId,
    this.pinningPolicy = 'none',
    this.pinningPolicyRationale =
        'This tab uses ordered content rather than a pinned surface.',
    this.sectionTitles = const [],
    this.cardSurfaceFamilies = const [],
    this.pinnedWorkflowIds = const [],
    this.visiblePersonaIds = const [],
    this.requiredPermission = 'community.surface.navigation.read',
  });

  final String tabId;
  final String label;
  final String iconKey;
  final String description;
  final String rendererContractId;
  final String pinningPolicy;
  final String pinningPolicyRationale;
  final List<String> sectionTitles;
  final List<String> cardSurfaceFamilies;
  final List<String> pinnedWorkflowIds;
  final List<String> visiblePersonaIds;
  final String requiredPermission;

  LoomAppShellTabSpec toTabSpec() {
    return LoomAppShellTabSpec(
      tabId: tabId,
      label: label,
      icon: _tabIconForKey(iconKey),
      description: description,
      rendererContractId: rendererContractId,
      pinningPolicy: pinningPolicy,
      pinningPolicyRationale: pinningPolicyRationale,
      sectionTitles: sectionTitles,
      cardSurfaceFamilies: cardSurfaceFamilies,
      pinnedWorkflowIds: pinnedWorkflowIds,
      visiblePersonaIds: visiblePersonaIds,
      requiredPermission: requiredPermission,
    );
  }
}

class CommunityAppShellCustomizationSpec {
  const CommunityAppShellCustomizationSpec({
    required this.experience,
    required this.persona,
    required this.tabs,
    required this.selectedTab,
    required this.visibleWorkflowIds,
    required this.focusKey,
    required this.focusedWorkflowId,
    required this.presentationStatesByWorkflowId,
    required this.theme,
  });

  factory CommunityAppShellCustomizationSpec.fromSelection({
    required LoomExperienceDefinition experience,
    required LoomPersonaDefinition persona,
    required List<LoomAppShellTabSpec> tabs,
    required LoomAppShellTabSpec selectedTab,
    required List<String> visibleWorkflowIds,
    required String? focusedWorkflowId,
    required String? expandedWorkflowId,
  }) {
    final states = <String, String>{};
    for (final workflowId in visibleWorkflowIds) {
      states[workflowId] = expandedWorkflowId == workflowId
          ? 'expanded'
          : focusedWorkflowId == workflowId
          ? 'medium'
          : 'minimized';
    }
    final accent = Color(experience.accentColor);
    return CommunityAppShellCustomizationSpec(
      experience: experience,
      persona: persona,
      tabs: List.unmodifiable(tabs),
      selectedTab: selectedTab,
      visibleWorkflowIds: List.unmodifiable(visibleWorkflowIds),
      focusKey: '${persona.personaId}:${selectedTab.tabId}',
      focusedWorkflowId: focusedWorkflowId,
      presentationStatesByWorkflowId: Map.unmodifiable(states),
      theme: LoomThemeCustomizationTokens(
        accent: accent,
        background: _screenBackgroundFor(accent),
        foreground: _foregroundFor(accent),
        density: 'comfortable-mobile',
        communityTitleScale: 1.06,
        surfaceTitleScale: 1.04,
        bodyScale: 1.0,
        metadataScale: 0.94,
        cardRadius: 16,
        surfaceSpacing: 16,
        elevation: 3,
        imageTreatment: 'community-icon-badge',
        buttonShape: 'rounded-pill',
        tabHeight: 76,
      ),
    );
  }

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final List<LoomAppShellTabSpec> tabs;
  final LoomAppShellTabSpec selectedTab;
  final List<String> visibleWorkflowIds;
  final String focusKey;
  final String? focusedWorkflowId;
  final Map<String, String> presentationStatesByWorkflowId;
  final LoomThemeCustomizationTokens theme;

  Map<String, LoomTabRendererContract> get rendererContractsByTabId {
    return Map.unmodifiable({
      for (final tab in tabs) tab.tabId: tab.rendererContract,
    });
  }
}

class LoomThemeCustomizationTokens {
  const LoomThemeCustomizationTokens({
    required this.accent,
    required this.background,
    required this.foreground,
    required this.density,
    this.communityTitleScale = 1.0,
    this.surfaceTitleScale = 1.0,
    this.bodyScale = 1.0,
    this.metadataScale = 1.0,
    this.cardRadius = 16,
    this.surfaceSpacing = 16,
    this.elevation = 2,
    this.imageTreatment = 'icon-badge',
    this.buttonShape = 'pill',
    this.tabHeight = 76,
  });

  final Color accent;
  final Color background;
  final Color foreground;
  final String density;
  final double communityTitleScale;
  final double surfaceTitleScale;
  final double bodyScale;
  final double metadataScale;
  final double cardRadius;
  final double surfaceSpacing;
  final double elevation;
  final String imageTreatment;
  final String buttonShape;
  final double tabHeight;
}

const _tabRendererContractsById = <String, LoomTabRendererContract>{
  'home-surface-stack': LoomTabRendererContract(
    rendererId: 'HomeTabSurfaceStack',
    label: 'Home surface stack',
    tabIds: ['home'],
    surfaceFamilies: [
      'community-home',
      'announcement',
      'event-rsvp',
      'calendar',
      'volunteer',
      'care-request',
      'approval',
      'workflow-status',
      'payment',
      'exchange',
      'equipment-loan',
      'documents',
      'external-document-link',
      'operations',
      'thread',
      'social',
      'form',
    ],
    requiredAnatomy: [
      'community identity header',
      'pinned or in-focus surface region',
      'minimized surface stack',
      'medium in-focus surface',
      'tap-to-expanded detail state',
    ],
    requiredInteractions: [
      'resolveCommunityTheme',
      'resolvePersonaTabs',
      'getPersonaSurfacePresentationState',
      'updatePersonaSurfacePresentationState',
      'previewNavigationConfiguration',
    ],
    requiredStates: ['minimized', 'medium', 'expanded', 'pinned or no-pin'],
    evidenceRequirements: [
      'community list minimized/medium card screenshots',
      'in-community minimized, medium, and expanded surface screenshots',
      'theme token proof',
      'explicit pinning policy proof',
    ],
    fallbackPolicy:
        'May host unassigned surfaces, but primary workflows should move to a tab-native renderer when a dedicated tab exists.',
  ),
  'calendar-agenda-event-detail': LoomTabRendererContract(
    rendererId: 'CalendarTabSurface',
    label: 'Calendar month/week/agenda and event detail',
    tabIds: ['calendar'],
    surfaceFamilies: ['calendar', 'event-rsvp', 'member-meetup'],
    requiredAnatomy: [
      'month or week/date strip',
      'agenda list grouped by date',
      'event detail with title, time, location, capacity, host, and reminders',
      'RSVP or meetup action state',
    ],
    requiredInteractions: [
      'listCalendarItems',
      'getCalendarItem',
      'openLinkedSurface',
      'respondGoingMaybeNo',
      'changeRsvp',
      'cancelRsvp',
      'joinWaitlist',
      'setReminder',
    ],
    requiredStates: [
      'empty schedule',
      'upcoming item',
      'selected detail',
      'responded',
      'waitlisted or full',
      'cancelled or rescheduled',
    ],
    evidenceRequirements: [
      'calendar tab screenshot',
      'selected event detail screenshot',
      'RSVP/change response screenshot',
      'receiver or reminder state screenshot',
    ],
    fallbackPolicy:
        'Event workflows may appear on Home as summaries, but Calendar owns dated browsing and event detail rendering.',
  ),
  'messages-inbox-thread-composer': LoomTabRendererContract(
    rendererId: 'MessagesTabSurface',
    label: 'Messages inbox, thread, composer, unread, and invites',
    tabIds: ['messages'],
    surfaceFamilies: ['thread', 'social', 'inbox'],
    requiredAnatomy: [
      'conversation or inbox list',
      'unread badges',
      'thread detail',
      'message composer',
      'connection invite/accept/decline state',
    ],
    requiredInteractions: [
      'createThread',
      'reply',
      'markRead',
      'listUnread',
      'muteThread',
      'archiveThread',
      'sendInvite',
      'acceptInvite',
      'declineInvite',
      'connectionStatus',
    ],
    requiredStates: [
      'empty inbox',
      'unread',
      'thread open',
      'sending',
      'sent/read',
      'muted/archived',
      'invite pending',
    ],
    evidenceRequirements: [
      'messages tab inbox screenshot',
      'thread detail screenshot',
      'composer/action screenshot',
      'connection invite or state screenshot',
    ],
    fallbackPolicy:
        'Messages must not render as a generic workflow list; it needs a chat/thread information architecture.',
  ),
  'marketplace-browse-listing-detail': LoomTabRendererContract(
    rendererId: 'MarketplaceTabSurface',
    label: 'Marketplace browse, search, listing, detail, custody, and queue',
    tabIds: ['marketplace'],
    surfaceFamilies: ['equipment-loan', 'exchange'],
    requiredAnatomy: [
      'browse/search/filter header',
      'listing grid or list',
      'listing detail with owner, availability, custody, queue, condition, and pickup',
      'list your item action',
      'loan/giveaway action state',
    ],
    requiredInteractions: [
      'browseEquipment',
      'searchEquipment',
      'listEquipmentListing',
      'updateEquipmentListing',
      'removeEquipmentListing',
      'requestLoan',
      'joinLoanQueue',
      'getCurrentHolder',
      'listCustodyHistory',
      'returnItem',
      'claimGiveaway',
      'transferGiveawayOwnership',
    ],
    requiredStates: [
      'available',
      'reserved',
      'checked out/current holder',
      'queued',
      'returned',
      'giveaway claimed',
      'delisted',
    ],
    evidenceRequirements: [
      'marketplace browse screenshot',
      'listing detail screenshot',
      'loan/giveaway action screenshot',
      'current holder or queue screenshot',
    ],
    fallbackPolicy:
        'Marketplace surfaces require browse and listing affordances; a single workflow card is not sufficient.',
  ),
  'documents-library-detail': LoomTabRendererContract(
    rendererId: 'DocumentsTabSurface',
    label: 'Documents library, detail, embedded, and external open',
    tabIds: ['documents'],
    surfaceFamilies: [
      'documents',
      'external-document-link',
      'operations',
      'portability',
      'workflow-status',
    ],
    requiredAnatomy: [
      'document library categories',
      'document detail with metadata and permissions',
      'embedded open affordance',
      'external app/link open affordance',
      'version/access/acknowledgement state',
    ],
    requiredInteractions: [
      'listDocuments',
      'getDocumentDetail',
      'openEmbeddedDocument',
      'openExternalDocument',
      'downloadDocument',
      'acknowledgeDocument',
      'requestDocumentAccess',
      'listDocumentVersions',
      'documentAuditTrail',
    ],
    requiredStates: [
      'available',
      'restricted',
      'access requested',
      'opened embedded',
      'opened external',
      'acknowledged',
      'retired/versioned',
    ],
    evidenceRequirements: [
      'documents tab library screenshot',
      'document detail screenshot',
      'embedded open screenshot or handoff proof',
      'external open screenshot or handoff proof',
    ],
    fallbackPolicy:
        'Document and portability workflows may summarize on Home, but Documents owns library/detail/open rendering.',
  ),
  'workflow-status-timeline-actions': LoomTabRendererContract(
    rendererId: 'WorkflowStatusSurface',
    label: 'Workflow status timeline and actions',
    tabIds: ['home', 'admin', 'documents'],
    surfaceFamilies: ['workflow-status', 'approval', 'form', 'operations'],
    requiredAnatomy: [
      'status timeline',
      'current step and owner',
      'submitted details',
      'comments/documents/payment needed',
      'next actions and alternate/reopen paths',
    ],
    requiredInteractions: [
      'createWorkflowInstance',
      'getWorkflowStatus',
      'listWorkflowSteps',
      'transitionWorkflowStep',
      'requestWorkflowChanges',
      'approveWorkflowStep',
      'rejectWorkflowStep',
      'addWorkflowComment',
      'attachWorkflowDocument',
      'reopenWorkflow',
    ],
    requiredStates: [
      'submitted',
      'under review',
      'feedback needed',
      'payment needed',
      'approved/rejected',
      'reopened',
      'cancelled',
    ],
    evidenceRequirements: [
      'timeline screenshot',
      'current step screenshot',
      'action/result screenshot',
      'receiver/notification state screenshot',
    ],
    fallbackPolicy:
        'Use this renderer for arbitrary multi-step requests instead of fixed approval cards when the workflow has variable steps.',
  ),
  'payment-giving-ledger': LoomTabRendererContract(
    rendererId: 'PaymentGivingTabSurface',
    label: 'Giving, payment, receipt, and entitlement ledger',
    tabIds: ['giving'],
    surfaceFamilies: ['payment', 'ad-off-entitlement', 'ad-off-settlement'],
    requiredAnatomy: [
      'amount and purpose summary',
      'checkout or payment intent',
      'receipt and audit state',
      'subscription/entitlement management',
    ],
    requiredInteractions: [
      'createPaymentIntent',
      'confirmPayment',
      'retryPayment',
      'refund',
      'manageRecurringPlan',
      'getReceipt',
      'getEntitlement',
      'settlementStatus',
    ],
    requiredStates: [
      'due',
      'checkout',
      'paid',
      'failed/retry',
      'refunded',
      'recurring',
      'entitled',
    ],
    evidenceRequirements: [
      'giving tab screenshot',
      'payment detail screenshot',
      'receipt/entitlement screenshot',
    ],
    fallbackPolicy:
        'Payment summaries may appear elsewhere, but Giving owns checkout, receipt, and entitlement depth.',
  ),
  'care-volunteer-request-queue': LoomTabRendererContract(
    rendererId: 'CareVolunteerTabSurface',
    label: 'Care requests, volunteer shifts, roster, and privacy',
    tabIds: ['care'],
    surfaceFamilies: ['care-request', 'volunteer'],
    requiredAnatomy: [
      'request or shift queue',
      'protected/public data split',
      'roster or volunteer count',
      'assignment/check-in state',
      'neutral notification state',
    ],
    requiredInteractions: [
      'createRequest',
      'assignCareTeam',
      'reviewRequest',
      'resolveRequest',
      'listShifts',
      'signup',
      'listVolunteers',
      'protectedContactReveal',
      'checkIn',
    ],
    requiredStates: [
      'open request',
      'assigned',
      'resolved',
      'shift open',
      'signed up',
      'checked in',
      'protected',
    ],
    evidenceRequirements: [
      'care tab queue screenshot',
      'request/detail screenshot',
      'volunteer roster/count screenshot',
      'protected contact handling screenshot',
    ],
    fallbackPolicy:
        'Care and volunteer tasks need privacy-aware queues/details, not generic action cards.',
  ),
  'admin-review-compose-queue': LoomTabRendererContract(
    rendererId: 'AdminReviewComposeTabSurface',
    label: 'Admin compose, approval queue, sponsorship, and moderation',
    tabIds: ['admin'],
    surfaceFamilies: ['announcement', 'approval', 'ad', 'workflow-status'],
    requiredAnatomy: [
      'role-specific task queue',
      'composer or reviewer detail',
      'preview/status/audit summary',
      'approve/reject/request changes actions',
    ],
    requiredInteractions: [
      'createDraft',
      'previewAnnouncement',
      'publishAnnouncement',
      'assignReviewer',
      'approve',
      'reject',
      'requestChanges',
      'comment',
      'recordImpression',
      'getDisclosure',
    ],
    requiredStates: [
      'draft',
      'preview',
      'published',
      'pending review',
      'approved',
      'rejected',
      'changes requested',
      'disclosed',
    ],
    evidenceRequirements: [
      'admin tab queue screenshot',
      'compose/detail screenshot',
      'decision/action screenshot',
      'result/audit screenshot',
    ],
    fallbackPolicy:
        'Admin tasks need queues and compose/review surfaces; do not expose them as undifferentiated workflow cards.',
  ),
};

LoomTabRendererContract tabRendererContractFor(String rendererContractId) {
  return _tabRendererContractsById[rendererContractId] ??
      _tabRendererContractsById['home-surface-stack']!;
}

List<LoomTabRendererContract> allTabRendererContracts() {
  return List.unmodifiable(_tabRendererContractsById.values);
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

List<LoomAppShellTabSpec> appShellTabsFor({
  required LoomExperienceDefinition experience,
  required String personaId,
  Map<String, Object?> appShellConfiguration = const {},
}) {
  final generatedTabs = <LoomAppShellTabSpec>[
    const LoomAppShellTabSpec(
      tabId: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      description: 'Pinned and unassigned community surfaces.',
      rendererContractId: 'home-surface-stack',
      pinningPolicy: 'none-declared-for-home',
      pinningPolicyRationale:
          'Home intentionally keeps the first visible surface in focus instead of pinning one workflow across every community.',
      requiredPermission: 'community.surface.navigation.read',
    ),
    if (_hasAnySection(experience, const ['Upcoming events']))
      LoomAppShellTabSpec(
        tabId: 'calendar',
        label: 'Calendar',
        icon: Icons.calendar_month_outlined,
        description: 'Events, schedules, capacity, and reminders.',
        rendererContractId: 'calendar-agenda-event-detail',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Calendar tabs pin the next dated event so members can act on the most time-sensitive schedule item first.',
        sectionTitles: const ['Upcoming events'],
        cardSurfaceFamilies: const ['event-rsvp', 'calendar'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSections(experience, const [
          'Upcoming events',
        ]),
        requiredPermission: 'community.surface.calendar.read',
      ),
    if (_hasAnySection(experience, const ['Documents and data']))
      LoomAppShellTabSpec(
        tabId: 'documents',
        label: 'Documents',
        icon: Icons.folder_open_outlined,
        description: 'Documents, exports, transfers, and audit records.',
        rendererContractId: 'documents-library-detail',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Document tabs pin the most important document or status surface so owners see the current record before browsing history.',
        sectionTitles: const ['Documents and data'],
        cardSurfaceFamilies: const [
          'documents',
          'external-document-link',
          'operations',
          'portability',
          'workflow-status',
        ],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSections(experience, const [
          'Documents and data',
        ]),
        requiredPermission: 'community.surface.documents.read',
      ),
    if (_hasAnySurfaceFamily(experience, const ['exchange', 'equipment-loan']))
      LoomAppShellTabSpec(
        tabId: 'marketplace',
        label: 'Marketplace',
        icon: Icons.storefront_outlined,
        description: 'Shared items, offers, claims, loans, and giveaways.',
        rendererContractId: 'marketplace-browse-listing-detail',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Marketplace tabs pin the most immediately actionable listing so members can browse, claim, or update availability quickly.',
        sectionTitles: const ['Care and volunteers', 'Member tools'],
        cardSurfaceFamilies: const ['exchange', 'equipment-loan'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['exchange', 'equipment-loan'],
        ),
        requiredPermission: 'community.surface.marketplace.read',
      ),
    if (_hasAnySection(experience, const ['Giving']))
      LoomAppShellTabSpec(
        tabId: 'giving',
        label: 'Giving',
        icon: Icons.payments_outlined,
        description: 'Payments, dues, donations, receipts, and ad-off state.',
        rendererContractId: 'payment-giving-ledger',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Giving tabs pin the current payment or receipt state because members need the amount, status, and next action first.',
        sectionTitles: const ['Giving'],
        cardSurfaceFamilies: const ['payment', 'ad-off-entitlement'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSections(experience, const [
          'Giving',
        ]),
        requiredPermission: 'community.surface.payments.read',
      ),
    if (_hasAnySurfaceFamily(experience, const ['volunteer', 'care-request']))
      LoomAppShellTabSpec(
        tabId: 'care',
        label: 'Care',
        icon: Icons.volunteer_activism_outlined,
        description: 'Care requests, volunteer shifts, and member support.',
        rendererContractId: 'care-volunteer-request-queue',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Care tabs pin the most urgent request or volunteer shift so the support workflow remains immediately visible.',
        sectionTitles: const ['Care and volunteers'],
        cardSurfaceFamilies: const ['volunteer', 'care-request'],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['volunteer', 'care-request'],
        ),
        requiredPermission: 'community.surface.care.read',
      ),
    if (_personaCanAdministerAnyWorkflow(experience, personaId))
      LoomAppShellTabSpec(
        tabId: 'admin',
        label: _adminTabLabelFor(experience.extensionId),
        icon: Icons.admin_panel_settings_outlined,
        description: 'Role-specific publishing, approvals, and operations.',
        rendererContractId: 'admin-review-compose-queue',
        pinningPolicy: 'pin-first-critical-surface',
        pinningPolicyRationale:
            'Admin tabs pin the first pending approval or publishing task so administrators see the queue item that needs action.',
        sectionTitles: const [
          'Announcements',
          'Requests and approvals',
          'Sponsored placement',
        ],
        cardSurfaceFamilies: const [
          'announcement',
          'approval',
          'ad',
          'workflow-status',
        ],
        pinnedWorkflowIds: _pinnedWorkflowIdsForSurfaceFamilies(
          experience,
          const ['announcement', 'approval', 'ad', 'workflow-status'],
        ),
        visiblePersonaIds: [personaId],
        requiredPermission: 'community.surface.navigation.configure',
      ),
    const LoomAppShellTabSpec(
      tabId: 'messages',
      label: 'Messages',
      icon: Icons.forum_outlined,
      description: 'Shell-owned communication and connections.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Messages uses a conversation surface rather than a pinned workflow card, so no pinned card surface is appropriate.',
      requiredPermission: 'community.surface.messages.read',
    ),
  ];
  return [
    for (final tab in _mergeDeclarativeTabSpecs(
      experience: experience,
      personaId: personaId,
      generatedTabs: generatedTabs,
      appShellConfiguration: appShellConfiguration,
    ))
      if (tab.isVisibleFor(personaId)) tab,
  ];
}

List<LoomAppShellTabSpec> _mergeDeclarativeTabSpecs({
  required LoomExperienceDefinition experience,
  required String personaId,
  required List<LoomAppShellTabSpec> generatedTabs,
  required Map<String, Object?> appShellConfiguration,
}) {
  final overrides = _declarativeTabSpecsFor(
    extensionId: experience.extensionId,
    personaId: personaId,
    appShellConfiguration: appShellConfiguration,
  );
  if (overrides.isEmpty) {
    return generatedTabs;
  }
  final mergedById = <String, LoomAppShellTabSpec>{
    for (final tab in generatedTabs) tab.tabId: tab,
  };
  for (final override in overrides) {
    mergedById[override.tabId] = override.toTabSpec();
  }
  final orderedIds = <String>[
    'home',
    ...overrides
        .map((override) => override.tabId)
        .where((tabId) => tabId != 'home' && tabId != 'messages'),
    for (final tab in generatedTabs)
      if (!overrides.any((override) => override.tabId == tab.tabId) &&
          tab.tabId != 'home' &&
          tab.tabId != 'messages')
        tab.tabId,
    'messages',
  ];
  return [
    for (final tabId in orderedIds)
      if (mergedById[tabId] != null) mergedById[tabId]!,
  ];
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFor({
  required String extensionId,
  required String personaId,
  Map<String, Object?> appShellConfiguration = const {},
}) {
  final packageGlobal = _declarativeTabSpecsFromConfiguration(
    appShellConfiguration['tabs'],
  );
  final packagePersona = _declarativeTabSpecsFromPersonaConfiguration(
    appShellConfiguration['personaTabs'],
    personaId: personaId,
  );
  final global = _declarativeTabSpecsByExtensionId[extensionId] ?? const [];
  final persona =
      _declarativeTabSpecsByExtensionAndPersona['$extensionId::$personaId'] ??
      const [];
  return [...global, ...persona, ...packageGlobal, ...packagePersona];
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFromPersonaConfiguration(
  Object? value, {
  required String personaId,
}) {
  if (value is! Map<String, Object?>) {
    return const [];
  }
  return _declarativeTabSpecsFromConfiguration(value[personaId]);
}

List<LoomDeclarativeTabSpec> _declarativeTabSpecsFromConfiguration(
  Object? value,
) {
  if (value is! List<Object?>) {
    return const [];
  }
  return [
    for (final item in value)
      if (_declarativeTabSpecFromMap(item) case final spec?) spec,
  ];
}

LoomDeclarativeTabSpec? _declarativeTabSpecFromMap(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }
  final tabId = _readShellString(value, const ['tabId', 'id']);
  final label = _readShellString(value, const ['label', 'title']);
  final iconKey = _readShellString(value, const ['iconKey', 'icon']) ?? 'home';
  final rendererContractId = _readShellString(value, const [
    'rendererContractId',
    'renderer',
    'rendererId',
  ]);
  if (tabId == null || label == null || rendererContractId == null) {
    return null;
  }
  return LoomDeclarativeTabSpec(
    tabId: tabId,
    label: label,
    iconKey: iconKey,
    description:
        _readShellString(value, const ['description', 'subtitle']) ??
        '$label surfaces for this community.',
    rendererContractId: rendererContractId,
    pinningPolicy: _readShellString(value, const ['pinningPolicy']) ?? 'none',
    pinningPolicyRationale:
        _readShellString(value, const ['pinningPolicyRationale']) ??
        'This package declares the tab pinning policy explicitly.',
    sectionTitles: _readShellStringList(value, const [
      'sectionTitles',
      'sections',
    ]),
    cardSurfaceFamilies: _readShellStringList(value, const [
      'cardSurfaceFamilies',
      'surfaceFamilies',
      'cardSurfaces',
    ]),
    pinnedWorkflowIds: _readShellStringList(value, const [
      'pinnedWorkflowIds',
      'pinnedSurfaces',
      'pinnedWorkflowIds',
    ]),
    visiblePersonaIds: _readShellStringList(value, const [
      'visiblePersonaIds',
      'personas',
    ]),
    requiredPermission:
        _readShellString(value, const ['requiredPermission', 'permission']) ??
        'community.surface.navigation.read',
  );
}

String? _readShellString(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

List<String> _readShellStringList(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is List<Object?>) {
      return value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}

IconData _tabIconForKey(String iconKey) {
  switch (iconKey) {
    case 'home':
      return Icons.home_outlined;
    case 'calendar':
      return Icons.calendar_month_outlined;
    case 'documents':
      return Icons.folder_open_outlined;
    case 'marketplace':
      return Icons.storefront_outlined;
    case 'gear':
      return Icons.photo_camera_back_outlined;
    case 'messages':
      return Icons.forum_outlined;
    case 'giving':
      return Icons.payments_outlined;
    case 'care':
      return Icons.volunteer_activism_outlined;
    case 'admin':
      return Icons.admin_panel_settings_outlined;
    case 'board':
      return Icons.fact_check_outlined;
  }
  return Icons.apps_outlined;
}

const _declarativeTabSpecsByExtensionId = <String, List<LoomDeclarativeTabSpec>>{
  'ext_camera_club': [
    LoomDeclarativeTabSpec(
      tabId: 'calendar',
      label: 'Walks',
      iconKey: 'calendar',
      description: 'Photo walks, critique deadlines, reminders, and RSVPs.',
      rendererContractId: 'calendar-agenda-event-detail',
      pinningPolicy: 'pin-next-photo-walk',
      pinningPolicyRationale:
          'Camera Club pins the next walk because members need the route, time, capacity, and gear reminder first.',
      sectionTitles: ['Upcoming events'],
      cardSurfaceFamilies: ['event-rsvp', 'calendar'],
      pinnedWorkflowIds: ['photo-walk-rsvp'],
      requiredPermission: 'community.surface.calendar.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'marketplace',
      label: 'Gear',
      iconKey: 'gear',
      description: 'Browse, request, loan, queue for, and return shared gear.',
      rendererContractId: 'marketplace-browse-listing-detail',
      pinningPolicy: 'pin-featured-available-listing',
      pinningPolicyRationale:
          'Gear tabs pin the featured available item so members can see availability and current-holder state immediately.',
      cardSurfaceFamilies: ['equipment-loan'],
      pinnedWorkflowIds: ['gear-loan-request'],
      requiredPermission: 'community.surface.marketplace.read',
    ),
    LoomDeclarativeTabSpec(
      tabId: 'messages',
      label: 'Club chat',
      iconKey: 'messages',
      description:
          'Threads, critique follow-up, walk coordination, and invites.',
      rendererContractId: 'messages-inbox-thread-composer',
      pinningPolicy: 'none-declared-for-messages',
      pinningPolicyRationale:
          'Club chat uses inbox and thread surfaces, so no pinned workflow card is appropriate.',
      requiredPermission: 'community.surface.messages.read',
    ),
  ],
  'ext_garden_club': [
    LoomDeclarativeTabSpec(
      tabId: 'marketplace',
      label: 'Exchange',
      iconKey: 'marketplace',
      description:
          'Browse offers, plant claims, pickup windows, and handoff state.',
      rendererContractId: 'marketplace-browse-listing-detail',
      pinningPolicy: 'pin-featured-available-listing',
      pinningPolicyRationale:
          'Garden exchange pins the most actionable offer so members can see variety, pickup, claim, and privacy state first.',
      cardSurfaceFamilies: ['exchange', 'equipment-loan'],
      pinnedWorkflowIds: ['plant-exchange-submission'],
      requiredPermission: 'community.surface.marketplace.read',
    ),
  ],
  'ext_hoa': [
    LoomDeclarativeTabSpec(
      tabId: 'admin',
      label: 'Board',
      iconKey: 'board',
      description:
          'Architectural decisions, dues, documents, and owner follow-up.',
      rendererContractId: 'admin-review-compose-queue',
      pinningPolicy: 'pin-first-critical-surface',
      pinningPolicyRationale:
          'Board tabs pin the first review or payment item that needs a decision.',
      sectionTitles: ['Requests and approvals', 'Giving', 'Documents and data'],
      cardSurfaceFamilies: [
        'approval',
        'payment',
        'operations',
        'workflow-status',
      ],
      visiblePersonaIds: ['hoa-board'],
      requiredPermission: 'community.surface.navigation.configure',
    ),
  ],
};

const _declarativeTabSpecsByExtensionAndPersona =
    <String, List<LoomDeclarativeTabSpec>>{};

bool _hasAnySection(
  LoomExperienceDefinition experience,
  List<String> sectionTitles,
) {
  return experience.workflows.any(
    (workflow) => sectionTitles.contains(_sectionTitleFor(workflow)),
  );
}

bool _hasAnySurfaceFamily(
  LoomExperienceDefinition experience,
  List<String> surfaceFamilies,
) {
  return experience.workflows.any((workflow) {
    final entry = cardSurfaceRegistryEntryFor(
      extensionId: experience.extensionId,
      workflow: workflow,
    );
    return surfaceFamilies.contains(entry.cardSurfaceFamily);
  });
}

bool _personaCanAdministerAnyWorkflow(
  LoomExperienceDefinition experience,
  String personaId,
) {
  return experience.workflows.any((workflow) {
    final state = personaWorkflowStateFor(
      extensionId: experience.extensionId,
      workflowId: workflow.workflowId,
      personaId: personaId,
    );
    if (state != LoomPersonaWorkflowState.actor) {
      return false;
    }
    final entry = cardSurfaceRegistryEntryFor(
      extensionId: experience.extensionId,
      workflow: workflow,
    );
    return entry.cardSurfaceFamily == 'announcement' ||
        entry.cardSurfaceFamily == 'approval' ||
        entry.cardSurfaceFamily == 'ad' ||
        entry.cardSurfaceFamily == 'workflow-status' ||
        _sectionTitleFor(workflow) == 'Requests and approvals';
  });
}

String _adminTabLabelFor(String extensionId) {
  switch (extensionId) {
    case 'ext_youth_soccer':
      return 'Coach';
    case 'ext_hoa':
      return 'Board';
    case 'ext_mosque':
      return 'Admin';
    case 'ext_garden_club':
      return 'Organize';
    case 'ext_book_club':
      return 'Host';
  }
  return 'Admin';
}

String workflowPersonaReceiptKey({
  required String workflowId,
  required String personaId,
}) {
  return '$workflowId::$personaId';
}

List<LoomWorkflowCardSurfaceRegistryEntry> cardSurfaceRegistryForExtensionId(
  String extensionId,
) {
  final experience = experienceForExtensionId(extensionId);
  return [
    for (final workflow in experience.workflows)
      cardSurfaceRegistryEntryFor(extensionId: extensionId, workflow: workflow),
  ];
}

LoomWorkflowCardSurfaceRegistryEntry cardSurfaceRegistryEntryFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) {
  final base = _cardSurfaceRegistryEntryForWorkflowId(workflow.workflowId);
  return LoomWorkflowCardSurfaceRegistryEntry(
    workflowId: workflow.workflowId,
    cardSurfaceFamily: base.cardSurfaceFamily,
    apiContract: base.apiContract,
    requiredInteractions: base.requiredInteractions,
    primaryActions: base.primaryActions,
    alternateActions: base.alternateActions,
    rendererTarget: _rendererTargetForWorkflow(
      extensionId: extensionId,
      workflowId: workflow.workflowId,
    ),
    fakeBackendSupport: base.fakeBackendSupport,
    routeTemplate: _routeTemplateForSurfaceFamily(base.cardSurfaceFamily),
  );
}

List<String> _pinnedWorkflowIdsForSections(
  LoomExperienceDefinition experience,
  List<String> sectionTitles,
) {
  return [
    for (final workflow in experience.workflows)
      if (sectionTitles.contains(_sectionTitleFor(workflow)))
        workflow.workflowId,
  ].take(1).toList(growable: false);
}

List<String> _pinnedWorkflowIdsForSurfaceFamilies(
  LoomExperienceDefinition experience,
  List<String> surfaceFamilies,
) {
  return [
    for (final workflow in experience.workflows)
      if (surfaceFamilies.contains(
        cardSurfaceRegistryEntryFor(
          extensionId: experience.extensionId,
          workflow: workflow,
        ).cardSurfaceFamily,
      ))
        workflow.workflowId,
  ].take(1).toList(growable: false);
}

LoomProductionWorkflowContract productionWorkflowContractFor({
  required String extensionId,
  required LoomWorkflowDefinition workflow,
}) {
  final category = _workflowCategoryFor(workflow);
  final objectLabel = _objectLabelFor(workflow);
  final cardSurface = cardSurfaceRegistryEntryFor(
    extensionId: extensionId,
    workflow: workflow,
  );
  return LoomProductionWorkflowContract(
    workflowId: workflow.workflowId,
    cardSurfaceFamily: cardSurface.cardSurfaceFamily,
    apiContract: cardSurface.apiContract,
    requiredInteractions: cardSurface.requiredInteractions,
    primaryActions: <String>{
      _primaryActionLabelFor(workflow),
      ...cardSurface.primaryActions,
    }.toList(),
    alternateActions: <String>{
      _alternateActionLabelFor(workflow),
      ...cardSurface.alternateActions,
    }.toList(),
    rendererTarget: cardSurface.rendererTarget,
    fakeBackendSupport: cardSurface.fakeBackendSupport,
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

LoomWorkflowCardSurfaceRegistryEntry _cardSurfaceRegistryEntryForWorkflowId(
  String workflowId,
) {
  final id = workflowId.toLowerCase();
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'announcement',
      apiContract: 'CommunityAnnouncementApi',
      requiredInteractions: const [
        'createDraft',
        'updateDraft',
        'previewAnnouncement',
        'scheduleAnnouncement',
        'publishAnnouncement',
        'cancelScheduledAnnouncement',
        'updatePublishedAnnouncement',
        'unpublishAnnouncement',
        'deliveryStatus',
        'readReceipts',
        'revisionHistory',
      ],
      primaryActions: const ['Save draft', 'Preview', 'Publish', 'Schedule'],
      alternateActions: const ['Edit published update', 'Unpublish'],
    );
  }
  if (id.contains('ad-off')) {
    if (id.contains('settlement')) {
      return _registryEntry(
        workflowId: workflowId,
        cardSurfaceFamily: 'ad-off-settlement',
        apiContract: 'CommunityAdOffSettlementApi',
        requiredInteractions: const [
          'calculateUtilityAllocation',
          'getSettlementRecord',
          'reviewSettlement',
          'correctAllocation',
          'rollbackSettlement',
          'exportSettlementAudit',
          'memberSettlementVisibility',
        ],
        primaryActions: const ['Review settlement', 'Export audit'],
        alternateActions: const ['Correct allocation', 'Rollback'],
      );
    }
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'ad-off-entitlement',
      apiContract: 'CommunityAdOffEntitlementApi',
      requiredInteractions: const [
        'startCheckout',
        'confirmEntitlement',
        'restoreEntitlement',
        'manageSubscription',
        'openReceipt',
        'listSuppressedAdSlots',
        'verifyNoFillReason',
        'renewOrCancel',
      ],
      primaryActions: const [
        'Activate ad-free',
        'Manage subscription',
        'Restore purchase',
      ],
      alternateActions: const ['Open receipt', 'View suppressed slots'],
    );
  }
  if (id.contains('ad-off') ||
      id.contains('payment') ||
      id.contains('donation') ||
      id.contains('dues') ||
      id.contains('checkout')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'payment',
      apiContract: 'CommunityPaymentSurfaceApi',
      requiredInteractions: const [
        'createPaymentIntent',
        'confirmPayment',
        'recordFailure',
        'retryPayment',
        'refund',
        'createRecurringPlan',
        'manageRecurringPlan',
        'setDonorVisibility',
        'getReceipt',
        'getEntitlement',
        'settlementStatus',
      ],
      primaryActions: const ['Pay', 'Confirm', 'Manage subscription'],
      alternateActions: const ['Retry', 'Refund', 'Open receipt'],
    );
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('schedule') ||
      id.contains('photo-walk')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'event-rsvp',
      apiContract: 'CommunityEventRsvpApi',
      requiredInteractions: const [
        'getEventDetail',
        'respondGoingMaybeNo',
        'changeRsvp',
        'cancelRsvp',
        'joinWaitlist',
        'listAttendees',
        'updateCapacity',
        'sendReminder',
        'calendarState',
        'cancelOrReschedule',
      ],
      primaryActions: const ['Going', 'Maybe', 'Not going'],
      alternateActions: const ['Change response', 'Cancel RSVP'],
    );
  }
  if (id.contains('volunteer') || id.contains('shift')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'volunteer',
      apiContract: 'CommunityVolunteerApi',
      requiredInteractions: const [
        'listShifts',
        'signup',
        'updateAvailability',
        'cancelSignup',
        'joinWaitlist',
        'listVolunteers',
        'volunteerSummary',
        'assignCoordinator',
        'checkInVolunteer',
        'markNoShow',
        'protectedContactReveal',
      ],
      primaryActions: const ['Sign up', 'Edit availability', 'Confirm in'],
      alternateActions: const ['Cancel signup', 'View volunteers'],
    );
  }
  if (id.contains('plant') || id.contains('exchange')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'exchange',
      apiContract: 'CommunityExchangeApi',
      requiredInteractions: const [
        'createOffer',
        'updateOffer',
        'cancelOffer',
        'claimOffer',
        'cancelClaim',
        'markUnavailable',
        'schedulePickup',
        'handoffComplete',
        'listClaims',
        'privacyScopedContact',
      ],
      primaryActions: const ['Offer item', 'Claim', 'Schedule pickup'],
      alternateActions: const ['Edit offer', 'Cancel claim'],
    );
  }
  if (id.contains('equipment') ||
      id.contains('gear') ||
      id.contains('loan') ||
      id.contains('racquet')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'equipment-loan',
      apiContract: 'CommunityEquipmentLoanApi',
      requiredInteractions: const [
        'offerEquipment',
        'requestLoan',
        'approveLoan',
        'declineLoan',
        'schedulePickup',
        'checkOut',
        'returnItem',
        'cancelLoan',
        'listAvailability',
        'privacyScopedContact',
      ],
      primaryActions: const ['Offer equipment', 'Request loan', 'Confirm out'],
      alternateActions: const ['Return item', 'Cancel loan'],
    );
  }
  if (id.contains('nomination')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'nomination',
      apiContract: 'CommunityNominationApi',
      requiredInteractions: const [
        'createNomination',
        'updateNomination',
        'withdrawNomination',
        'listNominations',
        'detectDuplicate',
        'checkEligibility',
        'linkToBallot',
        'nominationStatus',
      ],
      primaryActions: const ['Nominate', 'Edit nomination'],
      alternateActions: const ['Withdraw nomination'],
    );
  }
  if (id.contains('vote') || id.contains('ballot') || id.contains('poll')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'vote',
      apiContract: 'CommunityVoteApi',
      requiredInteractions: const [
        'openBallot',
        'castVote',
        'changeVote',
        'clearVote',
        'getVoteState',
        'getResults',
        'publishSelection',
        'auditVote',
      ],
      primaryActions: const ['Vote', 'Change vote'],
      alternateActions: const ['Clear vote', 'View results'],
    );
  }
  if (id.contains('message') ||
      id.contains('discussion') ||
      id.contains('thread')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'thread',
      apiContract: 'CommunityThreadApi',
      requiredInteractions: const [
        'createThread',
        'reply',
        'editMessage',
        'deleteMessage',
        'markRead',
        'listUnread',
        'muteThread',
        'archiveThread',
        'attachMedia',
        'mentionMember',
      ],
      primaryActions: const ['Reply', 'Mark read'],
      alternateActions: const ['Edit', 'Mute', 'Archive'],
    );
  }
  if (id.contains('care')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'care-request',
      apiContract: 'CommunityCareRequestApi',
      requiredInteractions: const [
        'createRequest',
        'updateRequest',
        'withdrawRequest',
        'assignCareTeam',
        'reviewRequest',
        'requestChanges',
        'resolveRequest',
        'neutralNotification',
        'readPublicSummary',
        'readProtectedDetails',
        'redactedAudit',
      ],
      primaryActions: const ['Request care', 'Assign care team', 'Resolve'],
      alternateActions: const ['Update request', 'Withdraw'],
    );
  }
  if (id.contains('approval') ||
      id.contains('decision') ||
      id.contains('architectural') ||
      id.contains('request')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'approval',
      apiContract: 'CommunityApprovalApi',
      requiredInteractions: const [
        'submitRequest',
        'assignReviewer',
        'approve',
        'reject',
        'requestChanges',
        'comment',
        'statusHistory',
        'reopen',
        'appeal',
        'notifyRequester',
      ],
      primaryActions: const ['Approve', 'Reject', 'Request changes'],
      alternateActions: const ['Comment', 'Reopen', 'Appeal'],
    );
  }
  if (id.contains('document') ||
      id.contains('facility') ||
      id.contains('reservation') ||
      id.contains('roster')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'operations',
      apiContract: 'CommunityOperationsSurfaceApi',
      requiredInteractions: const [
        'listDocuments',
        'openDocument',
        'downloadDocument',
        'acknowledgeDocument',
        'requestAccess',
        'documentVersions',
        'reserveFacility',
        'updateReservation',
        'cancelReservation',
        'resolveConflict',
        'getRoster',
        'updateRosterMember',
        'rosterHistory',
      ],
      primaryActions: const ['Open', 'Reserve', 'Acknowledge'],
      alternateActions: const ['Cancel reservation', 'Request access'],
    );
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'knowledge',
      apiContract: 'CommunityKnowledgeSurfaceApi',
      requiredInteractions: const [
        'search',
        'answerQuestion',
        'listCitations',
        'openCitation',
        'saveDigest',
        'shareDigest',
        'refreshIndex',
        'staleCitationCheck',
        'visibilityDecision',
      ],
      primaryActions: const ['Search', 'Open citation', 'Save digest'],
      alternateActions: const ['Share', 'Refresh index'],
    );
  }
  if (id.contains('export') ||
      id.contains('import') ||
      id.contains('transfer') ||
      id.contains('redaction') ||
      id.contains('rollback') ||
      id.contains('checksum')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'portability',
      apiContract: 'CommunityPortabilitySurfaceApi',
      requiredInteractions: const [
        'createExportPlan',
        'previewRedaction',
        'generateExport',
        'downloadExport',
        'verifyChecksum',
        'cancelExport',
        'retryExport',
        'startTransfer',
        'verifyTransfer',
        'rollbackTransfer',
        'auditTrail',
      ],
      primaryActions: const ['Generate export', 'Download', 'Start transfer'],
      alternateActions: const ['Preview redaction', 'Cancel', 'Retry'],
    );
  }
  if (id.contains('invite') ||
      id.contains('connection') ||
      id.contains('social')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'social',
      apiContract: 'CommunitySocialSurfaceApi',
      requiredInteractions: const [
        'sendInvite',
        'acceptInvite',
        'declineInvite',
        'cancelInvite',
        'block',
        'unblock',
        'mute',
        'archive',
        'connectionStatus',
        'createThread',
        'reply',
        'markRead',
      ],
      primaryActions: const ['Invite', 'Accept', 'Reply'],
      alternateActions: const ['Decline', 'Block', 'Mute'],
    );
  }
  if (id.contains('ad') || id.contains('sponsor')) {
    return _registryEntry(
      workflowId: workflowId,
      cardSurfaceFamily: 'ad',
      apiContract: 'CommunityAdSurfaceApi',
      requiredInteractions: const [
        'requestAdDecision',
        'recordImpression',
        'recordClick',
        'recordNoFill',
        'getNoFillReason',
        'getDisclosure',
        'getAdOffEntitlement',
        'suppressAds',
        'restoreAds',
        'receiptEvidence',
      ],
      primaryActions: const ['Open sponsor', 'Turn off ads'],
      alternateActions: const ['Restore ads', 'View disclosure'],
    );
  }
  return _registryEntry(
    workflowId: workflowId,
    cardSurfaceFamily: 'form',
    apiContract: 'CommunityFormSurfaceApi',
    requiredInteractions: const [
      'loadForm',
      'validateDraft',
      'saveDraft',
      'submitForm',
      'updateSubmission',
      'withdrawSubmission',
      'routeProtectedFields',
      'reviewSubmission',
      'exportSubmission',
    ],
    primaryActions: const ['Save draft', 'Submit', 'Update'],
    alternateActions: const ['Withdraw', 'Open details'],
  );
}

LoomWorkflowCardSurfaceRegistryEntry _registryEntry({
  required String workflowId,
  required String cardSurfaceFamily,
  required String apiContract,
  required List<String> requiredInteractions,
  required List<String> primaryActions,
  required List<String> alternateActions,
}) {
  return LoomWorkflowCardSurfaceRegistryEntry(
    workflowId: workflowId,
    cardSurfaceFamily: cardSurfaceFamily,
    apiContract: apiContract,
    requiredInteractions: requiredInteractions,
    primaryActions: primaryActions,
    alternateActions: alternateActions,
    rendererTarget: '',
    fakeBackendSupport:
        'LocalInAppBackend imports the initialization package, stores workflow state, records persona-specific receipts, and exposes the state used by this surface in the Demo App.',
  );
}

String _routeTemplateForSurfaceFamily(String cardSurfaceFamily) {
  switch (cardSurfaceFamily) {
    case 'calendar':
    case 'event-rsvp':
    case 'member-meetup':
      return '/calendar/:workflowId';
    case 'thread':
    case 'social':
    case 'inbox':
      return '/messages/:workflowId';
    case 'equipment-loan':
    case 'exchange':
      return '/marketplace/:workflowId';
    case 'documents':
    case 'external-document-link':
    case 'operations':
    case 'portability':
      return '/documents/:workflowId';
    case 'workflow-status':
    case 'approval':
    case 'form':
      return '/workflows/:workflowId';
    case 'payment':
    case 'ad-off-entitlement':
    case 'ad-off-settlement':
      return '/giving/:workflowId';
    case 'care-request':
    case 'volunteer':
      return '/care/:workflowId';
    case 'announcement':
    case 'ad':
      return '/admin/:workflowId';
  }
  return '/workflows/:workflowId';
}

String _rendererTargetForWorkflow({
  required String extensionId,
  required String workflowId,
}) {
  final entry = _cardSurfaceRegistryEntryForWorkflowId(workflowId);
  final rendererContract = tabRendererContractFor(
    _rendererContractIdForSurfaceFamily(entry.cardSurfaceFamily),
  );
  final surfaceRenderer = _surfaceRendererNameForSurfaceFamily(
    entry.cardSurfaceFamily,
  );
  if (extensionId == 'ext_garden_club' && workflowId == 'garden-event-rsvp') {
    return '${rendererContract.rendererId}/$surfaceRenderer + _GardenEventRsvpActionSurface';
  }
  if (extensionId == 'ext_garden_club' &&
      workflowId == 'plant-exchange-submission') {
    return '${rendererContract.rendererId}/$surfaceRenderer + _GardenPlantExchangeActionSurface';
  }
  if (_richWorkflowSpecFor(workflowId) != null) {
    return '${rendererContract.rendererId}/$surfaceRenderer + _RichWorkflowActionSurface';
  }
  return '${rendererContract.rendererId}/$surfaceRenderer + _WorkflowActionSurface';
}

String _rendererContractIdForSurfaceFamily(String cardSurfaceFamily) {
  switch (cardSurfaceFamily) {
    case 'calendar':
    case 'event-rsvp':
    case 'member-meetup':
      return 'calendar-agenda-event-detail';
    case 'thread':
    case 'social':
    case 'inbox':
      return 'messages-inbox-thread-composer';
    case 'equipment-loan':
    case 'exchange':
      return 'marketplace-browse-listing-detail';
    case 'documents':
    case 'external-document-link':
    case 'operations':
    case 'portability':
      return 'documents-library-detail';
    case 'workflow-status':
    case 'approval':
    case 'form':
      return 'workflow-status-timeline-actions';
    case 'payment':
    case 'ad-off-entitlement':
    case 'ad-off-settlement':
      return 'payment-giving-ledger';
    case 'care-request':
    case 'volunteer':
      return 'care-volunteer-request-queue';
    case 'announcement':
    case 'ad':
      return 'admin-review-compose-queue';
  }
  return 'home-surface-stack';
}

String _surfaceRendererNameForSurfaceFamily(String cardSurfaceFamily) {
  switch (cardSurfaceFamily) {
    case 'calendar':
      return 'CalendarItemRenderer';
    case 'event-rsvp':
      return 'EventRsvpDetailRenderer';
    case 'member-meetup':
      return 'MeetupDetailRenderer';
    case 'thread':
      return 'ThreadPreviewRenderer';
    case 'social':
      return 'ConnectionInviteRenderer';
    case 'inbox':
      return 'InboxItemRenderer';
    case 'equipment-loan':
      return 'MarketplaceListingDetailRenderer';
    case 'exchange':
      return 'ExchangeOfferRenderer';
    case 'documents':
      return 'DocumentDetailRenderer';
    case 'external-document-link':
      return 'ExternalDocumentRenderer';
    case 'operations':
      return 'OperationsRecordRenderer';
    case 'portability':
      return 'PortabilityStatusRenderer';
    case 'workflow-status':
      return 'WorkflowStatusTimelineRenderer';
    case 'approval':
      return 'ApprovalRequestTimelineRenderer';
    case 'form':
      return 'FormSubmissionStatusRenderer';
    case 'payment':
      return 'PaymentReceiptRenderer';
    case 'ad-off-entitlement':
      return 'AdOffEntitlementRenderer';
    case 'ad-off-settlement':
      return 'AdOffSettlementRenderer';
    case 'care-request':
      return 'CareRequestDetailRenderer';
    case 'volunteer':
      return 'VolunteerShiftRenderer';
    case 'announcement':
      return 'AnnouncementComposerRenderer';
    case 'ad':
      return 'SponsoredPlacementRenderer';
  }
  return 'SurfaceStackRenderer';
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
        'This role can read the current record without editing.';
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
      return 'You can read this item without editing it.';
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
    return 'Open ${_objectLabelFor(workflow)}';
  }
  return label;
}

String _workflowCategoryFor(LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  final title = workflow.title.toLowerCase();
  if (id.contains('ad-off')) {
    return 'Ad-free';
  }
  if (id.contains('search') ||
      id.contains('digest') ||
      id.contains('citation')) {
    return 'Knowledge';
  }
  if (id.contains('in-stream-ad') ||
      id.contains('top-banner') ||
      id.contains('no-fill') ||
      id.contains('sensitive-no-fill') ||
      id.contains('sponsor')) {
    return 'Ads';
  }
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
      title.contains('receipt') ||
      title.contains('reservation')) {
    return 'Payment';
  }
  if (id.contains('announcement') ||
      id.contains('publish') ||
      id.contains('notification')) {
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
    case 'Ad-free':
      return 'Ad-free account';
    case 'Ads':
      return 'Ad placement';
    case 'Knowledge':
      return 'Knowledge answer';
    case 'Publishing':
      return 'Member update';
    case 'Approval':
      return 'Request changes';
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
    return id.contains('ad-off')
        ? 'Start ad-free checkout'
        : 'Confirm checkout';
  }
  if (id.contains('entitlement')) {
    return 'Manage entitlement';
  }
  if (id.contains('receipt')) {
    return 'Open receipt';
  }
  if (id.contains('suppression')) {
    return 'Verify ad suppression';
  }
  if (id.contains('settlement')) {
    return 'Review settlement';
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
    return 'Confirm blocked state';
  }
  if (id.contains('ad') || id.contains('banner')) {
    return 'Open ad details';
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
  if (id.contains('ad-off')) {
    return id.contains('settlement')
        ? 'Correct allocation'
        : 'Restore or cancel';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout')) {
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
  if (id.contains('nomination')) {
    return 'Edit nomination';
  }
  if (id.contains('vote')) {
    return 'Change vote';
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
  if (id.contains('signup')) {
    return 'Edit availability';
  }
  return 'Edit response';
}

String _decisionSummaryFor(String category, LoomWorkflowDefinition workflow) {
  final id = workflow.workflowId;
  if (id.contains('announcement') || id.contains('publish')) {
    return 'Message body, audience, delivery timing, preview, and draft option stay visible before publishing.';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'Event date, time, location, capacity, and Going/Maybe/Not going options are visible.';
  }
  if (id.contains('ad-off')) {
    return id.contains('settlement')
        ? 'Funded amount, settlement ID, utility allocation, audit status, correction, and rollback path are visible.'
        : 'Entitlement scope, renewal or expiry, receipt link, restore/manage action, and affected ad slots are visible.';
  }
  if (id.contains('payment') ||
      id.contains('dues') ||
      id.contains('donation') ||
      id.contains('checkout') ||
      id.contains('ad-off')) {
    return 'Amount, payer context, visibility, receipt destination, retry, refund, and manage-payment options are visible.';
  }
  if (id.contains('document')) {
    return 'Document access, version, download, save, share, and access-request options are visible.';
  }
  if (id.contains('architectural') ||
      id.contains('approval') ||
      id.contains('request')) {
    return 'Request details, approval, rejection, revision request, comments, and status history are visible.';
  }
  if (id.contains('care')) {
    return 'Care details, recipient visibility, privacy settings, protected fields, and follow-up option are visible.';
  }
  if (id.contains('gear')) {
    return 'Owner, pickup, due date, borrower queue, claim, decline, change, and return options are visible.';
  }
  if (id.contains('plant-exchange')) {
    return 'Variety, pickup, protected contact, claim, offer, edit, and cancel options are visible.';
  }
  if (id.contains('critique')) {
    return 'Image, prompt, consent note, comments, submit, edit, withdraw, and resubmit options are visible.';
  }
  if (id.contains('match') || id.contains('chess')) {
    return 'Opponent, round, score, standings impact, save, edit, correct, and dispute options are visible.';
  }
  if (id.contains('message') ||
      id.contains('connection') ||
      id.contains('invite')) {
    return 'Sender, recipient, message body, timestamp, reply, send, accept, decline, mute, archive, and block options are visible.';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Scope, redaction, checksum, destination, retry, rollback, and change-scope options are visible.';
  }
  return 'This view shows editable details, current progress, and the next step before saving.';
}

String _receiverStateSummaryFor(
  String category,
  LoomWorkflowDefinition workflow,
) {
  final id = workflow.workflowId;
  if (id.contains('announcement') || id.contains('publish')) {
    return 'Members see it later in the inbox, notification list, and read receipt.';
  }
  if (id.contains('rsvp') ||
      id.contains('event') ||
      id.contains('practice') ||
      id.contains('photo-walk')) {
    return 'The calendar, attendee roster, and member record remain visible after the response.';
  }
  if (id.contains('ad-off')) {
    return id.contains('settlement')
        ? 'Settlement ID, funded amount, audit status, utility impact, correction, and rollback path remain visible.'
        : 'Ad-free entitlement, receipt, renewal, restore path, and suppressed ad slots remain available.';
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
    return 'Recipient inbox, thread, and connection record remain visible.';
  }
  if (id.contains('export') ||
      id.contains('transfer') ||
      id.contains('import')) {
    return 'Provider, destination, rollback, audit, and transfer progress remain visible.';
  }
  return 'History, receiver status, and next step remain visible.';
}

String _screenTitleFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Event details';
    case 'Payment':
      return 'Payment checkout';
    case 'Ad-free':
      return 'Ad-free account';
    case 'Ads':
      return 'Ad slot state';
    case 'Knowledge':
      return 'Cited answer';
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
    case 'Ad-free':
      return const Color(0xff4d668f);
    case 'Ads':
      return const Color(0xff6d5a1e);
    case 'Knowledge':
      return const Color(0xff4e5fa8);
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
    case 'Ad-free':
      return 'Manage ad-free account';
    case 'Ads':
      return 'Review sponsored placement';
    case 'Knowledge':
      return 'Use cited answer';
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
        return 'The member can open the receipt, privacy choice, and amount.';
      case 'Ad-free':
        return 'The member sees ad-free entitlement, receipt, renewal, and affected ad slots.';
      case 'Ads':
        return 'The member sees disclosure, no-fill reason, dismissal, or report state.';
      case 'Knowledge':
        return 'The member sees the cited answer, source visibility, and saved digest state.';
      case 'Publishing':
        return 'The member sees the message, audience, and delivery channel.';
      case 'Approval':
        return 'The member sees the decision and the next action.';
      case 'Portability':
        return 'The member can open scope, status, and protected-data handling.';
      case 'Platform':
        return 'The member sees the channel or relationship change.';
      case 'Form':
        return 'The reviewer can open the submitted details and follow-up option.';
    }
  }
  switch (category) {
    case 'Event':
      return 'This screen helps you publish event details, capacity, and attendance state.';
    case 'Payment':
      return 'This screen helps you capture the amount, receipt, and privacy setting.';
    case 'Ad-free':
      return 'This screen helps you manage entitlement, receipt, renewal, restore, and affected ad slots.';
    case 'Ads':
      return 'This screen helps you inspect disclosure, reserved slot, sponsor or no-fill reason, and controls.';
    case 'Knowledge':
      return 'This screen helps you inspect query, answer, citations, source visibility, and follow-up.';
    case 'Publishing':
      return 'This screen helps you send a scoped announcement to the selected audience.';
    case 'Approval':
      return 'This screen helps you record the decision and member follow-up.';
    case 'Portability':
      return 'This screen helps you package export scope, redaction, and handoff status.';
    case 'Platform':
      return 'This screen helps you change a member communication or relationship setting.';
    case 'Form':
      return 'This screen helps you submit structured member details.';
  }
  return workflow.entryText;
}

String _surfaceInputFor(String category, LoomWorkflowDefinition workflow) {
  switch (category) {
    case 'Event':
      return 'Date, location, capacity, and attendee state are included.';
    case 'Payment':
      return 'Amount, payer, privacy choice, and receipt destination are included.';
    case 'Ad-free':
      return 'Entitlement scope, renewal, receipt, restore/manage action, and affected ad slots are included.';
    case 'Ads':
      return 'Reserved slot, disclosure/no-fill reason, impression state, and report/dismiss controls are included.';
    case 'Knowledge':
      return 'Query, answer, citations, source visibility, save/share, and refresh state are included.';
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
    case 'Ad-free':
      return 'The entitlement, renewal or expiry, receipt, restore path, and ad suppression state remain visible.';
    case 'Ads':
      return 'The ad slot preserves layout with disclosure, impression/no-fill, and member controls visible.';
    case 'Knowledge':
      return 'The cited answer can be saved, shared, refreshed, and checked for stale sources.';
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
    case 'Ad-free':
      return 'Entitlement scope, receipt, renewal, restore, and suppressed ad slots are ready.';
    case 'Ads':
      return 'Disclosure, slot state, no-fill reason, and member controls are ready.';
    case 'Knowledge':
      return 'Query, answer, citations, source visibility, and follow-up prompts are ready.';
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
    case 'Ad-free':
      return 'Entitlement, receipt, restore/manage action, and affected ad slots are checked.';
    case 'Ads':
      return 'Disclosure, impression/no-fill state, and member controls are checked.';
    case 'Knowledge':
      return 'Citations, source visibility, stale-source handling, and saved digest state are checked.';
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
    case 'Ad-free':
      return 'Ad-free account updated';
    case 'Ads':
      return 'Ad slot recorded';
    case 'Knowledge':
      return 'Answer saved';
    case 'Publishing':
      return 'Update sent';
    case 'Approval':
      return 'Request outcome saved';
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
    return 'The coordinator can open the signup and protected contact details.';
  }
  if (id.contains('care')) {
    return 'The care team can open the private request details.';
  }
  switch (category) {
    case 'Event':
      return 'Event details and attendance records are up to date.';
    case 'Payment':
      return 'The receipt is saved and available to the member.';
    case 'Ad-free':
      return 'The entitlement, receipt, renewal, restore path, and suppressed ad slots remain visible.';
    case 'Ads':
      return 'The slot keeps disclosure/no-fill state, member control, and stable layout visible.';
    case 'Knowledge':
      return 'The cited answer is saved with source visibility and refresh/follow-up actions.';
    case 'Publishing':
      return 'The update is available to the selected audience.';
    case 'Approval':
      return 'The request outcome is saved and ready for member follow-up.';
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
    case 'Ad-free':
      return 'Ad-free status ready';
    case 'Ads':
      return 'Ad slot state ready';
    case 'Knowledge':
      return 'Saved answer ready';
    case 'Publishing':
      return 'Update ready';
    case 'Approval':
      return 'Request update ready';
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
    case 'Ad-free':
      return 'Ad-free';
    case 'Ads':
      return 'Recorded';
    case 'Knowledge':
      return 'Saved';
    case 'Publishing':
      return 'Sent';
    case 'Approval':
      return 'Reviewed';
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
    case 'Ad-free':
      return 'Ad-free entitlement and receipt records stay tied to the member account.';
    case 'Ads':
      return 'Sponsored placement and no-fill decisions preserve member trust.';
    case 'Knowledge':
      return 'Answers stay permission-aware and cite visible sources.';
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
    case 'Ad-free':
      return Icons.block_outlined;
    case 'Ads':
      return Icons.campaign_outlined;
    case 'Knowledge':
      return Icons.manage_search_outlined;
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
      description: 'Coordinates events, exchanges, and garden exports.',
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
      description: 'Manages requests, sends decisions, and exports records.',
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
      description: 'Runs community homes and match records.',
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
      description: 'Coordinates RSVPs, critiques, and gear-loan requests.',
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
      description: 'Manages prevention and sensitive-page behavior.',
    ),
    LoomPersonaDefinition(
      personaId: 'platform-blocked-member',
      label: 'Blocked Member',
      roleLabel: 'Restricted',
      description: 'Sees restricted social actions and account status.',
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
        receiverEntryText: 'A member garden submission is ready for action.',
        receiverActionText: 'Open',
        receiverResultText:
            'Garden coordinator received the member submission.',
      );
    case 'garden-export-custom-schemas':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['garden-coordinator'],
        readOnlyPersonaIds: ['garden-member'],
        readOnlyText: 'Members can open that their garden records export.',
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
            'A member book-club contribution is ready for organizer action.',
        receiverActionText: 'Open',
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
        readOnlyText: 'Members can open export metadata without creating it.',
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
        readOnlyText: 'Guardian can open protected export coverage.',
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
        receiverEntryText: 'A homeowner action is ready for board action.',
        receiverActionText: 'Open',
        receiverResultText: 'Board received the homeowner request update.',
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
        readOnlyText: 'Homeowners can open export evidence.',
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
        receiverEntryText: 'A member submission is ready for admin action.',
        receiverActionText: 'Open',
        receiverResultText: 'Admin received the member submission.',
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
        receiverEntryText: 'A match result is ready for organizer action.',
        receiverActionText: 'Open result',
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
        receiverEntryText: 'A member camera-club action is ready for action.',
        receiverActionText: 'Open',
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
            'Blocked persona can open shell state but cannot initiate social actions.',
      );
    case 'platform-connection-invite':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['platform-member'],
        receiverPersonaIds: ['platform-moderator'],
        disabledReason:
            'Blocked or moderator roles do not send this member invite.',
        receiverEntryText:
            'A member invite attempt is ready for moderator action.',
        receiverActionText: 'Open invite',
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
            'Non-admin roles can open economics without recalculating settlement.',
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
        readOnlyText: 'Non-owner roles open redacted portability evidence.',
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
        actionText: 'Submit a basil seedling offer to the plant exchange.',
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
        entryText: 'Fence color request is ready for board action.',
        actionText: 'Submit architectural request for committee decision.',
        resultText: 'Architectural request case opened.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'hoa-committee-decision',
        title: 'Committee decision',
        entryText: 'Committee decision step is waiting.',
        actionText: 'Approve the architectural request.',
        resultText: 'Architectural request approved.',
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
        actionText: 'Open the Chess Club home.',
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
        resultText: 'Gear-loan request created and pending response.',
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
        entryText: 'Messages are available from the app bar.',
        actionText: 'Open Messages entry from the app bar.',
        resultText: 'Messages entry is reachable.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'platform-connections-entry',
        title: 'Connections entry',
        entryText: 'Connections are available from the app bar.',
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
        actionText: 'Evaluate top banner fill and no-fill results.',
        resultText: 'Top banner records required no-fill result.',
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
        entryText: 'Member ad-free checkout is available.',
        actionText: 'Complete member ad-off checkout.',
        resultText: 'Member ad-off entitlement active.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-community-checkout',
        title: 'Community ad-off checkout',
        entryText: 'Community-wide ad-free checkout is available.',
        actionText: 'Complete community ad-off checkout.',
        resultText: 'Community ad-off entitlement active.',
      ),
      LoomWorkflowDefinition(
        workflowId: 'ad-off-entitlement-status',
        title: 'Entitlement record',
        entryText: 'Ad-off entitlement can be restored and checked.',
        actionText: 'Verify member and community entitlement record.',
        resultText: 'Entitlement record shows active.',
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
