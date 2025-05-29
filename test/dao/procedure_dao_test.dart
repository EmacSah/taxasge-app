// test/dao/procedure_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/procedure_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/procedure.dart';
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart';   // sqfliteTestInit() + getTestDatabaseService()

void main() {
  // Initialise sqflite_common_ffi pour les environnements desktop / CI
  sqfliteTestInit();

  group('ProcedureDao – tests combinés', () {
    late DatabaseService dbService;
    late ProcedureDao    procedureDao;

    //------------------------------------------------------------------
    //  ⚙️  Références issues de test_taxes.json
    //------------------------------------------------------------------
    const conceptoId = 'T-TEST-001';

    // Trois étapes ES déclarées dans le JSON
    const paso1 = 'Paso 1: Llenar el formulario de solicitud';
    const paso2 = 'Paso 2: Presentar documentos requeridos';
    const paso3 = 'Paso 3: Pagar las tasas correspondientes';

    setUp(() async {
      dbService     = await getTestDatabaseService(seedData: true);
      procedureDao  = dbService.procedureDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => dbService.close());

    // ────────────────────────────────────────────────────────────────
    // 1.  Intégrité de l’import  (valeurs figées = golden)
    // ────────────────────────────────────────────────────────────────
    group('[Golden] Import integrity', () {
      test('Les 3 procédures ES sont bien importées', () async {
        final list = await procedureDao.getByConceptoId(conceptoId, langCode: 'es');

        expect(list.map((p) => p.getDescription('es')),
            containsAll([paso1, paso2, paso3]));
      });
    });

    // ────────────────────────────────────────────────────────────────
    // 2.  Comportement dynamique du DAO
    // ────────────────────────────────────────────────────────────────
    group('[Dynamic] DAO behaviour', () {
      //----------------------------------------------------------------
      test('getAll retourne toutes les lignes', () async {
        final all = await procedureDao.getAll();
        expect(all.length, 3);
      });

      //----------------------------------------------------------------
      test('Ordre : tri par "orden" puis description', () async {
        // insertion d’une étape supplémentaire (orden = 0)
        await procedureDao.insert(
          Procedure(
            id: 0,
            conceptoId: conceptoId,
            descriptionTraductions: {'es': 'Paso 0: Prerregistro'},
            orden: 0,
          ),
        );

        final list = await procedureDao.getByConceptoId(conceptoId, langCode: 'es');
        expect(list.first.getDescription('es'), startsWith('Paso 0'));
      });

      //----------------------------------------------------------------
      test('update modifie la description ES uniquement', () async {
        final proc = (await procedureDao.getByConceptoId(conceptoId)).first;

        final mod  = proc.copyWith(
          descriptionTraductions: {'es': 'Procedimiento actualizado ES'},
        );
        await procedureDao.update(mod);

        final fetched = await procedureDao.getById(proc.id);
        expect(fetched!.getDescription('es'), 'Procedimiento actualizado ES');
      });

      //----------------------------------------------------------------
      test('updateTranslation ajoute / remplace une langue', () async {
        final proc = (await procedureDao.getByConceptoId(conceptoId)).first;

        await procedureDao.updateTranslation(proc.id, 'fr', 'Procédure FR modifiée');
        final fetched = await procedureDao.getById(proc.id);

        expect(fetched!.getDescription('fr'), 'Procédure FR modifiée');
        expect(fetched.getDescription('es'), isNotEmpty);   // ES préservé
      });

      //----------------------------------------------------------------
      test('updateOrder met à jour le champ orden', () async {
        final proc = (await procedureDao.getByConceptoId(conceptoId)).first;

        await procedureDao.updateOrder(proc.id, 10);
        final updated = await procedureDao.getById(proc.id);

        expect(updated!.orden, 10);
      });

      //----------------------------------------------------------------
      test('delete retire une procédure et count est ajusté', () async {
        final before = await procedureDao.getByConceptoId(conceptoId);
        final toDel  = before.first;

        await procedureDao.delete(toDel.id);

        final after = await procedureDao.getByConceptoId(conceptoId);
        expect(after.length, before.length - 1);
        expect(await procedureDao.getById(toDel.id), isNull);
      });
    });
  });
}
