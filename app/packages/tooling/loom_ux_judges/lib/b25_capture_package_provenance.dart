import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/community_package_provenance.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

/// The package provenance recorded beside a captured community.
///
/// [entry] is deliberately the existing provenance-manifest entry. Its
/// SHA-256 is the stable build identifier used for staleness comparison; the
/// remaining fields make the durable evidence self-describing.
final class CapturedCommunityPackageProvenance {
  const CapturedCommunityPackageProvenance({
    required this.packageName,
    required this.entry,
  });

  factory CapturedCommunityPackageProvenance.fromJson(
    Map<String, dynamic> json,
  ) => CapturedCommunityPackageProvenance(
    packageName: json['packageName'] as String,
    entry: CommunityPackageProvenanceEntry.fromJson(json),
  );

  final String packageName;
  final CommunityPackageProvenanceEntry entry;

  Map<String, Object?> toJson() => <String, Object?>{
    'packageName': packageName,
    ...entry.toJson(),
  };
}

/// A community represented in a B25 capture manifest.
///
/// Older manifests do not have [packageProvenance]. They remain useful as
/// historical walkthrough evidence, but their package build is unknown.
final class B25CapturedCommunity {
  const B25CapturedCommunity({
    required this.communityId,
    required this.communityName,
    required this.slug,
    required this.phases,
    required this.packageProvenance,
  });

  factory B25CapturedCommunity.fromJson(Map<String, dynamic> json) {
    final rawProvenance = json['packageProvenance'];
    CapturedCommunityPackageProvenance? packageProvenance;
    if (rawProvenance is Map) {
      final provenanceJson = Map<String, dynamic>.from(rawProvenance);
      if (_hasCompletePackageProvenance(provenanceJson)) {
        packageProvenance = CapturedCommunityPackageProvenance.fromJson(
          provenanceJson,
        );
      }
    }
    final phases = _stringList(json['phases']);
    final legacyPhase = _nonEmptyString(json['phase']);
    return B25CapturedCommunity(
      communityId: _nonEmptyString(json['communityId']),
      communityName: _nonEmptyString(json['communityName']),
      slug: _nonEmptyString(json['slug']),
      phases: phases.isNotEmpty
          ? phases
          : legacyPhase == null
          ? const <String>[]
          : <String>[legacyPhase],
      packageProvenance: packageProvenance,
    );
  }

  final String? communityId;
  final String? communityName;
  final String? slug;
  final List<String> phases;
  final CapturedCommunityPackageProvenance? packageProvenance;

  /// A human-readable, stable-enough label for reports across both the new
  /// schema and the historical row-only manifest shape.
  String get reportName =>
      communityName ??
      communityId ??
      slug ??
      packageProvenance?.packageName ??
      'unknown';

  Map<String, Object?> toJson() => <String, Object?>{
    if (communityId != null) 'communityId': communityId,
    if (communityName != null) 'communityName': communityName,
    if (slug != null) 'slug': slug,
    if (phases.isNotEmpty) 'phases': phases,
    if (packageProvenance != null)
      'packageProvenance': packageProvenance!.toJson(),
  };
}

/// Backward-compatible reader for both the historical B25 row array and the
/// capture manifests written by the current capture runner.
final class B25CaptureManifest {
  const B25CaptureManifest({required this.communities});

  factory B25CaptureManifest.fromFile(File file) =>
      B25CaptureManifest.fromJson(jsonDecode(file.readAsStringSync()));

