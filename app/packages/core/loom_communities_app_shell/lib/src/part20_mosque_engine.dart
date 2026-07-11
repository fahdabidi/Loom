part of '../loom_communities_app_shell.dart';

class _MosqueEngineTabSurface extends StatefulWidget {
  const _MosqueEngineTabSurface({
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
  State<_MosqueEngineTabSurface> createState() => _MosqueEngineTabSurfaceState();
}

class _MosqueEngineTabSurfaceState extends State<_MosqueEngineTabSurface> {
  static final _stores = <String, _MosqueEngineStore>{};
  late final _MosqueEngineStore _store;
  final _controllers = <String, TextEditingController>{};
  List<WorkflowInstance> _instances = const [];
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = _stores.putIfAbsent(
      widget.experience.extensionId,
      () => _MosqueEngineStore(communityId: widget.experience.extensionId),
    );
    if (widget.tabId != 'home') {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(_MosqueEngineTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.persona.personaId != widget.persona.personaId ||
        oldWidget.tabId != widget.tabId) {
      if (widget.tabId != 'home') {
        unawaited(_load());
      }
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

  Future<void> _transition(WorkflowInstance instance, String transitionId) async {
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
          field: _fieldValue(field, _controller(instance.instanceId, field).text),
      },
      personaId: widget.persona.personaId,
    );
    await _load();
  }

  Object _fieldValue(String field, String value) {
    if (field == 'invitedPersonaIds' || field == 'privateFieldKeys') {
      return value
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
    }
    if (field == 'capacity') return int.tryParse(value) ?? value;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabId == 'home') return _home(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Text(_error!, key: ValueKey('mosque-load-error-${widget.tabId}'));
    }
    return Column(
      key: ValueKey('mosque-engine-${widget.tabId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tabId == 'calendar') ..._calendar(context),
        if (widget.tabId == 'giving') ..._cards(context, [
          ['mosque-donation-payment', 'Donation checkout', 'Amount, fund, privacy indicator, receipt, recurring controls', Icons.payments_outlined],
          ['mosque-donor-visibility', 'Donor visibility preference', 'Public, anonymous, or restricted preference outlives a single donation', Icons.privacy_tip_outlined],
        ]),
        if (widget.tabId == 'care') ..._care(context),
        if (widget.tabId == 'admin') ..._cards(context, [
          ['mosque-announcement', 'Announcement composer', 'Body, audience, schedule, sent/read tracking', Icons.campaign_outlined],
          ['mosque-volunteer-signup', 'Volunteer roster', 'Open spots, signed-up roster, protected contact, open/close/contact actions', Icons.volunteer_activism_outlined],
          ['mosque-care-request', 'Care review queue', 'Protected care detail, assignment, response, and close actions', Icons.health_and_safety_outlined],
        ]),
        if (widget.tabId == 'messages') ..._cards(context, [
          ['mosque-discussion-thread', 'Community discussion', 'Discussion thread for logistics and member questions', Icons.forum_outlined],
          ['mosque-neutral-notification', 'Neutral care notification', 'Privacy-safe notice that does not leak protected care details', Icons.notifications_outlined],
          ['mosque-announcement', 'Announcement inbox', 'Member-safe announcement receive/read card', Icons.mark_email_read_outlined],
        ]),
        if (widget.tabId == 'search') ..._cards(context, [
          ['mosque-search-ai-citation', 'Iftar search answer', 'Permission-guarded citations with refine, hide-source, and report stale actions', Icons.search_outlined],
        ]),
      ],
    );
  }

  List<Widget> _calendar(BuildContext context) {
    if (widget.persona.personaId == 'mosque-admin') {
      return [
        _card(
          context,
          _first('mosque-event-rsvp'),
          'Event creation form',
          'Admin-only formEntry with audienceSelector: all, selected-many, or individual',
          Icons.event_outlined,
        ),
      ];
    }
    return _cards(context, [
      ['mosque-event-rsvp', 'Friday service and iftar', 'Member agenda/RSVP card resolved by audienceMemberField', Icons.calendar_month_outlined],
    ]);
  }

  List<Widget> _care(BuildContext context) {
    return _cards(context, [
      ['mosque-care-request', 'Care request', 'Member form and protectedDetail review with field-level private flags', Icons.health_and_safety_outlined],
      if (widget.persona.personaId == 'mosque-member')
        ['mosque-volunteer-signup', 'Volunteer signup', 'Member signup, edit, and cancel surface outside Admin', Icons.volunteer_activism_outlined],
    ]);
  }

  List<Widget> _cards(BuildContext context, List<List<Object>> specs) {
    return [
      for (var i = 0; i < specs.length; i += 1) ...[
        if (i > 0) const SizedBox(height: 12),
        _card(
          context,
          _first(specs[i][0] as String),
          specs[i][1] as String,
          specs[i][2] as String,
          specs[i][3] as IconData,
        ),
      ],
    ];
  }

  Widget _home(BuildContext context) {
    final admin = widget.persona.personaId == 'mosque-admin';
    return Column(
      key: const ValueKey('mosque-engine-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (admin) ...[
          _pin(context, const ValueKey('mosque-home-composer'), 'Announcement composer', Icons.campaign_outlined, 'Draft Ramadan update ready for preview, schedule, or publish.'),
          const SizedBox(height: 12),
          _pin(context, const ValueKey('mosque-home-volunteers'), 'Volunteer roster', Icons.volunteer_activism_outlined, 'Iftar setup: 2 filled, 4 open spots, protected contact gated.'),
          const SizedBox(height: 12),
          _pin(context, const ValueKey('mosque-home-care-review'), 'Care review', Icons.health_and_safety_outlined, 'Care requests show public summary unless assigned reviewer unlocks private fields.'),
        ] else ...[
          _pin(context, const ValueKey('mosque-home-event'), 'Friday service and iftar', Icons.calendar_month_outlined, 'Friday 7:00 PM at Masjid Nur Hall. RSVP from Calendar.'),
          const SizedBox(height: 12),
          _pin(context, const ValueKey('mosque-home-donation'), 'Donation receipt', Icons.receipt_long_outlined, 'Iftar meals donation receipt respects donor visibility preference.'),
          const SizedBox(height: 12),
          _pin(context, const ValueKey('mosque-home-care-status'), 'Care request status', Icons.health_and_safety_outlined, 'Private details stay masked outside the assigned reviewer.'),
        ],
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
        body: 'No engine-backed Mosque instance is available for this tab.',
        accent: widget.accent,
        modernTheme: widget.modernTheme,
      );
    }
    final machine = _store.machineFor(instance.workflowType);
    return DecoratedBox(
      key: ValueKey('mosque-card-${instance.workflowType}-${instance.instanceId}'),
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
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
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
                _SurfaceFactPill(icon: Icons.flag_outlined, label: 'State: ${machine.states[instance.currentState]?.label ?? instance.currentState}', foreground: widget.accent),
                for (final pill in _pills(machine, instance.instanceData)) pill,
              ],
            ),
            const SizedBox(height: 10),
            if (instance.workflowType == 'mosque-care-request') _careDetail(instance) else _dataLines(instance),
            _edit(instance),
            const SizedBox(height: 12),
            _actions(instance),
          ],
        ),
      ),
    );
  }

  Widget _careDetail(WorkflowInstance instance) {
    final assigned = instance.instanceData['assignedReviewerPersonaId'] == widget.persona.personaId;
    final memberOwner = widget.persona.personaId == instance.createdByPersonaId;
    final canSeePrivate = assigned || memberOwner;
    return Column(
      key: const ValueKey('mosque-protected-care-detail'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${instance.instanceData['publicSummary'] ?? instance.instanceData['needDescription']}'),
        Text('Urgency: ${instance.instanceData['urgency']}'),
        Text('Contact preference: ${canSeePrivate ? instance.instanceData['contactPreference'] : 'Private field masked'}'),
        Text('Private details: ${canSeePrivate ? instance.instanceData['privateDetails'] : 'Masked for this viewer'}'),
        Text('Assigned reviewer: ${instance.instanceData['assignedReviewerPersonaId'] ?? ''}'),
        if (instance.instanceData['responseSummary'] case final value?) Text('$value'),
      ],
    );
  }

  Widget _dataLines(WorkflowInstance instance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in _displayKeys)
          if (instance.instanceData[key] case final value?)
            Text(value is List ? '$key: ${value.join(', ')}' : '$value'),
      ],
    );
  }

  static const _displayKeys = [
    'eventTitle', 'eventDate', 'eventTime', 'location', 'capacity', 'audienceScope',
    'calendarSync', 'rsvpStatus', 'amount', 'fund', 'privacyIndicator', 'paymentStatus',
    'receiptId', 'visibilityPreference', 'receiptVisibility', 'fundContext',
    'announcementBody', 'scheduledTime', 'deliveryState', 'readState', 'shiftRole',
    'shiftTime', 'openSpots', 'filledSpots', 'protectedContact', 'contactStatus',
    'noticeTitle', 'safeBody', 'threadTitle', 'lastMessage', 'query', 'answer',
    'citations', 'hiddenSources', 'citationStatus',
  ];

  Widget _actions(WorkflowInstance instance) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final transition in _store.availableTransitions(instance: instance, personaId: widget.persona.personaId))
          OutlinedButton.icon(
            key: ValueKey('mosque-action-${transition.id}'),
            style: _style(transition),
            onPressed: () => _transition(instance, transition.id),
            icon: Icon(_icon(transition.icon)),
            label: Text(transition.label),
          ),
      ],
    );
  }

  Widget _edit(WorkflowInstance instance) {
    final fields = _store.editableFieldsFor(workflowType: instance.workflowType, state: instance.currentState);
    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in fields)
          TextField(
            key: ValueKey('mosque-edit-$field'),
            controller: _controller(instance.instanceId, field),
            decoration: InputDecoration(labelText: field),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: ValueKey('mosque-save-edit-${instance.workflowType}'),
          onPressed: () => _save(instance),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save edits'),
        ),
      ],
    );
  }

  List<Widget> _pills(LoomWorkflowStateMachine machine, Map<String, dynamic> data) {
    return [
      for (final entry in machine.instanceDataSchema.entries)
        if (entry.value.displayIcon != null && !(entry.value.hideWhenEmpty && _empty(data[entry.key])))
          _SurfaceFactPill(
            icon: _fact(entry.value.displayIcon!),
            label: (entry.value.labelTemplate ?? '{value}')
                .replaceAll('{value.length}', data[entry.key] is List ? '${(data[entry.key] as List).length}' : '0')
                .replaceAll('{value}', data[entry.key] is List ? (data[entry.key] as List).join(', ') : '${data[entry.key] ?? ''}'),
            foreground: widget.accent,
          ),
    ];
  }

  bool _empty(Object? value) => value == null || value is List && value.isEmpty || value is String && value.isEmpty;

  void _sync(List<WorkflowInstance> rows) {
    for (final instance in rows) {
      for (final field in _store.editableFieldsFor(workflowType: instance.workflowType, state: instance.currentState)) {
        final value = instance.instanceData[field];
        _controller(instance.instanceId, field).text = value is List ? value.join(', ') : '${value ?? ''}';
      }
    }
  }

  TextEditingController _controller(String id, String field) => _controllers.putIfAbsent('$id::$field', TextEditingController.new);

  WorkflowInstance? _first(String type) {
    if (type == 'mosque-event-rsvp' && widget.persona.personaId == 'mosque-admin') {
      for (final instance in _instances) {
        if (instance.workflowType == type &&
            instance.instanceData['_seedInstanceId'] == 'mosque-event-draft') {
          return instance;
        }
      }
      for (final instance in _instances) {
        if (instance.workflowType == type && instance.currentState == 'draft') {
          return instance;
        }
      }
    }
    if (type == 'mosque-volunteer-signup') {
      final preferredId = widget.persona.personaId == 'mosque-admin'
          ? 'mosque-volunteer-contact'
          : 'mosque-volunteer-iftar';
      for (final instance in _instances) {
        if (instance.workflowType == type && instance.instanceData['_seedInstanceId'] == preferredId) {
          return instance;
        }
      }
      final preferredStates = widget.persona.personaId == 'mosque-admin'
          ? const ['signedUp', 'edited', 'contacted', 'open', 'withdrawn']
          : const ['open', 'signedUp', 'edited', 'withdrawn'];
      for (final state in preferredStates) {
        for (final instance in _instances) {
          if (instance.workflowType == type && instance.currentState == state) {
            return instance;
          }
        }
      }
    }
    for (final instance in _instances) {
      if (instance.workflowType == type) return instance;
    }
    return null;
  }

  Widget _pin(BuildContext context, Key key, String title, IconData icon, String body) {
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
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
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
    final primary = transition.tone == 'primary';
    final destructive = transition.tone == 'destructive';
    return OutlinedButton.styleFrom(
      foregroundColor: destructive ? Colors.red.shade800 : primary ? Colors.white : widget.accent,
      backgroundColor: primary ? widget.accent : null,
      side: BorderSide(color: destructive ? Colors.red.shade800 : widget.accent),
    );
  }

  IconData _icon(String? icon) => switch (icon) {
    'check' => Icons.check_circle_outline, 'close' => Icons.close_outlined, 'delete' => Icons.delete_outline,
    'edit' => Icons.edit_outlined, 'publish' => Icons.publish_outlined, 'payments' => Icons.payments_outlined,
    'privacy_tip' => Icons.privacy_tip_outlined, 'settings' => Icons.settings_outlined, 'open_in_new' => Icons.open_in_new_outlined,
    'person' => Icons.person_outline, 'reply' => Icons.reply_outlined, 'send' => Icons.send_outlined,
    'schedule' => Icons.schedule_outlined, 'search' => Icons.search_outlined, 'report' => Icons.report_problem_outlined,
    'groups' => Icons.groups_outlined, 'save' => Icons.save_outlined, 'preview' => Icons.preview_outlined,
    'lock' => Icons.lock_outline, _ => Icons.account_balance_outlined,
  };

  IconData _fact(String icon) => switch (icon) {
    'event' => Icons.event_outlined, 'schedule' => Icons.schedule_outlined, 'location_on' => Icons.location_on_outlined,
    'groups' => Icons.groups_outlined, 'person' => Icons.person_outline, 'check' => Icons.check_circle_outline,
    'payments' => Icons.payments_outlined, 'flag' => Icons.flag_outlined, 'privacy_tip' => Icons.privacy_tip_outlined,
    'description' => Icons.description_outlined, 'settings' => Icons.settings_outlined, 'report' => Icons.report_problem_outlined,
    'reply' => Icons.reply_outlined, 'publish' => Icons.publish_outlined, 'verified' => Icons.verified_outlined,
    'send' => Icons.send_outlined, 'notifications' => Icons.notifications_outlined, 'forum' => Icons.forum_outlined,
    'delete' => Icons.delete_outline, 'search' => Icons.search_outlined, _ => Icons.label_outline,
  };

  BoxDecoration get _box => BoxDecoration(
    color: widget.modernTheme?.resolvedFill ?? Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: widget.modernTheme?.resolvedBorder ?? widget.accent.withValues(alpha: 0.2)),
  );
}

