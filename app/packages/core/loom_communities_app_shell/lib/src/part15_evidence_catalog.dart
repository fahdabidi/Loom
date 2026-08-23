part of '../loom_communities_app_shell.dart';

LoomExperienceDefinition experienceForExtensionId(
  String extensionId, {
  String? displayName,
  int? specVersion,
  Map<String, Object?> experienceConfiguration = const {},
}) {
  final packageExperience = _experienceFromConfiguration(
    extensionId,
    displayName: displayName,
    specVersion: specVersion,
    experienceConfiguration: experienceConfiguration,
  );
  if (packageExperience != null) {
    _installEngineNativeExperience(extensionId, packageExperience);
    return packageExperience;
  }
  final known =
      _experienceByExtensionId[_legacyDemoCatalogExtensionId(extensionId)];
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

// These aliases preserve legacy metadata-fixture unit coverage only. Android
// walkthrough targets use the shipped ids and are always installed from the
// shipped package; these aliases are never a package lookup or fallback.
const _legacyDemoCatalogExtensionIdByShippedId = <String, String>{
  'ext_neighborhood_book_club': 'ext_book_club',
  'ext_cedar_commons_hoa': 'ext_hoa',
  'ext_member_social_space': 'ext_platform_social',
  'ext_ad_free_community': 'ext_ad_off',
  'ext_data_portability_community': 'ext_export_migration',
};

String _legacyDemoCatalogExtensionId(String extensionId) =>
    _legacyDemoCatalogExtensionIdByShippedId[extensionId] ?? extensionId;

/// Parses a package-declared `experience` block (from `loom.initialization.json`
/// or `loom.extension.json`) into a [LoomExperienceDefinition]. Returns null
/// when the block is absent or does not contain at least one valid workflow,
/// so callers fall back to the hardcoded demo catalog.
LoomExperienceDefinition? _experienceFromConfiguration(
  String extensionId, {
  String? displayName,
  int? specVersion,
  required Map<String, Object?> experienceConfiguration,
}) {
  if (experienceConfiguration.isEmpty) {
    return null;
  }
  if (specVersion != currentCommunitySpecVersion) {
    throw FormatException(
      'Unsupported specVersion "$specVersion" for extension "$extensionId". '
      'Packages must declare specVersion: $currentCommunitySpecVersion.',
    );
  }
  return _experienceFromEngineNativeConfiguration(
    extensionId,
    displayName: displayName,
    experienceConfiguration: experienceConfiguration,
  );
}

List<CalendarDateRailEntry>? _parseCalendarDateRailEntries(Object? themeRaw) {
  if (themeRaw is! Map) return null;
  final calendarRaw = themeRaw['calendar'];
  if (calendarRaw is! Map) return null;
  final dateRailRaw = calendarRaw['dateRail'];
  if (dateRailRaw is! Map) return null;
  final entriesRaw = dateRailRaw['entries'];
  if (entriesRaw is! List) return null;

  final entries = <CalendarDateRailEntry>[];
  for (final rawEntry in entriesRaw) {
    if (rawEntry is! Map) continue;
    try {
      final kind = rawEntry['kind'];
      final style = rawEntry['style'];
      final token = rawEntry['token'];
      final formula = rawEntry['formula'];
      final colorSource = rawEntry['colorSource'];
      if (kind is! String || style is! String) continue;
      if (kind != 'dateToken' && kind != 'formula') continue;
      if (style != 'label' && style != 'circleHighlight' && style != 'badge') {
        continue;
      }
      if (kind == 'dateToken' && token is! String) continue;
      if (kind == 'formula' && formula is! String) continue;
      if (token != null && token is! String) continue;
      if (formula != null && formula is! String) continue;
      if (colorSource != null && colorSource is! String) continue;
      if (token != null &&
          !const <String>{
            'weekdayAbbrev',
            'dayOfMonth',
            'monthAbbrev',
            'year',
          }.contains(token)) {
        continue;
      }
      if (colorSource != null &&
          colorSource != 'accent' &&
          colorSource != 'styleField') {
        continue;
      }
      entries.add(
        CalendarDateRailEntry(
          kind: kind,
          token: token as String?,
          formula: formula as String?,
          style: style,
          colorSource: colorSource as String?,
        ),
      );
    } catch (_) {}
  }
  return entries;
}

LoomExperienceDefinition? _experienceFromEngineNativeConfiguration(
  String extensionId, {
  String? displayName,
  required Map<String, Object?> experienceConfiguration,
}) {
  final rawDefinitions = experienceConfiguration['workflowDefinitions'];
  if (rawDefinitions is! Map || rawDefinitions.isEmpty) return null;
  final definitions = <String, LoomWorkflowStateMachine>{};
  for (final entry in rawDefinitions.entries) {
    if (entry.value is! Map) continue;
    try {
      definitions[entry.key.toString()] = LoomWorkflowStateMachine.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
        entry.key.toString(),
      );
    } catch (error) {
      // Grammar validation errors must be visible to package parsing callers;
      // unrelated construction errors stay isolated to the malformed entry.
      if (error is FormatException) rethrow;
    }
  }
  if (definitions.isEmpty) return null;
  final rawInstances = experienceConfiguration['workflowInstances'];
  final instances = <LoomWorkflowSeedInstance>[];
  if (rawInstances is List)
    for (final entry in rawInstances) {
      if (entry is! Map) continue;
      try {
        instances.add(
          LoomWorkflowSeedInstance.fromJson(Map<String, dynamic>.from(entry)),
        );
      } catch (_) {}
    }
  final rolesRaw = experienceConfiguration['roles'];
  final actorIdentities = rolesRaw is List
      ? [
          for (final entry in rolesRaw)
            if (entry is Map<String, Object?>)
              if (_parseActorIdentity(entry) case final p?) p,
        ]
      : <LoomActorIdentity>[];
  final themeRaw = experienceConfiguration['theme'];
  final calendarDateRailEntries = _parseCalendarDateRailEntries(themeRaw);
  final creatableAction = _parseCreatableActionStyle(
    experienceConfiguration['creatableAction'],
  );
  final notificationPresentation = _parseNotificationPresentation(
    experienceConfiguration['notificationPresentation'],
  );
  final tabCreatableActionStyles = _parseTabCreatableActionStyles(
    experienceConfiguration['tabCreatableActionStyles'],
  );
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
    workflows: const [],
    actorIdentities: actorIdentities.isEmpty ? null : actorIdentities,
    themeOverride: _parseCardTheme(themeRaw),
    calendarDateRailEntries: calendarDateRailEntries,
    tabThemeOverrides: _parseTabThemes(
      themeRaw is Map<String, Object?> ? themeRaw['tabThemes'] : null,
    ),
    creatableAction: creatableAction,
    notificationPresentation: notificationPresentation,
    tabCreatableActionStyles: tabCreatableActionStyles,
    workflowDefinitions: definitions,
    workflowInstances: instances.isEmpty ? null : instances,
  );
}

