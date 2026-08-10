part of '../loom_communities_app_shell.dart';

enum WorkflowTemplateSlotKind { workflowActionButtonRow, workflowFactPillRow }

class WorkflowAudienceSelectorField extends StatefulWidget {
  final List<String> availablePersonaIds;
  final Map<String, dynamic> initialInstanceData;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const WorkflowAudienceSelectorField({
    super.key,
    required this.availablePersonaIds,
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
  late Set<String> _selectedPersonaIds;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialInstanceData['audienceScope'] as String? ?? 'all';
    final initialIds = widget.initialInstanceData['invitedPersonaIds'];
    _selectedPersonaIds = initialIds is Iterable
        ? initialIds.map((id) => '$id').toSet()
        : <String>{};
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _setScope(String scope) {
    setState(() {
      _scope = scope;
      if (scope == 'all') {
        _selectedPersonaIds.clear();
      } else if (scope == 'individual' && _selectedPersonaIds.length > 1) {
        final first = _selectedPersonaIds.first;
        _selectedPersonaIds = {first};
      }
    });
    _emit();
  }

  void _togglePersona(String personaId, bool selected) {
    setState(() {
      if (_scope == 'individual') {
        _selectedPersonaIds = selected ? {personaId} : <String>{};
      } else if (selected) {
        _selectedPersonaIds.add(personaId);
      } else {
        _selectedPersonaIds.remove(personaId);
      }
    });
    _emit();
  }

  void _emit() {
    widget.onChanged({
      'audienceScope': _scope,
      'invitedPersonaIds': _scope == 'all'
          ? <String>[]
          : _selectedPersonaIds.toList(growable: false),
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
            children: widget.availablePersonaIds
                .map(
                  (personaId) => CheckboxListTile(
                    key: ValueKey('audience-selector-persona-$personaId'),
                    title: Text(personaId),
                    value: _selectedPersonaIds.contains(personaId),
                    onChanged: (selected) =>
                        _togglePersona(personaId, selected ?? false),
                  ),
                )
                .toList(growable: false),
          ),
        if (_scope == 'individual')
          Column(
            key: const ValueKey('audience-selector-individual'),
            children: widget.availablePersonaIds
                .map(
                  (personaId) => ListTile(
                    key: ValueKey('audience-selector-persona-$personaId'),
                    title: Text(personaId),
                    selected: _selectedPersonaIds.contains(personaId),
                    trailing: _selectedPersonaIds.contains(personaId)
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () => _togglePersona(personaId, true),
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
    this.displayIcon,
    this.labelTemplate,
    this.hideWhenEmpty = false,
    this.displayContexts,
    this.openMode,
    this.itemSchema,
  });

  final String type;
  final int? maxLength;
  final String? displayIcon;
  final String? labelTemplate;
  final bool hideWhenEmpty;
  final List<String>? displayContexts;
  final String? openMode;
  final Map<String, WorkflowFactPillFieldSchema>? itemSchema;

  bool shouldDisplayInContext(String context) {
    if (displayContexts == null || displayContexts!.isEmpty) return true;
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
  'waitlistedPersonaIds': WorkflowFactPillFieldSchema(
    type: 'personaId[]',
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
  'holderPersonaId': WorkflowFactPillFieldSchema(
    type: 'personaId',
    displayIcon: 'person_outline',
    labelTemplate: 'Holder: {value}',
    displayContexts: ['tile', 'detail'],
  ),
  'queuedPersonaIds': WorkflowFactPillFieldSchema(
    type: 'personaId[]',
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
  'claimedByPersonaId': WorkflowFactPillFieldSchema(
    type: 'personaId',
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
    if (type == 'personaid' || type == 'personaid[]') {
      return _WorkflowPersonaFact(
        key: ValueKey('workflow-fact-persona-$field'),
        label: label,
        isCollection: type == 'personaid[]',
        foreground: foreground,
        accent: accent,
      );
    }
    if (type == 'url') {
      if (schema.openMode == 'external') {
        return InkWell(
          key: ValueKey('workflow-fact-url-$field'),
          onTap: value == null
              ? null
              : () async {
                  await launchUrl(
                    Uri.parse(value.toString()),
                    mode: LaunchMode.externalApplication,
                  );
                },
          child: _SurfaceFactPill(
            icon: _iconForName(schema.displayIcon),
            label: label,
            foreground: foreground,
            accent: accent,
          ),
        );
      }
      return _SurfaceFactPill(
        icon: Icons.link_off,
        label: '${schema.openMode ?? 'unsupported'}: $label',
        foreground: foreground.withValues(alpha: 0.45),
        accent: accent,
      );
    }
    if (type == 'list' &&
        schema.itemSchema != null &&
        value is List) {
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
                InkWell(
                  key: ValueKey(
                    'workflow-fact-list-url-$field-$index-${member.key}',
                  ),
                  onTap: memberValue == null
                      ? null
                      : () async {
                          await launchUrl(
                            Uri.parse(memberValue.toString()),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                  child: _SurfaceFactPill(
                    icon: _iconForName(member.value.displayIcon),
                    label: memberLabel,
                    foreground: foreground,
                    accent: accent,
                  ),
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
            for (final item in itemRows) ...[
              item,
              const SizedBox(height: 8),
            ],
          ],
        );
      }
    }
    return _SurfaceFactPill(
      icon: _iconForName(schema.displayIcon),
      label: label,
      foreground: foreground,
      accent: accent,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowPersonaFact extends StatelessWidget {
  const _WorkflowPersonaFact({
    super.key,
    required this.label,
    required this.isCollection,
    required this.foreground,
    this.accent,
  });

  final String label;
  final bool isCollection;
  final Color foreground;
  final Color? accent;

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
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
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
  return '$rawValue';
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
