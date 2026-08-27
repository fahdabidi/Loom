/// Keeps the ChatGPT upload bundle byte-identical to the `docs/references/**`
/// files it mirrors.
///
/// `PORTING-TO-CHATGPT.md` calls the ChatGPT GPT "the production target", and
/// `SKILL.md` carries a `cp` recipe for refreshing the bundle from source. That
/// recipe is correct and complete. It is also manual, and by 2026-08-24 six
/// mirrored files had drifted from their sources:
///
///   04-validation.md          114 lines behind guide/05-validation.md
///   12-render-bindings.md      54 lines behind
///   21-permissions.md          25 lines behind
///   11-field-types.md           8 lines behind
///   22-archetype-contracts.md, 29-archetype-event-rsvp.md
///
/// A stale mirror is worse than a missing one: the production authoring channel
/// reads it as current and authors against retired grammar. `SKILL.md` already
/// says "do not hand-edit individual copies out of sync with the source" — this
/// makes that sentence enforceable instead of advisory.
///
/// Refresh with the recipe in SKILL.md's "`chatgpt-upload/` — the portable
/// export" section, then re-run.
library;

import 'dart:io';

import 'package:test/test.dart';

const _bundle = '.agents/skills/loom-calendar-experience-authoring/chatgpt-upload';

/// bundle filename -> path under `docs/references`, transcribed from SKILL.md's
/// copy recipe. Kept in the same order as the recipe so the two read together.
const _mirroredFiles = <String, String>{
  '01-authoring-procedure.md': 'guide/01-authoring-procedure.md',
  '02-common-patterns.md': 'guide/03-common-patterns.md',
  '03-antipatterns.md': 'guide/04-antipatterns.md',
  '04-validation.md': 'guide/05-validation.md',
  '05-actions-and-fabs.md': 'guide/07-actions-and-fabs.md',
  '06-card-styling.md': 'guide/08-card-styling.md',
  '07-workflow-grammar.md': 'reference/workflow-grammar.md',
  '08-guards.md': 'reference/guards.md',
  '09-effects.md': 'reference/effects.md',
  '10-formulas.md': 'reference/formulas.md',
  '11-field-types.md': 'reference/field-types.md',
  '12-render-bindings.md': 'reference/render-bindings.md',
  '13-theming.md': 'reference/theming.md',
  '14-platform-services.md': 'reference/platform-services.md',
  '15-archetypes.md': 'archetypes/README.md',
  '16-spec-version.json': 'spec-version.json',
  '20-solved-patterns.md': 'reference/solved-patterns.md',
  '21-permissions.md': 'reference/permissions.md',
  '22-archetype-contracts.md': 'archetypes/CONTRACTS.md',
  '23-identity-types.md': 'reference/identity-types.md',
  '24-archetype-approval-queue-item.md': 'archetypes/approval-queue-item.md',
  '25-archetype-approval-queue.md': 'archetypes/approval-queue.md',
  '26-archetype-discussion-thread.md': 'archetypes/discussion-thread.md',
  '27-archetype-document-library.md': 'archetypes/document-library.md',
  '28-archetype-equipment-loan.md': 'archetypes/equipment-loan.md',
  '29-archetype-event-rsvp.md': 'archetypes/event-rsvp.md',
  '30-archetype-export-wizard.md': 'archetypes/export-wizard.md',
  '31-archetype-form-entry.md': 'archetypes/form-entry.md',
  '32-archetype-notification-inbox.md': 'archetypes/notification-inbox.md',
  '33-archetype-payment-checkout.md': 'archetypes/payment-checkout.md',
  '34-archetype-search-ai-answer.md': 'archetypes/search-ai-answer.md',
  '35-archetype-status-timeline.md': 'archetypes/status-timeline.md',
  '36-archetype-table.md': 'archetypes/table.md',
  '37-archetype-vote-poll.md': 'archetypes/vote-poll.md',
  '38-archetype-calendar.md': 'archetypes/calendar.md',
};

/// Authored directly in the Skill bundle, per SKILL.md — not mirrors, so they
/// have no source to compare against.
const _authoredInBundle = <String>{
  '00-INSTRUCTIONS.md',
  '17-worked-example-calendar.jsonc',
  '18-validator-action-openapi.yaml',
  '19-debugging-validator-responses.md',
};

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${directory.path}/$_bundle').existsSync()) return directory;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the repository root from ${Directory.current.path}.',
  );
}

void main() {
  late final Directory root;

  setUpAll(() => root = _repositoryRoot());

  test('every bundle file is either a declared mirror or declared as authored', () {
    // Catches a file added to the bundle without deciding which it is — the
    // state in which drift goes unnoticed because nothing claims to own it.
    final present = Directory('${root.path}/$_bundle')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    final accounted = {..._mirroredFiles.keys, ..._authoredInBundle};
    final unaccounted = present.difference(accounted);

    expect(
      unaccounted,
      isEmpty,
      reason:
          'Bundle files not covered by the mirror map or the authored list: '
          '${unaccounted.toList()..sort()}. Add each to _mirroredFiles (with '
          'its docs/references source) or to _authoredInBundle.',
    );

    final missing = _mirroredFiles.keys.toSet().difference(present);
    expect(
      missing,
      isEmpty,
      reason: 'Declared mirrors missing from the bundle: ${missing.toList()..sort()}',
    );
  });

  group('bundle mirrors match their docs/references source', () {
    _mirroredFiles.forEach((bundleName, sourcePath) {
      test(bundleName, () {
        final bundled = File('${root.path}/$_bundle/$bundleName');
        final source = File('${root.path}/docs/references/$sourcePath');

        expect(
          source.existsSync(),
          isTrue,
          reason:
              'Mirror source docs/references/$sourcePath does not exist. '
              'Either the source moved (update the map) or the mirror is stale.',
        );

        expect(
          bundled.readAsStringSync(),
          source.readAsStringSync(),
          reason:
              '$bundleName has drifted from docs/references/$sourcePath.\n'
              'The ChatGPT bundle is the production authoring channel; a stale '
              'mirror teaches retired grammar as if it were current.\n'
              'Refresh with the copy recipe in SKILL.md, do not hand-edit the '
              'copy, and do not delete this assertion.',
        );
      });
    });
  });
}
