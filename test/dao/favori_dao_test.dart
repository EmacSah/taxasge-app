import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/favori_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/favori.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('FavoriDao Tests', () {
    late DatabaseService dbService;
    late FavoriDao favoriDao;
    const String testConceptoId1 = 'T-TEST';
    // const String testConceptoId2 = 'T-002'; // Supposons que cet ID existe dans un jeu de données plus large

    setUp(() async {
      // Utiliser minimalTestJson qui contient T-TEST.
      // T-002 (utilisé dans certains tests originaux) n'est pas dans minimalTestJson.
      // Les tests seront adaptés pour T-TEST.
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      favoriDao = dbService.favoriDao;
    });
    tearDown(() async => await dbService.close());

    test('add and isFavorite', () async {
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
      await favoriDao.add(Favori(conceptoId: testConceptoId1, fechaAgregado: DateTime.now()));
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
    });

    test('remove a favorite', () async {
      await favoriDao.add(Favori(conceptoId: testConceptoId1, fechaAgregado: DateTime.now()));
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
      await favoriDao.remove(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
    });

    test('toggleFavorite adds if not present', () async {
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
      await favoriDao.toggleFavorite(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
    });

    test('toggleFavorite removes if present', () async {
      await favoriDao.add(Favori(conceptoId: testConceptoId1, fechaAgregado: DateTime.now()));
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
      await favoriDao.toggleFavorite(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
    });
    
    test('getAll returns all favorites', () async {
      await favoriDao.add(Favori(conceptoId: testConceptoId1, fechaAgregado: DateTime.now()));
      // Pour un meilleur test, il faudrait un testConceptoId2 valide et l'ajouter aussi
      // Si T-002 était dans minimalTestJson, on pourrait faire:
      // await favoriDao.add(Favori(conceptoId: testConceptoId2, fechaAgregado: DateTime.now()));
      
      final favorites = await favoriDao.getAll();
      expect(favorites.length, 1);
      expect(favorites.first.conceptoId, testConceptoId1);
    });

    test('count returns correct number of favorites', () async {
      expect(await favoriDao.count(), 0);
      await favoriDao.add(Favori(conceptoId: testConceptoId1, fechaAgregado: DateTime.now()));
      expect(await favoriDao.count(), 1);
    });
  });
}
