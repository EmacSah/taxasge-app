import 'package:sqflite/sqflite.dart';
import '../../models/sector.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des secteurs avec support multilingue.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des secteurs dans la base de données.
class SectorDao {
  /// Instance de la base de données
  final Database _db;

  /// Constructeur
  SectorDao(this._db);

  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableSectores;

  /// Langues supportées
  final List<String> _supportedLanguages = DatabaseSchema.supportedLanguages;

  /// Langue par défaut
  ///final String _defaultLanguage = DatabaseSchema.defaultLanguage;

  /// Insère un nouveau secteur dans la base de données.
  ///
  /// Retourne l'ID du secteur inséré.
  /// Lève une exception en cas d'erreur.
  Future<String> insert(Sector sector) async {
    try {
      await _db.insert(
        _tableName,
        sector.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return sector.id;
    } catch (e) {
      developer.log('Error inserting sector: $e', name: 'SectorDao');
      throw Exception('Could not insert sector: $e');
    }
  }

  /// Insère plusieurs secteurs en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les secteurs un par un
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<Sector> sectors) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();

        for (final sector in sectors) {
          batch.insert(
            _tableName,
            sector.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple sectors: $e', name: 'SectorDao');
      throw Exception('Could not insert sectors: $e');
    }
  }

  /// Récupère un secteur par son ID.
  ///
  /// Retourne null si aucun secteur n'est trouvé avec cet ID.
  Future<Sector?> getById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      return Sector.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting sector by id: $e', name: 'SectorDao');
      throw Exception('Could not get sector: $e');
    }
  }

  /// Récupère tous les secteurs.
  ///
  /// Les secteurs sont optionnellement triés par le champ spécifié et dans la langue spécifiée.
  Future<List<Sector>> getAll({String? orderBy, String? langCode}) async {
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

      return maps.map((map) => Sector.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all sectors: $e', name: 'SectorDao');
      throw Exception('Could not get sectors: $e');
    }
  }

  /// Récupère tous les secteurs pour un ministère spécifique.
  ///
  /// Les secteurs sont optionnellement triés par le champ spécifié et dans la langue spécifiée.
  Future<List<Sector>> getByMinisterioId(String ministerioId,
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
        where: 'ministerio_id = ?',
        whereArgs: [ministerioId],
        orderBy: effectiveOrderBy ?? 'nombre',
      );

      return maps.map((map) => Sector.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting sectors by ministerio id: $e',
          name: 'SectorDao');
      throw Exception('Could not get sectors for ministerio: $e');
    }
  }

  /// Met à jour un secteur existant.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun secteur n'a été mis à jour).
  Future<int> update(Sector sector) async {
    try {
      return await _db.update(
        _tableName,
        sector.toMap(),
        where: 'id = ?',
        whereArgs: [sector.id],
      );
    } catch (e) {
      developer.log('Error updating sector: $e', name: 'SectorDao');
      throw Exception('Could not update sector: $e');
    }
  }

  /// Met à jour une traduction spécifique d'un secteur.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun secteur n'a été mis à jour).
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
      developer.log('Error updating sector translation: $e', name: 'SectorDao');
      throw Exception('Could not update sector translation: $e');
    }
  }

  /// Supprime un secteur par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun secteur n'a été supprimé).
  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting sector: $e', name: 'SectorDao');
      throw Exception('Could not delete sector: $e');
    }
  }

  /// Supprime tous les secteurs d'un ministère spécifique.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteByMinisterioId(String ministerioId) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'ministerio_id = ?',
        whereArgs: [ministerioId],
      );
    } catch (e) {
      developer.log('Error deleting sectors by ministerio id: $e',
          name: 'SectorDao');
      throw Exception('Could not delete sectors for ministerio: $e');
    }
  }

  /// Supprime tous les secteurs.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all sectors: $e', name: 'SectorDao');
      throw Exception('Could not delete sectors: $e');
    }
  }

  /// Vérifie si un secteur existe par son ID.
  ///
  /// Retourne true si le secteur existe, false sinon.
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
      developer.log('Error checking if sector exists: $e', name: 'SectorDao');
      throw Exception('Could not check if sector exists: $e');
    }
  }

  /// Récupère le nombre total de secteurs dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );

      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting sectors: $e', name: 'SectorDao');
      throw Exception('Could not count sectors: $e');
    }
  }

  /// Récupère le nombre de secteurs pour un ministère spécifique.
  Future<int> countByMinisterioId(String ministerioId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE ministerio_id = ?',
        [ministerioId],
      );

      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting sectors by ministerio id: $e',
          name: 'SectorDao');
      throw Exception('Could not count sectors for ministerio: $e');
    }
  }

  /// Recherche des secteurs par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Il est possible de rechercher dans une langue spécifique.
  Future<List<Sector>> searchByName(String searchTerm,
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

      return maps.map((map) => Sector.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching sectors by name: $e', name: 'SectorDao');
      throw Exception('Could not search sectors: $e');
    }
  }

  /// Récupère les secteurs qui ont une traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les secteurs qui n'ont pas encore été traduits.
  Future<List<Sector>> getSectorsWithTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NOT NULL AND nombre_$langCode <> ""',
      );

      return maps.map((map) => Sector.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting sectors with translation: $e',
          name: 'SectorDao');
      throw Exception('Could not get sectors with translation: $e');
    }
  }

  /// Récupère les secteurs qui n'ont pas de traduction disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les secteurs qui doivent être traduits.
  Future<List<Sector>> getSectorsWithoutTranslation(String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NULL OR nombre_$langCode = ""',
      );

      return maps.map((map) => Sector.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting sectors without translation: $e',
          name: 'SectorDao');
      throw Exception('Could not get sectors without translation: $e');
    }
  }

  /// Récupère les langues disponibles pour un secteur spécifique
  ///
  /// Cette méthode retourne la liste des codes de langue pour lesquels
  /// le secteur possède des traductions.
  Future<List<String>> getAvailableLanguagesForSector(String sectorId) async {
    try {
      final sector = await getById(sectorId);
      if (sector == null) {
        return [];
      }

      final List<String> availableLanguages = [];

      for (final lang in _supportedLanguages) {
        if (sector.nombreTraductions.containsKey(lang) &&
            sector.nombreTraductions[lang]!.isNotEmpty) {
          availableLanguages.add(lang);
        }
      }

      return availableLanguages;
    } catch (e) {
      developer.log('Error getting available languages for sector: $e',
          name: 'SectorDao');
      throw Exception('Could not get available languages for sector: $e');
    }
  }
}
