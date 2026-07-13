part of '../loom_communities_app_shell.dart';

LoomExperienceDefinition experienceForExtensionId(
  String extensionId, {
  String? displayName,
  Map<String, Object?> experienceConfiguration = const {},
}) {
  final packageExperience = _experienceFromConfiguration(
    extensionId,
    displayName: displayName,
    experienceConfiguration: experienceConfiguration,
  );
  if (packageExperience != null) {
    return packageExperience;
  }
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

/// Parses a package-declared `experience` block (from `loom.initialization.json`
/// or `loom.extension.json`) into a [LoomExperienceDefinition]. Returns null
/// when the block is absent or does not contain at least one valid workflow,
/// so callers fall back to the hardcoded demo catalog.
LoomExperienceDefinition? _experienceFromConfiguration(
  String extensionId, {
  String? displayName,
  required Map<String, Object?> experienceConfiguration,
}) {
  if (experienceConfiguration.isEmpty) {
    return null;
  }
  final workflowsRaw = experienceConfiguration['workflows'];
  if (workflowsRaw is! List) {
    return null;
  }
  final workflows = <LoomWorkflowDefinition>[
    for (final entry in workflowsRaw)
      if (entry is Map<String, Object?>)
        if (_parseWorkflowDefinition(entry) case final workflow?) workflow,
  ];
  if (workflows.isEmpty) {
    return null;
  }

  List<LoomPersonaDefinition>? personas;
  final personasRaw = experienceConfiguration['personas'];
  if (personasRaw is List) {
    final parsed = <LoomPersonaDefinition>[
      for (final entry in personasRaw)
        if (entry is Map<String, Object?>)
          if (_parsePersonaDefinition(entry) case final persona?) persona,
    ];
    if (parsed.isNotEmpty) {
      personas = parsed;
    }
  }

  Map<String, LoomWorkflowPersonaPolicy>? personaPolicies;
  final policiesRaw = experienceConfiguration['personaPolicies'];
  if (policiesRaw is Map<String, Object?>) {
    final parsed = <String, LoomWorkflowPersonaPolicy>{};
    for (final entry in policiesRaw.entries) {
      final value = entry.value;
      if (value is Map<String, Object?>) {
        parsed[entry.key] = _parsePersonaPolicyDefinition(value);
      }
    }
    if (parsed.isNotEmpty) {
      personaPolicies = parsed;
    }
  }

  final themeRaw = experienceConfiguration['theme'];

  List<LoomMessageThread>? threads;
  final threadsRaw = experienceConfiguration['threads'];
  if (threadsRaw is List) {
    final parsed = <LoomMessageThread>[
      for (final entry in threadsRaw)
        if (entry is Map<String, Object?>)
          if (_parseThread(entry) case final thread?) thread,
    ];
    if (parsed.isNotEmpty) threads = parsed;
  }

  List<LoomNotificationItem>? notifications;
  final notificationsRaw = experienceConfiguration['notifications'];
  if (notificationsRaw is List) {
    final parsed = <LoomNotificationItem>[
      for (final entry in notificationsRaw)
        if (entry is Map<String, Object?>)
          if (_parseNotificationItem(entry) case final notification?)
            notification,
    ];
    if (parsed.isNotEmpty) notifications = parsed;
  }
  final exportWizard = _parseExportWizardSeed(
    experienceConfiguration['exportWizard'],
  );
  List<LoomVolunteerShiftSeed>? volunteerShifts;
  final volunteerShiftsRaw = experienceConfiguration['volunteerShifts'];
  if (volunteerShiftsRaw is List) {
    final parsed = <LoomVolunteerShiftSeed>[
      for (final entry in volunteerShiftsRaw)
        if (entry is Map<String, Object?>)
          if (_parseVolunteerShiftSeed(entry) case final shift?) shift,
    ];
    if (parsed.isNotEmpty) volunteerShifts = parsed;
  }

  // Parse marketplace templates first (listings may reference them)
  LoomListingStateMachine? marketplaceTemplate;
  final Map<String, LoomListingStateMachine> marketplaceTemplateMap = {};
  final marketplaceRaw = experienceConfiguration['marketplace'];
  if (marketplaceRaw is Map<String, Object?>) {
    final templatesRaw = marketplaceRaw['templates'];
    if (templatesRaw is Map<String, Object?>) {
      for (final entry in templatesRaw.entries) {
        final value = entry.value;
        if (value is Map<String, Object?>) {
          final parsed = _parseListingStateMachine(value);
          if (parsed != null) {
            marketplaceTemplateMap[entry.key] = parsed;
          }
        }
      }
    }
  }
  // Default template (first available) for backward compatibility
  marketplaceTemplate = marketplaceTemplateMap.values.firstOrNull;

  List<LoomMarketplaceListing>? marketplaceListings;
  final listingsRaw = experienceConfiguration['marketplaceListings'];
  if (listingsRaw is List) {
    final parsed = <LoomMarketplaceListing>[
      for (final entry in listingsRaw)
        if (entry is Map<String, Object?>)
          if (_parseListing(entry, marketplaceTemplateMap) case final listing?)
            listing,
    ];
    if (parsed.isNotEmpty) marketplaceListings = parsed;
  }

  return LoomExperienceDefinition(
    extensionId: extensionId,
    displayName: _shellStringOr(
      experienceConfiguration['displayName'],
      displayName ?? 'Local Community',
    ),
    tagline: _shellStringOr(
      experienceConfiguration['tagline'],
      'Local community tools and member actions.',
    ),
    accentColor:
        _parseShellHexColor(experienceConfiguration['accentColor']) ??
        0xff246b62,
    workflows: workflows,
    personas: personas,
    personaPolicies: personaPolicies,
    themeOverride: _parseCardTheme(themeRaw),
    tabThemeOverrides: _parseTabThemes(
      themeRaw is Map<String, Object?> ? themeRaw['tabThemes'] : null,
    ),
    threads: threads,
    notifications: notifications,
    exportWizard: exportWizard,
    volunteerShifts: volunteerShifts,
    marketplaceListings: marketplaceListings,
    marketplaceTemplate: marketplaceTemplate,
  );
}

LoomWorkflowDefinition? _parseWorkflowDefinition(Map<String, Object?> map) {
  final workflowId = map['workflowId'];
  final title = map['title'];
  final entryText = map['entryText'];
  final actionText = map['actionText'];
  final resultText = map['resultText'];
  if (workflowId is! String ||
      workflowId.isEmpty ||
      title is! String ||
      title.isEmpty ||
      entryText is! String ||
      actionText is! String ||
      resultText is! String) {
    return null;
  }
  return LoomWorkflowDefinition(
    workflowId: workflowId,
    title: title,
    entryText: entryText,
    actionText: actionText,
    resultText: resultText,
    calendarItem: _parseCalendarItem(map['calendar']),
    responseChoices: _parseResponseChoices(map['responseChoices']),
    theme: _parseCardTheme(map['theme']),
    givingPayment: _parseGivingPayment(map['givingPayment']),
    documentLibrary: _parseDocumentLibrary(map['documentLibrary']),
    architecturalRequest: _parseArchitecturalRequest(
      map['architecturalRequest'],
    ),
  );
}

/// Parses an optional per-scope card theme block (community-level
/// `experience.theme`, a `tabThemes.<tabId>` entry, or a per-workflow
/// `theme` block) — every field is optional, matching [LoomCardTheme]'s
/// partial/overridable shape. Returns null when [value] isn't a map or has
/// no recognized theme keys, so callers keep inheriting from their parent
/// scope.
LoomCardTheme? _parseCardTheme(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }
  final accent = _parseShellHexColor(value['accent']);
  final fillColor = _parseShellHexColor(value['fillColor']);
  final borderColor = _parseShellHexColor(value['borderColor']);
  final headingColor = _parseShellHexColor(value['headingColor']);
  final bodyColor = _parseShellHexColor(value['bodyColor']);
  final theme = LoomCardTheme(
    accent: accent != null ? Color(accent) : null,
    fillColor: fillColor != null ? Color(fillColor) : null,
    fillOpacity: _shellDoubleOr(value['fillOpacity']),
    borderColor: borderColor != null ? Color(borderColor) : null,
    borderOpacity: _shellDoubleOr(value['borderOpacity']),
    borderWidth: _shellDoubleOr(value['borderWidth']),
    headingColor: headingColor != null ? Color(headingColor) : null,
    headingOpacity: _shellDoubleOr(value['headingOpacity']),
    headingWeight: _parseFontWeight(value['headingWeight']),
    bodyColor: bodyColor != null ? Color(bodyColor) : null,
    bodyOpacity: _shellDoubleOr(value['bodyOpacity']),
    cornerRadius: _shellDoubleOr(value['cornerRadius']),
    elevation: _shellDoubleOr(value['elevation']),
    shadowOpacity: _shellDoubleOr(value['shadowOpacity']),
    primaryButton: _parseButtonTheme(value['primaryButton']),
    secondaryButton: _parseButtonTheme(value['secondaryButton']),
  );
  final isEmpty =
      theme.accent == null &&
      theme.fillColor == null &&
      theme.fillOpacity == null &&
      theme.borderColor == null &&
      theme.borderOpacity == null &&
      theme.borderWidth == null &&
      theme.headingColor == null &&
      theme.headingOpacity == null &&
      theme.headingWeight == null &&
      theme.bodyColor == null &&
      theme.bodyOpacity == null &&
      theme.cornerRadius == null &&
      theme.elevation == null &&
      theme.shadowOpacity == null &&
      theme.primaryButton == null &&
      theme.secondaryButton == null;
  return isEmpty ? null : theme;
}