class _MosqueEngineStore {
  _MosqueEngineStore({required this.communityId});

  final String communityId;
  late final WorkflowDatabase _database = WorkflowDatabase.memory();
  late final LocalWorkflowEngineApi _engine = LocalWorkflowEngineApi(db: _database, communityId: communityId);
  _MosqueFixtureBundle? _fixture;
  Future<void>? _readyFuture;
  bool _ready = false;

  Future<void> ensureReady() {
    if (_ready) return Future.value();
    return _readyFuture ??= _init();
  }

  Future<void> _init() async {
    _fixture ??= await _MosqueFixtureBundle.load();
    for (final machine in _fixture!.machines.values) {
      _engine.registerDefinition(machine);
    }
    for (final instance in _fixture!.instances) {
      final seedData = Map<String, dynamic>.from(instance.instanceData)
        ..['_seedInstanceId'] = instance.instanceId;
      final instanceId = await _engine.createInstance(workflowType: instance.workflowType, initialInstanceData: seedData, personaId: instance.createdByPersonaId);
      final initialState = _fixture!.machines[instance.workflowType]?.initialState;
      if (instance.currentState != initialState) {
        await _database.updateInstanceState(
          instanceId: instanceId,
          newState: instance.currentState,
          newInstanceData: seedData,
        );
      }
    }
    _ready = true;
  }

