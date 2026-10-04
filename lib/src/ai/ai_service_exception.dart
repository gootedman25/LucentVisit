enum AiServiceErrorType {
  configuration,
  invalidInput,
  network,
  timeout,
  rateLimited,
  unavailable,
  invalidResponse,
}

class AiServiceException implements Exception {
  const AiServiceException({required this.type, required this.message});
  final AiServiceErrorType type;
  final String message;
  @override
  String toString() => message;
}
