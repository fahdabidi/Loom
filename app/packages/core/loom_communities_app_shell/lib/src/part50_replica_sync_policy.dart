part of '../loom_communities_app_shell.dart';

/// The member's cumulative preference for refreshing offline replicas.
///
/// The enum order is intentional: every policy includes the behaviour of the
/// policy before it.
enum LoomReplicaSyncPolicy {
  communityOpen,
  appForeground,
  visibleCommunity,
  knownCommunitiesOnForeground;

  bool get refreshesOnAppForeground => index >= appForeground.index;
  bool get refreshesVisibleCommunityPeriodically =>
      index >= visibleCommunity.index;
  bool get refreshesKnownCommunitiesOnForeground =>
      index >= knownCommunitiesOnForeground.index;

  String get memberFacingTitle => switch (this) {
    communityOpen => 'Refresh only when I open a community',
    appForeground =>
      'Also refresh when I open the app — the community I was last in',
    visibleCommunity =>
      'Also keep the community I’m looking at up to date while it is open',
    knownCommunitiesOnForeground =>
      'Also keep my communities up to date in the background',
  };

  String get memberFacingDescription => switch (this) {
    communityOpen => 'Refreshes when you enter a community.',
    appForeground =>
      'Includes refreshing when you enter a community, plus the community you were last viewing when Loom returns to the foreground.',
    visibleCommunity =>
      'Includes foreground refreshes, plus periodic refreshes only for the community currently on screen.',
    knownCommunitiesOnForeground =>
      'Includes visible-community refreshes. Background execution is not available in this app: when you return to Loom, it refreshes the communities you have opened on this device. It cannot refresh while the app is closed.',
  };
}

/// Local storage for the app-level choice of one member.
///
/// A null value is meaningful: it means that the member has not chosen yet
/// and must receive [LoomReplicaSyncPolicy.communityOpen].
abstract interface class LoomReplicaSyncPolicyStore {
  Future<LoomReplicaSyncPolicy?> readForMember(String memberId);
  Future<void> writeForMember(String memberId, LoomReplicaSyncPolicy policy);
}

/// Device-local, secure persistence for replica sync choices.
final class LoomSecureReplicaSyncPolicyStore
    implements LoomReplicaSyncPolicyStore {
  LoomSecureReplicaSyncPolicyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyPrefix = 'loom.replica_sync_policy.v1.';
  final FlutterSecureStorage _storage;

  @override
  Future<LoomReplicaSyncPolicy?> readForMember(String memberId) async {
    _requireReplicaSyncMemberId(memberId);
    final encoded = await _storage.read(key: _keyFor(memberId));
    if (encoded == null) return null;
    for (final policy in LoomReplicaSyncPolicy.values) {
      if (policy.name == encoded) return policy;
    }
    throw StateError(
      'The saved replica sync policy for member "$memberId" is invalid.',
    );
  }

  @override
  Future<void> writeForMember(
    String memberId,
    LoomReplicaSyncPolicy policy,
  ) async {
    _requireReplicaSyncMemberId(memberId);
    await _storage.write(key: _keyFor(memberId), value: policy.name);
  }

  String _keyFor(String memberId) =>
      '$_keyPrefix${base64Url.encode(utf8.encode(memberId))}';
}

/// Deterministic local storage for tests and hosts that explicitly want an
/// in-memory app session.
final class LoomMemoryReplicaSyncPolicyStore
    implements LoomReplicaSyncPolicyStore {
  final Map<String, LoomReplicaSyncPolicy> _values =
      <String, LoomReplicaSyncPolicy>{};

  @override
  Future<LoomReplicaSyncPolicy?> readForMember(String memberId) async {
    _requireReplicaSyncMemberId(memberId);
    return _values[memberId];
  }

  @override
  Future<void> writeForMember(
    String memberId,
    LoomReplicaSyncPolicy policy,
  ) async {
    _requireReplicaSyncMemberId(memberId);
    _values[memberId] = policy;
  }
}

typedef LoomReplicaSyncAction =
    Future<void> Function({
      required String memberId,
      required String extensionId,
    });

