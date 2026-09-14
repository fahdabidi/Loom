import 'package:loom_communities_demo/main.dart';

import 'b25_workflow_row_selection.dart';

/// The complete, closed set of prose role forms in the B25 interaction-model
/// asset as of 2026-09-14. These are product-doc narrative qualifiers, not
/// role identifiers. No other prose is stripped or otherwise guessed at.
const b25DocumentedNarrativeQualifierPhrases = <String>{
  'community member acting as donor',
  'community member recipient',
  'community member acting as payer',
};

const _b25NarrativeQualifierBaseRoles = <String, String>{
  'community member acting as donor': 'community member',
  'community member recipient': 'community member',
  'community member acting as payer': 'community member',
};

/// The exact actor identities independently selected for one product-doc role.
///
/// A two-entry result is only possible for a literal, two-sided slash pair.
/// It never means a single role term was allowed to resolve ambiguously.
class B25ProductDocRoleResolution {
  const B25ProductDocRoleResolution({
    required this.role,
    required this.roleIds,
  });

  final String role;
  final List<String> roleIds;

  bool get requiresTwoActorWalkthrough => roleIds.length == 2;
}

/// The existing package/role diagnostic in a typed form so a known resolver
/// mismatch stays row-local instead of becoming an unexplained execution
/// failure.
class B25ProductDocRoleResolutionFailure extends B25SelectorSetupFailure {
  B25ProductDocRoleResolutionFailure({
    required String extensionId,
    required String role,
    required List<LoomActorIdentity> availableIdentities,
    String? detail,
    String cause = B25SelectorSetupFailure.unresolvableRoleCause,
  }) : super(
         'Shipped package $extensionId has no actor identity that can '
         'represent B25 product-doc role `$role`. Available identities: '
         '${availableIdentities.map((identity) => '${identity.roleId} (${identity.label})').join(', ')}.'
         '${detail == null ? '' : ' $detail'}',
         cause: cause,
       );

  /// A tier matched more than one shipped identity. That is a different
  /// defect from a role nothing can represent, and the summary must say so.
  static const ambiguousRoleCause =
      'a resolution tier matched more than one shipped actor identity';
}

/// A row-local, named refusal for a two-actor product-doc row when the
/// current walkthrough can only drive one actor identity.
class B25CompoundRoleWalkthroughFailure extends B25SelectorSetupFailure {
  B25CompoundRoleWalkthroughFailure({
    required String extensionId,
    required String role,
    required List<String> roleIds,
  }) : super(
         'B25 product-doc role `$role` in shipped package $extensionId '
         'resolves the required two actor identities ${roleIds.join(', ')}. '
         'The '
         'current walkthrough supports one actor identity per row, so this '
         'row is recorded as blocked_by_two_actor_walkthrough instead of '
         'silently selecting the first actor identity.',
         cause: outcomeCause,
       );

  static const outcomeCause = 'blocked_by_two_actor_walkthrough';
}

/// Resolves a B25 product-doc role conservatively.
///
/// Every single role term is matched in this ordered list of exact tiers, and
/// stops at the first tier that yields exactly one identity:
///
///  1. exact role id
///  2. exact case-insensitive identity label
///  3. exact case-insensitive identity role label
///  4. role-id suffix: the identity's role id equals or ends with `-<term>`
///  5. the closed qualifier phrase list above
///
/// Only declared, deterministic fields are consulted: a role id, a label, a
/// role label, or a documented qualifier phrase. At no stage can a term choose
/// from multiple identities or fall back to a closest/default actor identity:
/// a tier matching more than one identity fails loudly without falling through
/// to a later tier, and a run with no match fails loudly too.
///
/// A slash pair is the one explicit two-actor form: both terms are
/// resolved independently by these same tiers.
B25ProductDocRoleResolution resolveB25ProductDocRole({
  required String extensionId,
  required String role,
  required Iterable<LoomActorIdentity> actorIdentities,
}) {
  final identities = List<LoomActorIdentity>.unmodifiable(actorIdentities);
  final roleParts = _b25RoleParts(role);
  return B25ProductDocRoleResolution(
    role: role,
    roleIds: List<String>.unmodifiable([
      for (final rolePart in roleParts)
        _resolveB25RolePart(
          extensionId: extensionId,
          fullRole: role,
          rolePart: rolePart,
          identities: identities,
        ),
    ]),
  );
}

/// Requires a selector shape that the present B25 walkthrough can execute.
///
/// This is intentionally separate from role resolution: the pair is valid and
/// fully resolved, but one-actor walkthrough code is not evidence for it.
String requireSingleActorIdentityB25Walkthrough({
  required String extensionId,
  required B25ProductDocRoleResolution resolution,
}) {
  if (resolution.requiresTwoActorWalkthrough) {
    throw B25CompoundRoleWalkthroughFailure(
      extensionId: extensionId,
      role: resolution.role,
      roleIds: resolution.roleIds,
    );
  }
  return resolution.roleIds.single;
}

List<String> _b25RoleParts(String role) {
  final trimmedRole = role.trim();
  final slashCount = '/'.allMatches(trimmedRole).length;
  if (slashCount != 1) return <String>[trimmedRole];

  final parts = trimmedRole.split('/').map((part) => part.trim()).toList();
  if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
    return <String>[trimmedRole];
  }
  return parts;
}

