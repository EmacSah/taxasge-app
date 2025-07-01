import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxasge/services/localization_service.dart';
import 'package:taxasge/database/schema.dart'; // Pour defaultLanguage et supportedLanguages
import 'package:flutter/material.dart'; // Pour Locale et TextDirection

// Importez sqflite_common_ffi et dart:io
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() {
  // Ajoutez ce bloc setUpAll pour initialiser Sqflite FFI pour les tests
  setUpAll(() async {
    // Initialisation conditionnelle pour les plateformes de bureau ou les tests FFI
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Si votre service de localisation dépend de DatabaseService, vous pourriez avoir besoin
    // d'initialiser également la base de données de test ici.
    // import 'package:taxasge/database/database_service.dart'; // Décommenter si nécessaire
    // await DatabaseService.instance.initializeForTesting(); // Décommenter et adapter si nécessaire
  });

  // Vous pouvez ajouter un bloc tearDownAll ici si vous avez besoin de nettoyer des ressources
  // après l'exécution de tous les tests dans ce fichier (par exemple, fermer la base de données).
  // tearDownAll(() async {
  //   // Nettoyage des ressources après les tests
  //   // Par exemple: await DatabaseService.instance.closeDatabase();
  // });

  group('LocalizationService Tests', () {
    late LocalizationService localizationService;

    setUp(() async {
      // Initialiser SharedPreferences pour les tests
      SharedPreferences.setMockInitialValues({});
      localizationService = LocalizationService.instance;
      // Réinitialiser le service avant chaque test pour assurer l'isolation
      // car c'est un singleton. Il faut une méthode pour cela ou le réinstancier.
      // Pour l'instant, on suppose qu'initialize() peut le réinitialiser.
      await localizationService.initialize();
    });

    // Le test qui échoue pour le format de date (ancien)
    test('formatDate formats correctly for current language', () {
      // Supposons que vous avez une date à formater et que la méthode formatDate est accessible
      // via localizationService.
      // Exemple (adaptez à votre code réel):
      // final dateToFormat = DateTime(2023, 10, 26);
      // final formattedDate = localizationService.formatDate(dateToFormat);

      // L'assertion actuelle qui attend un format spécifique
      // expect(localizationService.currentLanguage, DatabaseSchema.defaultLanguage); // Ceci teste la langue, pas le format de date
      // expect(formattedDate, '10/26/2023'); // L'assertion pour le format de date qui échoue

      // Vous devrez adapter cette assertion en fonction de la locale active pendant le test
      // et du format attendu pour cette locale.
      // Exemple si la locale de test donne jj/mm/aaaa:
      // expect(formattedDate, '26/10/2023');
    });

    test('initializes with default language', () {
      expect(
          localizationService.currentLanguage, DatabaseSchema.defaultLanguage);
      expect(localizationService.isInitialized, isTrue);
    });

    test('setLanguage updates currentLanguage and notifies listeners',
        () async {
      String? newLang;
      localizationService.addListener(() {
        newLang = localizationService.currentLanguage;
      });

      await localizationService.setLanguage('fr');
      expect(localizationService.currentLanguage, 'fr');
      expect(newLang, 'fr');

      // Essayer une langue non supportée
      expect(() async => await localizationService.setLanguage('xx'),
          throwsArgumentError);
    });

    test('getTranslation returns correct translation based on current language',
        () async {
      final translations = {
        'es': 'Hola',
        'fr': 'Bonjour',
        'en': 'Hello',
      };

      await localizationService.setLanguage('es');
      expect(localizationService.getTranslation(translations), 'Hola');

      await localizationService.setLanguage('fr');
      expect(localizationService.getTranslation(translations), 'Bonjour');

      await localizationService.setLanguage('en');
      expect(localizationService.getTranslation(translations), 'Hello');
    });

    test(
        'getTranslation falls back to default/first available if current is missing',
        () async {
      final translations = {
        'es': 'Hola',
        // 'fr' est manquant
        'en': 'Hello',
      };
      await localizationService.setLanguage('fr'); // Langue actuelle est 'fr'
      // Doit tomber sur 'es' (defaultLanguage) ou 'en' (premier non vide)
      // Comportement exact dépend de l'ordre interne et de DatabaseSchema.defaultLanguage
      // Supposons que defaultLanguage est 'es' et qu'il est prioritaire
      expect(localizationService.getTranslation(translations), 'Hola');

      final translationsOnlyEn = {'en': 'Hello Only'};
      await localizationService.setLanguage('fr');
      expect(
          localizationService.getTranslation(translationsOnlyEn), 'Hello Only');

      expect(localizationService.getTranslation(null), '');
      expect(localizationService.getTranslation({}), '');
    });

    test('formatDate formats correctly for current language', () async {
      final date = DateTime(2023, 10, 26);

      await localizationService.setLanguage('es');
      expect(localizationService.formatDate(date), '26/10/2023');

      await localizationService.setLanguage('en');
      expect(localizationService.formatDate(date), '10/26/2023');

      await localizationService.setLanguage('fr');
      expect(localizationService.formatDate(date), '26/10/2023');

      // Test avec format personnalisé
      expect(localizationService.formatDate(date, format: 'yyyy-MM-dd'),
          '2023-10-26');
    });

    test('textDirection returns correct direction for language', () async {
      await localizationService.setLanguage('es'); // LTR
      expect(localizationService.textDirection, TextDirection.ltr);

      await localizationService.setLanguage('en'); // LTR
      expect(localizationService.textDirection, TextDirection.ltr);

      // Supposons que 'ar' (arabe) soit ajouté comme langue RTL supportée pour tester
      // Pour l'instant, aucune langue RTL n'est dans DatabaseSchema.supportedLanguages
      // donc on ne peut pas tester directement le cas RTL sans modifier cela.
      // Si on ajoutait 'ar' :
      // await localizationService.setLanguage('ar');
      // expect(localizationService.textDirection, TextDirection.rtl);
    });
  });
}
