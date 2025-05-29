// test/dao/sector_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/sector_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart';   // sqfliteTestInit(), getTestDatabaseService()

void main() {
  // Initialise sqflite_common_ffi pour les tests desktop/CI
  sqfliteTestInit();

  group('SectorDao – tests combinés', () {
    late DatabaseService dbService;
    late SectorDao sectorDao;

    setUp(() async {
      // Charge le jeu de données de test (test/test_assets/test_taxes.json par défaut)
      dbService = await getTestDatabaseService(seedData: true);
      sectorDao = dbService.sectorDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => dbService.close());

    // ───────────────────────────
    // 1)  GOLDEN / FIGÉ (intégrité)
    // ───────────────────────────
    group('[Golden] Import integrity', () {
      test('Le dataset contient exactement 2 ministères', () async {
        final ministerios = await dbService.ministerioDao.getAll();
        expect(ministerios.length, 2);           // valeur figée du JSON
      });

      test('Le secteur S-TEST-001 existe et possède le bon nom ES', () async {
        final sector = await sectorDao.getById('S-TEST-001');
        expect(sector, isNotNull);
        expect(sector!.getNombre('es'), 'SECTOR DE PRUEBA');
      });
    });

    // ───────────────────────────
    // 2)  DYNAMIQUE (logique DAO)
    // ───────────────────────────
    group('[Dynamic] DAO behaviour', () {
      test('Tous les secteurs récupérés appartiennent bien à leur ministère', () async {
        final ministerios = await dbService.ministerioDao.getAll();
        for (final min in ministerios) {
          final sectores = await sectorDao.getByMinisterioId(min.id);
          // Chaque secteur doit avoir le bon ministerioId
          for (final s in sectores) {
            expect(s.ministerioId, min.id,
                reason: 'Sector ${s.id} doit référencer ${min.id}');
          }
        }
      });

      test('Au moins un secteur par ministère (structure cohérente)', () async {
        final ministerios = await dbService.ministerioDao.getAll();
        for (final min in ministerios) {
          final sectores = await sectorDao.getByMinisterioId(min.id);
          expect(sectores, isNotEmpty,
              reason: 'Le ministère ${min.id} devrait avoir ≥1 secteur');
        }
      });

      test('Recherche par nom (case-insensitive, multi-langues)', () async {
        // On ne connaît pas forcément le nom exact -> on cherche un fragment
        final resultEs = await sectorDao.searchByName('Prueba', langCode: 'es');
        final resultFr = await sectorDao.searchByName('Financier', langCode: 'fr');

        // On s’attend simplement à ≥1 résultat cohérent, sans figer les IDs
        expect(resultEs, isNotEmpty);
        expect(resultFr, isNotEmpty);

        // Tous les noms retournés doivent contenir le fragment
        for (final sec in resultEs) {
          expect(sec.getNombre('es').toLowerCase(), contains('prueba'));
        }
        for (final sec in resultFr) {
          expect(sec.getNombre('fr').toLowerCase(), contains('financier'));
        }
      });
    });
  });
}
