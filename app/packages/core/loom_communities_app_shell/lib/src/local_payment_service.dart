part of loom_communities_app_shell;

/// A structured amount expressed in minor currency units.
///
/// This deliberately has no display-string constructor.  Payment callers must
/// supply an integer amount and a currency code from their typed obligation.
final class LocalPaymentMoney {
  const LocalPaymentMoney({required this.amount, required this.currency});

  final int amount;
  final String currency;

  Map<String, Object> toJson() => <String, Object>{
    'amount': amount,
    'currency': currency,
  };

  @override
  bool operator ==(Object other) =>
      other is LocalPaymentMoney &&
      other.amount == amount &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}

/// The complete caller-controlled input for [LocalPaymentService.confirmPayment].
///
/// It intentionally has neither payment credentials nor an outcome field.
/// The service decides whether its simulation succeeds; this object only
/// identifies the payment obligation it is being asked to simulate.
final class ConfirmPaymentRequest {
  const ConfirmPaymentRequest({
    required this.attemptId,
    required this.communityId,
    required this.workflowInstanceId,
    required this.initiatingFanId,
    this.payerRef,
    required this.obligationRef,
    required this.amount,
  });

  final String attemptId;
  final String communityId;
  final String workflowInstanceId;
  final String initiatingFanId;
  final String? payerRef;
  final String obligationRef;
  final LocalPaymentMoney amount;

  Map<String, Object?> toJson() => <String, Object?>{
    'attemptId': attemptId,
    'communityId': communityId,
    'workflowInstanceId': workflowInstanceId,
    'initiatingFanId': initiatingFanId,
    'payerRef': payerRef,
    'obligationRef': obligationRef,
    'amount': amount.toJson(),
  };

  bool _isIdenticalTo(ConfirmPaymentRequest other) =>
      other.attemptId == attemptId &&
      other.communityId == communityId &&
      other.workflowInstanceId == workflowInstanceId &&
      other.initiatingFanId == initiatingFanId &&
      other.payerRef == payerRef &&
      other.obligationRef == obligationRef &&
      other.amount == amount;
}

/// A successfully persisted local payment simulation.
///
/// Its constructor is private so callers cannot manufacture a result, choose
/// an outcome, or provide values other than the contract's simulation markers.
final class SimulatedPaymentResult {
  SimulatedPaymentResult._({
    required this.attemptId,
    required this.confirmationId,
    required DateTime completedAt,
    required this.amount,
  }) : completedAt = completedAt.toUtc();

  static const executionModeLocalStub = 'local-stub';
  static const settlementStatusNotSettled = 'not-settled';

  final String attemptId;

  /// A simulation can only return a stored successful result.  Faults are
  /// represented by [LocalPaymentException] rather than a false success.
  String get outcome => 'succeeded';

  /// Constant simulation provenance; never an input or constructor value.
  String get executionMode => executionModeLocalStub;

  /// Constant settlement provenance; no money moved.
  String get settlementStatus => settlementStatusNotSettled;

  final String confirmationId;
  final DateTime completedAt;
  final LocalPaymentMoney amount;

  /// Successful results have no failure reason.  Faults do not return a
  /// [SimulatedPaymentResult] at all.
  String? get failureReason => null;

  Map<String, Object?> toJson() => <String, Object?>{
    'attemptId': attemptId,
    'outcome': outcome,
    'executionMode': executionMode,
    'settlementStatus': settlementStatus,
    'confirmationId': confirmationId,
    'completedAt': completedAt.toIso8601String(),
    'amount': amount.toJson(),
    'failureReason': failureReason,
  };
}

