import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'migration.dart';
import 'schema.dart';
import 'dao/ministerio_dao.dart';
import 'dao/sector_dao.dart';
import 'dao/categoria_dao.dart';
import 'dao/sub_categoria_dao.dart';
import 'dao/concepto_dao.dart';
import 'dao/document_requis_dao.dart';
import 'dao/mot_cle_dao.dart';
import 'dao/favori_dao.dart';
import '../models/ministerio.dart';
import '../models/sector.dart';
import '../models/categoria.dart';
import '../models/sub_categoria.dart';
import '../models/concepto.dart';
import '../models/document_requis.dart';
import '../models/mot_cle.dart';

/// Service principal de gestion de la base de données.
///
/// Cette classe est responsable de l'initialisation de la base de données,
/// de la gestion des connexions, et de l'orchestration des opérations de données.
/// Elle agit comme une façade qui unifie l'accès à tous les DAOs.
class DatabaseService {
  /// Base de données SQLite
  Database? _db;
  
  /// DAOs
  MinisterioDao? _ministerioDao;
  SectorDao? _sectorDao;
  CategoriaDao? _categoriaDao;
  SubCategoriaDao? _subCategoriaDao;
  ConceptoDao? _conceptoDao;
  DocumentRequisDao? _documentRequisDao;
  MotCleDao? _motCleDao;
  FavoriDao? _favoriDao;
  
  /// Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  
  /// Constructeur interne pour le singleton
  DatabaseService._internal();
  
  /// Accesseur du singleton
  factory DatabaseService() => _instance;
  
  /// Vérifie si la base de données est ouverte
  bool get isOpen => _db != null;
  
  /// Getters pour les DAOs (initialisation lazy)
  MinisterioDao get ministerioDao {
    if (_ministerioDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _ministerioDao = MinisterioDao(_db!);
    }
    return _ministerioDao!;
  }
  
  SectorDao get sectorDao {
    if (_sectorDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _sectorDao = SectorDao(_db!);
    }
    return _sectorDao!;
  }
  
  CategoriaDao get categoriaDao {
    if (_categoriaDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _categoriaDao = CategoriaDao(_db!);
    }
    return _categoriaDao!;
  }
  
  SubCategoriaDao get subCategoriaDao {
    if (_subCategoriaDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _subCategoriaDao = SubCategoriaDao(_db!);
    }
    return _subCategoriaDao!;
  }
  
  ConceptoDao get conceptoDao {
    if (_conceptoDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _conceptoDao = ConceptoDao(_db!);
    }
    return _conceptoDao!;
  }
  
  DocumentRequisDao get documentRequisDao {
    if (_documentRequisDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _documentRequisDao = DocumentRequisDao(_db!);
    }
    return _documentRequisDao!;
  }
  
  MotCleDao get motCleDao {
    if (_motCleDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _motCleDao = MotCleDao(_db!);
    }
    return _motCleDao!;
  }
  
  FavoriDao get favoriDao {
    if (_favoriDao == null) {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      _favoriDao = FavoriDao(_db!);
    }
    return _favoriDao!;
  }
  
  /// Initialise la base de données.
  ///
  /// Cette méthode doit être appelée avant toute autre opération sur la base de données.
  /// [forceReset] : Si true, la base de données sera recréée complètement.
  /// [seedData] : Si true et que la base de données est vide ou recréée, les données initiales seront importées.
  /// [testJsonString] : Pour les tests, permet de fournir directement des données JSON au lieu de les charger depuis les assets.
  Future<void> initialize({bool forceReset = false, bool seedData = true, String? testJsonString}) async {
    if (_db != null && !forceReset) {
      developer.log('Database already initialized', name: 'DatabaseService');
      return;
    }
    
    try {
      developer.log('Initializing database...', name: 'DatabaseService');
      
      // Si la base de données est déjà ouverte, la fermer d'abord
      if (_db != null) {
        await _db!.close();
        _db = null;
        _resetDaos();
      }
      
      // Ouvrir la base de données avec gestion de migration
      _db = await DatabaseMigration.openDatabaseWithMigration(forceReset: forceReset);
      
      developer.log('Database initialized successfully', name: 'DatabaseService');
      
      // Initialiser les DAOs (si nécessaire)
      _initDaos();
      
      // Si la base de données est vide ou a été réinitialisée, importer les données initiales
      if (seedData) {
        final ministerioCount = await ministerioDao.count();
        
        if (ministerioCount == 0 || forceReset) {
          developer.log('Seeding database with initial data...', name: 'DatabaseService');
          await _importInitialData(testJsonString: testJsonString);
        }
      }
    } catch (e) {
      developer.log('Error initializing database: $e', name: 'DatabaseService');
      throw Exception('Could not initialize database: $e');
    }
  }
  