LoomCreatableActionStyle? _parseCreatableActionStyle(Object? raw) {
  if (raw is! Map) return null;
  return LoomCreatableActionStyle.fromJson(Map<String, Object?>.from(raw));
}

LoomNotificationPresentation? _parseNotificationPresentation(Object? raw) {
  if (raw is! Map) return null;
  return LoomNotificationPresentation.fromJson(Map<String, Object?>.from(raw));
}

Map<String, LoomCreatableActionStyle> _parseTabCreatableActionStyles(
  Object? raw,
) {
  if (raw is! Map) return const {};
  final styles = <String, LoomCreatableActionStyle>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    if (value is Map) {
      styles[entry.key.toString()] = LoomCreatableActionStyle.fromJson(
        Map<String, Object?>.from(value),
      );
    }
  }
  return styles;
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

LoomActorIdentity? _parseActorIdentity(Map<String, Object?> map) {
  final roleId = map['roleId'];
  final label = map['label'];
  if (roleId is! String || roleId.isEmpty || label is! String) {
    return null;
  }
  final roleLabel = map['roleLabel'];
  final description = map['description'];
  final accessMode = LoomActorIdentityAccessMode.fromJson(map['accessMode']);
  return LoomActorIdentity(
    fanId: roleId,
    roleId: roleId,
    label: label,
    roleLabel: roleLabel is String ? roleLabel : label,
    description: description is String ? description : '',
    accessMode: accessMode,
  );
}

