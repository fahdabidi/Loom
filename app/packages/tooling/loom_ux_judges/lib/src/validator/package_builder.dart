// Bundles a validated Loom community initialization package (the JSON this
// Skill/GPT authors) into the pair of files the real Demo App's "Add
// Community" flow expects -- a `.loom-extension.zip` manifest and a
// `.loom-init.zip` initialization package.
//
// The two inner files are plain JSON text named with a `.zip` suffix, not
// real zip archives. This matches the app's own installer
// (`LocalInAppBackend.installLocalPackagePairFromFiles`,
// loom_demo_local_backend.dart), which tries to parse the bytes as a real
// zip first and falls back to treating the whole file as a plain JSON
// document if it isn't one -- the same convention this repo's own
// `generate_tabletop_club_package.dart` tool uses.
//
// Two output shapes are offered:
//   - buildExtensionPackagePlan: the manifest + both files' JSON text, no
//     zip involved. This is the one the HTTP server's ChatGPT-Action-facing
//     route uses -- binary (application/zip) Action responses were found to
//     fail in practice ("client transport exception" on every attempt,
//     while plain-JSON Action responses have been reliable), so the
//     Action-facing endpoint stays JSON-only.
//   - buildExtensionPackageZip: wraps the same plan into one real zip
//     archive (built with `package:archive`), for direct HTTP/CLI use where
//     binary responses aren't a problem.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

/// Required top-level fields on the init package, per
/// `LocalInAppBackend.parseLocalPackagePair`'s own validation
/// (loom_demo_local_backend.dart): `extensionId`, `communityId`,
/// `displayName` must all be present, non-empty strings.
class PackageBuilderError implements Exception {
  PackageBuilderError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The extension manifest + init package pair, before any zip encoding.
class ExtensionPackagePlan {
  ExtensionPackagePlan({
    required this.extensionId,
    required this.downloadFilename,
    required this.extensionManifest,
    required this.extensionManifestFilename,
    required this.initializationPackage,
    required this.initializationPackageFilename,
  });

  final String extensionId;
  final String downloadFilename;
  final Map<String, dynamic> extensionManifest;
  final String extensionManifestFilename;
  final Map<String, dynamic> initializationPackage;
  final String initializationPackageFilename;

  Map<String, dynamic> toJson() => {
    'extensionId': extensionId,
    'downloadFilename': downloadFilename,
    'extensionManifestFilename': extensionManifestFilename,
    'extensionManifest': extensionManifest,
    'initializationPackageFilename': initializationPackageFilename,
    'initializationPackage': initializationPackage,
  };
}

class BuiltExtensionPackage {
  BuiltExtensionPackage({required this.plan, required this.zipBytes});

  final ExtensionPackagePlan plan;
  final List<int> zipBytes;

  String get downloadFilename => plan.downloadFilename;
  String get extensionId => plan.extensionId;
  String get extensionManifestFilename => plan.extensionManifestFilename;
  String get initializationPackageFilename =>
      plan.initializationPackageFilename;
}

/// Validates the init package's real-installer-required fields and builds
/// the extension manifest + filenames. Throws [PackageBuilderError] if a
/// required field is missing.
ExtensionPackagePlan buildExtensionPackagePlan(
  Map<String, dynamic> initPackage,
) {
  final extensionId = _requireNonEmptyString(initPackage, 'extensionId');
  final communityId = _requireNonEmptyString(initPackage, 'communityId');
  final displayName = _requireNonEmptyString(initPackage, 'displayName');

  final handle = _sanitizeFilenameStem(
    (initPackage['communityHandle'] as String?)?.trim().isNotEmpty == true
        ? initPackage['communityHandle'] as String
        : communityId,
  );

  final extensionManifest = <String, dynamic>{
    'specVersion': currentCommunitySpecVersion,
    'extensionId': extensionId,
    'displayName': displayName,
    'version': '1.0.0',
    'mode': 'local-demo',
  };

  return ExtensionPackagePlan(
    extensionId: extensionId,
    downloadFilename: '$handle-loom-package.zip',
    extensionManifest: extensionManifest,
    extensionManifestFilename: '$handle.loom-extension.zip',
    initializationPackage: initPackage,
    initializationPackageFilename: '$handle.loom-init.zip',
  );
}

/// Builds the plan, then wraps both files into one real zip archive.
BuiltExtensionPackage buildExtensionPackageZip(
  Map<String, dynamic> initPackage,
) {
  final plan = buildExtensionPackagePlan(initPackage);
  const encoder = JsonEncoder.withIndent('  ');

  final archive = Archive();
  archive.addFile(
    ArchiveFile.bytes(
      plan.extensionManifestFilename,
      utf8.encode(encoder.convert(plan.extensionManifest)),
    ),
  );
  archive.addFile(
    ArchiveFile.bytes(
      plan.initializationPackageFilename,
      utf8.encode(encoder.convert(plan.initializationPackage)),
    ),
  );

  return BuiltExtensionPackage(
    plan: plan,
    zipBytes: ZipEncoder().encode(archive),
  );
}

String _requireNonEmptyString(Map<String, dynamic> package, String key) {
  final value = package[key];
  if (value is! String || value.trim().isEmpty) {
    throw PackageBuilderError(
      'Package is missing required non-empty string field "$key" -- the '
      'real installer (LocalInAppBackend.parseLocalPackagePair) requires '
      'extensionId, communityId, and displayName. Fix the package and '
      'validate it again before packaging.',
    );
  }
  return value;
}

String _sanitizeFilenameStem(String raw) {
  final lower = raw.trim().toLowerCase();
  final sanitized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final trimmed = sanitized.replaceAll(RegExp(r'^-+|-+$'), '');
  return trimmed.isEmpty ? 'community' : trimmed;
}
