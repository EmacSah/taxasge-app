import 'package:sqflite/sqflite.dart';
import '../../models/document_requis.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des documents requis avec support multilingue.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des documents requis dans la base de données.
class DocumentRequisDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  DocumentRequisDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableDocumentosRequeridos;
  
  /// Langues supportées
  final List<String> _supportedLanguages = DatabaseSchema.supportedLanguages;
  
  /// Insère un nouveau document requis dans la base de données.
  ///
  /// Retourne l'ID du document inséré.
  /// Lève une exception en cas d'erreur.
  Future<int> insert(DocumentRequis document) async {
    try {
      return await _db.insert(
        _tableName,
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not insert document_requis: $e');
    }
  }
  
  /// Insère plusieurs documents requis en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les documents un par un
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<DocumentRequis> documents) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final document in documents) {
          batch.insert(
            _tableName,
            document.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not insert document_requis: $e');
    }
  }
  
  /// Récupère un document requis par son ID.
  ///
  /// Retourne null si aucun document n'est trouvé avec cet ID.
  Future<DocumentRequis?> getById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return DocumentRequis.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting document_requis by id: $e', name: 'DocumentRequisDao');
      throw Exception('Could not get document_requis: $e');
    }
  }
  
  /// Récupère tous les documents requis.
  ///
  /// Les documents sont optionnellement triés par le champ spécifié.
  Future<List<DocumentRequis>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy,
      );
      
      return maps.map((map) => DocumentRequis.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not get document_requis: $e');
    }
  }
  
  /// Récupère tous les documents requis pour un concept spécifique.
  ///
  /// Les documents sont optionnellement triés par le champ spécifié.
  Future<List<DocumentRequis>> getByConceptoId(String conceptoId, {String? orderBy, String? langCode}) async {
    try {
      // Construire la clause ORDER BY en fonction de la langue spécifiée
      String? effectiveOrderBy = orderBy;
      if (orderBy == null && langCode != null) {
        // Si une langue est spécifiée mais pas d'ordre, trier par le nom dans cette langue
        if (_supportedLanguages.contains(langCode)) {
          effectiveOrderBy = 'nombre_$langCode';
        } else {
          effectiveOrderBy = 'nombre';
        }
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
        orderBy: effectiveOrderBy ?? 'nombre',
      );
      
      return maps.map((map) => DocumentRequis.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting document_requis by concepto id: $e', name: 'DocumentRequisDao');
      throw Exception('Could not get document_requis for concepto: $e');
    }
  }
  
  /// Met à jour un document requis existant.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun document n'a été mis à jour).
  Future<int> update(DocumentRequis document) async {
    try {
      return await _db.update(
        _tableName,
        document.toMap(),
        where: 'id = ?',
        whereArgs: [document.id],
      );
    } catch (e) {
      developer.log('Error updating document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not update document_requis: $e');
    }
  }
  
  /// Met à jour une traduction spécifique d'un document requis.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun document n'a été mis à jour).
  Future<int> updateTranslation(int id, String langCode, {String? nombre, String? description}) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }
      
      final Map<String, Object?> values = {};
      
      // Ajouter uniquement les champs à mettre à jour
      if (nombre != null) {
        values['nombre_$langCode'] = nombre;
      }
      
      if (description != null) {
        values['description_$langCode'] = description;
      }
      
      if (values.isEmpty) {
        return 0; // Rien à mettre à jour
      }
      
      return await _db.update(
        _tableName,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating document_requis translation: $e', name: 'DocumentRequisDao');
      throw Exception('Could not update document_requis translation: $e');
    }
  }
  
  /// Supprime un document requis par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun document n'a été supprimé).
  Future<int> delete(int id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not delete document_requis: $e');
    }
  }
  
  /// Supprime tous les documents requis pour un concept spécifique.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteByConceptoId(String conceptoId) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
      );
    } catch (e) {
      developer.log('Error deleting document_requis by concepto id: $e', name: 'DocumentRequisDao');
      throw Exception('Could not delete document_requis for concepto: $e');
    }
  }
  
  /// Supprime tous les documents requis.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not delete document_requis: $e');
    }
  }
  
  /// Vérifie si un document requis existe par son ID.
  ///
  /// Retourne true si le document existe, false sinon.
  Future<bool> exists(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      return maps.isNotEmpty;
    } catch (e) {
      developer.log('Error checking if document_requis exists: $e', name: 'DocumentRequisDao');
      throw Exception('Could not check if document_requis exists: $e');
    }
  }
  
  /// Récupère le nombre total de documents requis dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting document_requis: $e', name: 'DocumentRequisDao');
      throw Exception('Could not count document_requis: $e');
    }
  }
  
  /// Récupère le nombre de documents requis pour un concept spécifique.
  Future<int> countByConceptoId(String conceptoId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE concepto_id = ?',
        [conceptoId],
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting document_requis by concepto id: $e', name: 'DocumentRequisDao');
      throw Exception('Could not count document_requis for concepto: $e');
    }
  }
  
  /// Recherche des documents requis par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Supporte la recherche dans une langue spécifique ou dans toutes les langues.
  Future<List<DocumentRequis>> searchByName(String searchTerm, {String? langCode}) async {
    try {
      String whereClause;
      List<Object> whereArgs = [];
      
      if (langCode != null && _supportedLanguages.contains(langCode)) {
        // Recherche dans une langue spécifique
        whereClause = 'nombre_$langCode LIKE ?';
        whereArgs.add('%$searchTerm%');
      } else {
        // Recherche dans toutes les langues (par défaut)
        List<String> conditions = [];
        
        // Ajouter le champ 'nombre' original pour compatibilité
        conditions.add('nombre LIKE ?');
        whereArgs.add('%$searchTerm%');
        
        // Ajouter les colonnes de traduction
        for (final lang in _supportedLanguages) {
          conditions.add('nombre_$lang LIKE ?');
          whereArgs.add('%$searchTerm%');
        }
        
        whereClause = conditions.join(' OR ');
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      return maps.map((map) => DocumentRequis.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching document_requis by name: $e', name: 'DocumentRequisDao');
      throw Exception('Could not search document_requis: $e');
    }
  }
  
  /// Recherche des documents requis qui ont une traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les documents qui n'ont pas encore été traduits.
  Future<List<DocumentRequis>> getDocumentsWithTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NOT NULL AND nombre_$langCode <> ""',
      );
      
      return maps.map((map) => DocumentRequis.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting documents with translation: $e', name: 'DocumentRequisDao');
      throw Exception('Could not get documents with translation: $e');
    }
  }
  
  /// Recherche des documents requis qui n'ont pas de traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les documents qui doivent être traduits.
  Future<List<DocumentRequis>> getDocumentsWithoutTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NULL OR nombre_$langCode = ""',
      );
      
      return maps.map((map) => DocumentRequis.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting documents without translation: $e', name: 'DocumentRequisDao');
      throw Exception('Could not get documents without translation: $e');
    }
  }
}