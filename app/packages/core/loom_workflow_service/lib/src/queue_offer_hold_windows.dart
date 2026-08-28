import 'dart:convert';

const queueOfferHoldWindowsEnvironmentVariable =
    'LOOM_QUEUE_OFFER_HOLD_WINDOWS_SECONDS';

/// Parses the per-community duration used when offering the head of a queue.
///
/// Queueing itself does not need an offer duration, so an unset value leaves
/// every community unconfigured. The advance route then reports that precise
/// configuration error only when it needs to create an offer.
Map<String, Duration> parseQueueOfferHoldWindows(String? encoded) {
  if (encoded == null || encoded.trim().isEmpty) {
    return const <String, Duration>{};
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(encoded);
  } on FormatException {
    throw StateError(
      '$queueOfferHoldWindowsEnvironmentVariable must be a JSON object.',
    );
  }
  if (decoded is! Map<String, dynamic>) {
    throw StateError(
      '$queueOfferHoldWindowsEnvironmentVariable must be a JSON object.',
    );
  }

  final result = <String, Duration>{};
  for (final entry in decoded.entries) {
    final seconds = entry.value;
    if (entry.key.trim().isEmpty || seconds is! int || seconds <= 0) {
      throw StateError(
        'Each queue offer hold window must have a community id and positive '
        'integer seconds.',
      );
    }
    result[entry.key] = Duration(seconds: seconds);
  }
  return result;
}
