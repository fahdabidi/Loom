/// Keeps the generated permissions vocabulary in step with `ArchetypeResolver`.
///
/// The artifact is what the App Access installer reads, so a stale copy means
/// the service derives permissions from one vocabulary while the validator
/// checks packages against another — the service would then grant permissions
/// for a package the validator had already passed, or refuse one it had.
///
/// Regenerate with:
///   dart run bin/generate_permissions_vocabulary.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/permissions/archetype_resolver.dart';
import 'package:test/test.dart';

import '../bin/generate_permissions_vocabulary.dart' as generator;

File _artifact() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/${generator.outputPath}');
    if (candidate.existsSync()) return candidate;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'Could not locate ${generator.outputPath}. Generate it with '
    '`dart run bin/generate_permissions_vocabulary.dart`.',
  );
}

void main() {
  group('generated permissions vocabulary', () {
    late Map<String, Object?> artifact;

    setUpAll(() {
      artifact =
          jsonDecode(_artifact().readAsStringSync()) as Map<String, Object?>;
    });

    test('is byte-identical to what the generator produces now', () {
      const encoder = JsonEncoder.withIndent('  ');
      expect(
        _artifact().readAsStringSync(),
        equals('${encoder.convert(generator.buildVocabulary())}\n'),
        reason: 'The checked-in artifact has drifted from ArchetypeResolver. '
            'Regenerate it with '
            '`dart run bin/generate_permissions_vocabulary.dart`.',
      );
    });

    test('covers every family the resolver knows, and only those', () {
      final bespoke =
          (artifact['bespokeArchetypes'] as Map<String, Object?>).keys.toSet();
      final generic =
          (artifact['genericArchetypes'] as Map<String, Object?>).keys.toSet();

      expect(bespoke, equals(ArchetypeResolver.bespokeFamilies));
      expect(generic, equals(ArchetypeResolver.genericFamilies));
      expect(
        bespoke.intersection(generic),
        isEmpty,
        reason: 'A family in both lists would derive twice, by two rules.',
      );
    });

    test('every permission id is prefix.action, and unique across the catalog', () {
      final all = <String>[];
      for (final section in ['bespokeArchetypes', 'genericArchetypes']) {
        final families = artifact[section] as Map<String, Object?>;
        for (final entry in families.entries) {
          final family = entry.value as Map<String, Object?>;
          final prefix = family['permissionPrefix'] as String;
          final actions = (family['actions'] as List).cast<String>();
          final permissions = (family['permissions'] as List).cast<String>();

          expect(
            permissions,
            equals([for (final a in actions) '$prefix.$a']),
            reason: '${entry.key} permission ids do not match its actions.',
          );
          all.addAll(permissions);
        }
      }
      expect(
        all.length,
        equals(all.toSet().length),
        reason: 'Duplicate permission id across families — two archetypes would '
            'share one grant, so granting for one silently grants the other.',
      );
      expect(all, isNotEmpty);
    });

    test('declares the single spec version it was generated for', () {
      expect(
        artifact['specVersion'],
        equals(4),
        reason: 'One number versions the whole package. The installer refuses '
            'packages whose version it does not implement, so this must track '
            'the real one.',
      );
    });

    test('carries a contract for every archetype the resolver knows', () {
      final contracts = Map<String, Object?>.from(
        artifact['archetypeContracts'] as Map<String, Object?>,
      )..removeWhere((key, _) => key.startsWith('_'));

      expect(
        contracts.keys.toSet(),
        equals({
          ...ArchetypeResolver.bespokeFamilies,
          ...ArchetypeResolver.genericFamilies,
        }),
        reason: 'An archetype with no contract has no defined bookkeeping or '
            'visibility model, so the workflow service would have nothing to '
            'enforce for it.',
      );
    });

    test('every contract names a visibility model and an enforcement boundary', () {
      const visibilityModels = {
        'roles',
        'owner',
        'owner_and_shared',
        'participants',
        'parties',
        'recipient',
      };
      final contracts = Map<String, Object?>.from(
        artifact['archetypeContracts'] as Map<String, Object?>,
      )..removeWhere((key, _) => key.startsWith('_'));

      for (final entry in contracts.entries) {
        final contract = entry.value as Map<String, Object?>;
        expect(
          visibilityModels,
          contains(contract['visibility']),
          reason: '${entry.key} declares an unknown visibility model.',
        );
        expect(
          const ['client_engine', 'server'],
          contains(contract['enforcement']),
          reason: '${entry.key} must state where its rules are enforced. '
              'Everything is client_engine today, because no workflow service '
              'exists — that is a fact worth being explicit about rather than '
              'implied.',
        );
        expect(contract['allowsCustomActions'], isTrue);
      }
    });

    test('only equipment-loan claims special placement', () {
      // Six ids in one archetype, matched by name in part36 purely to position
      // them. If another archetype grows placement, the claim in CONTRACTS.md
      // that legality always comes from availableTransitionsAsync needs
      // re-checking.
      final contracts = Map<String, Object?>.from(
        artifact['archetypeContracts'] as Map<String, Object?>,
      )..removeWhere((key, _) => key.startsWith('_'));

      final withPlacement = [
        for (final e in contracts.entries)
          if ((e.value as Map<String, Object?>).containsKey('placement')) e.key,
      ];
      expect(withPlacement, equals(['equipment-loan']));
    });
  });
}
