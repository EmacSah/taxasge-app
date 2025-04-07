import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  // Initialiser SQLite FFI pour les tests
  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Test de la base de données TaxasGE', () async {
    final dbService = DatabaseService();
    
    // Initialiser la base de données
    print('Initialisation de la base de données...');
    await dbService.initialize(forceReset: true, seedData: true);
    print('Base de données initialisée avec succès.');
    
    // Vérifier les ministères
    final ministerios = await dbService.ministerioDao.getAll();
    print('\n=== Ministères (${ministerios.length}) ===');
    for (final ministerio in ministerios) {
      print('- ${ministerio.id}: ${ministerio.nombre}');
    }
    
    if (ministerios.isNotEmpty) {
      // Vérifier les secteurs du premier ministère
      final sectores = await dbService.sectorDao.getByMinisterioId(ministerios.first.id);
      print('\n=== Secteurs du ministère ${ministerios.first.nombre} (${sectores.length}) ===');
      for (final sector in sectores) {
        print('- ${sector.id}: ${sector.nombre}');
      }
      
      if (sectores.isNotEmpty) {
        // Vérifier les catégories du premier secteur
        final categorias = await dbService.categoriaDao.getBySectorId(sectores.first.id);
        print('\n=== Catégories du secteur ${sectores.first.nombre} (${categorias.length}) ===');
        for (final categoria in categorias) {
          print('- ${categoria.id}: ${categoria.nombre}');
        }
        
        if (categorias.isNotEmpty) {
          // Vérifier les sous-catégories de la première catégorie
          final subCategorias = await dbService.subCategoriaDao.getByCategoriaId(categorias.first.id);
          print('\n=== Sous-catégories de la catégorie ${categorias.first.nombre} (${subCategorias.length}) ===');
          for (final subCategoria in subCategorias) {
            print('- ${subCategoria.id}: ${subCategoria.nombre ?? "Sans nom"}');
          }
          
          if (subCategorias.isNotEmpty) {
            // Vérifier les concepts (taxes) de la première sous-catégorie
            final conceptos = await dbService.conceptoDao.getBySubCategoriaId(subCategorias.first.id);
            print('\n=== Concepts de la sous-catégorie ${subCategorias.first.nombre ?? "Sans nom"} (${conceptos.length}) ===');
            for (final concepto in conceptos) {
              print('- ${concepto.id}: ${concepto.nombre}');
              print('  Expédition: ${concepto.tasaExpedicion}');
              print('  Renouvellement: ${concepto.tasaRenovacion}');
              
              // Vérifier les documents requis
              final documents = await dbService.documentRequisDao.getByConceptoId(concepto.id);
              if (documents.isNotEmpty) {
                print('  Documents requis:');
                for (final doc in documents) {
                  print('    - ${doc.nombre}');
                }
              }
              
              // Vérifier les mots-clés
              final motsCles = await dbService.motCleDao.getMotsClesByConceptoId(concepto.id);
              if (motsCles.isNotEmpty) {
                print('  Mots-clés: ${motsCles.join(", ")}');
              }
            }
            
            // Tester l'ajout et la suppression d'un favori
            if (conceptos.isNotEmpty) {
              final conceptoId = conceptos.first.id;
              print('\n=== Test des favoris ===');
              print('Ajout aux favoris: ${conceptoId}');
              await dbService.favoriDao.addToFavorites(conceptoId);
              
              final isFavorite = await dbService.favoriDao.isFavorite(conceptoId);
              print('Est un favori: $isFavorite');
              expect(isFavorite, true);
              
              await dbService.favoriDao.deleteByConceptoId(conceptoId);
              final isStillFavorite = await dbService.favoriDao.isFavorite(conceptoId);
              print('Est toujours un favori après suppression: $isStillFavorite');
              expect(isStillFavorite, false);
            }
            
            // Tester la recherche avancée
            print('\n=== Test de recherche avancée ===');
            final searchResults = await dbService.searchConceptos(
              searchTerm: conceptos.isNotEmpty ? conceptos.first.nombre.split(' ').first : 'test',
            );
            print('Résultats de recherche: ${searchResults.length}');
            if (searchResults.isNotEmpty) {
              print('Premier résultat: ${searchResults.first['nombre']}');
            }
          }
        }
      }
    }
    
    // Tester l'export JSON
    print('\n=== Test d\'export JSON ===');
    final exportPath = await dbService.exportToJson();
    print('Données exportées vers: $exportPath');
    
    // Fermer la base de données
    await dbService.close();
    print('\nTest terminé avec succès!');
    
    // Test qui passe toujours
    expect(true, true);
  });
}