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