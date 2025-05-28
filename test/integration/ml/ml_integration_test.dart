// test/integration/ml_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
//import 'package:taxasge/ml/model_service.dart';
//import 'package:taxasge/ml/query_processor.dart';
//import 'package:taxasge/ml/response_generator.dart';
import 'package:taxasge/services/chatbot_service.dart';
import '../../test_utils/test_config.dart';

void main() {
  group('ML Integration Tests', () {
    late ChatbotService chatbotService;

    setUpAll(() async {
      await TestConfig.initialize();
      await TestConfig.initializeDatabase();
    });

    setUp(() {
      chatbotService = ChatbotService.instance;
    });

    test('Complete chatbot flow should work end-to-end', () async {
      await chatbotService.initialize();

      const testQuery = '¿Cuánto cuesta el pasaporte?';

      // This should process the complete flow:
      // Query -> NLP Processing -> Database Search -> Response Generation
      await chatbotService.sendMessage(testQuery);

      expect(chatbotService.messages.length, greaterThan(1));
      expect(chatbotService.messages.last.isUser, false);
      expect(chatbotService.messages.last.text, isNotEmpty);
    });

    test('Multilingual flow should work correctly', () async {
      await chatbotService.initialize();

      const queries = [
        '¿Cuánto cuesta el pasaporte?',
        'Combien coûte le passeport?',
        'How much does a passport cost?',
      ];

      for (final query in queries) {
        await chatbotService.sendMessage(query);

        // Should have response for each query
        expect(chatbotService.messages.last.isUser, false);
        expect(chatbotService.messages.last.text, isNotEmpty);
      }
    });

    test('Error handling should work gracefully', () async {
      await chatbotService.initialize();

      // Test with invalid/nonsensical input
      const invalidQuery = 'xyzabc123invalid';

      await chatbotService.sendMessage(invalidQuery);

      // Should still provide a response, even if it's a fallback
      expect(chatbotService.messages.last.isUser, false);
      expect(chatbotService.messages.last.text, isNotEmpty);
    });

    group('Performance Tests', () {
      test('Response time should be under 2 seconds', () async {
        await chatbotService.initialize();

        const testQuery = '¿Cuál es el procedimiento para el pasaporte?';

        final stopwatch = Stopwatch()..start();
        await chatbotService.sendMessage(testQuery);
        stopwatch.stop();

        // Response should be generated within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });
    });
  });
}
