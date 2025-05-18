import 'package:sqflite/sqflite.dart';
import '../../models/ministerio.dart';
import '../schema.dart';
import 'dart:developer' as developer;
import '../../services/localization_service.dart';

/// Data Access Object pour la table des ministères.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des ministères dans la base de données.
/// Le support multilingue est intégré pour toutes les opérations.
class MinisterioDao {
  /// Instance de la base de données
  final Database _db;

  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableMinisterios;

  /// Constructeur
  MinisterioDao(this._db);

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
      developer.log('Error inserting multiple ministerios: $e',
          name: 'MinisterioDao');
      throw Exception('Could not insert ministerios: $e');
    }
  }

  /// Récupère un ministère par son ID.
  ///
  /// [id] : Identifiant du ministère à récupérer
  /// [langCodes] : Liste optionnelle des codes de langue à récupérer.
  /// Si null, toutes les langues disponibles seront récupérées.
  ///
  /// Retourne null si aucun ministère n'est trouvé avec cet ID.
  Future<Ministerio?> getById(String id, {List<String>? langCodes}) async {
    try {
      // Construire la liste des colonnes à récupérer
      final List<String> columns = ['id'];

      // Récupérer les colonnes de traduction pour les langues spécifiées ou toutes les langues
      if (langCodes == null) {
        // Récupérer toutes les langues supportées
        columns.add('nombre'); // Colonne principale pour compatibilité
        for (final lang in DatabaseSchema.supportedLanguages) {
          columns.add('nombre_$lang');
        }
      } else {
        // Récupérer seulement les langues spécifiées
        columns.add('nombre'); // Colonne principale pour compatibilité
        for (final lang in langCodes) {
          if (DatabaseSchema.supportedLanguages.contains(lang)) {
            columns.add('nombre_$lang');
          }
        }
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        columns: columns,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      return Ministerio.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting ministerio by id: $e',
          name: 'MinisterioDao');
      throw Exception('Could not get ministerio: $e');
    }
  }

  /// Récupère tous les ministères.
  ///
  /// [orderBy] : Clause optionnelle pour trier les résultats
  /// [langCodes] : Liste optionnelle des codes de langue à récupérer.
  /// Si null, toutes les langues disponibles seront récupérées.
  /// [searchTerm] : Terme de recherche optionnel pour filtrer par nom
  /// [langCodeForSearch] : Code de langue à utiliser pour la recherche
  ///
  /// Retourne la liste de tous les ministères correspondant aux critères.
  Future<List<Ministerio>> getAll({
    String? orderBy,
    List<String>? langCodes,
    String? searchTerm,
    String? langCodeForSearch,
  }) async {
    try {
      // Construire la liste des colonnes à récupérer
      final List<String> columns = ['id'];

      // Récupérer les colonnes de traduction pour les langues spécifiées ou toutes les langues
      if (langCodes == null) {
        // Récupérer toutes les langues supportées
        columns.add('nombre'); // Colonne principale pour compatibilité
        for (final lang in DatabaseSchema.supportedLanguages) {
          columns.add('nombre_$lang');
        }
      } else {
        // Récupérer seulement les langues spécifiées
        columns.add('nombre'); // Colonne principale pour compatibilité
        for (final lang in langCodes) {
          if (DatabaseSchema.supportedLanguages.contains(lang)) {
            columns.add('nombre_$lang');
          }
        }
      }

      // Construire la clause WHERE pour la recherche
      String? whereClause;
      List<dynamic>? whereArgs;

      if (searchTerm != null && searchTerm.isNotEmpty) {
        final langCode =
            langCodeForSearch ?? LocalizationService.instance.currentLanguage;

        // Vérifier si le code de langue est valide
        if (DatabaseSchema.supportedLanguages.contains(langCode)) {
          // Rechercher dans la colonne de la langue spécifiée
          whereClause = 'nombre_$langCode LIKE ?';
          whereArgs = ['%$searchTerm%'];
        } else {
          // Fallback sur la colonne 'nombre' si le code de langue est invalide
          whereClause = 'nombre LIKE ?';
          whereArgs = ['%$searchTerm%'];
        }
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        columns: columns,
        where: whereClause,
        whereArgs: whereArgs,
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
  /// Cette méthode met à jour toutes les traductions du ministère.
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

  /// Met à jour une traduction spécifique d'un ministère.
  ///
  /// Cette méthode permet de mettre à jour seulement une traduction spécifique
  /// sans modifier les autres traductions.
  ///
  /// [id] : Identifiant du ministère à mettre à jour
  /// [langCode] : Code de la langue de la traduction à mettre à jour
  /// [translation] : Nouvelle traduction
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun ministère n'a été mis à jour).
  Future<int> updateTranslation(
      String id, String langCode, String translation) async {
    try {
      // Vérifier si le code de langue est supporté
      if (!DatabaseSchema.supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final Map<String, Object?> values = {
        'nombre_$langCode': translation,
      };

      // Si c'est la langue par défaut, mettre également à jour la colonne 'nombre'
      if (langCode == DatabaseSchema.defaultLanguage) {
        values['nombre'] = translation;
      }

      return await _db.update(
        _tableName,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating ministerio translation: $e',
          name: 'MinisterioDao');
      throw Exception('Could not update ministerio translation: $e');
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
      developer.log('Error deleting all ministerios: $e',
          name: 'MinisterioDao');
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
      developer.log('Error checking if ministerio exists: $e',
          name: 'MinisterioDao');
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

  /// Recherche des ministères par nom dans une langue spécifique.
  ///
  /// [searchTerm] : Terme de recherche
  /// [langCode] : Code de la langue dans laquelle effectuer la recherche.
  /// Si null, la langue par défaut est utilisée.
  ///
  /// Retourne la liste des ministères correspondant à la recherche.
  Future<List<Ministerio>> searchByName(String searchTerm,
      {String? langCode}) async {
    try {
      final language = langCode ?? DatabaseSchema.defaultLanguage;

      // Vérifier si le code de langue est supporté
      if (!DatabaseSchema.supportedLanguages.contains(language)) {
        throw ArgumentError('Langue non supportée: $language');
      }

      // Construire la requête de recherche
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$language LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );

      return maps.map((map) => Ministerio.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching ministerios by name: $e',
          name: 'MinisterioDao');
      throw Exception('Could not search ministerios: $e');
    }
  }

  /// Vérifie si un ministère a une traduction pour une langue spécifique.
  ///
  /// [id] : Identifiant du ministère
  /// [langCode] : Code de la langue à vérifier
  ///
  /// Retourne true si une traduction existe, false sinon.
  Future<bool> hasTranslation(String id, String langCode) async {
    try {
      // Vérifier si le code de langue est supporté
      if (!DatabaseSchema.supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        columns: ['nombre_$langCode'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return false;
      }

      final value = maps.first['nombre_$langCode'];
      return value != null && value.toString().isNotEmpty;
    } catch (e) {
      developer.log('Error checking if ministerio has translation: $e',
          name: 'MinisterioDao');
      throw Exception('Could not check if ministerio has translation: $e');
    }
  }

  /// Récupère les langues disponibles pour un ministère.
  ///
  /// [id] : Identifiant du ministère
  ///
  /// Retourne la liste des codes de langue pour lesquelles une traduction existe.
  Future<List<String>> getAvailableLanguages(String id) async {
    try {
      // Construire la liste des colonnes à récupérer
      final List<String> columns = [];

      for (final lang in DatabaseSchema.supportedLanguages) {
        columns.add('nombre_$lang');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        columns: columns,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return [];
      }

      final List<String> availableLanguages = [];
      final row = maps.first;

      for (final lang in DatabaseSchema.supportedLanguages) {
        final value = row['nombre_$lang'];
        if (value != null && value.toString().isNotEmpty) {
          availableLanguages.add(lang);
        }
      }

      return availableLanguages;
    } catch (e) {
      developer.log('Error getting available languages for ministerio: $e',
          name: 'MinisterioDao');
      throw Exception('Could not get available languages for ministerio: $e');
    }
  }
}
