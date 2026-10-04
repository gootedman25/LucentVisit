import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucentvisit/src/ai/ai_assistant_service.dart';
import 'package:lucentvisit/src/ai/ai_service_exception.dart';

void main() {
  Future<String?> testToken() async => 'test-app-check-token';

  test('explainer posts text and parses snake-case response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/explain');
      expect(request.headers['X-Firebase-AppCheck'], 'test-app-check-token');
      expect(jsonDecode(request.body), {'text': 'Example letter'});
      return http.Response(
        jsonEncode({
          'summary': 'Summary',
          'important_details': ['One'],
          'plain_terms': [
            {'term': 'CBC', 'meaning': 'A blood test'},
          ],
          'questions_to_ask': ['What next?'],
          'uncertainties': <String>[],
          'cautions': ['Not medical advice'],
        }),
        200,
      );
    });
    final service = AiAssistantService(
      client: client,
      baseUrl: 'https://example.test',
      appCheckTokenProvider: testToken,
    );
    final result = await service.explain('Example letter');
    expect(result.summary, 'Summary');
    expect(result.plainTerms.single.term, 'CBC');
    service.close();
  });

  test('draft creator parses organizer drafts', () async {
    final service = AiAssistantService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'drafts': [
              {
                'type': 'medication',
                'values': [
                  {'field': 'name', 'value': 'Example'},
                ],
                'evidence': 'Take Example.',
                'missing_required': ['dose'],
              },
            ],
          }),
          200,
        ),
      ),
      baseUrl: 'https://example.test',
      appCheckTokenProvider: testToken,
    );
    final drafts = await service.createDrafts('Take Example.');
    expect(drafts.single.values.single.value, 'Example');
    expect(drafts.single.missingRequired, ['dose']);
    service.close();
  });

  test('requires configuration and valid input', () async {
    final service = AiAssistantService(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: '',
      appCheckTokenProvider: testToken,
    );
    await expectLater(
      service.explain('text'),
      throwsA(isA<AiServiceException>()),
    );
    await expectLater(service.explain(' '), throwsA(isA<AiServiceException>()));
  });

  test('maps rate limits to a safe error', () async {
    final service = AiAssistantService(
      client: MockClient((_) async => http.Response('provider secret', 429)),
      baseUrl: 'https://example.test',
      appCheckTokenProvider: testToken,
    );
    await expectLater(
      service.explain('text'),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.type,
          'type',
          AiServiceErrorType.rateLimited,
        ),
      ),
    );
  });

  test('rejects requests when app verification has no token', () async {
    final service = AiAssistantService(
      client: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: 'https://example.test',
      appCheckTokenProvider: () async => null,
    );

    await expectLater(
      service.explain('text'),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.type,
          'type',
          AiServiceErrorType.configuration,
        ),
      ),
    );
    service.close();
  });
}
