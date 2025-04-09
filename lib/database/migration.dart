import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

import 'schema.dart';

/// Classe qui gère les migrations de la base de données.
///
/// Cette classe est responsable de la création, mise à jour et maintenance
/// du schéma de la base de données au fil des versions de l'application.
class DatabaseMigration {
  /// Instance de la base de données
  final Database db;
  
  /// Constructeur
  DatabaseMigration(this.db);
  
  /// Exécute les migrations nécessaires pour mettre à jour la base de données.
  ///
  /// Cette méthode détermine quelles migrations doivent être exécutées en fonction
  /// de la version actuelle et de la version cible de la base de données.
  /// 
  /// [oldVersion] : La version actuelle de la base de données
  /// [newVersion] : La version cible de la base de données
  Future<void> migrate(int oldVersion, int newVersion) async {
    developer.log('Migrating database from version $oldVersion to $newVersion',
        name: 'DatabaseMigration');
    
    // Si c'est une nouvelle base de données (version 0), on crée toutes les tables
    if (oldVersion == 0) {
      await DatabaseSchema.createAllTables(db);
      return;
    }
    
    // Sinon, on exécute progressivement les migrations nécessaires
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      await _migrateToVersion(version);
    }
  }
  
  /// Exécute la migration vers une version spécifique.
  ///
  /// Cette méthode contient les instructions pour mettre à jour le schéma
  /// à une version spécifique. Chaque future version aura son propre cas.
  /// 
  /// [version] : La version cible de la migration
  Future<void> _migrateToVersion(int version) async {
    developer.log('Executing migration to version $version',
        name: 'DatabaseMigration');
    
    // Exécute la migration appropriée en fonction de la version
    switch (version) {
      case 1:
        // Version 1 : création initiale, déjà gérée dans createAllTables
        break;
      case 2:
        // Exemple de futur changement de schéma pour la version 2
        // await _migrateToVersion2();
        break;
      case 3:
        // Exemple de futur changement de schéma pour la version 3
        // await _migrateToVersion3();
        break;
      default:
        throw Exception('Migration to version $version not implemented');
    }
  }
  
  /// Exemple de méthode pour la migration vers la version 2
  Future<void> _migrateToVersion2() async {
    // Exemple : Ajout d'une colonne à la table conceptos
    // await db.execute('''
    //   ALTER TABLE ${DatabaseSchema.tableConceptos}
    //   ADD COLUMN fecha_actualizacion TEXT
    // ''');
  }
  
  /// Exemple de méthode pour la migration vers la version 3
  Future<void> _migrateToVersion3() async {
    // Exemple : Création d'une nouvelle table
    // await db.execute('''
    //   CREATE TABLE comments (
    //     id INTEGER PRIMARY KEY AUTOINCREMENT,
    //     concepto_id TEXT NOT NULL,
    //     comment TEXT NOT NULL,
    //     FOREIGN KEY (concepto_id) REFERENCES ${DatabaseSchema.tableConceptos} (id)
    //   )
    // ''');
  }
  
  /// Ouvre la base de données et exécute les migrations nécessaires
  ///
  /// Cette méthode statique est le point d'entrée principal pour initialiser
  /// et mettre à jour la base de données.
  /// 
  /// [forceReset] : Si true, la base de données sera recréée complètement
  static Future<Database> openDatabaseWithMigration({bool forceReset = false}) async {
    // Obtient le chemin de la base de données
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, DatabaseSchema.databaseName);
    
    // Supprime la base de données si la réinitialisation est forcée
    if (forceReset) {
      developer.log('Forcing database reset', name: 'DatabaseMigration');
      await deleteDatabase(path);
    }
    
    // Ouvre la base de données avec gestion de version
    return await openDatabase(
      path,
      version: DatabaseSchema.databaseVersion,
      onCreate: (Database db, int version) async {
        // Création initiale
        final migration = DatabaseMigration(db);
        await migration.migrate(0, version);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Migration pour mise à jour
        final migration = DatabaseMigration(db);
        await migration.migrate(oldVersion, newVersion);
      },
      onDowngrade: (Database db, int oldVersion, int newVersion) async {
        // En cas de déclassement (rare), on réinitialise la base de données
        developer.log('Downgrading database from $oldVersion to $newVersion, rebuilding schema',
            name: 'DatabaseMigration');
        await DatabaseSchema.dropAllTables(db);
        final migration = DatabaseMigration(db);
        await migration.migrate(0, newVersion);
      },
    );
  }
}