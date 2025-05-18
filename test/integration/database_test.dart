import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart' as sqflite_common_ffi;

void main() {
  // Initialiser SQLite FFI pour les tests
  setUp(() {
    databaseFactory = sqflite_common_ffi.databaseFactoryFfi;
  });

  test('Test de la base de données TaxasGE avec fichier de test', () async {
    final dbService = DatabaseService();
    // Lire le fichier JSON de test
    final file = File('test/test_assets/test_taxes.json');
    final testJsonString = await file.readAsString();
    
    // Initialiser la base de données avec les données de test
    print('Initialisation de la base de données avec données de test...');
    await dbService.initialize(forceReset: true, seedData: true, testJsonString: testJsonString);
    print('Base de données initialisée avec succès.');
    
    // Vérifier les ministères
    final ministerios = await dbService.ministerioDao.getAll();
    print('\n=== Ministères (${ministerios.length}) ===');
    for (final ministerio in ministerios) {
      print('- ${ministerio.id}: ${ministerio.nombre}');
    }
    expect(ministerios.length, 1);
    expect(ministerios.first.id, "M-001");
    expect(ministerios.first.nombre, "MINISTÈRE TEST");
    
    if (ministerios.isNotEmpty) {
      // Vérifier les secteurs du premier ministère
      final sectores = await dbService.sectorDao.getByMinisterioId(ministerios.first.id);
      print('\n=== Secteurs du ministère ${ministerios.first.nombre} (${sectores.length}) ===');
      for (final sector in sectores) {
        print('- ${sector.id}: ${sector.nombre}');
      }
      expect(sectores.length, 1);
      expect(sectores.first.id, "S-001");
      expect(sectores.first.nombre, "SECTEUR TEST");
      
      if (sectores.isNotEmpty) {
        // Vérifier les catégories du premier secteur
        final categorias = await dbService.categoriaDao.getBySectorId(sectores.first.id);
        print('\n=== Catégories du secteur ${sectores.first.nombre} (${categorias.length}) ===');
        for (final categoria in categorias) {
          print('- ${categoria.id}: ${categoria.nombre}');
        }
        expect(categorias.length, 1);
        expect(categorias.first.id, "C-001");
        expect(categorias.first.nombre, "CATÉGORIE TEST");
        
        if (categorias.isNotEmpty) {
          // Vérifier les sous-catégories de la première catégorie
          final subCategorias = await dbService.subCategoriaDao.getByCategoriaId(categorias.first.id);
          print('\n=== Sous-catégories de la catégorie ${categorias.first.nombre} (${subCategorias.length}) ===');
          for (final subCategoria in subCategorias) {
            print('- ${subCategoria.id}: ${subCategoria.nombre ?? "Sans nom"}');
          }
          expect(subCategorias.length, 1);
          expect(subCategorias.first.id, "SC-001");
          expect(subCategorias.first.nombre, "SOUS-CATÉGORIE TEST");
          
          if (subCategorias.isNotEmpty) {
            // Vérifier les concepts (taxes) de la première sous-catégorie
            final conceptos = await dbService.conceptoDao.getBySubCategoriaId(subCategorias.first.id);
            print('\n=== Concepts de la sous-catégorie ${subCategorias.first.nombre ?? "Sans nom"} (${conceptos.length}) ===');
            for (final concepto in conceptos) {
              print('- ${concepto.id}: ${concepto.nombre}');
              print('  Expédition: ${concepto.tasaExpedicion}');
              print('  Renouvellement: ${concepto.tasaRenovacion}');
            }
            expect(conceptos.length, 1);
            expect(conceptos.first.id, "T-001");
            expect(conceptos.first.nombre, "TAXE TEST");
            expect(conceptos.first.tasaExpedicion, "1000");
            expect(conceptos.first.tasaRenovacion, "500");
            
            // Vérifier les documents requis
            final documents = await dbService.documentRequisDao.getByConceptoId(conceptos.first.id);
            if (documents.isNotEmpty) {
              print('  Documents requis:');
              for (final doc in documents) {
                print('    - ${doc.nombre}');
              }
            }
            expect(documents.length, 2);
            expect(documents.map((d) => d.nombre).toList()..sort(), ["Document 1", "Document 2"]..sort());
            
            // Vérifier les mots-clés
            final motsCles = await dbService.motCleDao.getMotsClesByConceptoId(conceptos.first.id);
            if (motsCles.isNotEmpty) {
              print('  Mots-clés: ${motsCles.join(", ")}');
            }
            expect(motsCles.length, 3);
            expect(motsCles.toSet(), {"test", "taxe", "exemple"}.toSet());
          }
        }
      }
    }
    
    // Fermer la base de données
    await dbService.close();
    print('\nTest terminé avec succès!');
  });
  
  test('Test de sauvegarde avec données intégrées (fallback)', () async {
    final dbService = DatabaseService();
    
    // Initialiser la base de données sans fournir de données externes
    // Le service devrait utiliser les données de test minimales intégrées
    print('Initialisation de la base de données avec données de secours...');
    await dbService.initialize(forceReset: true, seedData: true);
    print('Base de données initialisée avec succès.');
    
    // Vérifier que des données ont été chargées
    final count = await dbService.ministerioDao.count();
    expect(count, greaterThan(0), reason: "Au moins un ministère devrait être chargé");
    
    // Fermer la base de données
    await dbService.close();
    print('\nTest de données intégrées terminé avec succès!');
  });
}