import 'package:sqflite/sqflite.dart';
import '../../models/concepto.dart';
import '../schema.dart';
import 'dart:developer' as developer;

/// Data Access Object pour la table des concepts (taxes).
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
      developer.log('Error inserting multiple conceptos: $e', name: 'ConceptoDao');
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
      
      // Récupération du concept
      final conceptoData = maps.first;
      
      // Création du modèle Concepto complet
      return Concepto.fromMap(conceptoData);
    } catch (e) {
      developer.log('Error getting concepto by id: $e', name: 'ConceptoDao');
      throw Exception('Could not get concepto: $e');
    }
  }
  
  /// Récupère un concept par son ID avec toutes ses relations (documents requis, mots-clés).
  ///
  /// Retourne null si aucun concept n'est trouvé avec cet ID.
  Future<Concepto?> getByIdWithRelations(String id) async {
    try {
      // Récupération du concept
      final concepto = await getById(id);
      
      if (concepto == null) {
        return null;
      }
      
      // Enrichir le modèle avec les relations
      // Note: Ces méthodes seraient implémentées dans les DAO correspondants
      // et seraient appelées ici. Pour l'exemple, on les simule.
      
      // Exemple de code commenté pour montrer comment cela fonctionnerait
      // avec des DAOs externes:
      // 
      // final documentsDao = DocumentoRequeridoDao(_db);
      // final documents = await documentsDao.getByConceptoId(id);
      // 
      // final motsClesDao = MotCleDao(_db);
      // final motsCles = await motsClesDao.getByConceptoId(id);
      // 
      // return concepto.copyWith(
      //   documentosRequeridos: documents,
      //   motsClave: motsCles,
      // );
      
      return concepto;
    } catch (e) {
      developer.log('Error getting concepto with relations by id: $e', name: 'ConceptoDao');
      throw Exception('Could not get concepto with relations: $e');
    }
  }
  
  /// Récupère tous les concepts.
  ///
  /// Les concepts sont optionnellement triés par le champ spécifié.
  Future<List<Concepto>> getAll({String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        orderBy: orderBy,
      );
      
      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting all conceptos: $e', name: 'ConceptoDao');
      throw Exception('Could not get conceptos: $e');
    }
  }
  
  /// Récupère tous les concepts pour une sous-catégorie spécifique.
  ///
  /// Les concepts sont optionnellement triés par le champ spécifié.
  Future<List<Concepto>> getBySubCategoriaId(String subCategoriaId, {String? orderBy}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'sub_categoria_id = ?',
        whereArgs: [subCategoriaId],
        orderBy: orderBy,
      );
      
      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting conceptos by sub_categoria id: $e', name: 'ConceptoDao');
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
      developer.log('Error deleting conceptos by sub_categoria id: $e', name: 'ConceptoDao');
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
      developer.log('Error checking if concepto exists: $e', name: 'ConceptoDao');
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
      developer.log('Error counting conceptos by sub_categoria id: $e', name: 'ConceptoDao');
      throw Exception('Could not count conceptos for sub_categoria: $e');
    }
  }
  
  /// Recherche des concepts par nom.
  ///
  /// La recherche est insensible à la casse et utilise le pattern LIKE %term%.
  Future<List<Concepto>> searchByName(String searchTerm) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        _tableName,
        where: 'nombre LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );
      
      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching conceptos by name: $e', name: 'ConceptoDao');
      throw Exception('Could not search conceptos: $e');
    }
  }
  
  /// Recherche des concepts par montant (tasa_expedicion ou tasa_renovacion).
  ///
  /// Retourne les concepts dont le montant est inférieur ou égal à la valeur spécifiée.
  Future<List<Concepto>> searchByAmount(String campo, String amount) async {
    try {
      if (campo != 'tasa_expedicion' && campo != 'tasa_renovacion') {
        throw ArgumentError('Campo debe ser "tasa_expedicion" o "tasa_renovacion"');
      }
      
      // Note: Cette recherche est simplifiée, car les montants sont stockés sous forme de texte.
      // Une implémentation plus robuste utiliserait des conversions numériques appropriées.
      final List<Map<String, dynamic>> maps = await _db.rawQuery(
        'SELECT * FROM $_tableName WHERE $campo <= ?',
        [amount],
      );
      
      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error searching conceptos by amount: $e', name: 'ConceptoDao');
      throw Exception('Could not search conceptos by amount: $e');
    }
  }
  
  /// Recherche avancée de concepts avec plusieurs critères.
  ///
  /// Permet de combiner des critères sur le nom, le ministère, le secteur, la catégorie,
  /// et les montants des taxes.
  Future<List<Concepto>> advancedSearch({
    String? searchTerm,
    String? ministerioId,
    String? sectorId,
    String? categoriaId,
    String? subCategoriaId,
    String? maxTasaExpedicion,
    String? maxTasaRenovacion,
  }) async {
    try {
      // Construction de la requête SQL avec des conditions dynamiques
      final conditions = <String>[];
      final arguments = <Object>[];
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        conditions.add('c.nombre LIKE ?');
        arguments.add('%$searchTerm%');
      }
      
      if (subCategoriaId != null && subCategoriaId.isNotEmpty) {
        conditions.add('c.sub_categoria_id = ?');
        arguments.add(subCategoriaId);
      } else if (categoriaId != null && categoriaId.isNotEmpty) {
        conditions.add('sc.categoria_id = ?');
        arguments.add(categoriaId);
      } else if (sectorId != null && sectorId.isNotEmpty) {
        conditions.add('cat.sector_id = ?');
        arguments.add(sectorId);
      } else if (ministerioId != null && ministerioId.isNotEmpty) {
        conditions.add('s.ministerio_id = ?');
        arguments.add(ministerioId);
      }
      
      if (maxTasaExpedicion != null && maxTasaExpedicion.isNotEmpty) {
        // Note: Cette comparaison de texte peut ne pas fonctionner correctement pour des montants
        // Une implémentation réelle devrait convertir les montants en valeurs numériques
        conditions.add('c.tasa_expedicion <= ?');
        arguments.add(maxTasaExpedicion);
      }
      
      if (maxTasaRenovacion != null && maxTasaRenovacion.isNotEmpty) {
        conditions.add('c.tasa_renovacion <= ?');
        arguments.add(maxTasaRenovacion);
      }
      
      final whereClause = conditions.isEmpty 
          ? '' 
          : 'WHERE ${conditions.join(' AND ')}';
      
      // Requête SQL avec jointures pour permettre le filtrage par hiérarchie
      final query = '''
        SELECT c.* FROM $_tableName c
        JOIN ${DatabaseSchema.tableSubCategorias} sc ON c.sub_categoria_id = sc.id
        JOIN ${DatabaseSchema.tableCategorias} cat ON sc.categoria_id = cat.id
        JOIN ${DatabaseSchema.tableSectores} s ON cat.sector_id = s.id
        JOIN ${DatabaseSchema.tableMinisterios} m ON s.ministerio_id = m.id
        $whereClause
        ORDER BY c.nombre
      ''';
      
      final List<Map<String, dynamic>> maps = await _db.rawQuery(query, arguments);
      
      return maps.map((map) => Concepto.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error in advanced search: $e', name: 'ConceptoDao');
      throw Exception('Could not perform advanced search: $e');
    }
  }
}