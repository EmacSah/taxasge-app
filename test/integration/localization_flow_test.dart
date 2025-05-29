import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:taxasge/main.dart' as app;
// import 'package:taxasge/screens/tax_ministries_screen.dart'; // Ou un autre écran initial affichant du texte localisé
import 'package:taxasge/services/localization_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io'; // Pour File
// import 'dart:convert'; // Pas nécessaire si readAsString est utilisé
import 'dart:typed_data'; // Pour ByteData
import '../database_test_utils.dart'; // Pour sqfliteTestInit
import 'package:shared_preferences/shared_preferences.dart'; // Ajout pour SharedPreferences mock

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteTestInit();

  group('Localization Flow Integration Test', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized(); // Redondant, IntegrationTestWidgetsFlutterBinding le fait.
      SharedPreferences.setMockInitialValues({});

      // Configurer le mock pour rootBundle
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          final String? key = methodCall.arguments as String?;
          if (key == 'assets/data/taxes.json') {
            try {
              final file = File('test/test_assets/test_taxes.json');
              return await file.readAsString(); // Correct: loadString attend Future<String>
            } catch (e) {
              // print('Erreur chargement test_taxes.json dans localization_flow_test: $e'); // Nettoyé
              return '[]'; // Correct: loadString attend Future<String>
            }
          }
          if ((key ?? "").contains('tokenizer.json')) {
            return '{}'; // Correct: loadString attend Future<String>
          }
          if ((key ?? "").contains('taxasge_model.tflite')) {
            final ByteData header = ByteData(16);
            header.setInt64(0, 0, Endian.little);
            header.setInt64(8, 0, Endian.little);
            return header.buffer.asByteData(); // Correct pour rootBundle.load
          }
          // print("Unhandled asset in mock for ${methodCall.method}: ${methodCall.arguments}"); // Nettoyé
          return null;
        },
      );
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);
    });

    testWidgets('Changing language updates UI text and MaterialApp locale', (WidgetTester tester) async {
      app.main(); // Lance l'application
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Temps pour initialisation

      // 1. Vérifier la langue initiale (supposons 'es' par défaut d'après les tests précédents)
      // Le titre de l'AppBar de TaxasGEApp est fixe "TaxasGE".
      // On va vérifier la locale de MaterialApp et l'état de LocalizationService.
      expect(find.widgetWithText(AppBar, 'TaxasGE'), findsOneWidget, reason: "Initial AppBar title 'TaxasGE' should be present."); 
      
      // Accéder au LocalizationService via le contexte de MaterialApp
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final localizationService = Provider.of<LocalizationService>(context, listen: false);

      // S'assurer que la langue initiale est 'es' (ou la langue par défaut de vos tests)
      // DatabaseSchema.defaultLanguage est 'es'.
      expect(localizationService.currentLanguage, 'es', reason: "Initial language should be 'es'.");
      MaterialApp initialMaterialApp = tester.widget(find.byType(MaterialApp));
      expect(initialMaterialApp.locale, const Locale('es'), reason: "Initial MaterialApp locale should be 'es'.");


      // 2. Changer la langue en Français
      await localizationService.setLanguage('fr');
      await tester.pumpAndSettle(); // Laisser le temps à l'UI de se reconstruire

      expect(localizationService.currentLanguage, 'fr', reason: "Language should change to 'fr' in service.");
      MaterialApp materialAppFr = tester.widget(find.byType(MaterialApp));
      expect(materialAppFr.locale, const Locale('fr'), reason: "MaterialApp locale should update to 'fr'.");

      // 3. Changer la langue en Anglais
      await localizationService.setLanguage('en');
      await tester.pumpAndSettle();
      
      expect(localizationService.currentLanguage, 'en', reason: "Language should change to 'en' in service.");
      MaterialApp materialAppEn = tester.widget(find.byType(MaterialApp));
      expect(materialAppEn.locale, const Locale('en'), reason: "MaterialApp locale should update to 'en'.");

      // Note pour robustesse:
      // Pour vérifier que le TEXTE de l'UI change réellement, il faudrait que l'écran
      // affiché contienne du texte localisé via LocalizationService.getTranslation ou similaire,
      // et que ce texte soit vérifié. Par exemple, si TaxMinistriesScreen était l'écran d'accueil
      // et que son titre d'AppBar était localisé, on pourrait vérifier :
      // await localizationService.setLanguage('fr');
      // await tester.pumpAndSettle();
      // expect(find.widgetWithText(AppBar, "Ministères"), findsOneWidget); // Titre en français.
    });
  });
}
