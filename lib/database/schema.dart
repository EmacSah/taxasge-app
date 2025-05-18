import 'package:sqflite/sqflite.dart';

/// Classe qui définit le schéma de la base de données SQLite pour l'application TaxasGE.
///
/// Cette classe contient les constantes et les méthodes nécessaires pour créer et
/// manipuler le schéma de la base de données locale, avec support multilingue.
class DatabaseSchema {
  // Nom de la base de données
  static const String databaseName = 'taxasge.db';

  // Version actuelle de la base de données
  static const int databaseVersion = 3; // Mise à jour pour le support des procédures

  // Langues supportées par l'application
  static const List<String> supportedLanguages = ['es', 'fr', 'en'];

  // Langue par défaut
  static const String defaultLanguage = 'es';

  // Noms des tables
  static const String tableMinisterios = 'ministerios';
  static const String tableSectores = 'sectores';
  static const String tableCategorias = 'categorias';
  static const String tableSubCategorias = 'sub_categorias';
  static const String tableConceptos = 'conceptos';
  static const String tableProcedimientos = 'procedimientos'; // Nouvelle table pour les procédures
  static const String tableDocumentosRequeridos = 'documentos_requeridos';
  static const String tableMotsCles = 'mots_cles';
  static const String tableFavoritos = 'favoritos';
  static const String tableSyncRecords = 'sync_records';
  static const String tableLanguagePrefs = 'language_prefs';

  // Scripts de création des tables

  /// Script SQL pour la création de la table des ministères avec support multilingue
  static const String createMinisteriosTable = '''
    CREATE TABLE $tableMinisterios (
      id TEXT PRIMARY KEY,
      nombre TEXT NOT NULL,
      nombre_es TEXT,
      nombre_fr TEXT,
      nombre_en TEXT
    )
  ''';

