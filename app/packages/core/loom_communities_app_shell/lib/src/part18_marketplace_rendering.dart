part of '../loom_communities_app_shell.dart';

enum WorkflowTemplateSlotKind { workflowActionButtonRow, workflowFactPillRow }

class WorkflowAudienceSelectorField extends StatefulWidget {
  final List<String> availableFanIds;
  final Map<String, dynamic> initialInstanceData;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const WorkflowAudienceSelectorField({
    super.key,
    required this.availableFanIds,
    required this.onChanged,
    this.initialInstanceData = const {},
  });

  @override
  State<WorkflowAudienceSelectorField> createState() =>
      _WorkflowAudienceSelectorFieldState();
}

class _WorkflowAudienceSelectorFieldState
    extends State<WorkflowAudienceSelectorField> {
  late String _scope;
  late Set<String> _selectedFanIds;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialInstanceData['audienceScope'] as String? ?? 'all';
    final initialIds = widget.initialInstanceData['invitedFanIds'];
    _selectedFanIds = initialIds is Iterable
        ? initialIds.map((id) => '$id').toSet()
        : <String>{};
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _setScope(String scope) {
    setState(() {
      _scope = scope;
      if (scope == 'all') {
        _selectedFanIds.clear();
      } else if (scope == 'individual' && _selectedFanIds.length > 1) {
        final first = _selectedFanIds.first;
        _selectedFanIds = {first};
      }
    });
    _emit();
  }

  void _toggleFan(String fanId, bool selected) {
    setState(() {
      if (_scope == 'individual') {
        _selectedFanIds = selected ? {fanId} : <String>{};
      } else if (selected) {
        _selectedFanIds.add(fanId);
      } else {
        _selectedFanIds.remove(fanId);
      }
    });
    _emit();
  }

  void _emit() {
    widget.onChanged({
      'audienceScope': _scope,
      'invitedFanIds': _scope == 'all'
          ? <String>[]
          : _selectedFanIds.toList(growable: false),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('audience-selector-field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          key: const ValueKey('audience-selector-scope'),
          value: _scope,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All members')),
            DropdownMenuItem(
              value: 'selected',
              child: Text('Selected members'),
            ),
            DropdownMenuItem(value: 'individual', child: Text('One member')),
          ],
          onChanged: (value) {
            if (value != null) _setScope(value);
          },
        ),
        if (_scope == 'selected')
          Column(
            key: const ValueKey('audience-selector-selected-many'),
            children: widget.availableFanIds
                .map(
                  (fanId) => CheckboxListTile(
                    key: ValueKey('audience-selector-fan-$fanId'),
                    title: Text(fanId),
                    value: _selectedFanIds.contains(fanId),
                    onChanged: (selected) =>
                        _toggleFan(fanId, selected ?? false),
                  ),
                )
                .toList(growable: false),
          ),
        if (_scope == 'individual')
          Column(
            key: const ValueKey('audience-selector-individual'),
            children: widget.availableFanIds
                .map(
                  (fanId) => ListTile(
                    key: ValueKey('audience-selector-fan-$fanId'),
                    title: Text(fanId),
                    selected: _selectedFanIds.contains(fanId),
                    trailing: _selectedFanIds.contains(fanId)
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () => _toggleFan(fanId, true),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

enum WorkflowActionTone { primary, secondary, destructive }

typedef WorkflowActionPressed = void Function(String transitionId);

class WorkflowActionButtonTransition {
  const WorkflowActionButtonTransition({
    required this.id,
    required this.label,
    this.iconName,
    this.tone = WorkflowActionTone.primary,
    this.waitingForPrerequisite = false,
    this.waitingText = 'Waiting',
  });

  final String id;
  final String label;
  final String? iconName;
  final WorkflowActionTone tone;
  final bool waitingForPrerequisite;
  final String waitingText;
}

class WorkflowFactPillFieldSchema {
  const WorkflowFactPillFieldSchema({
    this.type = 'text',
    this.maxLength = 80,
    this.maxLines = 1,
    this.displayIcon,
    this.labelTemplate,
    this.hideWhenEmpty = false,
    this.displayContexts,
    this.openMode,
    this.itemSchema,
  });

  final String type;
  final int? maxLength;
  final int maxLines;
  final String? displayIcon;
  final String? labelTemplate;
  final bool hideWhenEmpty;
  final List<String>? displayContexts;
  final String? openMode;
  final Map<String, WorkflowFactPillFieldSchema>? itemSchema;

  bool shouldDisplayInContext(String context) {
    // An empty list is an explicit author signal ("never render this field
    // anywhere" -- used throughout community JSON for internal/formula-only
    // fields like memberFanId), distinct from an omitted/null list
    // ("no restriction, show everywhere"). Only null gets the default.
    if (displayContexts == null) return true;
    return displayContexts!.contains(context);
  }
}

class WorkflowCardSurfaceTemplate {
  const WorkflowCardSurfaceTemplate({
    required this.cardSurfaceFamily,
    required this.primaryBindingSlots,
    this.summaryBindingSlots = const [],
  });

  final String cardSurfaceFamily;
  final List<WorkflowTemplateSlotKind> primaryBindingSlots;
  final List<WorkflowTemplateSlotKind> summaryBindingSlots;
}

const Map<String, WorkflowCardSurfaceTemplate> workflowCardSurfaceTemplates = {
  'equipment-loan': WorkflowCardSurfaceTemplate(
    cardSurfaceFamily: 'equipment-loan',
    primaryBindingSlots: [
      WorkflowTemplateSlotKind.workflowFactPillRow,
      WorkflowTemplateSlotKind.workflowActionButtonRow,
    ],
  ),
  'equipment-giveaway': WorkflowCardSurfaceTemplate(
    cardSurfaceFamily: 'equipment-giveaway',
    primaryBindingSlots: [
      WorkflowTemplateSlotKind.workflowFactPillRow,
      WorkflowTemplateSlotKind.workflowActionButtonRow,
    ],
  ),
  'event-rsvp': WorkflowCardSurfaceTemplate(
    cardSurfaceFamily: 'event-rsvp',
    primaryBindingSlots: [
      WorkflowTemplateSlotKind.workflowFactPillRow,
      WorkflowTemplateSlotKind.workflowActionButtonRow,
    ],
  ),
  'payment': WorkflowCardSurfaceTemplate(
    cardSurfaceFamily: 'payment',
    primaryBindingSlots: [
      WorkflowTemplateSlotKind.workflowFactPillRow,
      WorkflowTemplateSlotKind.workflowActionButtonRow,
    ],
  ),
  'paymentCheckout': WorkflowCardSurfaceTemplate(
    cardSurfaceFamily: 'paymentCheckout',
    primaryBindingSlots: [
      WorkflowTemplateSlotKind.workflowFactPillRow,
      WorkflowTemplateSlotKind.workflowActionButtonRow,
    ],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
paymentCheckoutDefaultInstanceDataSchema = {
  'amountLabel': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'payments_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'purpose': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'receipt_long',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'recipient': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'account_balance_outlined',
    labelTemplate: 'Recipient: {value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'cadence': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'repeat',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'entitlement': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'verified_outlined',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
eventRsvpDefaultInstanceDataSchema = {
  'eventDate': WorkflowFactPillFieldSchema(
    type: 'date',
    displayIcon: 'calendar_today_outlined',
    labelTemplate: '{value}',
    displayContexts: ['detail'],
  ),
  'eventDateTime': WorkflowFactPillFieldSchema(
    type: 'date',
    displayIcon: 'schedule',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'host': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'person_outline',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'location': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'location_on_outlined',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'capacityLabel': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'groups_outlined',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'rsvpStatus': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'event_available',
    labelTemplate: 'Your RSVP: {value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'waitlistedFanIds': WorkflowFactPillFieldSchema(
    type: 'fanId[]',
    displayIcon: 'hourglass_empty',
    labelTemplate: 'Waitlist: {value.length}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'reminderState': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'notifications_active',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
equipmentLoanDefaultInstanceDataSchema = {
  'title': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    maxLines: 2,
    displayIcon: 'title',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'category': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'category_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'condition': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'verified_outlined',
    labelTemplate: '{value}',
    displayContexts: ['detail'],
  ),
  'availabilityState': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'inventory_2_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'holderFanId': WorkflowFactPillFieldSchema(
    type: 'fanId',
    maxLines: 2,
    displayIcon: 'person_outline',
    labelTemplate: 'Holder: {value}',
    displayContexts: ['tile', 'detail'],
  ),
  'queuedFanIds': WorkflowFactPillFieldSchema(
    type: 'fanId[]',
    displayIcon: 'groups_outlined',
    labelTemplate: 'Queue: {value.length}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'dueDate': WorkflowFactPillFieldSchema(
    type: 'date',
    displayIcon: 'schedule',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
equipmentGiveawayDefaultInstanceDataSchema = {
  'title': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    maxLines: 2,
    displayIcon: 'title',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'category': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 40,
    displayIcon: 'category_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'condition': WorkflowFactPillFieldSchema(
    type: 'text',
    maxLength: 80,
    displayIcon: 'verified_outlined',
    labelTemplate: '{value}',
    displayContexts: ['detail'],
  ),
  'claimedByFanId': WorkflowFactPillFieldSchema(
    type: 'fanId',
    maxLines: 2,
    displayIcon: 'person_outline',
    labelTemplate: 'Claimed by: {value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
};

class WorkflowActionButtonRow extends StatelessWidget {
  const WorkflowActionButtonRow({
    super.key,
    required this.surface,
    required this.availableTransitions,
    this.onTransitionPressed,
    this.foreground,
    this.accent,
    this.modernTheme,
    this.waitingText = 'Waiting',
  });

  final String surface;
  final List<WorkflowActionButtonTransition> availableTransitions;
  final WorkflowActionPressed? onTransitionPressed;
  final Color? foreground;
  final Color? accent;
  final LoomCardTheme? modernTheme;
  final String waitingText;

  @override
  Widget build(BuildContext context) {
    final resolvedForeground =
        foreground ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final transition in availableTransitions) ...[
          const SizedBox(height: 8),
          _WorkflowActionRowItem(
            surface: surface,
            transition: transition,
            foreground: resolvedForeground,
            accent: accent,
            modernTheme: modernTheme,
            waitingText: waitingText,
            onPressed: onTransitionPressed == null
                ? null
                : () => onTransitionPressed!(transition.id),
          ),
        ],
      ],
    );
  }
}

class WorkflowFactPillRow extends StatelessWidget {
  const WorkflowFactPillRow({
    super.key,
    required this.instanceData,
    required this.instanceDataSchema,
    this.displayContext = 'tile',
    this.foreground,
    this.accent,
  });

  final Map<String, dynamic> instanceData;
  final Map<String, WorkflowFactPillFieldSchema> instanceDataSchema;
  final String displayContext;
  final Color? foreground;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final resolvedForeground =
        foreground ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87);
    final rows = <Widget>[];
    var hasParagraph = false;
    for (final entry in instanceDataSchema.entries) {
      final field = entry.key;
      final schema = entry.value;
      if (!schema.shouldDisplayInContext(displayContext)) {
        continue;
      }
      final value = instanceData[field];
      if (schema.hideWhenEmpty && _isEmpty(value)) {
        continue;
      }
      final label = _renderLabel(schema.labelTemplate ?? field, value);
      if (label.trim().isEmpty) {
        continue;
      }
      hasParagraph = hasParagraph || _rendersAsParagraph(schema, value);
      rows.add(
        _factWidget(
          context: context,
          field: field,
          schema: schema,
          value: value,
          label: label,
          foreground: resolvedForeground,
        ),
      );
    }
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    if (!hasParagraph) {
      return Wrap(spacing: 8, runSpacing: 8, children: rows);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[row, const SizedBox(height: 8)],
      ],
    );
  }

  static const _paragraphValueLengthThreshold = 80;

  static bool _rendersAsParagraph(
    WorkflowFactPillFieldSchema schema,
    dynamic value,
  ) {
    final type = schema.type.toLowerCase();
    return (type == 'text' || type == 'textarea') &&
        '$value'.length > (schema.maxLength ?? _paragraphValueLengthThreshold);
  }

  Widget _factWidget({
    required BuildContext context,
    required String field,
    required WorkflowFactPillFieldSchema schema,
    required dynamic value,
    required String label,
    required Color foreground,
  }) {
    final type = schema.type.toLowerCase();
    if (_rendersAsParagraph(schema, value)) {
      return _WorkflowFactParagraph(
        key: ValueKey('workflow-fact-paragraph-$field'),
        field: field,
        value: value,
        foreground: foreground,
        accent: accent,
      );
    }
    if (type == 'fanid' || type == 'fanid[]') {
      return _WorkflowFanFact(
        key: ValueKey('workflow-fact-fan-$field'),
        label: label,
        isCollection: type == 'fanid[]',
        foreground: foreground,
        accent: accent,
        maxLines: schema.maxLines,
      );
    }
    if (type == 'url') {
      if (schema.openMode == 'external') {
        return _externalUrlPill(
          key: ValueKey('workflow-fact-url-$field'),
          value: value,
          label: label,
          foreground: foreground,
          iconName: schema.displayIcon,
          maxLines: schema.maxLines,
        );
      }
      if (schema.openMode == 'choice') {
        return _choiceUrlPill(
          context: context,
          value: value,
          embeddedLabel: 'Open embedded',
          externalLabel: 'Open externally',
          externalKey: ValueKey('workflow-fact-url-$field-open-external'),
          embeddedKey: ValueKey('workflow-fact-url-$field-open-embedded'),
          title: label,
          externalIcon: schema.displayIcon,
          foreground: foreground,
        );
      }
      return _SurfaceFactPill(
        icon: Icons.link_off,
        label: '${schema.openMode ?? 'unsupported'}: $label',
        foreground: foreground.withValues(alpha: 0.45),
        accent: accent,
        maxLines: schema.maxLines,
      );
    }
    if (type == 'list' && schema.itemSchema != null && value is List) {
      final itemRows = <Widget>[];
      for (var index = 0; index < value.length; index++) {
        final item = value[index];
        if (item is! Map) {
          continue;
        }
        final memberWidgets = <Widget>[];
        for (final member in schema.itemSchema!.entries) {
          final memberValue = item[member.key];
          if (member.value.hideWhenEmpty && _isEmpty(memberValue)) {
            continue;
          }
          final memberLabel = _renderLabel(
            member.value.labelTemplate ?? member.key,
            memberValue,
          );
          if (memberLabel.trim().isEmpty) {
            continue;
          }

          final memberType = member.value.type.toLowerCase();
          if (memberType == 'url') {
            if (member.value.openMode == 'external') {
              memberWidgets.add(
                _externalUrlPill(
                  key: ValueKey(
                    'workflow-fact-list-url-$field-$index-${member.key}',
                  ),
                  value: memberValue,
                  label: memberLabel,
                  foreground: foreground,
                  iconName: member.value.displayIcon,
                  maxLines: member.value.maxLines,
                ),
              );
            } else if (member.value.openMode == 'choice') {
              memberWidgets.add(
                _choiceUrlPill(
                  context: context,
                  value: memberValue,
                  embeddedLabel: 'Open embedded',
                  externalLabel: 'Open externally',
                  externalKey: ValueKey(
                    'workflow-fact-list-url-$field-$index-${member.key}-open-external',
                  ),
                  embeddedKey: ValueKey(
                    'workflow-fact-list-url-$field-$index-${member.key}-open-embedded',
                  ),
                  title: memberLabel,
                  externalIcon: member.value.displayIcon,
                  foreground: foreground,
                ),
              );
            } else {
              memberWidgets.add(
                _SurfaceFactPill(
                  icon: Icons.link_off,
                  label:
                      '${member.value.openMode ?? 'unsupported'}: $memberLabel',
                  foreground: foreground.withValues(alpha: 0.45),
                  accent: accent,
                  maxLines: member.value.maxLines,
                ),
              );
            }
          } else {
            memberWidgets.add(
              Text(
                memberLabel,
                key: ValueKey(
                  'workflow-fact-list-text-$field-$index-${member.key}',
                ),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
        }
        if (memberWidgets.isNotEmpty) {
          itemRows.add(
            Wrap(
              key: ValueKey('workflow-fact-list-item-$field-$index'),
              spacing: 8,
              runSpacing: 8,
              children: memberWidgets,
            ),
          );
        }
      }
      if (itemRows.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in itemRows) ...[item, const SizedBox(height: 8)],
          ],
        );
      }
    }
    return _SurfaceFactPill(
      icon: _iconForName(schema.displayIcon),
      label: label,
      foreground: foreground,
      accent: accent,
      maxLines: schema.maxLines,
    );
  }

  Widget _externalUrlPill({
    required Key key,
    required dynamic value,
    required String label,
    required Color foreground,
    String? iconName,
    int? maxLines,
  }) {
    return InkWell(
      key: key,
      onTap: value == null
          ? null
          : () async {
              await launchUrl(
                Uri.parse(value.toString()),
                mode: LaunchMode.externalApplication,
              );
            },
      child: _SurfaceFactPill(
        icon: _iconForName(iconName),
        label: label,
        foreground: foreground,
        accent: accent,
        maxLines: maxLines ?? 1,
      ),
    );
  }

  Widget _choiceUrlPill({
    required BuildContext context,
    required dynamic value,
    required String embeddedLabel,
    required String externalLabel,
    required Key externalKey,
    required Key embeddedKey,
    required String title,
    required String? externalIcon,
    required Color foreground,
  }) {
    final url = value?.toString();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        InkWell(
          key: embeddedKey,
          onTap: url == null
              ? null
              : () async =>
                    _openUrlInApp(context: context, url: url, title: title),
          child: _SurfaceFactPill(
            icon: Icons.open_in_new,
            label: embeddedLabel,
            foreground: foreground,
            accent: accent,
          ),
        ),
        _externalUrlPill(
          key: externalKey,
          value: url,
          label: externalLabel,
          foreground: foreground,
          iconName: externalIcon,
        ),
      ],
    );
  }

  Future<void> _openUrlInApp({
    required BuildContext context,
    required String url,
    required String title,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            _DocumentLibraryEmbeddedUrlViewer(url: url, title: title),
      ),
    );
  }
}

class _DocumentLibraryEmbeddedUrlViewer extends StatefulWidget {
  const _DocumentLibraryEmbeddedUrlViewer({
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<_DocumentLibraryEmbeddedUrlViewer> createState() =>
      _DocumentLibraryEmbeddedUrlViewerState();
}

class _DocumentLibraryEmbeddedUrlViewerState
    extends State<_DocumentLibraryEmbeddedUrlViewer> {
  WebViewController? _controller;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initController());
  }

  Future<void> _initController() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Invalid URL.';
        });
      }
      return;
    }
    if (WebViewPlatform.instance == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Embedded web view is unavailable.';
        });
      }
      return;
    }
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadRequest(uri);
      if (mounted) {
        setState(() {
          _controller = controller;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text(_error!));
    } else if (_controller == null) {
      content = const Center(child: Text('Could not create embedded viewer.'));
    } else {
      content = WebViewWidget(controller: _controller!);
    }
    return Scaffold(
      key: const ValueKey('document-library-embedded-viewer'),
      appBar: AppBar(title: Text(widget.title)),
      body: content,
    );
  }
}

