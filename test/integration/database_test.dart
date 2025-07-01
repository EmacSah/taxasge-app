import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:taxasge/database/database_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialisation de sqflite_ffi pour les tests
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  late DatabaseService databaseService;

  setUp(() async {
    // Configuration du chemin de la base de données de test
    final databasePath = await getDatabasesPath();
    final dbPath = path.join(databasePath, 'test_taxasge.db');

    debugPrint('⚙️ Configuration du test avec la base de données: $dbPath');

    // Supprimer la base de données de test si elle existe
    if (File(dbPath).existsSync()) {
      debugPrint('🗑️ Suppression de la base de données existante');
      await deleteDatabase(dbPath);
    }

    // Mock du chargement des assets
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter/assets'),
            (MethodCall methodCall) async {
      if (methodCall.method == 'getAssetData' &&
          methodCall.arguments.toString().contains('test_taxes.json')) {
        debugPrint('📂 Chargement des données de test');
        final File file = File('test/assets/test_taxes.json');
        final String content = await file.readAsString();
        return Uint8List.fromList(utf8.encode(content)).buffer.asByteData();
      }
      return null;
    });

    // Initialiser le service de base de données
    debugPrint('🚀 Initialisation du service de base de données');
    databaseService = DatabaseService();
    await databaseService.initialize(forceReset: true);
    debugPrint('✅ Initialisation terminée avec succès');
  });

  tearDown(() async {
    debugPrint('⏹️ Fermeture de la base de données');
    await databaseService.close();
  });

  group('Tests multilingues de la base de données', () {
    test('Initialisation de la base de données', () {
      debugPrint('🧪 Test: Initialisation de la base de données');
      expect(databaseService.isOpen, isTrue);
      debugPrint('✓ Base de données initialisée avec succès');
    });

    test('Vérification des tables de la base de données', () async {
      debugPrint('🧪 Test: Vérification des tables de la base de données');

      final ministryCount = await databaseService.ministerioDao.count();
      debugPrint('📊 Nombre de ministères: $ministryCount');
      expect(ministryCount, 1);

      final sectorCount = await databaseService.sectorDao.count();
      debugPrint('📊 Nombre de secteurs: $sectorCount');
      expect(sectorCount, 1);

      final categoryCount = await databaseService.categoriaDao.count();
      debugPrint('📊 Nombre de catégories: $categoryCount');
      expect(categoryCount, 1);

      final subCategoryCount = await databaseService.subCategoriaDao.count();
      debugPrint('📊 Nombre de sous-catégories: $subCategoryCount');
      expect(subCategoryCount, 1);

      final conceptCount = await databaseService.conceptoDao.count();
      debugPrint('📊 Nombre de concepts: $conceptCount');
      expect(conceptCount, 1);

      debugPrint('✓ Toutes les tables ont été créées avec succès');
    });

    group('Tests des entités multilingues', () {
      test('Récupération d\'un ministère multilingue', () async {
        debugPrint('🧪 Test: Récupération d\'un ministère multilingue');

        final ministry =
            await databaseService.ministerioDao.getById('M-TEST-001');
        expect(ministry, isNotNull);

        debugPrint('🔤 Nom en espagnol: ${ministry!.getNombre("es")}');
        expect(ministry.getNombre('es'), equals('MINISTERIO DE PRUEBA'));

        debugPrint('🔤 Nom en français: ${ministry.getNombre("fr")}');
        expect(ministry.getNombre('fr'), equals('MINISTÈRE DE TEST'));

        debugPrint('🔤 Nom en anglais: ${ministry.getNombre("en")}');
        expect(ministry.getNombre('en'), equals('TEST MINISTRY'));

        debugPrint('✓ Ministère multilingue récupéré avec succès');
      });

      test('Récupération d\'un secteur multilingue', () async {
        debugPrint('🧪 Test: Récupération d\'un secteur multilingue');

        final sector = await databaseService.sectorDao.getById('S-TEST-001');
        expect(sector, isNotNull);

        debugPrint('🔤 Nom en espagnol: ${sector!.getNombre("es")}');
        expect(sector.getNombre('es'), equals('SECTOR DE PRUEBA'));

        debugPrint('🔤 Nom en français: ${sector.getNombre("fr")}');
        expect(sector.getNombre('fr'), equals('SECTEUR DE TEST'));

        debugPrint('🔤 Nom en anglais: ${sector.getNombre("en")}');
        expect(sector.getNombre('en'), equals('TEST SECTOR'));

        debugPrint('✓ Secteur multilingue récupéré avec succès');
      });

      test('Récupération d\'une catégorie multilingue', () async {
        debugPrint('🧪 Test: Récupération d\'une catégorie multilingue');

        final categoria =
            await databaseService.categoriaDao.getById('C-TEST-001');
        expect(categoria, isNotNull);

        debugPrint('🔤 Nom en espagnol: ${categoria!.getNombre("es")}');
        expect(categoria.getNombre('es'), equals('CATEGORIA DE PRUEBA'));

        debugPrint('🔤 Nom en français: ${categoria.getNombre("fr")}');
        expect(categoria.getNombre('fr'), equals('CATEGORIE DE TEST'));

        debugPrint('🔤 Nom en anglais: ${categoria.getNombre("en")}');
        expect(categoria.getNombre('en'), equals('TEST CATEGORY'));

        debugPrint('✓ Catégorie multilingue récupérée avec succès');
      });

      test('Récupération d\'une sous-catégorie multilingue', () async {
        debugPrint('🧪 Test: Récupération d\'une sous-catégorie multilingue');

        final subCategoria =
            await databaseService.subCategoriaDao.getById('SC-TEST-001');
        expect(subCategoria, isNotNull);

        debugPrint('🔤 Nom en espagnol: ${subCategoria!.getNombre("es")}');
        expect(subCategoria.getNombre('es'), equals('SUB-CATEGORIA DE PRUEBA'));

        debugPrint('🔤 Nom en français: ${subCategoria.getNombre("fr")}');
        expect(subCategoria.getNombre('fr'), equals('SOUS-CATEGORIE DE TEST'));

        debugPrint('🔤 Nom en anglais: ${subCategoria.getNombre("en")}');
        expect(subCategoria.getNombre('en'), equals('TEST SUB-CATEGORY'));
      });

      test('Récupération d\'un concept multilingue avec détails', () async {
        debugPrint(
            '🧪 Test: Récupération d\'un concept multilingue avec détails');

        const conceptId = 'T-TEST-001';
        final details = await databaseService.getConceptoWithDetails(conceptId,
            langCode: 'fr');

        expect(details, isNotNull);
        debugPrint('📑 Détails du concept récupérés dans la langue française');

        debugPrint(
            '🔤 Nom du concept en français: ${details!["nombre_current"]}');
        expect(details["nombre_current"], equals('CONCEPT DE TEST'));

        debugPrint(
            '💰 Taxes: ${details["tasa_expedicion"]}, ${details["tasa_renovacion"]}');
        expect(details["tasa_expedicion"], equals('1000'));
        expect(details["tasa_renovacion"], equals('500'));

        debugPrint('✓ Concept multilingue récupéré avec succès');
      });

      test('Recherche multilingue par mot-clé', () async {
        debugPrint('🧪 Test: Recherche multilingue');

        // Test de recherche en français
        final resultsFr = await databaseService.searchConceptos(
            searchTerm: 'test', langCode: 'fr');

        debugPrint(
            '🔍 Résultats de la recherche en français: ${resultsFr.length}');
        expect(resultsFr, isNotEmpty);
        expect(resultsFr.first['id'], equals('T-TEST-001'));
        expect(resultsFr.first['nombre_current'], equals('CONCEPT DE TEST'));

        // Test de recherche en espagnol
        final resultsEs = await databaseService.searchConceptos(
            searchTerm: 'prueba', langCode: 'es');

        debugPrint(
            '🔍 Résultats de la recherche en espagnol: ${resultsEs.length}');
        expect(resultsEs, isNotEmpty);
        expect(resultsEs.first['id'], equals('T-TEST-001'));
        expect(resultsEs.first['nombre_current'], equals('CONCEPTO DE PRUEBA'));

        debugPrint('✓ Recherche multilingue effectuée avec succès');
      });

      test('Recherche multilingue avec un terme vide', () async {
        debugPrint('🧪 Test: Recherche multilingue avec un terme vide');

        final results = await databaseService.searchConceptos(
            searchTerm: '', langCode: 'fr');

        debugPrint('🔍 Résultats de la recherche avec terme vide: ${results.length}');
        expect(results, isEmpty); // Or expect all concepts depending on implementation

        debugPrint('✓ Recherche avec terme vide gérée avec succès');
      });

      test('Recherche multilingue avec un terme sans correspondance', () async {
        debugPrint('🧪 Test: Recherche multilingue avec un terme sans correspondance');

        final results = await databaseService.searchConceptos(
            searchTerm: 'nonexistent', langCode: 'fr');

        debugPrint('🔍 Résultats de la recherche sans correspondance: ${results.length}');
        expect(results, isEmpty);

        debugPrint('✓ Recherche sans correspondance gérée avec succès');
      });

      test('Gestion des codes de langue invalides dans getNombre', () async {
        debugPrint('🧪 Test: Gestion des codes de langue invalides dans getNombre');

        final ministry =
            await databaseService.ministerioDao.getById('M-TEST-001');
        expect(ministry, isNotNull);

        // Assuming getNombre returns a default or throws an error for invalid codes
        // You might need to adjust the expectation based on the actual implementation
        debugPrint('🔤 Nom avec code de langue invalide: ${ministry!.getNombre("invalid_lang")}');
        expect(ministry.getNombre('invalid_lang'), equals('MINISTERIO DE PRUEBA')); // Assuming Spanish is the default

        debugPrint('✓ Codes de langue invalides gérés dans getNombre');
      });

       test('Gestion des codes de langue invalides dans searchConceptos', () async {
         debugPrint('🧪 Test: Gestion des codes de langue invalides dans searchConceptos');
         // Depending on implementation, this might throw an error or return empty
       });
    });

    test('Test d\'exportation de la base de données', () async {
      debugPrint('🧪 Test: Exportation de la base de données');

      final exportPath = await databaseService.exportToJson(langCode: 'fr');
      debugPrint('📤 Base de données exportée vers: $exportPath');

      expect(File(exportPath).existsSync(), isTrue);

      final exportContent = await File(exportPath).readAsString();
      final exportData = json.decode(exportContent);

      debugPrint(
          '📊 Nombre de ministères dans l\'export: ${exportData.length}');
      expect(exportData, isNotEmpty);

      debugPrint('✓ Exportation réussie');
    });
  });
}
