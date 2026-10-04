enum AiServiceErrorType {
    configuration,
    invalidInput,
    rateLimited,
    timeout,
    unavailable,
    invalidResponse,
    network,
}

class AiServiceException implements Exception {
    const AiServiceException({
        required this.type,
        required this.message,
        this.statusCode,
    });

    finaal AiServiceErrorType type;
    final String message;
    final int? statusCode;

    @override
    String toString() => message;
}

