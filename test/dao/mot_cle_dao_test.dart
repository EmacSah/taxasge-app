// test/dao/mot_cle_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/mot_cle_dao.dart';
import 'package:taxasge/database/database_service.dart';

import '../database_test_utils.dart';   // sqfliteTestInit() + getTestDatabaseService()

void main() {
  // nécessaire pour sqflite_common_ffi sur desktop/CI
  sqfliteTestInit();

  group('MotCleDao – tests combinés', () {
    late DatabaseService dbService;
    late MotCleDao       motCleDao;

    // premier concept du jeu de données
    const conceptoId = 'T-TEST-001';

    // -------------------- Valeurs figées du JSON --------------------
    const esWords = ['prueba', 'test', 'ejemplo', 'muestra'];
    const frWords = ['test', 'exemple', 'essai', 'échantillon'];
    const enWords = ['test', 'example', 'sample', 'specimen'];

    setUp(() async {
      dbService = await getTestDatabaseService(seedData: true);
      motCleDao = dbService.motCleDao;
    });

    tearDown(() async => dbService.close());

    // ─────────────────────────────────────────────
    // 1.  GOLDEN  – intégrité de l’import initial
    // ─────────────────────────────────────────────
    group('[Golden] Import integrity', () {
      test('Liste ES complète', () async {
        final list = await motCleDao.getMotsClesByConceptoId(
          conceptoId,
          langCode: 'es',
        );
        expect(list, containsAll(esWords));
      });

      test('Structure multilingue ES / FR / EN', () async {
        final multi =
            await motCleDao.getMotsClesMultilinguesByConceptoId(conceptoId);

        expect(multi.motsClesByLang.keys, containsAll(['es', 'fr', 'en']));
        expect(multi.motsClesByLang['es'], containsAll(esWords));
        expect(multi.motsClesByLang['fr'], containsAll(frWords));
        expect(multi.motsClesByLang['en'], containsAll(enWords));
      });
    });

    // ─────────────────────────────────────────────
    // 2.  DYNAMIC – comportement CRUD du DAO
    // ─────────────────────────────────────────────
    group('[Dynamic] DAO behaviour', () {
      test('deleteByConceptoId supprime toutes les traductions', () async {
        await motCleDao.deleteByConceptoId(conceptoId);

        // ES doit être vide
        final es =
            await motCleDao.getMotsClesByConceptoId(conceptoId, langCode: 'es');
        expect(es, isEmpty);

        // Toutes les cartes langue doivent être vides
        final multi =
            await motCleDao.getMotsClesMultilinguesByConceptoId(conceptoId);
        final everyLangEmpty =
            multi.motsClesByLang.values.every((l) => l.isEmpty);
        expect(everyLangEmpty, isTrue);
      });
    });
  });
}
