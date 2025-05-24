import 'package:sqflite/sqflite.dart';
import '../../models/categoria.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des catégories avec support multilingue.
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

  /// Langues supportées
  final List<String> _supportedLanguages = DatabaseSchema.supportedLanguages;

  /// Langue par défaut
  ///final String _defaultLanguage = DatabaseSchema.defaultLanguage;

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
      developer.log('Error inserting multiple categorias: $e',
          name: 'CategoriaDao');
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
  /// Les catégories sont optionnellement triées par le champ spécifié et dans la langue spécifiée.
  Future<List<Categoria>> getAll({String? orderBy, String? langCode}) async {
    try {
      // Si une langue est spécifiée et aucun ordre n'est défini, trier par le nom dans cette langue
      String? effectiveOrderBy = orderBy;
      if (orderBy == null &&
          langCode != null &&
          _supportedLanguages.contains(langCode)) {
        effectiveOrderBy = 'nombre_$langCode';
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: effectiveOrderBy ?? 'nombre',
      );

      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all categorias: $e', name: 'CategoriaDao');
      throw Exception('Could not get categorias: $e');
    }
  }

  /// Récupère toutes les catégories pour un secteur spécifique.
  ///
  /// Les catégories sont optionnellement triées par le champ spécifié et dans la langue spécifiée.
  Future<List<Categoria>> getBySectorId(String sectorId,
      {String? orderBy, String? langCode}) async {
    try {
      // Si une langue est spécifiée et aucun ordre n'est défini, trier par le nom dans cette langue
      String? effectiveOrderBy = orderBy;
      if (orderBy == null &&
          langCode != null &&
          _supportedLanguages.contains(langCode)) {
        effectiveOrderBy = 'nombre_$langCode';
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'sector_id = ?',
        whereArgs: [sectorId],
        orderBy: effectiveOrderBy ?? 'nombre',
      );

      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting categorias by sector id: $e',
          name: 'CategoriaDao');
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

  /// Met à jour une traduction spécifique d'une catégorie.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucune catégorie n'a été mise à jour).
  Future<int> updateTranslation(
      String id, String langCode, String nombre) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      return await _db.update(
        _tableName,
        {'nombre_$langCode': nombre},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating categoria translation: $e',
          name: 'CategoriaDao');
      throw Exception('Could not update categoria translation: $e');
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
      developer.log('Error deleting categorias by sector id: $e',
          name: 'CategoriaDao');
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
      developer.log('Error checking if categoria exists: $e',
          name: 'CategoriaDao');
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
      developer.log('Error counting categorias by sector id: $e',
          name: 'CategoriaDao');
      throw Exception('Could not count categorias for sector: $e');
    }
  }

  /// Recherche des catégories par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Il est possible de rechercher dans une langue spécifique.
  Future<List<Categoria>> searchByName(String searchTerm,
      {String? langCode}) async {
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

      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching categorias by name: $e',
          name: 'CategoriaDao');
      throw Exception('Could not search categorias: $e');
    }
  }

  /// Récupère les catégories qui ont une traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les catégories qui n'ont pas encore été traduites.
  Future<List<Categoria>> getCategoriasWithTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NOT NULL AND nombre_$langCode <> ""',
      );

      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting categorias with translation: $e',
          name: 'CategoriaDao');
      throw Exception('Could not get categorias with translation: $e');
    }
  }

  /// Récupère les catégories qui n'ont pas de traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les catégories qui doivent être traduites.
  Future<List<Categoria>> getCategoriasWithoutTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NULL OR nombre_$langCode = ""',
      );

      return maps.map((map) => Categoria.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting categorias without translation: $e',
          name: 'CategoriaDao');
      throw Exception('Could not get categorias without translation: $e');
    }
  }

  /// Récupère les langues disponibles pour une catégorie spécifique
  ///
  /// Cette méthode retourne la liste des codes de langue pour lesquels
  /// la catégorie possède des traductions.
  Future<List<String>> getAvailableLanguagesForCategoria(
      String categoriaId) async {
    try {
      final categoria = await getById(categoriaId);
      if (categoria == null) {
        return [];
      }

      final List<String> availableLanguages = [];

      for (final lang in _supportedLanguages) {
        if (categoria.nombreTraductions.containsKey(lang) &&
            categoria.nombreTraductions[lang]!.isNotEmpty) {
          availableLanguages.add(lang);
        }
      }

      return availableLanguages;
    } catch (e) {
      developer.log('Error getting available languages for categoria: $e',
          name: 'CategoriaDao');
      throw Exception('Could not get available languages for categoria: $e');
    }
  }
}