  factory B25CaptureManifest.fromJson(Object? json) {
    if (json is List) {
      return B25CaptureManifest(
        communities: json
            .whereType<Map<Object?, Object?>>()
            .map(
              (entry) => B25CapturedCommunity.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(growable: false),
      );
    }
    if (json is! Map) {
      throw const FormatException(
        'A B25 capture manifest must be a JSON object or array.',
      );
    }
    final manifest = Map<String, dynamic>.from(json);
    final capturedCommunities = manifest['capturedCommunities'];
    if (capturedCommunities is List) {
      return B25CaptureManifest(
        communities: capturedCommunities
            .whereType<Map<Object?, Object?>>()
            .map(
              (entry) => B25CapturedCommunity.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList(growable: false),
      );
    }

    // The first schema used phase manifests with workflow rows only. Reading
    // those remains useful, but correctly leaves their build provenance
    // unknown rather than manufacturing a current/stale conclusion.
    final workflows = manifest['workflows'];
    if (workflows is List) {
      return B25CaptureManifest(
        communities: _communitiesFromWorkflowRows(workflows),
      );
    }
    return const B25CaptureManifest(communities: <B25CapturedCommunity>[]);
  }

  final List<B25CapturedCommunity> communities;

  Map<String, Object?> toJson() => <String, Object?>{
    'capturedCommunities': [
      for (final community in communities) community.toJson(),
    ],
  };
}

/// A provenance entry associated with the community identity in a shipped
/// package. This joins capture rows to the existing provenance manifest; it
/// does not create another package-identity source.
final class CommunityPackageProvenanceRecord {
  const CommunityPackageProvenanceRecord({
    required this.communityId,
    required this.communityName,
    required this.extensionId,
    required this.packageName,
    required this.entry,
  });

  final String? communityId;
  final String? communityName;
  final String? extensionId;
  final String packageName;
  final CommunityPackageProvenanceEntry entry;

  CapturedCommunityPackageProvenance get capturedProvenance =>
      CapturedCommunityPackageProvenance(
        packageName: packageName,
        entry: entry,
      );
}

/// Looks up the provenance-manifest entry for a captured community.
final class CommunityPackageProvenanceIndex {
  CommunityPackageProvenanceIndex(
    Iterable<CommunityPackageProvenanceRecord> records,
  ) : _records = List<CommunityPackageProvenanceRecord>.unmodifiable(records);

  factory CommunityPackageProvenanceIndex.fromRepository({
    required Directory repositoryRoot,
    required CommunityPackageProvenanceManifest provenanceManifest,
  }) {
    final records = <CommunityPackageProvenanceRecord>[];
    for (final packageFile in communityPackageFiles(repositoryRoot)) {
      final packageName = communityPackageFileName(packageFile);
      final entry = provenanceManifest.packages[packageName];
      // A package omitted from current provenance must remain observable as an
      // unknown capture, not turn a historical or partial manifest into an
      // error.
      if (entry == null) continue;
      final decoded = jsonDecode(
        stripJsonComments(packageFile.readAsStringSync()),
      );
      if (decoded is! Map) {
        throw FormatException(
          'Community package $packageName must decode to a JSON object.',
        );
      }
      final package = Map<String, dynamic>.from(decoded);
      records.add(
        CommunityPackageProvenanceRecord(
          communityId: _nonEmptyString(package['communityId']),
          communityName: _nonEmptyString(package['displayName']),
          extensionId: _nonEmptyString(package['extensionId']),
          packageName: packageName,
          entry: entry,
        ),
      );
    }
    return CommunityPackageProvenanceIndex(records);
  }

  final List<CommunityPackageProvenanceRecord> _records;

  CommunityPackageProvenanceRecord? forCommunity({
    String? communityId,
    String? communityName,
    String? extensionId,
  }) {
    if (extensionId != null && extensionId.isNotEmpty) {
      for (final record in _records) {
        if (record.extensionId == extensionId) return record;
      }
    }
    if (communityId != null && communityId.isNotEmpty) {
      for (final record in _records) {
        if (record.communityId == communityId) return record;
      }
    }
    if (communityName != null && communityName.isNotEmpty) {
      for (final record in _records) {
        if (record.communityName == communityName) return record;
      }
    }
    return null;
  }
}

/// Adds the current package provenance to a phase manifest after the
/// walkthrough has finished capturing it.
///
/// The runner owns this mutation, so the UI walkthrough and screenshot writer
/// remain unchanged. A row that cannot be joined to a current provenance entry
/// is retained without [B25CapturedCommunity.packageProvenance], which reports
/// as [CaptureProvenanceStatus.unknown] later.
List<B25CapturedCommunity> recordB25CapturePackageProvenance({
  required Map<String, dynamic> manifest,
  required CommunityPackageProvenanceIndex provenanceIndex,
}) {
  final phase = _nonEmptyString(manifest['phase']);
  final workflows = manifest['workflows'];
  final communities = _communitiesFromWorkflowRows(
    workflows is List ? workflows : const <Object?>[],
    phase: phase,
    provenanceIndex: provenanceIndex,
  );
  manifest['capturedCommunities'] = [
    for (final community in communities) community.toJson(),
  ];
  return communities;
}

/// Combines phase-level captured communities for an aggregate capture
/// manifest, preserving all phases that exercised each package.
List<B25CapturedCommunity> combineB25CapturedCommunities(
  Iterable<B25CapturedCommunity> communities,
) {
  final combined = <String, _CombinedCapturedCommunity>{};
  for (final community in communities) {
    final key =
        community.communityId ??
        community.communityName ??
        community.slug ??
        community.packageProvenance?.packageName ??
        'unknown-${combined.length}';
    final existing = combined[key];
    if (existing == null) {
      combined[key] = _CombinedCapturedCommunity.fromCommunity(community);
    } else {
      existing.add(community);
    }
  }
  final result = combined.values.map((entry) => entry.toCommunity()).toList()
    ..sort((left, right) => left.reportName.compareTo(right.reportName));
  return result;
}

/// The three possible outcomes for a captured community. In particular,
/// [unknown] is intentionally distinct from [stale].
enum CaptureProvenanceStatus { current, stale, unknown }

/// A single community's comparison against the current provenance manifest.
final class CaptureProvenanceComparison {
  const CaptureProvenanceComparison({
    required this.community,
    required this.status,
  });

  final B25CapturedCommunity community;
  final CaptureProvenanceStatus status;

  bool get isStale => status == CaptureProvenanceStatus.stale;
}

/// Compares durable B25 capture evidence to the current provenance manifest.
///
/// Callers can report [CaptureProvenanceComparison.status] for every captured
/// community, or use [staleCapturedCommunities] when only changed package
/// builds are relevant.
List<CaptureProvenanceComparison> compareB25CaptureManifestProvenance({
  required B25CaptureManifest captureManifest,
  required CommunityPackageProvenanceManifest currentProvenance,
}) => [
  for (final community in captureManifest.communities)
    CaptureProvenanceComparison(
      community: community,
      status: _provenanceStatusFor(
        community: community,
        currentProvenance: currentProvenance,
      ),
    ),
];

List<CaptureProvenanceComparison> staleCapturedCommunities({
  required B25CaptureManifest captureManifest,
  required CommunityPackageProvenanceManifest currentProvenance,
}) => compareB25CaptureManifestProvenance(
  captureManifest: captureManifest,
  currentProvenance: currentProvenance,
).where((comparison) => comparison.isStale).toList(growable: false);

CaptureProvenanceStatus _provenanceStatusFor({
  required B25CapturedCommunity community,
  required CommunityPackageProvenanceManifest currentProvenance,
}) {
  final captured = community.packageProvenance;
  if (captured == null) return CaptureProvenanceStatus.unknown;
  final current = currentProvenance.packages[captured.packageName];
  if (current == null) return CaptureProvenanceStatus.unknown;
  return current.sha256 == captured.entry.sha256
      ? CaptureProvenanceStatus.current
      : CaptureProvenanceStatus.stale;
}

List<B25CapturedCommunity> _communitiesFromWorkflowRows(
  Iterable<Object?> workflows, {
  String? phase,
  CommunityPackageProvenanceIndex? provenanceIndex,
}) {
  final communities = <String, _CombinedCapturedCommunity>{};
  for (final rawWorkflow in workflows) {
    if (rawWorkflow is! Map) continue;
    final workflow = Map<String, dynamic>.from(rawWorkflow);
    final communityId = _nonEmptyString(workflow['communityId']);
    final communityName = _nonEmptyString(workflow['communityName']);
    final slug = _nonEmptyString(workflow['slug']);
    final extensionId = _nonEmptyString(workflow['appId']);
    if (communityId == null && communityName == null && slug == null) continue;
    final provenanceRecord = provenanceIndex?.forCommunity(
      communityId: communityId,
      communityName: communityName,
      extensionId: extensionId,
    );
    final provenance = provenanceRecord?.capturedProvenance;
    final community = B25CapturedCommunity(
      communityId: communityId,
      communityName: communityName,
      slug: slug,
      phases: phase == null ? const <String>[] : <String>[phase],
      packageProvenance: provenance,
    );
    final key = communityId ?? communityName ?? slug!;
    final existing = communities[key];
    if (existing == null) {
      communities[key] = _CombinedCapturedCommunity.fromCommunity(community);
    } else {
      existing.add(community);
    }
  }
  final result = communities.values.map((entry) => entry.toCommunity()).toList()
    ..sort((left, right) => left.reportName.compareTo(right.reportName));
  return result;
}

final class _CombinedCapturedCommunity {
  _CombinedCapturedCommunity.fromCommunity(B25CapturedCommunity community)
    : communityId = community.communityId,
      communityName = community.communityName,
      slug = community.slug,
      packageProvenance = community.packageProvenance,
      phases = <String>{...community.phases};

  final String? communityId;
  final String? communityName;
  final String? slug;
  CapturedCommunityPackageProvenance? packageProvenance;
  final Set<String> phases;

  void add(B25CapturedCommunity community) {
    phases.addAll(community.phases);
    packageProvenance ??= community.packageProvenance;
  }

  B25CapturedCommunity toCommunity() {
    final sortedPhases = phases.toList()..sort();
    return B25CapturedCommunity(
      communityId: communityId,
      communityName: communityName,
      slug: slug,
      phases: sortedPhases,
      packageProvenance: packageProvenance,
    );
  }
}

bool _hasCompletePackageProvenance(Map<String, dynamic> json) =>
    json['packageName'] is String &&
    json['sha256'] is String &&
    json['bytes'] is int &&
    json['authoredBy'] is String &&
    json['lastCommit'] is String &&
    json['lastCommitDate'] is String &&
    json['lastCommitSubject'] is String;

String? _nonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

List<String> _stringList(Object? value) => (value as List? ?? const <Object?>[])
    .whereType<String>()
    .toList(growable: false);
