import 'package:sqflite/sqflite.dart';
import '../../models/concepto.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des concepts (taxes) avec support multilingue.
///
/// Cette classe fournit les méthodes pour effectuer les opérations CRUD
/// (Create, Read, Update, Delete) sur la table des concepts dans la base de données.
class ConceptoDao {
  /// Instance de la base de données
  final Database _db;

  /// Constructeur
  ConceptoDao(this._db);

  /// Nom de la table
  static const String _tableName = DatabaseSchema.tableConceptos;

  /// Langues supportées
  final List<String> _supportedLanguages = DatabaseSchema.supportedLanguages;

  /// Langue par défaut
  ///final String _defaultLanguage = DatabaseSchema.defaultLanguage;

  /// Insère un nouveau concept dans la base de données.
  ///
  /// Retourne l'ID du concept inséré.
  /// Lève une exception en cas d'erreur.
  Future<String> insert(Concepto concepto) async {
    try {
      await _db.insert(
        _tableName,
        concepto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return concepto.id;
    } catch (e) {
      developer.log('Error inserting concepto: $e', name: 'ConceptoDao');
      throw Exception('Could not insert concepto: $e');
    }
  }

  /// Insère plusieurs concepts en une seule transaction.
  ///
  /// Cette méthode est plus efficace que d'insérer les concepts un par un
  /// lorsqu'il y a un grand nombre d'insertions à effectuer.
  Future<void> insertAll(List<Concepto> conceptos) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();

        for (final concepto in conceptos) {
          batch.insert(
            _tableName,
            concepto.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit(noResult: true);
      });
    } catch (e) {
      developer.log('Error inserting multiple conceptos: $e',
          name: 'ConceptoDao');
      throw Exception('Could not insert conceptos: $e');
    }
  }

  /// Récupère un concept par son ID.
  ///
  /// Retourne null si aucun concept n'est trouvé avec cet ID.
  Future<Concepto?> getById(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return null;
      }

      return Concepto.fromMap(maps.first);
    } catch (e) {
      developer.log('Error getting concepto by id: $e', name: 'ConceptoDao');
      throw Exception('Could not get concepto: $e');
    }
  }

  /// Récupère tous les concepts.
  ///
  /// Les concepts sont optionnellement triés par le champ spécifié et dans la langue spécifiée.
  Future<List<Concepto>> getAll({String? orderBy, String? langCode}) async {
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

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all conceptos: $e', name: 'ConceptoDao');
      throw Exception('Could not get conceptos: $e');
    }
  }

  /// Récupère tous les concepts pour une sous-catégorie spécifique.
  ///
  /// Les concepts sont optionnellement triés par le champ spécifié et dans la langue spécifiée.
  Future<List<Concepto>> getBySubCategoriaId(String subCategoriaId,
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
        where: 'sub_categoria_id = ?',
        whereArgs: [subCategoriaId],
        orderBy: effectiveOrderBy ?? 'nombre',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting conceptos by sub_categoria id: $e',
          name: 'ConceptoDao');
      throw Exception('Could not get conceptos for sub_categoria: $e');
    }
  }

  /// Met à jour un concept existant.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun concept n'a été mis à jour).
  Future<int> update(Concepto concepto) async {
    try {
      return await _db.update(
        _tableName,
        concepto.toMap(),
        where: 'id = ?',
        whereArgs: [concepto.id],
      );
    } catch (e) {
      developer.log('Error updating concepto: $e', name: 'ConceptoDao');
      throw Exception('Could not update concepto: $e');
    }
  }

  /// Met à jour une traduction spécifique du nom d'un concept.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun concept n'a été mis à jour).
  Future<int> updateNombreTranslation(
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
      developer.log('Error updating concepto nombre translation: $e',
          name: 'ConceptoDao');
      throw Exception('Could not update concepto nombre translation: $e');
    }
  }

  /// Met à jour une traduction spécifique des documents requis d'un concept.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun concept n'a été mis à jour).
  Future<int> updateDocumentosRequeridosTranslation(
      String id, String langCode, String documentosRequeridos) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      return await _db.update(
        _tableName,
        {'documentos_requeridos_$langCode': documentosRequeridos},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log(
          'Error updating concepto documentos_requeridos translation: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not update concepto documentos_requeridos translation: $e');
    }
  }

  /// Met à jour une traduction spécifique de la procédure d'un concept.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun concept n'a été mis à jour).
  Future<int> updateProcedimientoTranslation(
      String id, String langCode, String procedimiento) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      return await _db.update(
        _tableName,
        {'procedimiento_$langCode': procedimiento},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error updating concepto procedimiento translation: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not update concepto procedimiento translation: $e');
    }
  }

  /// Supprime un concept par son ID.
  ///
  /// Retourne le nombre de lignes affectées (0 si aucun concept n'a été supprimé).
  Future<int> delete(String id) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      developer.log('Error deleting concepto: $e', name: 'ConceptoDao');
      throw Exception('Could not delete concepto: $e');
    }
  }

  /// Supprime tous les concepts d'une sous-catégorie spécifique.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteBySubCategoriaId(String subCategoriaId) async {
    try {
      return await _db.delete(
        _tableName,
        where: 'sub_categoria_id = ?',
        whereArgs: [subCategoriaId],
      );
    } catch (e) {
      developer.log('Error deleting conceptos by sub_categoria id: $e',
          name: 'ConceptoDao');
      throw Exception('Could not delete conceptos for sub_categoria: $e');
    }
  }

  /// Supprime tous les concepts.
  ///
  /// Retourne le nombre de lignes affectées.
  Future<int> deleteAll() async {
    try {
      return await _db.delete(_tableName);
    } catch (e) {
      developer.log('Error deleting all conceptos: $e', name: 'ConceptoDao');
      throw Exception('Could not delete conceptos: $e');
    }
  }

  /// Vérifie si un concept existe par son ID.
  ///
  /// Retourne true si le concept existe, false sinon.
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
      developer.log('Error checking if concepto exists: $e',
          name: 'ConceptoDao');
      throw Exception('Could not check if concepto exists: $e');
    }
  }

  /// Récupère le nombre total de concepts dans la base de données.
  Future<int> count() async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );

      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting conceptos: $e', name: 'ConceptoDao');
      throw Exception('Could not count conceptos: $e');
    }
  }

  /// Récupère le nombre de concepts pour une sous-catégorie spécifique.
  Future<int> countBySubCategoriaId(String subCategoriaId) async {
    try {
      final List<Map<String, dynamic>> result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE sub_categoria_id = ?',
        [subCategoriaId],
      );

      return result.first['count'] as int;
    } catch (e) {
      developer.log('Error counting conceptos by sub_categoria id: $e',
          name: 'ConceptoDao');
      throw Exception('Could not count conceptos for sub_categoria: $e');
    }
  }

  /// Recherche des concepts par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Il est possible de rechercher dans une langue spécifique.
  Future<List<Concepto>> searchByName(String searchTerm,
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

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching conceptos by name: $e',
          name: 'ConceptoDao');
      throw Exception('Could not search conceptos: $e');
    }
  }

  /// Recherche des concepts par procédure.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Il est possible de rechercher dans une langue spécifique.
  Future<List<Concepto>> searchByProcedimiento(String searchTerm,
      {String? langCode}) async {
    try {
      String whereClause;
      List<Object> whereArgs = [];

      if (langCode != null && _supportedLanguages.contains(langCode)) {
        // Recherche dans une langue spécifique
        whereClause = 'procedimiento_$langCode LIKE ?';
        whereArgs.add('%$searchTerm%');
      } else {
        // Recherche dans toutes les langues (par défaut)
        List<String> conditions = [];

        // Ajouter le champ 'procedimiento' original pour compatibilité
        conditions.add('procedimiento LIKE ?');
        whereArgs.add('%$searchTerm%');

        // Ajouter les colonnes de traduction
        for (final lang in _supportedLanguages) {
          conditions.add('procedimiento_$lang LIKE ?');
          whereArgs.add('%$searchTerm%');
        }

        whereClause = conditions.join(' OR ');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching conceptos by procedimiento: $e',
          name: 'ConceptoDao');
      throw Exception('Could not search conceptos by procedimiento: $e');
    }
  }

  /// Recherche des concepts par documents requis.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  /// Il est possible de rechercher dans une langue spécifique.
  Future<List<Concepto>> searchByDocumentosRequeridos(String searchTerm,
      {String? langCode}) async {
    try {
      String whereClause;
      List<Object> whereArgs = [];

      if (langCode != null && _supportedLanguages.contains(langCode)) {
        // Recherche dans une langue spécifique
        whereClause = 'documentos_requeridos_$langCode LIKE ?';
        whereArgs.add('%$searchTerm%');
      } else {
        // Recherche dans toutes les langues (par défaut)
        List<String> conditions = [];

        // Ajouter le champ 'documentos_requeridos' original pour compatibilité
        conditions.add('documentos_requeridos LIKE ?');
        whereArgs.add('%$searchTerm%');

        // Ajouter les colonnes de traduction
        for (final lang in _supportedLanguages) {
          conditions.add('documentos_requeridos_$lang LIKE ?');
          whereArgs.add('%$searchTerm%');
        }

        whereClause = conditions.join(' OR ');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching conceptos by documentos_requeridos: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not search conceptos by documentos_requeridos: $e');
    }
  }

  /// Recherche avancée de concepts avec plusieurs critères.
  ///
  /// Cette méthode permet de rechercher des concepts en combinant plusieurs critères
  /// comme le terme de recherche, le ministère, le secteur, la catégorie, etc.
  Future<List<Concepto>> advancedSearch({
    String? searchTerm,
    String? ministerioId,
    String? sectorId,
    String? categoriaId,
    String? subCategoriaId,
    String? maxTasaExpedicion,
    String? maxTasaRenovacion,
    String? langCode,
  }) async {
    try {
      // Construire la requête SQL de manière dynamique
      final StringBuffer queryBuffer = StringBuffer();
      final List<String> conditions = [];
      final List<Object> args = [];

      // Table de base et jointures nécessaires
      queryBuffer.write('''
        SELECT c.* FROM $_tableName c
        JOIN ${DatabaseSchema.tableSubCategorias} sc ON c.sub_categoria_id = sc.id
        JOIN ${DatabaseSchema.tableCategorias} cat ON sc.categoria_id = cat.id
        JOIN ${DatabaseSchema.tableSectores} s ON cat.sector_id = s.id
      ''');

      // Condition pour la recherche par terme
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final List<String> searchConditions = [];

        if (langCode != null && _supportedLanguages.contains(langCode)) {
          // Recherche dans une langue spécifique
          searchConditions.add('c.nombre_$langCode LIKE ?');
          args.add('%$searchTerm%');
          searchConditions.add('c.procedimiento_$langCode LIKE ?');
          args.add('%$searchTerm%');
          searchConditions.add('c.documentos_requeridos_$langCode LIKE ?');
          args.add('%$searchTerm%');
        } else {
          // Recherche dans toutes les langues
          searchConditions.add('c.nombre LIKE ?');
          args.add('%$searchTerm%');

          for (final lang in _supportedLanguages) {
            searchConditions.add('c.nombre_$lang LIKE ?');
            args.add('%$searchTerm%');
            searchConditions.add('c.procedimiento_$lang LIKE ?');
            args.add('%$searchTerm%');
            searchConditions.add('c.documentos_requeridos_$lang LIKE ?');
            args.add('%$searchTerm%');
          }
        }

        // Ajouter une jointure pour rechercher aussi dans les mots-clés
        queryBuffer.write('''
          LEFT JOIN ${DatabaseSchema.tableMotsCles} mk ON c.id = mk.concepto_id
        ''');

        // Ajouter la condition pour les mots-clés avec la bonne langue
        if (langCode != null && _supportedLanguages.contains(langCode)) {
          searchConditions.add('(mk.mot_cle LIKE ? AND mk.lang_code = ?)');
          args.add('%$searchTerm%');
          args.add(langCode);
        } else {
          searchConditions.add('mk.mot_cle LIKE ?');
          args.add('%$searchTerm%');
        }

        conditions.add('(${searchConditions.join(' OR ')})');
      }

      // Condition pour le ministère
      if (ministerioId != null && ministerioId.isNotEmpty) {
        conditions.add('s.ministerio_id = ?');
        args.add(ministerioId);
      }

      // Condition pour le secteur
      if (sectorId != null && sectorId.isNotEmpty) {
        conditions.add('cat.sector_id = ?');
        args.add(sectorId);
      }

      // Condition pour la catégorie
      if (categoriaId != null && categoriaId.isNotEmpty) {
        conditions.add('sc.categoria_id = ?');
        args.add(categoriaId);
      }

      // Condition pour la sous-catégorie
      if (subCategoriaId != null && subCategoriaId.isNotEmpty) {
        conditions.add('c.sub_categoria_id = ?');
        args.add(subCategoriaId);
      }

      // Condition pour le montant maximum d'expédition
      if (maxTasaExpedicion != null && maxTasaExpedicion.isNotEmpty) {
        try {
          final double value =
              double.parse(maxTasaExpedicion.replaceAll(' ', ''));
          conditions
              .add('CAST(REPLACE(c.tasa_expedicion, " ", "") AS NUMERIC) <= ?');
          args.add(value);
        } catch (e) {
          developer.log('Invalid maxTasaExpedicion value: $maxTasaExpedicion',
              name: 'ConceptoDao');
          // Ne pas ajouter la condition si la valeur n'est pas valide
        }
      }

      // Condition pour le montant maximum de renouvellement
      if (maxTasaRenovacion != null && maxTasaRenovacion.isNotEmpty) {
        try {
          final double value =
              double.parse(maxTasaRenovacion.replaceAll(' ', ''));
          conditions
              .add('CAST(REPLACE(c.tasa_renovacion, " ", "") AS NUMERIC) <= ?');
          args.add(value);
        } catch (e) {
          developer.log('Invalid maxTasaRenovacion value: $maxTasaRenovacion',
              name: 'ConceptoDao');
          // Ne pas ajouter la condition si la valeur n'est pas valide
        }
      }

      // Ajouter les conditions à la requête
      if (conditions.isNotEmpty) {
        queryBuffer.write(' WHERE ${conditions.join(' AND ')}');
      }

      // Ajouter GROUP BY pour éviter les doublons dus à la jointure avec les mots-clés
      queryBuffer.write(' GROUP BY c.id');

      // Ordre de tri
      String orderByClause = 'c.nombre';
      if (langCode != null && _supportedLanguages.contains(langCode)) {
        orderByClause = 'c.nombre_$langCode';
      }
      queryBuffer.write(' ORDER BY $orderByClause');

      // Exécuter la requête
      final List<Map<String, dynamic>> maps = await _db.rawQuery(
        queryBuffer.toString(),
        args,
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error performing advanced search: $e',
          name: 'ConceptoDao');
      throw Exception('Could not perform advanced search: $e');
    }
  }

  /// Récupère les concepts qui ont une traduction de nom disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les concepts qui n'ont pas encore été traduits.
  Future<List<Concepto>> getConceptosWithNombreTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NOT NULL AND nombre_$langCode <> ""',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting conceptos with nombre translation: $e',
          name: 'ConceptoDao');
      throw Exception('Could not get conceptos with nombre translation: $e');
    }
  }

  /// Récupère les concepts qui n'ont pas de traduction de nom disponible dans la langue spécifiée.
  ///
  /// Cette méthode est utile pour identifier les concepts qui doivent être traduits.
  Future<List<Concepto>> getConceptosWithoutNombreTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre_$langCode IS NULL OR nombre_$langCode = ""',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting conceptos without nombre translation: $e',
          name: 'ConceptoDao');
      throw Exception('Could not get conceptos without nombre translation: $e');
    }
  }

  /// Récupère les concepts qui ont une traduction de procédure disponible dans la langue spécifiée.
  Future<List<Concepto>> getConceptosWithProcedimientoTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where:
            'procedimiento_$langCode IS NOT NULL AND procedimiento_$langCode <> ""',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log(
          'Error getting conceptos with procedimiento translation: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not get conceptos with procedimiento translation: $e');
    }
  }

  /// Récupère les concepts qui n'ont pas de traduction de procédure disponible dans la langue spécifiée.
  Future<List<Concepto>> getConceptosWithoutProcedimientoTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where:
            'procedimiento_$langCode IS NULL OR procedimiento_$langCode = ""',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log(
          'Error getting conceptos without procedimiento translation: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not get conceptos without procedimiento translation: $e');
    }
  }

  /// Récupère les concepts qui ont une traduction de documents requis disponible dans la langue spécifiée.
  Future<List<Concepto>> getConceptosWithDocumentosRequeridosTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where:
            'documentos_requeridos_$langCode IS NOT NULL AND documentos_requeridos_$langCode <> ""',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log(
          'Error getting conceptos with documentos_requeridos translation: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not get conceptos with documentos_requeridos translation: $e');
    }
  }

  /// Récupère les concepts qui n'ont pas de traduction de documents requis disponible dans la langue spécifiée.
  Future<List<Concepto>> getConceptosWithoutDocumentosRequeridosTranslation(
      String langCode) async {
    try {
      if (!_supportedLanguages.contains(langCode)) {
        throw ArgumentError('Langue non supportée: $langCode');
      }

      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where:
            'documentos_requeridos_$langCode IS NULL OR documentos_requeridos_$langCode = ""',
      );

      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log(
          'Error getting conceptos without documentos_requeridos translation: $e',
          name: 'ConceptoDao');
      throw Exception(
          'Could not get conceptos without documentos_requeridos translation: $e');
    }
  }

  /// Récupère les langues disponibles pour un concept spécifique
  ///
  /// Cette méthode retourne la liste des codes de langue pour lesquels
  /// le concept possède des traductions.
  Future<Map<String, List<String>>> getAvailableLanguagesForConcepto(
      String conceptoId) async {
    try {
      final concepto = await getById(conceptoId);
      if (concepto == null) {
        return {};
      }

      final Map<String, List<String>> availableLanguages = {
        'nombre': [],
        'documentos_requeridos': [],
        'procedimiento': []
      };

      // Vérifier les traductions disponibles pour le nom
      for (final lang in _supportedLanguages) {
        if (concepto.nombreTraductions.containsKey(lang) &&
            concepto.nombreTraductions[lang]!.isNotEmpty) {
          availableLanguages['nombre']!.add(lang);
        }
      }

      // Vérifier les traductions disponibles pour les documents requis
      if (concepto.documentosRequeridosTraductions != null) {
        for (final lang in _supportedLanguages) {
          if (concepto.documentosRequeridosTraductions!.containsKey(lang) &&
              concepto.documentosRequeridosTraductions![lang]!.isNotEmpty) {
            availableLanguages['documentos_requeridos']!.add(lang);
          }
        }
      }

      // Vérifier les traductions disponibles pour la procédure
      if (concepto.procedimientoTraductions != null) {
        for (final lang in _supportedLanguages) {
          if (concepto.procedimientoTraductions!.containsKey(lang) &&
              concepto.procedimientoTraductions![lang]!.isNotEmpty) {
            availableLanguages['procedimiento']!.add(lang);
          }
        }
      }

      return availableLanguages;
    } catch (e) {
      developer.log('Error getting available languages for concepto: $e',
          name: 'ConceptoDao');
      throw Exception('Could not get available languages for concepto: $e');
    }
  }
}
