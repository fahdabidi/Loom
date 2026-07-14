part of '../loom_communities_app_shell.dart';

class _YouthSoccerEngineTabSurface extends StatefulWidget {
  const _YouthSoccerEngineTabSurface({
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
  State<_YouthSoccerEngineTabSurface> createState() =>
      _YouthSoccerEngineTabSurfaceState();
}

class _YouthSoccerEngineTabSurfaceState
    extends State<_YouthSoccerEngineTabSurface> {
  static final _stores = <String, _YouthSoccerEngineStore>{};
  late final _YouthSoccerEngineStore _store;
  final _controllers = <String, TextEditingController>{};
  List<WorkflowInstance> _instances = const [];
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = _stores.putIfAbsent(
      widget.experience.extensionId,
      () => _YouthSoccerEngineStore(communityId: widget.experience.extensionId),
    );
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_YouthSoccerEngineTabSurface oldWidget) {
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
      final rows = await _store.instancesFor(
        tabId: widget.tabId,
        personaId: widget.persona.personaId,
      );
      _sync(rows);
      if (!mounted) return;
      setState(() {
        _instances = rows;
        _loaded = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _error = '$error';
      });
    }
  }

  Future<void> _transition(
    WorkflowInstance instance,
    String transitionId,
  ) async {
    await _store.apply(
      instance: instance,
      transitionId: transitionId,
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  Future<void> _save(WorkflowInstance instance) async {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    await _store.updateFields(
      instance: instance,
      fieldUpdates: {
        for (final field in fields)
          field: _controller(instance.instanceId, field).text,
      },
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Text(_error!, key: ValueKey('soccer-load-error-${widget.tabId}'));
    }
    if (widget.tabId == 'home') return _home(context);
    return Column(
      key: ValueKey('soccer-engine-${widget.tabId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tabId == 'registration') ...[
          _registration(context),
          const SizedBox(height: 12),
          _card(
            context,
            _first('soccer-guardian-join-approval'),
            'Registration reviewer timeline',
            'Current step, missing items, approve/reject for coach and owner',
            Icons.fact_check_outlined,
          ),
        ],
        if (widget.tabId == 'schedule')
          _card(
            context,
            _first('soccer-practice-schedule'),
            'Saturday U10 practice',
            'Date, time, field, opponent, RSVP, attendance, reminders, and calendar sync',
            Icons.calendar_month_outlined,
          ),
        if (widget.tabId == 'team') ...[
          _team(context),
          const SizedBox(height: 12),
          _card(
            context,
            _first('soccer-minor-redaction'),
            'Protected minor detail',
            'Birth date and medical notes are masked outside consent scope',
            Icons.privacy_tip_outlined,
          ),
          const SizedBox(height: 12),
          _card(
            context,
            _first('soccer-waiver-document'),
            'Waiver access from Team',
            'Guardian can reach document state from the protected roster context',
            Icons.description_outlined,
          ),
        ],
        if (widget.tabId == 'payments')
          _card(
            context,
            _first('soccer-registration-payment'),
            'Registration checkout',
            'Fee, receipt, failed payment recovery, refund, and subscription management',
            Icons.payments_outlined,
          ),
        if (widget.tabId == 'documents')
          _card(
            context,
            _first('soccer-waiver-document'),
            '2026 waiver library',
            'Versioned waiver with embedded, external, acknowledgement, and audit trail',
            Icons.description_outlined,
          ),
        if (widget.tabId == 'coach') ...[
          _pin(
            context,
            const ValueKey('soccer-coach-dashboard'),
            'Coach dashboard',
            Icons.dashboard_outlined,
            'Roster, schedule, and reminders for U10 Falcons',
          ),
          const SizedBox(height: 12),
          _card(
            context,
            _first('soccer-team-roster'),
            'Roster operations',
            'Edit, request updates, redact, and undo protected roster fields',
            Icons.groups_outlined,
          ),
          const SizedBox(height: 12),
          _card(
            context,
            _first('soccer-reminder-notification'),
            'Reminder inbox',
            'Draft, schedule, publish, cancel, delivery receipts, and read state',
            Icons.notifications_outlined,
          ),
          const SizedBox(height: 12),
          _card(
            context,
            _first('soccer-practice-schedule'),
            'Schedule controls',
            'Coach can change/cancel practice and send reminders',
            Icons.event_available_outlined,
          ),
        ],
        if (widget.tabId == 'messages')
          _card(
            context,
            _first('soccer-team-discussion'),
            'Team discussion',
            'Guardian and coach thread with reply/archive actions',
            Icons.forum_outlined,
          ),
        if (widget.tabId == 'admin')
          _card(
            context,
            _first('soccer-export-metadata'),
            'Protected export wizard',
            'Scope, minor redaction preview, checksum, transfer, rollback, and retry',
            Icons.ios_share_outlined,
          ),
      ],
    );
  }

  Widget _home(BuildContext context) {
    final schedule = _first('soccer-practice-schedule');
    final payment = _first('soccer-registration-payment');
    final reminder = _first('soccer-reminder-notification');
    return Column(
      key: const ValueKey('soccer-engine-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pin(
          context,
          const ValueKey('soccer-home-schedule'),
          'Next practice',
          Icons.calendar_month_outlined,
          '${schedule?.instanceData['eventTitle'] ?? 'Practice'} - ${schedule?.instanceData['practiceDate'] ?? ''} ${schedule?.instanceData['practiceTime'] ?? ''} at ${schedule?.instanceData['field'] ?? ''}',
        ),
        const SizedBox(height: 12),
        _pin(
          context,
          const ValueKey('soccer-home-privacy'),
          'Privacy protected roster',
          Icons.privacy_tip_outlined,
          'Minor birth dates and medical notes stay masked unless consent and role allow access.',
        ),
        const SizedBox(height: 12),
        _pin(
          context,
          const ValueKey('soccer-home-receipt'),
          'Payment receipt',
          Icons.receipt_long_outlined,
          '${payment?.instanceData['feeLabel'] ?? 'Registration fee'} - ${payment?.instanceData['paymentStatus'] ?? 'Unpaid'}',
        ),
        const SizedBox(height: 12),
        _pin(
          context,
          const ValueKey('soccer-home-reminder'),
          'Reminder status',
          Icons.notifications_outlined,
          '${reminder?.instanceData['message'] ?? 'Practice reminder'} - ${reminder?.instanceData['deliveryState'] ?? 'Draft'}',
        ),
      ],
    );
  }

