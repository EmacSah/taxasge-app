// ──────────────────────────────────────────────────────────────────────────────
// test/dao/ministerio_dao_test.dart
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/ministerio_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/ministerio.dart';
import 'package:taxasge/services/localization_service.dart';

import '../database_test_utils.dart'; // sqfliteTestInit() + getTestDatabaseService()

void main() {
  // Initialisation sqflite_common_ffi pour les tests desktop / CI
  sqfliteTestInit();

  group('MinisterioDao – tests combinés', () {
    late DatabaseService dbService;
    late MinisterioDao ministerioDao;

    const idRef = 'M-TEST-001'; // présent dans test_taxes.json

    setUp(() async {
      // Crée une DB en mémoire et importe test_taxes.json
      dbService = await getTestDatabaseService(seedData: true);
      ministerioDao = dbService.ministerioDao;

      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => dbService.close());

    // ───────────────────────────
    // 1)  GOLDEN / FIGÉ
    // ───────────────────────────
    group('[Golden] Import integrity', () {
      test('Le ministère $idRef existe avec nom ES / FR correct', () async {
        final min = await ministerioDao.getById(idRef);
        expect(min, isNotNull);

        expect(min!.getNombre('es'), 'MINISTERIO DE PRUEBA (TEST)');
        expect(min.getNombre('fr'), 'MINISTÈRE DE TEST (TEST)');
      });

      test('Le jeu de données contient exactement 2 ministères', () async {
        final all = await ministerioDao.getAll();
        expect(all.length, 2); // valeur connue du JSON
      });
    });

    // ───────────────────────────
    // 2)  DYNAMIQUE
    // ───────────────────────────
    group('[Dynamic] DAO behaviour', () {
      test('getAll() respecte le tri par nom dans une langue donnée', () async {
        // Ajout de deux ministères supplémentaires
        await ministerioDao.insert(
          Ministerio(id: 'M-ALPHA', nombreTraductions: {
            'es': 'Ministerio Alpha',
            'fr': 'Ministère Alpha',
          }),
        );
        await ministerioDao.insert(
          Ministerio(id: 'M-OMEGA', nombreTraductions: {
            'es': 'Ministerio Omega',
            'fr': 'Ministère Omega',
          }),
        );

        // Tri ES ASC
        final esAsc = await ministerioDao.getAll(
          langCode: ['es'],
          orderBy: 'nombre_es ASC',
        );
        expect(esAsc.first.getNombre('es'), 'Ministerio Alpha');

        // Tri FR ASC
        final frAsc = await ministerioDao.getAll(
          langCode: ['fr'],
          orderBy: 'nombre_fr ASC',
        );
        expect(frAsc.first.getNombre('fr'), 'Ministère Alpha');
      });

      test('update() modifie correctement les traductions', () async {
        final min = (await ministerioDao.getById(idRef))!;
        final mod = min.copyWith(
          nombreTraductions: {
            'es': 'Nombre ES modifié',
            'fr': 'Nom FR modifié',
            'en': min.getNombre('en'), // conserve EN
          },
        );
        await ministerioDao.update(mod);

        final fetched = await ministerioDao.getById(idRef);
        expect(fetched!.getNombre('es'), 'Nombre ES modifié');
        expect(fetched.getNombre('fr'), 'Nom FR modifié');
      });

      test('delete() retire bien l’élément', () async {
        await ministerioDao.delete(idRef);
        expect(await ministerioDao.getById(idRef), isNull);
      });

      test('count() reflète les insert / delete', () async {
        final initial = await ministerioDao.count();

        await ministerioDao.insert(
          Ministerio(
            id: 'M-COUNT',
            nombreTraductions: {'es': 'Contador ES'},
          ),
        );
        expect(await ministerioDao.count(), initial + 1);
      });
    });
  });
}