String _shellStringOr(Object? value, String fallback) {
  return value is String && value.isNotEmpty ? value : fallback;
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
    extensionId: 'ext_neighborhood_book_club',
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
    extensionId: 'ext_cedar_commons_hoa',
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
    extensionId: 'ext_member_social_space',
    accentColor: '#315C8A',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
  ),
  LoomEvidenceTarget(
    phase: 'B16',
    communityId: 'community_ad_off',
    communityName: 'Ad-Free Community',
    handle: 'ad-off-demo',
    extensionId: 'ext_ad_free_community',
    accentColor: '#5B5F97',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
  ),
  LoomEvidenceTarget(
    phase: 'B16',
    communityId: 'community_export_migration',
    communityName: 'Data Portability Community',
    handle: 'portability-demo',
    extensionId: 'ext_data_portability_community',
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

const List<LoomActorIdentity> _fallbackActorIdentities = [
  LoomActorIdentity(
    fanId: 'local-owner',
    roleId: 'local-owner',
    label: 'Local Owner',
    roleLabel: 'Owner',
    description: 'Manages local community setup and member actions.',
  ),
  LoomActorIdentity(
    fanId: 'local-member',
    roleId: 'local-member',
    label: 'Local Member',
    roleLabel: 'Member',
    description: 'Uses local community member tools.',
  ),
];

const Map<String, List<LoomActorIdentity>> _actorIdentitiesByExtensionId = {
  'ext_garden_club': [
    LoomActorIdentity(
      fanId: 'garden-coordinator',
      roleId: 'garden-coordinator',
      label: 'Garden Coordinator',
      roleLabel: 'Coordinator',
      description: 'Coordinates events, exchanges, and garden exports.',
    ),
    LoomActorIdentity(
      fanId: 'garden-member',
      roleId: 'garden-member',
      label: 'Garden Member',
      roleLabel: 'Member',
      description: 'RSVPs to garden events and submits exchange offers.',
    ),
  ],
  'ext_book_club': [
    LoomActorIdentity(
      fanId: 'book-organizer',
      roleId: 'book-organizer',
      label: 'Book Organizer',
      roleLabel: 'Organizer',
      description: 'Publishes selections and manages club records.',
    ),
    LoomActorIdentity(
      fanId: 'book-member',
      roleId: 'book-member',
      label: 'Book Member',
      roleLabel: 'Member',
      description: 'Nominates, votes, attends, and discusses books.',
    ),
  ],
  'ext_youth_soccer': [
    LoomActorIdentity(
      fanId: 'guardian',
      roleId: 'guardian',
      label: 'Guardian',
      roleLabel: 'Guardian',
      description: 'Handles player registration, payments, and reminders.',
    ),
    LoomActorIdentity(
      fanId: 'coach',
      roleId: 'coach',
      label: 'Coach',
      roleLabel: 'Team staff',
      description:
          'Approves guardians, manages rosters, and publishes team operations.',
    ),
    LoomActorIdentity(
      fanId: 'owner',
      roleId: 'owner',
      label: 'Owner',
      roleLabel: 'Owner',
      description: 'Runs protected exports with minor-data redaction.',
    ),
  ],
  'ext_hoa': [
    LoomActorIdentity(
      fanId: 'hoa-board',
      roleId: 'hoa-board',
      label: 'HOA Board',
      roleLabel: 'Board',
      description: 'Manages requests, sends decisions, and exports records.',
    ),
    LoomActorIdentity(
      fanId: 'hoa-homeowner',
      roleId: 'hoa-homeowner',
      label: 'Homeowner',
      roleLabel: 'Member',
      description: 'Pays dues, reserves facilities, and submits requests.',
    ),
  ],
  'ext_mosque': [
    LoomActorIdentity(
      fanId: 'mosque-admin',
      roleId: 'mosque-admin',
      label: 'Masjid Admin',
      roleLabel: 'Admin',
      description: 'Publishes announcements and sends neutral notifications.',
    ),
    LoomActorIdentity(
      fanId: 'mosque-member',
      roleId: 'mosque-member',
      label: 'Community Member',
      roleLabel: 'Member',
      description:
          'Receives announcements, RSVPs, volunteers, gives, and requests care.',
    ),
  ],
  'ext_chess_club': [
    LoomActorIdentity(
      fanId: 'chess-organizer',
      roleId: 'chess-organizer',
      label: 'Chess Organizer',
      roleLabel: 'Organizer',
      description: 'Runs community homes and match records.',
    ),
    LoomActorIdentity(
      fanId: 'chess-player',
      roleId: 'chess-player',
      label: 'Chess Player',
      roleLabel: 'Member',
      description: 'Opens club routes and records match results.',
    ),
  ],
  'ext_camera_club': [
    LoomActorIdentity(
      fanId: 'camera-organizer',
      roleId: 'camera-organizer',
      label: 'Camera Organizer',
      roleLabel: 'Organizer',
      description: 'Coordinates RSVPs, critiques, and gear-loan requests.',
    ),
    LoomActorIdentity(
      fanId: 'camera-member',
      roleId: 'camera-member',
      label: 'Camera Member',
      roleLabel: 'Member',
      description: 'RSVPs, submits critiques, and requests shared gear.',
    ),
  ],
  'ext_platform_social': [
    LoomActorIdentity(
      fanId: 'platform-member',
      roleId: 'platform-member',
      label: 'Platform Member',
      roleLabel: 'Member',
      description: 'Uses allowed messages, connections, and ad preferences.',
    ),
    LoomActorIdentity(
      fanId: 'platform-moderator',
      roleId: 'platform-moderator',
      label: 'Moderator',
      roleLabel: 'Moderator',
      description: 'Manages prevention and sensitive-page behavior.',
    ),
    LoomActorIdentity(
      fanId: 'platform-blocked-member',
      roleId: 'platform-blocked-member',
      label: 'Blocked Member',
      roleLabel: 'Restricted',
      description: 'Sees restricted social actions and account status.',
    ),
  ],
  'ext_ad_off': [
    LoomActorIdentity(
      fanId: 'ad-off-member',
      roleId: 'ad-off-member',
      label: 'Ad-Off Member',
      roleLabel: 'Member',
      description: 'Purchases and verifies member ad-off entitlement.',
    ),
    LoomActorIdentity(
      fanId: 'ad-off-admin',
      roleId: 'ad-off-admin',
      label: 'Community Admin',
      roleLabel: 'Admin',
      description: 'Purchases community ad-off and audits settlement.',
    ),
    LoomActorIdentity(
      fanId: 'ad-off-viewer',
      roleId: 'ad-off-viewer',
      label: 'Ad-Free Viewer',
      roleLabel: 'Viewer',
      description: 'Receives entitlement effects without checkout ownership.',
    ),
  ],
  'ext_export_migration': [
    LoomActorIdentity(
      fanId: 'export-owner',
      roleId: 'export-owner',
      label: 'Data Owner',
      roleLabel: 'Owner',
      description: 'Runs import, export, redaction, and checksum actions.',
    ),
    LoomActorIdentity(
      fanId: 'export-member',
      roleId: 'export-member',
      label: 'Export Member',
      roleLabel: 'Member',
      description: 'Inspects redacted data without accessing protected values.',
    ),
    LoomActorIdentity(
      fanId: 'export-provider',
      roleId: 'export-provider',
      label: 'Receiving Provider',
      roleLabel: 'Provider',
      description: 'Verifies transfer and rollback outcomes.',
    ),
  ],
};

LoomWorkflowRolePolicy _gardenPolicy(String workflowId) {
  switch (workflowId) {
    case 'garden-event-rsvp':
    case 'plant-exchange-submission':
    case 'garden-tool-loan':
    case 'garden-volunteer-shift':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['garden-member'],
        receiverRoleIds: ['garden-coordinator'],
        receiverEntryText: 'A member garden submission is ready for action.',
        receiverActionText: 'Open',
        receiverResultText:
            'Garden coordinator received the member submission.',
      );
    case 'garden-export-custom-schemas':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['garden-coordinator'],
        readOnlyRoleIds: ['garden-member'],
        readOnlyText: 'Members can open that their garden records export.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['garden-coordinator']);
}

LoomWorkflowRolePolicy _bookPolicy(String workflowId) {
  switch (workflowId) {
    case 'book-nomination':
    case 'book-vote':
    case 'book-meeting-rsvp':
    case 'book-discussion-message':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['book-member'],
        receiverRoleIds: ['book-organizer'],
        receiverEntryText:
            'A member book-club contribution is ready for organizer action.',
        receiverActionText: 'Open',
        receiverResultText:
            'Organizer received the member book-club contribution.',
      );
    case 'book-selection-publish':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['book-organizer'],
        receiverRoleIds: ['book-member'],
        receiverEntryText:
            'The published monthly selection is ready to receive.',
        receiverActionText: 'Receive selection',
        receiverResultText: 'Member received the selected-book announcement.',
      );
    case 'book-search-ai-digest':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['book-member', 'book-organizer'],
      );
    case 'book-export-metadata':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['book-organizer'],
        readOnlyRoleIds: ['book-member'],
        readOnlyText: 'Members can open export metadata without creating it.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['book-organizer']);
}