/// Base exception for an operation defined by the local payment contract.
sealed class LocalPaymentException implements Exception {
  const LocalPaymentException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// The request did not meet the contract's required preconditions (HTTP 400).
final class LocalPaymentValidationException extends LocalPaymentException {
  const LocalPaymentValidationException(String message) : super(message, 400);
}

/// An [attemptId] was reused with a different request body (HTTP 409).
final class LocalPaymentConflictException extends LocalPaymentException {
  const LocalPaymentConflictException()
    : super(
        'A payment attempt cannot be replayed with a different request body.',
        409,
      );
}

/// No simulation exists for the requested attempt (HTTP 404).
final class LocalPaymentNotFoundException extends LocalPaymentException {
  const LocalPaymentNotFoundException()
    : super('No simulated payment exists for this attempt.', 404);
}

/// The simulator failed before it could persist any result (HTTP 500).
final class LocalPaymentInternalException extends LocalPaymentException {
  const LocalPaymentInternalException()
    : super('The local payment simulation failed before it was stored.', 500);
}

/// A test-only hook for exercising the contract's internal-fault response.
///
/// It runs after validation and before any result is created or stored.  It
/// receives only the credential-free request type and has no access to a
/// result, outcome, settlement status, or execution mode.
typedef LocalPaymentFaultInjector =
    void Function(ConfirmPaymentRequest request);

/// In-process implementation of the Local Payment Service OpenAPI contract.
///
/// It records successful simulations only in this process.  It neither
/// accepts nor stores card, bank, credential, or caller-selected-outcome data.
final class LocalPaymentService {
  LocalPaymentService() : _faultInjector = null;

  @visibleForTesting
  LocalPaymentService.forTesting({LocalPaymentFaultInjector? faultInjector})
    : _faultInjector = faultInjector;

  final Map<String, SimulatedPaymentResult> _resultsByAttemptId =
      <String, SimulatedPaymentResult>{};
  final Set<String> _confirmationIds = <String>{};
  final LocalPaymentFaultInjector? _faultInjector;

  /// Simulates an authorized payment attempt.
  ///
  /// Replaying an identical request returns the original stored object.  A
  /// different request for the same [ConfirmPaymentRequest.attemptId] fails
  /// closed with [LocalPaymentConflictException].
  SimulatedPaymentResult confirmPayment(ConfirmPaymentRequest request) {
    final recorded = _resultsByAttemptId[request.attemptId];
    if (recorded != null) {
      final originalRequest = _requestByAttemptId[request.attemptId]!;
      if (originalRequest._isIdenticalTo(request)) return recorded;
      throw const LocalPaymentConflictException();
    }

    _validate(request);
    try {
      _faultInjector?.call(request);
      final result = SimulatedPaymentResult._(
        attemptId: request.attemptId,
        confirmationId: _newConfirmationId(),
        completedAt: DateTime.now(),
        amount: request.amount,
      );
      // This is the commit point: any failure before here leaves no result to
      // look like a successful payment.
      _resultsByAttemptId[request.attemptId] = result;
      _requestByAttemptId[request.attemptId] = request;
      return result;
    } on LocalPaymentException {
      rethrow;
    } on Object {
      throw const LocalPaymentInternalException();
    }
  }

  /// Returns the actual stored simulation for [attemptId], never an empty or
  /// synthesized success.
  SimulatedPaymentResult getSimulatedPayment(String attemptId) {
    final result = _resultsByAttemptId[attemptId];
    if (result == null) throw const LocalPaymentNotFoundException();
    return result;
  }

  /// Exposed solely so unit tests can prove an idempotent replay did not add a
  /// second stored result.  It is not an OpenAPI operation.
  @visibleForTesting
  int get storedAttemptCount => _resultsByAttemptId.length;

  final Map<String, ConfirmPaymentRequest> _requestByAttemptId =
      <String, ConfirmPaymentRequest>{};

  void _validate(ConfirmPaymentRequest request) {
    _requireText(request.attemptId, 'attemptId');
    _requireText(request.communityId, 'communityId');
    _requireText(request.workflowInstanceId, 'workflowInstanceId');
    _requireText(request.initiatingFanId, 'initiatingFanId');
    _requireText(request.obligationRef, 'obligationRef');
    final payerRef = request.payerRef;
    if (payerRef != null) _requireText(payerRef, 'payerRef');

    if (request.amount.amount <= 0) {
      throw const LocalPaymentValidationException(
        'amount must be a positive number of minor currency units.',
      );
    }
    if (!_iso4217CurrencyCodes.contains(request.amount.currency)) {
      throw const LocalPaymentValidationException(
        'currency must be a current ISO 4217 alphabetic code.',
      );
    }
  }