class _WorkflowFactParagraph extends StatelessWidget {
  const _WorkflowFactParagraph({
    super.key,
    required this.field,
    required this.value,
    required this.foreground,
    this.accent,
  });

  final String field;
  final dynamic value;
  final Color foreground;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: accent == null ? 0.06 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _humanizeFactField(field),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value?.toString() ?? '',
              softWrap: true,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowFanFact extends StatelessWidget {
  const _WorkflowFanFact({
    super.key,
    required this.label,
    required this.isCollection,
    required this.foreground,
    this.accent,
    this.maxLines = 1,
  });

  final String label;
  final bool isCollection;
  final Color foreground;
  final Color? accent;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? foreground;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: accent == null ? 0.08 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: tint.withValues(alpha: 0.18),
              child: Icon(
                isCollection ? Icons.groups_outlined : Icons.person_outline,
                size: 15,
                color: tint,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _humanizeFactField(String field) => field
    .replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    )
    .replaceAll('_', ' ')
    .replaceFirstMapped(RegExp(r'^.'), (match) => match[0]!.toUpperCase());

class WorkflowCardSurfaceTemplateRenderer extends StatelessWidget {
  const WorkflowCardSurfaceTemplateRenderer({
    super.key,
    required this.surfaceFamily,
    required this.instanceData,
    required this.instanceDataSchema,
    required this.availableTransitions,
    this.onTransitionPressed,
    this.displayContext = 'tile',
    this.foreground,
    this.accent,
    this.actionSurfaceKey,
  });

  final String surfaceFamily;
  final Map<String, dynamic> instanceData;
  final Map<String, WorkflowFactPillFieldSchema> instanceDataSchema;
  final List<WorkflowActionButtonTransition> availableTransitions;
  final WorkflowActionPressed? onTransitionPressed;
  final String displayContext;
  final Color? foreground;
  final Color? accent;
  final String? actionSurfaceKey;

  @override
  Widget build(BuildContext context) {
    final template = workflowCardSurfaceTemplates[surfaceFamily];
    if (template == null) {
      return const SizedBox.shrink();
    }
    final widgets = <Widget>[];
    for (final slot in template.primaryBindingSlots) {
      switch (slot) {
        case WorkflowTemplateSlotKind.workflowActionButtonRow:
          widgets.add(
            WorkflowActionButtonRow(
              surface: actionSurfaceKey ?? surfaceFamily,
              availableTransitions: availableTransitions,
              onTransitionPressed: onTransitionPressed,
              foreground: foreground,
              accent: accent,
            ),
          );
        case WorkflowTemplateSlotKind.workflowFactPillRow:
          widgets.add(
            WorkflowFactPillRow(
              instanceData: instanceData,
              instanceDataSchema: instanceDataSchema,
              displayContext: displayContext,
              foreground: foreground,
              accent: accent,
            ),
          );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets
          .expand((entry) => [const SizedBox(height: 8), entry])
          .toList(),
    );
  }
}

class _WorkflowActionRowItem extends StatelessWidget {
  const _WorkflowActionRowItem({
    required this.surface,
    required this.transition,
    required this.foreground,
    required this.onPressed,
    this.accent,
    this.modernTheme,
    required this.waitingText,
  });

  final String surface;
  final WorkflowActionButtonTransition transition;
  final Color foreground;
  final Color? accent;
  final LoomCardTheme? modernTheme;
  final VoidCallback? onPressed;
  final String waitingText;

  @override
  Widget build(BuildContext context) {
    final controlKey = ValueKey('$_buttonKeyBase-${transition.id}');
    if (transition.waitingForPrerequisite) {
      return Align(
        alignment: Alignment.centerRight,
        child: _StateBadge(
          key: controlKey,
          icon: Icons.schedule,
          label: transition.waitingText.trim().isEmpty
              ? waitingText
              : transition.waitingText,
          foreground: foreground,
          accent: accent,
        ),
      );
    }
    final icon = _iconForName(transition.iconName);
    final toneColor = _toneColor(transition.tone, context);
    final themedButton = switch (transition.tone) {
      WorkflowActionTone.primary => _buttonStyleFor(modernTheme?.primaryButton),
      WorkflowActionTone.secondary => _buttonStyleFor(
        modernTheme?.secondaryButton,
      ),
      WorkflowActionTone.destructive => null,
    };
    final themedForeground = switch (transition.tone) {
      WorkflowActionTone.primary =>
        modernTheme?.primaryButton?.resolvedForeground,
      WorkflowActionTone.secondary =>
        modernTheme?.secondaryButton?.resolvedForeground,
      WorkflowActionTone.destructive => null,
    };
    switch (transition.tone) {
      case WorkflowActionTone.secondary:
        return OutlinedButton.icon(
          key: controlKey,
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(transition.label),
          style:
              themedButton ??
              OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground.withValues(alpha: 0.45)),
              ),
        );
      case WorkflowActionTone.primary:
        return FilledButton.icon(
          key: controlKey,
          onPressed: onPressed,
          icon: Icon(icon, color: themedForeground ?? Colors.white),
          label: Text(
            transition.label,
            style: TextStyle(color: themedForeground ?? Colors.white),
          ),
          style:
              themedButton ??
              FilledButton.styleFrom(
                backgroundColor: toneColor,
                foregroundColor: Colors.white,
              ),
        );
      case WorkflowActionTone.destructive:
        return FilledButton.icon(
          key: controlKey,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            transition.label,
            style: const TextStyle(color: Colors.white),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: toneColor,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  String get _buttonKeyBase => '$surface-action';
}

Color _toneColor(WorkflowActionTone tone, BuildContext context) {
  switch (tone) {
    case WorkflowActionTone.primary:
      return Theme.of(context).colorScheme.primary;
    case WorkflowActionTone.secondary:
      return Theme.of(context).colorScheme.secondary;
    case WorkflowActionTone.destructive:
      return Colors.red.shade700;
  }
}

bool _isEmpty(Object? value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  if (value is bool) return false;
  if (value is num) return false;
  return false;
}

String _renderLabel(String template, Object? rawValue) {
  final valueLength = _valueLength(rawValue);
  final valueText = _valueText(rawValue);
  return template
      .replaceAll('{value.length}', '$valueLength')
      .replaceAll('{value}', valueText)
      .trim();
}

String _valueText(Object? rawValue) {
  if (rawValue == null) return '';
  if (rawValue is Iterable) {
    if (rawValue.isEmpty) return '';
    return rawValue
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .join(', ');
  }
  if (rawValue is String) {
    return _looksLikeIdentifierValue(rawValue)
        ? humanizeIdentifierValue(rawValue)
        : rawValue;
  }
  if (rawValue is bool) {
    return rawValue ? 'Yes' : 'No';
  }
  return '$rawValue';
}

String humanizeIdentifierValue(String rawValue) {
  final spaced = rawValue
      .trim()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAllMapped(
        RegExp(r'(?<=[a-z0-9])([A-Z])'),
        (match) => ' ${match.group(0)}',
      );
  return spaced
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map(
        // A word that is already all-uppercase (e.g. "TBD", "HOA") reads as
        // an intentional acronym, not a raw camelCase/snake_case identifier
        // -- title-casing it would make it less readable, not more.
        (word) => word == word.toUpperCase()
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

bool _looksLikeIdentifierValue(String rawValue) {
  final value = rawValue.trim();
  if (value.contains(' ')) return false;
  return RegExp(r'^[A-Za-z][A-Za-z0-9_-]*$').hasMatch(value);
}

int _valueLength(Object? rawValue) {
  if (rawValue == null) return 0;
  if (rawValue is String) return rawValue.length;
  if (rawValue is Iterable) return rawValue.length;
  return 0;
}

IconData _iconForName(String? iconName) {
  switch (iconName) {
    case 'title':
      return Icons.title;
    case 'category_outlined':
      return Icons.category_outlined;
    case 'inventory_2_outlined':
      return Icons.inventory_2_outlined;
    case 'verified_outlined':
      return Icons.verified_outlined;
    case 'person_outline':
      return Icons.person_outline;
    case 'groups_outlined':
      return Icons.groups_outlined;
    case 'calendar_today_outlined':
      return Icons.calendar_today_outlined;
    case 'location_on_outlined':
      return Icons.location_on_outlined;
    case 'event_available':
      return Icons.event_available;
    case 'event_busy':
      return Icons.event_busy;
    case 'help_outline':
      return Icons.help_outline;
    case 'groups':
      return Icons.groups;
    case 'hourglass_empty':
      return Icons.hourglass_empty;
    case 'notifications_active':
      return Icons.notifications_active;
    case 'payments_outlined':
      return Icons.payments_outlined;
    case 'receipt_long':
      return Icons.receipt_long;
    case 'account_balance_outlined':
      return Icons.account_balance_outlined;
    case 'repeat':
      return Icons.repeat;
    case 'schedule':
      return Icons.schedule;
    case 'arrow_forward':
      return Icons.arrow_forward;
    case 'add_circle_outline':
      return Icons.add_circle_outline;
    case 'remove_circle_outline':
      return Icons.remove_circle_outline;
    case 'keyboard_return':
      return Icons.keyboard_return;
    case 'check_circle':
      return Icons.check_circle;
    case 'undo':
      return Icons.undo;
    case 'send':
      return Icons.send;
    case 'check_circle_outline':
      return Icons.check_circle_outline;
    case 'archive':
      return Icons.archive;
    case 'calendar_today':
      return Icons.calendar_today;
    case 'campaign':
      return Icons.campaign;
    case 'cancel':
      return Icons.cancel;
    case 'casino':
      return Icons.casino;
    case 'check':
      return Icons.check;
    case 'delete_outline':
      return Icons.delete_outline;
    case 'event_seat':
      return Icons.event_seat;
    case 'forum':
      return Icons.forum;
    case 'gavel':
      return Icons.gavel;
    case 'how_to_vote':
      return Icons.how_to_vote;
    case 'how_to_vote_outlined':
      return Icons.how_to_vote_outlined;
    case 'mark_email_read':
      return Icons.mark_email_read;
    default:
      return Icons.label_outline;
  }
}