  Future<List<WorkflowInstance>> instancesFor({required String tabId, required String personaId}) async {
    await ensureReady();
    final query = tabId == 'calendar' && personaId != 'mosque-admin'
        ? const SurfaceQuery(audienceMemberField: 'invitedPersonaIds')
        : const SurfaceQuery();
    final page = await _engine.queryInstances(tabId: tabId, personaId: personaId, limit: 100, query: query);
    final allowed = switch (tabId) {
      'calendar' => const {'mosque-event-rsvp'},
      'giving' => const {'mosque-donation-payment', 'mosque-donor-visibility'},
      'care' => const {'mosque-care-request', 'mosque-volunteer-signup'},
      'admin' => const {'mosque-announcement', 'mosque-volunteer-signup', 'mosque-care-request'},
      'messages' => const {'mosque-discussion-thread', 'mosque-neutral-notification', 'mosque-announcement'},
      'search' => const {'mosque-search-ai-citation'},
      'home' => const {'mosque-event-rsvp', 'mosque-donation-payment', 'mosque-care-request', 'mosque-announcement', 'mosque-volunteer-signup', 'mosque-neutral-notification'},
      _ => const <String>{},
    };
    return page.items.where((instance) => allowed.contains(instance.workflowType)).where((instance) => _visible(instance, tabId, personaId)).toList(growable: false);
  }