  /// Initialise tous les DAOs.
  void _initDaos() {
    if (_db == null) {
      throw Exception('Cannot initialize DAOs: Database not initialized');
    }
    
    _ministerioDao = MinisterioDao(_db!);
    _sectorDao = SectorDao(_db!);
    _categoriaDao = CategoriaDao(_db!);
    _subCategoriaDao = SubCategoriaDao(_db!);
    _conceptoDao = ConceptoDao(_db!);
    _documentRequisDao = DocumentRequisDao(_db!);
    _motCleDao = MotCleDao(_db!);
    _favoriDao = FavoriDao(_db!);
  }
  
  /// Réinitialise tous les DAOs.
  void _resetDaos() {
    _ministerioDao = null;
    _sectorDao = null;
    _categoriaDao = null;
    _subCategoriaDao = null;
    _conceptoDao = null;
    _documentRequisDao = null;
    _motCleDao = null;
    _favoriDao = null;
  }
  
  /// Ferme la base de données.
  ///
  /// Cette méthode doit être appelée lorsque l'application se termine
  /// pour libérer les ressources.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _resetDaos();
      developer.log('Database closed', name: 'DatabaseService');
    }
  }
  
  /// Importe les données initiales depuis le fichier JSON.
  ///
  /// Cette méthode lit le fichier JSON contenant les données fiscales
  /// et les importe dans la base de données.
  /// [testJsonString] : Pour les tests, permet de fournir directement des données JSON au lieu de les charger depuis les assets.
  Future<void> _importInitialData({String? testJsonString}) async {
    try {
      // Charger le fichier JSON depuis les assets ou utiliser les données de test
      final String jsonString;
      if (testJsonString != null) {
        jsonString = testJsonString;
      } else {
        try {
          jsonString = await rootBundle.loadString('assets/data/taxes.json');
        } catch (e) {
          // Données de test minimales pour les environnements sans assets
          developer.log('Failed to load assets, using minimal test data', name: 'DatabaseService');
          jsonString = '''[
            {
              "id": "M-001",
              "nombre": "MINISTÈRE TEST",
              "sectores": [
                {
                  "id": "S-001",
                  "nombre": "SECTEUR TEST",
                  "categorias": [
                    {
                      "id": "C-001",
                      "nombre": "CATÉGORIE TEST",
                      "sub_categorias": [
                        {
                          "id": "SC-001",
                          "nombre": "SOUS-CATÉGORIE TEST",
                          "conceptos": [
                            {
                              "id": "T-001",
                              "nombre": "TAXE TEST",
                              "tasa_expedicion": "1000",
                              "tasa_renovacion": "500",
                              "documentos_requeridos": "Document 1\\nDocument 2",
                              "procedimiento": "Procédure test",
                              "palabras_clave": "test, taxe, exemple"
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]''';
        }
      }
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Importer les données dans une transaction pour assurer l'intégrité
      await _db!.transaction((txn) async {
        final ministerios = <Ministerio>[];
        final sectores = <Sector>[];
        final categorias = <Categoria>[];
        final subCategorias = <SubCategoria>[];
        final conceptos = <Concepto>[];
        final documentosMap = <String, List<DocumentRequis>>{};
        final motsClesMap = <String, List<String>>{};
        
        // Parcourir les ministères
        for (final ministerioJson in jsonData) {
          final ministerio = Ministerio.fromJson(ministerioJson);
          ministerios.add(ministerio);
          
          // Parcourir les secteurs de chaque ministère
          if (ministerioJson['sectores'] != null) {
            for (final sectorJson in ministerioJson['sectores']) {
              final sector = Sector.fromJson(sectorJson);
              sector.ministerioId = ministerio.id;
              sectores.add(sector);
              
              // Parcourir les catégories de chaque secteur
              if (sectorJson['categorias'] != null) {
                for (final categoriaJson in sectorJson['categorias']) {
                  final categoria = Categoria.fromJson(categoriaJson);
                  categoria.sectorId = sector.id;
                  categorias.add(categoria);
                  
                  // Parcourir les sous-catégories de chaque catégorie
                  if (categoriaJson['sub_categorias'] != null) {
                    for (final subCategoriaJson in categoriaJson['sub_categorias']) {
                      final subCategoria = SubCategoria.fromJson(subCategoriaJson);
                      subCategoria.categoriaId = categoria.id;
                      subCategorias.add(subCategoria);
                      
                      // Parcourir les concepts (taxes) de chaque sous-catégorie
                      if (subCategoriaJson['conceptos'] != null) {
                        for (final conceptoJson in subCategoriaJson['conceptos']) {
                          final concepto = Concepto.fromJson(conceptoJson);
                          concepto.subCategoriaId = subCategoria.id;
                          conceptos.add(concepto);
                          
                          // Traiter les documents requis (s'il y en a)
                          if (conceptoJson['documentos_requeridos'] != null && 
                              conceptoJson['documentos_requeridos'].toString().trim().isNotEmpty) {
                            final docsString = conceptoJson['documentos_requeridos'].toString();
                            final docsList = docsString.split('\n')
                                .where((doc) => doc.trim().isNotEmpty)
                                .map((doc) => doc.trim())
                                .toList();
                            
                            final documents = <DocumentRequis>[];
                            for (final docName in docsList) {
                              documents.add(DocumentRequis(
                                id: 0, // Auto-généré
                                conceptoId: concepto.id,
                                nombre: docName,
                                description: null,
                              ));
                            }
                            
                            documentosMap[concepto.id] = documents;
                          }
                          
                          // Traiter les mots-clés (s'il y en a)
                          if (conceptoJson['palabras_clave'] != null && 
                              conceptoJson['palabras_clave'].toString().trim().isNotEmpty) {
                            final keywordsString = conceptoJson['palabras_clave'].toString();
                            final keywordsList = keywordsString.split(',')
                                .map((word) => word.trim().toLowerCase())
                                .where((word) => word.isNotEmpty)
                                .toList();
                            
                            motsClesMap[concepto.id] = keywordsList;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        
        // Insérer les données dans la base de données
        developer.log('Inserting ${ministerios.length} ministerios...', name: 'DatabaseService');
        for (final ministerio in ministerios) {
          await txn.insert(
            DatabaseSchema.tableMinisterios,
            ministerio.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        developer.log('Inserting ${sectores.length} sectores...', name: 'DatabaseService');
        for (final sector in sectores) {
          await txn.insert(
            DatabaseSchema.tableSectores,
            sector.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        developer.log('Inserting ${categorias.length} categorias...', name: 'DatabaseService');
        for (final categoria in categorias) {
          await txn.insert(
            DatabaseSchema.tableCategorias,
            categoria.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        developer.log('Inserting ${subCategorias.length} subCategorias...', name: 'DatabaseService');
        for (final subCategoria in subCategorias) {
          await txn.insert(
            DatabaseSchema.tableSubCategorias,
            subCategoria.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        developer.log('Inserting ${conceptos.length} conceptos...', name: 'DatabaseService');
        for (final concepto in conceptos) {
          await txn.insert(
            DatabaseSchema.tableConceptos,
            concepto.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        // Insérer les documents requis
        for (final entry in documentosMap.entries) {
          final conceptoId = entry.key;
          final documents = entry.value;
          
          for (final doc in documents) {
            await txn.insert(
              DatabaseSchema.tableDocumentosRequeridos,
              doc.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        
        // Insérer les mots-clés
        for (final entry in motsClesMap.entries) {
          final conceptoId = entry.key;
          final keywords = entry.value;
          
          for (final keyword in keywords) {
            await txn.insert(
              DatabaseSchema.tableMotsCles,
              {
                'concepto_id': conceptoId,
                'mot_cle': keyword,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
      
      developer.log('Initial data imported successfully', name: 'DatabaseService');
    } catch (e) {
      developer.log('Error importing initial data: $e', name: 'DatabaseService');
      throw Exception('Could not import initial data: $e');
    }
  }
  
  /// Efface toutes les données de la base de données.
  ///
  /// Cette méthode est utile pour les tests ou pour réinitialiser l'application.
  Future<void> clearAllData() async {
    try {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      
      developer.log('Clearing all data from database...', name: 'DatabaseService');
      
      await _db!.transaction((txn) async {
        await txn.delete(DatabaseSchema.tableFavoritos);
        await txn.delete(DatabaseSchema.tableMotsCles);
        await txn.delete(DatabaseSchema.tableDocumentosRequeridos);
        await txn.delete(DatabaseSchema.tableConceptos);
        await txn.delete(DatabaseSchema.tableSubCategorias);
        await txn.delete(DatabaseSchema.tableCategorias);
        await txn.delete(DatabaseSchema.tableSectores);
        await txn.delete(DatabaseSchema.tableMinisterios);
        await txn.delete(DatabaseSchema.tableSyncRecords);
      });
      
      developer.log('All data cleared from database', name: 'DatabaseService');
    } catch (e) {
      developer.log('Error clearing data: $e', name: 'DatabaseService');
      throw Exception('Could not clear data: $e');
    }
  }
  
  /// Exporte toutes les données de la base de données vers un fichier JSON.
  ///
  /// Cette méthode est utile pour sauvegarder les données ou pour les déboguer.
  /// [path] : Le chemin du fichier où exporter les données. Si null, un fichier
  /// sera créé dans le répertoire temporaire de l'application.
  Future<String> exportToJson({String? path}) async {
    try {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      
      developer.log('Exporting database to JSON...', name: 'DatabaseService');
      
      // Récupérer toutes les données
      final ministerios = await ministerioDao.getAll(orderBy: 'id');
      final Map<String, dynamic> exportData = {'ministerios': []};
      
      for (final ministerio in ministerios) {
        final ministerioMap = ministerio.toMap();
        final sectores = await sectorDao.getByMinisterioId(ministerio.id, orderBy: 'id');
        ministerioMap['sectores'] = [];
        
        for (final sector in sectores) {
          final sectorMap = sector.toMap();
          final categorias = await categoriaDao.getBySectorId(sector.id, orderBy: 'id');
          sectorMap['categorias'] = [];
          
          for (final categoria in categorias) {
            final categoriaMap = categoria.toMap();
            final subCategorias = await subCategoriaDao.getByCategoriaId(categoria.id, orderBy: 'id');
            categoriaMap['sub_categorias'] = [];
            
            for (final subCategoria in subCategorias) {
              final subCategoriaMap = subCategoria.toMap();
              final conceptos = await conceptoDao.getBySubCategoriaId(subCategoria.id, orderBy: 'id');
              subCategoriaMap['conceptos'] = [];
              
              for (final concepto in conceptos) {
                final conceptoMap = concepto.toMap();
                
                // Récupérer les documents requis
                final documents = await documentRequisDao.getByConceptoId(concepto.id);
                if (documents.isNotEmpty) {
                  conceptoMap['documentos_requeridos'] = documents
                      .map((doc) => doc.nombre)
                      .join('\n');
                }
                
                // Récupérer les mots-clés
                final keywords = await motCleDao.getMotsClesByConceptoId(concepto.id);
                if (keywords.isNotEmpty) {
                  conceptoMap['palabras_clave'] = keywords.join(', ');
                }
                
                subCategoriaMap['conceptos'].add(conceptoMap);
              }
              
              categoriaMap['sub_categorias'].add(subCategoriaMap);
            }
            
            sectorMap['categorias'].add(categoriaMap);
          }
          
          ministerioMap['sectores'].add(sectorMap);
        }
        
        exportData['ministerios'].add(ministerioMap);
      }
      
      // Écrire les données dans un fichier
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData['ministerios']);
      
      late final String filePath;
      if (path != null) {
        filePath = path;
      } else {
        final dir = await getTemporaryDirectory();
        filePath = join(dir.path, 'taxasge_export_${DateTime.now().millisecondsSinceEpoch}.json');
      }
      
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      developer.log('Database exported to JSON: $filePath', name: 'DatabaseService');
      return filePath;
    } catch (e) {
      developer.log('Error exporting database to JSON: $e', name: 'DatabaseService');
      throw Exception('Could not export database to JSON: $e');
    }
  }
  
  /// Recherche des concepts (taxes) en fonction de critères.
  ///
  /// Cette méthode est une façade pour la méthode `advancedSearch` du DAO de concept,
  /// mais elle ajoute la logique pour récupérer les mots-clés et documents associés.
  Future<List<Map<String, dynamic>>> searchConceptos({
    String? searchTerm,
    String? ministerioId,
    String? sectorId,
    String? categoriaId,
    String? subCategoriaId,
    String? maxTasaExpedicion,
    String? maxTasaRenovacion,
  }) async {
    try {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      
      // Effectuer la recherche de base
      final conceptos = await conceptoDao.advancedSearch(
        searchTerm: searchTerm,
        ministerioId: ministerioId,
        sectorId: sectorId,
        categoriaId: categoriaId,
        subCategoriaId: subCategoriaId,
        maxTasaExpedicion: maxTasaExpedicion,
        maxTasaRenovacion: maxTasaRenovacion,
      );
      
      // Enrichir les résultats avec les informations supplémentaires
      final results = <Map<String, dynamic>>[];
      
      for (final concepto in conceptos) {
        final result = concepto.toMap();
        
        // Récupérer les documents requis
        final documents = await documentRequisDao.getByConceptoId(concepto.id);
        result['documentos'] = documents.map((doc) => doc.toMap()).toList();
        
        // Récupérer les mots-clés
        final keywords = await motCleDao.getMotsClesByConceptoId(concepto.id);
        result['palabras_clave'] = keywords;
        
        // Vérifier si ce concept est un favori
        result['es_favorito'] = await favoriDao.isFavorite(concepto.id);
        
        // Récupérer les informations hiérarchiques (pour l'affichage du chemin)
        final subCategoria = await subCategoriaDao.getById(concepto.subCategoriaId);
        if (subCategoria != null) {
          result['sub_categoria_nombre'] = subCategoria.nombre;
          
          final categoria = await categoriaDao.getById(subCategoria.categoriaId);
          if (categoria != null) {
            result['categoria_nombre'] = categoria.nombre;
            
            final sector = await sectorDao.getById(categoria.sectorId);
            if (sector != null) {
              result['sector_nombre'] = sector.nombre;
              
              final ministerio = await ministerioDao.getById(sector.ministerioId);
              if (ministerio != null) {
                result['ministerio_nombre'] = ministerio.nombre;
              }
            }
          }
        }
        
        results.add(result);
      }
      
      return results;
    } catch (e) {
      developer.log('Error searching conceptos: $e', name: 'DatabaseService');
      throw Exception('Could not search conceptos: $e');
    }
  }
  
  /// Récupère un concept avec toutes ses relations et informations hiérarchiques.
  ///
  /// Cette méthode est utile pour afficher les détails complets d'une taxe.
  Future<Map<String, dynamic>?> getConceptoWithDetails(String conceptoId) async {
    try {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      
      final concepto = await conceptoDao.getById(conceptoId);
      if (concepto == null) {
        return null;
      }
      
      // Construire le résultat enrichi
      final result = concepto.toMap();
      
      // Récupérer les documents requis
      final documents = await documentRequisDao.getByConceptoId(conceptoId);
      result['documentos'] = documents.map((doc) => doc.toMap()).toList();
      
      // Récupérer les mots-clés
      final keywords = await motCleDao.getMotsClesByConceptoId(conceptoId);
      result['palabras_clave'] = keywords;
      
      // Vérifier si ce concept est un favori
      result['es_favorito'] = await favoriDao.isFavorite(conceptoId);
      
      // Récupérer les informations hiérarchiques
      final subCategoria = await subCategoriaDao.getById(concepto.subCategoriaId);
      if (subCategoria != null) {
        result['sub_categoria'] = subCategoria.toMap();
        
        final categoria = await categoriaDao.getById(subCategoria.categoriaId);
        if (categoria != null) {
          result['categoria'] = categoria.toMap();
          
          final sector = await sectorDao.getById(categoria.sectorId);
          if (sector != null) {
            result['sector'] = sector.toMap();
            
            final ministerio = await ministerioDao.getById(sector.ministerioId);
            if (ministerio != null) {
              result['ministerio'] = ministerio.toMap();
            }
          }
        }
      }
      
      return result;
    } catch (e) {
      developer.log('Error getting concepto with details: $e', name: 'DatabaseService');
      throw Exception('Could not get concepto with details: $e');
    }
  }
  
  /// Récupère tous les favoris avec les détails des concepts associés.
  ///
  /// Cette méthode est utile pour afficher la liste des favoris.
  Future<List<Map<String, dynamic>>> getFavoritesWithDetails() async {
    try {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      
      final favoris = await favoriDao.getAll();
      final results = <Map<String, dynamic>>[];
      
      for (final favori in favoris) {
        final result = favori.toMap();
        
        // Récupérer le concept associé
        final conceptoDetails = await getConceptoWithDetails(favori.conceptoId);
        if (conceptoDetails != null) {
          result['concepto'] = conceptoDetails;
          results.add(result);
        }
      }
      
      return results;
    } catch (e) {
      developer.log('Error getting favorites with details: $e', name: 'DatabaseService');
      throw Exception('Could not get favorites with details: $e');
    }
  }
  
  /// Récupère la taille de la base de données en octets.
  ///
  /// Cette méthode est utile pour le débogage ou pour informer l'utilisateur
  /// sur l'espace occupé par l'application.
  Future<int> getDatabaseSize() async {
    try {
      if (_db == null) {
        throw Exception('Database not initialized');
      }
      
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, DatabaseSchema.databaseName);
      final file = File(path);
      
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      
      return 0;
    } catch (e) {
      developer.log('Error getting database size: $e', name: 'DatabaseService');
      throw Exception('Could not get database size: $e');
    }
  }
}