String _resolveB25RolePart({
  required String extensionId,
  required String fullRole,
  required String rolePart,
  required List<LoomActorIdentity> identities,
}) {
  final exactRoleIds = identities
      .where((identity) => identity.roleId == rolePart)
      .toList(growable: false);
  if (exactRoleIds.isNotEmpty) {
    return _requireSingleB25RoleMatch(
      extensionId: extensionId,
      fullRole: fullRole,
      rolePart: rolePart,
      stage: 'exact roleId',
      matches: exactRoleIds,
      identities: identities,
    ).roleId;
  }

  final exactLabels = identities
      .where(
        (identity) => identity.label.toLowerCase() == rolePart.toLowerCase(),
      )
      .toList(growable: false);
  if (exactLabels.isNotEmpty) {
    return _requireSingleB25RoleMatch(
      extensionId: extensionId,
      fullRole: fullRole,
      rolePart: rolePart,
      stage: 'case-insensitive label',
      matches: exactLabels,
      identities: identities,
    ).roleId;
  }

  final exactRoleLabels = identities
      .where(
        (identity) =>
            identity.roleLabel.toLowerCase() == rolePart.toLowerCase(),
      )
      .toList(growable: false);
  if (exactRoleLabels.isNotEmpty) {
    return _requireSingleB25RoleMatch(
      extensionId: extensionId,
      fullRole: fullRole,
      rolePart: rolePart,
      stage: 'case-insensitive roleLabel',
      matches: exactRoleLabels,
      identities: identities,
    ).roleId;
  }

  final roleIdSuffixMatches = identities
      .where(
        (identity) => _b25RoleIdMatchesSuffix(
          roleId: identity.roleId,
          rolePart: rolePart,
        ),
      )
      .toList(growable: false);
  if (roleIdSuffixMatches.isNotEmpty) {
    return _requireSingleB25RoleMatch(
      extensionId: extensionId,
      fullRole: fullRole,
      rolePart: rolePart,
      stage: 'case-insensitive roleId suffix `-${rolePart.trim()}`',
      matches: roleIdSuffixMatches,
      identities: identities,
    ).roleId;
  }

  final normalizedRolePart =
      _b25NarrativeQualifierBaseRoles[rolePart.toLowerCase()];
  if (normalizedRolePart != null) {
    return _resolveNormalizedB25RolePart(
      extensionId: extensionId,
      fullRole: fullRole,
      originalRolePart: rolePart,
      normalizedRolePart: normalizedRolePart,
      identities: identities,
    ).roleId;
  }

  throw B25ProductDocRoleResolutionFailure(
    extensionId: extensionId,
    role: fullRole,
    availableIdentities: identities,
  );
}

/// Whether [roleId] is the bare [rolePart] or ends with `-<rolePart>`.
///
/// This is an exact suffix test against the whole hyphen-delimited final
/// segment of the declared role id. It deliberately never matches a role id
/// that merely contains the term, so `owner` cannot resolve an id such as
/// `hoa-board` and `member` cannot resolve `moderator`.
bool _b25RoleIdMatchesSuffix({
  required String roleId,
  required String rolePart,
}) {
  final normalizedRoleId = roleId.toLowerCase();
  final normalizedRolePart = rolePart.trim().toLowerCase();
  if (normalizedRolePart.isEmpty) return false;
  return normalizedRoleId == normalizedRolePart ||
      normalizedRoleId.endsWith('-${normalizedRolePart}');
}

LoomActorIdentity _resolveNormalizedB25RolePart({
  required String extensionId,
  required String fullRole,
  required String originalRolePart,
  required String normalizedRolePart,
  required List<LoomActorIdentity> identities,
}) {
  final exactRoleIds = identities
      .where((identity) => identity.roleId == normalizedRolePart)
      .toList(growable: false);
  if (exactRoleIds.isNotEmpty) {
    return _requireSingleB25RoleMatch(
      extensionId: extensionId,
      fullRole: fullRole,
      rolePart: originalRolePart,
      stage:
          'documented qualifier normalized to exact roleId '
          '`$normalizedRolePart`',
      matches: exactRoleIds,
      identities: identities,
    );
  }

  final exactLabels = identities
      .where(
        (identity) =>
            identity.label.toLowerCase() == normalizedRolePart.toLowerCase(),
      )
      .toList(growable: false);
  if (exactLabels.isNotEmpty) {
    return _requireSingleB25RoleMatch(
      extensionId: extensionId,
      fullRole: fullRole,
      rolePart: originalRolePart,
      stage:
          'documented qualifier normalized to case-insensitive label '
          '`$normalizedRolePart`',
      matches: exactLabels,
      identities: identities,
    );
  }

  throw B25ProductDocRoleResolutionFailure(
    extensionId: extensionId,
    role: fullRole,
    availableIdentities: identities,
  );
}

LoomActorIdentity _requireSingleB25RoleMatch({
  required String extensionId,
  required String fullRole,
  required String rolePart,
  required String stage,
  required List<LoomActorIdentity> matches,
  required List<LoomActorIdentity> identities,
}) {
  if (matches.length == 1) return matches.single;
  throw B25ProductDocRoleResolutionFailure(
    extensionId: extensionId,
    role: fullRole,
    availableIdentities: identities,
    cause: B25ProductDocRoleResolutionFailure.ambiguousRoleCause,
    detail:
        'Resolution is ambiguous: role term `$rolePart` matched '
        '${matches.map((identity) => identity.roleId).join(', ')} at $stage.',
  );
}
