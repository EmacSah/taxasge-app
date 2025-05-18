import 'package:sqflite/sqflite.dart';
import '../../models/favori.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des favoris.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des favoris dans la base de données.
/// Bien que les favoris ne soient pas directement multilingues, ce DAO est adapté
/// pour fonctionner avec le reste du système qui supporte le multilinguisme.
class FavoriDao {
  /// Instance de la base de données
  final Database _db;
  
  /// Constructeur
  FavoriDao(this._db);
  
  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableFavoritos;
  
  /// Insère un nouveau favori dans la base de données.
  ///
  /// Retourne l'ID du favori inséré.
  /// Lève une exception en cas d'erreur.
  Future<int> insert(Favori favori) async {
    try {
      // Si la date d'ajout n'est pas définie, utilisez la date actuelle
      final favoriToInsert = favori.fechaAgregado != null
          ? favori
          : favori.copyWith(fechaAgregado: DateTime.now().toIso8601String());
      
      return await _db.insert(
        _tableName,
        favoriToInsert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      developer.log('Error inserting favori: $e', name: 'FavoriDao');
      throw Exception('Could not insert favori: $e');
    }
  }
  
  /// Ajoute un concept aux favoris.
  ///
  /// Cette méthode est un raccourci pratique pour créer et insérer un favori
  /// à partir d'un ID de concept.
  Future<int> addToFavorites(String conceptoId) async {
    try {
      final favori = Favori(
        id: 0, // L'ID sera généré automatiquement
        conceptoId: conceptoId,
        fechaAgregado: DateTime.now().toIso8601String(),
      );
      
      return await insert(favori);
    } catch (e) {
      developer.log('Error adding to favorites: $e', name: 'FavoriDao');
      throw Exception('Could not add to favorites: $e');
    }
  }
  
  /// Récupère un favori par son ID.
  ///
  /// Retourne null si aucun favori n'est trouvé avec cet ID.
  Future<Favori?> getById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Favori.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting favori by id: $e', name: 'FavoriDao');
      throw Exception('Could not get favori: $e');
    }
  }
  
  /// Récupère tous les favoris.
  ///
  /// Les favoris sont optionnellement triés par le champ spécifié.
  /// Par défaut, ils sont triés par date d'ajout en ordre décroissant (plus récent en premier).
  Future<List<Favori>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy ?? 'fecha_agregado DESC',
      );
      
      return maps.map((map) => Favori.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all favoris: $e', name: 'FavoriDao');
      throw Exception('Could not get favoris: $e');
    }
  }
  
  /// Récupère le favori associé à un concept spécifique.
  ///
  /// Retourne null si le concept n'est pas dans les favoris.
  Future<Favori?> getByConceptoId(String conceptoId) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        return null;
      }
      
      return Favori.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting favori by concepto id: $e', name: 'FavoriDao');
      throw Exception('Could not get favori for concepto: $e');
    }
  }
  
  /// Vérifie si un concept est dans les favoris.
  ///
  /// Retourne true si le concept est dans les favoris, false sinon.
  Future<bool> isFavorite(String conceptoId) async {
    try {
      final favori = await getByConceptoId(conceptoId);
      return favori != null;
    } catch (e) {
      developer.log('Error checking if concept is favorite: $e', name: 'FavoriDao');
      throw Exception('Could not check if concept is favorite: $e');
    }
  }
  
  /// Met à jour un favori existant.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun favori n'a été mis à jour).
  Future<int> update(Favori favori) async {
    try {
      return await _db.update(
        _tableName,
        favori.toMap(),
        where: 'id = ?',
        whereArgs: [favori.id],
      );
    } catch (e) {
      developer.log('Error updating favori: $e', name: 'FavoriDao');
      throw Exception('Could not update favori: $e');
    }
  }
  
  /// Supprime un favori par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun favori n'a été supprimé).
  Future<int> delete(int id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting favori: $e', name: 'FavoriDao');
      throw Exception('Could not delete favori: $e');
    }
  }
  
  /// Supprime un favori par son ID de concept.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun favori n'a été supprimé).
  /// Cette méthode est utile pour retirer un concept des favoris.
  Future<int> deleteByConceptoId(String conceptoId) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'concepto_id = ?',
        whereArgs: [conceptoId],
      );
    } catch (e) {
      developer.log('Error deleting favori by concepto id: $e', name: 'FavoriDao');
      throw Exception('Could not delete favori for concepto: $e');
    }
  }
  
  /// Bascule l'état de favori d'un concept.
  ///
  /// Si le concept est déjà dans les favoris, il est retiré.
  /// Sinon, il est ajouté aux favoris.
  /// 
  /// Retourne true si le concept est maintenant un favori, false sinon.
  Future<bool> toggleFavorite(String conceptoId) async {
    try {
      final isFav = await isFavorite(conceptoId);
      
      if (isFav) {
        await deleteByConceptoId(conceptoId);
        return false;
      } else {
        await addToFavorites(conceptoId);
        return true;
      }
    } catch (e) {
      developer.log('Error toggling favorite status: $e', name: 'FavoriDao');
      throw Exception('Could not toggle favorite status: $e');
    }
  }
  
  /// Supprime tous les favoris.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all favoris: $e', name: 'FavoriDao');
      throw Exception('Could not delete favoris: $e');
    }
  }
  
  /// Récupère le nombre total de favoris dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      
      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting favoris: $e', name: 'FavoriDao');
      throw Exception('Could not count favoris: $e');
    }
  }
  
  /// Récupère les ID des concepts favoris.
  ///
  /// Cette méthode est utile pour rapidement vérifier quels concepts sont favoris.
  Future<List<String>> getAllFavoriteConceptoIds() async {
    try {
      final List<Map<String, dynamic>> result = await _db.query(
        _tableName,
        columns: ['concepto_id'],
        orderBy: 'fecha_agregado DESC',
      );
      
      return result.map((map) => map['concepto_id'] as String).toList();
    } catch (e) {
      developer.log('Error getting all favorite concepto ids: $e', name: 'FavoriDao');
      throw Exception('Could not get favorite concepto ids: $e');
    }
  }
  
  /// Récupère les favoris ajoutés après une date spécifique.
  ///
  /// Cette méthode est utile pour synchroniser les favoris avec un serveur.
  Future<List<Favori>> getFavorisAddedAfter(DateTime date) async {
    try {
      final dateString = date.toIso8601String();
      
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'fecha_agregado > ?',
        whereArgs: [dateString],
        orderBy: 'fecha_agregado ASC',
      );
      
      return maps.map((map) => Favori.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting favoris added after date: $e', name: 'FavoriDao');
      throw Exception('Could not get favoris added after date: $e');
    }
  }
  
  /// Récupère les favoris pour les concepts d'un ministère spécifique.
  ///
  /// Cette méthode utilise des jointures pour trouver tous les favoris associés
  /// à des concepts qui appartiennent à un ministère spécifique.
  Future<List<Favori>> getFavorisByMinisterioId(String ministerioId) async {
    try {
      final query = '''
        SELECT f.* FROM $_tableName f
        JOIN ${DatabaseSchema.tableConceptos} c ON f.concepto_id = c.id
        JOIN ${DatabaseSchema.tableSubCategorias} sc ON c.sub_categoria_id = sc.id
        JOIN ${DatabaseSchema.tableCategorias} cat ON sc.categoria_id = cat.id
        JOIN ${DatabaseSchema.tableSectores} s ON cat.sector_id = s.id
        WHERE s.ministerio_id = ?
        ORDER BY f.fecha_agregado DESC
      ''';
      
      final List<Map<String, dynamic>> maps = await _db.rawQuery(query, [ministerioId]);
      
      return maps.map((map) => Favori.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting favoris by ministerio id: $e', name: 'FavoriDao');
      throw Exception('Could not get favoris for ministerio: $e');
    }
  }
  
  /// Récupère les favoris groupés par date d'ajout.
  ///
  /// Cette méthode est utile pour afficher les favoris organisés par date
  /// (aujourd'hui, hier, cette semaine, ce mois, etc.).
  Future<Map<String, List<Favori>>> getFavorisGroupedByDate({String? langCode}) async {
    try {
      final List<Favori> allFavoris = await getAll();
      final Map<String, List<Favori>> result = {};
      final now = DateTime.now();
      
      for (final favori in allFavoris) {
        final addedDate = DateTime.parse(favori.fechaAgregado);
        final difference = now.difference(addedDate);
        
        String category;
        if (difference.inDays == 0) {
          category = (langCode == 'fr') ? 'Aujourd\'hui' : 
                    (langCode == 'en') ? 'Today' : 'Hoy';
        } else if (difference.inDays == 1) {
          category = (langCode == 'fr') ? 'Hier' : 
                    (langCode == 'en') ? 'Yesterday' : 'Ayer';
        } else if (difference.inDays < 7) {
          category = (langCode == 'fr') ? 'Cette semaine' : 
                    (langCode == 'en') ? 'This week' : 'Esta semana';
        } else if (difference.inDays < 30) {
          category = (langCode == 'fr') ? 'Ce mois' : 
                    (langCode == 'en') ? 'This month' : 'Este mes';
        } else {
          category = (langCode == 'fr') ? 'Plus ancien' : 
                    (langCode == 'en') ? 'Older' : 'Más antiguo';
        }
        
        if (!result.containsKey(category)) {
          result[category] = [];
        }
        
        result[category]!.add(favori);
      }
      
      return result;
    } catch (e) {
      developer.log('Error getting favoris grouped by date: $e', name: 'FavoriDao');
      throw Exception('Could not get favoris grouped by date: $e');
    }
  }
}