LoomButtonTheme? _parseButtonTheme(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }
  final fillColor = _parseShellHexColor(value['fillColor']);
  final borderColor = _parseShellHexColor(value['borderColor']);
  final foregroundColor = _parseShellHexColor(value['foregroundColor']);
  return LoomButtonTheme(
    fillColor: fillColor != null ? Color(fillColor) : null,
    fillOpacity: _shellDoubleOr(value['fillOpacity']),
    borderColor: borderColor != null ? Color(borderColor) : null,
    borderOpacity: _shellDoubleOr(value['borderOpacity']),
    borderWidth: _shellDoubleOr(value['borderWidth']),
    foregroundColor: foregroundColor != null ? Color(foregroundColor) : null,
    foregroundOpacity: _shellDoubleOr(value['foregroundOpacity']),
    shape: _parseButtonShape(value['shape']),
    labelWeight: _parseFontWeight(value['labelWeight']),
  );
}

LoomButtonShape? _parseButtonShape(Object? value) {
  switch (value) {
    case 'pill':
      return LoomButtonShape.pill;
    case 'rounded':
      return LoomButtonShape.rounded;
    case 'square':
      return LoomButtonShape.square;
  }
  return null;
}

FontWeight? _parseFontWeight(Object? value) {
  if (value is! String) {
    return null;
  }
  switch (value) {
    case 'w400':
    case 'regular':
      return FontWeight.w400;
    case 'w500':
    case 'medium':
      return FontWeight.w500;
    case 'w600':
    case 'semibold':
      return FontWeight.w600;
    case 'w700':
    case 'bold':
      return FontWeight.w700;
    case 'w800':
    case 'extrabold':
      return FontWeight.w800;
  }
  return null;
}

