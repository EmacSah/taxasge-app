import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/document_requis_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/document_requis.dart';
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart';

void main() {
  sqfliteTestInit();

  group('DocumentRequisDao Tests', () {
    late DatabaseService dbService;
    late DocumentRequisDao documentRequisDao;
    const String testConceptoId = 'T-TEST';

    setUp(() async {
      // Utilise le même JSON que pour ConceptoDao car il contient des documents
      // minimalTestJson est défini dans database_test_utils.dart
      dbService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      documentRequisDao = dbService.documentRequisDao;
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es');
    });

    tearDown(() async {
      await dbService.close();
    });

    test('insert and getById', () async {
      // Les données sont insérées via _importInitialData dans DatabaseService
      // On s'attend à ce que les documents pour T-TEST (Doc1, Doc2) soient là.
      // On va récupérer le premier pour vérifier son existence et son contenu.
      final docs = await documentRequisDao.getByConceptoId(testConceptoId);
      expect(docs, isNotEmpty);
      
      final firstDoc = docs.first;
      final fetchedDoc = await documentRequisDao.getById(firstDoc.id);
      
      expect(fetchedDoc, isNotNull);
      expect(fetchedDoc!.id, firstDoc.id);
      expect(fetchedDoc.conceptoId, testConceptoId);
      expect(fetchedDoc.getNombre('es'), 'Doc1');
    });

    test('getAll returns all documents', () async {
      final allDocs = await documentRequisDao.getAll();
      // minimalTestJson a 2 documents pour T-TEST
      expect(allDocs.length, 2); 
    });

    test('getByConceptoId returns correct documents', () async {
      final docs = await documentRequisDao.getByConceptoId(testConceptoId);
      expect(docs.length, 2);
      expect(docs.any((d) => d.getNombre('es') == 'Doc1'), isTrue);
      expect(docs.any((d) => d.getNombre('es') == 'Doc2'), isTrue);
    });

    test('update a document', () async {
      final docs = await documentRequisDao.getByConceptoId(testConceptoId);
      final originalDoc = docs.first;

      final updatedDoc = originalDoc.copyWith(nombreTraductions: {'es': 'Documento Actualizado ES'});
      await documentRequisDao.update(updatedDoc);

      final fetchedDoc = await documentRequisDao.getById(originalDoc.id);
      expect(fetchedDoc!.getNombre('es'), 'Documento Actualizado ES');
    });
    
    test('updateTranslation updates specific language', () async {
      final docs = await documentRequisDao.getByConceptoId(testConceptoId);
      final docToUpdate = docs.firstWhere((d) => d.getNombre('es') == 'Doc1');
      
      // minimalTestJson from database_test_utils.dart has "Doc1 fr\nDoc2 fr" for T-TEST in French.
      // So, 'fr' translation already exists. Let's update it.
      await documentRequisDao.updateTranslation(docToUpdate.id, 'fr', nombre: 'Document FR Modifié');
      final updatedDoc = await documentRequisDao.getById(docToUpdate.id);
      
      expect(updatedDoc, isNotNull);
      expect(updatedDoc!.getNombre('fr'), 'Document FR Modifié');
      // S'assurer que les autres langues ne sont pas affectées.
      expect(updatedDoc.getNombre('es'), 'Doc1'); 
    });

    test('delete a document', () async {
      final docs = await documentRequisDao.getByConceptoId(testConceptoId);
      final docToDelete = docs.first;
      
      await documentRequisDao.delete(docToDelete.id);
      final fetchedDoc = await documentRequisDao.getById(docToDelete.id);
      expect(fetchedDoc, isNull);
      
      final remainingDocs = await documentRequisDao.getByConceptoId(testConceptoId);
      expect(remainingDocs.length, 1);
    });
    
    test('count returns correct number of documents', () async {
      final count = await documentRequisDao.count();
      expect(count, 2);
    });
  });
}
