class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  final String code;
  final String message;
  final int statusCode;

  @override
  String toString() => '$code $message'.trim();
}