  bool _visible(WorkflowInstance instance, String tabId, String personaId) {
    if (tabId == 'admin') return personaId == 'mosque-admin';
    if (tabId == 'calendar' && personaId == 'mosque-admin') return instance.currentState == 'draft' || instance.createdByPersonaId == personaId;
    if (tabId == 'calendar') return instance.currentState != 'draft';
    if (tabId == 'care' && personaId == 'mosque-member' && instance.workflowType == 'mosque-care-request') return instance.createdByPersonaId == personaId;
    if (tabId == 'messages' && instance.workflowType == 'mosque-announcement') return personaId == 'mosque-member' && (instance.currentState == 'sent' || instance.currentState == 'read');
    return true;
  }

  List<LoomWorkflowTransition> availableTransitions({required WorkflowInstance instance, required String personaId}) => _engine.availableTransitions(workflowType: instance.workflowType, instanceId: instance.instanceId, currentState: instance.currentState, instanceData: instance.instanceData, personaId: personaId);

  Future<void> apply({required WorkflowInstance instance, required String transitionId, required String personaId}) => _engine.applyTransition(workflowType: instance.workflowType, instanceId: instance.instanceId, transitionId: transitionId, personaId: personaId);

  Future<void> updateFields({required WorkflowInstance instance, required Map<String, dynamic> fieldUpdates, required String personaId}) => _engine.updateInstanceFields(workflowType: instance.workflowType, instanceId: instance.instanceId, fieldUpdates: fieldUpdates, personaId: personaId);

  LoomWorkflowStateMachine machineFor(String workflowType) => _fixture!.machines[workflowType]!;

  List<String> editableFieldsFor({required String workflowType, required String state}) => machineFor(workflowType).states[state]?.editableFields ?? const [];
}

class _MosqueFixtureBundle {
  _MosqueFixtureBundle({required this.machines, required this.instances});
  final Map<String, LoomWorkflowStateMachine> machines;
  final List<_GardenSeedInstance> instances;

  static Future<_MosqueFixtureBundle> load() async {
    final json = jsonDecode(_stripGardenJsoncComments(_mosqueBundledFixtureJsonc)) as Map<String, dynamic>;
    final defs = json['workflowDefinitions'] as Map<String, dynamic>;
    final machines = <String, LoomWorkflowStateMachine>{};
    for (final entry in defs.entries) {
      machines[entry.key] = LoomWorkflowStateMachine.fromJson(_normalizeGardenMachineJson(entry.value as Map<String, dynamic>), entry.key);
    }
    final instances = [
      for (final item in json['workflowInstances'] as List<dynamic>)
        _GardenSeedInstance.fromJson(item as Map<String, dynamic>),
    ];
    return _MosqueFixtureBundle(machines: machines, instances: instances);
  }
}

