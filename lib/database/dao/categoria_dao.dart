import 'package:sqflite/sqflite.dart';
import '../../models/categoria.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des catégories.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des catégories dans la base de données.
class CategoriaDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  CategoriaDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableCategorias;
  
  /// Insère une nouvelle catégorie dans la base de données.
  ///
  /// Retourne l'ID de la catégorie insérée.
  /// Lève une exception en cas d'erreur.
  Future<String> insert(Categoria categoria) async {
    try {
      await _db.insert(
        _tableName,
        categoria.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return categoria.id;
    } catch (e) {
      developer.log('Error inserting categoria: $e', name: 'CategoriaDao');
      throw Exception('Could not insert categoria: $e');
    }
  }
  
  /// Insère plusieurs catégories en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les catégories une par une
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<Categoria> categorias) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final categoria in categorias) {
          batch.insert(
            _tableName,
            categoria.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple categorias: $e', name: 'CategoriaDao');
      throw Exception('Could not insert categorias: $e');
    }
  }
  
  /// Récupère une catégorie par son ID.
  ///
  /// Retourne null si aucune catégorie n'est trouvée avec cet ID.
  Future<Categoria?> getById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Categoria.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting categoria by id: $e', name: 'CategoriaDao');
      throw Exception('Could not get categoria: $e');
    }
  }
  
  /// Récupère toutes les catégories.
  ///
  /// Les catégories sont optionnellement triées par le champ spécifié.
  Future<List<Categoria>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy,
      );
      
      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all categorias: $e', name: 'CategoriaDao');
      throw Exception('Could not get categorias: $e');
    }
  }
  
  /// Récupère toutes les catégories pour un secteur spécifique.
  ///
  /// Les catégories sont optionnellement triées par le champ spécifié.
  Future<List<Categoria>> getBySectorId(String sectorId, {String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'sector_id = ?',
        whereArgs: [sectorId],
        orderBy: orderBy,
      );
      
      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting categorias by sector id: $e', name: 'CategoriaDao');
      throw Exception('Could not get categorias for sector: $e');
    }
  }
  
  /// Met à jour une catégorie existante.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune catégorie n'a été mise à jour).
  Future<int> update(Categoria categoria) async {
    try {
      return await _db.update(
        _tableName,
        categoria.toMap(),
        where: 'id = ?',
        whereArgs: [categoria.id],
      );
    } catch (e) {
      developer.log('Error updating categoria: $e', name: 'CategoriaDao');
      throw Exception('Could not update categoria: $e');
    }
  }
  
  /// Supprime une catégorie par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune catégorie n'a été supprimée).
  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting categoria: $e', name: 'CategoriaDao');
      throw Exception('Could not delete categoria: $e');
    }
  }
  
  /// Supprime toutes les catégories d'un secteur spécifique.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteBySectorId(String sectorId) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'sector_id = ?',
        whereArgs: [sectorId],
      );
    } catch (e) {
      developer.log('Error deleting categorias by sector id: $e', name: 'CategoriaDao');
      throw Exception('Could not delete categorias for sector: $e');
    }
  }
  
  /// Supprime toutes les catégories.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all categorias: $e', name: 'CategoriaDao');
      throw Exception('Could not delete categorias: $e');
    }
  }
  
  /// Vérifie si une catégorie existe par son ID.
  ///
  /// Retourne true si la catégorie existe, false sinon.
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
      developer.log('Error checking if categoria exists: $e', name: 'CategoriaDao');
      throw Exception('Could not check if categoria exists: $e');
    }
  }
  
  /// Récupère le nombre total de catégories dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting categorias: $e', name: 'CategoriaDao');
      throw Exception('Could not count categorias: $e');
    }
  }
  
  /// Récupère le nombre de catégories pour un secteur spécifique.
  Future<int> countBySectorId(String sectorId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE sector_id = ?',
        [sectorId],
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting categorias by sector id: $e', name: 'CategoriaDao');
      throw Exception('Could not count categorias for sector: $e');
    }
  }
  
  /// Recherche des catégories par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  Future<List<Categoria>> searchByName(String searchTerm) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );
      
      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching categorias by name: $e', name: 'CategoriaDao');
      throw Exception('Could not search categorias: $e');
    }
  }
}