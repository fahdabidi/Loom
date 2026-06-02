import 'package:flutter/material.dart';

import '../../tokens/spacing.dart';

enum AgentProviderOption { claude, openAi, gemini, custom }

extension AgentProviderOptionLabel on AgentProviderOption {
  String get label {
    switch (this) {
      case AgentProviderOption.claude:
        return 'Claude';
      case AgentProviderOption.openAi:
        return 'OpenAI';
      case AgentProviderOption.gemini:
        return 'Gemini';
      case AgentProviderOption.custom:
        return 'Custom';
    }
  }
}

class AgentConnectResult {
  const AgentConnectResult({required this.provider, required this.endpoint});

  final AgentProviderOption provider;
  final String endpoint;
}

class AgentConnectSheet extends StatefulWidget {
  const AgentConnectSheet({
    this.initialProvider = AgentProviderOption.claude,
    this.initialEndpoint = 'mcp://demo-agent/search',
    super.key,
  });

  final AgentProviderOption initialProvider;
  final String initialEndpoint;

  @override
  State<AgentConnectSheet> createState() => _AgentConnectSheetState();
}

class _AgentConnectSheetState extends State<AgentConnectSheet> {
  late AgentProviderOption _provider;
  late final TextEditingController _endpointController;

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
    _endpointController = TextEditingController(text: widget.initialEndpoint);
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect search agent',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: LoomSpacing.sm),
            const Text(
              'This demo stores a simulated MCP endpoint. A production connection would use scoped OAuth or token exchange.',
            ),
            const SizedBox(height: LoomSpacing.md),
            SegmentedButton<AgentProviderOption>(
              segments: [
                for (final provider in AgentProviderOption.values)
                  ButtonSegment(
                    value: provider,
                    label: Text(provider.label),
                    icon: const Icon(Icons.smart_toy_outlined),
                  ),
              ],
              selected: {_provider},
              onSelectionChanged: (selection) {
                setState(() => _provider = selection.single);
              },
            ),
            const SizedBox(height: LoomSpacing.md),
            TextField(
              key: const ValueKey('p22_agent_endpoint_field'),
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'MCP endpoint',
                prefixIcon: Icon(Icons.hub_outlined),
              ),
            ),
            const SizedBox(height: LoomSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('p22_confirm_agent_connect_button'),
                onPressed: () {
                  Navigator.of(context).pop(
                    AgentConnectResult(
                      provider: _provider,
                      endpoint: _endpointController.text.trim(),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Connect agent'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
