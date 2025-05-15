import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'dart:convert'; // Ajoutez cet import pour utiliser jsonDecode

void main() {
  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Test de la base de données TaxasGE avec fichier de test', () async {
    final dbService = DatabaseService();

    // Lire le fichier JSON de test
    final file = File('test/test_assets/test_taxes.json');
    final testJsonString = await file.readAsString();

    // Afficher le contenu du fichier JSON
    print('Contenu du fichier JSON de test:');
    print(testJsonString);

    // Convertir la chaîne JSON en objet Dart pour une meilleure visualisation
    final testJson = jsonDecode(testJsonString);
    print('Données JSON décodées: $testJson');

    // Initialiser la base de données avec les données de test
    print('Initialisation de la base de données avec données de test...');
    await dbService.initialize(
        forceReset: true, seedData: true, testJsonString: testJsonString);
    print('Base de données initialisée avec succès.');

    // Vos assertions et vérifications ici...

    // Fermer la base de données
    await dbService.close();
    print('\nTest terminé avec succès!');
  });

  test('Test de sauvegarde avec données intégrées (fallback)', () async {
    final dbService = DatabaseService();

    // Initialiser la base de données sans fournir de données externes
    print('Initialisation de la base de données avec données de secours...');
    await dbService.initialize(forceReset: true, seedData: true);
    print('Base de données initialisée avec succès.');

    // Vérifier que des données ont été chargées
    final count = await dbService.ministerioDao.count();
    expect(count, greaterThan(0),
        reason: "Au moins un ministère devrait être chargé");

    // Fermer la base de données
    await dbService.close();
    print('\nTest de données intégrées terminé avec succès!');
  });
}
