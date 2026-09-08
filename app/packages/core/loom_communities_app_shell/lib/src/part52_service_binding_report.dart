part of '../loom_communities_app_shell.dart';

/// The implementation mode actually selected at a service seam.
enum LoomServiceBindingMode { remote, local, unconfigured }

/// The most recent liveness observation for a resolved service binding.
enum LoomServiceCallOutcomeKind { success, failure, neverCalled, notApplicable }

/// A best-effort observation of a service call.
final class LoomServiceCallOutcome {
  const LoomServiceCallOutcome._({
    required this.kind,
    this.statusCode,
    this.errorKind,
    this.observedAt,
  });

  const LoomServiceCallOutcome.success({
    int? statusCode,
    required DateTime observedAt,
  }) : this._(
         kind: LoomServiceCallOutcomeKind.success,
         statusCode: statusCode,
         observedAt: observedAt,
       );

  const LoomServiceCallOutcome.failure({
    int? statusCode,
    String? errorKind,
    required DateTime observedAt,
  }) : this._(
         kind: LoomServiceCallOutcomeKind.failure,
         statusCode: statusCode,
         errorKind: errorKind,
         observedAt: observedAt,
       );

  const LoomServiceCallOutcome.neverCalled()
    : this._(kind: LoomServiceCallOutcomeKind.neverCalled);

  const LoomServiceCallOutcome.notApplicable()
    : this._(kind: LoomServiceCallOutcomeKind.notApplicable);

  final LoomServiceCallOutcomeKind kind;
  final int? statusCode;
  final String? errorKind;
  final DateTime? observedAt;

  bool get isFailure => kind == LoomServiceCallOutcomeKind.failure;
}

/// An immutable snapshot of one service's resolved implementation and liveness.
final class LoomServiceBinding {
  const LoomServiceBinding({
    required this.service,
    required this.mode,
    required this.endpoint,
    required this.scope,
    required this.resolvedAt,
    required this.lastCallOutcome,
  });

  final String service;
  final LoomServiceBindingMode mode;
  final Uri? endpoint;
  final String scope;
  final DateTime resolvedAt;
  final LoomServiceCallOutcome lastCallOutcome;

  bool get isRemoteBound =>
      mode == LoomServiceBindingMode.remote && endpoint != null;

  LoomServiceBinding copyWith({LoomServiceCallOutcome? lastCallOutcome}) =>
      LoomServiceBinding(
        service: service,
        mode: mode,
        endpoint: endpoint,
        scope: scope,
        resolvedAt: resolvedAt,
        lastCallOutcome: lastCallOutcome ?? this.lastCallOutcome,
      );
}

/// Stable service names used by the log line, registry, and widget keys.
abstract final class LoomServiceBindingNames {
  static const workflowEngine = 'workflow-engine';
  static const appAccess = 'app-access';
  static const fanPassport = 'fan-passport';
  static const authTokenEndpoint = 'auth-token-endpoint';
  static const offlineReplica = 'offline-replica';
  static const processScope = 'process';

  static const all = <String>[
    workflowEngine,
    appAccess,
    fanPassport,
    authTokenEndpoint,
    offlineReplica,
  ];

  static const communityScoped = <String>[
    workflowEngine,
    appAccess,
    fanPassport,
  ];

  static const healthChecked = <String>[
    workflowEngine,
    appAccess,
    fanPassport,
    authTokenEndpoint,
  ];
}

/// Signature used by remote transports to report only the call they made.
///
/// The callback is intentionally synchronous and optional. Implementations
/// must never await it or let a diagnostics failure alter a real request.
typedef LoomServiceCallOutcomeRecorder =
    void Function({required bool success, int? statusCode, String? errorKind});

/// The process-wide, read-safe report of actual service bindings.
///
/// Binding writes happen at implementation-selection seams, not when a URI is
/// merely configured. Call outcomes are updated independently by the request
/// paths. All mutation methods are deliberately void and best effort: a
/// diagnostic problem cannot change whether a production request succeeds.
final class LoomServiceBindingRegistry {
  LoomServiceBindingRegistry._();

  static final LoomServiceBindingRegistry instance =
      LoomServiceBindingRegistry._();

  final Map<String, LoomServiceBinding> _bindings =
      <String, LoomServiceBinding>{};
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Rebuilds listeners after a binding or liveness observation changes.
  ValueListenable<int> get changes => _revision;

  /// Returns a stable immutable snapshot of all recorded bindings.
  List<LoomServiceBinding> get bindings =>
      List<LoomServiceBinding>.unmodifiable(_bindings.values);

  /// Reads a recorded binding without exposing the registry's mutable map.
  LoomServiceBinding? find({required String service, required String scope}) =>
      _bindings[_key(service, scope)];

