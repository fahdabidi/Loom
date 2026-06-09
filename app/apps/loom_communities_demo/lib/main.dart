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

  void _loadSampleLocalCommunity() {
    _backend.loadExtensionPackage(
      const LoomExtensionPackageSummary(
        extensionId: 'ext_book_club',
        displayName: 'Book Club',
        version: '1.0.0',
        permissions: ['content.publish'],
        assetIds: ['asset_card_book_club'],
      ),
    );
    _backend.importInitializationPackage(
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final communities = _backend.listCommunities();
    return Scaffold(
      appBar: AppBar(title: const Text('Loom Communities')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-community-button'),
        onPressed: _loadSampleLocalCommunity,
        icon: const Icon(Icons.add),
        label: const Text('Add Community'),
      ),
      body: communities.isEmpty
          ? const Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _EmptyCommunityState(
                    onAddCommunity: _loadSampleLocalCommunity,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: communities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final community = communities[index];
                return Card(
                  child: ListTile(
                    key: ValueKey('community-card-${community.communityId}'),
                    title: Text(community.displayName),
                    subtitle: Text(community.extensionId),
                    leading: CircleAvatar(
                      child: Text(community.displayName.substring(0, 1)),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${community.displayName}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
