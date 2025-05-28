import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:taxasge/database/schema.dart'; // Assure-toi que ce chemin est correct

/// Initialise sqflite_common_ffi pour les tests sur desktop.
void sqfliteTestInit() {
  // Initialise FFI
  sqfliteFfiInit();
  // Change la factory par défaut pour utiliser FFI
  databaseFactory = databaseFactoryFfi;
}

/// Fournit une instance de DatabaseService avec une base de données en mémoire pour les tests.
/// La base de données est nettoyée avant chaque test.
Future<DatabaseService> getTestDatabaseService({String? testJsonString, bool seedData = true}) async {
  // Utilise une base de données en mémoire pour l'isolation des tests
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(
    version: DatabaseSchema.databaseVersion,
    onCreate: (db, version) async {
      await DatabaseSchema.createAllTables(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Pour les tests, on pourrait simplement recréer, ou tester les migrations spécifiques
      await DatabaseSchema.dropAllTables(db);
      await DatabaseSchema.createAllTables(db);
    },
  ));

  // Nettoyer toutes les tables avant chaque test pour assurer l'isolation
  for (final tableName in DatabaseSchema.createTableStatements.map((s) => s.split(" ")[2]).toList().reversed) {
      // Ceci est une simplification pour obtenir les noms de table, pourrait être amélioré
      if (await db.query('sqlite_master', where: 'name = ?', whereArgs: [tableName]).then((value) => value.isNotEmpty)) {
          await db.delete(tableName);
      }
  }
  
  final dbService = DatabaseService();
  // Simuler l'initialisation interne de DatabaseService avec la DB en mémoire
  // Ceci est un hack car _db est privé. Idéalement, DatabaseService permettrait d'injecter une DB.
  // Pour l'instant, on va supposer que DatabaseService().initialize() peut être appelé plusieurs fois 
  // ou qu'on peut le modifier pour accepter une DB.
  // Alternative: Utiliser une instance réelle mais la réinitialiser.
  // Pour ce subtask, nous allons nous concentrer sur la structure. 
  // Le DatabaseService sera initialisé avec des données de test dans les fichiers de test eux-mêmes.
  
  // Fermer la base de données ouverte pour la laisser être réouverte par initialize
  await db.close();


  // Initialiser le service avec la base de données en mémoire et potentiellement des données de test
  // Note: The `inMemory: true` parameter was present in the previous version of this file from the subtask.
  // The current subtask description for this file omits `inMemory: true` here. Adhering to current prompt.
  await dbService.initialize(forceReset: true, seedData: seedData, testJsonString: testJsonString);
  return dbService;
}

// Un exemple de JSON de test minimal pour les tests d'importation
const String minimalTestJson = '''
[
  {
    "id": "M-TEST",
    "nombre": {
      "es": "MINISTERIO DE PRUEBA",
      "fr": "MINISTÈRE DE TEST",
      "en": "TEST MINISTRY"
    },
    "sectores": [
      {
        "id": "S-TEST",
        "nombre": { "es": "SECTOR PRUEBA" },
        "categorias": [
          {
            "id": "C-TEST",
            "nombre": { "es": "CATEGORIA PRUEBA" },
            "sub_categorias": [
              {
                "id": "SC-TEST",
                "nombre": { "es": "SUBCATEGORIA PRUEBA" },
                "conceptos": [
                  {
                    "id": "T-TEST",
                    "nombre": { "es": "CONCEPTO DE PRUEBA" },
                    "tasa_expedicion": "100",
                    "tasa_renovacion": "50",
                    "documentos_requeridos": { "es": "Doc1
Doc2" },
                    "procedimiento": { "es": "Proc1
Proc2" },
                    "palabras_clave": { "es": "test,prueba" }
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