LoomWorkflowRolePolicy _soccerPolicy(String workflowId) {
  switch (workflowId) {
    case 'soccer-guardian-join-approval':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['guardian'],
        receiverRoleIds: ['coach', 'owner'],
        receiverEntryText: 'Guardian approval is ready to receive.',
        receiverActionText: 'Receive approval',
        receiverResultText: 'Guardian received active membership approval.',
      );
    case 'soccer-team-roster':
      return const LoomWorkflowRolePolicy(actorRoleIds: ['coach', 'guardian']);
    case 'soccer-minor-redaction':
    case 'soccer-registration-payment':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['guardian'],
        readOnlyRoleIds: ['coach'],
        readOnlyText: 'Coach sees only permission-safe evidence.',
      );
    case 'soccer-practice-schedule':
    case 'soccer-reminder-notification':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['guardian'],
        receiverRoleIds: ['coach', 'owner'],
        receiverEntryText: 'Team update is ready for guardian receipt.',
        receiverActionText: 'Receive update',
        receiverResultText: 'Guardian received the team update.',
      );
    case 'soccer-export-metadata':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['owner'],
        readOnlyRoleIds: ['guardian', 'coach'],
        readOnlyText: 'Guardian can open protected export coverage.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['coach']);
}

LoomWorkflowRolePolicy _hoaPolicy(String workflowId) {
  switch (workflowId) {
    case 'hoa-dues-payment':
    case 'hoa-member-document':
    case 'hoa-facility-reservation':
    case 'hoa-architectural-request':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['hoa-homeowner'],
        receiverRoleIds: ['hoa-board'],
        receiverEntryText: 'A homeowner action is ready for board action.',
        receiverActionText: 'Open',
        receiverResultText: 'Board received the homeowner request update.',
      );
    case 'hoa-committee-decision':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['hoa-board'],
        receiverRoleIds: ['hoa-homeowner'],
        prerequisiteWorkflowId: 'hoa-architectural-request',
        receiverEntryText: 'The committee decision is ready for the homeowner.',
        receiverActionText: 'Receive decision',
        receiverResultText: 'Homeowner received the architectural decision.',
      );
    case 'hoa-owner-notification':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['hoa-board'],
        receiverRoleIds: ['hoa-homeowner'],
        prerequisiteWorkflowId: 'hoa-committee-decision',
        receiverEntryText: 'The owner notification is ready to receive.',
        receiverActionText: 'Receive notice',
        receiverResultText: 'Homeowner received the owner notification.',
      );
    case 'hoa-export-evidence':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['hoa-board'],
        readOnlyRoleIds: ['hoa-homeowner'],
        readOnlyText: 'Homeowners can open export evidence.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['hoa-board']);
}

