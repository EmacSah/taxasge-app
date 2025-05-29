// test/dao/document_requis_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/document_requis_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/document_requis.dart';   // modèle
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();

  group('DocumentRequisDao – tests combinés', () {
    late DatabaseService   dbService;
    late DocumentRequisDao documentRequisDao;

    const conceptoId = 'T-TEST-001';
    const docES1 = 'Copia del documento de identidad';
    const docES2 = 'Fotocopia del pasaporte vigente';

    setUp(() async {
      dbService         = await getTestDatabaseService(seedData: true);
      documentRequisDao = dbService.documentRequisDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => dbService.close());

    // ─────────── GOLDEN ───────────
    test('[Golden] total = 7', () async {
      expect(await documentRequisDao.count(), 7);
    });

    test('[Golden] 2 docs ES pour $conceptoId', () async {
      final docs = await documentRequisDao.getByConceptoId(conceptoId);
      expect(docs.length, 2);
      expect(docs.map((d) => d.getNombre('es')), containsAll([docES1, docES2]));
    });

    // ─────────── DYNAMIQUE ───────────
    test('update conserve les autres langues', () async {
      final doc = (await documentRequisDao.getByConceptoId(conceptoId)).first;

      final frExistait = doc.nombreTraductions.containsKey('fr');

      final modif = doc.copyWith(nombreTraductions: {
        ...doc.nombreTraductions,
        'es': 'Documento ES Actualizado',
      });
      await documentRequisDao.update(modif);

      final fetched = await documentRequisDao.getById(doc.id);
      expect(fetched!.getNombre('es'), 'Documento ES Actualizado');

      if (frExistait) {
        // la traduction FR n’a pas bougé
        expect(
          fetched.getNombre('fr'),
          doc.getNombre('fr'),
        );
      }
    });

    test('updateTranslation ne touche qu’une langue', () async {
      final doc = (await documentRequisDao.getByConceptoId(conceptoId)).first;

      await documentRequisDao.updateTranslation(
        doc.id,
        'fr',
        nombre: 'Document FR Modifié',
      );

      final updated = await documentRequisDao.getById(doc.id);
      expect(updated!.getNombre('fr'), 'Document FR Modifié');
      expect(updated.getNombre('es'), isNot(equals('Document FR Modifié')));
    });

    test('delete décrémente le total', () async {
      final totalAvant = await documentRequisDao.count();
      final doc        = (await documentRequisDao.getByConceptoId(conceptoId)).first;

      await documentRequisDao.delete(doc.id);

      expect(await documentRequisDao.count(), totalAvant - 1);
      expect(await documentRequisDao.getById(doc.id), isNull);
    });

    test('count reflète insert ▶ delete', () async {
      final start = await documentRequisDao.count();

      // insertion propre via le modèle
      final newId = await documentRequisDao.insert(
        DocumentRequis(
          id: 0,                           // auto-increment
          conceptoId: conceptoId,
          nombreTraductions: {
            'es': 'Anexo extra ES',
            'fr': 'Annexe extra FR',
          },
          //orden: 99,
        ),
      );

      expect(await documentRequisDao.count(), start + 1);

      await documentRequisDao.delete(newId);
      expect(await documentRequisDao.count(), start);
    });
  });
}
