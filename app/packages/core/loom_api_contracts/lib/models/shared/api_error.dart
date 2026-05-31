class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.correlationId,
  });

  final String code;
  final String message;
  final String? correlationId;

  @override
  String toString() => 'ApiError($code): $message';
}