/// Parses a `tabThemes` map (`{ "<tabId>": { ...LoomCardTheme fields... } }`)
/// into per-tab [LoomCardTheme] overrides, dropping any entry that isn't a
/// valid theme block. Returns an empty map when [value] is absent or has no
/// valid entries.
Map<String, LoomCardTheme> _parseTabThemes(Object? value) {
  if (value is! Map<String, Object?>) {
    return const {};
  }
  final parsed = <String, LoomCardTheme>{};
  for (final entry in value.entries) {
    final theme = _parseCardTheme(entry.value);
    if (theme != null) {
      parsed[entry.key] = theme;
    }
  }
  return parsed;
}

double? _shellDoubleOr(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

List<LoomWorkflowResponseChoice>? _parseResponseChoices(Object? value) {
  if (value is! List) {
    return null;
  }
  final choices = <LoomWorkflowResponseChoice>[
    for (final entry in value)
      if (entry is Map<String, Object?>)
        if (_parseResponseChoice(entry) case final choice?) choice,
  ];
  return choices.isEmpty ? null : choices;
}

LoomWorkflowResponseChoice? _parseResponseChoice(Map<String, Object?> map) {
  final responseId = map['responseId'];
  final label = map['label'];
  if (responseId is! String || responseId.isEmpty || label is! String) {
    return null;
  }
  return LoomWorkflowResponseChoice(
    responseId: responseId,
    label: label,
    isDestructive: map['isDestructive'] == true,
  );
}

LoomCalendarItem? _parseCalendarItem(Object? value) {
  if (value is! Map<String, Object?>) {
    return null;
  }
  final date = value['date'];
  if (date is! String || date.isEmpty) {
    return null;
  }
  final time = value['time'];
  final dateTime = DateTime.tryParse(
    time is String && time.isNotEmpty ? '${date}T$time:00' : date,
  );
  if (dateTime == null) {
    return null;
  }
  final location = value['location'];
  final capacityLabel = value['capacityLabel'];
  final host = value['host'];
  return LoomCalendarItem(
    dateTime: dateTime,
    location: location is String ? location : null,
    capacityLabel: capacityLabel is String ? capacityLabel : null,
    host: host is String ? host : null,
  );
}

LoomGivingPayment? _parseGivingPayment(Object? value) {
  if (value is! Map<String, Object?>) return null;
  final amountLabel = value['amountLabel'];
  if (amountLabel is! String || amountLabel.isEmpty) return null;
  return LoomGivingPayment(
    amountLabel: amountLabel,
    purpose: value['purpose'] as String?,
    recipient: value['recipient'] as String?,
    cadence: value['cadence'] as String?,
    entitlement: value['entitlement'] as String?,
  );
}

LoomDocumentLibrary? _parseDocumentLibrary(Object? value) {
  if (value is! Map<String, Object?>) return null;
  final documentsRaw = value['documents'];
  if (documentsRaw is! List) return null;
  final documents = <LoomDocumentItem>[
    for (final entry in documentsRaw)
      if (entry is Map<String, Object?>)
        if (_parseDocumentItem(entry) case final document?) document,
  ];
  if (documents.isEmpty) return null;
  final declaredCategories = _shellStringList(value['categories']);
  final categories = declaredCategories.isNotEmpty
      ? declaredCategories
      : <String>{for (final document in documents) document.category}.toList();
  return LoomDocumentLibrary(categories: categories, documents: documents);
}

LoomArchitecturalRequest? _parseArchitecturalRequest(Object? value) {
  if (value is! Map<String, Object?>) return null;
  final projectTypes = _shellStringList(value['projectTypes']);
  return LoomArchitecturalRequest(
    projectTypes: projectTypes.isEmpty
        ? const ['Exterior change']
        : projectTypes,
    defaultProjectDescription: _shellStringOr(
      value['defaultProjectDescription'],
      'Fence color update with matching trim sample.',
    ),
    defaultPropertyAddress: _shellStringOr(
      value['defaultPropertyAddress'],
      'Lot 42, Cedar Commons',
    ),
    defaultRequestedCompletionDate: _shellStringOr(
      value['defaultRequestedCompletionDate'],
      '2026-08-15',
    ),
    defaultAttachments: _shellStringOr(
      value['defaultAttachments'],
      'paint-chip.pdf, elevation-photo.jpg',
    ),
  );
}

LoomDocumentItem? _parseDocumentItem(Map<String, Object?> map) {
  final documentId = map['documentId'];
  final title = map['title'];
  final category = map['category'];
  final version = map['version'];
  final updatedLabel = map['updatedLabel'];
  final accessState = map['accessState'];
  if (documentId is! String ||
      documentId.isEmpty ||
      title is! String ||
      title.isEmpty ||
      category is! String ||
      category.isEmpty ||
      version is! String ||
      version.isEmpty ||
      updatedLabel is! String ||
      updatedLabel.isEmpty ||
      accessState is! String ||
      accessState.isEmpty) {
    return null;
  }
  return LoomDocumentItem(
    documentId: documentId,
    title: title,
    category: category,
    version: version,
    updatedLabel: updatedLabel,
    accessState: accessState,
    summary: map['summary'] as String?,
    embeddedLabel: map['embeddedLabel'] as String? ?? 'Open embedded',
    externalLabel: map['externalLabel'] as String? ?? 'Open external',
    acknowledgeLabel: map['acknowledgeLabel'] as String? ?? 'Acknowledge',
    requestAccessLabel:
        map['requestAccessLabel'] as String? ?? 'Request access',
  );
}

LoomMessageThread? _parseThread(Map<String, Object?> map) {
  final threadId = map['threadId'];
  final subject = map['subject'];
  if (threadId is! String || threadId.isEmpty || subject is! String)
    return null;
  final participantPersonaIds = _shellStringList(map['participantPersonaIds']);
  final messagesRaw = map['messages'];
  final messages = <LoomMessage>[];
  if (messagesRaw is List) {
    for (final entry in messagesRaw) {
      if (entry is Map<String, Object?>) {
        final parsed = _parseMessage(entry);
        if (parsed != null) messages.add(parsed);
      }
    }
  }
  return LoomMessageThread(
    threadId: threadId,
    subject: subject,
    participantPersonaIds: participantPersonaIds,
    messages: messages,
    muted: map['muted'] == true,
    archived: map['archived'] == true,
  );
}

LoomMessage? _parseMessage(Map<String, Object?> map) {
  final messageId = map['messageId'];
  final senderPersonaId = map['senderPersonaId'];
  final body = map['body'];
  if (messageId is! String ||
      messageId.isEmpty ||
      senderPersonaId is! String ||
      body is! String)
    return null;
  final timestamp =
      DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now();
  return LoomMessage(
    messageId: messageId,
    senderPersonaId: senderPersonaId,
    body: body,
    timestamp: timestamp,
  );
}

LoomNotificationItem? _parseNotificationItem(Map<String, Object?> map) {
  final notificationId = map['notificationId'];
  final title = map['title'];
  final body = map['body'];
  final source = map['source'];
  final timestamp = DateTime.tryParse(map['timestamp'] as String? ?? '');
  if (notificationId is! String ||
      notificationId.isEmpty ||
      title is! String ||
      title.isEmpty ||
      body is! String ||
      body.isEmpty ||
      source is! String ||
      source.isEmpty ||
      timestamp == null) {
    return null;
  }
  return LoomNotificationItem(
    notificationId: notificationId,
    title: title,
    body: body,
    source: source,
    timestamp: timestamp,
    recipientPersonaIds: _shellStringList(map['recipientPersonaIds']),
    isUnread: map['isUnread'] != false,
  );
}

LoomExportWizardSeed? _parseExportWizardSeed(Object? value) {
  if (value is! Map<String, Object?>) return null;
  final wizardId = value['wizardId'];
  final scope = _shellStringList(value['scope']);
  if (wizardId is! String || wizardId.isEmpty || scope.isEmpty) return null;
  return LoomExportWizardSeed(wizardId: wizardId, scope: scope);
}

LoomVolunteerShiftSeed? _parseVolunteerShiftSeed(Map<String, Object?> map) {
  final shiftId = map['shiftId'];
  final title = map['title'];
  final capacity = map['capacity'];
  final filled = map['filled'];
  if (shiftId is! String ||
      shiftId.isEmpty ||
      title is! String ||
      title.isEmpty ||
      capacity is! int ||
      capacity <= 0 ||
      (filled != null && filled is! int) ||
      (filled is int && (filled < 0 || filled > capacity))) {
    return null;
  }
  return LoomVolunteerShiftSeed(
    shiftId: shiftId,
    title: title,
    capacity: capacity,
    filled: filled as int? ?? 0,
  );
}

LoomMarketplaceListing? _parseListing(
  Map<String, Object?> map,
  Map<String, LoomListingStateMachine> marketplaceTemplateMap,
) {
  final listingId = map['listingId'];
  final title = map['title'];
  if (listingId is! String ||
      listingId.isEmpty ||
      title is! String ||
      title.isEmpty)
    return null;

  LoomListingStateMachine? resolvedStateMachine;
  // 1) Inline stateMachine overrides everything
  final smRaw = map['stateMachine'];
  if (smRaw is Map<String, Object?>) {
    resolvedStateMachine = _parseListingStateMachine(smRaw);
  }
  // 2) Named template reference
  if (resolvedStateMachine == null) {
    final templateName = map['template'];
    if (templateName is String) {
      resolvedStateMachine = marketplaceTemplateMap[templateName];
    }
  }
  // 3) Runtime state override, defaulting to machine's initialState
  final stateOverride =
      map['state'] as String? ?? resolvedStateMachine?.initialState;

  return LoomMarketplaceListing(
    listingId: listingId,
    title: title,
    category: map['category'] as String?,
    iconKey: map['iconKey'] as String?,
    condition: map['condition'] as String?,
    availability: map['availability'] as String? ?? 'available',
    currentHolderLabel: map['currentHolderLabel'] as String?,
    queueLength: (map['queueLength'] as num?)?.toInt() ?? 0,
    dueLabel: map['dueLabel'] as String?,
    description: map['description'] as String?,
    linkedWorkflowId: map['linkedWorkflowId'] as String?,
    stateMachine: resolvedStateMachine,
    template: map['template'] as String?,
    state: stateOverride,
    queuedPersonaIds: _shellStringList(map['queuedPersonaIds']),
  );
}

LoomListingStateMachine? _parseListingStateMachine(Map<String, Object?> map) {
  final initialState = map['initialState'];
  if (initialState is! String) return null;
  final statesRaw = map['states'];
  final transitionsRaw = map['transitions'];
  if (statesRaw is! Map<String, Object?> || transitionsRaw is! List)
    return null;
  final states = <String, LoomListingState>{};
  for (final entry in statesRaw.entries) {
    final value = entry.value;
    if (value is Map<String, Object?>) {
      final label = value['label'];
      if (label is String) {
        states[entry.key] = LoomListingState(
          label: label,
          tone: value['tone'] as String?,
          showsHolder: value['showsHolder'] == true,
          showsDue: value['showsDue'] == true,
          showsQueue: value['showsQueue'] == true,
        );
      }
    }
  }
  if (!states.containsKey(initialState)) return null;
  final transitions = <LoomListingTransition>[
    for (final entry in transitionsRaw)
      if (entry is Map<String, Object?>) _parseTransition(entry),
  ];
  return LoomListingStateMachine(
    initialState: initialState,
    states: states,
    transitions: transitions,
  );
}

LoomListingTransition _parseTransition(Map<String, Object?> map) {
  return LoomListingTransition(
    id: map['id'] as String? ?? '',
    label: map['label'] as String? ?? '',
    fromStates: _shellStringList(map['from']),
    to: map['to'] as String?,
    allowedPersonaIds: _shellStringList(map['allowedPersonaIds']),
    requiresWorkflowsComplete: _shellStringList(
      map['requiresWorkflowsComplete'],
    ),
    linkedWorkflowId: map['linkedWorkflowId'] as String?,
    setsHolderToActor: map['setsHolderToActor'] == true,
    clearsHolder: map['clearsHolder'] == true,
    incrementsQueue: map['incrementsQueue'] == true,
    decrementsQueue: map['decrementsQueue'] == true,
    removesFromList: map['removesFromList'] == true,
    addsActorToQueue: map['addsActorToQueue'] == true,
    removesActorFromQueue: map['removesActorFromQueue'] == true,
    requiresActorInQueue: map['requiresActorInQueue'] == true,
    requiresActorNotInQueue: map['requiresActorNotInQueue'] == true,
  );
}

LoomPersonaDefinition? _parsePersonaDefinition(Map<String, Object?> map) {
  final personaId = map['personaId'];
  final label = map['label'];
  if (personaId is! String || personaId.isEmpty || label is! String) {
    return null;
  }
  final roleLabel = map['roleLabel'];
  final description = map['description'];
  return LoomPersonaDefinition(
    personaId: personaId,
    label: label,
    roleLabel: roleLabel is String ? roleLabel : label,
    description: description is String ? description : '',
  );
}

LoomWorkflowPersonaPolicy _parsePersonaPolicyDefinition(
  Map<String, Object?> map,
) {
  return LoomWorkflowPersonaPolicy(
    actorPersonaIds: _shellStringList(map['actorPersonaIds']),
    receiverPersonaIds: _shellStringList(map['receiverPersonaIds']),
    readOnlyPersonaIds: _shellStringList(map['readOnlyPersonaIds']),
    prerequisiteWorkflowId: map['prerequisiteWorkflowId'] as String?,
    receiverEntryText: map['receiverEntryText'] as String?,
    receiverActionText: map['receiverActionText'] as String?,
    receiverResultText: map['receiverResultText'] as String?,
    readOnlyText: map['readOnlyText'] as String?,
    disabledReason:
        map['disabledReason'] as String? ?? 'Not available for this persona',
  );
}

String _shellStringOr(Object? value, String fallback) {
  return value is String && value.isNotEmpty ? value : fallback;
}

List<String> _shellStringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final entry in value)
      if (entry is String) entry,
  ];
}