/// Applies a member's sync policy while a session is active.
///
/// It owns only scheduling and explicit lifecycle decisions. The supplied
/// [refreshCommunity] action owns replica opening and the existing security
/// rules around read fallback and writes. Communities are registered after a
/// member successfully opens them, so the D fallback can refresh every known
/// joined community without a backend lookup.
final class LoomReplicaSyncPolicyController with WidgetsBindingObserver {
  LoomReplicaSyncPolicyController({
    required LoomReplicaSyncPolicyStore store,
    required LoomReplicaSyncAction refreshCommunity,
    this.visibleCommunityRefreshInterval = const Duration(minutes: 5),
  }) : _store = store,
       _refreshCommunity = refreshCommunity {
    if (visibleCommunityRefreshInterval <= Duration.zero) {
      throw ArgumentError.value(
        visibleCommunityRefreshInterval,
        'visibleCommunityRefreshInterval',
        'must be greater than zero',
      );
    }
  }

  final LoomReplicaSyncPolicyStore _store;
  final LoomReplicaSyncAction _refreshCommunity;
  final Duration visibleCommunityRefreshInterval;

  final Map<String, Set<String>> _knownCommunitiesByMember =
      <String, Set<String>>{};
  Timer? _visibleCommunityTimer;
  String? _activeMemberId;
  String? _visibleCommunityId;
  int _sessionRevision = 0;
  bool _observingLifecycle = false;
  bool _disposed = false;

  String? get activeMemberId => _activeMemberId;
  String? get visibleCommunityId => _visibleCommunityId;

  Future<LoomReplicaSyncPolicy> policyFor(String memberId) async {
    _requireReplicaSyncMemberId(memberId);
    return await _store.readForMember(memberId) ??
        LoomReplicaSyncPolicy.communityOpen;
  }

  /// Records a successfully entered, visible community and immediately
  /// applies the selected policy without waiting for an app restart.
  Future<void> activateCommunity({
    required String memberId,
    required String extensionId,
  }) async {
    _ensureUsable();
    _requireReplicaSyncMemberId(memberId);
    _requireReplicaSyncExtensionId(extensionId);
    _ensureLifecycleObserver();
    _sessionRevision += 1;
    final revision = _sessionRevision;
    _visibleCommunityTimer?.cancel();
    _visibleCommunityTimer = null;
    _activeMemberId = memberId;
    _visibleCommunityId = extensionId;
    (_knownCommunitiesByMember[memberId] ??= <String>{}).add(extensionId);

    final policy = await policyFor(memberId);
    if (!_matchesActiveSession(
      revision: revision,
      memberId: memberId,
      extensionId: extensionId,
    )) {
      return;
    }
    _startVisibleCommunityTimerIfNeeded(policy, revision: revision);
  }

  /// Stops C/D polling when a community is no longer the visible route.
  void deactivateCommunity({
    required String memberId,
    required String extensionId,
  }) {
    if (_activeMemberId != memberId || _visibleCommunityId != extensionId) {
      return;
    }
    _sessionRevision += 1;
    _visibleCommunityTimer?.cancel();
    _visibleCommunityTimer = null;
    _visibleCommunityId = null;
  }

  /// Stores a member's choice and reschedules an active session immediately.
  Future<void> setPolicy({
    required String memberId,
    required LoomReplicaSyncPolicy policy,
  }) async {
    _ensureUsable();
    _requireReplicaSyncMemberId(memberId);
    await _store.writeForMember(memberId, policy);
    if (_activeMemberId != memberId || _visibleCommunityId == null) return;

    final revision = ++_sessionRevision;
    _visibleCommunityTimer?.cancel();
    _visibleCommunityTimer = null;
    _startVisibleCommunityTimerIfNeeded(policy, revision: revision);
  }