  /// Returns every row needed by the community diagnostics panel.
  ///
  /// Missing rows are synthetic unconfigured snapshots. They are intentionally
  /// visible to callers and are not inserted as if a seam had been checked.
  List<LoomServiceBinding> snapshotForCommunity(String communityScope) => [
    for (final service in LoomServiceBindingNames.all)
      find(
            service: service,
            scope: LoomServiceBindingNames.communityScoped.contains(service)
                ? communityScope
                : LoomServiceBindingNames.processScope,
          ) ??
          _unconfiguredSnapshot(
            service: service,
            scope: LoomServiceBindingNames.communityScoped.contains(service)
                ? communityScope
                : LoomServiceBindingNames.processScope,
          ),
  ];

  /// Records the implementation selected by a real seam.
  void recordBinding({
    required String service,
    required LoomServiceBindingMode mode,
    required Uri? endpoint,
    required String scope,
    DateTime? resolvedAt,
  }) {
    try {
      final at = (resolvedAt ?? DateTime.now()).toUtc();
      final binding = LoomServiceBinding(
        service: service,
        mode: mode,
        endpoint: mode == LoomServiceBindingMode.remote ? endpoint : null,
        scope: scope,
        resolvedAt: at,
        lastCallOutcome: mode == LoomServiceBindingMode.local
            ? const LoomServiceCallOutcome.notApplicable()
            : const LoomServiceCallOutcome.neverCalled(),
      );
      _bindings[_key(service, scope)] = binding;
      _publish(binding);
    } catch (_) {
      // Diagnostics are not allowed to become a request or startup failure.
    }
  }

  /// Records a successful response without changing the resolved mode.
  void recordCallSuccess({
    required String service,
    required String scope,
    int? statusCode,
    DateTime? observedAt,
  }) => _recordCall(
    service: service,
    scope: scope,
    outcome: LoomServiceCallOutcome.success(
      statusCode: statusCode,
      observedAt: (observedAt ?? DateTime.now()).toUtc(),
    ),
  );

  /// Records a failed response or transport error without changing the mode.
  void recordCallFailure({
    required String service,
    required String scope,
    int? statusCode,
    String? errorKind,
    DateTime? observedAt,
  }) => _recordCall(
    service: service,
    scope: scope,
    outcome: LoomServiceCallOutcome.failure(
      statusCode: statusCode,
      errorKind: _simpleToken(errorKind ?? 'unknown_error'),
      observedAt: (observedAt ?? DateTime.now()).toUtc(),
    ),
  );

  /// Restores the empty process state for a test isolate.
  @visibleForTesting
  void resetForTesting() {
    try {
      _bindings.clear();
      _publish(null);
    } catch (_) {
      // A broken diagnostic listener must not make test cleanup fail.
    }
  }

  /// Provides warning labels for the currently displayed community.
  List<String> warningLabelsForCommunity(String communityScope) {
    try {
      final rows = snapshotForCommunity(communityScope)
          .where(
            (binding) =>
                LoomServiceBindingNames.healthChecked.contains(binding.service),
          )
          .toList(growable: false);
      final labels = <String>[];
      for (final binding in rows) {
        if (binding.lastCallOutcome.isFailure) {
          final label = _failureWarningLabel(binding.lastCallOutcome);
          if (!labels.contains(label)) labels.add(label);
          continue;
        }
        if (binding.isRemoteBound) continue;
        final label = _warningLabelFor(binding);
        if (!labels.contains(label)) labels.add(label);
      }
      return List<String>.unmodifiable(labels);
    } catch (_) {
      return const ['SERVICE DIAGNOSTICS UNAVAILABLE'];
    }
  }

  String _warningLabelFor(LoomServiceBinding binding) {
    if (binding.mode == LoomServiceBindingMode.unconfigured ||
        (binding.mode == LoomServiceBindingMode.remote &&
            binding.endpoint == null)) {
      return switch (binding.service) {
        LoomServiceBindingNames.workflowEngine => 'ENGINE UNCONFIGURED',
        LoomServiceBindingNames.appAccess => 'AUTH UNCONFIGURED',
        LoomServiceBindingNames.fanPassport => 'PASSPORT UNCONFIGURED',
        LoomServiceBindingNames.authTokenEndpoint => 'AUTH TOKEN UNCONFIGURED',
        _ => 'SERVICE UNCONFIGURED',
      };
    }
    return switch (binding.service) {
      LoomServiceBindingNames.workflowEngine => 'LOCAL ENGINE',
      LoomServiceBindingNames.appAccess => 'LOCAL AUTH',
      LoomServiceBindingNames.fanPassport => 'LOCAL PASSPORT',
      LoomServiceBindingNames.authTokenEndpoint => 'LOCAL AUTH TOKEN',
      _ => 'SERVICE UNCONFIGURED',
    };
  }