int? _parseShellHexColor(Object? value) {
  if (value is! String) {
    return null;
  }
  final hex = value.trim().replaceFirst('#', '');
  if (hex.length != 6 && hex.length != 8) {
    return null;
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) {
    return null;
  }
  return hex.length == 6 ? (0xff000000 | parsed) : parsed;
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

LocalBackendSnapshot preloadedExampleCommunitiesSnapshot() {
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

Map<String, List<String>> preloadedSeedFilesByCommunityId() {
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
      personaId: 'guardian',
      label: 'Guardian',
      roleLabel: 'Guardian',
      description: 'Handles player registration, payments, and reminders.',
    ),
    LoomPersonaDefinition(
      personaId: 'coach',
      label: 'Coach',
      roleLabel: 'Team staff',
      description:
          'Approves guardians, manages rosters, and publishes team operations.',
    ),
    LoomPersonaDefinition(
      personaId: 'owner',
      label: 'Owner',
      roleLabel: 'Owner',
      description: 'Runs protected exports with minor-data redaction.',
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
    case 'garden-tool-loan':
    case 'garden-volunteer-shift':
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
        actorPersonaIds: ['guardian'],
        receiverPersonaIds: ['coach', 'owner'],
        receiverEntryText: 'Guardian approval is ready to receive.',
        receiverActionText: 'Receive approval',
        receiverResultText: 'Guardian received active membership approval.',
      );
    case 'soccer-team-roster':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['coach', 'guardian'],
      );
    case 'soccer-minor-redaction':
    case 'soccer-registration-payment':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['guardian'],
        readOnlyPersonaIds: ['coach'],
        readOnlyText: 'Coach sees only permission-safe evidence.',
      );
    case 'soccer-practice-schedule':
    case 'soccer-reminder-notification':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['guardian'],
        receiverPersonaIds: ['coach', 'owner'],
        receiverEntryText: 'Team update is ready for guardian receipt.',
        receiverActionText: 'Receive update',
        receiverResultText: 'Guardian received the team update.',
      );
    case 'soccer-export-metadata':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['owner'],
        readOnlyPersonaIds: ['guardian', 'coach'],
        readOnlyText: 'Guardian can open protected export coverage.',
      );
  }
  return const LoomWorkflowPersonaPolicy(actorPersonaIds: ['coach']);
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
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-admin', 'mosque-member'],
      );
    case 'mosque-volunteer-signup':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-admin', 'mosque-member'],
      );
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
    case 'mosque-discussion-thread':
      return const LoomWorkflowPersonaPolicy(
        actorPersonaIds: ['mosque-admin', 'mosque-member'],
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
