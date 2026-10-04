import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lucentvisit/src/ai/ai_assistant_service.dart';
import 'package:lucentvisit/src/ai/ai_models.dart';
import 'package:lucentvisit/src/ai/ai_service_exception.dart';

void main() {
  group('AiAssistantService.explain', () {
    test('sends text and parses an explanation', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://example.run.app/v1/explain',
        );
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');

        final requestBody =
            jsonDecode(request.body) as Map<String, dynamic>;

        expect(requestBody, {
          'text': 'Example medical letter',
        });

        return http.Response(
          jsonEncode({
            'summary': 'A simple summary.',
            'important_details': ['Important detail'],
            'plain_terms': [
              {
                'term': 'Term',
                'meaning': 'Simple meaning',
              },
            ],
            'questions_to_ask': ['What happens next?'],
            'uncertainties': ['The date is unclear.'],
            'cautions': ['Confirm this with your provider.'],
          }),
          200,
          headers: {
            'content-type': 'application/json',
          },
        );
      });

      final service = AiAssistantService(
        client: client,
        baseUrl: 'https://example.run.app',
      );

      final result = await service.explain(
        '  Example medical letter  ',
      );

      expect(result.summary, 'A simple summary.');
      expect(result.importantDetails, ['Important detail']);
      expect(result.plainTerms.single.term, 'Term');
      expect(result.questionsToAsk, ['What happens next?']);
      expect(result.uncertainties, ['The date is unclear.']);
    });
  });

  group('AiAssistantService.createDrafts', () {
    test('parses proposed drafts without saving them', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://example.run.app/v1/drafts',
        );

        return http.Response(
          jsonEncode({
            'drafts': [
              {
                'type': 'reminder',
                'values': [
                  {
                    'field': 'title',
                    'value': 'Bring medication list',
                  },
                  {
                    'field': 'date',
                    'value': '2026-10-17',
                  },
                ],
                'evidence': 'Please bring your medication list.',
                'missing_required': [],
              },
            ],
          }),
          200,
        );
      });

      final service = AiAssistantService(
        client: client,
        baseUrl: 'https://example.run.app',
      );

      final drafts = await service.createDrafts(
        'Please bring your medication list.',
      );

      expect(drafts, hasLength(1));
      expect(drafts.single.type, AiDraftType.reminder);
      expect(
        drafts.single.valueFor('title'),
        'Bring medication list',
      );
      expect(drafts.single.isComplete, isTrue);
    });

    test('preserves missing required fields', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'drafts': [
              {
                'type': 'appointment',
                'values': [],
                'evidence': 'Schedule a follow-up appointment.',
                'missing_required': ['date', 'time'],
              },
            ],
          }),
          200,
        );
      });

      final service = AiAssistantService(
        client: client,
        baseUrl: 'https://example.run.app',
      );

      final drafts = await service.createDrafts(
        'Schedule a follow-up appointment.',
      );

      expect(drafts.single.isComplete, isFalse);
      expect(
        drafts.single.missingRequired,
        ['date', 'time'],
      );
      expect(drafts.single.valueFor('date'), isNull);
    });
  });

  group('AiAssistantService errors', () {
    test('rejects blank input without making a request', () async {
      var requestCount = 0;

      final client = MockClient((request) async {
        requestCount += 1;
        return http.Response('{}', 200);
      });

      final service = AiAssistantService(
        client: client,
        baseUrl: 'https://example.run.app',
      );

      await expectLater(
        service.explain('   '),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.type,
            'type',
            AiServiceErrorType.invalidInput,
          ),
        ),
      );

      expect(requestCount, 0);
    });

    test('converts a rate limit into a typed error', () async {
      final client = MockClient((request) async {
        return http.Response('{}', 429);
      });

      final service = AiAssistantService(
        client: client,
        baseUrl: 'https://example.run.app',
      );

      await expectLater(
        service.explain('Example text'),
        throwsA(
          isA<AiServiceException>()
              .having(
                (error) => error.type,
                'type',
                AiServiceErrorType.rateLimited,
              )
              .having(
                (error) => error.statusCode,
                'statusCode',
                429,
              ),
        ),
      );
    });

    test('rejects malformed response JSON', () async {
      final client = MockClient((request) async {
        return http.Response('not json', 200);
      });

      final service = AiAssistantService(
        client: client,
        baseUrl: 'https://example.run.app',
      );

      await expectLater(
        service.explain('Example text'),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.type,
            'type',
            AiServiceErrorType.invalidResponse,
          ),
        ),
      );
    });

    test('rejects an insecure non-local URL', () async {
      final service = AiAssistantService(
        client: MockClient((request) async {
          return http.Response('{}', 200);
        }),
        baseUrl: 'http://example.com',
      );

      await expectLater(
        service.explain('Example text'),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.type,
            'type',
            AiServiceErrorType.configuration,
          ),
        ),
      );
    });
  });
}
