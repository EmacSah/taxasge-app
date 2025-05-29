import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/sub_categoria_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart';  // sqfliteTestInit() + getTestDatabaseService()

void main() {
  // Initialise sqflite_common_ffi.
  sqfliteTestInit();

  group('SubCategoriaDao – tests combinés', () {
    late DatabaseService dbService;
    late SubCategoriaDao subCategoriaDao;

    // IDs et noms réels du fichier test_taxes.json
    const es = 'es', fr = 'fr', en = 'en';
    const subCatId    = 'SC-TEST-001';
    const categoriaId = 'C-TEST-001';
    const expectedNames = {
      es: 'SUBCATEGORIA DE PRUEBA',
      fr: 'SOUS-CATÉGORIE DE TEST',
      en: 'TEST SUBCATEGORY',
    };

    setUp(() async {
      // Charge le jeu de données complet test_taxes.json
      dbService = await getTestDatabaseService(seedData: true);
      subCategoriaDao = dbService.subCategoriaDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage(es); // langue par défaut
    });

    tearDown(() async => dbService.close());

    // ─────────────────────────────────────────────────────────────
    // 1)  Intégrité de l’import (golden = valeurs figées)
    // ─────────────────────────────────────────────────────────────
    test('[Golden] getById retourne la sous-catégorie multilingue', () async {
      final sc = await subCategoriaDao.getById(subCatId);
      expect(sc, isNotNull);

      expectedNames.forEach((lang, nomAttendu) {
        expect(sc!.getNombre(lang), nomAttendu,
            reason: 'Nom $lang doit être "$nomAttendu"');
      });
    });

    // ─────────────────────────────────────────────────────────────
    // 2)  Comportement DAO dynamique
    // ─────────────────────────────────────────────────────────────
    test('[Dynamic] getByCategoriaId renvoie au moins 1 ligne', () async {
      final list = await subCategoriaDao.getByCategoriaId(categoriaId, langCode: es);
      expect(list, isNotEmpty);
      expect(list.first.getNombre(es), expectedNames[es]);
    });
  });
}