LoomWorkflowRolePolicy _mosquePolicy(String workflowId) {
  switch (workflowId) {
    case 'mosque-announcement':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-admin'],
        receiverRoleIds: ['mosque-member'],
        receiverEntryText: 'A public announcement is ready to receive.',
        receiverActionText: 'Receive announcement',
        receiverResultText: 'Member received the public announcement.',
      );
    case 'mosque-event-rsvp':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-admin', 'mosque-member'],
      );
    case 'mosque-volunteer-signup':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-admin', 'mosque-member'],
      );
    case 'mosque-donor-visibility':
    case 'mosque-donation-payment':
    case 'mosque-care-request':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-member'],
        receiverRoleIds: ['mosque-admin'],
        receiverEntryText: 'A member submission is ready for admin action.',
        receiverActionText: 'Open',
        receiverResultText: 'Admin received the member submission.',
      );
    case 'mosque-neutral-notification':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-admin'],
        receiverRoleIds: ['mosque-member'],
        prerequisiteWorkflowId: 'mosque-care-request',
        receiverEntryText: 'A neutral care notification is ready to receive.',
        receiverActionText: 'Receive notice',
        receiverResultText: 'Member received the neutral care notification.',
      );
    case 'mosque-discussion-thread':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-admin', 'mosque-member'],
      );
    case 'mosque-search-ai-citation':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['mosque-admin', 'mosque-member'],
        prerequisiteWorkflowId: 'mosque-announcement',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['mosque-admin']);
}

