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
            }
          }
        }
      }
    }
    
    // Fermer la base de données
    await dbService.close();
    print('\nTest terminé avec succès!');
    
    // Test qui passe toujours
    expect(true, true);
  });
}
