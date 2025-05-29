import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:taxasge/main.dart' as app;
import 'package:taxasge/test/test_utils/test_config.dart';

void main() {
  // Initialise l'environnement d'intégration
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock des assets et initialisation de la base de données de test
    await TestConfig.initialize();
    await TestConfig.initializeDatabase(forceReset: true);
  });

  group('Integration Tests - TaxasGE', () {
    testWidgets('App launches and shows home screen',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Vérifier la présence du titre ou d'un élément clé de l'écran d'accueil
      expect(find.text('TaxasGE'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('Perform a search and display results',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Trouver le champ de recherche et y entrer du texte
      final Finder searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'passeport');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Vérifier que la liste de résultats contient au moins un élément
      final Finder resultItem = find.textContaining('Passeport');
      expect(resultItem, findsWidgets);
    });

    testWidgets('Open detail screen from search result',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Effectuer une recherche
      await tester.enterText(find.byType(TextField), 'passeport');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Taper sur le premier élément pour ouvrir l'écran de détail
      final Finder firstItem = find.byType(ListTile).first;
      expect(firstItem, findsOneWidget);
      await tester.tap(firstItem);
      await tester.pumpAndSettle();

      // Vérifier la présence des informations détaillées
      expect(find.textContaining('Taux d\'expédition'), findsOneWidget);
      expect(find.textContaining('Documents requis'), findsOneWidget);
    });
  });
}