  void _requireText(String value, String field) {
    if (value.trim().isNotEmpty) return;
    throw LocalPaymentValidationException('$field must not be empty.');
  }

  String _newConfirmationId() {
    String candidate;
    do {
      candidate = 'SIMULATED-${_newUuidV4()}';
    } while (_confirmationIds.contains(candidate));
    _confirmationIds.add(candidate);
    return candidate;
  }
}

/// Snapshot of ISO 4217 List One (current currencies and funds).
///
/// The contract requires unknown currency rejection.  We validate the opaque
/// code only; minor-unit interpretation stays with the caller's obligation and
/// this service never parses a display amount.
const Set<String> _iso4217CurrencyCodes = <String>{
  'AED',
  'AFN',
  'ALL',
  'AMD',
  'AOA',
  'ARS',
  'AUD',
  'AWG',
  'AZN',
  'BAM',
  'BBD',
  'BDT',
  'BHD',
  'BIF',
  'BMD',
  'BND',
  'BOB',
  'BOV',
  'BRL',
  'BSD',
  'BTN',
  'BWP',
  'BYN',
  'BZD',
  'CAD',
  'CDF',
  'CHE',
  'CHF',
  'CHW',
  'CLF',
  'CLP',
  'CNY',
  'COP',
  'COU',
  'CRC',
  'CUP',
  'CVE',
  'CZK',
  'DJF',
  'DKK',
  'DOP',
  'DZD',
  'EGP',
  'ERN',
  'ETB',
  'EUR',
  'FJD',
  'FKP',
  'GBP',
  'GEL',
  'GHS',
  'GIP',
  'GMD',
  'GNF',
  'GTQ',
  'GYD',
  'HKD',
  'HNL',
  'HTG',
  'HUF',
  'IDR',
  'ILS',
  'INR',
  'IQD',
  'IRR',
  'ISK',
  'JMD',
  'JOD',
  'JPY',
  'KES',
  'KGS',
  'KHR',
  'KMF',
  'KPW',
  'KRW',
  'KWD',
  'KYD',
  'KZT',
  'LAK',
  'LBP',
  'LKR',
  'LRD',
  'LSL',
  'LYD',
  'MAD',
  'MDL',
  'MGA',
  'MKD',
  'MMK',
  'MNT',
  'MOP',
  'MRU',
  'MUR',
  'MVR',
  'MWK',
  'MXN',
  'MXV',
  'MYR',
  'MZN',
  'NAD',
  'NGN',
  'NIO',
  'NOK',
  'NPR',
  'NZD',
  'OMR',
  'PAB',
  'PEN',
  'PGK',
  'PHP',
  'PKR',
  'PLN',
  'PYG',
  'QAR',
  'RON',
  'RSD',
  'RUB',
  'RWF',
  'SAR',
  'SBD',
  'SCR',
  'SDG',
  'SEK',
  'SGD',
  'SHP',
  'SLE',
  'SOS',
  'SRD',
  'SSP',
  'STN',
  'SVC',
  'SYP',
  'SZL',
  'THB',
  'TJS',
  'TMT',
  'TND',
  'TOP',
  'TRY',
  'TTD',
  'TWD',
  'TZS',
  'UAH',
  'UGX',
  'USD',
  'USN',
  'UYI',
  'UYU',
  'UYW',
  'UZS',
  'VED',
  'VES',
  'VND',
  'VUV',
  'WST',
  'XAD',
  'XAF',
  'XAG',
  'XAU',
  'XBA',
  'XBB',
  'XBC',
  'XBD',
  'XCD',
  'XCG',
  'XDR',
  'XOF',
  'XPD',
  'XPF',
  'XPT',
  'XSU',
  'XTS',
  'XUA',
  'XXX',
  'YER',
  'ZAR',
  'ZMW',
  'ZWG',
};
