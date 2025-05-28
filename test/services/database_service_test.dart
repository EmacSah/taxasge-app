import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/ministerio.dart'; // pour vérifier le type
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart'; // Importer les utilitaires

void main() {
  sqfliteTestInit(); // Initialiser FFI pour les tests desktop

  group('DatabaseService Tests', () {
    late DatabaseService databaseService;

    setUpAll(() async {
      // Initialiser le service de localisation une fois pour tous les tests du groupe
      // car il est utilisé par getConceptoWithDetails et d'autres potentiellement
      await LocalizationService.instance.initialize(); 
    });

    test('initialize and import initial data (minimalTestJson)', () async {
      databaseService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      
      final ministerios = await databaseService.ministerioDao.getAll();
      expect(ministerios, isNotEmpty);
      expect(ministerios.first.id, 'M-TEST');

      final conceptos = await databaseService.conceptoDao.getAll();
      expect(conceptos, isNotEmpty);
      expect(conceptos.first.id, 'T-TEST');
      
      // Note: The original test expected 'Doc1 es', 'Proc1 es'.
      // The provided minimalTestJson in this subtask has "Doc1\nDoc2" and "Proc1\nProc2" for 'es'.
      // And "test,prueba" for keywords.
      // I'll adjust expectations to match the JSON provided in *this* subtask.

      final documents = await databaseService.documentRequisDao.getByConceptoId('T-TEST');
      expect(documents, isNotEmpty);
      expect(documents.length, 2); // Doc1, Doc2
      expect(documents.first.getNombre('es'), 'Doc1'); // Assuming getNombre correctly parses the first line

      final procedures = await databaseService.procedureDao.getByConceptoId('T-TEST');
      expect(procedures, isNotEmpty);
      expect(procedures.length, 2); // Proc1, Proc2
      expect(procedures.first.getDescription('es'), 'Proc1'); // Assuming getDescription correctly parses
      
      final motsCles = await databaseService.motCleDao.getMotsClesByConceptoId('T-TEST', langCode: 'es');
      expect(motsCles, contains('test'));
      expect(motsCles, contains('prueba'));
    });

    test('getConceptoWithDetails retrieves full details', () async {
      databaseService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      // Ensuring language is set to 'es' as the minimalTestJson primarily has 'es' details for nested items.
      // And getConceptoWithDetails uses LocalizationService.instance.currentLanguage.
      LocalizationService.instance.setLanguage('es'); 

      final conceptoDetails = await databaseService.getConceptoWithDetails('T-TEST');
      
      expect(conceptoDetails, isNotNull);
      expect(conceptoDetails!['id'], 'T-TEST');
      // nombre_current should be 'CONCEPTO DE PRUEBA' (from 'es' as per minimalTestJson)
      expect(conceptoDetails['nombre_current'], 'CONCEPTO DE PRUEBA'); 
      expect(conceptoDetails['tasa_expedicion'], '100');
      
      // Vérifier la hiérarchie (all names are 'es' from minimalTestJson)
      expect(conceptoDetails['subcategoria_nombre'], 'SUBCATEGORIA PRUEBA');
      expect(conceptoDetails['categoria_nombre'], 'CATEGORIA PRUEBA');
      expect(conceptoDetails['sector_nombre'], 'SECTOR PRUEBA');
      expect(conceptoDetails['ministerio_nombre'], 'MINISTERIO DE PRUEBA');

      // Vérifier les documents
      expect(conceptoDetails['documentos'], isList);
      expect(conceptoDetails['documentos'].length, 2);
      // Accessing 'nombre_es' as getConceptoWithDetails fetches based on current language ('es')
      // and the structure from DAO should be Map<String, dynamic> with 'nombre_es', 'nombre_fr' etc.
      // The DAO for DocumentRequis should populate 'nombre_current' based on lang.
      // For this test, assuming the map contains 'nombre_es' directly from the parsing.
      // Let's assume getConceptoWithDetails populates a 'nombre_current' or similar field
      // based on the language passed to it (which is 'es' here).
      // The provided test structure is `conceptoDetails['documentos'][0]['nombre_es']`.
      // This depends on how DocumentRequisDao.getMapByConceptoId structures its output
      // or how getConceptoWithDetails processes it.
      // The minimalTestJson has "Doc1\nDoc2" for 'es'.
      // The previous test for 'initialize' expected 'Doc1'.
      // Let's be consistent: if DocumentRequisDao.getByConceptoId splits, then it should be 'Doc1'.
      // If `getConceptoWithDetails` fetches raw map, it will be "Doc1\nDoc2".
      // Given the previous test, let's assume the DAO splits and `getConceptoWithDetails` uses that.
      // The test from the prompt expects `conceptoDetails['documentos'][0]['nombre_es']`. This implies
      // `getConceptoWithDetails` returns a list of maps, and each map has language-specific keys.
      // This is a bit inconsistent with the idea of `nombre_current`.
      // Let's stick to the prompt's expectation for this field access.
      expect(conceptoDetails['documentos'][0]['nombre_es'], 'Doc1');


      // Vérifier les procédures
      expect(conceptoDetails['procedimientos'], isList);
      expect(conceptoDetails['procedimientos'].length, 2);
      expect(conceptoDetails['procedimientos'][0]['description_es'], 'Proc1');
      
      // Vérifier les mots-clés
      expect(conceptoDetails['palabras_clave'], isList);
      expect(conceptoDetails['palabras_clave'], contains('test')); // keywords are already split
      
      expect(conceptoDetails['es_favorito'], isFalse); // Par défaut
    });
    
    test('getConceptoWithDetails returns null for non-existent ID', () async {
      databaseService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      final conceptoDetails = await databaseService.getConceptoWithDetails('NON_EXISTENT_ID');
      expect(conceptoDetails, isNull);
    });

    // TODO: Ajouter des tests pour searchConceptos (similaires à ConceptoDao mais via le service)
    // TODO: Ajouter des tests pour getFavoritesWithDetails (nécessite d'abord d'ajouter des favoris)
    // TODO: Ajouter des tests pour getConceptosByMinisterio
  });
}
