// test/unit/ml/query_processor_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/ml/query_processor.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/services/localization_service.dart';
import '../../test_utils/test_config.dart';

void main() {
  group('QueryProcessor Tests', () {
    late QueryProcessor queryProcessor;
    late DatabaseService mockDbService;

    setUpAll(() async {
      await TestConfig.initialize();
      mockDbService = await TestConfig.initializeDatabase();
    });

    setUp(() {
      queryProcessor = QueryProcessor(
        dbService: mockDbService,
        localizationService: LocalizationService.instance,
      );
    });

    group('Query Normalization', () {
      test('should normalize queries correctly', () async {
        const rawQuery = '  ¿CUÁNTO CUESTA el PASAPORTE?  ';

        final result = await queryProcessor.processQuery(rawQuery);

        expect(
            result['normalized_query'], equals('¿cuánto cuesta el pasaporte?'));
        expect(result['raw_query'], equals(rawQuery));
      });

      test('should detect greetings', () async {
        const greeting = 'Hola';

        final result = await queryProcessor.processQuery(greeting);

        expect(result['type'], equals('greeting'));
      });

      test('should detect thanks', () async {
        const thanks = 'Gracias';

        final result = await queryProcessor.processQuery(thanks);

        expect(result['type'], equals('thanks'));
      });
    });

    group('Intent Detection', () {
      test('should detect price intent', () async {
        const priceQuery = '¿Cuánto cuesta el pasaporte?';

        final result = await queryProcessor.processQuery(priceQuery);

        expect(result['intent'], equals('prix'));
      });

      test('should detect document intent', () async {
        const docQuery = '¿Qué documentos necesito para el pasaporte?';

        final result = await queryProcessor.processQuery(docQuery);

        expect(result['intent'], equals('documents'));
      });

      test('should detect procedure intent', () async {
        const procQuery = '¿Cuál es el procedimiento para el pasaporte?';

        final result = await queryProcessor.processQuery(procQuery);

        expect(result['intent'], equals('procedure'));
      });
    });

    group('Concept Identification', () {
      test('should identify mentioned concepts', () async {
        const query = 'Información sobre pasaporte';

        final result = await queryProcessor.processQuery(query);

        expect(result['concepts'], isA<List>());
        // Should find concepts related to passport if they exist in test data
      });
    });

    group('Multilingual Support', () {
      test('should process French queries', () async {
        const frenchQuery = 'Combien coûte le passeport?';

        final result = await queryProcessor.processQuery(frenchQuery);

        expect(result['language'], isNotNull);
        expect(result['intent'], isNotNull);
      });

      test('should process English queries', () async {
        const englishQuery = 'How much does a passport cost?';

        final result = await queryProcessor.processQuery(englishQuery);

        expect(result['language'], isNotNull);
        expect(result['intent'], isNotNull);
      });
    });
  });
}