LoomWorkflowRolePolicy _chessPolicy(String workflowId) {
  switch (workflowId) {
    case 'chess-local-install-open':
    case 'chess-route-home':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['chess-organizer', 'chess-player'],
      );
    case 'chess-match-result':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['chess-player'],
        receiverRoleIds: ['chess-organizer'],
        receiverEntryText: 'A match result is ready for organizer action.',
        receiverActionText: 'Open result',
        receiverResultText: 'Organizer received the chess match result.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['chess-organizer']);
}

LoomWorkflowRolePolicy _cameraPolicy(String workflowId) {
  switch (workflowId) {
    case 'photo-walk-rsvp':
    case 'critique-submission':
    case 'gear-loan-request':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['camera-member'],
        receiverRoleIds: ['camera-organizer'],
        receiverEntryText: 'A member camera-club action is ready for action.',
        receiverActionText: 'Open',
        receiverResultText: 'Camera organizer received the member action.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['camera-organizer']);
}

LoomWorkflowRolePolicy _platformPolicy(String workflowId) {
  switch (workflowId) {
    case 'platform-messages-entry':
    case 'platform-connections-entry':
    case 'platform-message-stream':
    case 'platform-in-stream-ad':
    case 'platform-top-banner-no-fill':
    case 'platform-sensitive-no-fill':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['platform-member', 'platform-moderator'],
        readOnlyRoleIds: ['platform-blocked-member'],
        readOnlyText:
            'Blocked actor identity can open shell state but cannot initiate social actions.',
      );
    case 'platform-connection-invite':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['platform-member'],
        receiverRoleIds: ['platform-moderator'],
        disabledReason:
            'Blocked or moderator roles do not send this member invite.',
        receiverEntryText:
            'A member invite attempt is ready for moderator action.',
        receiverActionText: 'Open invite',
        receiverResultText:
            'Moderator received the connection invite evidence.',
      );
    case 'platform-blocked-target':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['platform-moderator'],
        receiverRoleIds: ['platform-member'],
        disabledReason:
            'Blocked actor identity remains unable to receive invites.',
        receiverEntryText: 'Blocked-target prevention result is ready.',
        receiverActionText: 'Receive prevention',
        receiverResultText:
            'Member received blocked-target prevention evidence.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['platform-moderator']);
}

