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
    this.displayIcon,
    this.labelTemplate,
    this.hideWhenEmpty = false,
    this.displayContexts,
  });

  final String? displayIcon;
  final String? labelTemplate;
  final bool hideWhenEmpty;
  final List<String>? displayContexts;

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
    displayIcon: 'payments_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'purpose': WorkflowFactPillFieldSchema(
    displayIcon: 'receipt_long',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'recipient': WorkflowFactPillFieldSchema(
    displayIcon: 'account_balance_outlined',
    labelTemplate: 'Recipient: {value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'cadence': WorkflowFactPillFieldSchema(
    displayIcon: 'repeat',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'entitlement': WorkflowFactPillFieldSchema(
    displayIcon: 'verified_outlined',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
eventRsvpDefaultInstanceDataSchema = {
  'eventDate': WorkflowFactPillFieldSchema(
    displayIcon: 'calendar_today_outlined',
    labelTemplate: '{value}',
    displayContexts: ['detail'],
  ),
  'eventDateTime': WorkflowFactPillFieldSchema(
    displayIcon: 'schedule',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'host': WorkflowFactPillFieldSchema(
    displayIcon: 'person_outline',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'location': WorkflowFactPillFieldSchema(
    displayIcon: 'location_on_outlined',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'capacityLabel': WorkflowFactPillFieldSchema(
    displayIcon: 'groups_outlined',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'rsvpStatus': WorkflowFactPillFieldSchema(
    displayIcon: 'event_available',
    labelTemplate: 'Your RSVP: {value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'waitlistedPersonaIds': WorkflowFactPillFieldSchema(
    displayIcon: 'hourglass_empty',
    labelTemplate: 'Waitlist: {value.length}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
  'reminderState': WorkflowFactPillFieldSchema(
    displayIcon: 'notifications_active',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
equipmentLoanDefaultInstanceDataSchema = {
  'title': WorkflowFactPillFieldSchema(
    displayIcon: 'title',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'category': WorkflowFactPillFieldSchema(
    displayIcon: 'category_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'condition': WorkflowFactPillFieldSchema(
    displayIcon: 'verified_outlined',
    labelTemplate: '{value}',
    displayContexts: ['detail'],
  ),
  'holderPersonaId': WorkflowFactPillFieldSchema(
    displayIcon: 'person_outline',
    labelTemplate: 'Holder: {value}',
    displayContexts: ['tile', 'detail'],
  ),
  'queuedPersonaIds': WorkflowFactPillFieldSchema(
    displayIcon: 'groups_outlined',
    labelTemplate: 'Queue: {value.length}',
    hideWhenEmpty: true,
    displayContexts: ['tile', 'detail'],
  ),
  'dueDate': WorkflowFactPillFieldSchema(
    displayIcon: 'schedule',
    labelTemplate: '{value}',
    hideWhenEmpty: true,
    displayContexts: ['detail'],
  ),
};

const Map<String, WorkflowFactPillFieldSchema>
equipmentGiveawayDefaultInstanceDataSchema = {
  'title': WorkflowFactPillFieldSchema(
    displayIcon: 'title',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'category': WorkflowFactPillFieldSchema(
    displayIcon: 'category_outlined',
    labelTemplate: '{value}',
    displayContexts: ['tile', 'detail'],
  ),
  'condition': WorkflowFactPillFieldSchema(
    displayIcon: 'verified_outlined',
    labelTemplate: '{value}',
    displayContexts: ['detail'],
  ),
  'claimedByPersonaId': WorkflowFactPillFieldSchema(
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
    this.waitingText = 'Waiting',
  });

  final String surface;
  final List<WorkflowActionButtonTransition> availableTransitions;
  final WorkflowActionPressed? onTransitionPressed;
  final Color? foreground;
  final Color? accent;
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
      rows.add(
        _SurfaceFactPill(
          icon: _iconForName(schema.displayIcon),
          label: label,
          foreground: resolvedForeground,
          accent: accent,
        ),
      );
    }
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(spacing: 8, runSpacing: 8, children: rows);
  }
}

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
    required this.waitingText,
  });

  final String surface;
  final WorkflowActionButtonTransition transition;
  final Color foreground;
  final Color? accent;
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
    switch (transition.tone) {
      case WorkflowActionTone.secondary:
        return OutlinedButton.icon(
          key: controlKey,
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(transition.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            side: BorderSide(color: foreground.withValues(alpha: 0.45)),
          ),
        );
      case WorkflowActionTone.primary:
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
    default:
      return Icons.label_outline;
  }
}
