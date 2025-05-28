import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/ml/response_generator.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/services/localization_service.dart';
import '../../test_utils/test_config.dart';

void main() {
  group('ResponseGenerator Tests', () {
    late ResponseGenerator responseGenerator;
    late DatabaseService mockDbService;

    setUpAll(() async {
      await TestConfig.initialize();
      mockDbService = await TestConfig.initializeDatabase();
    });

    setUp(() {
      responseGenerator = ResponseGenerator(
        dbService: mockDbService,
        localizationService: LocalizationService.instance,
      );
    });

    group('Greeting and Thanks Responses', () {
      test('should generate appropriate greeting response in Spanish', () async {
        final mockQuery = {
          'type': 'greeting',
          'language': 'es'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('procedure'),
          contains('process'),
          contains('Test Tax')
        ]));
      });

      test('should generate ministry response for ministry intent', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'ministerio',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'es'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('Ministerio'),
          contains('gestionado'),
          contains('Test Tax')
        ]));
      });
    });

    group('Error Handling', () {
      test('should generate error response for empty concepts', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'prix',
          'concepts': <Map<String, dynamic>>[],
          'encoded_state': List.filled(256, 0.0),
          'language': 'es'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        // Should fall back to ML model or error template
      });

      test('should handle unknown query type gracefully', () async {
        final mockQuery = {
          'type': 'unknown',
          'language': 'es'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('Lo siento'),
          contains('no pude'),
          contains('reformular')
        ]));
      });

      test('should handle missing language gracefully', () async {
        final mockQuery = {
          'type': 'greeting'
          // Missing language
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        // Should default to Spanish
        expect(response, anyOf([
          contains('Hola'),
          contains('Buenos')
        ]));
      });
    });

    group('Template Combination', () {
      test('should combine multiple response templates correctly', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'info',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax',
            'tasa_expedicion': '1000',
            'tasa_renovacion': '500'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'es'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, contains('Test Tax'));
      });

      test('should add follow-up suggestions when appropriate', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'prix',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'fr'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        // Response might include follow-up suggestions
      });
    });

    group('Multilingual Support', () {
      test('should respect language preference in responses', () async {
        final languages = ['es', 'fr', 'en'];
        
        for (final lang in languages) {
          final mockQuery = {
            'type': 'greeting',
            'language': lang
          };

          final response = await responseGenerator.generateResponse(mockQuery);
          
          expect(response, isNotEmpty);
          
          // Verify language-specific content
          switch (lang) {
            case 'es':
              expect(response, anyOf([contains('Hola'), contains('Buenos')]));
              break;
            case 'fr':
              expect(response, anyOf([contains('Bonjour'), contains('Salut')]));
              break;
            case 'en':
              expect(response, anyOf([contains('Hello'), contains('Hi')]));
              break;
          }
        }
      });

      test('should fallback to default language for unsupported languages', () async {
        final mockQuery = {
          'type': 'greeting',
          'language': 'de' // Unsupported language
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        // Should fallback to Spanish (default)
        expect(response, anyOf([
          contains('Hola'),
          contains('Buenos')
        ]));
      });
    });

    group('Performance Tests', () {
      test('should generate response within acceptable time', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'prix',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'es'
        };

        final stopwatch = Stopwatch()..start();
        final response = await responseGenerator.generateResponse(mockQuery);
        stopwatch.stop();

        expect(response, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Less than 1 second
      });

      test('should handle multiple concurrent requests', () async {
        final futures = <Future<String>>[];
        
        for (int i = 0; i < 5; i++) {
          final mockQuery = {
            'type': 'greeting',
            'language': 'es'
          };
          
          futures.add(responseGenerator.generateResponse(mockQuery));
        }

        final responses = await Future.wait(futures);
        
        expect(responses.length, equals(5));
        for (final response in responses) {
          expect(response, isNotEmpty);
        }
      });
    });
  });
}, anyOf([
          contains('Hola'),
          contains('Buenos'),
          contains('ayudarte'),
          contains('asistente')
        ]));
      });

      test('should generate appropriate greeting response in French', () async {
        final mockQuery = {
          'type': 'greeting',
          'language': 'fr'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('Bonjour'),
          contains('aider'),
          contains('assistant')
        ]));
      });

      test('should generate appropriate thanks response in English', () async {
        final mockQuery = {
          'type': 'thanks',
          'language': 'en'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('welcome'),
          contains('pleasure'),
          contains('help')
        ]));
      });
    });

    group('Contextual Responses', () {
      test('should generate price response for price intent', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'prix',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax',
            'tasa_expedicion': '1000',
            'tasa_renovacion': '500'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'es'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('costo'),
          contains('precio'),
          contains('1000'),
          contains('500')
        ]));
      });

      test('should generate documents response for documents intent', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'documents',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'fr'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response, anyOf([
          contains('documents'),
          contains('requis'),
          contains('Test Tax')
        ]));
      });

      test('should generate procedure response for procedure intent', () async {
        final mockQuery = {
          'type': 'query',
          'intent': 'procedure',
          'concepts': [{
            'id': 'T-TEST-001',
            'nombre_current': 'Test Tax'
          }],
          'encoded_state': List.filled(256, 0.0),
          'language': 'en'
        };

        final response = await responseGenerator.generateResponse(mockQuery);
        
        expect(response, isNotEmpty);
        expect(response