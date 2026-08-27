/// Keeps `ArchetypeResolver` and `docs/references/reference/permissions.md`
/// from drifting apart.
///
/// The resolver is the source of truth for machines; permissions.md is the
/// source of truth for humans and authoring agents. Nothing but this test stops
/// one from being edited without the other — and that exact failure has already
/// bitten this repo twice: three copies of the Skill instructions drifting, and
/// a Milestone 2 dispatch silently re-breaking work because it read stale
/// guidance.
///
/// So this test parses the document and asserts, in both directions, that every
/// family and every action matches. Editing the doc without the code fails
/// here, and so does the reverse.
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/src/archetypes/archetype_resolver.dart';
import 'package:test/test.dart';

File _permissionsDoc() {
  // test/ -> loom_ux_judges -> tooling -> packages -> app -> repo root
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/docs/references/reference/permissions.md',
    );
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not locate docs/references/reference/permissions.md by walking up '
    'from ${Directory.current.path}. This test must run inside the repo.',
  );
}

/// Extracts `### \`family\`` sections and the `| \`action\` |` rows beneath
/// them, which is exactly how §4 is written.
Map<String, Set<String>> _parseVocabularies(String markdown) {
  final vocabularies = <String, Set<String>>{};
  final familyHeading = RegExp(r'^### `([^`]+)`');
  final actionCell = RegExp(r'^\|\s*`([a-z_]+)`\s*\|');
  String? family;

  for (final line in const LineSplitter().convert(markdown)) {
    final heading = familyHeading.firstMatch(line);
    if (heading != null) {
      family = heading.group(1);
      continue;
    }
    // A non-table, non-heading line ends the current family's table region
    // only when we hit the next heading; §4 interleaves prose between tables,
    // so we keep the family until another `###` arrives.
    if (family == null) continue;
    final match = actionCell.firstMatch(line);
    if (match != null) {
      (vocabularies[family] ??= <String>{}).add(match.group(1)!);
    }
  }
  return vocabularies;
}

void main() {
  final markdown = _permissionsDoc().readAsStringSync();
  final documented = _parseVocabularies(markdown);

  group('permissions.md and ArchetypeResolver agree', () {
    test('the document actually parsed', () {
      // Guards against the parser silently matching nothing and the whole
      // suite passing vacuously.
      expect(
        documented,
        isNotEmpty,
        reason:
            'Parsed no vocabularies out of permissions.md — the §4 table '
            'format has probably changed, and this test is no longer '
            'checking anything.',
      );
    });

    test('the same bespoke families appear in both', () {
      expect(
        documented.keys.toSet(),
        equals(ArchetypeResolver.bespokeVocabularies.keys.toSet()),
        reason:
            'permissions.md §4 documents a different set of bespoke '
            'families than ArchetypeResolver implements. If a family was '
            'promoted or demoted, both must change together — and check '
            'whether it has a dispatcher case before calling it bespoke.',
      );
    });

    for (final family in ArchetypeResolver.bespokeVocabularies.keys) {
      test('$family has the same closed vocabulary in both', () {
        expect(
          documented[family],
          equals(ArchetypeResolver.bespokeVocabularies[family]),
          reason:
              'The action vocabulary for "$family" differs between '
              'permissions.md §4 and ArchetypeResolver. Adding an action to '
              'one without the other makes the doc lie to authoring agents, '
              'or makes the validator reject values the doc invites.',
        );
      });
    }

    test('every family has a permission-id prefix', () {
      final families = {
        ...ArchetypeResolver.bespokeFamilies,
        ...ArchetypeResolver.genericFamilies,
      };
      expect(
        families.difference(ArchetypeResolver.permissionPrefixes.keys.toSet()),
        isEmpty,
        reason:
            'A family with no prefix derives no permission id at all, so '
            'its transitions would silently grant nothing.',
      );
    });

    test('bespoke and generic families are disjoint, and table is generic', () {
      expect(
        ArchetypeResolver.bespokeFamilies.intersection(
          ArchetypeResolver.genericFamilies,
        ),
        isEmpty,
      );
      expect(
        ArchetypeResolver.genericFamilies,
        contains('table'),
        reason:
            '`table` renders as a grid but has no dispatcher case — that '
            'is list layout, not a semantic contract. It derives '
            'structurally and takes no action field.',
      );
    });

    test('withdraw_vote is gone from votePoll', () {
      // Removed deliberately: cancel-vote calls the poll off for everyone
      // rather than withdrawing one ballot, so it shares `close`. Pinned
      // because it was added once on a premise the fixtures disprove.
      expect(
        ArchetypeResolver.bespokeVocabularies['votePoll'],
        isNot(contains('withdraw_vote')),
      );
      expect(documented['votePoll'], isNot(contains('withdraw_vote')));
    });
  });
}
