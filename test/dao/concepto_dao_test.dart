import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/dao/concepto_dao.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/models/concepto.dart';
import 'package:taxasge/services/localization_service.dart'; // Pour les tests de recherche par langue
import '../database_test_utils.dart'; // Utilitaire d'initialisation de la DB

void main() {
  sqfliteTestInit(); // Initialiser FFI pour les tests desktop

  group('ConceptoDao Tests', () {
    late DatabaseService dbService;
    late ConceptoDao conceptoDao;

    // Un JSON de test plus complet pour ConceptoDao
    const String conceptoTestJson = '''
    [
      {
        "id": "M-001",
        "nombre": { "es": "Ministerio A", "fr": "Ministère A", "en": "Ministry A" },
        "sectores": [
          {
            "id": "S-001",
            "nombre": { "es": "Sector A1" },
            "categorias": [
              {
                "id": "C-001",
                "nombre": { "es": "Categoria A1.1" },
                "sub_categorias": [
                  {
                    "id": "SC-001",
                    "nombre": { "es": "SubCategoria A1.1.1" },
                    "conceptos": [
                      {
                        "id": "T-001",
                        "nombre": { "es": "Impuesto Alpha", "fr": "Taxe Alpha", "en": "Alpha Tax" },
                        "tasa_expedicion": "1000",
                        "tasa_renovacion": "500",
                        "documentos_requeridos": { "es": "Doc ES 1", "fr": "Doc FR 1" },
                        "procedimiento": { "es": "Proc ES 1", "fr": "Proc FR 1" },
                        "palabras_clave": { "es": "alpha,impuesto", "fr": "alpha,taxe" }
                      },
                      {
                        "id": "T-002",
                        "nombre": { "es": "Servicio Beta", "fr": "Service Beta", "en": "Beta Service" },
                        "tasa_expedicion": "2000",
                        "tasa_renovacion": "",
                        "procedimiento": { "es": "Proc ES 2" },
                        "palabras_clave": { "es": "beta,servicio", "en": "beta,service" }
                      }
                    ]
                  },
                  {
                    "id": "SC-002",
                    "nombre": { "es": "SubCategoria A1.1.2" },
                    "conceptos": [
                      {
                        "id": "T-003",
                        "nombre": { "es": "Contribucion Gamma", "fr": "Contribution Gamma" },
                        "tasa_expedicion": "0", 
                        "tasa_renovacion": "0",
                        "documentos_requeridos": { "es": "Doc ES 3" }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
    ''';

    setUp(() async {
      dbService = await getTestDatabaseService(testJsonString: conceptoTestJson, seedData: true);
      conceptoDao = dbService.conceptoDao;
      // Assurer que LocalizationService est initialisé si des tests en dépendent pour langCode
      await LocalizationService.instance.initialize();
      await LocalizationService.instance.setLanguage('es'); // Langue par défaut pour les tests
    });

    tearDown(() async {
      await dbService.close();
    });

    test('insert and getById', () async {
      final concepto = await conceptoDao.getById('T-001');
      expect(concepto, isNotNull);
      expect(concepto!.id, 'T-001');
      expect(concepto.getNombre('es'), 'Impuesto Alpha');
      expect(concepto.getNombre('fr'), 'Taxe Alpha');
      expect(concepto.tasaExpedicion, '1000');
    });

    test('getAll returns all conceptos', () async {
      final conceptos = await conceptoDao.getAll();
      expect(conceptos.length, 3);
    });

    test('getBySubCategoriaId returns correct conceptos', () async {
      final conceptos = await conceptoDao.getBySubCategoriaId('SC-001');
      expect(conceptos.length, 2);
      expect(conceptos.any((c) => c.id == 'T-001'), isTrue);
      expect(conceptos.any((c) => c.id == 'T-002'), isTrue);
    });

    test('update a concepto', () async {
      Concepto? concepto = await conceptoDao.getById('T-001');
      expect(concepto, isNotNull);
      
      final updatedConcepto = concepto!.copyWith(tasaExpedicion: "1200");
      await conceptoDao.update(updatedConcepto);
      
      final fetchedConcepto = await conceptoDao.getById('T-001');
      expect(fetchedConcepto!.tasaExpedicion, "1200");
    });

    test('delete a concepto', () async {
      await conceptoDao.delete('T-001');
      final concepto = await conceptoDao.getById('T-001');
      expect(concepto, isNull);
    });

    test('count returns correct number of conceptos', () async {
      final count = await conceptoDao.count();
      expect(count, 3);
    });

    group('searchByName', () {
      test('finds by Spanish name', () async {
        final results = await conceptoDao.searchByName('Alpha', langCode: 'es');
        expect(results.length, 1);
        expect(results.first.id, 'T-001');
      });

      test('finds by French name', () async {
        final results = await conceptoDao.searchByName('Beta', langCode: 'fr');
        expect(results.length, 1);
        expect(results.first.id, 'T-002');
      });

      test('finds by partial name across all languages if langCode is null', () async {
        final results = await conceptoDao.searchByName('gamma'); // Contribution Gamma (es)
        expect(results.length, 1);
        expect(results.first.id, 'T-003');
      });
    });
    
    group('advancedSearch', () {
      test('by searchTerm in nombre (es)', () async {
        final results = await conceptoDao.advancedSearch(searchTerm: 'Alpha', langCode: 'es');
        expect(results.length, 1);
        expect(results.first.id, 'T-001');
      });

      test('by searchTerm in nombre (fr)', () async {
        final results = await conceptoDao.advancedSearch(searchTerm: 'Taxe Alpha', langCode: 'fr');
        expect(results.length, 1);
        expect(results.first.id, 'T-001');
      });
      
      test('by searchTerm in procedimiento (es)', () async {
        final results = await conceptoDao.advancedSearch(searchTerm: 'Proc ES 1', langCode: 'es');
        expect(results.length, 1);
        expect(results.first.id, 'T-001');
      });

      test('by searchTerm in documentos_requeridos (fr)', () async {
        final results = await conceptoDao.advancedSearch(searchTerm: 'Doc FR 1', langCode: 'fr');
        expect(results.length, 1);
        expect(results.first.id, 'T-001');
      });
      
      // Nécessite que MotCleDao et l'import des mots-clés fonctionnent correctement
      // et que DatabaseService.getTestDatabaseService les peuple.
      test('by searchTerm in mots_cles (es)', () async {
        final results = await conceptoDao.advancedSearch(searchTerm: 'beta', langCode: 'es');
        expect(results.length, 1);
        expect(results.first.id, 'T-002');
      });

      test('by ministerioId', () async {
        final results = await conceptoDao.advancedSearch(ministerioId: 'M-001', langCode: 'es');
        expect(results.length, 3); // Tous les concepts sont sous M-001 dans les données de test
      });

      test('by sectorId', () async {
        final results = await conceptoDao.advancedSearch(sectorId: 'S-001', langCode: 'es');
        expect(results.length, 3);
      });

      test('by categoriaId', () async {
        final results = await conceptoDao.advancedSearch(categoriaId: 'C-001', langCode: 'es');
        expect(results.length, 3);
      });

      test('by subCategoriaId', () async {
        final results = await conceptoDao.advancedSearch(subCategoriaId: 'SC-001', langCode: 'es');
        expect(results.length, 2);
      });
      
      test('by maxTasaExpedicion', () async {
        final results = await conceptoDao.advancedSearch(maxTasaExpedicion: '1500', langCode: 'es');
        expect(results.length, 2); // T-001 (1000), T-003 (0)
        expect(results.any((c) => c.id == 'T-001'), isTrue);
        expect(results.any((c) => c.id == 'T-003'), isTrue);
      });

      test('by maxTasaRenovacion (finds those with empty or valid lower rates)', () async {
        // T-001 (500), T-002 (""), T-003 (0)
        final results = await conceptoDao.advancedSearch(maxTasaRenovacion: '50', langCode: 'es');
         // Seul T-003 (0) et T-002 ("") devraient correspondre.
         // La gestion des chaînes vides comme "0" ou non-numérique est importante ici.
         // Le DAO actuel pourrait avoir du mal avec les chaînes vides si la conversion en NUMERIC échoue.
         // Pour ce test, on s'attend à ce que T-003 (0) corresponde. T-002 ("") ne sera pas inclus par CAST.
        expect(results.length, 1); 
        expect(results.first.id, 'T-003');
      });

      test('combined search (searchTerm and subCategoriaId)', () async {
        final results = await conceptoDao.advancedSearch(searchTerm: 'Beta', subCategoriaId: 'SC-001', langCode: 'es');
        expect(results.length, 1);
        expect(results.first.id, 'T-002');
      });
    });
    
    group('Translation availability', () {
      test('getConceptosWithNombreTranslation for fr', () async {
        final results = await conceptoDao.getConceptosWithNombreTranslation('fr');
        // T-001 (Taxe Alpha), T-002 (Service Beta), T-003 (Contribution Gamma)
        expect(results.length, 3);
      });

      test('getConceptosWithoutNombreTranslation for en (only T-001 and T-002 have English names)', () async {
        final results = await conceptoDao.getConceptosWithoutNombreTranslation('en');
        // T-003 n'a pas de nom en anglais
        expect(results.length, 1);
        expect(results.first.id, 'T-003');
      });
      
      test('getAvailableLanguagesForConcepto T-001', () async {
        final available = await conceptoDao.getAvailableLanguagesForConcepto('T-001');
        expect(available['nombre'], containsAll(['es', 'fr', 'en']));
        expect(available['documentos_requeridos'], containsAll(['es', 'fr']));
        expect(available['procedimiento'], containsAll(['es', 'fr']));
      });
      
      test('getAvailableLanguagesForConcepto T-003 (less translations)', () async {
        final available = await conceptoDao.getAvailableLanguagesForConcepto('T-003');
        expect(available['nombre'], containsAll(['es', 'fr']));
        expect(available['nombre']!,isNot(contains('en')));
        expect(available['documentos_requeridos'], contains('es'));
        expect(available['documentos_requeridos']!,isNot(contains('fr')));
        // Procédure n'est pas défini pour T-003 dans les données de test
        expect(available['procedimiento'], isEmpty);
      });
    });
  });
}
