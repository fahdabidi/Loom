import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

export 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

const bool _preloadExampleCommunities = bool.fromEnvironment(
  'LOOM_PRELOAD_EXAMPLE_COMMUNITIES',
);

void main() {
  final remoteServices = configureLoomRemoteServicesFromEnvironment();
  if (remoteServices != null) {
    configureEngineNativeCommunityEngineFactoryForProduction(
      createRemoteEngineNativeCommunityEngineFactoryForConfiguration(
        configuration: remoteServices,
        httpClient: http.Client(),
      ),
    );
  }
  runApp(const LoomCommunitiesDemoApp());
}

class LoomCommunitiesDemoApp extends StatelessWidget {
  const LoomCommunitiesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loom Communities Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff246b62)),
        scaffoldBackgroundColor: const Color(0xfffbfffd),
        useMaterial3: true,
      ),
      home: const LoomCommunitiesHome(),
    );
  }
}

class LoomCommunitiesHome extends StatefulWidget {
  const LoomCommunitiesHome({super.key});

  @override
  State<LoomCommunitiesHome> createState() => _LoomCommunitiesHomeState();
}

class _LoomCommunitiesHomeState extends State<LoomCommunitiesHome> {
  late final LocalInAppBackend _backend;
  late final Map<String, List<String>> _importedSeedFilesByCommunityId;
  late final Map<String, LoomAuthApi> _authApisByCommunityId;
  late final ScrollController _communityScrollController;
  String? _lastLocalImportMessage;
  String? _focusedCommunityId;

  @override
  void initState() {
    super.initState();
    _communityScrollController = ScrollController()
      ..addListener(_updateFocusedCommunityFromScroll);
    _backend = LocalInAppBackend(
      snapshot: _preloadExampleCommunities
          ? preloadedExampleCommunitiesSnapshot()
          : null,
    );
    _importedSeedFilesByCommunityId = _preloadExampleCommunities
        ? preloadedSeedFilesByCommunityId()
        : {};
    _authApisByCommunityId = {};
    _lastLocalImportMessage = _preloadExampleCommunities
        ? 'Loaded ${loomEvidenceTargets.length} example communities'
        : null;
  }

  @override
  void dispose() {
    _communityScrollController
      ..removeListener(_updateFocusedCommunityFromScroll)
      ..dispose();
    super.dispose();
  }

  void _updateFocusedCommunityFromScroll() {
    if (!_communityScrollController.hasClients) {
      return;
    }
    final communities = _backend.listCommunities();
    if (communities.isEmpty) {
      return;
    }
    final estimatedIndex = (_communityScrollController.offset / 132)
        .round()
        .clamp(0, communities.length - 1);
    final nextFocused = communities[estimatedIndex].communityId;
    if (nextFocused != _focusedCommunityId && mounted) {
      setState(() => _focusedCommunityId = nextFocused);
    }
  }

  Future<void> _showLocalPackageLoader() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return LocalPackageLoaderDialog(onInstall: _installLocalPackagePair);
      },
    );
  }

  String? _installLocalPackagePair({
    required String extensionPackagePath,
    required String initializationPackagePath,
  }) {
    late final LocalBackendImportReport report;
    try {
      report = _backend.installLocalPackagePairFromFiles(
        extensionPackagePath: extensionPackagePath,
        initializationPackagePath: initializationPackagePath,
      );
    } on StateError catch (error) {
      return error.message;
    }
    setState(() {
      _authApisByCommunityId.remove(report.community.communityId);
      _importedSeedFilesByCommunityId[report.community.communityId] =
          report.importedSeedFiles;
      _lastLocalImportMessage = reportMessage(
        communityName: report.community.displayName,
        created: report.created,
      );
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final communities = _backend.listCommunities();
    final focusedCommunityId =
        _focusedCommunityId ??
        (communities.isNotEmpty ? communities.first.communityId : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Loom Communities')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-community-button'),
        onPressed: _showLocalPackageLoader,
        icon: const Icon(Icons.add),
        label: const Text('Add Community'),
      ),
      body: communities.isEmpty
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyCommunityState(
                    onAddCommunity: _showLocalPackageLoader,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                if (_lastLocalImportMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: MaterialBanner(
                      key: const ValueKey('local-import-status'),
                      content: Text(_lastLocalImportMessage!),
                      leading: const Icon(Icons.check_circle_outline),
                      actions: const [SizedBox.shrink()],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    key: const ValueKey('community-list'),
                    controller: _communityScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
                    itemCount: communities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      final experience = experienceForExtensionId(
                        community.extensionId,
                        displayName: community.displayName,
                        specVersion: community.specVersion,
                        experienceConfiguration:
                            community.experienceConfiguration,
                      );
                      final presentationState =
                          community.communityId == focusedCommunityId
                          ? SurfacePresentationState.medium
                          : SurfacePresentationState.minimized;
                      return CommunityLaunchCard(
                        key: ValueKey(
                          'community-card-${community.communityId}',
                        ),
                        community: community,
                        experience: experience,
                        state: presentationState,
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) => LocalExtensionScreen(
                                community: community,
                                seedDataFiles:
                                    _importedSeedFilesByCommunityId[community
                                        .communityId] ??
                                    const [],
                                authApi: _authApiForCommunity(community),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String reportMessage({required String communityName, required bool created}) {
    return created
        ? 'Installed $communityName from local packages'
        : 'Updated $communityName from local packages';
  }

  LoomAuthApi _authApiForCommunity(LocalInstalledCommunity community) {
    return _authApisByCommunityId.putIfAbsent(community.communityId, () {
      return LocalAuthApi(
        actorIdentityResolver: (communityExtensionId) {
          final experience = _experienceForInstalledCommunityExtensionId(
            communityExtensionId,
          );
          return actorIdentitiesForExtensionId(
            communityExtensionId,
            experience: experience,
          );
        },
        experienceResolver: _experienceForInstalledCommunityExtensionId,
      );
    });
  }

  LoomExperienceDefinition _experienceForInstalledCommunityExtensionId(
    String communityExtensionId,
  ) {
    for (final community in _backend.listCommunities()) {
      if (community.extensionId == communityExtensionId) {
        return experienceForExtensionId(
          community.extensionId,
          displayName: community.displayName,
          specVersion: community.specVersion,
          experienceConfiguration: community.experienceConfiguration,
        );
      }
    }
    throw ArgumentError.value(
      communityExtensionId,
      'communityExtensionId',
      'must identify an installed community',
    );
  }
}
