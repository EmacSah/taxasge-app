import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taxasge/main.dart' as app;
import 'package:taxasge/screens/chatbot_screen.dart';
// import 'package:taxasge/widgets/chat/chat_input.dart'; // Non utilisé directement
import 'package:taxasge/widgets/chat/message_bubble.dart';
// import 'package:taxasge/services/chatbot_service.dart'; // Non utilisé directement
// import 'package:provider/provider.dart'; // Non utilisé directement
import 'package:flutter/services.dart'; // Pour MethodChannel
import 'dart:io'; // Pour File
// import 'dart:convert'; // Pour utf8 - Non utilisé
import 'dart:typed_data'; // Pour ByteData
import '../database_test_utils.dart'; // Pour sqfliteTestInit
import 'package:shared_preferences/shared_preferences.dart'; // Ajouté pour SharedPreferences


void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteTestInit();

  group('Chatbot Flow Integration Test', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized(); // Redondant, IntegrationTestWidgetsFlutterBinding le fait.
      SharedPreferences.setMockInitialValues({});

      // Configurer le mock pour rootBundle pour charger test_taxes.json et les assets NLP
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          final String? key = methodCall.arguments as String?;
          if (key == 'assets/data/taxes.json') {
            try {
              final file = File('test/test_assets/test_taxes.json');
              return await file.readAsString();
            } catch (e) {
              return '[]'; // Fallback JSON valide minimal
            }
          }
          if (key == 'assets/ml/taxasge_model_question_tokenizer.json') {
            return '{"config": {"word_index": {"<OOV>": 1, "hola": 2}}}'; // Mock tokenizer
          }
          if (key == 'assets/ml/taxasge_model_answer_tokenizer.json') {
            return '{"config": {"word_index": {"<OOV>": 1, "<START>": 2, "saludos": 3, "<END>":4}}}'; // Mock tokenizer
          }
          if (key == 'assets/ml/taxasge_model.tflite') {
            // Simuler un fichier TFLite bidon avec l'en-tête si ModelService le lit
            final ByteData header = ByteData(256); // Assez grand pour éviter les erreurs de Range
            header.setInt64(0, 128, Endian.little); // Dummy encoder size
            header.setInt64(8, 128, Endian.little); // Dummy decoder size
            // Remplir avec des zéros pour simuler le reste du modèle
            for(int i = 16; i < header.lengthInBytes; i++) {
              header.setUint8(i,0);
            }
            return header.buffer.asByteData();
          }
          return null;
        },
      );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);
    });

    testWidgets('User sends a message and receives a response from chatbot', (WidgetTester tester) async {
      app.main(); // Lance l'application
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Laisser le temps pour l'initialisation

      // Supposons que l'application démarre sur un écran qui a un moyen de naviguer vers ChatbotScreen,
      // ou que ChatbotScreen est l'écran d'accueil pour ce test.
      // Pour ce test, nous allons modifier temporairement main.dart pour que home soit ChatbotScreen
      // ou ajouter un bouton pour y naviguer.
      // Pour l'instant, nous allons supposer que ChatbotScreen est accessible directement
      // ou que la navigation vers celui-ci est simple (par exemple, un bouton sur l'écran d'accueil)
      // Si TaxMinistriesScreen est le premier écran, il faudrait naviguer à partir de là.
      // Pour un test ciblé du chatbot, il est courant de le lancer directement.
      // Pour ce faire, nous pourrions avoir un main_test.dart ou modifier main.dart pour le test.
      // Ici, on va d'abord s'assurer qu'on est sur ChatbotScreen.
      // Si l'app démarre sur TaxMinistriesScreen:
      // expect(find.byType(TaxMinistriesScreen), findsOneWidget);
      // await tester.tap(find.byIcon(Icons.chat)); // Supposant une icône pour aller au chat
      // await tester.pumpAndSettle();
      
      // Naviguer vers ChatbotScreen si ce n'est pas l'écran d'accueil
      // Pour cet exemple, on va supposer que TaxasGEApp dans main.dart
      // a un BottomNavigationBar ou un Drawer qui permet d'aller à ChatbotScreen.
      // Ou, pour simplifier ce test, on pourrait faire en sorte que `home` dans `main.dart`
      // soit directement `ChatbotScreen()` pour ce test spécifique.
      // Pour l'instant, on va directement chercher des éléments de ChatbotScreen.
      
      // S'assurer que le ChatbotScreen est chargé (il a un AppBar avec "Assistant TaxasGE")
      // Si ce n'est pas l'écran initial, il faudrait ajouter la navigation ici.
      // Pour l'instant, on va supposer que l'on peut modifier main.dart pour que home: ChatbotScreen()
      // ou qu'il y a un moyen simple d'y accéder.
      // Le plus simple pour ce test est de modifier temporairement lib/main.dart pour que
      // la page d'accueil soit ChatbotScreen().
      // Sinon, il faut simuler la navigation.

      // Pour le test actuel, nous allons partir du principe que l'UI de base du chatbot est là.
      // On attend le message de bienvenue.
      expect(find.byType(ChatbotScreen), findsOneWidget); // S'assurer que l'écran est chargé

      // Attendre que le message de bienvenue s'affiche (peut prendre un instant après l'init)
      await tester.pumpAndSettle(const Duration(milliseconds: 500)); 
      expect(find.widgetWithText(MessageBubble, "¡Hola! Soy el asistente virtual de TaxasGE. ¿En qué puedo ayudarte?"), findsOneWidget); // Ou le message en 'es'

      // Trouver le TextField et le bouton d'envoi
      final textField = find.byType(TextField);
      final sendButton = find.byType(IconButton); // Ou le type de bouton que vous utilisez

      expect(textField, findsOneWidget);
      expect(sendButton, findsOneWidget);

      // Entrer un message
      const String userMessage = "Hola";
      await tester.enterText(textField, userMessage);
      await tester.pump(); // Reconstruire pour activer le bouton

      // Envoyer le message
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Laisser le temps au chatbot de "répondre"

      // Vérifier que le message de l'utilisateur est affiché
      expect(find.widgetWithText(MessageBubble, userMessage), findsOneWidget);

      // Vérifier qu'une réponse du bot est affichée
      // La réponse exacte dépendra du modèle NLP et de sa logique.
      // On cherche une MessageBubble qui N'EST PAS de l'utilisateur et qui n'est pas le message de bienvenue.
      final allMessageBubbles = tester.widgetList<MessageBubble>(find.byType(MessageBubble));
      expect(allMessageBubbles.length, greaterThanOrEqualTo(3)); // Bienvenue, User, Bot
      
      final botResponseBubble = allMessageBubbles.lastWhere((bubble) => !bubble.chatMessage.isUser);
      expect(botResponseBubble.chatMessage.text, isNotEmpty);
      // Pour un test plus précis, si vous connaissez la réponse attendue pour "Hola" avec le modèle mocké/réel:
      // expect(botResponseBubble.chatMessage.text, "Hola! ¿Cómo puedo ayudarte?"); // Ou réponse du vrai modèle
      // print("Réponse du bot observée: ${botResponseBubble.chatMessage.text}"); // Nettoyé

      // Vérifier si des suggestions s'affichent (optionnel, dépend de la réponse)
      // expect(find.byType(ActionChip), findsWidgets);
    });
  });
}
