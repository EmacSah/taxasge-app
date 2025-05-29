import 'dart:async'; // Required for Completer

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/widgets/chat/chat_input.dart'; // Ajuste le chemin si nécessaire
import 'package:taxasge/theme/app_theme.dart'; // Pour le thème si des styles spécifiques sont appliqués

// Un widget wrapper pour fournir MaterialApp et le thème
Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.lightTheme, // Utiliser un thème par défaut
    home: Scaffold(body: child),
  );
}

void main() {
  group('ChatInput Tests', () {
    testWidgets('renders TextField and Send Button', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(
        child: ChatInput(onSendMessage: (message) async {}),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget); // Ou ElevatedButton/TextButton selon l'implémentation
    });

    testWidgets('Send Button is disabled when TextField is empty', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(
        child: ChatInput(onSendMessage: (message) async {}),
      ));

      final sendButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(sendButton.onPressed, isNull); // onPressed est null quand le bouton est désactivé
    });

    testWidgets('Send Button is enabled when TextField is not empty', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(
        child: ChatInput(onSendMessage: (message) async {}),
      ));

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump(); // Reconstruire le widget après la saisie

      final sendButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('calls onSendMessage when Send Button is tapped and clears TextField', (WidgetTester tester) async {
      String? sentMessage;
      await tester.pumpWidget(makeTestableWidget(
        child: ChatInput(onSendMessage: (message) async {
          sentMessage = message;
        }),
      ));

      await tester.enterText(find.byType(TextField), 'Test Message');
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle(); // Attendre que les animations/futures se terminent

      expect(sentMessage, 'Test Message');
      expect(find.widgetWithText(TextField, ''), findsOneWidget); // TextField devrait être vide
    });

    testWidgets('Send Button is disabled during async onSendMessage call', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      await tester.pumpWidget(makeTestableWidget(
        child: ChatInput(onSendMessage: (message) async {
          await completer.future; // Simuler un appel asynchrone long
        }),
      ));

      await tester.enterText(find.byType(TextField), 'Async Test');
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump(); // Début de l'appel _sendMessage

      // Le bouton devrait être désactivé (isSending = true)
      IconButton sendButton = tester.widget(find.byType(IconButton));
      expect(sendButton.onPressed, isNull); 

      completer.complete(); // Terminer l'appel asynchrone
      await tester.pumpAndSettle(); // Laisser le temps de reconstruire

      // Le bouton devrait être ré-activé (mais vide, donc désactivé à nouveau)
      sendButton = tester.widget(find.byType(IconButton));
      expect(sendButton.onPressed, isNull); // Vide donc désactivé
      
      // Entrer du texte à nouveau pour vérifier qu'il est bien réactivable
      await tester.enterText(find.byType(TextField), 'After Async');
      await tester.pump();
      sendButton = tester.widget(find.byType(IconButton));
      expect(sendButton.onPressed, isNotNull);
    });
    
    testWidgets('submitting TextField calls onSendMessage', (WidgetTester tester) async {
      String? sentMessage;
      await tester.pumpWidget(makeTestableWidget(
        child: ChatInput(onSendMessage: (message) async {
          sentMessage = message;
        }),
      ));

      await tester.enterText(find.byType(TextField), 'Submit Message');
      await tester.pump();
      
      // Utiliser testTextInput.receiveAction au lieu de .submit(), car .submit() est pour les formulaires.
      // TextInputAction.done est généralement l'action pour "envoyer" depuis le clavier.
      // Il faut s'assurer que le TextField dans ChatInput a textInputAction: TextInputAction.send ou similaire.
      // Et que onSubmitted est bien configuré pour appeler _sendMessage.
      // L'implémentation de ChatInput utilise onSubmitted: (_) => _sendMessage(),
      // et textInputAction: TextInputAction.send. Donc .done ou .send devrait fonctionner.
      // testTextInput.receiveAction(TextInputAction.done) ou testTextInput.receiveAction(TextInputAction.send)
      // En fonction de ce que le clavier simule. Souvent .done est plus générique.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(sentMessage, 'Submit Message');
      expect(find.widgetWithText(TextField, ''), findsOneWidget);
    });

  });
}