  /// Classifies only evidence recorded for the failed call. In particular, an
  /// HTTP response proves that a service was reachable, and a missing bearer
  /// session proves that no request was sent; neither may be presented as a
  /// backend outage.
  String _failureWarningLabel(LoomServiceCallOutcome outcome) {
    final statusCode = outcome.statusCode;
    final errorKind = outcome.errorKind?.toLowerCase() ?? '';
    if (statusCode == 401 ||
        errorKind.contains('authentication_required') ||
        errorKind.contains('notloggedin') ||
        errorKind.contains('login_required') ||
        errorKind.contains('refreshtokenexpired')) {
      return 'SIGN-IN REQUIRED';
    }
    if (statusCode == 403 ||
        errorKind.contains('authorization') ||
        errorKind.contains('forbidden') ||
        errorKind.contains('access_denied') ||
        errorKind.contains('refused')) {
      return 'ACCESS REFUSED';
    }
    if (statusCode == null &&
        (errorKind == 'network_error' ||
            errorKind == 'transport_error' ||
            errorKind.contains('socketexception') ||
            errorKind.contains('clientexception') ||
            errorKind.contains('handshakeexception'))) {
      return 'BACKEND UNREACHABLE';
    }
    return 'SERVICE REQUEST FAILED';
  }

  void _recordCall({
    required String service,
    required String scope,
    required LoomServiceCallOutcome outcome,
  }) {
    try {
      var binding = _bindings[_key(service, scope)];
      if (binding == null) {
        binding = _unconfiguredSnapshot(service: service, scope: scope);
      }
      if (binding.mode == LoomServiceBindingMode.local) return;
      final updated = binding.copyWith(lastCallOutcome: outcome);
      _bindings[_key(service, scope)] = updated;
      _publish(updated);
    } catch (_) {
      // See recordBinding: diagnostics never own the request's failure path.
    }
  }

  void _publish(LoomServiceBinding? binding) {
    if (binding != null) {
      try {
        debugPrint(_logLine(binding));
      } catch (_) {}
    }
    try {
      _revision.value++;
    } catch (_) {}
  }

  String _logLine(LoomServiceBinding binding) {
    final outcome = binding.lastCallOutcome;
    final outcomeToken = switch (outcome.kind) {
      LoomServiceCallOutcomeKind.success => 'ok',
      LoomServiceCallOutcomeKind.failure => 'failure',
      LoomServiceCallOutcomeKind.neverCalled => 'never-called',
      LoomServiceCallOutcomeKind.notApplicable => 'n/a',
    };
    final status = outcome.statusCode?.toString() ?? '-';
    final error = outcome.errorKind == null
        ? '-'
        : _simpleToken(outcome.errorKind!);
    return 'LOOM_BINDING service=${_simpleToken(binding.service)} '
        'mode=${binding.mode.name} '
        'endpoint=${binding.endpoint?.toString() ?? '-'} '
        'scope=${_simpleToken(binding.scope)} '
        'outcome=$outcomeToken status=$status error=$error '
        'at=${(outcome.observedAt ?? binding.resolvedAt).toUtc().toIso8601String()}';
  }

  LoomServiceBinding _unconfiguredSnapshot({
    required String service,
    required String scope,
  }) => LoomServiceBinding(
    service: service,
    mode: LoomServiceBindingMode.unconfigured,
    endpoint: null,
    scope: scope,
    resolvedAt: DateTime.now().toUtc(),
    lastCallOutcome: const LoomServiceCallOutcome.neverCalled(),
  );

  static String _key(String service, String scope) => '$service\u0000$scope';

  static String _simpleToken(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._:/?&=%-]'), '_');
}

/// Public singleton access for hosts that prefer a top-level app-shell API.
LoomServiceBindingRegistry get loomServiceBindingRegistry =>
    LoomServiceBindingRegistry.instance;

@visibleForTesting
void resetLoomServiceBindingRegistryForTesting() =>
    loomServiceBindingRegistry.resetForTesting();

void _recordAuthTokenCallOutcome({
  required bool success,
  int? statusCode,
  String? errorKind,
}) {
  if (success) {
    loomServiceBindingRegistry.recordCallSuccess(
      service: LoomServiceBindingNames.authTokenEndpoint,
      scope: LoomServiceBindingNames.processScope,
      statusCode: statusCode,
    );
  } else {
    loomServiceBindingRegistry.recordCallFailure(
      service: LoomServiceBindingNames.authTokenEndpoint,
      scope: LoomServiceBindingNames.processScope,
      statusCode: statusCode,
      errorKind: errorKind,
    );
  }
}

