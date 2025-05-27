import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/services.dart';
//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'dart:io';
import 'dart:convert';

/// Configuration partagée pour tous les tests de l'application TaxasGE
///
/// Cette classe centralise la configuration des tests et fournit des utilitaires
/// communs pour initialiser l'environnement de test, notamment la base de données
/// et les mocks nécessaires.
class TestConfig {
  static Database? _db;
  static DatabaseService? _databaseService;
  static bool _isInitialized = false;

   /// Initialise l'environnement de test global
  ///
  /// Cette méthode doit être appelée avant tous les tests qui nécessitent
  /// une base de données ou des services Flutter.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialisation de Flutter pour les tests
    TestWidgetsFlutterBinding.ensureInitialized();

    // Configuration sqflite pour les tests sur desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Configuration des mocks pour les assets
    _setupAssetMocks();

    _isInitialized = true;
  }

  /// Configure les mocks pour le chargement des assets
  static void _setupAssetMocks() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/assets'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAssetData') {
          final String assetPath = methodCall.arguments.toString();

          // Mock pour le fichier de taxes de test
          if (assetPath.contains('test_taxes.json')) {
              final file = File('test/test_assets/test_taxes.json');
              final content = await file.readAsString();
              return Uint8List.fromList(utf8.encode(content)).buffer.asByteData();
          }

          // Mock pour d'autres assets si nécessaire
          if (assetPath.contains('taxasge_model.tflite')) {
            // Retourne un fichier vide pour les tests
            return Uint8List(0).buffer.asByteData();
          }
        }
        return null;
      },
    );
  }

  /// Initialise une base de données de test fraîche
  ///
  /// [testData] Données JSON optionnelles pour initialiser la base
  /// [forceReset] Force la suppression de la base existante
  static Future<DatabaseService> initializeDatabase({
    String? testData,
    bool forceReset = true,
  }) async {
    await initialize();

    // Supprime l'ancienne instance si elle existe
    if (_databaseService != null) {
      await _databaseService!.close();
      _databaseService = null;
    }

    // Crée une nouvelle instance du service
    _databaseService = DatabaseService();

    await _databaseService!.initialize(
      forceReset: forceReset,
      testJsonString: testData,
      //testJsonString: testData ?? defaultTestDataJson,
    );

    return _databaseService!;
  }

  /// Obtient l'instance de la base de données de test
  static Database get database {
    if (_db == null) {
      throw Exception(
          'Database not initialized. Call TestConfig.initializeDatabase() first');
    }
    return _db!;
  }

  /// Obtient le service de base de données de test
  static DatabaseService get databaseService {
    if (_databaseService == null) {
      throw Exception(
          'DatabaseService not initialized. Call TestConfig.initializeDatabase() first');
    }
    return _databaseService!;
  }

  /// Définit l'instance de base de données (pour compatibilité)
  static void setDatabase(Database db) {
    _db = db;
  }

  /// Nettoie toutes les ressources de test
  static Future<void> cleanup() async {
    if (_databaseService != null) {
      await _databaseService!.close();
      _databaseService = null;
    }

    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    // Supprime les mocks
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);

    _isInitialized = false;
  }

  /// Crée des données de test personnalisées pour un ministère
  ///
  /// [ministerioId] ID du ministère
  /// [ministerioName] Nom du ministère en espagnol
  /// [conceptCount] Nombre de concepts à créer
  static String createTestMinisterio({
    required String ministerioId,
    required String ministerioName,
    int conceptCount = 1,
  }) {
    // Cette méthode pourrait être étoffée pour générer des données
    // de test plus complexes selon les besoins
    return '[]';
  }

  /// Vérifie que l'environnement de test est correctement configuré
  static void validateTestEnvironment() {
    if (!_isInitialized) {
      throw Exception('Test environment not initialized');
    }

    // Vérifie que sqflite est configuré correctement
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (databaseFactory != databaseFactoryFfi) {
        throw Exception('sqflite_ffi not properly configured');
      }
    }
  }

  /// Méthode utilitaire pour attendre que les opérations asynchrones se terminent
  static Future<void> waitForAsyncOperations() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Utilitaire pour générer des IDs de test uniques
  static String generateTestId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-TEST-$timestamp';
  }
}
