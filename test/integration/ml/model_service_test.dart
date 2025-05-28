//import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/ml/model_service.dart';
// Import sqflite_common_ffi pour l'initialisation si des dépendances indirectes l'exigent.
// Normalement, ModelService ne devrait pas dépendre directement de sqflite.
// Mais si LocalizationService est instancié par ModelService, il faut l'init.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Initialiser FFI au cas où une dépendance transitive (comme LocalizationService) en aurait besoin.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;


  group('ModelService Tests', () {
    late ModelService modelService;

    // Mock des tokenizers JSON et du modèle TFLite
    const String mockQuestionTokenizerJson = '''
    {
      "config": {
        "word_index": {
          "<OOV>": 1, "hola": 2, "mundo": 3, "precio": 4, "de": 5, "impuesto": 6, "alpha": 7
        },
        "oov_token": "<OOV>" 
      }
    }
    ''';
    const String mockAnswerTokenizerJson = '''
    {
      "config": {
         "word_index": {
          "<OOV>": 1, "<START>": 2, "<END>": 3, "el": 4, "costo": 5, "es": 6, "cien": 7
        },
        "oov_token": "<OOV>"
      }
    }
    ''';

    // Simuler un fichier TFLite bidon avec l'en-tête attendu (si applicable)
    // Pour ces tests, nous n'allons pas réellement exécuter l'interpréteur,
    // donc le contenu du modèle n'a pas besoin d'être un vrai modèle TFLite.
    // Si la logique _extractModelSizes est toujours utilisée, cet en-tête est important.
    // Encoder 256 (taille de l'encodeur) et 256 (taille du décodeur) en tant que int64 little-endian.
    final ByteData header = ByteData(16);
    header.setInt64(0, 256, Endian.little); // Dummy encoder size
    header.setInt64(8, 256, Endian.little); // Dummy decoder size
    final Uint8List mockModelBytes = header.buffer.asUint8List();


    setUp(() async {
      modelService = ModelService.instance;
      
      // Configurer le mock pour rootBundle.loadString et rootBundle.load
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String? key = methodCall.arguments as String?;
            if (key == 'assets/ml/taxasge_model_question_tokenizer.json') {
              return mockQuestionTokenizerJson;
            }
            if (key == 'assets/ml/taxasge_model_answer_tokenizer.json') {
              return mockAnswerTokenizerJson;
            }
          }
          if (methodCall.method == 'load') {
             final String? key = methodCall.arguments as String?;
            if (key == 'assets/ml/taxasge_model.tflite') {
              return ByteData.view(mockModelBytes.buffer);
            }
          }
          return null;
        },
      );
      // Forcer la réinitialisation pour charger les mocks (si ModelService garde un état _isInitialized)
      // Cela nécessite une méthode de réinitialisation dans ModelService ou de le rendre non-singleton pour les tests.
      // Pour l'instant, on va supposer qu'on peut le réinitialiser avant chaque test si nécessaire.
      // Ou que les tests ne dépendent pas d'une initialisation "propre" à chaque fois après le premier setUp.
      // Si ModelService est un vrai singleton et s'initialise une seule fois,
      // les mocks doivent être setup AVANT la première initialisation.
       await modelService.dispose(); // Pour s'assurer qu'il se réinitialise avec les mocks
       await modelService.initialize(); // Cela devrait maintenant utiliser les mocks
    });

    tearDown(() async {
       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);
       await modelService.dispose(); // Nettoyer l'état du service
    });

    test('initialize loads tokenizers and model (mocked)', () async {
      // L'initialisation est faite dans setUp. On vérifie l'état.
      expect(modelService.isInitialized, isTrue);
      // Des vérifications plus poussées pourraient inspecter les tokenizers chargés si rendus publics.
    });

    test('encodeText correctly tokenizes and pads question', () {
      final encoded = modelService.encodeText("hola mundo", true); // true pour question
      // "hola": 2, "mundo": 3. Padded avec 0. MAX_SEQUENCE_LENGTH est 50.
      expect(encoded.length, ModelService.maxSequenceLength);
      expect(encoded.sublist(0, 2), [2, 3]);
      expect(encoded.skip(2).every((val) => val == 0), isTrue); // Le reste doit être du padding
    });

    test('encodeText handles OOV words for question', () {
      final encoded = modelService.encodeText("hola desconocido", true);
      // "hola": 2, "desconocido": 1 (OOV)
      expect(encoded.sublist(0, 2), [2, 1]);
    });
    
    test('encodeText uses answer tokenizer correctly', () {
      // Utilise le tokenizer de réponse (isQuestion = false)
      // "<START>": 2, "el": 4, "costo": 5
      final encoded = modelService.encodeText("<START> el costo", false); 
      expect(encoded.length, ModelService.maxSequenceLength);
      expect(encoded.sublist(0,3), [2, 4, 5]);
    });

    test('decodeSequence correctly decodes sequence to text', () {
      // "<START>": 2, "el": 4, "costo": 5, "es": 6, "cien": 7, "<END>": 3
      final decoded = modelService.decodeSequence([2, 4, 5, 6, 7, 3, 0, 0]);
      expect(decoded, "el costo es cien");
    });
    
    test('decodeSequence handles OOV and padding', () {
      final decoded = modelService.decodeSequence([2, 4, 1, 6, 0, 0, 0]); // 1 est OOV
      // OOV devrait être ignoré par decodeSequence
      expect(decoded, "el es"); 
    });

    // Les tests pour encodeQuestion et generateResponse nécessiteraient de mocker Tflite.Interpreter
    // ce qui est plus complexe. Pour l'instant, on se concentre sur les parties testables sans cela.
    // Si le but est de tester que les interpréteurs sont appelés, on pourrait les mocker aussi.
    
    test('_extractModelSizes (if used and public) or model loading logic', () async {
        // Si _extractModelSizes était public, on pourrait le tester.
        // Sinon, on teste l'effet: que les interpréteurs sont créés.
        // Ceci est déjà implicitement testé par le fait que initialize() se termine sans erreur
        // et que isInitialized est true, car il essaie de créer les interprètes.
        // Pour un test plus direct, il faudrait rendre les interprètes accessibles ou avoir une méthode de vérification.
        
        // Pour ce test, nous allons juste nous assurer que l'initialisation a réussi,
        // ce qui implique que le chargement du modèle (mocké) et l'extraction (si applicable) n'ont pas levé d'erreur.
        await modelService.dispose(); // S'assurer qu'il n'est pas initialisé
        expect(modelService.isInitialized, isFalse);
        await modelService.initialize();
        expect(modelService.isInitialized, isTrue);
        // On pourrait ajouter des mocks pour Tflite.Interpreter.fromBuffer pour vérifier qu'ils sont appelés.
    });

  });
}
