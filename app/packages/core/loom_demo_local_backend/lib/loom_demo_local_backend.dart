import 'dart:convert';
import 'dart:io';

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
  });

  final String communityId;
  final String displayName;
  final String extensionId;
  final String? logoAssetId;
  final String? cardImageAssetId;
  final String? heroImageAssetId;
  final String accentColor;
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
  });

  final LoomExtensionPackageSummary extensionPackage;
  final LoomInitializationPackageSummary initializationPackage;
  final String accentColor;
  final String? logoAssetId;
  final String? heroImageAssetId;
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
    } else if (requireReadableFiles &&
        !File(initializationPath).existsSync()) {
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
    );
    final initialization = _readJsonObject(
      initializationPackagePath,
      packageLabel: 'initialization package',
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
      communityName: _requiredString(initialization, 'communityName'),
      extensionId: initExtensionId,
      seedDataFiles: _stringList(initialization['seedDataFiles']),
      cardAssetId:
          _optionalString(initialization['cardAssetId']) ??
          _optionalString(branding?['cardAssetId']),
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
          _optionalString(branding?['logoAssetId']),
      heroImageAssetId:
          _optionalString(initialization['heroImageAssetId']) ??
          _optionalString(branding?['heroImageAssetId']),
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
  }) {
    final existing = _communities[package.communityId];
    if (existing != null) {
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
    );
    _communities[community.communityId] = community;
    return LocalBackendImportReport(
      community: community,
      created: true,
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
}) {
  try {
    final Object? decoded = jsonDecode(File(path).readAsStringSync());
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
