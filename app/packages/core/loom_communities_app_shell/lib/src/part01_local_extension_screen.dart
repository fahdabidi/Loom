part of '../loom_communities_app_shell.dart';

enum SurfacePresentationState { minimized, medium, expanded }

class CommunityLaunchCard extends StatelessWidget {
  const CommunityLaunchCard({
    super.key,
    required this.community,
    required this.experience,
    required this.state,
    required this.onTap,
  });

  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
  final SurfacePresentationState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Color(experience.accentColor);
    final textTheme = Theme.of(context).textTheme;
    final isFocused = state == SurfacePresentationState.medium;
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

class LocalExtensionScreen extends StatefulWidget {
  const LocalExtensionScreen({
    required this.community,
    required this.seedDataFiles,
  });

  final LocalInstalledCommunity community;
  final List<String> seedDataFiles;

  @override
  State<LocalExtensionScreen> createState() => _LocalExtensionScreenState();
}

class _LocalExtensionScreenState extends State<LocalExtensionScreen> {
  final Set<String> _completedWorkflowIds = {};
  final Set<String> _receivedWorkflowPersonaKeys = {};
  final Map<String, String> _selectedResponseByWorkflowId = {};
  final Set<String> _reminderEnabledWorkflowIds = {};
  final Map<String, String> _selectedTabIdByPersonaId = {};
  final Map<String, String> _focusedWorkflowIdByPersonaTab = {};
  final Map<String, GlobalKey> _workflowSurfaceKeysById = {};
  late final ScrollController _surfaceScrollController;
  List<String> _visibleWorkflowIds = const [];
  String? _activeSurfaceFocusKey;
  String? _expandedWorkflowId;
  String? _selectedPersonaId;

  /// Auth API — seeded with demo accounts by default.
  late final LoomAuthApi _authApi = LocalAuthApi();

  /// The individual account id when signed in, otherwise falls back to
  /// [_selectedPersonaId] (the persona type) for backward compatibility.
  String? get _activeAccountId {
    final session = _authApi.currentSession;
    return session?.account.accountId ?? _selectedPersonaId;
  }

  /// The persona type of the signed-in account, or [_selectedPersonaId].
  String? get _activePersonaTypeId {
    final session = _authApi.currentSession;
    return session?.account.personaTypeId ?? _selectedPersonaId;
  }

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
    _syncEnginePersonaTypes();
  }

