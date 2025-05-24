import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/services/chatbot_service.dart';
//import 'package:taxasge/models/chat_message.dart';

void main() {
  group('ChatbotService', () {
    late ChatbotService chatbotService;

    setUp(() {
      chatbotService = ChatbotService.instance;
    });

    test('instance est un singleton', () {
      final instance1 = ChatbotService.instance;
      final instance2 = ChatbotService.instance;
      expect(identical(instance1, instance2), true);
    });

    test('initialisation ajoute un message de bienvenue', () async {
      await chatbotService.initialize();

      expect(chatbotService.messages, hasLength(1));
      expect(chatbotService.messages.first.isUser, false);
      expect(chatbotService.messages.first.text, isNotEmpty);
    });

    test('sendMessage ajoute les messages correctement', () async {
      await chatbotService.initialize();
      final initialCount = chatbotService.messages.length;

      await chatbotService.sendMessage('Test message');

      // Vérifie qu'il y a deux nouveaux messages (utilisateur + réponse)
      expect(chatbotService.messages.length, initialCount + 2);

      // Vérifie le message de l'utilisateur
      expect(chatbotService.messages[initialCount].isUser, true);
      expect(chatbotService.messages[initialCount].text, 'Test message');

      // Vérifie la réponse du chatbot
      expect(chatbotService.messages.last.isUser, false);
      expect(chatbotService.messages.last.text, isNotEmpty);
    });

    test('clearHistory réinitialise la conversation', () async {
      await chatbotService.initialize();
      await chatbotService.sendMessage('Test message');

      chatbotService.clearHistory();

      // Doit avoir uniquement le message de bienvenue
      expect(chatbotService.messages.length, 1);
      expect(chatbotService.messages.first.isUser, false);
    });

    test('getSuggestions retourne des suggestions valides', () async {
      await chatbotService.initialize();

      final suggestions = chatbotService.getSuggestions();

      expect(suggestions, isNotEmpty);
      expect(suggestions, isA<List<String>>());
      expect(suggestions.every((s) => s.isNotEmpty), true);
    });
  });
}