  /// Runs the policy's foreground action. D deliberately refreshes every
  /// known community; it does not imply platform work while the app is closed.
  Future<void> onAppForeground() async {
    final memberId = _activeMemberId;
    final visibleCommunityId = _visibleCommunityId;
    if (memberId == null || visibleCommunityId == null || _disposed) return;
    final revision = _sessionRevision;
    final policy = await policyFor(memberId);
    if (!_matchesActiveSession(
      revision: revision,
      memberId: memberId,
      extensionId: visibleCommunityId,
    )) {
      return;
    }
    if (!policy.refreshesOnAppForeground) return;

    final extensionIds = policy.refreshesKnownCommunitiesOnForeground
        ? _knownCommunitiesForForeground(memberId, visibleCommunityId)
        : <String>[visibleCommunityId];
    for (final extensionId in extensionIds) {
      if (!_matchesActiveSession(
        revision: revision,
        memberId: memberId,
        extensionId: visibleCommunityId,
      )) {
        return;
      }
      await _refreshCommunity(memberId: memberId, extensionId: extensionId);
    }
  }

  /// Ends the app-level scheduling session. This is intentionally independent
  /// from a route's disposal: credentials, not a screen, define its lifetime.
  Future<void> endSession({String? memberId}) async {
    if (memberId != null && memberId != _activeMemberId) return;
    _sessionRevision += 1;
    _visibleCommunityTimer?.cancel();
    _visibleCommunityTimer = null;
    _activeMemberId = null;
    _visibleCommunityId = null;
  }

  @visibleForTesting
  Future<void> runVisibleCommunityRefreshForTesting() =>
      _runVisibleCommunityRefresh(_sessionRevision);

  @visibleForTesting
  bool get isVisibleCommunityPolling => _visibleCommunityTimer != null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onAppForeground());
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sessionRevision += 1;
    _visibleCommunityTimer?.cancel();
    _visibleCommunityTimer = null;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
  }

  List<String> _knownCommunitiesForForeground(
    String memberId,
    String visibleCommunityId,
  ) {
    final known = _knownCommunitiesByMember[memberId] ?? const <String>{};
    // Keep the visible community last. The single-active-replica coordinator
    // therefore finishes on the community whose surface may immediately read.
    final backgroundCommunities =
        known.where((id) => id != visibleCommunityId).toList()..sort();
    return <String>[...backgroundCommunities, visibleCommunityId];
  }

  void _startVisibleCommunityTimerIfNeeded(
    LoomReplicaSyncPolicy policy, {
    required int revision,
  }) {
    if (!policy.refreshesVisibleCommunityPeriodically) return;
    _visibleCommunityTimer = Timer.periodic(
      visibleCommunityRefreshInterval,
      (_) => unawaited(_runVisibleCommunityRefresh(revision)),
    );
  }

  Future<void> _runVisibleCommunityRefresh(int revision) async {
    final memberId = _activeMemberId;
    final extensionId = _visibleCommunityId;
    if (memberId == null || extensionId == null || _disposed) return;
    final policy = await policyFor(memberId);
    if (!policy.refreshesVisibleCommunityPeriodically ||
        !_matchesActiveSession(
          revision: revision,
          memberId: memberId,
          extensionId: extensionId,
        )) {
      return;
    }
    await _refreshCommunity(memberId: memberId, extensionId: extensionId);
  }

  bool _matchesActiveSession({
    required int revision,
    required String memberId,
    required String extensionId,
  }) =>
      !_disposed &&
      _sessionRevision == revision &&
      _activeMemberId == memberId &&
      _visibleCommunityId == extensionId;

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError(
        'This replica sync policy controller has been disposed.',
      );
    }
  }
}

LoomReplicaSyncPolicyController _loomReplicaSyncPolicyController =
    LoomReplicaSyncPolicyController(
      // A host opts into device persistence at startup. Keeping the library
      // default in-memory makes an embedded/test host explicit about platform
      // storage instead of quietly attempting a plugin call it did not set up.
      store: LoomMemoryReplicaSyncPolicyStore(),
      refreshCommunity: _refreshReplicaSyncCommunity,
    );

LoomReplicaSyncPolicyController get loomReplicaSyncPolicyController =>
    _loomReplicaSyncPolicyController;

