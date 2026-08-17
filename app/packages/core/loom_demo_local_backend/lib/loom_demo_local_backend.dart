import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:loom_extension_package/loom_extension_package.dart';

class LoomDemoLocalBackendCapabilities {
  static const List<String> phase0Endpoints = [
    'GET /local/communities',
    'POST /local/extensions/load',
    'POST /local/initialization/import',
    'POST /local/reset',
  ];

  const LoomDemoLocalBackendCapabilities._();
}

class LocalCommunityInstallDraft {
  const LocalCommunityInstallDraft({
    required this.extensionPackage,
    required this.initializationPackage,
  });

  final LoomExtensionPackageSummary extensionPackage;
  final LoomInitializationPackageSummary initializationPackage;
}

class LocalInstalledCommunity {
  const LocalInstalledCommunity({
    required this.communityId,
    required this.displayName,
    required this.extensionId,
    required this.logoAssetId,
    required this.cardImageAssetId,
    required this.heroImageAssetId,
    required this.accentColor,
    this.specVersion,
    this.appShellConfiguration = const {},
    this.experienceConfiguration = const {},
  });

  final String communityId;
  final String displayName;
  final String extensionId;
  final String? logoAssetId;
  final String? cardImageAssetId;
  final String? heroImageAssetId;
  final String accentColor;
  final int? specVersion;
  final Map<String, Object?> appShellConfiguration;

  /// Package-declared workflows/personas/persona-policies (from the
  /// `experience` block in `loom.initialization.json` or
  /// `loom.extension.json`). Empty when the package did not declare one, in
  /// which case the App Shell falls back to its hardcoded demo catalog.
  final Map<String, Object?> experienceConfiguration;
}

class LocalBackendImportReport {
  const LocalBackendImportReport({
    required this.community,
    required this.created,
    required this.importedSeedFiles,
  });

  final LocalInstalledCommunity community;
  final bool created;
  final List<String> importedSeedFiles;
}

class LocalBackendSnapshot {
  const LocalBackendSnapshot({
    required this.communities,
    required this.loadedExtensionIds,
  });

  final List<LocalInstalledCommunity> communities;
  final List<String> loadedExtensionIds;
}