void _recordWorkflowCallOutcome(
  String scope, {
  required bool success,
  int? statusCode,
  String? errorKind,
}) {
  if (success) {
    loomServiceBindingRegistry.recordCallSuccess(
      service: LoomServiceBindingNames.workflowEngine,
      scope: scope,
      statusCode: statusCode,
    );
  } else {
    loomServiceBindingRegistry.recordCallFailure(
      service: LoomServiceBindingNames.workflowEngine,
      scope: scope,
      statusCode: statusCode,
      errorKind: errorKind,
    );
  }
}

void _recordRemoteServiceCallOutcome({
  required String service,
  required String scope,
  required bool success,
  int? statusCode,
  String? errorKind,
}) {
  if (success) {
    loomServiceBindingRegistry.recordCallSuccess(
      service: service,
      scope: scope,
      statusCode: statusCode,
    );
  } else {
    loomServiceBindingRegistry.recordCallFailure(
      service: service,
      scope: scope,
      statusCode: statusCode,
      errorKind: errorKind,
    );
  }
}

/// A compact warning chip intended for persistent community chrome.
class LoomServiceBindingWarningBadge extends StatelessWidget {
  const LoomServiceBindingWarningBadge({
    super.key,
    required this.communityScope,
  });

  final String communityScope;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: loomServiceBindingRegistry.changes,
    builder: (context, _, child) {
      final labels = loomServiceBindingRegistry.warningLabelsForCommunity(
        communityScope,
      );
      if (labels.isEmpty) return const SizedBox.shrink();
      final hasTransportFailure = labels.contains('BACKEND UNREACHABLE');
      final badgeLabel = hasTransportFailure
          ? 'BACKEND UNREACHABLE'
          : labels.first;
      final scheme = Theme.of(context).colorScheme;
      return Semantics(
        container: true,
        liveRegion: true,
        label: labels.join(', '),
        child: Chip(
          key: const ValueKey('service-binding-warning-badge'),
          avatar: Icon(
            hasTransportFailure ? Icons.cloud_off : Icons.warning_amber_rounded,
            size: 18,
            color: hasTransportFailure
                ? scheme.onErrorContainer
                : scheme.onTertiaryContainer,
          ),
          backgroundColor: hasTransportFailure
              ? scheme.errorContainer
              : scheme.tertiaryContainer,
          label: Text(badgeLabel, overflow: TextOverflow.ellipsis),
          labelStyle: TextStyle(
            color: hasTransportFailure
                ? scheme.onErrorContainer
                : scheme.onTertiaryContainer,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );
    },
  );
}

/// The complete service report placed in the existing account dialog.
class LoomServiceBindingDiagnosticsPanel extends StatelessWidget {
  const LoomServiceBindingDiagnosticsPanel({
    super.key,
    required this.communityScope,
  });

  final String communityScope;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: loomServiceBindingRegistry.changes,
    builder: (context, _, child) {
      final rows = loomServiceBindingRegistry.snapshotForCommunity(
        communityScope,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Service binding diagnostics',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          for (final binding in rows) _LoomServiceBindingRow(binding: binding),
        ],
      );
    },
  );
}

class _LoomServiceBindingRow extends StatelessWidget {
  const _LoomServiceBindingRow({required this.binding});

  final LoomServiceBinding binding;

  @override
  Widget build(BuildContext context) {
    final outcome = binding.lastCallOutcome;
    final outcomeText = switch (outcome.kind) {
      LoomServiceCallOutcomeKind.success =>
        'success${outcome.statusCode == null ? '' : ' (${outcome.statusCode})'}',
      LoomServiceCallOutcomeKind.failure =>
        'failure${outcome.statusCode == null ? '' : ' (${outcome.statusCode})'}'
            '${outcome.errorKind == null ? '' : ' ${outcome.errorKind}'}',
      LoomServiceCallOutcomeKind.neverCalled => 'never-called',
      LoomServiceCallOutcomeKind.notApplicable => 'not-applicable',
    };
    final observedText = outcome.observedAt?.toUtc().toIso8601String() ?? '—';
    return Card(
      key: ValueKey('service-binding-row-${binding.service}'),
      margin: const EdgeInsets.only(top: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _serviceDisplayName(binding.service),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text('Mode: ${binding.mode.name}'),
            Text('Endpoint: ${binding.endpoint?.toString() ?? '-'}'),
            Text('Last call: $outcomeText'),
            Text('Observed: $observedText'),
          ],
        ),
      ),
    );
  }
}

String _serviceDisplayName(String service) => switch (service) {
  LoomServiceBindingNames.workflowEngine => 'Workflow engine',
  LoomServiceBindingNames.appAccess => 'App Access',
  LoomServiceBindingNames.fanPassport => 'Fan Passport',
  LoomServiceBindingNames.authTokenEndpoint => 'Auth / token endpoint',
  LoomServiceBindingNames.offlineReplica => 'Offline replica coordinator',
  _ => service,
};
