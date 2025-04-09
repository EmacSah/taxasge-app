import 'package:sqflite/sqflite.dart';
import '../../models/mot_cle.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des mots clés.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des mots clés dans la base de données.
class MotCleDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  MotCleDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableMotsCles;
  
  /// Insère un nouveau mot clé dans la base de données.
  ///
  /// Retourne l'ID du mot clé inséré.
  /// Lève une exception en cas d'erreur.
  Future<int> insert(MotCle motCle) async {
    try {
      return await _db.insert(
        _tableName,
        motCle.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not insert mot_cle: $e');
    }
  }
  
  /// Insère plusieurs mots clés en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les mots clés un par un
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<MotCle> motsCles) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final motCle in motsCles) {
          batch.insert(
            _tableName,
            motCle.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not insert mot_cle: $e');
    }
  }
  
  /// Insère une liste de mots clés pour un concept spécifique.
  ///
  /// Cette méthode prend une chaîne de mots clés séparés par des virgules,
  /// la divise en mots individuels et insère chaque mot comme une entrée distincte.
  Future<void> insertForConcepto(String conceptoId, String motsClesString) async {
    try {
      // Diviser la chaîne en mots individuels, nettoyer et normaliser
      final motsClesList = motsClesString
          .split(',')
          .map((mot) => mot.trim().toLowerCase())
          .where((mot) => mot.isNotEmpty)
          .toList();
      
      // Créer des objets MotCle et les insérer
      final motsCles = motsClesList
          .map((mot) => MotCle(
                id: 0, // L'ID sera généré automatiquement
                conceptoId: conceptoId,
                motCle: mot,
              ))
          .toList();
      
      await insertAll(motsCles);
    } catch (e) {
      developer.log('Error inserting mot_cle for concepto: $e', name: 'MotCleDao');
      throw Exception('Could not insert mot_cle for concepto: $e');
    }
  }
  
  /// Récupère un mot clé par son ID.
  ///
  /// Retourne null si aucun mot clé n'est trouvé avec cet ID.
  Future<MotCle?> getById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return MotCle.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting mot_cle by id: $e', name: 'MotCleDao');
      throw Exception('Could not get mot_cle: $e');
    }
  }
  
  /// Récupère tous les mots clés.
  ///
  /// Les mots clés sont optionnellement triés par le champ spécifié.
  Future<List<MotCle>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy ?? 'mot_cle',
      );
      
      return maps.map((map) => MotCle.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not get mot_cle: $e');
    }
  }
  
  /// Récupère tous les mots clés pour un concept spécifique.
  ///
  /// Les mots clés sont optionnellement triés par le champ spécifié.
  Future<List<MotCle>> getByConceptoId(String conceptoId, {String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
        orderBy: orderBy ?? 'mot_cle',
      );
      
      return maps.map((map) => MotCle.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting mot_cle by concepto id: $e', name: 'MotCleDao');
      throw Exception('Could not get mot_cle for concepto: $e');
    }
  }
  
  /// Récupère tous les mots clés pour un concept spécifique sous forme de liste de chaînes.
  ///
  /// Cette méthode est utile pour récupérer directement les mots clés sans
  /// avoir à manipuler les objets MotCle.
  Future<List<String>> getMotsClesByConceptoId(String conceptoId) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        columns: ['mot_cle'],
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
        orderBy: 'mot_cle',
      );
      
      return maps.map((map) => map['mot_cle'] as String).toList();
    } catch (e) {
      developer.log('Error getting mots_cles strings by concepto id: $e', name: 'MotCleDao');
      throw Exception('Could not get mots_cles strings for concepto: $e');
    }
  }
  
  /// Met à jour un mot clé existant.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun mot clé n'a été mis à jour).
  Future<int> update(MotCle motCle) async {
    try {
      return await _db.update(
        _tableName,
        motCle.toMap(),
        where: 'id = ?',
        whereArgs: [motCle.id],
      );
    } catch (e) {
      developer.log('Error updating mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not update mot_cle: $e');
    }
  }
  
  /// Supprime un mot clé par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun mot clé n'a été supprimé).
  Future<int> delete(int id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not delete mot_cle: $e');
    }
  }
  
  /// Supprime tous les mots clés pour un concept spécifique.
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
      developer.log('Error deleting mot_cle by concepto id: $e', name: 'MotCleDao');
      throw Exception('Could not delete mot_cle for concepto: $e');
    }
  }
  
  /// Supprime tous les mots clés.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not delete mot_cle: $e');
    }
  }
  
  /// Vérifie si un mot clé existe par son ID.
  ///
  /// Retourne true si le mot clé existe, false sinon.
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
      developer.log('Error checking if mot_cle exists: $e', name: 'MotCleDao');
      throw Exception('Could not check if mot_cle exists: $e');
    }
  }
  
  /// Récupère le nombre total de mots clés dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not count mot_cle: $e');
    }
  }
  
  /// Récupère le nombre de mots clés pour un concept spécifique.
  Future<int> countByConceptoId(String conceptoId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE concepto_id = ?',
        [conceptoId],
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting mot_cle by concepto id: $e', name: 'MotCleDao');
      throw Exception('Could not count mot_cle for concepto: $e');
    }
  }
  
  /// Recherche des concepts par mot clé.
  ///
  /// Retourne les IDs des concepts qui contiennent le mot clé spécifié.
  /// La recherche est insensible à la casse.
  Future<List<String>> searchConceptosByMotCle(String searchTerm) async {
    try {
      final List<Map<String, dynamic>> result = await _db.query(
        _tableName,
        columns: ['concepto_id'],
        where: 'mot_cle LIKE ?',
        whereArgs: ['%$searchTerm%'],
        groupBy: 'concepto_id',
      );
      
      return result.map((map) => map['concepto_id'] as String).toList();
    } catch (e) {
      developer.log('Error searching conceptos by mot_cle: $e', name: 'MotCleDao');
      throw Exception('Could not search conceptos by mot_cle: $e');
    }
  }
  
  /// Récupère tous les mots clés uniques dans la base de données.
  ///
  /// Utile pour construire un index de recherche ou un nuage de tags.
  Future<List<String>> getAllUniqueMotsCles() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT DISTINCT mot_cle FROM $_tableName ORDER BY mot_cle',
      );
      
      return result.map((map) => map['mot_cle'] as String).toList();
    } catch (e) {
      developer.log('Error getting all unique mots_cles: $e', name: 'MotCleDao');
      throw Exception('Could not get unique mots_cles: $e');
    }
  }
}