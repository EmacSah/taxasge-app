// test/dao/concepto_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/concepto_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart';   // sqfliteTestInit + getTestDatabaseService

void main() {
  // Initialisation FFI (desktop / CI)
  sqfliteTestInit();

  group('ConceptoDao – tests combinés', () {
    late DatabaseService dbService;
    late ConceptoDao     conceptoDao;

    setUp(() async {
      // charge test/test_assets/test_taxes.json (+ seedData)
      dbService   = await getTestDatabaseService(seedData: true);
      conceptoDao = dbService.conceptoDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => dbService.close());

    // ───────────────────────────
    // 1)  GOLDEN / FIGÉ
    // ───────────────────────────
    test('[Golden] getById retourne le bon concept', () async {
      final concepto = await conceptoDao.getById('T-TEST-001');
      expect(concepto, isNotNull);
      expect(concepto!.getNombre('es'), 'CONCEPTO DE PRUEBA');
      expect(concepto.tasaExpedicion, '1000');
    });

    test('[Golden] le JSON de test contient 3 concepts', () async {
      expect((await conceptoDao.getAll()).length, 3);
    });

    test('[Golden] SC-TEST-001 ➜ 2 concepts', () async {
      final ids = (await conceptoDao.getBySubCategoriaId('SC-TEST-001'))
          .map((c) => c.id);
      expect(ids, containsAll(['T-TEST-001', 'T-TEST-002']));
    });

    // ───────────────────────────
    // 2)  DYNAMIQUE (CRUD)
    // ───────────────────────────
    test('update modifie bien la tasaExpedicion', () async {
      final original = (await conceptoDao.getById('T-TEST-001'))!;
      await conceptoDao.update(original.copyWith(tasaExpedicion: '1200'));

      final fetched = await conceptoDao.getById('T-TEST-001');
      expect(fetched!.tasaExpedicion, '1200');
    });

    test('delete retire un concept & count() décrémente', () async {
      final countAvant = await conceptoDao.count();
      await conceptoDao.delete('T-TEST-002');
      expect(await conceptoDao.getById('T-TEST-002'), isNull);
      expect(await conceptoDao.count(), countAvant - 1);
    });

    // ───────────────────────────
    // 3)  RECHERCHE
    // ───────────────────────────
    group('searchByName', () {
      test('ES : fragment “prueba” ➜ 2 résultats', () async {
        final res = await conceptoDao.searchByName('prueba', langCode: 'es');
        expect(res.map((c) => c.id), containsAll(['T-TEST-001', 'T-TEST-002']));
      });

      test('EN : “import” ➜ T-TEST-003', () async {
        final res = await conceptoDao.searchByName('import', langCode: 'en');
        expect(res.length, 1);
        expect(res.first.id, 'T-TEST-003');
      });
    });

    // ───────────────────────────
    // 4)  advancedSearch (exemple)
    // ───────────────────────────
    test('advancedSearch par ministerioId = 2 concepts', () async {
      final res = await conceptoDao.advancedSearch(
        ministerioId: 'M-TEST-001',
        langCode: 'es',
      );
      expect(res.length, 2); // T-TEST-001 + T-TEST-002
    });
  });
}