  /// Script SQL pour la création de la table des secteurs avec support multilingue
  static const String createSectoresTable = '''
    CREATE TABLE $tableSectores (
      id TEXT PRIMARY KEY,
      ministerio_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      nombre_es TEXT,
      nombre_fr TEXT,
      nombre_en TEXT,
      FOREIGN KEY (ministerio_id) REFERENCES $tableMinisterios (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des catégories avec support multilingue
  static const String createCategoriasTable = '''
    CREATE TABLE $tableCategorias (
      id TEXT PRIMARY KEY,
      sector_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      nombre_es TEXT,
      nombre_fr TEXT,
      nombre_en TEXT,
      FOREIGN KEY (sector_id) REFERENCES $tableSectores (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des sous-catégories avec support multilingue
  static const String createSubCategoriasTable = '''
    CREATE TABLE $tableSubCategorias (
      id TEXT PRIMARY KEY,
      categoria_id TEXT NOT NULL,
      nombre TEXT,
      nombre_es TEXT,
      nombre_fr TEXT,
      nombre_en TEXT,
      FOREIGN KEY (categoria_id) REFERENCES $tableCategorias (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des concepts (taxes) avec support multilingue
  static const String createConceptosTable = '''
    CREATE TABLE $tableConceptos (
      id TEXT PRIMARY KEY,
      sub_categoria_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      nombre_es TEXT,
      nombre_fr TEXT,
      nombre_en TEXT,
      tasa_expedicion TEXT NOT NULL,
      tasa_renovacion TEXT NOT NULL,
      documentos_requeridos TEXT,
      documentos_requeridos_es TEXT,
      documentos_requeridos_fr TEXT,
      documentos_requeridos_en TEXT,
      procedimiento TEXT,
      procedimiento_es TEXT,
      procedimiento_fr TEXT,
      procedimiento_en TEXT,
      FOREIGN KEY (sub_categoria_id) REFERENCES $tableSubCategorias (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des procédures avec support multilingue
  static const String createProcedimientosTable = '''
    CREATE TABLE $tableProcedimientos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      description TEXT NOT NULL,
      description_es TEXT,
      description_fr TEXT,
      description_en TEXT,
      orden INTEGER,
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des documents requis avec support multilingue
  static const String createDocumentosRequeridosTable = '''
    CREATE TABLE $tableDocumentosRequeridos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      nombre_es TEXT,
      nombre_fr TEXT,
      nombre_en TEXT,
      description TEXT,
      description_es TEXT,
      description_fr TEXT,
      description_en TEXT,
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des mots clés avec support multilingue
  static const String createMotsClesTable = '''
    CREATE TABLE $tableMotsCles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      mot_cle TEXT NOT NULL,
      lang_code TEXT NOT NULL DEFAULT '$defaultLanguage',
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des favoris (inchangée)
  static const String createFavoritosTable = '''
    CREATE TABLE $tableFavoritos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      fecha_agregado TEXT NOT NULL,
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';

  /// Script SQL pour la création de la table des enregistrements de synchronisation (inchangée)
  static const String createSyncRecordsTable = '''
    CREATE TABLE $tableSyncRecords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      last_modified INTEGER NOT NULL,
      sync_status TEXT NOT NULL
    )
  ''';

  /// Script SQL pour la création de la table des préférences linguistiques (nouvelle)
  static const String createLanguagePrefsTable = '''
    CREATE TABLE $tableLanguagePrefs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT,
      preferred_language TEXT NOT NULL DEFAULT '$defaultLanguage',
      fallback_language TEXT NOT NULL DEFAULT '$defaultLanguage',
      last_updated TEXT NOT NULL
    )
  ''';

  /// Liste de tous les scripts de création des tables, dans l'ordre de dépendance
  static final List<String> createTableStatements = [
    createMinisteriosTable,
    createSectoresTable,
    createCategoriasTable,
    createSubCategoriasTable,
    createConceptosTable,
    createProcedimientosTable, // Ajout de la nouvelle table
    createDocumentosRequeridosTable,
    createMotsClesTable,
    createFavoritosTable,
    createSyncRecordsTable,
    createLanguagePrefsTable
  ];

  /// Crée toutes les tables de la base de données
  static Future<void> createAllTables(Database db) async {
    for (final statement in createTableStatements) {
      await db.execute(statement);
    }

    // Création des index pour optimiser les performances
    await _createIndexes(db);
  }

  /// Crée les index pour optimiser les performances des requêtes fréquentes
  static Future<void> _createIndexes(Database db) async {
    // Index sur les clés étrangères pour accélérer les jointures
    await db.execute(
        'CREATE INDEX idx_sectores_ministerio ON $tableSectores (ministerio_id)');
    await db.execute(
        'CREATE INDEX idx_categorias_sector ON $tableCategorias (sector_id)');
    await db.execute(
        'CREATE INDEX idx_subcategorias_categoria ON $tableSubCategorias (categoria_id)');
    await db.execute(
        'CREATE INDEX idx_conceptos_subcategoria ON $tableConceptos (sub_categoria_id)');
    await db.execute(
        'CREATE INDEX idx_procedimientos_concepto ON $tableProcedimientos (concepto_id)'); // Nouvel index
    await db.execute(
        'CREATE INDEX idx_documentos_concepto ON $tableDocumentosRequeridos (concepto_id)');
    await db.execute(
        'CREATE INDEX idx_motscles_concepto ON $tableMotsCles (concepto_id)');
    await db.execute(
        'CREATE INDEX idx_favoritos_concepto ON $tableFavoritos (concepto_id)');

    // Index sur les noms pour accélérer la recherche textuelle (pour chaque langue)
    for (final lang in supportedLanguages) {
      await db.execute(
          'CREATE INDEX idx_ministerios_nombre_$lang ON $tableMinisterios (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_sectores_nombre_$lang ON $tableSectores (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_categorias_nombre_$lang ON $tableCategorias (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_subcategorias_nombre_$lang ON $tableSubCategorias (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_conceptos_nombre_$lang ON $tableConceptos (nombre_$lang)');
      await db.execute(
          'CREATE INDEX idx_procedimientos_descr_$lang ON $tableProcedimientos (description_$lang)'); // Nouvel index
    }

    // Index sur l'ordre des procédures
    await db.execute(
        'CREATE INDEX idx_procedimientos_orden ON $tableProcedimientos (orden)');

    // Index sur les mots clés pour optimiser la recherche multilingue
    await db.execute(
        'CREATE INDEX idx_motscles_palabra ON $tableMotsCles (mot_cle)');
    await db.execute(
        'CREATE INDEX idx_motscles_language ON $tableMotsCles (lang_code)');
    await db.execute(
        'CREATE INDEX idx_motscles_palabra_lang ON $tableMotsCles (mot_cle, lang_code)');

    // Index sur les dates d'ajout pour optimiser le tri des favoris
    await db.execute(
        'CREATE INDEX idx_favoritos_fecha ON $tableFavoritos (fecha_agregado)');

    // Index sur les enregistrements de synchronisation
    await db.execute(
        'CREATE INDEX idx_sync_entity ON $tableSyncRecords (entity_type, entity_id)');
    await db.execute(
        'CREATE INDEX idx_sync_status ON $tableSyncRecords (sync_status)');

    // Index sur les préférences linguistiques
    await db.execute(
        'CREATE INDEX idx_language_prefs_user ON $tableLanguagePrefs (user_id)');
  }

  /// Supprime toutes les tables de la base de données
  static Future<void> dropAllTables(Database db) async {
    // Suppression en ordre inverse pour respecter les contraintes de clé étrangère
    for (final tableName in [
      tableLanguagePrefs,
      tableSyncRecords,
      tableFavoritos,
      tableMotsCles,
      tableDocumentosRequeridos,
      tableProcedimientos, // Ajout de la nouvelle table
      tableConceptos,
      tableSubCategorias,
      tableCategorias,
      tableSectores,
      tableMinisterios
    ]) {
      await db.execute('DROP TABLE IF EXISTS $tableName');
    }
  }
}