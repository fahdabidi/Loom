class LoomExtensionPackageFormat {
  static const int specVersion = 4;
  static const String extensionManifestFile = 'loom.extension.json';
  static const String initializationManifestFile = 'loom.initialization.json';
  static const String assetManifestFile = 'assets/loom.assets.json';

  const LoomExtensionPackageFormat._();
}

class LoomExtensionPackageSummary {
  const LoomExtensionPackageSummary({
    required this.extensionId,
    required this.displayName,
    required this.version,
    required this.permissions,
    required this.assetIds,
  });

  final String extensionId;
  final String displayName;
  final String version;
  final List<String> permissions;
  final List<String> assetIds;
}

class LoomInitializationPackageSummary {
  const LoomInitializationPackageSummary({
    required this.communityId,
    required this.communityName,
    required this.extensionId,
    required this.seedDataFiles,
    required this.cardAssetId,
  });

  final String communityId;
  final String communityName;
  final String extensionId;
  final List<String> seedDataFiles;
  final String? cardAssetId;
}
