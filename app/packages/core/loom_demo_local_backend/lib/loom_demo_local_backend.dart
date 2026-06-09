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
  }) {
    final errors = <String>[];
    final extensionPath = extensionPackagePath.trim();
    final initializationPath = initializationPackagePath.trim();
    if (extensionPath.isEmpty) {
      errors.add('Choose an extension package.');
    } else if (!extensionPath.endsWith('.loom-extension.zip')) {
      errors.add('Extension package must end with .loom-extension.zip.');
    }
    if (initializationPath.isEmpty) {
      errors.add('Choose an initialization package.');
    } else if (!initializationPath.endsWith('.loom-init.zip')) {
      errors.add('Initialization package must end with .loom-init.zip.');
    }
    return LocalPackagePairValidation(errors: errors);
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
