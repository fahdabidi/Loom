/// Enforces that `docs/references/**` stays in step with the specification.
///
/// `_meta/docs-sync-checker.md` specified this tool and opened with "Status:
/// specified, NOT built … Until it exists, sync is maintained by hand and *will*
/// drift". Nothing implemented it, and the prediction came true three times: the
/// `CommunityVoteApi` docs that outlived the API, grammar 2 shipping into every
/// fixture's content while all thirteen kept declaring 1 for four months, and an
/// identity rename that renamed keys across three versioned layers while bumping
/// only one.
///
/// The version numbers were never the real problem — the absence of a gate was.
/// A policy nothing executes is a suggestion.
library;

import 'dart:convert';
import 'dart:io';

/// One thing wrong. `path` is repo-relative so failures are clickable.
class DocsSyncFinding {
  const DocsSyncFinding(this.type, this.path, this.message);

  final String type;
  final String path;
  final String message;

  @override
  String toString() => '[$type] $path: $message';
}

class DocsSyncReport {
  const DocsSyncReport(this.findings, this.docsChecked);

  final List<DocsSyncFinding> findings;
  final int docsChecked;

  bool get isClean => findings.isEmpty;
}

/// Checks the reference tree against `spec-version.json` and `doc-manifest.json`.
class DocsSyncChecker {
  const DocsSyncChecker(this.repoRoot);

  /// Repo root — the directory containing `docs/`.
  final Directory repoRoot;

  static final _frontmatterSpec = RegExp(r'^spec:\s*(.+)$', multiLine: true);

