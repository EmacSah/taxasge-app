import 'package:sqflite/sqflite.dart';
import '../../models/procedure.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des procédures avec support multilingue.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des procédures dans la base de données.
class ProcedureDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  ProcedureDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableProcedimientos;
  
  /// Langues supportées
  final List<String> _supportedLanguages = DatabaseSchema.supportedLanguages;
  
  /// Langue par défaut
  final String _defaultLanguage = DatabaseSchema.defaultLanguage;
  
  /// Insère une nouvelle procédure dans la base de données.
  ///
  /// Retourne l'ID de la procédure insérée.
  /// Lève une exception en cas d'erreur.
  Future<int> insert(Procedure procedure) async {
    try {
      return await _db.insert(
        _tableName,
        procedure.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting procedure: $e', name: 'ProcedureDao');
      throw Exception('Could not insert procedure: $e');
    }
  }
  
  /// Insère plusieurs procédures en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les procédures une par une
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<Procedure> procedures) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final procedure in procedures) {
          batch.insert(
            _tableName,
            procedure.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple procedures: $e', name: 'ProcedureDao');
      throw Exception('Could not insert procedures: $e');
    }
  }
  
  /// Récupère une procédure par son ID.
  ///
  /// Retourne null si aucune procédure n'est trouvée avec cet ID.
  Future<Procedure?> getById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Procedure.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting procedure by id: $e', name: 'ProcedureDao');
      throw Exception('Could not get procedure: $e');
    }
  }
  
  /// Récupère toutes les procédures.
  ///
  /// Les procédures sont optionnellement triées par le champ spécifié.
  Future<List<Procedure>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy ?? 'orden, id',
      );
      
      return maps.map((map) => Procedure.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all procedures: $e', name: 'ProcedureDao');
      throw Exception('Could not get procedures: $e');
    }
  }
  
  /// Récupère toutes les procédures pour un concept spécifique.
  ///
  /// Les procédures sont optionnellement triées par le champ spécifié et dans la langue spécifiée.
  Future<List<Procedure>> getByConceptoId(String conceptoId, {String? orderBy, String? langCode}) async {
    try {
      // Si une langue est spécifiée et aucun ordre n'est défini, trier d'abord par ordre puis par la description dans cette langue
      String? effectiveOrderBy = orderBy;
      if (orderBy == null && langCode != null && _supportedLanguages.contains(langCode)) {
        effectiveOrderBy = 'orden, description_$langCode';
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
        orderBy: effectiveOrderBy ?? 'orden, description',
      );
      
      return maps.map((map) => Procedure.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting procedures by concepto id: $e', name: 'ProcedureDao');
      throw Exception('Could not get procedures for concepto: $e');
    }
  }
  
  /// Met à jour une procédure existante.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune procédure n'a été mise à jour).
  Future<int> update(Procedure procedure) async {
    try {
      return await _db.update(
        _tableName,
        procedure.toMap(),
        where: 'id = ?',
        whereArgs: [procedure.id],
      );
    } catch (e) {
      developer.log('Error updating procedure: $e', name: 'ProcedureDao');
      throw Exception('Could not update procedure: $e');
    }
  }
  
  /// Met à jour une traduction spécifique d'une procédure.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune procédure n'a été mise à jour).
  Future<int> updateTranslation(int id, String langCode, String description) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }
      
      return await _db.update(
        _tableName,
        {'description_$langCode': description},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating procedure translation: $e', name: 'ProcedureDao');
      throw Exception('Could not update procedure translation: $e');
    }
  }
  
  /// Met à jour l'ordre d'une procédure.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune procédure n'a été mise à jour).
  Future<int> updateOrder(int id, int orden) async {
    try {
      return await _db.update(
        _tableName,
        {'orden': orden},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating procedure order: $e', name: 'ProcedureDao');
      throw Exception('Could not update procedure order: $e');
    }
  }
  
  /// Supprime une procédure par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune procédure n'a été supprimée).
  Future<int> delete(int id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting procedure: $e', name: 'ProcedureDao');
      throw Exception('Could not delete procedure: $e');
    }
  }
  
  /// Supprime toutes les procédures d'un concept spécifique.
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
      developer.log('Error deleting procedures by concepto id: $e', name: 'ProcedureDao');
      throw Exception('Could not delete procedures for concepto: $e');
    }
  }
  
  /// Supprime toutes les procédures.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all procedures: $e', name: 'ProcedureDao');
      throw Exception('Could not delete procedures: $e');
    }
  }
  
  /// Vérifie si une procédure existe par son ID.
  ///
  /// Retourne true si la procédure existe, false sinon.
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
      developer.log('Error checking if procedure exists: $e', name: 'ProcedureDao');
      throw Exception('Could not check if procedure exists: $e');
    }
  }
  
  /// Récupère le nombre total de procédures dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting procedures: $e', name: 'ProcedureDao');
      throw Exception('Could not count procedures: $e');
    }
  }
  
  /// Récupère le nombre de procédures pour un concept spécifique.
  Future<int> countByConceptoId(String conceptoId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE concepto_id = ?',
        [conceptoId],
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting procedures by concepto id: $e', name: 'ProcedureDao');
      throw Exception('Could not count procedures for concepto: $e');
    }
  }
  
  /// Recherche des procédures par description.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Il est possible de rechercher dans une langue spécifique.
  Future<List<Procedure>> searchByDescription(String searchTerm, {String? langCode}) async {
    try {
      String whereClause;
      List<Object> whereArgs = [];
      
      if (langCode != null && _supportedLanguages.contains(langCode)) {
        // Recherche dans une langue spécifique
        whereClause = 'description_$langCode LIKE ?';
        whereArgs.add('%$searchTerm%');
      } else {
        // Recherche dans toutes les langues (par défaut)
        List<String> conditions = [];
        
        // Ajouter le champ 'description' original pour compatibilité
        conditions.add('description LIKE ?');
        whereArgs.add('%$searchTerm%');
        
        // Ajouter les colonnes de traduction
        for (final lang in _supportedLanguages) {
          conditions.add('description_$lang LIKE ?');
          whereArgs.add('%$searchTerm%');
        }
        
        whereClause = conditions.join(' OR ');
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );
      
      return maps.map((map) => Procedure.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching procedures by description: $e', name: 'ProcedureDao');
      throw Exception('Could not search procedures: $e');
    }
  }
  
  /// Récupère les procédures qui ont une traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les procédures qui n'ont pas encore été traduites.
  Future<List<Procedure>> getProceduresWithTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'description_$langCode IS NOT NULL AND description_$langCode <> ""',
      );
      
      return maps.map((map) => Procedure.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting procedures with translation: $e', name: 'ProcedureDao');
      throw Exception('Could not get procedures with translation: $e');
    }
  }
  
  /// Récupère les procédures qui n'ont pas de traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les procédures qui doivent être traduites.
  Future<List<Procedure>> getProceduresWithoutTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'description_$langCode IS NULL OR description_$langCode = ""',
      );
      
      return maps.map((map) => Procedure.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting procedures without translation: $e', name: 'ProcedureDao');
      throw Exception('Could not get procedures without translation: $e');
    }
  }
  
  /// Récupère les langues disponibles pour une procédure spécifique
  ///
  /// Cette méthode retourne la liste des codes de langue pour lesquels 
  /// la procédure possède des traductions.
  Future<List<String>> getAvailableLanguagesForProcedure(int procedureId) async {
    try {
      final procedure = await getById(procedureId);
      if (procedure == null) {
        return [];
      }
      
      final List<String> availableLanguages = [];
      
      for (final lang in _supportedLanguages) {
        if (procedure.hasDescriptionInLanguage(lang)) {
          availableLanguages.add(lang);
        }
      }
      
      return availableLanguages;
    } catch (e) {
      developer.log('Error getting available languages for procedure: $e', name: 'ProcedureDao');
      throw Exception('Could not get available languages for procedure: $e');
    }
  }
  
  /// Migre les procédures depuis la table des concepts.
  ///
  /// Cette méthode est utilisée lors de la migration pour déplacer les données des procédures
  /// de la table des concepts vers la table des procédures dédiée.
  Future<int> migrateFromConcepts() async {
    try {
      // Récupérer tous les concepts qui ont une procédure définie
      final List<Map<String, dynamic>> conceptsWithProcedure = await _db.query(
        DatabaseSchema.tableConceptos,
        columns: [
          'id', 
          'procedimiento', 
          'procedimiento_es', 
          'procedimiento_fr', 
          'procedimiento_en'
        ],
        where: 'procedimiento IS NOT NULL AND procedimiento <> ""',
      );
      
      int migratedCount = 0;
      
      // Pour chaque concept, créer une entrée dans la table des procédures
      for (final conceptMap in conceptsWithProcedure) {
        final conceptoId = conceptMap['id'] as String;
        
        // Construire les traductions
        final Map<String, String> descriptionTraductions = {};
        
        // Essayer d'abord les champs dédiés aux langues
        if (conceptMap['procedimiento_es'] != null) {
          descriptionTraductions['es'] = conceptMap['procedimiento_es'] as String;
        }
        if (conceptMap['procedimiento_fr'] != null) {
          descriptionTraductions['fr'] = conceptMap['procedimiento_fr'] as String;
        }
        if (conceptMap['procedimiento_en'] != null) {
          descriptionTraductions['en'] = conceptMap['procedimiento_en'] as String;
        }
        
        // Si aucune traduction n'a été trouvée, utiliser le champ 'procedimiento' comme valeur espagnole
        if (descriptionTraductions.isEmpty && conceptMap['procedimiento'] != null) {
          descriptionTraductions['es'] = conceptMap['procedimiento'] as String;
        }
        
        // Créer et insérer la procédure
        if (descriptionTraductions.isNotEmpty) {
          final procedure = Procedure(
            id: 0, // Auto-généré
            conceptoId: conceptoId,
            descriptionTraductions: descriptionTraductions,
            orden: 1, // Par défaut, première étape
          );
          
          await insert(procedure);
          migratedCount++;
        }
      }
      
      return migratedCount;
    } catch (e) {
      developer.log('Error migrating procedures from concepts: $e', name: 'ProcedureDao');
      throw Exception('Could not migrate procedures from concepts: $e');
    }
  }
}