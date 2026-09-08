import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

void main() {
  group('LocalPaymentService', () {
    test('records a clearly marked successful simulation', () {
      final result = LocalPaymentService().confirmPayment(_request());

      expect(result.outcome, 'succeeded');
      expect(result.executionMode, 'local-stub');
      expect(result.settlementStatus, 'not-settled');
      expect(result.confirmationId, matches(RegExp(r'^SIMULATED-')));
      expect(result.failureReason, isNull);
    });

    test('accepts only the typed contract request at its two operations', () {
      final service = LocalPaymentService();

      // These assignments are compile-time signature checks.  Neither
      // operation accepts execution mode, settlement status, or an outcome.
      final SimulatedPaymentResult Function(ConfirmPaymentRequest) confirm =
          service.confirmPayment;
      final SimulatedPaymentResult Function(String) get =
          service.getSimulatedPayment;
      final request = _request();

      expect(confirm(request).executionMode, 'local-stub');
      expect(get(request.attemptId).settlementStatus, 'not-settled');
      expect(
        request.toJson().keys,
        unorderedEquals(<String>[
          'attemptId',
          'communityId',
          'workflowInstanceId',
          'initiatingFanId',
          'payerRef',
          'obligationRef',
          'amount',
        ]),
      );
    });

    test('replays an identical request as the original stored result', () {
      final service = LocalPaymentService();
      final request = _request(attemptId: 'attempt-replay');

      final original = service.confirmPayment(request);
      final replay = service.confirmPayment(request);

      expect(identical(replay, original), isTrue);
      expect(jsonEncode(replay.toJson()), jsonEncode(original.toJson()));
      expect(service.storedAttemptCount, 1);
    });

    test('rejects a changed replay and preserves the original attempt', () {
      final service = LocalPaymentService();
      final original = service.confirmPayment(
        _request(attemptId: 'attempt-conflict'),
      );

      expect(
        () => service.confirmPayment(
          _request(attemptId: 'attempt-conflict', amount: 2450),
        ),
        throwsA(
          isA<LocalPaymentConflictException>().having(
            (error) => error.statusCode,
            'statusCode',
            409,
          ),
        ),
      );

      final stored = service.getSimulatedPayment('attempt-conflict');
      expect(jsonEncode(stored.toJson()), jsonEncode(original.toJson()));
      expect(service.storedAttemptCount, 1);
    });

    test('stores a separate result for every distinct attempt id', () {
      final service = LocalPaymentService();

      final first = service.confirmPayment(_request(attemptId: 'attempt-one'));
      final second = service.confirmPayment(_request(attemptId: 'attempt-two'));

      expect(second.confirmationId, isNot(first.confirmationId));
      expect(service.storedAttemptCount, 2);
      expect(service.getSimulatedPayment(first.attemptId), same(first));
      expect(service.getSimulatedPayment(second.attemptId), same(second));
    });

    test('round-trips a returned confirmation to its stored result', () {
      final service = LocalPaymentService();
      final confirmed = service.confirmPayment(
        _request(attemptId: 'attempt-round-trip'),
      );

      final stored = service.getSimulatedPayment(confirmed.attemptId);

      expect(stored.confirmationId, confirmed.confirmationId);
      expect(jsonEncode(stored.toJson()), jsonEncode(confirmed.toJson()));
    });

    test('does not synthesize a success for an unknown attempt id', () {
      final service = LocalPaymentService();

      expect(
        () => service.getSimulatedPayment('not-recorded'),
        throwsA(
          isA<LocalPaymentNotFoundException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      expect(service.storedAttemptCount, 0);
    });

    for (final invalidCase in <({String name, LocalPaymentMoney amount})>[
      (
        name: 'zero amount',
        amount: const LocalPaymentMoney(amount: 0, currency: 'USD'),
      ),
      (
        name: 'negative amount',
        amount: const LocalPaymentMoney(amount: -1, currency: 'USD'),
      ),
      (
        name: 'unknown currency',
        amount: const LocalPaymentMoney(amount: 1200, currency: 'ZZZ'),
      ),
    ]) {
      test('rejects ${invalidCase.name} before a result is stored', () {
        final service = LocalPaymentService();
        final request = _request(
          attemptId: 'attempt-invalid-${invalidCase.name}',
          money: invalidCase.amount,
        );

        expect(
          () => service.confirmPayment(request),
          throwsA(
            isA<LocalPaymentValidationException>().having(
              (error) => error.statusCode,
              'statusCode',
              400,
            ),
          ),
        );
        expect(service.storedAttemptCount, 0);
        expect(
          () => service.getSimulatedPayment(request.attemptId),
          throwsA(isA<LocalPaymentNotFoundException>()),
        );
      });
    }

    test('fails closed when the simulation has an internal fault', () {
      final service = LocalPaymentService.forTesting(
        faultInjector: (_) => throw StateError('simulated storage fault'),
      );
      final request = _request(attemptId: 'attempt-internal-fault');

      expect(
        () => service.confirmPayment(request),
        throwsA(
          isA<LocalPaymentInternalException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(service.storedAttemptCount, 0);
      expect(
        () => service.getSimulatedPayment(request.attemptId),
        throwsA(isA<LocalPaymentNotFoundException>()),
      );
    });
  });
}

ConfirmPaymentRequest _request({
  String attemptId = 'attempt-default',
  int amount = 1250,
  LocalPaymentMoney? money,
}) {
  return ConfirmPaymentRequest(
    attemptId: attemptId,
    communityId: 'community_riverside_youth_soccer',
    workflowInstanceId: 'registration-42',
    initiatingFanId: 'fan-ada',
    payerRef: 'household-ada',
    obligationRef: 'registration-fee-2026',
    amount: money ?? LocalPaymentMoney(amount: amount, currency: 'USD'),
  );
}