class LocalPackagePairValidation {
  const LocalPackagePairValidation({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class LocalPackagePairInstallPlan {
  const LocalPackagePairInstallPlan({
    required this.extensionPackage,
    required this.initializationPackage,
    required this.accentColor,
    required this.logoAssetId,
    required this.heroImageAssetId,
    required this.appShellConfiguration,
    this.specVersion,
    this.experienceConfiguration = const {},
  });

  final LoomExtensionPackageSummary extensionPackage;
  final LoomInitializationPackageSummary initializationPackage;
  final String accentColor;
  final String? logoAssetId;
  final String? heroImageAssetId;
  final Map<String, Object?> appShellConfiguration;
  final int? specVersion;
  final Map<String, Object?> experienceConfiguration;
}

class LocalInAppBackend {
  LocalInAppBackend({LocalBackendSnapshot? snapshot}) {
    if (snapshot != null) {
      for (final community in snapshot.communities) {
        _communities[community.communityId] = community;
      }
      _loadedExtensionIds.addAll(snapshot.loadedExtensionIds);
    }
  }

  final Map<String, LocalInstalledCommunity> _communities = {};
  final Set<String> _loadedExtensionIds = {};

  List<LocalInstalledCommunity> listCommunities() {
    return _communities.values.toList(growable: false);
  }

  bool isExtensionLoaded(String extensionId) {
    return _loadedExtensionIds.contains(extensionId);
  }

  LocalPackagePairValidation validateLocalPackagePair({
    required String extensionPackagePath,
    required String initializationPackagePath,
    bool requireReadableFiles = false,
  }) {
    final errors = <String>[];
    final extensionPath = extensionPackagePath.trim();
    final initializationPath = initializationPackagePath.trim();
    if (extensionPath.isEmpty) {
      errors.add('Choose an extension package.');
    } else if (!extensionPath.endsWith('.loom-extension.zip')) {
      errors.add('Extension package must end with .loom-extension.zip.');
    } else if (requireReadableFiles && !File(extensionPath).existsSync()) {
      errors.add('Extension package file was not found.');
    }
    if (initializationPath.isEmpty) {
      errors.add('Choose an initialization package.');
    } else if (!initializationPath.endsWith('.loom-init.zip')) {
      errors.add('Initialization package must end with .loom-init.zip.');
    } else if (requireReadableFiles && !File(initializationPath).existsSync()) {
      errors.add('Initialization package file was not found.');
    }
    return LocalPackagePairValidation(errors: errors);
  }

  LocalPackagePairInstallPlan parseLocalPackagePair({
    required String extensionPackagePath,
    required String initializationPackagePath,
  }) {
    final validation = validateLocalPackagePair(
      extensionPackagePath: extensionPackagePath,
      initializationPackagePath: initializationPackagePath,
      requireReadableFiles: true,
    );
    if (!validation.isValid) {
      throw StateError(validation.errors.join('\n'));
    }

    final extension = _readJsonObject(
      extensionPackagePath,
      packageLabel: 'extension package',
      manifestFileName: LoomExtensionPackageFormat.extensionManifestFile,
    );
    final initialization = _readJsonObject(
      initializationPackagePath,
      packageLabel: 'initialization package',
      manifestFileName: LoomExtensionPackageFormat.initializationManifestFile,
    );
    final extensionPackage = LoomExtensionPackageSummary(
      extensionId: _requiredString(extension, 'extensionId'),
      displayName: _requiredString(extension, 'displayName'),
      version: _requiredString(extension, 'version'),
      permissions: _stringList(extension['permissions']),
      assetIds: _assetIds(extension),
    );
    final initExtensionId = _requiredString(initialization, 'extensionId');
    if (initExtensionId != extensionPackage.extensionId) {
      throw StateError(
        'Initialization package extensionId must match extension package.',
      );
    }
    final branding = _objectMap(initialization['branding']);
    final initializationPackage = LoomInitializationPackageSummary(
      communityId: _requiredString(initialization, 'communityId'),
      communityName:
          _optionalString(initialization['communityName']) ??
          _requiredString(initialization, 'displayName'),
      extensionId: initExtensionId,
      seedDataFiles: _stringList(initialization['seedDataFiles']),
      cardAssetId:
          _optionalString(initialization['cardAssetId']) ??
          _optionalString(branding?['cardAssetId']) ??
          _optionalString(branding?['cardImage']),
    );

    return LocalPackagePairInstallPlan(
      extensionPackage: extensionPackage,
      initializationPackage: initializationPackage,
      accentColor:
          _optionalString(initialization['accentColor']) ??
          _optionalString(branding?['accentColor']) ??
          '#246B62',
      logoAssetId:
          _optionalString(initialization['logoAssetId']) ??
          _optionalString(branding?['logoAssetId']) ??
          _optionalString(branding?['logo']),
      heroImageAssetId:
          _optionalString(initialization['heroImageAssetId']) ??
          _optionalString(branding?['heroImageAssetId']) ??
          _optionalString(branding?['heroImage']),
      specVersion: initialization['specVersion'] as int?,
      appShellConfiguration:
          _objectMap(initialization['appShell']) ??
          _objectMap(initialization['appShellCustomization']) ??
          _objectMap(extension['appShell']) ??
          const {},
      experienceConfiguration:
          _objectMap(initialization['experience']) ??
          _objectMap(extension['experience']) ??
          const {},
    );
  }

  LocalBackendImportReport installLocalPackagePairFromFiles({
    required String extensionPackagePath,
    required String initializationPackagePath,
  }) {
    final plan = parseLocalPackagePair(
      extensionPackagePath: extensionPackagePath,
      initializationPackagePath: initializationPackagePath,
    );
    loadExtensionPackage(plan.extensionPackage);
    return importInitializationPackage(
      plan.initializationPackage,
      accentColor: plan.accentColor,
      logoAssetId: plan.logoAssetId,
      heroImageAssetId: plan.heroImageAssetId,
      specVersion: plan.specVersion,
      appShellConfiguration: plan.appShellConfiguration,
      experienceConfiguration: plan.experienceConfiguration,
    );
  }

  void loadExtensionPackage(LoomExtensionPackageSummary package) {
    _loadedExtensionIds.add(package.extensionId);
  }

  LocalBackendImportReport importInitializationPackage(
    LoomInitializationPackageSummary package, {
    String accentColor = '#246B62',
    String? logoAssetId,
    String? heroImageAssetId,
    int? specVersion,
    Map<String, Object?> appShellConfiguration = const {},
    Map<String, Object?> experienceConfiguration = const {},
  }) {
    final existing = _communities[package.communityId];
    final shouldHydratePreloadedShell = existing != null &&
        existing.experienceConfiguration.isEmpty &&
        experienceConfiguration.isNotEmpty;
    if (existing != null && !shouldHydratePreloadedShell) {
      return LocalBackendImportReport(
        community: existing,
        created: false,
        importedSeedFiles: package.seedDataFiles,
      );
    }
    final community = LocalInstalledCommunity(
      communityId: package.communityId,
      displayName: package.communityName,
      extensionId: package.extensionId,
      logoAssetId: logoAssetId,
      cardImageAssetId: package.cardAssetId,
      heroImageAssetId: heroImageAssetId,
      accentColor: accentColor,
      specVersion: specVersion,
      appShellConfiguration: appShellConfiguration,
      experienceConfiguration: experienceConfiguration,
    );
    _communities[community.communityId] = community;
    return LocalBackendImportReport(
      community: community,
      created: existing == null,
      importedSeedFiles: package.seedDataFiles,
    );
  }

  LocalBackendSnapshot snapshot() {
    return LocalBackendSnapshot(
      communities: listCommunities(),
      loadedExtensionIds: _loadedExtensionIds.toList(growable: false),
    );
  }

  void reset() {
    _communities.clear();
    _loadedExtensionIds.clear();
  }
}

Map<String, Object?> _readJsonObject(
  String path, {
  required String packageLabel,
  required String manifestFileName,
}) {
  final bytes = File(path).readAsBytesSync();
  final archivedManifest = _tryReadArchivedManifest(
    bytes,
    manifestFileName: manifestFileName,
  );
  if (archivedManifest != null) {
    return archivedManifest;
  }

  try {
    final Object? decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  } on FormatException catch (error) {
    throw StateError('$packageLabel could not be parsed: ${error.message}');
  } on FileSystemException catch (error) {
    throw StateError('$packageLabel could not be read: ${error.message}');
  }
  throw StateError('$packageLabel must contain a JSON object.');
}

Map<String, Object?>? _tryReadArchivedManifest(
  List<int> bytes, {
  required String manifestFileName,
}) {
  try {
    final archive = _ZipArchiveView(Uint8List.fromList(bytes));
    final manifestBytes = archive.readFile(manifestFileName);
    if (manifestBytes == null) {
      throw StateError('Package archive must include $manifestFileName.');
    }
    final Object? decoded = jsonDecode(utf8.decode(manifestBytes));
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    throw StateError('$manifestFileName must contain a JSON object.');
  } on _NotZipArchive {
    return null;
  }
}

class _ZipArchiveView {
  _ZipArchiveView(this._bytes) : _data = ByteData.sublistView(_bytes);

  final Uint8List _bytes;
  final ByteData _data;

  Uint8List? readFile(String name) {
    final eocd = _findEndOfCentralDirectory();
    if (eocd == -1) {
      throw const _NotZipArchive();
    }
    final entries = _u16(eocd + 10);
    var offset = _u32(eocd + 16);
    for (var index = 0; index < entries; index += 1) {
      if (_u32(offset) != 0x02014b50) {
        throw StateError('Invalid ZIP central directory.');
      }
      final flags = _u16(offset + 8);
      final method = _u16(offset + 10);
      final compressedSize = _u32(offset + 20);
      final nameLength = _u16(offset + 28);
      final extraLength = _u16(offset + 30);
      final commentLength = _u16(offset + 32);
      final localHeaderOffset = _u32(offset + 42);
      final entryName = utf8.decode(_slice(offset + 46, nameLength));
      if (entryName == name) {
        return _readLocalFile(
          localHeaderOffset: localHeaderOffset,
          compressedSize: compressedSize,
          flags: flags,
          method: method,
        );
      }
      offset += 46 + nameLength + extraLength + commentLength;
    }
    return null;
  }

  Uint8List _readLocalFile({
    required int localHeaderOffset,
    required int compressedSize,
    required int flags,
    required int method,
  }) {
    if (_u32(localHeaderOffset) != 0x04034b50) {
      throw StateError('Invalid ZIP local file header.');
    }
    if ((flags & 0x0001) != 0) {
      throw StateError('Encrypted ZIP packages are not supported.');
    }
    final nameLength = _u16(localHeaderOffset + 26);
    final extraLength = _u16(localHeaderOffset + 28);
    final dataOffset = localHeaderOffset + 30 + nameLength + extraLength;
    final compressed = _slice(dataOffset, compressedSize);
    if (method == 0) {
      return compressed;
    }
    if (method == 8) {
      return Uint8List.fromList(ZLibDecoder(raw: true).convert(compressed));
    }
    throw StateError('Unsupported ZIP compression method: $method.');
  }

  int _findEndOfCentralDirectory() {
    if (_bytes.length < 4) {
      return -1;
    }
    final start = (_bytes.length - 22).clamp(0, _bytes.length - 4).toInt();
    for (var offset = start; offset >= 0; offset -= 1) {
      if (_u32(offset) == 0x06054b50) {
        return offset;
      }
    }
    return -1;
  }

  Uint8List _slice(int start, int length) {
    return Uint8List.sublistView(_bytes, start, start + length);
  }

  int _u16(int offset) => _data.getUint16(offset, Endian.little);

  int _u32(int offset) => _data.getUint32(offset, Endian.little);
}

class _NotZipArchive implements Exception {
  const _NotZipArchive();
}

Map<String, Object?>? _objectMap(Object? value) {
  return value is Map<String, Object?> ? value : null;
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = _optionalString(map[key]);
  if (value == null) {
    throw StateError('$key is required.');
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List<Object?>) {
    return const [];
  }
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _assetIds(Map<String, Object?> extension) {
  final directAssetIds = _stringList(extension['assetIds']);
  final assets = extension['assets'];
  if (assets is List<Object?>) {
    return {
      ...directAssetIds,
      for (final asset in assets) ..._assetIdFromListEntry(asset),
    }.toList(growable: false);
  }
  if (assets is Map<String, Object?>) {
    return {
      ...directAssetIds,
      ...assets.values.whereType<String>().where((value) => value.isNotEmpty),
    }.toList(growable: false);
  }
  return directAssetIds;
}

Iterable<String> _assetIdFromListEntry(Object? asset) sync* {
  if (asset is String && asset.trim().isNotEmpty) {
    yield asset.trim();
  }
  if (asset is Map<String, Object?>) {
    final assetId = _optionalString(asset['assetId']);
    if (assetId != null) {
      yield assetId;
    }
  }
}
