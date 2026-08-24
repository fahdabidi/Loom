/// Keeps the two Skill delivery channels carrying the same authoring rules.
///
/// The Skill ships through two channels: `codex-dispatch/INSTRUCTIONS.md`, which
/// an agent fetches from GitHub, and `chatgpt-upload/00-INSTRUCTIONS.md`, which
/// is bundled for manual upload. They are NOT byte-identical by design — the
/// fetch order and the packaging differ per channel.
///
/// What must never differ is the authoring contract. Hard rule 14 (converge the
/// product doc and the JSON) lived only on the codex channel from the day it was
/// written until 2026-08-24, so a chatgpt-upload run was authorised to ship a
/// package that had never been compared against its product doc. Nothing failed;
/// the rule was simply absent on one side.
///
/// This test is the thing that would have failed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _skillDirectory = '.agents/skills/loom-calendar-experience-authoring';
const _codexChannel = '$_skillDirectory/codex-dispatch/INSTRUCTIONS.md';
const _chatgptChannel = '$_skillDirectory/chatgpt-upload/00-INSTRUCTIONS.md';

/// Phrases that carry a process guarantee rather than channel mechanics.
///
/// Each one is load-bearing: it is the sentence an agent has to read to get the
/// behaviour right, and a channel missing it is a channel that authorises the
/// wrong thing.
const _loadBearingPhrases = <String>[
  'CONVERGENCE IS NEVER ACHIEVED BY REMOVAL',
  'convergence record',
  'Never author a permission',
  'createdByFanId',
  'responseTable',
];

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${directory.path}/$_skillDirectory').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the repository root from ${Directory.current.path}.',
  );
}

String _read(String relativePath) {
  final file = File('${_repositoryRoot().path}/$relativePath');
  if (!file.existsSync()) {
    throw StateError('Skill channel file is missing: $relativePath');
  }
  return file.readAsStringSync();
}

/// The `## Hard rules` section only — numbered lists appear elsewhere in both
/// documents (deliverables, validation steps) and must not be mistaken for rules.
String _hardRulesSection(String source, String channelName) {
  final lines = const LineSplitter().convert(source);
  final start = lines.indexWhere((line) => line.startsWith('## Hard rules'));
  if (start < 0) {
    throw StateError('No "## Hard rules" section in $channelName.');
  }
  final rest = lines.skip(start + 1).toList();
  final end = rest.indexWhere((line) => line.startsWith('## '));
  final body = end < 0 ? rest : rest.take(end);
  return body.join('\n');
}

final _ruleHeading = RegExp(r'^(\d+[a-z]?)\.\s+(.*)$');

/// Rule id -> single-line title, for rules whose title fits on the heading line.
/// A rule whose bold title wraps still contributes its id, which is what the
/// presence check needs.
({Set<String> ids, Map<String, String> titles}) _rules(
  String source,
  String channelName,
) {
  final ids = <String>{};
  final titles = <String, String>{};
  for (final line in const LineSplitter().convert(
    _hardRulesSection(source, channelName),
  )) {
    final match = _ruleHeading.firstMatch(line);
    if (match == null) continue;
    final id = match.group(1)!;
    ids.add(id);
    final title = match.group(2)!;
    if (title.startsWith('**')) {
      titles[id] = title.replaceAll('**', '').trim();
    }
  }
  return (ids: ids, titles: titles);
}

void main() {
  group('Skill channel parity', () {
    late final String codex;
    late final String chatgpt;
    late final ({Set<String> ids, Map<String, String> titles}) codexRules;
    late final ({Set<String> ids, Map<String, String> titles}) chatgptRules;

    setUpAll(() {
      codex = _read(_codexChannel);
      chatgpt = _read(_chatgptChannel);
      codexRules = _rules(codex, 'codex-dispatch');
      chatgptRules = _rules(chatgpt, 'chatgpt-upload');
    });

    test('both channels declare a non-trivial set of hard rules', () {
      // Guards the extraction itself: a regex that silently stops matching
      // would make every parity assertion below pass vacuously.
      expect(
        codexRules.ids.length,
        greaterThanOrEqualTo(15),
        reason: 'Extracted too few rules from codex-dispatch to trust parity.',
      );
      expect(
        chatgptRules.ids.length,
        greaterThanOrEqualTo(15),
        reason: 'Extracted too few rules from chatgpt-upload to trust parity.',
      );
    });

    test('every hard rule exists on both channels', () {
      final missingFromChatgpt = codexRules.ids.difference(chatgptRules.ids);
      final missingFromCodex = chatgptRules.ids.difference(codexRules.ids);

      expect(
        missingFromChatgpt,
        isEmpty,
        reason:
            'Hard rules present in codex-dispatch but absent from '
            'chatgpt-upload: ${missingFromChatgpt.toList()..sort()}. '
            'Port them across — a rule on one channel only is a rule that '
            'does not apply to half the runs.',
      );
      expect(
        missingFromCodex,
        isEmpty,
        reason:
            'Hard rules present in chatgpt-upload but absent from '
            'codex-dispatch: ${missingFromCodex.toList()..sort()}.',
      );
    });

    test('shared hard rules say the same thing on both channels', () {
      final divergent = <String>[];
      for (final entry in codexRules.titles.entries) {
        final other = chatgptRules.titles[entry.key];
        if (other == null) continue;
        if (other != entry.value) {
          divergent.add(
            'rule ${entry.key}:\n'
            '  codex-dispatch: ${entry.value}\n'
            '  chatgpt-upload: $other',
          );
        }
      }
      expect(
        divergent,
        isEmpty,
        reason:
            'A hard rule was edited on one channel only:\n'
            '${divergent.join('\n')}',
      );
    });

    test('load-bearing process guarantees appear on both channels', () {
      for (final phrase in _loadBearingPhrases) {
        expect(
          codex.contains(phrase),
          isTrue,
          reason: 'codex-dispatch no longer contains: "$phrase"',
        );
        expect(
          chatgpt.contains(phrase),
          isTrue,
          reason:
              'chatgpt-upload does not contain: "$phrase". '
              'This is the exact drift that let rule 14 ship on one channel '
              'only — port the rule, do not delete the assertion.',
        );
      }
    });
  });
}
