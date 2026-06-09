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