const _mosqueBundledFixtureJsonc = r'''
{
  "personas": [
    "mosque-admin",
    "mosque-member"
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
    "calendarAgenda": {
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
    "singleItem": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    },
    "protectedDetail": {
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
    "volunteerRoster": {
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
    "searchAiAnswer": {
      "slots": [
        "WorkflowFactPillRow",
        "WorkflowActionButtonRow"
      ]
    }
  },
  "workflowDefinitions": {
    "mosque-event-rsvp": {
      "initialState": "draft",
      "states": {
        "draft": {
          "label": "Draft event",
          "editableFields": [
            "eventTitle",
            "eventDate",
            "eventTime",
            "location",
            "capacity",
            "audienceScope",
            "invitedPersonaIds"
          ]
        },
        "published": {
          "label": "Published"
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
        "waitlisted": {
          "label": "Waitlisted",
          "isTerminal": true
        },
        "changed": {
          "label": "Changed"
        },
        "cancelled": {
          "label": "Cancelled",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "publish-event",
          "label": "Publish event",
          "icon": "publish",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "published",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "calendarSync",
              "value": "Published to selected audience"
            }
          ]
        },
        {
          "id": "rsvp-going",
          "label": "RSVP going",
          "icon": "check",
          "tone": "primary",
          "from": [
            "published",
            "maybe",
            "notGoing",
            "changed"
          ],
          "to": "going",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
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
            "published",
            "going",
            "notGoing",
            "changed"
          ],
          "to": "maybe",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
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
            "published",
            "going",
            "maybe",
            "changed"
          ],
          "to": "notGoing",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
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
          "id": "join-waitlist",
          "label": "Join waitlist",
          "icon": "groups",
          "tone": "secondary",
          "from": [
            "published"
          ],
          "to": "waitlisted",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "waitlistPersonaIds",
              "value": "{actor}"
            }
          ]
        },
        {
          "id": "change-event",
          "label": "Change event",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "published",
            "going",
            "maybe",
            "notGoing"
          ],
          "to": "changed",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "eventTime",
              "value": "Friday 7:30 PM"
            }
          ]
        },
        {
          "id": "cancel-event",
          "label": "Cancel event",
          "icon": "delete",
          "tone": "destructive",
          "from": [
            "published",
            "changed"
          ],
          "to": "cancelled",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": []
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft"
          ],
          "role": "actor",
          "tabId": "calendar",
          "cardSurfaceFamily": "formEntry",
          "bindingKind": "primary"
        },
        {
          "states": [
            "published",
            "going",
            "maybe",
            "notGoing",
            "waitlisted",
            "changed"
          ],
          "role": "receiver",
          "tabId": "calendar",
          "cardSurfaceFamily": "calendarAgenda",
          "bindingKind": "primary",
          "audienceMemberField": "invitedPersonaIds"
        },
        {
          "states": [
            "published",
            "going",
            "maybe",
            "notGoing"
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
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "event",
          "labelTemplate": "{value}"
        },
        "eventDate": {
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
        "capacity": {
          "type": "number",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "groups",
          "labelTemplate": "Capacity {value}"
        },
        "audienceScope": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "groups",
          "labelTemplate": "Audience: {value}"
        },
        "invitedPersonaIds": {
          "type": "list",
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Invited: {value.length}",
          "hideWhenEmpty": true
        },
        "calendarSync": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "{value}"
        },
        "rsvpStatus": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "RSVP: {value}"
        },
        "waitlistPersonaIds": {
          "type": "list",
          "writableBy": "effect",
          "displayIcon": "groups",
          "labelTemplate": "Waitlist: {value.length}",
          "hideWhenEmpty": true
        }
      }
    },
    "mosque-donation-payment": {
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
        "receiptOpened": {
          "label": "Receipt opened",
          "isTerminal": true
        },
        "recurringManaged": {
          "label": "Recurring managed",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "pay-donation",
          "label": "Pay donation",
          "icon": "payments",
          "tone": "primary",
          "from": [
            "unpaid",
            "failed"
          ],
          "to": "paid",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
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
              "value": "MN-2026-050"
            }
          ]
        },
        {
          "id": "simulate-payment-failure",
          "label": "Simulate payment failure",
          "icon": "report",
          "tone": "secondary",
          "from": [
            "unpaid"
          ],
          "to": "failed",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
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
          "id": "retry-donation",
          "label": "Retry donation",
          "icon": "undo",
          "tone": "primary",
          "from": [
            "failed"
          ],
          "to": "paid",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": []
        },
        {
          "id": "manage-recurring",
          "label": "Manage recurring",
          "icon": "settings",
          "tone": "secondary",
          "from": [
            "unpaid",
            "paid"
          ],
          "to": "recurringManaged",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "recurringStatus",
              "value": "Managed monthly"
            }
          ]
        },
        {
          "id": "open-receipt",
          "label": "Open receipt",
          "icon": "open_in_new",
          "tone": "secondary",
          "from": [
            "paid"
          ],
          "to": "receiptOpened",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member",
              "mosque-admin"
            ]
          },
          "effects": []
        }
      ],
      "renderBindings": [
        {
          "states": [
            "unpaid",
            "paid",
            "failed",
            "receiptOpened",
            "recurringManaged"
          ],
          "role": "any",
          "tabId": "giving",
          "cardSurfaceFamily": "paymentCheckout",
          "bindingKind": "primary"
        },
        {
          "states": [
            "paid",
            "receiptOpened"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "amount": {
          "type": "number",
          "displayIcon": "payments",
          "labelTemplate": "{value} USD"
        },
        "fund": {
          "type": "text",
          "displayIcon": "flag",
          "labelTemplate": "Fund: {value}"
        },
        "privacyIndicator": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "paymentStatus": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "Status: {value}"
        },
        "receiptId": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "Receipt: {value}"
        },
        "recurringStatus": {
          "type": "text",
          "displayIcon": "settings",
          "labelTemplate": "{value}"
        }
      }
    },
    "mosque-donor-visibility": {
      "initialState": "restricted",
      "states": {
        "public": {
          "label": "Public"
        },
        "anonymous": {
          "label": "Anonymous"
        },
        "restricted": {
          "label": "Restricted"
        }
      },
      "transitions": [
        {
          "id": "set-public",
          "label": "Set public",
          "icon": "person",
          "tone": "secondary",
          "from": [
            "anonymous",
            "restricted"
          ],
          "to": "public",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "visibilityPreference",
              "value": "Public donor"
            }
          ]
        },
        {
          "id": "set-anonymous",
          "label": "Set anonymous",
          "icon": "privacy_tip",
          "tone": "primary",
          "from": [
            "public",
            "restricted"
          ],
          "to": "anonymous",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "visibilityPreference",
              "value": "Anonymous donor"
            }
          ]
        },
        {
          "id": "set-restricted",
          "label": "Set restricted",
          "icon": "lock",
          "tone": "secondary",
          "from": [
            "public",
            "anonymous"
          ],
          "to": "restricted",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "visibilityPreference",
              "value": "Restricted donor"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "public",
            "anonymous",
            "restricted"
          ],
          "role": "any",
          "tabId": "giving",
          "cardSurfaceFamily": "singleItem",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "visibilityPreference": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "receiptVisibility": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "fundContext": {
          "type": "text",
          "displayIcon": "flag",
          "labelTemplate": "{value}"
        }
      }
    },
    "mosque-care-request": {
      "initialState": "draft",
      "states": {
        "draft": {
          "label": "Draft",
          "editableFields": [
            "needDescription",
            "urgency",
            "contactPreference",
            "privateFieldKeys"
          ]
        },
        "submitted": {
          "label": "Submitted"
        },
        "assigned": {
          "label": "Assigned"
        },
        "responded": {
          "label": "Responded"
        },
        "resolved": {
          "label": "Resolved",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "submit-care-request",
          "label": "Submit care request",
          "icon": "send",
          "tone": "primary",
          "from": [
            "draft"
          ],
          "to": "submitted",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "publicSummary",
              "value": "Meal support requested"
            }
          ]
        },
        {
          "id": "edit-care-request",
          "label": "Edit care request",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "draft",
            "submitted"
          ],
          "to": "draft",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": []
        },
        {
          "id": "assign-care-request",
          "label": "Assign reviewer",
          "icon": "person",
          "tone": "primary",
          "from": [
            "submitted"
          ],
          "to": "assigned",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "assignedReviewerPersonaId",
              "value": "mosque-admin"
            }
          ]
        },
        {
          "id": "respond-care-request",
          "label": "Respond privately",
          "icon": "reply",
          "tone": "primary",
          "from": [
            "assigned"
          ],
          "to": "responded",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "responseSummary",
              "value": "Care team will call after Jummah"
            }
          ]
        },
        {
          "id": "close-care-request",
          "label": "Close care request",
          "icon": "check",
          "tone": "primary",
          "from": [
            "responded"
          ],
          "to": "resolved",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "careStatus",
              "value": "Resolved"
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
          "tabId": "care",
          "cardSurfaceFamily": "formEntry",
          "bindingKind": "primary"
        },
        {
          "states": [
            "submitted",
            "assigned",
            "responded",
            "resolved"
          ],
          "role": "receiver",
          "tabId": "care",
          "cardSurfaceFamily": "protectedDetail",
          "bindingKind": "primary"
        },
        {
          "states": [
            "submitted",
            "assigned",
            "responded"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "needDescription": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "description",
          "labelTemplate": "Need: {value}"
        },
        "urgency": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "report",
          "labelTemplate": "Urgency: {value}"
        },
        "contactPreference": {
          "type": "text",
          "writableBy": "formEntry",
          "displayIcon": "person",
          "labelTemplate": "Contact: {value}"
        },
        "privateFieldKeys": {
          "type": "list",
          "writableBy": "formEntry",
          "displayIcon": "privacy_tip",
          "labelTemplate": "Private fields: {value.length}"
        },
        "publicSummary": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "assignedReviewerPersonaId": {
          "type": "text",
          "displayIcon": "person",
          "labelTemplate": "Assigned: {value}"
        },
        "privateDetails": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "responseSummary": {
          "type": "text",
          "displayIcon": "reply",
          "labelTemplate": "{value}"
        },
        "careStatus": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "{value}"
        }
      }
    },
    "mosque-announcement": {
      "initialState": "draft",
      "states": {
        "draft": {
          "label": "Draft",
          "editableFields": [
            "announcementBody",
            "audienceScope",
            "scheduledTime"
          ]
        },
        "previewed": {
          "label": "Previewed"
        },
        "scheduled": {
          "label": "Scheduled"
        },
        "sent": {
          "label": "Sent"
        },
        "read": {
          "label": "Read",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "save-announcement-draft",
          "label": "Save draft",
          "icon": "save",
          "tone": "secondary",
          "from": [
            "draft"
          ],
          "to": "draft",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": []
        },
        {
          "id": "preview-announcement",
          "label": "Preview",
          "icon": "preview",
          "tone": "secondary",
          "from": [
            "draft"
          ],
          "to": "previewed",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": []
        },
        {
          "id": "schedule-announcement",
          "label": "Schedule",
          "icon": "schedule",
          "tone": "primary",
          "from": [
            "draft",
            "previewed"
          ],
          "to": "scheduled",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": []
        },
        {
          "id": "publish-announcement",
          "label": "Publish",
          "icon": "publish",
          "tone": "primary",
          "from": [
            "draft",
            "previewed",
            "scheduled"
          ],
          "to": "sent",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "deliveryState",
              "value": "Sent"
            }
          ]
        },
        {
          "id": "mark-announcement-read",
          "label": "Mark read",
          "icon": "check",
          "tone": "secondary",
          "from": [
            "sent"
          ],
          "to": "read",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "readState",
              "value": "Read"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "draft",
            "previewed",
            "scheduled",
            "sent"
          ],
          "role": "actor",
          "tabId": "admin",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        },
        {
          "states": [
            "sent",
            "read"
          ],
          "role": "receiver",
          "tabId": "messages",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        },
        {
          "states": [
            "draft",
            "previewed",
            "scheduled",
            "sent"
          ],
          "role": "actor",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "announcementBody": {
          "type": "text",
          "required": true,
          "writableBy": "formEntry",
          "displayIcon": "forum",
          "labelTemplate": "{value}"
        },
        "audienceScope": {
          "type": "text",
          "writableBy": "formEntry",
          "displayIcon": "groups",
          "labelTemplate": "Audience: {value}"
        },
        "scheduledTime": {
          "type": "text",
          "writableBy": "formEntry",
          "displayIcon": "schedule",
          "labelTemplate": "{value}"
        },
        "deliveryState": {
          "type": "text",
          "displayIcon": "publish",
          "labelTemplate": "{value}"
        },
        "readState": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "{value}"
        },
        "deliveryReceipts": {
          "type": "list",
          "displayIcon": "verified",
          "labelTemplate": "Receipts: {value.length}",
          "hideWhenEmpty": true
        }
      }
    },
    "mosque-volunteer-signup": {
      "initialState": "open",
      "states": {
        "open": {
          "label": "Open"
        },
        "signedUp": {
          "label": "Signed up"
        },
        "edited": {
          "label": "Edited"
        },
        "withdrawn": {
          "label": "Withdrawn"
        },
        "closed": {
          "label": "Closed",
          "isTerminal": true
        },
        "contacted": {
          "label": "Contacted"
        }
      },
      "transitions": [
        {
          "id": "sign-up-volunteer",
          "label": "Sign up",
          "icon": "check",
          "tone": "primary",
          "from": [
            "open"
          ],
          "to": "signedUp",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "signedUpPersonaIds",
              "value": "{actor}"
            }
          ]
        },
        {
          "id": "edit-volunteer-signup",
          "label": "Edit signup",
          "icon": "edit",
          "tone": "secondary",
          "from": [
            "signedUp"
          ],
          "to": "edited",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": []
        },
        {
          "id": "cancel-volunteer-signup",
          "label": "Cancel signup",
          "icon": "delete",
          "tone": "secondary",
          "from": [
            "signedUp",
            "edited"
          ],
          "to": "withdrawn",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": []
        },
        {
          "id": "open-volunteer-shift",
          "label": "Open shift",
          "icon": "publish",
          "tone": "secondary",
          "from": [
            "closed"
          ],
          "to": "open",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": []
        },
        {
          "id": "close-volunteer-shift",
          "label": "Close shift",
          "icon": "close",
          "tone": "destructive",
          "from": [
            "open",
            "signedUp",
            "edited",
            "withdrawn",
            "contacted"
          ],
          "to": "closed",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": []
        },
        {
          "id": "contact-volunteer",
          "label": "Contact volunteer",
          "icon": "send",
          "tone": "primary",
          "from": [
            "signedUp",
            "edited"
          ],
          "to": "contacted",
          "guard": {
            "allowedPersonaIds": [
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "contactStatus",
              "value": "Protected contact sent"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "open",
            "signedUp",
            "edited",
            "withdrawn",
            "closed",
            "contacted"
          ],
          "role": "any",
          "tabId": "admin",
          "cardSurfaceFamily": "volunteerRoster",
          "bindingKind": "primary"
        },
        {
          "states": [
            "open",
            "signedUp",
            "edited",
            "withdrawn"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "shiftRole": {
          "type": "text",
          "displayIcon": "groups",
          "labelTemplate": "{value}"
        },
        "shiftTime": {
          "type": "text",
          "displayIcon": "schedule",
          "labelTemplate": "{value}"
        },
        "openSpots": {
          "type": "number",
          "displayIcon": "groups",
          "labelTemplate": "Open spots: {value}"
        },
        "filledSpots": {
          "type": "number",
          "displayIcon": "person",
          "labelTemplate": "Filled: {value}"
        },
        "signedUpPersonaIds": {
          "type": "list",
          "displayIcon": "person",
          "labelTemplate": "Roster: {value.length}",
          "hideWhenEmpty": true
        },
        "protectedContact": {
          "type": "text",
          "displayIcon": "privacy_tip",
          "labelTemplate": "{value}"
        },
        "contactStatus": {
          "type": "text",
          "displayIcon": "send",
          "labelTemplate": "{value}"
        }
      }
    },
    "mosque-neutral-notification": {
      "initialState": "sent",
      "states": {
        "sent": {
          "label": "Sent"
        },
        "read": {
          "label": "Read",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "mark-neutral-read",
          "label": "Mark neutral notice read",
          "icon": "check",
          "tone": "secondary",
          "from": [
            "sent"
          ],
          "to": "read",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "readState",
              "value": "Read"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "sent",
            "read"
          ],
          "role": "receiver",
          "tabId": "messages",
          "cardSurfaceFamily": "notificationInbox",
          "bindingKind": "primary"
        },
        {
          "states": [
            "sent"
          ],
          "role": "any",
          "tabId": "home",
          "cardSurfaceFamily": "dashboard",
          "bindingKind": "summary"
        }
      ],
      "instanceDataSchema": {
        "noticeTitle": {
          "type": "text",
          "displayIcon": "notifications",
          "labelTemplate": "{value}"
        },
        "safeBody": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "readState": {
          "type": "text",
          "displayIcon": "check",
          "labelTemplate": "{value}"
        }
      }
    },
    "mosque-search-ai-citation": {
      "initialState": "answered",
      "states": {
        "answered": {
          "label": "Answered"
        },
        "refined": {
          "label": "Refined"
        },
        "sourceHidden": {
          "label": "Source hidden"
        },
        "reported": {
          "label": "Reported stale",
          "isTerminal": true
        }
      },
      "transitions": [
        {
          "id": "refine-search",
          "label": "Refine query",
          "icon": "search",
          "tone": "primary",
          "from": [
            "answered",
            "sourceHidden"
          ],
          "to": "refined",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member",
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "query",
              "value": "iftar volunteer time"
            }
          ]
        },
        {
          "id": "hide-source",
          "label": "Hide source",
          "icon": "delete",
          "tone": "secondary",
          "from": [
            "answered",
            "refined"
          ],
          "to": "sourceHidden",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member",
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "append",
              "key": "hiddenSources",
              "value": "private volunteer sheet"
            }
          ]
        },
        {
          "id": "report-stale-citation",
          "label": "Report stale citation",
          "icon": "report",
          "tone": "destructive",
          "from": [
            "answered",
            "refined",
            "sourceHidden"
          ],
          "to": "reported",
          "guard": {
            "allowedPersonaIds": [
              "mosque-member",
              "mosque-admin"
            ]
          },
          "effects": [
            {
              "op": "set",
              "key": "citationStatus",
              "value": "Reported stale"
            }
          ]
        }
      ],
      "renderBindings": [
        {
          "states": [
            "answered",
            "refined",
            "sourceHidden",
            "reported"
          ],
          "role": "any",
          "tabId": "search",
          "cardSurfaceFamily": "searchAiAnswer",
          "bindingKind": "primary"
        }
      ],
      "instanceDataSchema": {
        "query": {
          "type": "text",
          "displayIcon": "search",
          "labelTemplate": "Query: {value}"
        },
        "answer": {
          "type": "text",
          "displayIcon": "description",
          "labelTemplate": "{value}"
        },
        "citations": {
          "type": "list",
          "displayIcon": "description",
          "labelTemplate": "Citations: {value.length}"
        },
        "hiddenSources": {
          "type": "list",
          "displayIcon": "delete",
          "labelTemplate": "Hidden: {value.length}",
          "hideWhenEmpty": true
        },
        "citationStatus": {
          "type": "text",
          "displayIcon": "report",
          "labelTemplate": "{value}"
        }
      }
    },
    "mosque-discussion-thread": {
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
              "mosque-member",
              "mosque-admin"
            ]
          },
          "effects": []
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
              "mosque-admin"
            ]
          },
          "effects": []
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
        }
      }
    }
  },
  "workflowInstances": [
    {
      "instanceId": "mosque-event-friday",
      "workflowType": "mosque-event-rsvp",
      "currentState": "published",
      "createdByPersonaId": "mosque-admin",
      "instanceData": {
        "eventTitle": "Friday service and community iftar",
        "eventDate": "Fri Jul 17",
        "eventTime": "Friday 7:00 PM",
        "location": "Masjid Nur Hall",
        "capacity": 80,
        "audienceScope": "all",
        "invitedPersonaIds": [],
        "calendarSync": "Published to all",
        "rsvpStatus": "Not answered",
        "waitlistPersonaIds": []
      }
    },
    {
      "instanceId": "mosque-event-private",
      "workflowType": "mosque-event-rsvp",
      "currentState": "published",
      "createdByPersonaId": "mosque-admin",
      "instanceData": {
        "eventTitle": "Private consultation",
        "eventDate": "Sat Jul 18",
        "eventTime": "Saturday 10:00 AM",
        "location": "Office",
        "capacity": 1,
        "audienceScope": "individual",
        "invitedPersonaIds": [
          "other-member"
        ],
        "calendarSync": "Private invitation",
        "rsvpStatus": "Not answered",
        "waitlistPersonaIds": []
      }
    },
    {
      "instanceId": "mosque-event-draft",
      "workflowType": "mosque-event-rsvp",
      "currentState": "draft",
      "createdByPersonaId": "mosque-admin",
      "instanceData": {
        "eventTitle": "Planning committee check-in",
        "eventDate": "Sun Jul 19",
        "eventTime": "Sunday 4:00 PM",
        "location": "Library room",
        "capacity": 8,
        "audienceScope": "selected-many",
        "invitedPersonaIds": [
          "mosque-member"
        ],
        "calendarSync": "Draft audience-selected invitation",
        "rsvpStatus": "Not answered",
        "waitlistPersonaIds": []
      }
    },
    {
      "instanceId": "mosque-donation-main",
      "workflowType": "mosque-donation-payment",
      "currentState": "unpaid",
      "createdByPersonaId": "mosque-member",
      "instanceData": {
        "amount": 50,
        "fund": "Iftar meals",
        "privacyIndicator": "Restricted donor preference controls identity visibility",
        "paymentStatus": "Unpaid",
        "receiptId": "Pending",
        "recurringStatus": "Not recurring"
      }
    },
    {
      "instanceId": "mosque-donor-preference",
      "workflowType": "mosque-donor-visibility",
      "currentState": "restricted",
      "createdByPersonaId": "mosque-member",
      "instanceData": {
        "visibilityPreference": "Restricted donor",
        "receiptVisibility": "Receipt hides donor identity from public rolls",
        "fundContext": "Applies to Iftar meals donations"
      }
    },
    {
      "instanceId": "mosque-care-main",
      "workflowType": "mosque-care-request",
      "currentState": "draft",
      "createdByPersonaId": "mosque-member",
      "instanceData": {
        "needDescription": "Meal support requested",
        "urgency": "High",
        "contactPreference": "Call after Jummah",
        "privateFieldKeys": [
          "privateDetails",
          "contactPreference"
        ],
        "publicSummary": "Meal support requested",
        "assignedReviewerPersonaId": "",
        "privateDetails": "Please contact privately after Jummah",
        "responseSummary": "",
        "careStatus": "Draft"
      }
    },
    {
      "instanceId": "mosque-announcement-main",
      "workflowType": "mosque-announcement",
      "currentState": "draft",
      "createdByPersonaId": "mosque-admin",
      "instanceData": {
        "announcementBody": "Iftar volunteer signup and donation drive are open.",
        "audienceScope": "all",
        "scheduledTime": "Today 5 PM",
        "deliveryState": "Draft",
        "readState": "Unread",
        "deliveryReceipts": []
      }
    },
    {
      "instanceId": "mosque-volunteer-iftar",
      "workflowType": "mosque-volunteer-signup",
      "currentState": "open",
      "createdByPersonaId": "mosque-admin",
      "instanceData": {
        "shiftRole": "Iftar setup",
        "shiftTime": "Friday 5:30 PM",
        "openSpots": 4,
        "filledSpots": 2,
        "signedUpPersonaIds": [
          "amina",
          "yusuf"
        ],
        "protectedContact": "Phone hidden until contact action",
        "contactStatus": "Not contacted"
      }
    },
    {
      "instanceId": "mosque-volunteer-contact",
      "workflowType": "mosque-volunteer-signup",
      "currentState": "signedUp",
      "createdByPersonaId": "mosque-member",
      "instanceData": {
        "shiftRole": "Kitchen cleanup",
        "shiftTime": "Friday 9:00 PM",
        "openSpots": 2,
        "filledSpots": 1,
        "signedUpPersonaIds": [
          "mosque-member"
        ],
        "protectedContact": "Phone hidden until contact action",
        "contactStatus": "Not contacted"
      }
    },
    {
      "instanceId": "mosque-neutral-care",
      "workflowType": "mosque-neutral-notification",
      "currentState": "sent",
      "createdByPersonaId": "mosque-admin",
      "instanceData": {
        "noticeTitle": "Care request received",
        "safeBody": "Your request was received. A care volunteer will follow up privately.",
        "readState": "Unread"
      }
    },
    {
      "instanceId": "mosque-search-iftar",
      "workflowType": "mosque-search-ai-citation",
      "currentState": "answered",
      "createdByPersonaId": "mosque-member",
      "instanceData": {
        "query": "iftar",
        "answer": "Community iftar starts Friday at 7 PM.",
        "citations": [
          "Public announcement: Ramadan community night",
          "Members-only volunteer guide"
        ],
        "hiddenSources": [],
        "citationStatus": "Current"
      }
    },
    {
      "instanceId": "mosque-thread-general",
      "workflowType": "mosque-discussion-thread",
      "currentState": "open",
      "createdByPersonaId": "mosque-member",
      "instanceData": {
        "threadTitle": "Iftar logistics",
        "lastMessage": "Can I bring dates?"
      }
    }
  ]
}
''';
