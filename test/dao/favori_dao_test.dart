import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/favori_dao.dart';
import 'package:taxasge/database/database_service.dart';
// N'est plus nécessaire d'importer Favori directement pour les opérations d'ajout/suppression de base
// import 'package:taxasge/models/favori.dart'; 
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('FavoriDao Tests', () {
    late DatabaseService dbService;
    late FavoriDao favoriDao;
    // Utiliser un ID de concept qui existera grâce à minimalTestJson ou test_taxes.json
    const String testConceptoId1 = 'T-TEST'; 
    // Ajouter un autre ID si votre test_taxes.json en contient d'autres pour tester getAll
    // const String testConceptoId2 = 'T-002'; // Assurez-vous que cet ID est dans test_taxes.json si vous l'utilisez

    setUp(() async {
      // getTestDatabaseService charge test_taxes.json par défaut
      dbService = await getTestDatabaseService(); 
      favoriDao = dbService.favoriDao;
    });

    tearDown(() async {
      await dbService.close();
    });

    test('addToFavorites and isFavorite', () async {
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
      await favoriDao.addToFavorites(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
    });

    test('deleteByConceptoId a favorite', () async {
      await favoriDao.addToFavorites(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
      await favoriDao.deleteByConceptoId(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
    });

    test('toggleFavorite adds if not present', () async {
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
      await favoriDao.toggleFavorite(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
    });

    test('toggleFavorite removes if present', () async {
      await favoriDao.addToFavorites(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isTrue);
      await favoriDao.toggleFavorite(testConceptoId1);
      expect(await favoriDao.isFavorite(testConceptoId1), isFalse);
    });
    
    test('getAll returns all favorites', () async {
      await favoriDao.addToFavorites(testConceptoId1);
      // Pour un test plus robuste, ajoutez testConceptoId2 si présent dans vos données de test
      // Exemple:
      // final conceptos = await dbService.conceptoDao.getAll(); // Nécessite ConceptoDao et ses dépendances
      // const String testConceptoId2 = 'T-002'; // Assurez-vous que cet ID existe
      // if (conceptos.any((c) => c.id == testConceptoId2)) { 
      //   await favoriDao.addToFavorites(testConceptoId2);
      // }
      
      final favorites = await favoriDao.getAll();
      // Le nombre exact dépendra de si T-002 a pu être ajouté et existe dans test_taxes.json.
      // Si T-TEST est le seul concept dans les données chargées par getTestDatabaseService,
      // (par exemple si test_taxes.json est simple ou si on utilise minimalTestJson)
      // alors length sera 1.
      expect(favorites.length, greaterThanOrEqualTo(1)); 
      expect(favorites.any((f) => f.conceptoId == testConceptoId1), isTrue);
    });

    test('count returns correct number of favorites', () async {
      expect(await favoriDao.count(), 0);
      await favoriDao.addToFavorites(testConceptoId1);
      expect(await favoriDao.count(), 1);
    });

    test('getById retrieves a favorite by its auto-generated id', () async {
      final insertedId = await favoriDao.addToFavorites(testConceptoId1);
      // L'ID retourné par addToFavorites (via insert) est l'auto-generated ID.
      final favori = await favoriDao.getById(insertedId);
      expect(favori, isNotNull);
      expect(favori!.conceptoId, testConceptoId1);
      // Vérifier que fechaAgregado est une String ISO8601 valide
      expect(() => DateTime.parse(favori.fechaAgregado), returnsNormally);
    });

  });
}