  DocsSyncReport check() {
    final findings = <DocsSyncFinding>[];
    final refs = Directory('${repoRoot.path}/docs/references');
    if (!refs.existsSync()) {
      return DocsSyncReport([
        DocsSyncFinding('missing_tree', 'docs/references', 'Directory not found.'),
      ], 0);
    }

    final specVersion =
        jsonDecode(File('${refs.path}/spec-version.json').readAsStringSync())
            as Map<String, Object?>;
    final current = specVersion['current'];
    if (current is! int) {
      findings.add(const DocsSyncFinding(
        'bad_spec_version',
        'docs/references/spec-version.json',
        '`current` must be a single integer. The three-number scheme was '
            'collapsed into one `specVersion`; a map here means the collapse '
            'was reverted or half-applied.',
      ));
      return DocsSyncReport(findings, 0);
    }

    final manifest =
        jsonDecode(File('${refs.path}/_meta/doc-manifest.json').readAsStringSync())
            as Map<String, Object?>;
    final entries = (manifest['docs'] as List).cast<Map<String, Object?>>();

    final manifestPaths = <String>{};
    for (final entry in entries) {
      final path = entry['path'] as String;
      manifestPaths.add(path);
      final status = entry['status'] as String?;

      // `planned` docs do not exist yet by definition; the manifest says so and
      // the checker must not fail on them.
      if (status == 'planned') continue;

      // Product-requirement docs (communities/*-product-experience.md) are
      // inputs the authoring Skill works *from*, not descriptions of the
      // specification. Versioning them would be meaningless and would add a
      // dozen more stamps to bump on every spec change -- the exact overhead
      // that generates drift. They are still tracked for existence.
      final versioned = entry['syncedTo'] != null;

      final file = File('${refs.path}/$path');
      if (!file.existsSync()) {
        findings.add(DocsSyncFinding(
          'manifest_orphan',
          'docs/references/$path',
          'Listed in the manifest with status "$status" but the file does not '
              'exist. Either it was deleted without updating the manifest, or '
              'it should be marked "planned".',
        ));
        continue;
      }

      final syncedTo = entry['syncedTo'];
      if (versioned && syncedTo != current) {
        findings.add(DocsSyncFinding(
          'manifest_stale',
          'docs/references/$path',
          'Manifest says syncedTo $syncedTo but the specification is at '
              '$current. Re-verify the doc against the spec, then update '
              'syncedTo.',
        ));
      }

      // `derivedFrom` names the source of truth. If it has moved, the doc is
      // describing code that may no longer exist — which is exactly how the
      // CommunityVoteApi docs outlived the API they documented.
      for (final source in (entry['derivedFrom'] as List? ?? const [])) {
        if (source is! String || source.isEmpty) continue;
        if (!File('${repoRoot.path}/$source').existsSync()) {
          findings.add(DocsSyncFinding(
            'derived_from_missing',
            'docs/references/$path',
            'derivedFrom names "$source", which no longer exists. This doc is '
                'describing code that has moved or been deleted.',
          ));
        }
      }
    }

    // Which manifest entries are versioned, so the frontmatter check below can
    // skip product-requirement docs without letting them go untracked.
    final unversioned = <String>{
      for (final entry in entries)
        if (entry['syncedTo'] == null) entry['path'] as String,
    };

    // Every markdown file must be in the manifest, and must declare the current
    // version. Without the first check a new doc is invisible to this gate.
    var docsChecked = 0;
    for (final file in refs
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))) {
      final relative =
          file.path.substring(refs.path.length + 1).replaceAll(r'\', '/');
      docsChecked++;

      if (!manifestPaths.contains(relative)) {
        findings.add(DocsSyncFinding(
          'unmanifested_doc',
          'docs/references/$relative',
          'Exists but is absent from doc-manifest.json, so nothing tracks '
              'whether it is current. Add it to the manifest.',
        ));
      }

      if (unversioned.contains(relative)) continue;

      final match = _frontmatterSpec.firstMatch(file.readAsStringSync());
      if (match == null) {
        findings.add(DocsSyncFinding(
          'missing_frontmatter_spec',
          'docs/references/$relative',
          'No `spec:` line in the YAML frontmatter, so its version is unknown.',
        ));
        continue;
      }
      final declared = match.group(1)!.trim();
      if (declared != '$current') {
        findings.add(DocsSyncFinding(
          'doc_version_drift',
          'docs/references/$relative',
          'Declares `spec: $declared` but the specification is at $current.'
              '${declared.startsWith('{') ? ' This is the legacy three-number form and must be collapsed to a single integer.' : ''}',
        ));
      }
    }

    findings.addAll(_checkFixtures(refs, current, specVersion));
    findings.addAll(_checkArchetypeDocs(refs));
    return DocsSyncReport(findings, docsChecked);
  }

  /// Every archetype in the generated contract artifact must have a doc.
  ///
  /// The gate previously checked that docs were *current*, not that they
  /// *existed* — so eight archetypes, including the most-used one in the
  /// corpus, had contracts and no documentation, and nothing noticed until
  /// someone asked. An archetype an author cannot read about is one they will
  /// guess at.
  List<DocsSyncFinding> _checkArchetypeDocs(Directory refs) {
    final artifact =
        File('${refs.path}/generated/permissions-vocabulary.json');
    final dir = Directory('${refs.path}/archetypes');
    if (!artifact.existsSync() || !dir.existsSync()) return const [];

    final contracts = (jsonDecode(artifact.readAsStringSync())
            as Map<String, Object?>)['archetypeContracts'] as Map<String, Object?>?;
    if (contracts == null) return const [];

    final docNames = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .map((f) => f.uri.pathSegments.last)
        .toSet();

    final findings = <DocsSyncFinding>[];
    for (final family in contracts.keys.where((k) => !k.startsWith('_'))) {
      // documentLibrary -> document-library.md, event-rsvp -> event-rsvp.md
      final kebab = family
          .replaceAllMapped(
            RegExp('(?<=[a-z])(?=[A-Z])'),
            (_) => '-',
          )
          .toLowerCase();
      if (!docNames.contains('$kebab.md')) {
        findings.add(DocsSyncFinding(
          'archetype_doc_missing',
          'docs/references/archetypes/$kebab.md',
          'The generated contract declares archetype "$family" but no doc '
              'describes it. An author cannot read what it guarantees, so they '
              'will guess.',
        ));
      }
    }
    return findings;
  }

  /// Community packages must declare the current `specVersion` — unless
  /// `spec-version.json` lists the surface under `pendingMigration`, which makes
  /// the remaining debt explicit and forces it to be removed rather than
  /// forgotten.
  List<DocsSyncFinding> _checkFixtures(
    Directory refs,
    int current,
    Map<String, Object?> specVersion,
  ) {
    final pending = specVersion['pendingMigration'] as Map<String, Object?>?;
    if (pending != null && pending.containsKey('communityFixtures')) {
      return const [];
    }

    final findings = <DocsSyncFinding>[];
    final dir = Directory('${refs.path}/communities');
    if (!dir.existsSync()) return findings;

    for (final file in dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jsonc'))) {
      final name = file.uri.pathSegments.last;
      final text = file.readAsStringSync();
      final match =
          RegExp(r'"specVersion"\s*:\s*(\d+)').firstMatch(text);
      if (match == null) {
        findings.add(DocsSyncFinding(
          'fixture_missing_spec_version',
          'docs/references/communities/$name',
          'No `specVersion` at package root. The legacy schemaVersion / '
              'experienceSchemaVersion / workflowGrammarVersion triple is '
              'replaced by one field.',
        ));
      } else if (match.group(1) != '$current') {
        findings.add(DocsSyncFinding(
          'fixture_version_drift',
          'docs/references/communities/$name',
          'Declares specVersion ${match.group(1)} but the specification is at '
              '$current.',
        ));
      }
    }
    return findings;
  }
}
