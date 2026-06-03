import 'package:flutter/material.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_design_system/loom_design_system.dart';

import 'fan_ai_search_settings_controller.dart';

class FanAiSearchSettingsScreen extends StatefulWidget {
  const FanAiSearchSettingsScreen({
    required this.onBack,
    this.controller,
    super.key,
  });

  final VoidCallback onBack;
  final FanAiSearchSettingsController? controller;

  @override
  State<FanAiSearchSettingsScreen> createState() =>
      _FanAiSearchSettingsScreenState();
}

class _FanAiSearchSettingsScreenState extends State<FanAiSearchSettingsScreen> {
  late final FanAiSearchSettingsController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? FanAiSearchSettingsController();
    _ownsController = widget.controller == null;
    if (_ownsController) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.loading && _controller.config == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(
              title: 'Loading AI search settings',
              rows: 4,
            ),
          );
        }
        if (_controller.errorMessage != null && _controller.config == null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: LoomErrorState(
              title: 'Settings could not load',
              body: _controller.errorMessage!,
              onRetry: _controller.load,
            ),
          );
        }
        final config = _controller.config;
        if (config == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LoomEmptyState(
              icon: Icons.manage_search_rounded,
              title: 'No settings yet',
              body: 'Reset the demo or retry loading to restore defaults.',
            ),
          );
        }

        return ListView(
          key: const ValueKey('p22_fan_settings_screen'),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            const _SettingsHeader(),
            const SizedBox(height: 14),
            const DataDashboardRow(
              key: ValueKey('p22_query_egress_disclosure'),
              icon: Icons.privacy_tip_outlined,
              title: 'Your agent receives query context',
              subtitle:
                  'This demo simulates scoped MCP access. Production connectors would ask for explicit OAuth or token consent before sending query context to your chosen provider.',
            ),
            const SizedBox(height: 14),
            SettingsSection(
              title: 'AI search agent',
              subtitle:
                  'Connect a simulated MCP search agent that ranks results for you.',
              icon: Icons.smart_toy_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _providerLabel(config.provider),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    ConnectionStatusChip(connected: config.connected),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  config.mcpEndpoint.isEmpty
                      ? 'No MCP endpoint connected.'
                      : config.mcpEndpoint,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('p22_connect_agent_button'),
                        onPressed: _controller.saving
                            ? null
                            : () => _showConnectSheet(config),
                        icon: const Icon(Icons.hub_outlined),
                        label: Text(
                          config.connected
                              ? 'Reconnect agent'
                              : 'Connect agent',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.outlined(
                      key: const ValueKey('p22_disconnect_agent_button'),
                      tooltip: 'Disconnect agent',
                      onPressed: config.connected && !_controller.saving
                          ? _controller.disconnectAgent
                          : null,
                      icon: const Icon(Icons.link_off_rounded),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            SettingsSection(
              title: 'Search defaults',
              subtitle:
                  'Creator preference is a fan choice and never a paid boost.',
              icon: Icons.tune_rounded,
              children: [
                SettingsToggleRow(
                  key: const ValueKey('p22_prefer_creators_toggle'),
                  title: 'Prefer creator content',
                  subtitle:
                      'When matches are equal, rank creator-owned content first.',
                  icon: Icons.video_library_rounded,
                  value: config.preferCreators,
                  onChanged: _controller.saving
                      ? (_) {}
                      : _controller.setPreferCreators,
                ),
                SettingsToggleRow(
                  key: const ValueKey('p22_external_sources_toggle'),
                  title: 'Include external sources',
                  subtitle:
                      'Allow your connected agent to use compliant public external references.',
                  icon: Icons.public_rounded,
                  value: config.externalSourcesEnabled,
                  onChanged: _controller.saving
                      ? (_) {}
                      : _controller.setExternalSourcesEnabled,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SettingsSection(
              title: 'External sources',
              subtitle:
                  'YouTube can be simulated now; other sources are modeled for future connectors.',
              icon: Icons.travel_explore_rounded,
              children: [
                for (final source in _controller.sources)
                  ConnectedServiceRow(
                    key: ValueKey('p22_source_${source.sourceType.name}'),
                    title: source.displayName,
                    subtitle: _sourceSubtitle(source.sourceType),
                    icon: _sourceIcon(source.sourceType),
                    connected: source.connected,
                    onChanged: config.externalSourcesEnabled
                        ? (value) => _controller.setSourceConnected(
                            sourceType: source.sourceType,
                            connected: value,
                          )
                        : (_) {},
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConnectSheet(FanSearchAgentConfig config) async {
    final result = await showModalBottomSheet<AgentConnectResult>(
      context: context,
      showDragHandle: true,
      builder: (_) => AgentConnectSheet(
        initialProvider: _agentProviderOption(config.provider),
        initialEndpoint: config.mcpEndpoint.isEmpty
            ? 'mcp://demo-agent/search'
            : config.mcpEndpoint,
      ),
    );
    if (result == null) {
      return;
    }
    await _controller.connectAgent(
      provider: _apiProvider(result.provider),
      endpoint: result.endpoint,
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'AI search settings',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

String _providerLabel(AiSearchProvider provider) {
  switch (provider) {
    case AiSearchProvider.anthropicClaude:
      return 'Claude via MCP';
    case AiSearchProvider.openAi:
      return 'OpenAI via MCP';
    case AiSearchProvider.googleGemini:
      return 'Gemini via MCP';
    case AiSearchProvider.custom:
      return 'Custom agent';
  }
}

AgentProviderOption _agentProviderOption(AiSearchProvider provider) {
  switch (provider) {
    case AiSearchProvider.openAi:
      return AgentProviderOption.openAi;
    case AiSearchProvider.googleGemini:
      return AgentProviderOption.gemini;
    case AiSearchProvider.custom:
      return AgentProviderOption.custom;
    case AiSearchProvider.anthropicClaude:
      return AgentProviderOption.claude;
  }
}

AiSearchProvider _apiProvider(AgentProviderOption option) {
  switch (option) {
    case AgentProviderOption.openAi:
      return AiSearchProvider.openAi;
    case AgentProviderOption.gemini:
      return AiSearchProvider.googleGemini;
    case AgentProviderOption.custom:
      return AiSearchProvider.custom;
    case AgentProviderOption.claude:
      return AiSearchProvider.anthropicClaude;
  }
}

String _sourceSubtitle(ExternalSourceType sourceType) {
  switch (sourceType) {
    case ExternalSourceType.youtube:
      return 'Simulated connection; Phase 24 uses the official in-app player.';
    case ExternalSourceType.twitch:
      return 'Modeled now, full Twitch connector later.';
    case ExternalSourceType.discord:
      return 'Modeled now for community links.';
    case ExternalSourceType.blog:
      return 'Modeled now for creator-owned public posts.';
    case ExternalSourceType.webpage:
      return 'Modeled now for general public web references.';
  }
}

IconData _sourceIcon(ExternalSourceType sourceType) {
  switch (sourceType) {
    case ExternalSourceType.youtube:
      return Icons.play_circle_outline;
    case ExternalSourceType.twitch:
      return Icons.live_tv_rounded;
    case ExternalSourceType.discord:
      return Icons.forum_outlined;
    case ExternalSourceType.blog:
      return Icons.article_outlined;
    case ExternalSourceType.webpage:
      return Icons.public_rounded;
  }
}
