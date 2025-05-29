import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
// import 'package:taxasge/models/ministerio.dart'; // pour vérifier le type - Non utilisé
import 'package:taxasge/services/localization_service.dart';
import '../database_test_utils.dart'; // Importer les utilitaires

void main() {
  sqfliteTestInit(); // Initialiser FFI pour les tests desktop

  group('DatabaseService Tests', () {
    // late DatabaseService databaseService; // Déclaré localement dans les tests

    setUpAll(() async {
      // Initialiser le service de localisation une fois pour tous les tests du groupe
      // car il est utilisé par getConceptoWithDetails et d'autres potentiellement
      await LocalizationService.instance.initialize(); 
    });

    test('initialize and import initial data (minimalTestJson)', () async {
      final databaseService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      
      final ministerios = await databaseService.ministerioDao.getAll();
      expect(ministerios, isNotEmpty);
      expect(ministerios.first.id, 'M-TEST');

      final conceptos = await databaseService.conceptoDao.getAll();
      expect(conceptos, isNotEmpty);
      expect(conceptos.first.id, 'T-TEST');
      
      final documents = await databaseService.documentRequisDao.getByConceptoId('T-TEST');
      expect(documents, isNotEmpty);
      expect(documents.length, 2); // Doc1, Doc2
      expect(documents.first.getNombre('es'), 'Doc1');

      final procedures = await databaseService.procedureDao.getByConceptoId('T-TEST');
      expect(procedures, isNotEmpty);
      expect(procedures.length, 2); // Proc1, Proc2
      expect(procedures.first.getDescription('es'), 'Proc1');
      
      final motsCles = await databaseService.motCleDao.getMotsClesByConceptoId('T-TEST', langCode: 'es');
      expect(motsCles, contains('test'));
      expect(motsCles, contains('prueba'));
    });

    test('getConceptoWithDetails retrieves full details', () async {
      final databaseService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      LocalizationService.instance.setLanguage('es'); 

      final conceptoDetails = await databaseService.getConceptoWithDetails('T-TEST');
      
      expect(conceptoDetails, isNotNull);
      expect(conceptoDetails!['id'], 'T-TEST');
      expect(conceptoDetails['nombre_current'], 'CONCEPTO DE PRUEBA'); 
      expect(conceptoDetails['tasa_expedicion'], '100');
      
      expect(conceptoDetails['subcategoria_nombre'], 'SUBCATEGORIA PRUEBA');
      expect(conceptoDetails['categoria_nombre'], 'CATEGORIA PRUEBA');
      expect(conceptoDetails['sector_nombre'], 'SECTOR PRUEBA');
      expect(conceptoDetails['ministerio_nombre'], 'MINISTERIO DE PRUEBA');

      expect(conceptoDetails['documentos'], isList);
      expect(conceptoDetails['documentos'].length, 2);
      expect(conceptoDetails['documentos'][0]['nombre_es'], 'Doc1');

      expect(conceptoDetails['procedimientos'], isList);
      expect(conceptoDetails['procedimientos'].length, 2);
      expect(conceptoDetails['procedimientos'][0]['description_es'], 'Proc1');
      
      expect(conceptoDetails['palabras_clave'], isList);
      expect(conceptoDetails['palabras_clave'], contains('test'));
      
      expect(conceptoDetails['es_favorito'], isFalse);
    });
    
    test('getConceptoWithDetails returns null for non-existent ID', () async {
      final databaseService = await getTestDatabaseService(testJsonString: minimalTestJson, seedData: true);
      final conceptoDetails = await databaseService.getConceptoWithDetails('NON_EXISTENT_ID');
      expect(conceptoDetails, isNull);
    });

    // TODO: Ajouter des tests pour searchConceptos (similaires à ConceptoDao mais via le service)
    // TODO: Ajouter des tests pour getFavoritesWithDetails (nécessite d'abord d'ajouter des favoris)
    // TODO: Ajouter des tests pour getConceptosByMinisterio
  });
}
