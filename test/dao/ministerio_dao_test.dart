import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/ministerio_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/ministerio.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();
  group('MinisterioDao Tests', () {
    late DatabaseService dbService;
    late MinisterioDao ministerioDao;
    // Les données de test (M-TEST-001) sont maintenant chargées par getTestDatabaseService 
    // à partir de test/test_assets/test_taxes.json par défaut.
    const String testMinisterioId = 'M-TEST-001'; 

    setUp(() async {
      dbService = await getTestDatabaseService(); // Utilise test_taxes.json par défaut
      ministerioDao = dbService.ministerioDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async => await dbService.close());

    test('getById retrieves correct ministerio', () async {
      final item = await ministerioDao.getById(testMinisterioId);
      expect(item, isNotNull, reason: "Ministerio $testMinisterioId should be loaded from test_taxes.json");
      // Les noms exacts dépendent de test_taxes.json
      // Ajuster ces attentes si le contenu de test_taxes.json est différent.
      expect(item!.getNombre('es'), 'MINISTERIO DE PRUEBA (TEST)'); 
      expect(item.getNombre('fr'), 'MINISTÈRE DE TEST (TEST)');
    });

    test('getAll returns items (check with es)', () async {
      // Le langCode pour getAll dans MinisterioDao est List<String>?
      final items = await ministerioDao.getAll(langCode: ['es']);
      // Le nombre dépendra du contenu de test_taxes.json
      expect(items.isNotEmpty, isTrue, reason: "Devrait y avoir au moins un ministère depuis test_taxes.json");
      expect(items.any((m) => m.id == testMinisterioId), isTrue);
    });
    
    test('getAll sorts by name in specified language', () async {
      // Ajouter un autre ministère pour tester le tri
      // S'assurer que les IDs sont uniques et n'existent pas déjà dans test_taxes.json
      // ou gérer les conflits d'ID si insert ignore/update.
      try {
        await ministerioDao.insert(Ministerio(id: "M-AAA", nombreTraductions: {"es": "Ministerio Alpha", "fr": "Ministère Alpha"}));
        await ministerioDao.insert(Ministerio(id: "M-ZZZ", nombreTraductions: {"es": "Ministerio Omega", "fr": "Ministère Omega"}));
      } catch (e) {
        // Gérer les erreurs d'insertion si les ID existent déjà, par exemple.
        // Pour ce test, on suppose que les ID sont uniques ou que l'insertion gère les conflits.
        // print("Erreur lors de l'insertion des données de test pour le tri: $e"); // Nettoyé
      }


      // S'attendre à ce que 'Ministerio Alpha' vienne avant 'MINISTERIO DE PRUEBA (TEST)' en espagnol
      final itemsEs = await ministerioDao.getAll(langCode: ['es'], orderBy: 'nombre_es ASC');
      // Le nombre exact dépendra de test_taxes.json + 2 insertions.
      // On vérifie juste que le premier est Alpha après le tri.
      expect(itemsEs.length, greaterThanOrEqualTo(3), reason: "Expected at least 3 ministerios after inserts for sorting test.");
      expect(itemsEs.first.getNombre('es'), "Ministerio Alpha", reason: "First item in Spanish sort should be 'Ministerio Alpha'");
      
      // S'attendre à ce que 'Ministère Alpha' vienne avant 'MINISTÈRE DE TEST (TEST)' en français
      final itemsFr = await ministerioDao.getAll(langCode: ['fr'], orderBy: 'nombre_fr ASC');
      expect(itemsFr.length, greaterThanOrEqualTo(3), reason: "Expected at least 3 ministerios after inserts for sorting test.");
      expect(itemsFr.first.getNombre('fr'), "Ministère Alpha", reason: "First item in French sort should be 'Ministère Alpha'");
    });


    test('update an item', () async {
      final item = (await ministerioDao.getById(testMinisterioId))!;
      final updated = item.copyWith(nombreTraductions: {'es': 'Nuevo Nombre ES', 'fr': 'Nouveau Nom FR', 'en': item.getNombre('en')}); // Conserver 'en'
      await ministerioDao.update(updated);
      final fetched = await ministerioDao.getById(testMinisterioId);
      expect(fetched!.getNombre('es'), 'Nuevo Nombre ES');
      expect(fetched.getNombre('fr'), 'Nouveau Nom FR');
    });

    test('delete an item', () async {
      await ministerioDao.delete(testMinisterioId);
      expect(await ministerioDao.getById(testMinisterioId), isNull);
    });

    test('count items', () async {
      // Le nombre initial dépend de test_taxes.json
      final initialCount = await ministerioDao.count();
      expect(initialCount, greaterThanOrEqualTo(1));
      
      // Utiliser un ID unique pour l'insertion pour éviter les conflits
      await ministerioDao.insert(Ministerio(id: "M-NEW-COUNT-TEST", nombreTraductions: {"es": "Otro Ministerio"}));
      expect(await ministerioDao.count(), initialCount + 1);
    });
  });
}
