import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/procedure_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/procedure.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();

  group('ProcedureDao Tests', () {
    late DatabaseService dbService;
    late ProcedureDao procedureDao;
    const String testConceptoId = 'T-TEST';

    setUp(() async {
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      procedureDao = dbService.procedureDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async {
      await dbService.close();
    });

    test('insert and getById', () async {
      // Les données sont insérées via _importInitialData
      final procs = await procedureDao.getByConceptoId(testConceptoId);
      expect(procs, isNotEmpty);
      
      final firstProc = procs.first;
      final fetchedProc = await procedureDao.getById(firstProc.id);
      
      expect(fetchedProc, isNotNull);
      expect(fetchedProc!.id, firstProc.id);
      expect(fetchedProc.conceptoId, testConceptoId);
      expect(fetchedProc.getDescription('es'), 'Proc1');
    });

    test('getAll returns all procedures', () async {
      final allProcs = await procedureDao.getAll();
      // minimalTestJson a 2 procédures pour T-TEST
      expect(allProcs.length, 2);
    });

    test('getByConceptoId returns correct procedures', () async {
      final procs = await procedureDao.getByConceptoId(testConceptoId);
      expect(procs.length, 2);
      expect(procs.any((p) => p.getDescription('es') == 'Proc1'), isTrue);
      expect(procs.any((p) => p.getDescription('es') == 'Proc2'), isTrue);
    });
    
    test('getByConceptoId orders by "orden" then by description', () async {
      // Ajouter une autre procédure avec un ordre différent pour tester
      await procedureDao.insert(Procedure(
        id: 0, // auto-increment
        conceptoId: testConceptoId,
        descriptionTraductions: {'es': 'Proc0'},
        orden: 0,
      ));
      final procs = await procedureDao.getByConceptoId(testConceptoId, langCode: 'es');
      expect(procs.length, 3);
      expect(procs[0].getDescription('es'), 'Proc0'); // Doit venir en premier à cause de 'orden: 0'
      expect(procs[1].getDescription('es'), 'Proc1'); 
      expect(procs[2].getDescription('es'), 'Proc2');
    });

    test('update a procedure', () async {
      final procs = await procedureDao.getByConceptoId(testConceptoId);
      final originalProc = procs.first;

      final updatedProc = originalProc.copyWith(descriptionTraductions: {'es': 'Procedimiento Actualizado ES'});
      await procedureDao.update(updatedProc);

      final fetchedProc = await procedureDao.getById(originalProc.id);
      expect(fetchedProc!.getDescription('es'), 'Procedimiento Actualizado ES');
    });

    test('updateTranslation updates specific language', () async {
      final procs = await procedureDao.getByConceptoId(testConceptoId);
      final procToUpdate = procs.firstWhere((p) => p.getDescription('es') == 'Proc1');
      
      // minimalTestJson ne définit que 'es' pour les procédures initiales.
      // Ajoutons une traduction 'fr'.
      await procedureDao.updateTranslation(procToUpdate.id, 'fr', 'Procédure FR Modifiée');
      final updatedProc = await procedureDao.getById(procToUpdate.id);
      
      expect(updatedProc, isNotNull);
      expect(updatedProc!.getDescription('fr'), 'Procédure FR Modifiée');
      expect(updatedProc.getDescription('es'), 'Proc1');
    });
    
    test('updateOrder changes the order', () async {
      final procs = await procedureDao.getByConceptoId(testConceptoId);
      final procToUpdate = procs.firstWhere((p) => p.getDescription('es') == 'Proc1');
      
      await procedureDao.updateOrder(procToUpdate.id, 5);
      final updatedProc = await procedureDao.getById(procToUpdate.id);
      expect(updatedProc!.orden, 5);
    });

    test('delete a procedure', () async {
      final procs = await procedureDao.getByConceptoId(testConceptoId);
      final procToDelete = procs.first;
      
      await procedureDao.delete(procToDelete.id);
      final fetchedProc = await procedureDao.getById(procToDelete.id);
      expect(fetchedProc, isNull);
      
      final remainingProcs = await procedureDao.getByConceptoId(testConceptoId);
      expect(remainingProcs.length, 1);
    });
    
    test('count returns correct number of procedures', () async {
      final count = await procedureDao.count();
      expect(count, 2);
    });
  });
}
