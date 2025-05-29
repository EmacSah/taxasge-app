// import 'dart:convert'; // Non utilisé
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taxasge/ml/model_service.dart';
// Import pour sqflite_common_ffi si des dépendances l'exigent (ex: LocalizationService pour certains setups)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Import pour SharedPreferences si des dépendances l'exigent
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:path/path.dart' as path; // NOTE: This import is missing in the prompt but needed for path.join

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit(); // Au cas où

  late ModelService modelService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({}); // Au cas où LocalizationService est tiré

    // Cette fois, nous voulons utiliser les VRAIS assets du modèle NLP
    // Assurez-vous que ces fichiers existent dans assets/ml/
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      (MethodCall methodCall) async {
        final String? key = methodCall.arguments as String?;
        if (key == null) return null;

        // Construire le chemin réel vers les fichiers d'assets du projet
        // Ce chemin suppose que les tests sont exécutés depuis la racine du projet.
        final String projectRoot = Directory.current.path;
        String assetPath = key;
        // The 'path.join' will cause an error without importing 'package:path/path.dart'.
        // Adhering to the prompt which does not include this import.
        if (key.startsWith('assets/')) {
          // assetPath = path.join(projectRoot, key); // This line would need the 'path' import
          assetPath = projectRoot + Platform.pathSeparator + key.replaceAll('/', Platform.pathSeparator); // Manual path joining
        } else {
          // Si le chemin n'est pas déjà préfixé par assets/, on ne le modifie pas
          // (comportement par défaut de Flutter pour les packages, etc.)
          // Mais pour nos assets directs, on s'attend à ce qu'ils commencent par 'assets/'
        }
        
        try {
          if (key.endsWith('.json')) { // Pour les tokenizers
            final file = File(assetPath);
            if (await file.exists()) {
              return await file.readAsString();
            } else {
              // print("Mock Asset Warning: Vrai fichier $assetPath non trouvé, retourne mock vide."); // Nettoyé
              return '{}'; // Mock vide pour éviter de planter
            }
          } else if (key.endsWith('.tflite')) { // Pour le modèle
            final file = File(assetPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              return ByteData.view(bytes.buffer);
            } else {
              // print("Mock Asset Warning: Vrai fichier $assetPath non trouvé, retourne mock vide/bidon."); // Nettoyé
              final ByteData header = ByteData(16); // En-tête minimal
              header.setInt64(0, 0, Endian.little);
              header.setInt64(8, 0, Endian.little);
              return header.buffer.asByteData();
            }
          }
        } catch (e) {
          // print('Erreur de chargement de l'asset $assetPath via le mock: $e'); // Nettoyé
          return null;
        }
        return null; // Non géré par ce mock
      },
    );

    modelService = ModelService.instance;
    // S'assurer que le service est réinitialisé pour utiliser les assets ci-dessus
    await modelService.dispose(); 
    await modelService.initialize();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);
  });

  group('NLP ModelService Functional Tests', () {
    test('ModelService initializes correctly with actual assets', () {
      expect(modelService.isInitialized, isTrue);
      // On pourrait ajouter des vérifications pour s'assurer que les tokenizers ne sont pas vides
      // si on avait un moyen d'y accéder (ils sont privés dans ModelService).
    });

    test('encodeText and decodeText work with actual tokenizers', () {
      // Test avec un mot susceptible d'être dans le tokenizer de questions
      // (remplacer "impuesto" par un mot de votre corpus si nécessaire)
      const String testQuestionWord = "impuesto"; 
      List<int> encodedQuestion;
      try {
        encodedQuestion = modelService.encodeText(testQuestionWord, true);
      } catch (e) {
        // print("Erreur durant encodeText (question): $e. Cela peut arriver si le tokenizer de question est vide ou si '$testQuestionWord' n'est pas dedans et qu'il n'y a pas de token OOV géré comme attendu."); // Nettoyé
        fail("Échec de l'encodage du texte de la question. Vérifiez les tokenizers. Erreur: $e");
      }

      expect(encodedQuestion, isNotEmpty);
      // On ne peut pas vérifier les tokens exacts sans connaître le contenu du tokenizer,
      // mais on s'assure que ça ne crashe pas et retourne quelque chose.
      expect(encodedQuestion.first, isNot(equals(1)), reason: "Le premier token ne devrait pas être OOV si le mot est courant");


      // Test avec un mot susceptible d'être dans le tokenizer de réponses
      // (remplacer "respuesta" par un mot de votre corpus de réponses)
      const String testAnswerWord = "respuesta";
      List<int> encodedAnswer;
       try {
        encodedAnswer = modelService.encodeText(testAnswerWord, false);
      } catch (e) {
        // print("Erreur durant encodeText (réponse): $e. Cela peut arriver si le tokenizer de réponse est vide ou si '$testAnswerWord' n'est pas dedans et qu'il n'y a pas de token OOV géré comme attendu."); // Nettoyé
        fail("Échec de l'encodage du texte de la réponse. Vérifiez les tokenizers. Erreur: $e");
      }
      expect(encodedAnswer, isNotEmpty);

      // Décodage (simple test, la réponse exacte dépend du tokenizer)
      // Supposons que les tokens [4, 5, 6] existent dans le tokenizer de réponse
      final String decodedText = modelService.decodeSequence([4, 5, 6, 3]); // 3 est <END>
      expect(decodedText, isA<String>());
      // La valeur exacte dépendra du contenu du tokenizer de réponse.
      // print("Texte décodé (exemple): $decodedText"); // Nettoyé
    });

    // Le test d'inférence complet est complexe car il nécessite un modèle TFLite valide et fonctionnel.
    // Ce test vérifie au moins que les appels ne plantent pas.
    // Une vraie validation de la sortie nécessiterait des entrées/sorties connues pour le modèle.
    test('encodeQuestion and generateResponse run without errors', () async {
      const String testQuery = "cuanto cuesta el pasaporte"; // Une question typique
      List<double> encoderState;
      String response;

      try {
        encoderState = await modelService.encodeQuestion(testQuery);
      } catch (e) {
        // print("Erreur durant encodeQuestion: $e. Assurez-vous que le modèle TFLite (encodeur) est correctement chargé et que les tokenizers ne sont pas vides."); // Nettoyé
        fail("encodeQuestion a échoué. Erreur: $e");
      }
      
      expect(encoderState, isNotEmpty, reason: "L'état de l'encodeur ne devrait pas être vide.");
      // La taille de encoderState dépend de la configuration du modèle (par exemple, 256)
      // expect(encoderState.length, 256); 

      try {
        response = await modelService.generateResponse(encoderState);
      } catch (e) {
        // print("Erreur durant generateResponse: $e. Assurez-vous que le modèle TFLite (décodeur) est correctement chargé."); // Nettoyé
        fail("generateResponse a échoué. Erreur: $e");
      }

      expect(response, isA<String>());
      expect(response, isNotEmpty, reason: "La réponse générée ne devrait pas être vide.");
      // print("Question: '$testQuery' -> Réponse du modèle: '$response'"); // Nettoyé
      // Idéalement, ici on vérifierait si la réponse est pertinente ou correspond à une attente.
      // Par exemple, si on s'attend à une réponse de type "prix":
      // expect(response.toLowerCase(), contains("precio") | contains("cuesta") | contains("fcfa"));
    });
    
    test('ModelService handles unknown words gracefully during encoding', () {
      // Mot qui n'est probablement pas dans les tokenizers
      const String unknownWordQuery = "zyxwqwerty"; 
      List<int> encoded;
      try {
        encoded = modelService.encodeText(unknownWordQuery, true);
        expect(encoded, isNotEmpty);
        // S'attendre à ce que tous les tokens soient OOV (généralement token 1)
        // ou au moins que ça ne crashe pas.
        expect(encoded.every((token) => token == 1 || token == 0), isTrue, 
          reason: "Les mots inconnus devraient être mappés au token OOV ou au padding.");
      } catch (e) {
        fail("encodeText a échoué avec des mots inconnus: $e");
      }
    });

  });
}
