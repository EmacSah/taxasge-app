import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/categoria_dao.dart';
import 'package:taxasge/models/categoria.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart'; // sqfliteTestInit + getTestDatabaseService

void main() {
  // Initialise sqflite_common_ffi pour les tests desktop/CI
  sqfliteTestInit();

  group('CategoriaDao – tests combinés', () {
    late DatabaseService dbService;
    late CategoriaDao categoriaDao;

    setUp(() async {
      // Charge le jeu de données de test (test/test_assets/test_taxes.json par défaut)
      dbService = await getTestDatabaseService(seedData: true);
      categoriaDao = dbService.categoriaDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => await dbService.close());

    // ───────────────────────────
    // 1)  GOLDEN / FIGÉ (intégrité)
    // ───────────────────────────
    group('[Golden] Import integrity', () {
      test('getById retrouve C-TEST avec le bon nom ES', () async {
        final item = await categoriaDao.getById('C-TEST');
        expect(item, isNotNull);
        expect(item!.getNombre('es'), 'CATEGORIA PRUEBA');
      });

      test('getBySectorId renvoie exactement 1 catégorie pour S-TEST', () async {
        final items = await categoriaDao.getBySectorId('S-TEST', langCode: 'es');
        expect(items.length, 1);
      });
    });

    // ───────────────────────────
    // 2)  DYNAMIQUE (logique DAO)
    // ───────────────────────────
    group('[Dynamic] DAO behaviour', () {
      test('insert ajoute une nouvelle catégorie et getById la retrouve', () async {
        final nouvelle = Categoria(
          id: 'C-AAA',
          sectorId: 'S-TEST', // <--- ajouté
          nombreTraductions: {'es': 'Categoria AAA'},
        );
        await categoriaDao.insert(nouvelle);

        final fetched = await categoriaDao.getById('C-AAA');
        expect(fetched, isNotNull);
        expect(fetched!.getNombre('es'), 'Categoria AAA');
      });

      test('searchByName insensible à la casse et multilingue', () async {
        final resultEs = await categoriaDao.searchByName('prueba', langCode: 'es');
        expect(resultEs, isNotEmpty);

        for (final c in resultEs) {
          expect(c.getNombre('es').toLowerCase(), contains('prueba'));
        }
      });
    });
  });
}