  Widget _registration(BuildContext context) {
    final instance = _first('soccer-guardian-join-approval');
    if (instance == null) return const SizedBox.shrink();
    const states = ['joinRequest', 'waiver', 'payment', 'roster'];
    const labels = [
      'Join request',
      'Waiver acknowledgement',
      'Registration payment',
      'Roster confirmation',
    ];
    final index = states.indexOf(instance.currentState);
    return DecoratedBox(
      key: const ValueKey('soccer-guided-registration'),
      decoration: _box,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Guardian registration wizard',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              index >= 0
                  ? 'Step ${index + 1} of 4: ${labels[index]}'
                  : 'Step complete: ${instance.currentState}',
              key: const ValueKey('soccer-registration-step-indicator'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < labels.length; i += 1)
                  Chip(
                    key: ValueKey('soccer-step-${states[i]}'),
                    label: Text(labels[i]),
                    backgroundColor: i == (index < 0 ? 3 : index)
                        ? widget.accent.withValues(alpha: 0.16)
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              instance.currentState == 'payment'
                  ? 'Waiver signed; payment is now reachable.'
                  : 'Payment remains gated until waiver is signed.',
              key: const ValueKey('soccer-payment-gate-copy'),
            ),
            _edit(instance),
            const SizedBox(height: 12),
            _actions(instance),
            ..._historyWidgets(instance),
          ],
        ),
      ),
    );
  }

  Widget _team(BuildContext context) {
    final roster = _instances
        .where((instance) => instance.workflowType == 'soccer-team-roster')
        .toList();
    final guardian = widget.persona.personaId == 'guardian';
    return DecoratedBox(
      key: ValueKey(
        guardian ? 'soccer-guardian-roster-card' : 'soccer-coach-roster-table',
      ),
      decoration: _box,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              guardian ? 'My player card' : 'Coach roster table',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            if (guardian)
              for (final instance in roster) ...[
                _rosterLine(instance, redacted: true),
                const SizedBox(height: 8),
                _actions(instance),
              ]
            else ...[
              const Text(
                'Sortable columns: playerName / ageGroup / waiverStatus',
                key: ValueKey('soccer-roster-sortable-columns'),
              ),
              for (final instance in roster) ...[
                _rosterLine(instance, redacted: false),
                const SizedBox(height: 8),
                _actions(instance),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _rosterLine(WorkflowInstance instance, {required bool redacted}) {
    final machine = _store.machineFor(instance.workflowType);
    final redactedFields = instance.instanceData['redactedFields'] is List
        ? (instance.instanceData['redactedFields'] as List)
              .map((item) => '$item')
              .toSet()
        : const <String>{};
    final medicalNotes = redacted
        ? 'Medical notes: protected by consent scope'
        : redactedFields.contains('medicalNotes')
        ? 'Medical notes: redacted (medicalNotes)'
        : 'Medical notes: ${instance.instanceData['medicalNotes'] ?? 'None'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State: ${machine.states[instance.currentState]?.label ?? instance.currentState}',
        ),
        Text(
          '${instance.instanceData['playerName']} - ${instance.instanceData['ageGroup']} - ${instance.instanceData['waiverStatus']}',
          key: ValueKey('soccer-roster-${instance.instanceData['playerName']}'),
        ),
        Text('Guardian persona: ${instance.instanceData['guardianPersonaId']}'),
        Text(
          redacted
              ? 'Birth date: protected by consent scope'
              : 'Birth date: ${instance.instanceData['birthDate']}',
        ),
        Text(medicalNotes),
        if (redactedFields.isNotEmpty)
          Text('Redacted fields: ${redactedFields.join(', ')}'),
        Text('${instance.instanceData['redactionStatus']}'),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    WorkflowInstance? instance,
    String title,
    String subtitle,
    IconData icon,
  ) {
    if (instance == null) {
      return _TabEmptyState(
        icon: icon,
        title: '$title unavailable',
        body: 'No Youth Soccer engine instance is available for this surface.',
        accent: widget.accent,
        modernTheme: widget.modernTheme,
      );
    }
    final machine = _store.machineFor(instance.workflowType);
    return DecoratedBox(
      key: ValueKey(
        'soccer-card-${instance.workflowType}-${instance.instanceId}',
      ),
      decoration: _box,
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
                      'State: ${machine.states[instance.currentState]?.label ?? instance.currentState}',
                  foreground: widget.accent,
                ),
                for (final pill in _pills(machine, instance.instanceData)) pill,
              ],
            ),
            const SizedBox(height: 10),
            for (final key in _displayKeys)
              if (instance.instanceData[key] case final value?) Text('$value'),
            _edit(instance),
            const SizedBox(height: 12),
            _actions(instance),
            ..._historyWidgets(instance),
          ],
        ),
      ),
    );
  }

  static const _displayKeys = [
    'eventTitle',
    'practiceDate',
    'practiceTime',
    'location',
    'field',
    'opponent',
    'calendarSync',
    'rsvpStatus',
    'capacity',
    'attendance',
    'reminderStatus',
    'feeLabel',
    'paymentStatus',
    'receiptId',
    'documentTitle',
    'version',
    'source',
    'acknowledgementState',
    'sender',
    'audience',
    'channel',
    'timestamp',
    'message',
    'threadTitle',
    'lastMessage',
    'scope',
    'redactionPreview',
    'checksum',
    'exportStatus',
    'minorName',
    'birthDateMasked',
    'consentStatus',
    'redactionReason',
    'detailStatus',
    'guardianName',
    'playerName',
    'ageGroup',
    'waiverStatus',
    'currentStep',
    'reviewStatus',
  ];

  Widget _actions(WorkflowInstance instance) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final transition in _store.availableTransitions(
          instance: instance,
          personaId: widget.persona.personaId,
        ))
          OutlinedButton.icon(
            key: ValueKey('soccer-action-${transition.id}'),
            style: _style(transition),
            onPressed: () => _transition(instance, transition.id),
            icon: Icon(_icon(transition.icon)),
            label: Text(transition.label),
          ),
      ],
    );
  }

  Widget _edit(WorkflowInstance instance) {
    final fields = _store.editableFieldsFor(
      workflowType: instance.workflowType,
      state: instance.currentState,
    );
    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in fields)
          TextField(
            key: ValueKey('soccer-edit-$field'),
            controller: _controller(instance.instanceId, field),
            decoration: InputDecoration(labelText: field),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: ValueKey('soccer-save-edit-${instance.workflowType}'),
          onPressed: () => _save(instance),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save edits'),
        ),
      ],
    );
  }

  List<Widget> _pills(
    LoomWorkflowStateMachine machine,
    Map<String, dynamic> data,
  ) {
    return [
      for (final entry in machine.instanceDataSchema.entries)
        if (entry.value.displayIcon != null &&
            !(entry.value.hideWhenEmpty && _empty(data[entry.key])))
          _SurfaceFactPill(
            icon: _fact(entry.value.displayIcon!),
            label: (entry.value.labelTemplate ?? '{value}')
                .replaceAll(
                  '{value.length}',
                  data[entry.key] is List
                      ? '${(data[entry.key] as List).length}'
                      : '0',
                )
                .replaceAll(
                  '{value}',
                  data[entry.key] is List
                      ? (data[entry.key] as List).join(', ')
                      : '${data[entry.key] ?? ''}',
                ),
            foreground: widget.accent,
          ),
    ];
  }

  bool _empty(Object? value) =>
      value == null ||
      value is List && value.isEmpty ||
      value is String && value.isEmpty;

  List<Widget> _historyWidgets(WorkflowInstance instance) {
    final output = <Widget>[];
    for (final entry in instance.instanceData.entries) {
      if (entry.value is List &&
          (entry.key.toLowerCase().contains('history') ||
              entry.key.toLowerCase().contains('messages') ||
              entry.key.toLowerCase().contains('trail') ||
              entry.key.toLowerCase().contains('receipts'))) {
        for (final item in entry.value as List) {
          output.add(
            Text(
              '$item',
              key: ValueKey(
                'soccer-history-${instance.instanceId}-${item.hashCode}',
              ),
            ),
          );
        }
      }
    }
    return output;
  }

  void _sync(List<WorkflowInstance> rows) {
    for (final instance in rows) {
      for (final field in _store.editableFieldsFor(
        workflowType: instance.workflowType,
        state: instance.currentState,
      )) {
        _controller(instance.instanceId, field).text =
            '${instance.instanceData[field] ?? ''}';
      }
    }
  }

  TextEditingController _controller(String instanceId, String field) =>
      _controllers.putIfAbsent(
        '$instanceId::$field',
        TextEditingController.new,
      );

  WorkflowInstance? _first(String type) {
    for (final instance in _instances) {
      if (instance.workflowType == type) return instance;
    }
    return null;
  }

  Widget _pin(
    BuildContext context,
    Key key,
    String title,
    IconData icon,
    String body,
  ) {
    return DecoratedBox(
      key: key,
      decoration: _box,
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

  ButtonStyle _style(LoomWorkflowTransition transition) {
    final destructive = transition.tone == 'destructive';
    final primary = transition.tone == 'primary';
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

  IconData _icon(String? icon) => switch (icon) {
    'send' => Icons.send_outlined,
    'check' => Icons.check_circle_outline,
    'close' => Icons.close_outlined,
    'schedule' => Icons.schedule_outlined,
    'delete' => Icons.delete_outline,
    'edit' => Icons.edit_outlined,
    'report' => Icons.report_problem_outlined,
    'verified' => Icons.verified_outlined,
    'publish' => Icons.publish_outlined,
    'notifications' => Icons.notifications_outlined,
    'groups' => Icons.groups_outlined,
    'download' => Icons.download_outlined,
    'undo' => Icons.undo_outlined,
    'open_in_browser' => Icons.open_in_browser_outlined,
    'open_in_new' => Icons.open_in_new_outlined,
    'reply' => Icons.reply_outlined,
    'payments' => Icons.payments_outlined,
    'privacy_tip' => Icons.privacy_tip_outlined,
    'settings' => Icons.settings_outlined,
    _ => Icons.sports_soccer_outlined,
  };

  IconData _fact(String icon) => switch (icon) {
    'person' => Icons.person_outline,
    'schedule' => Icons.schedule_outlined,
    'location_on' => Icons.location_on_outlined,
    'history' => Icons.history_outlined,
    'flag' => Icons.flag_outlined,
    'event' => Icons.event_outlined,
    'groups' => Icons.groups_outlined,
    'notifications' => Icons.notifications_outlined,
    'description' => Icons.description_outlined,
    'verified' => Icons.verified_outlined,
    'forum' => Icons.forum_outlined,
    'payments' => Icons.payments_outlined,
    'privacy_tip' => Icons.privacy_tip_outlined,
    'report' => Icons.report_problem_outlined,
    'check' => Icons.check_circle_outline,
    'publish' => Icons.publish_outlined,
    'settings' => Icons.settings_outlined,
    'send' => Icons.send_outlined,
    'open_in_new' => Icons.open_in_new_outlined,
    _ => Icons.label_outline,
  };

  BoxDecoration get _box => BoxDecoration(
    color: widget.modernTheme?.resolvedFill ?? Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color:
          widget.modernTheme?.resolvedBorder ??
          widget.accent.withValues(alpha: 0.2),
    ),
  );
}

class _YouthSoccerEngineStore {
  _YouthSoccerEngineStore({required this.communityId});

  final String communityId;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(
    db: _database,
    communityId: communityId,
  );
  _YouthSoccerFixtureBundle? _fixture;
  Future<void>? _readyFuture;
  bool _ready = false;

  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _readyFuture ??= _init();
  }

  Future<void> _init() async {
    _fixture ??= await _YouthSoccerFixtureBundle.load();
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
      query: const SurfaceQuery(sort: SortSpec(key: 'playerName')),
    );
    final allowed = switch (tabId) {
      'registration' => const {'soccer-guardian-join-approval'},
      'schedule' => const {'soccer-practice-schedule'},
      'team' => const {
        'soccer-team-roster',
        'soccer-minor-redaction',
        'soccer-waiver-document',
      },
      'payments' => const {'soccer-registration-payment'},
      'documents' => const {'soccer-waiver-document'},
      'coach' => const {
        'soccer-team-roster',
        'soccer-reminder-notification',
        'soccer-practice-schedule',
      },
      'messages' => const {'soccer-team-discussion'},
      'admin' => const {'soccer-export-metadata'},
      'home' => const {
        'soccer-practice-schedule',
        'soccer-registration-payment',
        'soccer-reminder-notification',
        'soccer-guardian-join-approval',
      },
      _ => const <String>{},
    };
    final rows = page.items
        .where((instance) => allowed.contains(instance.workflowType))
        .where((instance) => _visible(instance, tabId, personaId))
        .toList();
    rows.sort(
      (a, b) => ('${a.instanceData['playerName'] ?? a.workflowType}').compareTo(
        '${b.instanceData['playerName'] ?? b.workflowType}',
      ),
    );
    return rows;
  }

  bool _visible(WorkflowInstance instance, String tabId, String personaId) {
    if (tabId == 'payments') return personaId == 'guardian';
    if (tabId == 'coach') return personaId == 'coach';
    if (tabId == 'admin') return personaId == 'owner';
    if (tabId == 'documents')
      return personaId == 'coach' || personaId == 'guardian';
    if (tabId == 'team' &&
        personaId == 'guardian' &&
        instance.workflowType == 'soccer-team-roster') {
      return instance.instanceData['guardianPersonaId'] == personaId;
    }
    return true;
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
  }) {
    return _engine.updateInstanceFields(
      workflowType: instance.workflowType,
      instanceId: instance.instanceId,
      fieldUpdates: fieldUpdates,
      personaId: personaId,
    );
  }

  LoomWorkflowStateMachine machineFor(String workflowType) =>
      _fixture!.machines[workflowType]!;

  List<String> editableFieldsFor({
    required String workflowType,
    required String state,
  }) {
    return machineFor(workflowType).states[state]?.editableFields ?? const [];
  }
}

