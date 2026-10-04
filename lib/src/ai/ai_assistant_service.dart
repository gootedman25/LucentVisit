import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_models.dart';
import 'ai_service_exception.dart';

class AiAssistantService {
  AiAssistantService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? const String.fromEnvironment('AI_SERVICE_BASE_URL');

  static const maximumInputLength = 12000;
  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  Future<AiExplanation> explain(String input) async =>
      AiExplanation.fromJson(await _post('/v1/explain', _validate(input)));

  Future<List<AiDraft>> createDrafts(String input) async {
    final json = await _post('/v1/drafts', _validate(input));
    final values = json['drafts'];
    if (values is! List) {
      throw const AiServiceException(
        type: AiServiceErrorType.invalidResponse,
        message: 'The AI service returned an invalid response.',
      );
    }
    try {
      return values.map((value) {
        if (value is! Map) throw const FormatException();
        return AiDraft.fromJson(
          value.map((key, value) => MapEntry(key.toString(), value)),
        );
      }).toList();
    } on FormatException {
      throw const AiServiceException(
        type: AiServiceErrorType.invalidResponse,
        message: 'The AI service returned an invalid response.',
      );
    }
  }

  String _validate(String input) {
    final text = input.trim();
    if (text.isEmpty || text.length > maximumInputLength) {
      throw const AiServiceException(
        type: AiServiceErrorType.invalidInput,
        message: 'Enter between 1 and 12,000 characters.',
      );
    }
    return text;
  }

  Future<Map<String, dynamic>> _post(String path, String text) async {
    final base = Uri.tryParse(_baseUrl.trim());
    if (base == null || !base.hasScheme || base.host.isEmpty) {
      throw const AiServiceException(
        type: AiServiceErrorType.configuration,
        message: 'The AI service has not been configured for this build.',
      );
    }
    final local =
        base.host == 'localhost' ||
        base.host == '127.0.0.1' ||
        base.host == '10.0.2.2';
    if (base.scheme != 'https' && !(local && base.scheme == 'http')) {
      throw const AiServiceException(
        type: AiServiceErrorType.configuration,
        message: 'The AI service URL must use HTTPS.',
      );
    }

    late http.Response response;
    try {
      response = await _client
          .post(
            base.resolve(path),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 35));
    } on TimeoutException {
      throw const AiServiceException(
        type: AiServiceErrorType.timeout,
        message: 'The AI service took too long. Please try again.',
      );
    } on http.ClientException {
      throw const AiServiceException(
        type: AiServiceErrorType.network,
        message: 'Could not reach the AI service. Check your connection.',
      );
    }

    if (response.statusCode == 429) {
      throw const AiServiceException(
        type: AiServiceErrorType.rateLimited,
        message: 'The AI service is busy. Please try again later.',
      );
    }
    if (response.statusCode != 200) {
      throw const AiServiceException(
        type: AiServiceErrorType.unavailable,
        message: 'The AI service is temporarily unavailable.',
      );
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const FormatException();
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } on FormatException {
      throw const AiServiceException(
        type: AiServiceErrorType.invalidResponse,
        message: 'The AI service returned an invalid response.',
      );
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
