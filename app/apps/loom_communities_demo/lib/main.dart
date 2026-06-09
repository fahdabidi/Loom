import 'package:flutter/material.dart';

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

class LoomCommunitiesHome extends StatelessWidget {
  const LoomCommunitiesHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loom Communities')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: _EmptyCommunityState(),
          ),
        ),
      ),
    );
  }
}

class _EmptyCommunityState extends StatelessWidget {
  const _EmptyCommunityState();

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
          onPressed: null,
          icon: const Icon(Icons.add),
          label: const Text('Add Community'),
        ),
      ],
    );
  }
}
