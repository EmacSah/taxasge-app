import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/services/chatbot_service.dart';
import 'package:taxasge/services/localization_service.dart';
import 'package:taxasge/models/chat_message.dart';
import 'package:mockito/mockito.dart'; // Importation standard
import 'package:shared_preferences/shared_preferences.dart'; // Ajout pour SharedPreferences
import '../database_test_utils.dart'; // Pour sqfliteTestInit
import '../mocks/mock_nlp_services.dart'; // Importer les mocks
import 'package:flutter/material.dart';

// Recréer des instances de mock si elles ne sont pas auto-générées par build_runner
// Ces lignes ne sont nécessaires que si vous n'utilisez pas build_runner pour générer les mocks.
// class MockModelService extends Mock implements ModelService {}
// class MockQueryProcessor extends Mock implements QueryProcessor {}
// class MockResponseGenerator extends Mock implements ResponseGenerator {}


void main() {
  sqfliteTestInit(); // Pour LocalizationService qui peut dépendre de la DB pour les prefs
  
  late ChatbotService chatbotService;
  late MockModelService mockModelService;
  late MockQueryProcessor mockQueryProcessor;
  late MockResponseGenerator mockResponseGenerator;

  setUp(() async {
    // Initialiser SharedPreferences pour LocalizationService
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.instance.initialize();
    await LocalizationService.instance.setLanguage('es');

    mockModelService = MockModelService();
    mockQueryProcessor = MockQueryProcessor();
    mockResponseGenerator = MockResponseGenerator();

    // Ici, il faudrait pouvoir injecter les mocks dans ChatbotService.
    // Puisque ChatbotService utilise des singletons pour ses dépendances NLP,
    // c'est plus complexe à tester unitairement de manière isolée sans refactorisation
    // du ChatbotService pour permettre l'injection de dépendances (par exemple via constructeur).

    // Pour ce test, nous allons instancier ChatbotService normalement,
    // et les mocks ne seront pas directement utilisés par CETTE instance de ChatbotService
    // à moins de modifier ChatbotService.
    // Les tests ci-dessous vont donc tester l'intégration de ChatbotService avec les vrais services NLP
    // (qui eux-mêmes pourraient avoir besoin de setup si ils ne sont pas triviaux).
    // OU, si ChatbotService était refactorisé :
    // chatbotService = ChatbotService.internal(mockModelService, mockQueryProcessor, mockResponseGenerator, LocalizationService.instance);
    
    // Pour l'instant, on va tester le ChatbotService tel quel.
    // On va simuler le comportement des mocks pour les appels attendus.
    // Note: Ceci ne teste pas ChatbotService de manière isolée.
    
    chatbotService = ChatbotService.instance; 
    // On doit s'assurer que le ModelService interne au ChatbotService est initialisé.
    // Si ModelService.instance.initialize() n'est pas appelé, les vrais services NLP ne fonctionneront pas.
    // Pour un test unitaire propre, il faudrait injecter les mocks.
    // Supposons que initialize() est appelé et que les mocks peuvent intercepter les appels
    // si ChatbotService était conçu pour cela.
    // Comme ce n'est pas le cas, ces tests seront plus des tests d'intégration.
    
    // Pour simuler un environnement où les services NLP sont "prêts" (même si ce sont les vrais)
    await chatbotService.initialize(); 
    // Cela va appeler ModelService.instance.initialize() qui chargera le vrai modèle.
    // Ce n'est PAS un test unitaire pur pour ChatbotService.
  });

  group('ChatbotService sendMessage', () {
    test('adds user message and bot response to messages list', () async {
      final initialMessageCount = chatbotService.messages.length; // Devrait être 1 (message de bienvenue)
      
      // Pour ce test, nous ne pouvons pas facilement mocker processQuery et generateResponse
      // sans modifier ChatbotService pour l'injection de dépendance.
      // Nous allons donc tester avec une entrée simple et observer.
      await chatbotService.sendMessage("Hola");
      
      expect(chatbotService.messages.length, initialMessageCount + 2);
      expect(chatbotService.messages[initialMessageCount].isUser, isTrue);
      expect(chatbotService.messages[initialMessageCount].text, "Hola");
      expect(chatbotService.messages[initialMessageCount+1].isUser, isFalse);
      // La réponse exacte dépendra du vrai modèle NLP et des données.
      // Pour un test unitaire, on aurait mocké la réponse.
      // expect(chatbotService.messages[initialMessageCount+1].text, "Hola! ¿Cómo puedo ayudarte?");
      debugPrint("Réponse du bot: ${chatbotService.messages[initialMessageCount+1].text}"); // Pour voir la vraie réponse
    });

    test('sets isProcessing to true during processing and false after', () async {
      bool processingStateDuringCall = false;
      chatbotService.addListener(() {
        if (chatbotService.isProcessing) {
          processingStateDuringCall = true;
        }
      });
      
      expect(chatbotService.isProcessing, isFalse);
      final future = chatbotService.sendMessage("Test"); // Pas d'await ici
      expect(chatbotService.isProcessing, isTrue);
      await future; // Attendre la complétion
      expect(chatbotService.isProcessing, isFalse);
      expect(processingStateDuringCall, isTrue);
    });

    test('handles empty message string gracefully', () async {
      final initialMessages = List.from(chatbotService.messages);
      await chatbotService.sendMessage("   ");
      expect(chatbotService.messages.length, initialMessages.length);
    });
  });

  group('ChatbotService suggestions', () {
    test('getSuggestions returns general suggestions initially', () {
      final suggestions = chatbotService.getSuggestions();
      // S'attendre à des suggestions générales car _lastConcept est null
      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.contains("pasaporte")), isTrue); // Exemple
    });

    // Pour tester les suggestions contextuelles, il faudrait pouvoir définir _lastConcept,
    // ce qui est difficile sans modifier ChatbotService ou avoir un contrôle fin sur QueryProcessor.
  });

  test('clearHistory clears messages and resets context', () async {
    await chatbotService.sendMessage("Test message");
    expect(chatbotService.messages.length, greaterThan(1)); // Au moins bienvenue + 2

    chatbotService.clearHistory();
    expect(chatbotService.messages.length, 1); // Seulement le message de bienvenue
    expect(chatbotService.messages.first.isUser, isFalse); // Doit être le message de bienvenue
    // Vérifier aussi que _lastIntent et _lastConcept sont null (non testable directement sans modification)
  });
}