LoomWorkflowRolePolicy _adOffPolicy(String workflowId) {
  switch (workflowId) {
    case 'ad-off-member-checkout':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['ad-off-member'],
        receiverRoleIds: ['ad-off-viewer'],
        receiverEntryText: 'Member ad-off entitlement is ready to observe.',
        receiverActionText: 'Receive entitlement',
        receiverResultText:
            'Ad-free viewer received member entitlement evidence.',
      );
    case 'ad-off-community-checkout':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['ad-off-admin'],
        receiverRoleIds: ['ad-off-member', 'ad-off-viewer'],
        receiverEntryText: 'Community ad-off entitlement is ready to receive.',
        receiverActionText: 'Receive entitlement',
        receiverResultText:
            'Actor identity received community ad-off entitlement evidence.',
      );
    case 'ad-off-entitlement-status':
    case 'ad-off-receipt-evidence':
    case 'ad-off-ad-suppression':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['ad-off-member', 'ad-off-admin', 'ad-off-viewer'],
      );
    case 'ad-off-settlement-utility':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['ad-off-admin'],
        readOnlyRoleIds: ['ad-off-member', 'ad-off-viewer'],
        readOnlyText:
            'Non-admin roles can open economics without recalculating settlement.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['ad-off-admin']);
}

LoomWorkflowRolePolicy _exportPolicy(String workflowId) {
  switch (workflowId) {
    case 'export-import-preview':
    case 'export-import-replay':
    case 'export-protected-redaction':
    case 'export-schema-listing':
    case 'export-redacted-bundle':
    case 'export-checksum-evidence':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['export-owner'],
        readOnlyRoleIds: ['export-member', 'export-provider'],
        readOnlyText: 'Non-owner roles open redacted portability evidence.',
      );
    case 'export-full-bundle':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['export-owner'],
        receiverRoleIds: ['export-provider'],
        readOnlyRoleIds: ['export-member'],
        receiverEntryText:
            'Export bundle is ready for receiving-provider validation.',
        receiverActionText: 'Receive bundle',
        receiverResultText: 'Receiving provider received the export bundle.',
      );
    case 'export-transfer-verification':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['export-provider'],
        receiverRoleIds: ['export-owner'],
        readOnlyRoleIds: ['export-member'],
        prerequisiteWorkflowId: 'export-full-bundle',
        receiverEntryText: 'Provider verification is ready for the data owner.',
        receiverActionText: 'Receive verification',
        receiverResultText:
            'Data owner received provider transfer verification.',
      );
    case 'export-transfer-rollback':
      return const LoomWorkflowRolePolicy(
        actorRoleIds: ['export-provider'],
        receiverRoleIds: ['export-owner'],
        readOnlyRoleIds: ['export-member'],
        prerequisiteWorkflowId: 'export-checksum-evidence',
        receiverEntryText:
            'Provider rollback result is ready for the data owner.',
        receiverActionText: 'Receive rollback',
        receiverResultText: 'Data owner received provider rollback result.',
      );
  }
  return const LoomWorkflowRolePolicy(actorRoleIds: ['export-owner']);
}
