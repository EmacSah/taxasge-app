import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/services.dart';
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

  /// Données de test par défaut
  static const String defaultTestDataJson = '''[
  {
    "id": "M-TEST-001",
    "nombre": {
      "es": "MINISTERIO DE PRUEBA",
      "fr": "MINISTÈRE DE TEST",
      "en": "TEST MINISTRY"
    },
    "sectores": [
      {
        "id": "S-TEST-001",
        "nombre": {
          "es": "SECTOR DE PRUEBA",
          "fr": "SECTEUR DE TEST",
          "en": "TEST SECTOR"
        },
        "categorias": [
          {
            "id": "C-TEST-001",
            "nombre": {
              "es": "CATEGORIA DE PRUEBA",
              "fr": "CATÉGORIE DE TEST",
              "en": "TEST CATEGORY"
            },
            "sub_categorias": [
              {
                "id": "SC-TEST-001",
                "nombre": {
                  "es": "SUBCATEGORIA DE PRUEBA",
                  "fr": "SOUS-CATÉGORIE DE TEST",
                  "en": "TEST SUBCATEGORY"
                },
                "conceptos": [
                  {
                    "id": "T-TEST-001",
                    "nombre": {
                      "es": "CONCEPTO DE PRUEBA",
                      "fr": "CONCEPT DE TEST",
                      "en": "TEST CONCEPT"
                    },
                    "tasa_expedicion": "1000",
                    "tasa_renovacion": "500",
                    "documentos_requeridos": {
                      "es": "Documento 1\\nDocumento 2",
                      "fr": "Document 1\\nDocument 2",
                      "en": "Document 1\\nDocument 2"
                    },
                    "procedimiento": {
                      "es": "Paso 1: Llenar formulario\\nPaso 2: Pagar tasa",
                      "fr": "Étape 1: Remplir formulaire\\nÉtape 2: Payer taxe",
                      "en": "Step 1: Fill form\\nStep 2: Pay fee"
                    },
                    "palabras_clave": {
                      "es": "prueba, test, ejemplo",
                      "fr": "test, exemple, essai",
                      "en": "test, example, sample"
                    }
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
]''';

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
          if (assetPath.contains('test_taxes.json') ||
              assetPath.contains('taxes.json')) {
            try {
              // Essayer de charger le fichier réel d'abord
              final file = File('test/test_assets/test_taxes.json');
              if (await file.exists()) {
                final content = await file.readAsString();
                return Uint8List.fromList(utf8.encode(content))
                    .buffer
                    .asByteData();
              }
            } catch (e) {
              // Utiliser les données par défaut si le fichier n'existe pas
            }

            // Fallback sur les données par défaut
            return Uint8List.fromList(utf8.encode(defaultTestDataJson))
                .buffer
                .asByteData();
          }

          // Mock pour les modèles ML
          if (assetPath.contains('taxasge_model.tflite')) {
            // Retourne un modèle vide pour les tests
            return Uint8List(1024).buffer.asByteData();
          }

          // Mock pour les tokenizers
          if (assetPath.contains('tokenizer.json')) {
            const mockTokenizer = '''
            {
              "config": {
                "word_index": {
                  "<OOV>": 1,
                  "cuanto": 2,
                  "cuesta": 3,
                  "pasaporte": 4,
                  "precio": 5,
                  "documentos": 6,
                  "procedimiento": 7,
                  "ministerio": 8
                }
              }
            }
            ''';
            return Uint8List.fromList(utf8.encode(mockTokenizer))
                .buffer
                .asByteData();
          }

          // Mock pour autres assets
          if (assetPath.contains('.json')) {
            return Uint8List.fromList(utf8.encode('{}')).buffer.asByteData();
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
      try {
        await _databaseService!.close();
      } catch (e) {
        // Ignore les erreurs de fermeture
      }
      _databaseService = null;
    }

    // Crée une nouvelle instance du service
    _databaseService = DatabaseService();

    try {
      await _databaseService!.initialize(
        forceReset: forceReset,
        seedData: true,
        testJsonString: testData ?? defaultTestDataJson,
      );
    } catch (e) {
      // En cas d'erreur, réessayer avec les données par défaut
      try {
        await _databaseService!.initialize(
          forceReset: true,
          seedData: true,
          testJsonString: defaultTestDataJson,
        );
      } catch (e2) {
        throw Exception('Failed to initialize test database: $e2');
      }
    }

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
      try {
        await _databaseService!.close();
      } catch (e) {
        // Ignore les erreurs de fermeture
      }
      _databaseService = null;
    }

    if (_db != null) {
      try {
        await _db!.close();
      } catch (e) {
        // Ignore les erreurs de fermeture
      }
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
    Map<String, String>? translations,
  }) {
    final ministerioNames = translations ??
        {
          'es': ministerioName,
          'fr': ministerioName,
          'en': ministerioName,
        };

    final List<Map<String, dynamic>> conceptos = [];

    for (int i = 1; i <= conceptCount; i++) {
      conceptos.add({
        'id': 'T-$ministerioId-${i.toString().padLeft(3, '0')}',
        'nombre': {
          'es': 'Concepto $i de $ministerioName',
          'fr': 'Concept $i de ${ministerioNames['fr']}',
          'en': 'Concept $i of ${ministerioNames['en']}',
        },
        'tasa_expedicion': '${1000 * i}',
        'tasa_renovacion': '${500 * i}',
        'documentos_requeridos': {
          'es': 'Documento ${i}a\\nDocumento ${i}b',
          'fr': 'Document ${i}a\\nDocument ${i}b',
          'en': 'Document ${i}a\\nDocument ${i}b',
        },
        'procedimiento': {
          'es': 'Paso 1: Proceso $i\\nPaso 2: Finalizar',
          'fr': 'Étape 1: Processus $i\\nÉtape 2: Finaliser',
          'en': 'Step 1: Process $i\\nStep 2: Finalize',
        },
        'palabras_clave': {
          'es': 'concepto$i, test, $ministerioName',
          'fr': 'concept$i, test, ${ministerioNames['fr']}',
          'en': 'concept$i, test, ${ministerioNames['en']}',
        }
      });
    }

    final ministerioData = [
      {
        'id': ministerioId,
        'nombre': ministerioNames,
        'sectores': [
          {
            'id': 'S-$ministerioId-001',
            'nombre': ministerioNames,
            'categorias': [
              {
                'id': 'C-$ministerioId-001',
                'nombre': ministerioNames,
                'sub_categorias': [
                  {
                    'id': 'SC-$ministerioId-001',
                    'nombre': ministerioNames,
                    'conceptos': conceptos,
                  }
                ]
              }
            ]
          }
        ]
      }
    ];

    return jsonEncode(ministerioData);
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

  /// Vérifie la santé de la base de données de test
  static Future<bool> isHealthy() async {
    try {
      if (_databaseService == null) return false;

      final count = await _databaseService!.ministerioDao.count();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Réinitialise la base de données avec des données fraîches
  static Future<void> resetDatabase() async {
    if (_databaseService != null) {
      await _databaseService!.clearAllData();
      await _databaseService!.initialize(
        forceReset: true,
        seedData: true,
        testJsonString: defaultTestDataJson,
      );
    }
  }
}
