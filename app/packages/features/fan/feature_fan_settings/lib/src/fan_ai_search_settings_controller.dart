import 'package:flutter/foundation.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';

class FanAiSearchSettingsController extends ChangeNotifier {
  FanAiSearchSettingsController({
    FanVaultApi? vaultApi,
    this.passportId = 'passport_demo_fan',
  }) : _vaultApi = vaultApi ?? resolveFanVaultApi();

  final FanVaultApi _vaultApi;
  final String passportId;

  FanSearchAgentConfig? _config;
  List<ExternalSourceConnection> _sources = const [];
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;

  FanSearchAgentConfig? get config => _config;
  List<ExternalSourceConnection> get sources => _sources;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _config = await _vaultApi.getSearchAgentConfig(passportId);
      _sources = await _vaultApi.getExternalSourceConnections(passportId);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> connectAgent({
    required AiSearchProvider provider,
    required String endpoint,
  }) async {
    await _saveConfig(
      provider: provider,
      mcpEndpoint: endpoint.isEmpty ? 'mcp://demo-agent/search' : endpoint,
      connected: true,
    );
  }

  Future<void> disconnectAgent() async {
    final current = _requireConfig();
    await _saveConfig(
      provider: current.provider,
      mcpEndpoint: current.mcpEndpoint,
      connected: false,
    );
  }

  Future<void> setPreferCreators(bool value) async {
    final current = _requireConfig();
    await _saveConfig(
      provider: current.provider,
      mcpEndpoint: current.mcpEndpoint,
      connected: current.connected,
      preferCreators: value,
    );
  }

  Future<void> setExternalSourcesEnabled(bool value) async {
    final current = _requireConfig();
    await _saveConfig(
      provider: current.provider,
      mcpEndpoint: current.mcpEndpoint,
      connected: current.connected,
      externalSourcesEnabled: value,
    );
  }

  Future<void> setSourceConnected({
    required ExternalSourceType sourceType,
    required bool connected,
  }) async {
    _saving = true;
    notifyListeners();
    try {
      final displayName = _sources
          .firstWhere((source) => source.sourceType == sourceType)
          .displayName;
      final updated = await _vaultApi.putExternalSourceConnection(
        passportId: passportId,
        sourceType: sourceType,
        connected: connected,
        displayName: displayName,
        idempotencyKey:
            'settings-source-${sourceType.name}-$connected-${DateTime.now().microsecondsSinceEpoch}',
      );
      _sources = [
        for (final source in _sources)
          source.sourceType == updated.sourceType ? updated : source,
      ];
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> _saveConfig({
    required AiSearchProvider provider,
    required String mcpEndpoint,
    required bool connected,
    bool? preferCreators,
    bool? externalSourcesEnabled,
  }) async {
    final current = _requireConfig();
    _saving = true;
    notifyListeners();
    try {
      _config = await _vaultApi.putSearchAgentConfig(
        passportId: passportId,
        provider: provider,
        mcpEndpoint: mcpEndpoint,
        connected: connected,
        preferCreators: preferCreators ?? current.preferCreators,
        externalSourcesEnabled:
            externalSourcesEnabled ?? current.externalSourcesEnabled,
        idempotencyKey:
            'settings-agent-$connected-${DateTime.now().microsecondsSinceEpoch}',
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  FanSearchAgentConfig _requireConfig() {
    final config = _config;
    if (config == null) {
      throw StateError('Search agent settings have not loaded.');
    }
    return config;
  }
}