/// Enables durable, device-local app settings for the production host.
void configureLoomReplicaSyncPolicyPersistenceForProduction({
  FlutterSecureStorage? storage,
}) {
  _loomReplicaSyncPolicyController.dispose();
  _loomReplicaSyncPolicyController = LoomReplicaSyncPolicyController(
    store: LoomSecureReplicaSyncPolicyStore(storage: storage),
    refreshCommunity: _refreshReplicaSyncCommunity,
  );
}

Future<void> _refreshReplicaSyncCommunity({
  required String memberId,
  required String extensionId,
}) async {
  final opened = await openOfflineReplicaForExtensionId(
    extensionId: extensionId,
    fanId: memberId,
  );
  if (!opened) return;
  // [open] is the server-fed synchronization. It also leaves the configured
  // one-active-replica coordinator on this member/community pair.
}

@visibleForTesting
void overrideLoomReplicaSyncPolicyControllerForTesting(
  LoomReplicaSyncPolicyController controller,
) {
  _loomReplicaSyncPolicyController.dispose();
  _loomReplicaSyncPolicyController = controller;
}

@visibleForTesting
void resetLoomReplicaSyncPolicyControllerForTesting() {
  _loomReplicaSyncPolicyController.dispose();
  _loomReplicaSyncPolicyController = LoomReplicaSyncPolicyController(
    store: LoomMemoryReplicaSyncPolicyStore(),
    refreshCommunity: _refreshReplicaSyncCommunity,
  );
}

Future<void> endLoomReplicaSyncSession({String? memberId}) =>
    _loomReplicaSyncPolicyController.endSession(memberId: memberId);

void _requireReplicaSyncMemberId(String memberId) {
  if (memberId.trim().isNotEmpty) return;
  throw ArgumentError.value(memberId, 'memberId', 'must not be empty');
}

void _requireReplicaSyncExtensionId(String extensionId) {
  if (extensionId.trim().isNotEmpty) return;
  throw ArgumentError.value(extensionId, 'extensionId', 'must not be empty');
}

/// App-level settings for the logged-in member's replica synchronization.
class LoomReplicaSyncSettingsScreen extends StatefulWidget {
  const LoomReplicaSyncSettingsScreen({
    super.key,
    required this.memberId,
    this.controller,
  });

  final String memberId;
  final LoomReplicaSyncPolicyController? controller;

  @override
  State<LoomReplicaSyncSettingsScreen> createState() =>
      _LoomReplicaSyncSettingsScreenState();
}

class _LoomReplicaSyncSettingsScreenState
    extends State<LoomReplicaSyncSettingsScreen> {
  LoomReplicaSyncPolicy? _selectedPolicy;
  Object? _loadError;
  bool _saving = false;

  LoomReplicaSyncPolicyController get _controller =>
      widget.controller ?? loomReplicaSyncPolicyController;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final policy = await _controller.policyFor(widget.memberId);
      if (mounted) setState(() => _selectedPolicy = policy);
    } on Object catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _select(LoomReplicaSyncPolicy policy) async {
    if (_saving || policy == _selectedPolicy) return;
    setState(() => _saving = true);
    try {
      await _controller.setPolicy(memberId: widget.memberId, policy: policy);
      if (mounted) setState(() => _selectedPolicy = policy);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update sync settings: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _loadError;
    return Scaffold(
      appBar: AppBar(title: const Text('Sync settings')),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load sync settings: $error'),
              ),
            )
          : _selectedPolicy == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              key: const ValueKey('replica-sync-settings-list'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose how often Loom refreshes saved community data.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Each choice includes everything in the choices above it.',
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<LoomReplicaSyncPolicy>(
                      groupValue: _selectedPolicy,
                      onChanged: (value) {
                        if (!_saving && value != null) {
                          unawaited(_select(value));
                        }
                      },
                      child: Column(
                        children: [
                          for (final policy in LoomReplicaSyncPolicy.values)
                            Card(
                              child: RadioListTile<LoomReplicaSyncPolicy>(
                                key: ValueKey(
                                  'replica-sync-policy-${policy.name}',
                                ),
                                value: policy,
                                enabled: !_saving,
                                title: Text(policy.memberFacingTitle),
                                subtitle: Text(policy.memberFacingDescription),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
