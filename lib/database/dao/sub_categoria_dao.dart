import 'package:sqflite/sqflite.dart';
import '../../models/sub_categoria.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des sous-catégories.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des sous-catégories dans la base de données.
class SubCategoriaDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  SubCategoriaDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableSubCategorias;
  
  /// Insère une nouvelle sous-catégorie dans la base de données.
  ///
  /// Retourne l'ID de la sous-catégorie insérée.
  /// Lève une exception en cas d'erreur.
  Future<String> insert(SubCategoria subCategoria) async {
    try {
      await _db.insert(
        _tableName,
        subCategoria.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return subCategoria.id;
    } catch (e) {
      developer.log('Error inserting sub_categoria: $e', name: 'SubCategoriaDao');
      throw Exception('Could not insert sub_categoria: $e');
    }
  }
  
  /// Insère plusieurs sous-catégories en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les sous-catégories une par une
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<SubCategoria> subCategorias) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        
        for (final subCategoria in subCategorias) {
          batch.insert(
            _tableName,
            subCategoria.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        
        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple sub_categorias: $e', name: 'SubCategoriaDao');
      throw Exception('Could not insert sub_categorias: $e');
    }
  }
  
  /// Récupère une sous-catégorie par son ID.
  ///
  /// Retourne null si aucune sous-catégorie n'est trouvée avec cet ID.
  Future<SubCategoria?> getById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return SubCategoria.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting sub_categoria by id: $e', name: 'SubCategoriaDao');
      throw Exception('Could not get sub_categoria: $e');
    }
  }
  
  /// Récupère toutes les sous-catégories.
  ///
  /// Les sous-catégories sont optionnellement triées par le champ spécifié.
  Future<List<SubCategoria>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy,
      );
      
      return maps.map((map) => SubCategoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all sub_categorias: $e', name: 'SubCategoriaDao');
      throw Exception('Could not get sub_categorias: $e');
    }
  }
  
  /// Récupère toutes les sous-catégories pour une catégorie spécifique.
  ///
  /// Les sous-catégories sont optionnellement triées par le champ spécifié.
  Future<List<SubCategoria>> getByCategoriaId(String categoriaId, {String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'categoria_id = ?',
        whereArgs: [categoriaId],
        orderBy: orderBy,
      );
      
      return maps.map((map) => SubCategoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting sub_categorias by categoria id: $e', name: 'SubCategoriaDao');
      throw Exception('Could not get sub_categorias for categoria: $e');
    }
  }
  
  /// Met à jour une sous-catégorie existante.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune sous-catégorie n'a été mise à jour).
  Future<int> update(SubCategoria subCategoria) async {
    try {
      return await _db.update(
        _tableName,
        subCategoria.toMap(),
        where: 'id = ?',
        whereArgs: [subCategoria.id],
      );
    } catch (e) {
      developer.log('Error updating sub_categoria: $e', name: 'SubCategoriaDao');
      throw Exception('Could not update sub_categoria: $e');
    }
  }
  
  /// Supprime une sous-catégorie par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune sous-catégorie n'a été supprimée).
  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting sub_categoria: $e', name: 'SubCategoriaDao');
      throw Exception('Could not delete sub_categoria: $e');
    }
  }
  
  /// Supprime toutes les sous-catégories d'une catégorie spécifique.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteByCategoriaId(String categoriaId) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'categoria_id = ?',
        whereArgs: [categoriaId],
      );
    } catch (e) {
      developer.log('Error deleting sub_categorias by categoria id: $e', name: 'SubCategoriaDao');
      throw Exception('Could not delete sub_categorias for categoria: $e');
    }
  }
  
  /// Supprime toutes les sous-catégories.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all sub_categorias: $e', name: 'SubCategoriaDao');
      throw Exception('Could not delete sub_categorias: $e');
    }
  }
  
  /// Vérifie si une sous-catégorie existe par son ID.
  ///
  /// Retourne true si la sous-catégorie existe, false sinon.
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
      developer.log('Error checking if sub_categoria exists: $e', name: 'SubCategoriaDao');
      throw Exception('Could not check if sub_categoria exists: $e');
    }
  }
  
  /// Récupère le nombre total de sous-catégories dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting sub_categorias: $e', name: 'SubCategoriaDao');
      throw Exception('Could not count sub_categorias: $e');
    }
  }
  
  /// Récupère le nombre de sous-catégories pour une catégorie spécifique.
  Future<int> countByCategoriaId(String categoriaId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE categoria_id = ?',
        [categoriaId],
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting sub_categorias by categoria id: $e', name: 'SubCategoriaDao');
      throw Exception('Could not count sub_categorias for categoria: $e');
    }
  }
  
  /// Recherche des sous-catégories par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Note: Cette méthode gère également les sous-catégories dont le nom est null.
  Future<List<SubCategoria>> searchByName(String searchTerm) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );
      
      return maps.map((map) => SubCategoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching sub_categorias by name: $e', name: 'SubCategoriaDao');
      throw Exception('Could not search sub_categorias: $e');
    }
  }
}