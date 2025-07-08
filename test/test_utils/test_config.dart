import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show debugPrint;
// Import this

/// Configuration centralisée pour les tests (unitaires et d'intégration).
///
/// Gère l'initialisation de Flutter, le mock des assets et la base de données de test.
class TestConfig {
  static DatabaseService? _databaseService;
  static bool _isInitialized = false;

  /// Initialise Flutter, sqflite-ffi et le mock des assets.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    TestWidgetsFlutterBinding.ensureInitialized();

    // Configuration sqflite pour desktop (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final testDir = Directory.current.path; // This is usually the project root
    const MethodChannel assetChannel = MethodChannel('flutter/assets');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(assetChannel, (MethodCall call) async {
      final assetPath = call.arguments as String;
      const mockTokenizerJsonString = '''
      {
        "config": {
          "word_index": {
            "<OOV>": 1, "cuanto": 2, "cuesta": 3, "pasaporte": 4,
            "precio": 5, "documentos": 6, "what": 7, "is": 8, "the": 9,
            "cost": 10, "of": 11, "needed": 13, "for": 14,
            "quel": 15, "est": 16, "le": 17, "prix": 18, "des": 19,
            "papiers": 20, "pour": 21
          }
        }
      }
      ''';

      // Mock tokenizer JSON files (intercepting both 'load' and 'loadString')
      if ((call.method == 'load' || call.method == 'loadString') && (assetPath == 'assets/ml/taxasge_model_question_tokenizer.json' || assetPath == 'assets/ml/taxasge_model_answer_tokenizer.json')) {
           // Create Uint8List directly from UTF-8 encoded string
           final byteData = Uint8List.fromList(utf8.encode(mockTokenizerJsonString)).buffer.asByteData();
           return byteData; // Return ByteData directly
      }

      // If the app requests the main taxes.json for seeding the database, serve the test version.
      if (call.method == 'loadString' && assetPath == 'assets/data/taxes.json') {
        final testTaxesPath = '$testDir/test/test_assets/test_taxes.json';
        try {
          final file = File(testTaxesPath);
          if (await file.exists()) {
            final fileContent = await file.readAsString();
            return fileContent; // Return the string content directly
          } else {
            debugPrint('Mock Asset Handler: Test taxes file not found at $testTaxesPath');
            throw PlatformException(
              code: 'AssetNotFound',
              message: 'Asset not found: $testTaxesPath (mock for $assetPath)',
            );
          }
        } catch (e) {
          debugPrint('Error reading mock asset $testTaxesPath: $e');
          throw PlatformException(
            code: 'AssetLoadError',
            message: 'Error loading asset $testTaxesPath: $e',
          );
        }
      }

      // Handle load for TFLite binary files
      if (call.method == 'load' && assetPath.endsWith('.tflite')) {
        // Return a minimal non-empty ByteData directly.
        return ByteData(16); // Using 16 bytes as a small, non-zero placeholder.
      }

      // Default case for any other 'load' calls to avoid null returns leading to errors
      if (call.method == 'load') {
         // Default for 'load': return empty ByteData directly.
        return ByteData(0);
      }

      // Fallback for unhandled methods or asset paths.
      if (call.method == 'loadString') {
        debugPrint('Mock Asset Handler: Unhandled loadString - Asset: $assetPath');
         throw PlatformException(
           code: 'AssetNotFound',
           message: 'Asset not found or not mocked for loadString: $assetPath',
         );
      }

      debugPrint('Mock Asset Handler: Unhandled call - Method: ${call.method}, Asset: $assetPath');
      throw PlatformException(
        code: 'MockHandlerError',
        message: 'Unhandled method call in mock asset handler: ${call.method} for asset $assetPath',
      );
    });

    _isInitialized = true;
  }

  /// Initialise une base de données fraîche à partir de `test_taxes.json`.
  ///
  /// [forceReset] : supprime les données précédentes si `true`.
  static Future<DatabaseService> initializeDatabase(
      {bool forceReset = true}) async {
    await initialize(); // Ensures mock asset handler is set up

    // Fermer l'instance existente si nécessaire
    if (_databaseService != null) {
      await _databaseService!.close();
      _databaseService = null;
    }

    // Créer et initialiser le service
    final svc = DatabaseService();
    // When seedData is true, DatabaseService.initialize will try to load 'assets/data/taxes.json'
    // Our mock handler will intercept this and provide 'test/test_assets/test_taxes.json'
    await svc.initialize(forceReset: forceReset, seedData: true);
    _databaseService = svc;
    return svc;
  }
}
