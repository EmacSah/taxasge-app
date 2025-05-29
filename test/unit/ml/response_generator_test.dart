import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/ml/response_generator.dart';
import 'package:taxasge/services/localization_service.dart';
import 'package:taxasge/database/database_service.dart'; // Au cas où ResponseGenerator l'utilise
import '../../database_test_utils.dart'; // Pour getTestDatabaseService et minimalTestJson
import 'package:shared_preferences/shared_preferences.dart'; // Ajouté pour SharedPreferences

void main() {
  sqfliteTestInit(); // Initialise FFI pour les tests db si nécessaire

  group('ResponseGenerator Tests', () {
    late ResponseGenerator responseGenerator;
    late DatabaseService dbService; // Au cas où ResponseGenerator en aurait besoin

    setUpAll(() async {
      // Initialiser SharedPreferences pour LocalizationService une fois
      TestWidgetsFlutterBinding.ensureInitialized(); // Nécessaire pour SharedPreferences
      SharedPreferences.setMockInitialValues({});
      await LocalizationService.instance.initialize();
    });

    setUp(() async {
      responseGenerator = ResponseGenerator();
      // Initialiser une DB de test si ResponseGenerator doit y accéder
      // Utiliser minimalTestJson pour des données de test contrôlées et simples
      // Correction de testJsonPath à testJsonAssetPath pour correspondre à la signature de getTestDatabaseService
      // Cependant, getTestDatabaseService utilise testJsonAssetPath pour charger via mock rootBundle.
      // Si on fournit testJsonString, il devrait l'utiliser directement (si DatabaseService.initialize le supporte).
      // La version actuelle de getTestDatabaseService (Turn 52) force l'utilisation de testJsonAssetPath via rootBundle mock
      // si testJsonString est null dans DatabaseService.initialize.
      // Pour que minimalTestJson soit utilisé, il faut que DatabaseService.initialize le prenne en compte.
      // Le DatabaseService.initialize actuel, quand testJsonString est fourni, l'utilise.
      // Donc, passer minimalTestJson à testJsonString est correct ici.
      // testJsonPath: '' est une erreur de frappe, ce devrait être testJsonAssetPath
      // Mais si on veut forcer minimalTestJson, on le passe à testJsonString.
      dbService = await getTestDatabaseService(testJsonAssetPath: '', testJsonString: minimalTestJson);
      await LocalizationService.instance.setLanguage('es'); // Langue par défaut pour les tests
    });

    tearDown(() async {
      await dbService.close();
    });

    test('generateResponse for "saludo" intent', () async {
      final processedQuery = {
        'intent': 'saludo',
        'concepts': [],
        'original_query': 'Hola'
      };
      final response = await responseGenerator.generateResponse(processedQuery);
      
      expect(response, isA<String>());
      expect(response, isNotEmpty);
      // La réponse exacte dépend de l'implémentation de ResponseGenerator
      // Pour ce test, on peut s'attendre à une salutation générique.
      // Exemple (à adapter selon la logique réelle de ResponseGenerator):
      // expect(response.toLowerCase(), contains('hola') | contains('saludos'));
      // print("Réponse pour saludo: $response"); // Nettoyé
    });

    test('generateResponse for "consulta_precio" intent with a concept', () async {
      // Ce concept "T-TEST" vient de minimalTestJson
      final processedQuery = {
        'intent': 'consulta_precio',
        'concepts': [{'id': 'T-TEST', 'nombre_current': 'CONCEPTO DE PRUEBA', 'nombre': {'es': 'CONCEPTO DE PRUEBA'}}],
        'original_query': 'precio de CONCEPTO DE PRUEBA',
      };
      
      // ResponseGenerator pourrait avoir besoin d'accéder à dbService.conceptoDao pour les détails.
      // L'instance dbService est disponible et initialisée avec minimalTestJson.
      final response = await responseGenerator.generateResponse(processedQuery);
      
      expect(response, isA<String>());
      expect(response, isNotEmpty);
      // La réponse devrait contenir le nom du concept et son prix.
      expect(response, contains('CONCEPTO DE PRUEBA'));
      expect(response, contains('100')); // tasa_expedicion de T-TEST dans minimalTestJson
      // print("Réponse pour consulta_precio (T-TEST): $response"); // Nettoyé
    });

    test('generateResponse for "desconocido" intent', () async {
      final processedQuery = {
        'intent': 'intencion_desconocida_xyz',
        'concepts': [],
        'original_query': 'blablabla'
      };
      final response = await responseGenerator.generateResponse(processedQuery);

      expect(response, isA<String>());
      expect(response, isNotEmpty);
      // S'attendre à une réponse de fallback.
      // Exemple (à adapter):
      // expect(response.toLowerCase(), contains('no he podido entender') | contains('lo siento'));
      // print("Réponse pour desconocido: $response"); // Nettoyé
    });

    test('generateResponse for intent requiring documents', () async {
      final processedQuery = {
        'intent': 'consulta_documentos',
        'concepts': [{'id': 'T-TEST', 'nombre_current': 'CONCEPTO DE PRUEBA'}],
        'original_query': 'documentos para CONCEPTO DE PRUEBA',
      };
      final response = await responseGenerator.generateResponse(processedQuery);
      expect(response, contains('Doc1'));
      expect(response, contains('Doc2'));
      // print("Réponse pour consulta_documentos (T-TEST): $response"); // Nettoyé
    });

    test('generateResponse for intent requiring procedure', () async {
      final processedQuery = {
        'intent': 'consulta_procedimiento',
        'concepts': [{'id': 'T-TEST', 'nombre_current': 'CONCEPTO DE PRUEBA'}],
        'original_query': 'procedimiento para CONCEPTO DE PRUEBA',
      };
      final response = await responseGenerator.generateResponse(processedQuery);
      expect(response, contains('Proc1'));
      expect(response, contains('Proc2'));
      // print("Réponse pour consulta_procedimiento (T-TEST): $response"); // Nettoyé
    });

    // TODO: Ajouter des tests pour différentes langues si ResponseGenerator les gère.
    // TODO: Tester les cas où les informations (prix, docs, proc) sont manquantes pour un concept.
  });
}
