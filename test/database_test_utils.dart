// import 'dart:convert'; // Pour utf8 - Non utilisé
import 'dart:io'; // Pour File
import 'dart:typed_data'; // Endian, ByteData
import 'package:flutter/services.dart'; // Pour MethodChannel, ByteData, Uint8List
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:taxasge/database/database_service.dart';
// import 'package:taxasge/database/schema.dart'; // Non utilisé ici
import 'package:path/path.dart' as p; // Importer path pour join

// Initialise sqflite_common_ffi pour les tests sur desktop.
void sqfliteTestInit() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

// Fournit une instance de DatabaseService avec une base de données en mémoire pour les tests,
// et charge les données depuis un fichier JSON de test spécifié.
Future<DatabaseService> getTestDatabaseService({
  String testJsonAssetPath =
      'test/test_assets/test_taxes.json', // Chemin relatif à la racine du projet
  bool seedData = true,
}) async {
  // Le mock pour rootBundle doit être configuré avant l'initialisation de DatabaseService
  // si DatabaseService appelle rootBundle.loadString lors de son initialisation.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter/assets'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'loadString') {
        final String? key = methodCall.arguments as String?;
        // Si DatabaseService demande le fichier JSON de production, on lui donne celui de test.
        if (key == 'assets/data/taxes.json' && testJsonAssetPath.isNotEmpty) {
          try {
            // Construire le chemin absolu basé sur le répertoire courant du projet
            final projectRoot = Directory.current.path;
            final absoluteTestJsonPath = p.join(projectRoot, testJsonAssetPath);

            final file = File(absoluteTestJsonPath);
            if (await file.exists()) {
              // print('Mocking asset load: Reading from $absoluteTestJsonPath for $key'); // Nettoyé
              return await file.readAsString(); // loadString attend une String
            } else {
              // print('Mock Asset Warning: Test JSON file $absoluteTestJsonPath not found for $key. Returning empty list.'); // Nettoyé
              return '[]'; // Fallback JSON valide minimal pour éviter de planter
            }
          } catch (e) {
            // print('Erreur de chargement du fichier JSON de test ($testJsonAssetPath) via mock pour $key: $e'); // Nettoyé
            return '[]'; // Fallback
          }
        }
        // Mocks pour les tokenizers (contenu JSON string simple)
        // Ces mocks sont nécessaires car DatabaseService.initialize peut appeler ChatbotService.initialize
        // qui à son tour appelle ModelService.initialize.
        if ((key ?? "").contains('taxasge_model_question_tokenizer.json')) {
          return '{"config": {"word_index": {"<OOV>": 1, "hola": 2, "precio":3, "de":4, "impuesto":5, "alpha":6, "test":7, "prueba":8 }, "oov_token":"<OOV>"}}';
        }
        if ((key ?? "").contains('taxasge_model_answer_tokenizer.json')) {
          return '{"config": {"word_index": {"<OOV>": 1, "<START>":2, "<END>":3, "el":4, "costo":5, "es":6, "mil":7, "quinientos":8 }, "oov_token":"<OOV>"}}';
        }
      }
      // Mock pour le modèle TFLite (ByteData)
      if (methodCall.method == 'load') {
        final String? key = methodCall.arguments as String?;
        if (key == 'assets/ml/taxasge_model.tflite') {
          // Simuler un fichier TFLite bidon avec l'en-tête si ModelService le lit
          final ByteData header =
              ByteData(256); // Assez grand pour éviter les erreurs de Range
          header.setInt64(0, 128, Endian.little); // Dummy encoder size
          header.setInt64(8, 128, Endian.little); // Dummy decoder size
          for (int i = 16; i < header.lengthInBytes; i++) {
            header.setUint8(i, 0);
          }
          return header.buffer.asByteData();
        }
      }
      // Pour tout autre appel d'asset non mocké explicitement ici
      // print('Mock Asset Warning: Unhandled asset call: ${methodCall.method} ${methodCall.arguments}'); // Nettoyé
      return null;
    },
  );

  final dbService = DatabaseService();
  // forceReset: true avec openDatabase(inMemoryDatabasePath) va créer une nouvelle DB en mémoire à chaque fois.
  // seedData: true appellera _importInitialData qui utilisera le mock ci-dessus.
  // testJsonString: null est crucial pour que DatabaseService utilise rootBundle.loadString('assets/data/taxes.json')
  await dbService.initialize(forceReset: true, seedData: seedData);

  // Nettoyer le mock après son utilisation par DatabaseService.initialize()
  // pour ne pas affecter d'autres tests qui pourraient vouloir utiliser le vrai rootBundle
  // ou un mock différent.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);

  return dbService;
}

// Le JSON minimal peut être conservé pour des tests très spécifiques si nécessaire,
// mais getTestDatabaseService chargera test_taxes.json par défaut.
