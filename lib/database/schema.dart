import 'package:sqflite/sqflite.dart';

/// Classe qui définit le schéma de la base de données SQLite pour l'application TaxasGE.
/// 
/// Cette classe contient les constantes et les méthodes nécessaires pour créer et 
/// manipuler le schéma de la base de données locale.
class DatabaseSchema {
  // Nom de la base de données
  static const String databaseName = 'taxasge.db';
  
  // Version actuelle de la base de données
  static const int databaseVersion = 1;
  
  // Noms des tables
  static const String tableMinisterios = 'ministerios';
  static const String tableSectores = 'sectores';
  static const String tableCategorias = 'categorias';
  static const String tableSubCategorias = 'sub_categorias';
  static const String tableConceptos = 'conceptos';
  static const String tableDocumentosRequeridos = 'documentos_requeridos';
  static const String tableMotsCles = 'mots_cles';
  static const String tableFavoritos = 'favoritos';
  static const String tableSyncRecords = 'sync_records';
  
  // Scripts de création des tables
  
  /// Script SQL pour la création de la table des ministères
  static const String createMinisteriosTable = '''
    CREATE TABLE $tableMinisterios (
      id TEXT PRIMARY KEY,
      nombre TEXT NOT NULL
    )
  ''';
  
  /// Script SQL pour la création de la table des secteurs
  static const String createSectoresTable = '''
    CREATE TABLE $tableSectores (
      id TEXT PRIMARY KEY,
      ministerio_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      FOREIGN KEY (ministerio_id) REFERENCES $tableMinisterios (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des catégories
  static const String createCategoriasTable = '''
    CREATE TABLE $tableCategorias (
      id TEXT PRIMARY KEY,
      sector_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      FOREIGN KEY (sector_id) REFERENCES $tableSectores (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des sous-catégories
  static const String createSubCategoriasTable = '''
    CREATE TABLE $tableSubCategorias (
      id TEXT PRIMARY KEY,
      categoria_id TEXT NOT NULL,
      nombre TEXT,
      FOREIGN KEY (categoria_id) REFERENCES $tableCategorias (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des concepts (taxes)
  static const String createConceptosTable = '''
    CREATE TABLE $tableConceptos (
      id TEXT PRIMARY KEY,
      sub_categoria_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      tasa_expedicion TEXT NOT NULL,
      tasa_renovacion TEXT NOT NULL,
      procedimiento TEXT,
      FOREIGN KEY (sub_categoria_id) REFERENCES $tableSubCategorias (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des documents requis
  static const String createDocumentosRequeridosTable = '''
    CREATE TABLE $tableDocumentosRequeridos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      nombre TEXT NOT NULL,
      description TEXT,
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des mots clés
  static const String createMotsClesTable = '''
    CREATE TABLE $tableMotsCles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      mot_cle TEXT NOT NULL,
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des favoris
  static const String createFavoritosTable = '''
    CREATE TABLE $tableFavoritos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      concepto_id TEXT NOT NULL,
      fecha_agregado TEXT NOT NULL,
      FOREIGN KEY (concepto_id) REFERENCES $tableConceptos (id) ON DELETE CASCADE
    )
  ''';
  
  /// Script SQL pour la création de la table des enregistrements de synchronisation
  static const String createSyncRecordsTable = '''
    CREATE TABLE $tableSyncRecords (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      last_modified INTEGER NOT NULL,
      sync_status TEXT NOT NULL
    )
  ''';
  
  /// Liste de tous les scripts de création des tables, dans l'ordre de dépendance
  static final List<String> createTableStatements = [
    createMinisteriosTable,
    createSectoresTable,
    createCategoriasTable,
    createSubCategoriasTable,
    createConceptosTable,
    createDocumentosRequeridosTable,
    createMotsClesTable,
    createFavoritosTable,
    createSyncRecordsTable
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
    await db.execute('CREATE INDEX idx_sectores_ministerio ON $tableSectores (ministerio_id)');
    await db.execute('CREATE INDEX idx_categorias_sector ON $tableCategorias (sector_id)');
    await db.execute('CREATE INDEX idx_subcategorias_categoria ON $tableSubCategorias (categoria_id)');
    await db.execute('CREATE INDEX idx_conceptos_subcategoria ON $tableConceptos (sub_categoria_id)');
    await db.execute('CREATE INDEX idx_documentos_concepto ON $tableDocumentosRequeridos (concepto_id)');
    await db.execute('CREATE INDEX idx_motscles_concepto ON $tableMotsCles (concepto_id)');
    await db.execute('CREATE INDEX idx_favoritos_concepto ON $tableFavoritos (concepto_id)');
    
    // Index sur les mots clés pour optimiser la recherche
    await db.execute('CREATE INDEX idx_motscles_palabra ON $tableMotsCles (mot_cle)');
    
    // Index sur les dates d'ajout pour optimiser le tri des favoris
    await db.execute('CREATE INDEX idx_favoritos_fecha ON $tableFavoritos (fecha_agregado)');
    
    // Index sur les enregistrements de synchronisation
    await db.execute('CREATE INDEX idx_sync_entity ON $tableSyncRecords (entity_type, entity_id)');
    await db.execute('CREATE INDEX idx_sync_status ON $tableSyncRecords (sync_status)');
  }
  
  /// Supprime toutes les tables de la base de données
  static Future<void> dropAllTables(Database db) async {
    // Suppression en ordre inverse pour respecter les contraintes de clé étrangère
    for (final tableName in [
      tableSyncRecords,
      tableFavoritos,
      tableMotsCles,
      tableDocumentosRequeridos,
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