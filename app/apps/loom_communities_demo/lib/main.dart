import 'package:flutter/material.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_extension_package/loom_extension_package.dart';

void main() {
  runApp(const LoomCommunitiesDemoApp());
}

class LoomCommunitiesDemoApp extends StatelessWidget {
  const LoomCommunitiesDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loom Communities Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff246b62)),
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
  final LocalInAppBackend _backend = LocalInAppBackend();
  String? _lastLocalImportMessage;

  Future<void> _showLocalPackageLoader() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _LocalPackageLoaderDialog(onInstall: _installLocalPackagePair);
      },
    );
  }

  String? _installLocalPackagePair({
    required String extensionPackagePath,
    required String initializationPackagePath,
  }) {
    final validation = _backend.validateLocalPackagePair(
      extensionPackagePath: extensionPackagePath,
      initializationPackagePath: initializationPackagePath,
    );
    if (!validation.isValid) {
      return validation.errors.join('\n');
    }

    _backend.loadExtensionPackage(
      const LoomExtensionPackageSummary(
        extensionId: 'ext_book_club',
        displayName: 'Book Club',
        version: '1.0.0',
        permissions: ['content.publish'],
        assetIds: ['asset_card_book_club'],
      ),
    );
    final report = _backend.importInitializationPackage(
      const LoomInitializationPackageSummary(
        communityId: 'community_book_club',
        communityName: 'Neighborhood Book Club',
        extensionId: 'ext_book_club',
        seedDataFiles: ['seed/community.json'],
        cardAssetId: 'asset_card_book_club',
      ),
      logoAssetId: 'asset_logo_book_club',
      heroImageAssetId: 'asset_hero_book_club',
    );
    setState(() {
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
                  child: _EmptyCommunityState(
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
                    padding: const EdgeInsets.all(16),
                    itemCount: communities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final community = communities[index];
                      return Card(
                        child: ListTile(
                          key: ValueKey(
                            'community-card-${community.communityId}',
                          ),
                          title: Text(community.displayName),
                          subtitle: Text(community.extensionId),
                          leading: CircleAvatar(
                            child: Text(community.displayName.substring(0, 1)),
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Opening ${community.displayName}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String reportMessage({
    required String communityName,
    required bool created,
  }) {
    return created
        ? 'Installed $communityName from local packages'
        : 'Updated $communityName from local packages';
  }
}

class _LocalPackageLoaderDialog extends StatefulWidget {
  const _LocalPackageLoaderDialog({required this.onInstall});

  final String? Function({
    required String extensionPackagePath,
    required String initializationPackagePath,
  }) onInstall;

  @override
  State<_LocalPackageLoaderDialog> createState() =>
      _LocalPackageLoaderDialogState();
}

class _LocalPackageLoaderDialogState extends State<_LocalPackageLoaderDialog> {
  late final TextEditingController _extensionPathController;
  late final TextEditingController _initializationPathController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _extensionPathController = TextEditingController(
      text: '/emulator/Download/book-club.loom-extension.zip',
    );
    _initializationPathController = TextEditingController(
      text: '/emulator/Download/book-club.loom-init.zip',
    );
  }

  @override
  void dispose() {
    _extensionPathController.dispose();
    _initializationPathController.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.onInstall(
      extensionPackagePath: _extensionPathController.text,
      initializationPackagePath: _initializationPathController.text,
    );
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add local community'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Point to the extension package and initialization package in the emulator file system.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('extension-package-path-field'),
              controller: _extensionPathController,
              decoration: const InputDecoration(
                labelText: 'Extension package',
                helperText: '.loom-extension.zip',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('initialization-package-path-field'),
              controller: _initializationPathController,
              decoration: const InputDecoration(
                labelText: 'Initialization package',
                helperText: '.loom-init.zip',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                key: const ValueKey('local-loader-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('load-local-community-button'),
          onPressed: _submit,
          icon: const Icon(Icons.upload_file),
          label: const Text('Validate and install'),
        ),
      ],
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState({required this.onAddCommunity});

  final VoidCallback onAddCommunity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'No communities installed',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Use Add Community to load a local extension package and initialization package.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('empty-add-community-button'),
          onPressed: onAddCommunity,
          icon: const Icon(Icons.add),
          label: const Text('Add Community'),
        ),
      ],
    );
  }
}
