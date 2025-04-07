import 'package:sqflite/sqflite.dart';
import '../../models/ministerio.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des ministères.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des ministères dans la base de données.
class MinisterioDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  MinisterioDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableMinisterios;
  
  /// Insère un nouveau ministère dans la base de données.
  ///
  /// Retourne l'ID du ministère inséré.
  /// Lève une exception en cas d'erreur.
  Future<String> insert(Ministerio ministerio) async {
    try {
      await _db.insert(
        _tableName,
        ministerio.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return ministerio.id;
    } catch (e) {
      developer.log('Error inserting ministerio: $e', name: 'MinisterioDao');
      throw Exception('Could not insert ministerio: $e');
    }
  }
  
  /// Insère plusieurs ministères en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les ministères un par un
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<Ministerio> ministerios) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final ministerio in ministerios) {
          batch.insert(
            _tableName,
            ministerio.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple ministerios: $e', name: 'MinisterioDao');
      throw Exception('Could not insert ministerios: $e');
    }
  }
  
  /// Récupère un ministère par son ID.
  ///
  /// Retourne null si aucun ministère n'est trouvé avec cet ID.
  Future<Ministerio?> getById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Ministerio.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting ministerio by id: $e', name: 'MinisterioDao');
      throw Exception('Could not get ministerio: $e');
    }
  }
  
  /// Récupère tous les ministères.
  ///
  /// Les ministères sont optionnellement triés par le champ spécifié.
  Future<List<Ministerio>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy,
      );
      
      return maps.map((map) => Ministerio.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all ministerios: $e', name: 'MinisterioDao');
      throw Exception('Could not get ministerios: $e');
    }
  }
  
  /// Met à jour un ministère existant.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun ministère n'a été mis à jour).
  Future<int> update(Ministerio ministerio) async {
    try {
      return await _db.update(
        _tableName,
        ministerio.toMap(),
        where: 'id = ?',
        whereArgs: [ministerio.id],
      );
    } catch (e) {
      developer.log('Error updating ministerio: $e', name: 'MinisterioDao');
      throw Exception('Could not update ministerio: $e');
    }
  }
  
  /// Supprime un ministère par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun ministère n'a été supprimé).
  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting ministerio: $e', name: 'MinisterioDao');
      throw Exception('Could not delete ministerio: $e');
    }
  }
  
  /// Supprime tous les ministères.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all ministerios: $e', name: 'MinisterioDao');
      throw Exception('Could not delete ministerios: $e');
    }
  }
  
  /// Vérifie si un ministère existe par son ID.
  ///
  /// Retourne true si le ministère existe, false sinon.
  Future<bool> exists(String id) async {
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
      developer.log('Error checking if ministerio exists: $e', name: 'MinisterioDao');
      throw Exception('Could not check if ministerio exists: $e');
    }
  }
  
  /// Récupère le nombre total de ministères dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting ministerios: $e', name: 'MinisterioDao');
      throw Exception('Could not count ministerios: $e');
    }
  }
  
  /// Recherche des ministères par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  Future<List<Ministerio>> searchByName(String searchTerm) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );
      
      return maps.map((map) => Ministerio.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching ministerios by name: $e', name: 'MinisterioDao');
      throw Exception('Could not search ministerios: $e');
    }
  }
}