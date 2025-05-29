// ──────────────────────────────────────────────────────────────────────────────
// test/dao/favori_dao_test.dart
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/favori_dao.dart';
import 'package:taxasge/database/database_service.dart';

import '../database_test_utils.dart';   // sqfliteTestInit() + getTestDatabaseService()

void main() {
  sqfliteTestInit();

  group('FavoriDao – tests combinés', () {
    late DatabaseService dbService;
    late FavoriDao       favoriDao;

    // ID existant dans test_taxes.json
    const conceptoId = 'T-TEST-001';

    setUp(() async {
      dbService  = await getTestDatabaseService(seedData: true);
      favoriDao  = dbService.favoriDao;
    });

    tearDown(() async => dbService.close());

    // ───────────────────────────
    // 1)  GOLDEN / FIGÉ
    // ───────────────────────────
    group('[Golden] Import integrity', () {
      test('La table des favoris est vide après import', () async {
        expect(await favoriDao.count(), 0);
      });
    });

    // ───────────────────────────
    // 2)  DYNAMIQUE
    // ───────────────────────────
    group('[Dynamic] DAO behaviour', () {
      test('addToFavorites puis isFavorite', () async {
        expect(await favoriDao.isFavorite(conceptoId), isFalse);
        await favoriDao.addToFavorites(conceptoId);
        expect(await favoriDao.isFavorite(conceptoId), isTrue);
      });

      test('toggleFavorite ajoute si absent, retire si présent', () async {
        // absent → toggle => ajoute
        await favoriDao.toggleFavorite(conceptoId);
        expect(await favoriDao.isFavorite(conceptoId), isTrue);

        // présent → toggle => retire
        await favoriDao.toggleFavorite(conceptoId);
        expect(await favoriDao.isFavorite(conceptoId), isFalse);
      });

      test('deleteByConceptoId supprime toutes les entrées liées', () async {
        await favoriDao.addToFavorites(conceptoId);
        expect(await favoriDao.count(), 1);

        await favoriDao.deleteByConceptoId(conceptoId);
        expect(await favoriDao.count(), 0);
      });

      test('getAll retourne toutes les entrées', () async {
        await favoriDao.addToFavorites(conceptoId);

        // Ajout facultatif d’un second favori si présent dans le JSON
        const conceptoId2 = 'T-TEST-002';           //  adapter si besoin
        try {
          await favoriDao.addToFavorites(conceptoId2);
        } catch (_) {
          // ignoré si l’ID n’existe pas
        }

        final all = await favoriDao.getAll();
        expect(all, isNotEmpty);
        expect(all.any((f) => f.conceptoId == conceptoId), isTrue);
      });

      test('count reflète correctement insert / delete', () async {
        final start = await favoriDao.count();

        await favoriDao.addToFavorites(conceptoId);
        expect(await favoriDao.count(), start + 1);

        await favoriDao.deleteByConceptoId(conceptoId);
        expect(await favoriDao.count(), start);
      });

      test('getById récupère l’entrée et sa date ISO-8601', () async {
        final rowId = await favoriDao.addToFavorites(conceptoId);
        final fav   = await favoriDao.getById(rowId);

        expect(fav, isNotNull);
        expect(fav!.conceptoId, conceptoId);
        expect(() => DateTime.parse(fav.fechaAgregado), returnsNormally);
      });
    });
  });
}
