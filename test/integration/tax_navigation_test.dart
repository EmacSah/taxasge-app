import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taxasge/main.dart' as app;
import 'package:taxasge/screens/tax_ministries_screen.dart';
import 'package:taxasge/screens/tax_sectors_screen.dart';
import 'package:taxasge/screens/tax_categories_screen.dart';
import 'package:taxasge/screens/tax_subcategories_screen.dart';
import 'package:taxasge/screens/tax_concepts_screen.dart';
import 'package:taxasge/screens/tax_detail_screen.dart';
import 'package:flutter/services.dart'; // Pour MethodChannel
import 'dart:io'; // Pour File
// import 'dart:convert'; // Pour utf8, pas nécessaire si readAsString est utilisé directement pour le cas succès
import 'dart:typed_data'; // Pour ByteData
import '../database_test_utils.dart'; // Pour sqfliteTestInit
import 'package:shared_preferences/shared_preferences.dart'; // Ajout oublié dans le prompt initial, mais nécessaire

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteTestInit();

  group('Tax Navigation Flow', () {
    setUpAll(() async {
      // TestWidgetsFlutterBinding.ensureInitialized(); // Déjà fait par IntegrationTestWidgetsFlutterBinding
      SharedPreferences.setMockInitialValues({}); // Ajout pour cohérence avec app_init_test

      // Configurer le mock pour rootBundle pour charger test_taxes.json
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'loadString') {
            final String? key = methodCall.arguments as String?;
            if (key == 'assets/data/taxes.json') {
              try {
                final file = File('test/test_assets/test_taxes.json'); // S'assurer que ce chemin est correct
                return await file.readAsString(); // loadString attend une String
              } catch (e) {
                print('Erreur chargement test_taxes.json dans tax_navigation_test: $e');
                // Retourner un JSON minimal valide pour éviter de planter si le fichier est manquant
                return '[]'; // Correct, loadString attend Future<String>, pas besoin de Future.value si c'est déjà une string
              }
            }
            // Mocks pour les tokenizers (contenu JSON string simple)
            if ((methodCall.arguments as String).contains('tokenizer.json')) {
              // Retourner un JSON de tokenizer valide minimal
              return '{}'; // Correct, loadString attend Future<String>
            }
          }
          if (methodCall.method == 'load') {
             final String? key = methodCall.arguments as String?;
            // Mock pour le modèle TFLite (ByteData)
            if (key == 'assets/ml/taxasge_model.tflite') {
              final ByteData header = ByteData(16); // Simuler l'en-tête si ModelService le lit
              header.setInt64(0, 0, Endian.little);
              header.setInt64(8, 0, Endian.little);
              return header.buffer.asByteData(); // Correct pour rootBundle.load
            }
          }
          print("Unhandled asset in mock for ${methodCall.method}: ${methodCall.arguments}");
          return null;
        },
      );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);
    });

    testWidgets('Full navigation from ministries to tax detail', (WidgetTester tester) async {
      // Il est crucial que test/test_assets/test_taxes.json contienne des données qui correspondent aux attentes.
      // Par exemple, un ministère nommé "MINISTERIO DE PRUEBA" qui a un secteur "SECTOR PRUEBA", etc.
      // et un concept "CONCEPTO DE PRUEBA" avec "tasa_expedicion": "100", et des documents/procédures.
      // Le minimalTestJson de database_test_utils.dart est un bon point de départ pour test_taxes.json.

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Laisser le temps pour l'initialisation

      // 1. TaxMinistriesScreen
      expect(find.byType(TaxMinistriesScreen), findsOneWidget, reason: "TaxMinistriesScreen should be visible");
      final ministerioTextFinder = find.text("MINISTERIO DE PRUEBA");
      expect(ministerioTextFinder, findsOneWidget, reason: "Text 'MINISTERIO DE PRUEBA' not found on TaxMinistriesScreen. Check test_taxes.json.");
      await tester.tap(ministerioTextFinder);
      await tester.pumpAndSettle();

      // 2. TaxSectorsScreen
      expect(find.byType(TaxSectorsScreen), findsOneWidget, reason: "TaxSectorsScreen should be visible");
      expect(find.widgetWithText(AppBar, "MINISTERIO DE PRUEBA"), findsOneWidget, reason: "AppBar title should be 'MINISTERIO DE PRUEBA'");
      final sectorTextFinder = find.text("SECTOR PRUEBA");
      expect(sectorTextFinder, findsOneWidget, reason: "Text 'SECTOR PRUEBA' not found on TaxSectorsScreen. Check test_taxes.json.");
      await tester.tap(sectorTextFinder);
      await tester.pumpAndSettle();

      // 3. TaxCategoriesScreen
      expect(find.byType(TaxCategoriesScreen), findsOneWidget, reason: "TaxCategoriesScreen should be visible");
      expect(find.widgetWithText(AppBar, "SECTOR PRUEBA"), findsOneWidget, reason: "AppBar title should be 'SECTOR PRUEBA'");
      final categoriaTextFinder = find.text("CATEGORIA PRUEBA");
      expect(categoriaTextFinder, findsOneWidget, reason: "Text 'CATEGORIA PRUEBA' not found on TaxCategoriesScreen. Check test_taxes.json.");
      await tester.tap(categoriaTextFinder);
      await tester.pumpAndSettle();

      // 4. TaxSubCategoriesScreen
      expect(find.byType(TaxSubCategoriesScreen), findsOneWidget, reason: "TaxSubCategoriesScreen should be visible");
      expect(find.widgetWithText(AppBar, "CATEGORIA PRUEBA"), findsOneWidget, reason: "AppBar title should be 'CATEGORIA PRUEBA'");
      final subCategoriaTextFinder = find.text("SUBCATEGORIA PRUEBA");
      expect(subCategoriaTextFinder, findsOneWidget, reason: "Text 'SUBCATEGORIA PRUEBA' not found on TaxSubCategoriesScreen. Check test_taxes.json.");
      await tester.tap(subCategoriaTextFinder);
      await tester.pumpAndSettle();

      // 5. TaxConceptsScreen
      expect(find.byType(TaxConceptsScreen), findsOneWidget, reason: "TaxConceptsScreen should be visible");
      expect(find.widgetWithText(AppBar, "SUBCATEGORIA PRUEBA"), findsOneWidget, reason: "AppBar title should be 'SUBCATEGORIA PRUEBA'");
      final conceptoTextFinder = find.text("CONCEPTO DE PRUEBA");
      expect(conceptoTextFinder, findsOneWidget, reason: "Text 'CONCEPTO DE PRUEBA' not found on TaxConceptsScreen. Check test_taxes.json.");
      await tester.tap(conceptoTextFinder);
      await tester.pumpAndSettle();

      // 6. TaxDetailScreen
      expect(find.byType(TaxDetailScreen), findsOneWidget, reason: "TaxDetailScreen should be visible");
      expect(find.widgetWithText(AppBar, "CONCEPTO DE PRUEBA"), findsOneWidget, reason: "AppBar title should be 'CONCEPTO DE PRUEBA'");
      // Vérifier quelques détails spécifiques du "CONCEPTO DE PRUEBA" de minimalTestJson/test_taxes.json
      expect(find.textContaining("Taxe d'expédition: 100"), findsOneWidget, reason: "Text 'Taxe d'expédition: 100' not found. Check TaxDetailScreen formatting and test_taxes.json data.");
      expect(find.textContaining("Doc1"), findsOneWidget, reason: "Document 'Doc1' not found. Check test_taxes.json.");
      expect(find.textContaining("Proc1"), findsOneWidget, reason: "Procedure 'Proc1' not found. Check test_taxes.json.");
      // Vérifier la présence du bouton favori
      expect(find.byIcon(Icons.star_border), findsOneWidget, reason: "Favorite button (star_border) not found."); // Ou Icons.star si déjà favori
    });
  });
}