class _YouthSoccerFixtureBundle {
  _YouthSoccerFixtureBundle({required this.machines, required this.instances});

  final Map<String, LoomWorkflowStateMachine> machines;
  final List<_GardenSeedInstance> instances;

  static Future<_YouthSoccerFixtureBundle> load() async {
    final json =
        jsonDecode(_stripGardenJsoncComments(_youthSoccerBundledFixtureJsonc))
            as Map<String, dynamic>;
    final defs = json['workflowDefinitions'] as Map<String, dynamic>;
    final machines = <String, LoomWorkflowStateMachine>{};
    for (final entry in defs.entries) {
      machines[entry.key] = LoomWorkflowStateMachine.fromJson(
        _normalizeGardenMachineJson(entry.value as Map<String, dynamic>),
        entry.key,
      );
    }
    final instances = [
      for (final item in json['workflowInstances'] as List<dynamic>)
        _GardenSeedInstance.fromJson(item as Map<String, dynamic>),
    ];
    return _YouthSoccerFixtureBundle(machines: machines, instances: instances);
  }
}

const _youthSoccerBundledFixtureJsonc = r'''
{
  "personas": [
    "guardian",
    "coach",
    "owner"
  ],
  "templates": {
    "dashboard": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "guidedProcess": {
      "steps": [
        "joinRequest",
        "waiver",
        "payment",
        "roster"
      ],
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
    "stateMachineGrid": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "table": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ],
      "columns": [
        {
          "key": "playerName",
          "sortable": true
        },
        {
          "key": "ageGroup",
          "sortable": true
        },
        {
          "key": "waiverStatus",
          "sortable": true
        }
      ]
    },
    "protectedDetail": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "paymentCheckout": {
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
    "notificationInbox": {
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
    },
    "exportWizard": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    }
  },
  "workflowDefinitions": {
    "soccer-guardian-join-approval": {
      "initialState": "joinRequest",
      "states": {
        "joinRequest": {
          "label": "Join request",
          "editableFields": [
            "guardianName",
            "playerName",
            "ageGroup"
          ]
        },
        "waiver": {
          "label": "Waiver required"
        },
        "payment": {
          "label": "Payment required"
        },
        "roster": {
          "label": "Roster confirmation"
        },
        "approved": {
          "label": "Approved",
          "isTerminal": true
        },
        "changesRequested": {
          "label": "Changes requested"
        },
        "rejected": {
          "label": "Rejected",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "submit-join-request",
          "label": "Submit join request",
          "icon": "send",
          "tone": "primary",
          "from": [
            "joinRequest"
          ],
          "to": "waiver",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "currentStep",
              "value": "Waiver acknowledgement"
            },
            {
              "op": "append",
              "key": "registrationHistory",
              "value": "Join request submitted"
            }
          ]
        },
        {
          "id": "sign-waiver",
          "label": "Sign waiver",
          "icon": "verified",
          "tone": "primary",
          "from": [
            "waiver"
          ],
          "to": "payment",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "waiverStatus",
              "value": "Signed"
            },
            {
              "op": "set",
              "key": "currentStep",
              "value": "Registration payment"
            }
          ]
        },
        {
          "id": "confirm-registration-payment",
          "label": "Confirm registration payment",
          "icon": "payments",
          "tone": "primary",
          "from": [
            "payment"
          ],
          "to": "roster",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "paymentStatus",
              "value": "Receipt pending on Payments tab"
            },
            {
              "op": "set",
              "key": "currentStep",
              "value": "Roster confirmation"
            }
          ]
        },
        {
          "id": "confirm-roster",
          "label": "Confirm roster",
          "icon": "check",
          "tone": "primary",
          "from": [
            "roster"
          ],
          "to": "approved",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "rosterStatus",
              "value": "Confirmed"
            },
            {
              "op": "set",
              "key": "currentStep",
              "value": "Approved"
            }
          ]
        },
        {
          "id": "request-changes",
          "label": "Request changes",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "waiver",
            "payment",
            "roster",
            "changesRequested"
          ],
          "to": "changesRequested",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "missingItems",
              "value": [
                "Updated emergency contact"
              ]
            }
          ]
        },
        {
          "id": "approve-registration",
          "label": "Approve registration",
          "icon": "check",
          "tone": "primary",
          "from": [
            "roster",
            "changesRequested"
          ],
          "to": "approved",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "reviewStatus",
              "value": "Approved by club"
            }
          ]
        },
        {
          "id": "reject-registration",
          "label": "Reject registration",
          "icon": "close",
          "tone": "destructive",
          "from": [
            "joinRequest",
            "waiver",
            "payment",
            "roster",
            "changesRequested"
          ],
          "to": "rejected",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "reviewStatus",
              "value": "Rejected by club"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "joinRequest",
            "waiver",
            "payment",
            "roster",
            "approved",
            "changesRequested"
          ],
          "role": "actor",
          "tabId": "registration",
          "cardSurfaceFamily": "guidedProcess",
          "bindingKind": "primary"
        },
        {
          "states": [
            "joinRequest",
            "waiver",
            "payment",
            "roster",
            "approved",
            "changesRequested",
            "rejected"
          ],
          "role": "receiver",
          "tabId": "registration",
          "cardSurfaceFamily": "statusTimeline",
          "bindingKind": "summary"
        },
        {
          "states": [
            "joinRequest",
            "waiver",
            "payment",
            "roster",
            "approved"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "guardianName": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Guardian: {value}"
        },
        "playerName": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Player: {value}"
        },
        "ageGroup": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "groups",
          "labelTemplate": "{value}"
        },
        "currentStep": {
          "type": "text",
          "displayIcon": "flag",
          "labelTemplate": "Step: {value}"
        },
        "waiverStatus": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "Waiver: {value}"
        },
        "paymentStatus": {
          "type": "text",
          "displayIcon": "payments",
          "labelTemplate": "Payment: {value}"
        },
        "rosterStatus": {
          "type": "text",
          "displayIcon": "groups",
          "labelTemplate": "Roster: {value}"
        },
        "missingItems": {
          "type": "list",
          "displayIcon": "report",
          "labelTemplate": "Missing: {value.length}",
          "hideWhenEmpty": true
        },
        "registrationHistory": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "history",
          "labelTemplate": "Updates: {value.length}",
          "hideWhenEmpty": true
        },
        "reviewStatus": {
          "type": "text",
          "displayIcon": "verified",
          "labelTemplate": "{value}"
        },
        "guardianPersonaId": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Guardian persona: {value}"
        }
      }
    },
    "soccer-practice-schedule": {
      "initialState": "scheduled",
      "states": {
        "scheduled": {
          "label": "Scheduled"
        },
        "going": {
          "label": "Going"
        },
        "maybe": {
          "label": "Maybe"
        },
        "notGoing": {
          "label": "Not going"
        },
        "changed": {
          "label": "Changed"
        },
        "cancelled": {
          "label": "Cancelled",
          "isTerminal": true
        },
        "reminded": {
          "label": "Reminder sent"
        }
      },
      "transitions": [
        {
          "id": "rsvp-going",
          "label": "RSVP going",
          "icon": "check",
          "tone": "primary",
          "from": [
            "scheduled",
            "maybe",
            "notGoing",
            "changed",
            "reminded"
          ],
          "to": "going",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "rsvpStatus",
              "value": "Going"
            }
          ]
        },
        {
          "id": "rsvp-maybe",
          "label": "RSVP maybe",
          "icon": "schedule",
          "tone": "secondary",
          "from": [
            "scheduled",
            "going",
            "notGoing",
            "changed",
            "reminded"
          ],
          "to": "maybe",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "rsvpStatus",
              "value": "Maybe"
            }
          ]
        },
        {
          "id": "rsvp-not-going",
          "label": "RSVP not going",
          "icon": "close",
          "tone": "secondary",
          "from": [
            "scheduled",
            "going",
            "maybe",
            "changed",
            "reminded"
          ],
          "to": "notGoing",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "rsvpStatus",
              "value": "Not going"
            }
          ]
        },
        {
          "id": "change-practice",
          "label": "Change practice",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "scheduled",
            "going",
            "maybe",
            "notGoing",
            "reminded"
          ],
          "to": "changed",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "practiceTime",
              "value": "Saturday 10:00 AM"
            }
          ]
        },
        {
          "id": "cancel-practice",
          "label": "Cancel practice",
          "icon": "delete",
          "tone": "destructive",
          "from": [
            "scheduled",
            "going",
            "maybe",
            "notGoing",
            "changed",
            "reminded"
          ],
          "to": "cancelled",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "scheduleHistory",
              "value": "Coach cancelled practice"
            }
          ]
        },
        {
          "id": "send-schedule-reminder",
          "label": "Send schedule reminder",
          "icon": "notifications",
          "tone": "primary",
          "from": [
            "scheduled",
            "going",
            "maybe",
            "notGoing",
            "changed"
          ],
          "to": "reminded",
          "guard": {
            "allowedPersonaIds": [
              "coach"
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
            "going",
            "maybe",
            "notGoing",
            "changed",
            "cancelled",
            "reminded"
          ],
          "role": "any",
          "tabId": "schedule",
          "cardSurfaceFamily": "calendarAgenda",
          "bindingKind": "primary"
        },
        {
          "states": [
            "scheduled",
            "changed",
            "reminded"
          ],
          "role": "actor",
          "tabId": "coach",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        },
        {
          "states": [
            "scheduled",
            "going",
            "maybe",
            "notGoing",
            "changed",
            "reminded"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "eventTitle": {
          "type": "text",
          "displayIcon": "event",
          "labelTemplate": "{value}"
        },
        "practiceDate": {
          "type": "text",
          "displayIcon": "event",
          "labelTemplate": "{value}"
        },
        "practiceTime": {
          "type": "text",
          "displayIcon": "schedule",
          "labelTemplate": "{value}"
        },
        "location": {
          "type": "text",
          "displayIcon": "location_on",
          "labelTemplate": "{value}"
        },
        "field": {
          "type": "text",
          "displayIcon": "flag",
          "labelTemplate": "Field: {value}"
        },
        "opponent": {
          "type": "text",
          "displayIcon": "groups",
          "labelTemplate": "Opponent: {value}"
        },
        "calendarSync": {
          "type": "text",
          "displayIcon": "event_available",
          "labelTemplate": "Calendar: {value}"
        },
        "rsvpStatus": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "RSVP: {value}"
        },
        "capacity": {
          "type": "number",
          "displayIcon": "groups",
          "labelTemplate": "Capacity {value}"
        },
        "attendance": {
          "type": "number",
          "displayIcon": "person",
          "labelTemplate": "Attendance {value}"
        },
        "reminderStatus": {
          "type": "text",
          "displayIcon": "notifications",
          "labelTemplate": "{value}"
        },
        "scheduleHistory": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "history",
          "labelTemplate": "Schedule updates: {value.length}",
          "hideWhenEmpty": true
        }
      }
    },
    "soccer-team-roster": {
      "initialState": "active",
      "states": {
        "active": {
          "label": "Active roster",
          "editableFields": [
            "playerName",
            "ageGroup",
            "waiverStatus"
          ]
        },
        "editing": {
          "label": "Editing"
        },
        "updateRequested": {
          "label": "Update requested"
        },
        "redacted": {
          "label": "Redacted"
        }
      },
      "transitions": [
        {
          "id": "edit-player",
          "label": "Edit player",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "active",
            "updateRequested",
            "redacted"
          ],
          "to": "editing",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "rosterHistory",
              "value": "Coach opened roster edit"
            }
          ]
        },
        {
          "id": "request-update",
          "label": "Request guardian update",
          "icon": "send",
          "tone": "secondary",
          "from": [
            "active",
            "editing",
            "redacted"
          ],
          "to": "updateRequested",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "rosterHistory",
              "value": "Update requested"
            }
          ]
        },
        {
          "id": "redact-field",
          "label": "Redact protected field",
          "icon": "delete",
          "tone": "destructive",
          "from": [
            "active",
            "editing",
            "updateRequested"
          ],
          "to": "redacted",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "redactionStatus",
              "value": "Minor medical note hidden for role scope"
            },
            {
              "op": "append",
              "key": "redactedFields",
              "value": "medicalNotes"
            }
          ]
        },
        {
          "id": "undo-redaction",
          "label": "Undo redaction",
          "icon": "undo",
          "tone": "secondary",
          "from": [
            "redacted"
          ],
          "to": "active",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "redactionStatus",
              "value": "Role-appropriate detail restored"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "active",
            "editing",
            "updateRequested",
            "redacted"
          ],
          "role": "guardian",
          "tabId": "team",
          "cardSurfaceFamily": "stateMachineGrid",
          "bindingKind": "primary"
        },
        {
          "states": [
            "active",
            "editing",
            "updateRequested",
            "redacted"
          ],
          "role": "coach",
          "tabId": "team",
          "cardSurfaceFamily": "table",
          "bindingKind": "primary"
        },
        {
          "states": [
            "active",
            "editing",
            "updateRequested",
            "redacted"
          ],
          "role": "any",
          "tabId": "team",
          "cardSurfaceFamily": "protectedDetail",
          "bindingKind": "summary"
        },
        {
          "states": [
            "active",
            "editing",
            "updateRequested",
            "redacted"
          ],
          "role": "coach",
          "tabId": "coach",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "playerName": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "sortable": true,
          "displayIcon": "person",
          "labelTemplate": "Player: {value}"
        },
        "ageGroup": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "sortable": true,
          "displayIcon": "groups",
          "labelTemplate": "{value}"
        },
        "waiverStatus": {
          "type": "text",
          "writableBy": "formEntry",
          "sortable": true,
          "displayIcon": "description",
          "labelTemplate": "Waiver: {value}"
        },
        "guardianName": {
          "type": "text",
          "displayIcon": "person",
          "labelTemplate": "Guardian: {value}"
        },
        "birthDate": {
          "type": "text",
          "displayIcon": "verified",
          "labelTemplate": "DOB: {value}"
        },
        "medicalNotes": {
          "type": "text",
          "displayIcon": "report",
          "labelTemplate": "Medical: {value}"
        },
        "redactionStatus": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "redactedFields": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "privacy_tip",
          "labelTemplate": "Redacted fields: {value.length}",
          "hideWhenEmpty": true
        },
        "rosterHistory": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "history",
          "labelTemplate": "Roster updates: {value.length}",
          "hideWhenEmpty": true
        },
        "guardianPersonaId": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Guardian persona: {value}",
          "sortable": true
        }
      }
    },
    "soccer-minor-redaction": {
      "initialState": "redacted",
      "states": {
        "redacted": {
          "label": "Protected detail"
        },
        "accessRequested": {
          "label": "Access requested"
        },
        "visible": {
          "label": "Consent scoped"
        }
      },
      "transitions": [
        {
          "id": "request-access",
          "label": "Request access",
          "icon": "send",
          "tone": "secondary",
          "from": [
            "redacted"
          ],
          "to": "accessRequested",
          "guard": {
            "allowedPersonaIds": [
              "guardian",
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "auditTrail",
              "value": "Access request logged"
            }
          ]
        },
        {
          "id": "redact-detail",
          "label": "Redact detail",
          "icon": "delete",
          "tone": "destructive",
          "from": [
            "visible",
            "accessRequested"
          ],
          "to": "redacted",
          "guard": {
            "allowedPersonaIds": [
              "coach",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "detailStatus",
              "value": "Redacted for minor privacy"
            }
          ]
        },
        {
          "id": "restore-detail",
          "label": "Restore consent view",
          "icon": "undo",
          "tone": "secondary",
          "from": [
            "redacted",
            "accessRequested"
          ],
          "to": "visible",
          "guard": {
            "allowedPersonaIds": [
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "detailStatus",
              "value": "Consent scoped view restored"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "redacted",
            "accessRequested",
            "visible"
          ],
          "role": "any",
          "tabId": "team",
          "cardSurfaceFamily": "protectedDetail",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "minorName": {
          "type": "text",
          "displayIcon": "person",
          "labelTemplate": "Minor: {value}"
        },
        "birthDateMasked": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "Birth date: {value}"
        },
        "consentStatus": {
          "type": "text",
          "displayIcon": "verified",
          "labelTemplate": "Consent: {value}"
        },
        "redactionReason": {
          "type": "text",
          "displayIcon": "report",
          "labelTemplate": "{value}"
        },
        "detailStatus": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "auditTrail": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "history",
          "labelTemplate": "Audit events: {value.length}",
          "hideWhenEmpty": true
        }
      }
    },
    "soccer-registration-payment": {
      "initialState": "unpaid",
      "states": {
        "unpaid": {
          "label": "Unpaid"
        },
        "paid": {
          "label": "Paid"
        },
        "failed": {
          "label": "Failed"
        },
        "refunded": {
          "label": "Refunded"
        },
        "subscriptionManaged": {
          "label": "Subscription managed",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "pay-registration",
          "label": "Pay registration",
          "icon": "payments",
          "tone": "primary",
          "from": [
            "unpaid",
            "failed"
          ],
          "to": "paid",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "paymentStatus",
              "value": "Paid"
            },
            {
              "op": "set",
              "key": "receiptId",
              "value": "RYS-2026-0042"
            },
            {
              "op": "append",
              "key": "receiptHistory",
              "value": "Receipt RYS-2026-0042 issued"
            }
          ]
        },
        {
          "id": "mark-payment-failed",
          "label": "Mark failed",
          "icon": "report",
          "tone": "secondary",
          "from": [
            "unpaid"
          ],
          "to": "failed",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "paymentStatus",
              "value": "Failed"
            }
          ]
        },
        {
          "id": "retry-payment",
          "label": "Retry payment",
          "icon": "undo",
          "tone": "primary",
          "from": [
            "failed"
          ],
          "to": "paid",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "paymentStatus",
              "value": "Paid after retry"
            }
          ]
        },
        {
          "id": "refund-payment",
          "label": "Refund payment",
          "icon": "undo",
          "tone": "secondary",
          "from": [
            "paid"
          ],
          "to": "refunded",
          "guard": {
            "allowedPersonaIds": [
              "guardian",
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "paymentStatus",
              "value": "Refunded"
            }
          ]
        },
        {
          "id": "manage-subscription",
          "label": "Manage subscription",
          "icon": "settings",
          "tone": "secondary",
          "from": [
            "paid",
            "refunded",
            "unpaid"
          ],
          "to": "subscriptionManaged",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "subscriptionStatus",
              "value": "Managed in Loom payments"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "unpaid",
            "paid",
            "failed",
            "refunded",
            "subscriptionManaged"
          ],
          "role": "actor",
          "tabId": "payments",
          "cardSurfaceFamily": "paymentCheckout",
          "bindingKind": "primary"
        },
        {
          "states": [
            "unpaid",
            "paid",
            "failed"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "feeLabel": {
          "type": "text",
          "displayIcon": "payments",
          "labelTemplate": "{value}"
        },
        "amount": {
          "type": "number",
          "displayIcon": "payments",
          "labelTemplate": "{value} USD"
        },
        "paymentStatus": {
          "type": "text",
          "displayIcon": "verified",
          "labelTemplate": "Status: {value}"
        },
        "receiptId": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "Receipt: {value}"
        },
        "receiptHistory": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "history",
          "labelTemplate": "Receipts: {value.length}",
          "hideWhenEmpty": true
        },
        "subscriptionStatus": {
          "type": "text",
          "displayIcon": "settings",
          "labelTemplate": "{value}"
        }
      }
    },
    "soccer-waiver-document": {
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
        "acknowledged": {
          "label": "Acknowledged",
          "isTerminal": true
        },
        "accessRequested": {
          "label": "Access requested"
        }
      },
      "transitions": [
        {
          "id": "open-embedded-waiver",
          "label": "Open embedded waiver",
          "icon": "open_in_browser",
          "tone": "secondary",
          "from": [
            "available",
            "externalOpened",
            "accessRequested"
          ],
          "to": "embeddedOpened",
          "guard": {
            "allowedPersonaIds": [
              "guardian",
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "auditTrail",
              "value": "Embedded waiver opened"
            }
          ]
        },
        {
          "id": "open-external-waiver",
          "label": "Open external waiver",
          "icon": "open_in_new",
          "tone": "secondary",
          "from": [
            "available",
            "embeddedOpened",
            "accessRequested"
          ],
          "to": "externalOpened",
          "guard": {
            "allowedPersonaIds": [
              "guardian",
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "auditTrail",
              "value": "External source opened"
            }
          ]
        },
        {
          "id": "acknowledge-waiver-document",
          "label": "Acknowledge waiver",
          "icon": "check",
          "tone": "primary",
          "from": [
            "embeddedOpened",
            "externalOpened"
          ],
          "to": "acknowledged",
          "guard": {
            "allowedPersonaIds": [
              "guardian",
              "coach"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "acknowledgementState",
              "value": "Acknowledged"
            }
          ]
        },
        {
          "id": "request-document-access",
          "label": "Request document access",
          "icon": "send",
          "tone": "secondary",
          "from": [
            "available"
          ],
          "to": "accessRequested",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "auditTrail",
              "value": "Guardian requested document access"
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
            "acknowledged",
            "accessRequested"
          ],
          "role": "any",
          "tabId": "documents",
          "cardSurfaceFamily": "documentLibrary",
          "bindingKind": "primary"
        },
        {
          "states": [
            "available",
            "embeddedOpened",
            "externalOpened",
            "acknowledged",
            "accessRequested"
          ],
          "role": "any",
          "tabId": "team",
          "cardSurfaceFamily": "documentLibrary",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "documentTitle": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "version": {
          "type": "text",
          "displayIcon": "flag",
          "labelTemplate": "Version {value}"
        },
        "source": {
          "type": "text",
          "displayIcon": "open_in_new",
          "labelTemplate": "Source: {value}"
        },
        "acknowledgementState": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "{value}"
        },
        "auditTrail": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "history",
          "labelTemplate": "Audit trail: {value.length}",
          "hideWhenEmpty": true
        }
      }
    },
    "soccer-reminder-notification": {
      "initialState": "draft",
      "states": {
        "draft": {
          "label": "Draft"
        },
        "scheduled": {
          "label": "Scheduled"
        },
        "published": {
          "label": "Published"
        },
        "read": {
          "label": "Read",
          "isTerminal": true
        },
        "cancelled": {
          "label": "Cancelled",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "schedule-reminder",
          "label": "Schedule reminder",
          "icon": "schedule",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "scheduled",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "deliveryState",
              "value": "Scheduled"
            }
          ]
        },
        {
          "id": "publish-reminder",
          "label": "Publish reminder",
          "icon": "publish",
          "tone": "primary",
          "from": [
            "draft",
            "scheduled"
          ],
          "to": "published",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "deliveryState",
              "value": "Published"
            },
            {
              "op": "append",
              "key": "deliveryReceipts",
              "value": "18 guardians delivered"
            }
          ]
        },
        {
          "id": "cancel-reminder",
          "label": "Cancel reminder",
          "icon": "delete",
          "tone": "destructive",
          "from": [
            "draft",
            "scheduled"
          ],
          "to": "cancelled",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "deliveryState",
              "value": "Cancelled"
            }
          ]
        },
        {
          "id": "mark-reminder-read",
          "label": "Mark read",
          "icon": "check",
          "tone": "secondary",
          "from": [
            "published"
          ],
          "to": "read",
          "guard": {
            "allowedPersonaIds": [
              "guardian"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "readState",
              "value": "Read by guardian"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft",
            "scheduled",
            "published",
            "read",
            "cancelled"
          ],
          "role": "coach",
          "tabId": "coach",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        },
        {
          "states": [
            "published",
            "read"
          ],
          "role": "guardian",
          "tabId": "home",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "sender": {
          "type": "text",
          "displayIcon": "person",
          "labelTemplate": "Sender: {value}"
        },
        "audience": {
          "type": "text",
          "displayIcon": "groups",
          "labelTemplate": "Audience: {value}"
        },
        "channel": {
          "type": "text",
          "displayIcon": "notifications",
          "labelTemplate": "Channel: {value}"
        },
        "timestamp": {
          "type": "text",
          "displayIcon": "schedule",
          "labelTemplate": "{value}"
        },
        "readState": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "{value}"
        },
        "deliveryState": {
          "type": "text",
          "displayIcon": "publish",
          "labelTemplate": "{value}"
        },
        "deliveryReceipts": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "verified",
          "labelTemplate": "Receipts: {value.length}",
          "hideWhenEmpty": true
        },
        "message": {
          "type": "text",
          "displayIcon": "forum",
          "labelTemplate": "{value}"
        }
      }
    },
    "soccer-team-discussion": {
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
              "guardian",
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "messages",
              "value": "Reply added"
            }
          ]
        },
        {
          "id": "archive-thread",
          "label": "Archive thread",
          "icon": "delete",
          "tone": "secondary",
          "from": [
            "open",
            "replied"
          ],
          "to": "archived",
          "guard": {
            "allowedPersonaIds": [
              "coach"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "messages",
              "value": "Coach archived thread"
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
          "displayIcon": "forum",
          "labelTemplate": "{value}"
        },
        "lastMessage": {
          "type": "text",
          "displayIcon": "reply",
          "labelTemplate": "{value}"
        },
        "messages": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "forum",
          "labelTemplate": "Messages: {value.length}",
          "hideWhenEmpty": true
        }
      }
    },
    "soccer-export-metadata": {
      "initialState": "ready",
      "states": {
        "ready": {
          "label": "Ready"
        },
        "previewed": {
          "label": "Previewed"
        },
        "generated": {
          "label": "Generated"
        },
        "transferred": {
          "label": "Transferred"
        },
        "rolledBack": {
          "label": "Rolled back"
        },
        "retried": {
          "label": "Retried"
        }
      },
      "transitions": [
        {
          "id": "preview-redaction",
          "label": "Preview redaction",
          "icon": "privacy_tip",
          "tone": "primary",
          "from": [
            "ready"
          ],
          "to": "previewed",
          "guard": {
            "allowedPersonaIds": [
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "redactionPreview",
              "value": "Minor birth dates and medical notes masked"
            }
          ]
        },
        {
          "id": "generate-export",
          "label": "Generate export",
          "icon": "download",
          "tone": "primary",
          "from": [
            "previewed"
          ],
          "to": "generated",
          "guard": {
            "allowedPersonaIds": [
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "checksum",
              "value": "sha256-rys-77a9"
            }
          ]
        },
        {
          "id": "transfer-export",
          "label": "Transfer export",
          "icon": "send",
          "tone": "primary",
          "from": [
            "generated",
            "retried"
          ],
          "to": "transferred",
          "guard": {
            "allowedPersonaIds": [
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "exportStatus",
              "value": "Transferred"
            }
          ]
        },
        {
          "id": "rollback-transfer",
          "label": "Rollback transfer",
          "icon": "undo",
          "tone": "secondary",
          "from": [
            "transferred"
          ],
          "to": "rolledBack",
          "guard": {
            "allowedPersonaIds": [
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "exportStatus",
              "value": "Rolled back"
            }
          ]
        },
        {
          "id": "retry-transfer",
          "label": "Retry transfer",
          "icon": "undo",
          "tone": "primary",
          "from": [
            "rolledBack"
          ],
          "to": "retried",
          "guard": {
            "allowedPersonaIds": [
              "owner"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "exportStatus",
              "value": "Retry queued"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "ready",
            "previewed",
            "generated",
            "transferred",
            "rolledBack",
            "retried"
          ],
          "role": "actor",
          "tabId": "admin",
          "cardSurfaceFamily": "exportWizard",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "scope": {
          "type": "text",
          "displayIcon": "flag",
          "labelTemplate": "Scope: {value}"
        },
        "redactionPreview": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "checksum": {
          "type": "text",
          "displayIcon": "verified",
          "labelTemplate": "{value}"
        },
        "exportStatus": {
          "type": "text",
          "displayIcon": "send",
          "labelTemplate": "{value}"
        }
      }
    }
  },
  "workflowInstances": [
    {
      "instanceId": "soccer-registration-main",
      "workflowType": "soccer-guardian-join-approval",
      "currentState": "joinRequest",
      "createdByPersonaId": "guardian",
      "instanceData": {
        "guardianName": "Elena Rivera",
        "playerName": "Sofia Rivera",
        "ageGroup": "U10 Falcons",
        "currentStep": "Join request",
        "waiverStatus": "Unsigned",
        "paymentStatus": "Not started",
        "rosterStatus": "Pending",
        "missingItems": [],
        "registrationHistory": [],
        "reviewStatus": "Awaiting reviewer",
        "guardianPersonaId": "guardian"
      }
    },
    {
      "instanceId": "soccer-practice-saturday",
      "workflowType": "soccer-practice-schedule",
      "currentState": "scheduled",
      "createdByPersonaId": "coach",
      "instanceData": {
        "eventTitle": "Saturday U10 practice",
        "practiceDate": "Sat Jul 18",
        "practiceTime": "Saturday 9:00 AM",
        "location": "Riverside Park",
        "field": "Field 3",
        "opponent": "No opponent - practice",
        "calendarSync": "Synced",
        "rsvpStatus": "Not answered",
        "capacity": 18,
        "attendance": 12,
        "reminderStatus": "Ready",
        "scheduleHistory": []
      }
    },
    {
      "instanceId": "soccer-roster-sofia",
      "workflowType": "soccer-team-roster",
      "currentState": "active",
      "createdByPersonaId": "coach",
      "instanceData": {
        "playerName": "Sofia Rivera",
        "ageGroup": "U10",
        "waiverStatus": "Unsigned",
        "guardianName": "Elena Rivera",
        "birthDate": "2016-04-12",
        "medicalNotes": "Inhaler on file",
        "redactionStatus": "Guardian sees own child; coach sees role-appropriate fields",
        "redactedFields": [],
        "rosterHistory": [],
        "guardianPersonaId": "guardian"
      }
    },
    {
      "instanceId": "soccer-roster-ari",
      "workflowType": "soccer-team-roster",
      "currentState": "active",
      "createdByPersonaId": "coach",
      "instanceData": {
        "playerName": "Ari Rivera",
        "ageGroup": "U12",
        "waiverStatus": "Signed",
        "guardianName": "Elena Rivera",
        "guardianPersonaId": "guardian",
        "birthDate": "2014-03-18",
        "medicalNotes": "No restrictions",
        "redactionStatus": "Guardian-linked roster row visible by relationship",
        "redactedFields": [],
        "rosterHistory": []
      }
    },
    {
      "instanceId": "soccer-roster-miles",
      "workflowType": "soccer-team-roster",
      "currentState": "active",
      "createdByPersonaId": "coach",
      "instanceData": {
        "playerName": "Miles Chen",
        "ageGroup": "U10",
        "waiverStatus": "Signed",
        "guardianName": "Tara Chen",
        "birthDate": "2016-08-03",
        "medicalNotes": "Protected",
        "redactionStatus": "Role-appropriate detail only",
        "redactedFields": [
          "medicalNotes"
        ],
        "rosterHistory": [],
        "guardianPersonaId": "guardian-chen"
      }
    },
    {
      "instanceId": "soccer-minor-detail",
      "workflowType": "soccer-minor-redaction",
      "currentState": "redacted",
      "createdByPersonaId": "coach",
      "instanceData": {
        "minorName": "Sofia Rivera",
        "birthDateMasked": "2***",
        "consentStatus": "Guardian consent active for roster only",
        "redactionReason": "Birth date and medical notes masked outside consent scope",
        "detailStatus": "Redacted for minor privacy",
        "auditTrail": []
      }
    },
    {
      "instanceId": "soccer-payment-registration",
      "workflowType": "soccer-registration-payment",
      "currentState": "unpaid",
      "createdByPersonaId": "guardian",
      "instanceData": {
        "feeLabel": "Registration fee $125.00",
        "amount": 125,
        "paymentStatus": "Unpaid",
        "receiptId": "Pending",
        "receiptHistory": [],
        "subscriptionStatus": "Not managed"
      }
    },
    {
      "instanceId": "soccer-waiver-2026",
      "workflowType": "soccer-waiver-document",
      "currentState": "available",
      "createdByPersonaId": "coach",
      "instanceData": {
        "documentTitle": "2026 Youth Sports Waiver",
        "version": "v3",
        "source": "Riverside Parks PDF",
        "acknowledgementState": "Not acknowledged",
        "auditTrail": []
      }
    },
    {
      "instanceId": "soccer-reminder-practice",
      "workflowType": "soccer-reminder-notification",
      "currentState": "draft",
      "createdByPersonaId": "coach",
      "instanceData": {
        "sender": "Coach Morgan",
        "audience": "U10 guardians",
        "channel": "Push + email",
        "timestamp": "Draft for Fri 6 PM",
        "readState": "Unread",
        "deliveryState": "Draft",
        "deliveryReceipts": [],
        "message": "Practice starts at 9 AM"
      }
    },
    {
      "instanceId": "soccer-thread-weekend",
      "workflowType": "soccer-team-discussion",
      "currentState": "open",
      "createdByPersonaId": "guardian",
      "instanceData": {
        "threadTitle": "Weekend snack rotation",
        "lastMessage": "Can anyone swap snack duty?",
        "messages": [
          "Elena: Can anyone swap snack duty?"
        ]
      }
    },
    {
      "instanceId": "soccer-export-2026",
      "workflowType": "soccer-export-metadata",
      "currentState": "ready",
      "createdByPersonaId": "owner",
      "instanceData": {
        "scope": "Registration, roster, payments, waivers",
        "redactionPreview": "Minor fields masked before transfer",
        "checksum": "Pending",
        "exportStatus": "Ready"
      }
    }
  ]
}
''';
