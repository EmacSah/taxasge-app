import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

import 'schema.dart';
import 'dao/procedure_dao.dart';

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
        // Version 2 : ajout du support multilingue
        await _migrateToVersion2();
        break;
      case 3:
        // Version 3 : ajout de la table des procédures
        await _migrateToVersion3();
        break;
      default:
        throw Exception('Migration to version $version not implemented');
    }
  }

  /// Migration vers la version 2 : ajout du support multilingue
  Future<void> _migrateToVersion2() async {
    try {
      developer.log(
          'Starting migration to version 2: Adding multilingual support',
          name: 'DatabaseMigration');

      // Vérifier si les colonnes multilinguisme existent déjà
      final List<Map<String, dynamic>> columns = await db
          .rawQuery("PRAGMA table_info(${DatabaseSchema.tableMinisterios})");

      // Si la colonne nombre_es existe déjà, la migration a déjà été faite
      final bool columnExists =
          columns.any((col) => col['name'] == 'nombre_es');

      if (columnExists) {
        developer.log('Multilingual columns already exist, skipping migration',
            name: 'DatabaseMigration');
        return;
      }

      // Ajouter les colonnes de traduction pour chaque table
      await _addMultilingualColumnsToMinisterios();
      await _addMultilingualColumnsToSectores();
      await _addMultilingualColumnsToCategories();
      await _addMultilingualColumnsToSubCategories();
      await _addMultilingualColumnsToConceptos();
      await _addMultilingualColumnsToDocumentos();

      // Créer la table des préférences linguistiques
      await db.execute(DatabaseSchema.createLanguagePrefsTable);

      // Mettre à jour la table des mots-clés pour supporter le multilinguisme
      await _updateMotsClesForMultilingual();

      // Créer les index pour les nouvelles colonnes
      await _createMultilingualIndexes();

      developer.log('Migration to version 2 completed successfully',
          name: 'DatabaseMigration');
    } catch (e) {
      developer.log('Error during migration to version 2: $e',
          name: 'DatabaseMigration');
      throw Exception('Migration to version 2 failed: $e');
    }
  }

  /// Migration vers la version 3 : ajout de la table des procédures
  Future<void> _migrateToVersion3() async {
    try {
      developer.log('Starting migration to version 3: Adding procedures table',
          name: 'DatabaseMigration');

      // Créer la table des procédures
      await db.execute(DatabaseSchema.createProcedimientosTable);

      // Créer les index pour la table des procédures
      await db.execute(
          'CREATE INDEX idx_procedimientos_concepto ON ${DatabaseSchema.tableProcedimientos} (concepto_id)');
      await db.execute(
          'CREATE INDEX idx_procedimientos_orden ON ${DatabaseSchema.tableProcedimientos} (orden)');

      // Créer des index pour les colonnes de traduction
      for (final lang in DatabaseSchema.supportedLanguages) {
        await db.execute(
            'CREATE INDEX idx_procedimientos_descr_$lang ON ${DatabaseSchema.tableProcedimientos} (description_$lang)');
      }

      // Migrer les données des procédures depuis la table des concepts
      final procedureDao = ProcedureDao(db);
      final migratedCount = await procedureDao.migrateFromConcepts();

      developer.log('Migrated $migratedCount procedures from conceptos table',
          name: 'DatabaseMigration');
      developer.log('Migration to version 3 completed successfully',
          name: 'DatabaseMigration');
    } catch (e) {
      developer.log('Error during migration to version 3: $e',
          name: 'DatabaseMigration');
      throw Exception('Migration to version 3 failed: $e');
    }
  }

  /// Ajoute les colonnes multilingues à la table des ministères
  Future<void> _addMultilingualColumnsToMinisterios() async {
    // Ajout des colonnes de langue pour les ministères
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableMinisterios} 
      ADD COLUMN nombre_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableMinisterios} 
      ADD COLUMN nombre_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableMinisterios} 
      ADD COLUMN nombre_en TEXT
    ''');

    // Copier les valeurs existantes dans les colonnes de langue par défaut
    await db.execute('''
      UPDATE ${DatabaseSchema.tableMinisterios}
      SET nombre_es = nombre
    ''');
  }

  /// Ajoute les colonnes multilingues à la table des secteurs
  Future<void> _addMultilingualColumnsToSectores() async {
    // Ajout des colonnes de langue pour les secteurs
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableSectores} 
      ADD COLUMN nombre_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableSectores} 
      ADD COLUMN nombre_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableSectores} 
      ADD COLUMN nombre_en TEXT
    ''');

    // Copier les valeurs existantes dans les colonnes de langue par défaut
    await db.execute('''
      UPDATE ${DatabaseSchema.tableSectores}
      SET nombre_es = nombre
    ''');
  }

  /// Ajoute les colonnes multilingues à la table des catégories
  Future<void> _addMultilingualColumnsToCategories() async {
    // Ajout des colonnes de langue pour les catégories
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableCategorias} 
      ADD COLUMN nombre_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableCategorias} 
      ADD COLUMN nombre_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableCategorias} 
      ADD COLUMN nombre_en TEXT
    ''');

    // Copier les valeurs existantes dans les colonnes de langue par défaut
    await db.execute('''
      UPDATE ${DatabaseSchema.tableCategorias}
      SET nombre_es = nombre
    ''');
  }

  /// Ajoute les colonnes multilingues à la table des sous-catégories
  Future<void> _addMultilingualColumnsToSubCategories() async {
    // Ajout des colonnes de langue pour les sous-catégories
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableSubCategorias} 
      ADD COLUMN nombre_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableSubCategorias} 
      ADD COLUMN nombre_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableSubCategorias} 
      ADD COLUMN nombre_en TEXT
    ''');

    // Copier les valeurs existantes dans les colonnes de langue par défaut
    await db.execute('''
      UPDATE ${DatabaseSchema.tableSubCategorias}
      SET nombre_es = nombre
    ''');
  }

  /// Ajoute les colonnes multilingues à la table des concepts
  Future<void> _addMultilingualColumnsToConceptos() async {
    // Ajout des colonnes de langue pour les noms des concepts
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN nombre_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN nombre_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN nombre_en TEXT
    ''');

    // Ajout des colonnes de langue pour les procédures des concepts
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN procedimiento_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN procedimiento_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN procedimiento_en TEXT
    ''');

    // Ajout des colonnes de langue pour les documents requis
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN documentos_requeridos_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN documentos_requeridos_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableConceptos} 
      ADD COLUMN documentos_requeridos_en TEXT
    ''');

    // Copier les valeurs existantes dans les colonnes de langue par défaut
    await db.execute('''
      UPDATE ${DatabaseSchema.tableConceptos}
      SET nombre_es = nombre,
          procedimiento_es = procedimiento,
          documentos_requeridos_es = documentos_requeridos
    ''');
  }

  /// Ajoute les colonnes multilingues à la table des documents requis
  Future<void> _addMultilingualColumnsToDocumentos() async {
    // Ajout des colonnes de langue pour les noms des documents
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableDocumentosRequeridos} 
      ADD COLUMN nombre_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableDocumentosRequeridos} 
      ADD COLUMN nombre_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableDocumentosRequeridos} 
      ADD COLUMN nombre_en TEXT
    ''');

    // Ajout des colonnes de langue pour les descriptions des documents
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableDocumentosRequeridos} 
      ADD COLUMN description_es TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableDocumentosRequeridos} 
      ADD COLUMN description_fr TEXT
    ''');
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableDocumentosRequeridos} 
      ADD COLUMN description_en TEXT
    ''');

    // Copier les valeurs existantes dans les colonnes de langue par défaut
    await db.execute('''
      UPDATE ${DatabaseSchema.tableDocumentosRequeridos}
      SET nombre_es = nombre,
          description_es = description
    ''');
  }

  /// Met à jour la table des mots-clés pour le support multilingue
  Future<void> _updateMotsClesForMultilingual() async {
    // Ajouter une colonne pour le code de langue
    await db.execute('''
      ALTER TABLE ${DatabaseSchema.tableMotsCles} 
      ADD COLUMN lang_code TEXT NOT NULL DEFAULT 'es'
    ''');
  }

  /// Crée des index pour les colonnes multilingues
  Future<void> _createMultilingualIndexes() async {
    // Index sur les noms pour accélérer la recherche textuelle (pour chaque langue)
    for (final lang in DatabaseSchema.supportedLanguages) {
      await db.execute(
          'CREATE INDEX idx_ministerios_nombre_$lang ON ${DatabaseSchema.tableMinisterios} (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_sectores_nombre_$lang ON ${DatabaseSchema.tableSectores} (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_categorias_nombre_$lang ON ${DatabaseSchema.tableCategorias} (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_subcategorias_nombre_$lang ON ${DatabaseSchema.tableSubCategorias} (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_conceptos_nombre_$lang ON ${DatabaseSchema.tableConceptos} (nombre_$lang)');
    }

    // Index sur les mots-clés pour optimiser la recherche multilingue
    await db.execute(
        'CREATE INDEX idx_motscles_language ON ${DatabaseSchema.tableMotsCles} (lang_code)');
    await db.execute(
        'CREATE INDEX idx_motscles_palabra_lang ON ${DatabaseSchema.tableMotsCles} (mot_cle, lang_code)');

    // Index sur les préférences linguistiques
    await db.execute(
        'CREATE INDEX idx_language_prefs_user ON ${DatabaseSchema.tableLanguagePrefs} (user_id)');
  }

  /// Ouvre la base de données et exécute les migrations nécessaires
  ///
  /// Cette méthode statique est le point d'entrée principal pour initialiser
  /// et mettre à jour la base de données.
  ///
  /// [forceReset] : Si true, la base de données sera recréée complètement
  static Future<Database> openDatabaseWithMigration(
      {bool forceReset = false}) async {
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
        developer.log(
            'Downgrading database from $oldVersion to $newVersion, rebuilding schema',
            name: 'DatabaseMigration');
        await DatabaseSchema.dropAllTables(db);
        final migration = DatabaseMigration(db);
        await migration.migrate(0, newVersion);
      },
    );
  }
}
