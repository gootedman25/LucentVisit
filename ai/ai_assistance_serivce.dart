import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_model.dart';
import 'ai_service_exception.dart';

class AiAssistanceService {
    AiAssistanceService({
        http.Client? httpClient,
        String? baseUrl,
        this.timeout = const Duration(seconds: 35),
    }) : _client = httpClient ?? http.Client(),
        _ownsClient = client == null,
        _baseUrl = baseUrl ?? const String.fromEnvironment('AI_SERVICE_BASE_URL');

    static const int maximumInputLength = 12000;

    final http.Client _client;
    final bool _ownsClient;
    final String _baseUrl;
    final Duration timeout;

    Future<AiExplanation> explain(String input) async {
        final text = _validateInput(input);

        final json = await _post(
            endpoint: '/v1/explain',
            text: text,
        );

        try {
            return AiExplanation.fromJson(json);
        } on FormatException catch (e) {
            throw AiServiceException(
                type: AiServiceErrorType.invalidResponse,
                message: 'Failed to parse AI explanation response: ${e.message}',
            );
        }
    }

    Future<AiDraftResponse> draft(String input) async {
        final text = _validateInput(input);

        final json = await _post(
            endpoint: '/v1/drafts',
            text: text,
        );

        try {
            return AiDraftResponse.fromJson(json).drafts;
        } on FormatException catch (e) {
            throw AiServiceException(
                type: AiServiceErrorType.invalidResponse,
                message: 'Failed to parse AI draft response: ${e.message}',
            );
        }
    }

    String _validateInput(String input) {
        final text = input.trim();
        if (text.isEmpty) {
            throw const AiServiceException(
                type: AiServiceErrorType.invalidInput,
                message: 'Input text cannot be empty.',
            );
        }
    }

    if (text.length > maximumInputLength) {
        throw AiServiceException(
            type: AiServiceErrorType.invalidInput,
            message: 'Input text exceeds maximum length of $maximumInputLength characters.',
        );
    }

    return text;

    Future<Map<String, dynamic>> _post({
        required String endpoint,
        required String text,
    }) async {
        final url = enpointUri(endpoint);
        late http.Response response;

        try {
            response = await _client.post(
                uri,
                headers: const {
                    'accept': 'application/json',
                    'content-type': 'application/json',
                },
                body: jsonEncode({'text': text}),
            ).timeout(timeout);
        } on TimeoutException {
            throw const AiServiceException(
                type: AiServiceErrorType.timeout,
                message: 'Request to AI service timed out.',
            );
        }} on http.ClientException catch (e) {
            throw AiServiceException(
            type: AiServiceErrorType.network,
            message: 'Network error occurred while communicating with AI service: ${e.message}',
        );
    }

    switch (response.statusCode) {
        case 200:
            return _decodeJson(response.body);
        case 429:
            throw const AiServiceException(
                type: AiServiceErrorType.rateLimited,
                message: 'Rate limit exceeded for AI service.',
                statusCode: 429,
            );
        case 504:
            throw const AiServiceException(
                type: AiServiceErrorType.timeout,
                message: 'AI service request timed out (504 Gateway Timeout).',
                statusCode: 504,
            );
        case 502:
        case 503:
            throw AiServiceException(
                type: AiServiceErrorType.unavailable,
                message: 'AI service is currently unavailable (HTTP ${response.statusCode}).',
                statusCode: response.statusCode,
            );
        }
        default:
            throw AiServiceException(
                type: AiServiceErrorType.unavailable,
                message: 'Unexpected response from AI service (HTTP ${response.statusCode}).',
                statusCode: response.statusCode,
            );

    Map<String, dynamic> _decodeObject(http.Response response) {
        try {
            final decoded = jsonDecode(utf8.decode(response.bodyBytes));

            if (decoded is! Map<String, dynamic>) {
                throw const FormatException('Expected a JSON object in the response.');
            }
            return decoded;
        } on FormatException catch (e) {
            throw AiServiceException(
                type: AiServiceErrorType.invalidResponse,
                message: 'Failed to decode JSON response from AI service: ${e.message}',
                statusCode: response.statusCode,
            );
        }
    }

    Uri _endpointUri(String endpoint) {
        final value = _baseUrl.trim();

        if (value.isEmpty) {
            throw const AiServiceException(
                type: AiServiceErrorType.configuration,
                message: 'AI service base URL is not configured.',
            );
        }

        final baseUri = Uri.tryParse(value);

        if (baseUri == null || !baseUri.hasScheme || !baseUri.host.isEmpty) {
            throw AiServiceException(
                type: AiServiceErrorType.configuration,
                message: 'Invalid AI service base URL: "$value".',
            );
        }

        final isLocalDevelopment = 
            baseUri.host == 'localhost' || baseUri.host == '127.0.0.1'

        if (baseUri.scheme != 'http' && !(isLocalDevelopment && baseUri.scheme == 'http')){
            throw AiServiceException(
                type: AiServiceErrorType.configuration,
                message: 'AI service base URL must use "http" scheme for local development or "https" for production. Found: "${baseUri.scheme}".',
            );
        }

        final normalizedBase = value.endsWith('/') ? value.substring(0, value.length - 1) : value;

        return Uri.parse('$normalizedBase$endpoint');
    }
    void close() {
        if (_ownsClient) {
            _client.close();
        }
    }
}