  /// Registers every seeded account's individual-id → persona-type mapping
  /// with the engine so [allowedPersonaIds] guards can check the type.
  ///
  /// No-op for legacy-schema communities (any community whose
  /// [LoomExperienceDefinition.workflowDefinitions] is null or empty —
  /// these communities never install an engine-native experience, so there
  /// is nothing to sync and attempting the lookup would throw).
  Future<void> _syncEnginePersonaTypes() async {
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    if (experience.workflowDefinitions == null ||
        experience.workflowDefinitions!.isEmpty) {
      return; // legacy-schema community — nothing to sync
    }
    final accounts = await _authApi.listAccounts(
      communityExtensionId: community.extensionId,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    if (engine is LocalWorkflowEngineApi) {
      for (final account in accounts) {
        engine.setPersonaType(account.accountId, account.personaTypeId);
      }
    }
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
    final currentFocused = _focusedWorkflowIdByPersonaTab[focusKey];
    var nextFocused = _visibleWorkflowIds.first;
    var largestVisibleExtent = -1.0;
    var currentFocusedExtent = -1.0;
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
      if (workflowId == currentFocused) {
        currentFocusedExtent = visibleExtent;
      }
      if (visibleExtent > largestVisibleExtent) {
        largestVisibleExtent = visibleExtent;
        nextFocused = workflowId;
      }
    }
    // Hysteresis: cards vary a lot in height (a completed multi-choice
    // workflow's card is much taller than a plain one), so as the user
    // scrolls, the "largest visible extent" winner can flip every frame
    // right around a crossover point — the card that just "lost" the focus
    // shrinks, which can make a neighbor "win" a frame later, which grows
    // it back, and so on. That produced a visible pop/snap while scrolling.
    // Require a clear margin before stealing focus from the current card so
    // borderline cases don't oscillate.
    const hysteresisPx = 48.0;
    final currentStillVisible =
        currentFocused != null && _visibleWorkflowIds.contains(currentFocused);
    final shouldSwitch =
        !currentStillVisible ||
        largestVisibleExtent > currentFocusedExtent + hysteresisPx;
    if (shouldSwitch &&
        _focusedWorkflowIdByPersonaTab[focusKey] != nextFocused &&
        mounted) {
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
    final personas = personasForExtensionId(
      experience.extensionId,
      experience: experience,
    );
    final typeId = _activePersonaTypeId;
    if (typeId != null) {
      for (final persona in personas) {
        if (persona.personaId == typeId) {
          return persona;
        }
      }
    }
    return personas.first;
  }

  /// Resolves the [LoomCardTheme] a workflow's pushed action surface should
  /// render with, outside of `build()` (where the current
  /// [CommunityAppShellCustomizationSpec] isn't in scope): recomputes the
  /// same community -> owning-tab -> workflow cascade. `home` is excluded
  /// from the owning-tab search since `matchesWorkflow` always returns true
  /// for it (Home lists every workflow), which would otherwise make it win
  /// the search for every workflow regardless of its real dedicated tab —
  /// unlike [_focusWorkflowAfterAction], which *wants* Home as the landing
  /// tab after any action and so does not exclude it.
  LoomCardTheme _resolvedCardThemeFor(LoomWorkflowDefinition workflow) {
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    final accent = Color(experience.accentColor);
    final usesModernCardTheme = experience.themeOverride != null;
    final communityCard = LoomCardTheme.merge(
      LoomCardTheme.deriveFromAccent(accent, lightSurface: usesModernCardTheme),
      experience.themeOverride,
    );
    final activePersona = _activePersona(experience);
    setCurrentActiveAccountId(_activeAccountId);
    final tabSpecs = appShellTabsFor(
      experience: experience,
      personaId: activePersona.personaId,
      appShellConfiguration: community.appShellConfiguration,
    );
    final owningTab = tabSpecs.firstWhere(
      (tab) =>
          tab.tabId != 'home' &&
          tab.matchesWorkflow(
            extensionId: experience.extensionId,
            workflow: workflow,
          ),
      orElse: () => tabSpecs.first,
    );
    final tabCard = LoomCardTheme.merge(
      communityCard,
      experience.tabThemeOverrides[owningTab.tabId],
    );
    return LoomCardTheme.merge(tabCard, workflow.theme);
  }

  Future<void> _confirmWorkflow(LoomWorkflowDefinition workflow) async {
    final contract = productionWorkflowContractFor(
      extensionId: community.extensionId,
      workflow: workflow,
    );
    final resolvedTheme = _resolvedCardThemeFor(workflow);
    final usesModernCardTheme =
        experienceForExtensionId(
          community.extensionId,
          displayName: community.displayName,
          experienceConfiguration: community.experienceConfiguration,
        ).themeOverride !=
        null;
    String? selectedResponseId;
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
              fallbackAccent: resolvedTheme.accent!,
              modernTheme: usesModernCardTheme ? resolvedTheme : null,
              onResponseSelected: (responseId) =>
                  selectedResponseId = responseId,
            ),
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    _focusWorkflowAfterAction(
      workflow,
      mutateState: () {
        _completedWorkflowIds.add(workflow.workflowId);
        if (selectedResponseId != null) {
          _selectedResponseByWorkflowId[workflow.workflowId] =
              selectedResponseId!;
        }
      },
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
    final resolvedTheme = _resolvedCardThemeFor(workflow);
    final usesModernCardTheme =
        experienceForExtensionId(
          community.extensionId,
          displayName: community.displayName,
          experienceConfiguration: community.experienceConfiguration,
        ).themeOverride !=
        null;
    final confirmed =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            fullscreenDialog: true,
            builder: (context) => _WorkflowActionSurface(
              key: ValueKey('workflow-receive-surface-${workflow.workflowId}'),
              workflow: workflow,
              contract: contract,
              fallbackAccent: resolvedTheme.accent!,
              modernTheme: usesModernCardTheme ? resolvedTheme : null,
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
      experienceConfiguration: community.experienceConfiguration,
    );
    final activePersona = _activePersona(experience);
    setCurrentActiveAccountId(_activeAccountId);
    final tabSpecs = appShellTabsFor(
      experience: experience,
      personaId: activePersona.personaId,
      appShellConfiguration: community.appShellConfiguration,
    );
    final targetTab = tabSpecs.firstWhere(
      (tab) =>
          tab.tabId != 'home' &&
          tab.matchesWorkflow(
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
    final personas = personasForExtensionId(
      experience.extensionId,
      experience: experience,
    );
    final usesModernCardTheme = experience.themeOverride != null;
    final communityCard = usesModernCardTheme
        ? LoomCardTheme.merge(
            LoomCardTheme.deriveFromAccent(
              Color(experience.accentColor),
              lightSurface: true,
            ),
            experience.themeOverride,
          )
        : null;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        final dialogAccent = communityCard?.accent;
        return AlertDialog(
          key: const ValueKey('persona-picker-dialog'),
          backgroundColor: communityCard?.resolvedFill,
          shape: communityCard != null
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              : null,
          title: Text(
            'Account role and permissions',
            style: communityCard != null
                ? TextStyle(color: communityCard.resolvedHeading)
                : null,
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your memberships determine which community actions are available. Choose the role you want to use in this community.',
                    style: communityCard != null
                        ? TextStyle(color: communityCard.resolvedBody)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  for (final persona in personas)
                    ListTile(
                      key: ValueKey('persona-option-${persona.personaId}'),
                      selected: persona.personaId == activePersona.personaId,
                      selectedTileColor: dialogAccent?.withValues(alpha: 0.08),
                      leading: Icon(
                        persona.personaId == activePersona.personaId
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: dialogAccent,
                      ),
                      title: Text(
                        persona.label,
                        style: communityCard != null
                            ? TextStyle(color: communityCard.resolvedHeading)
                            : null,
                      ),
                      subtitle: Text(
                        '${persona.roleLabel} - ${persona.description}',
                        style: communityCard != null
                            ? TextStyle(color: communityCard.resolvedBody)
                            : null,
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
              style: dialogAccent != null
                  ? TextButton.styleFrom(foregroundColor: dialogAccent)
                  : null,
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
    required SurfacePresentationState state,
    required CommunityAppShellCustomizationSpec shellSpec,
    required String focusKey,
  }) {
    final policy = personaPolicyForWorkflow(
      experience.extensionId,
      workflow.workflowId,
      experience: experience,
    );
    final view = personaWorkflowViewFor(
      extensionId: experience.extensionId,
      workflow: workflow,
      personaId: activePersona.personaId,
      completedWorkflowIds: _completedWorkflowIds,
      receivedWorkflowPersonaKeys: _receivedWorkflowPersonaKeys,
      experience: experience,
    );
    final workflowCardTheme = shellSpec.cardThemeFor(workflow);
    final modernTheme = shellSpec.theme.usesModernCardTheme
        ? workflowCardTheme
        : null;
    final workflowTile = _WorkflowTile(
      extensionId: experience.extensionId,
      workflow: workflow,
      view: view,
      state: state,
      fallbackAccent: workflowCardTheme.accent!,
      modernTheme: modernTheme,
      selectedResponseId: _selectedResponseByWorkflowId[workflow.workflowId],
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
        theme: workflowCardTheme,
        modernTheme: modernTheme,
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
      experienceConfiguration: community.experienceConfiguration,
    );
    final activePersona = _activePersona(experience);
    setCurrentActiveAccountId(_activeAccountId);
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            Builder(
              builder: (context) {
                final bannerTheme = shellSpec.theme.usesModernCardTheme
                    ? shellSpec.theme.communityCard
                    : null;
                final bannerFill =
                    bannerTheme?.resolvedFill ??
                    Colors.white.withValues(alpha: 0.10);
                final bannerBorder =
                    bannerTheme?.resolvedBorder ??
                    Colors.white.withValues(alpha: 0.22);
                final bannerForeground =
                    bannerTheme?.resolvedBody ?? Colors.white;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: bannerFill,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: bannerBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.campaign_outlined, color: bannerForeground),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No sponsored message right now.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: bannerForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final heroTheme = shellSpec.theme.usesModernCardTheme
                    ? shellSpec.theme.communityCard
                    : null;
                final heroFill = heroTheme?.resolvedFill ?? accent;
                final heroBorder = heroTheme?.resolvedBorder;
                final heroShadow =
                    heroTheme?.resolvedShadow ?? accent.withValues(alpha: 0.24);
                final heroHeading = heroTheme?.resolvedHeading ?? Colors.white;
                final heroBody =
                    heroTheme?.resolvedBody ??
                    Colors.white.withValues(alpha: 0.92);
                final heroAvatarBg = heroTheme != null
                    ? heroTheme.resolvedBorder.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.18);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: heroFill,
                    borderRadius: BorderRadius.circular(6),
                    border: heroBorder != null
                        ? Border.all(color: heroBorder)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: heroShadow,
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
                              backgroundColor: heroAvatarBg,
                              child: Icon(
                                _communityIconFor(experience.extensionId),
                                size: 34,
                                color: heroHeading,
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
                                      color: heroHeading,
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
                                      color: heroBody,
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
                            experience: experience,
                          ).length,
                          foreground: heroHeading,
                          modernTheme: heroTheme,
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
                            key: ValueKey(
                              'opened-route-${community.extensionId}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            _SelectedTabHeader(
              tab: selectedTab,
              accent: accent,
              persona: activePersona,
              modernTheme: shellSpec.theme.usesModernCardTheme
                  ? shellSpec.theme.tabCard
                  : null,
            ),
            const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                shellSpec.theme.tabHeight + 48,
              ),
              child: SingleChildScrollView(
                key: ValueKey('local-extension-${community.extensionId}'),
                controller: _surfaceScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        shellSpec: shellSpec,
                        focusKey: focusKey,
                      ),
                      reminderEnabledWorkflowIds: _reminderEnabledWorkflowIds,
                      onToggleReminder: (workflowId) => setState(() {
                        if (!_reminderEnabledWorkflowIds.remove(workflowId)) {
                          _reminderEnabledWorkflowIds.add(workflowId);
                        }
                      }),
                      onSelectCalendarDate: (workflowId) => setState(() {
                        _focusedWorkflowIdByPersonaTab[focusKey] = workflowId;
                      }),
                      onConfirmWorkflow: (workflow) => _confirmWorkflow(workflow),
                      completedWorkflowIds: _completedWorkflowIds,
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
            ),
          ),
        ],
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
