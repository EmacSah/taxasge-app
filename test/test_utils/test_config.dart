import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxasge/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

    // Get the current test file directory
    final testDir = Directory.current.path;

    // Mock global for rootBundle
    const assetChannel = MethodChannel('flutter/assets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(assetChannel, (MethodCall call) async {
      final assetPath = call.arguments as String;

      // Mock tokenizer JSON files (intercepting both 'load' and 'loadString')
      if ((call.method == 'load' || call.method == 'loadString') && (assetPath == 'assets/ml/taxasge_model_question_tokenizer.json' || assetPath == 'assets/ml/taxasge_model_answer_tokenizer.json')) {
           const mockTokenizer = '''
              {
                "config": {
                  "word_index": {
                    "<OOV>": 1,
                    "cuanto": 2,
                    "cuesta": 3,
                    "pasaporte": 4,
                    "precio": 5,
                    "documentos": 6
                  }
                }
              }
              ''';
           // Wrap the ByteData in a list or map that StandardMessageCodec might expect
           return [Uint8List.fromList(utf8.encode(mockTokenizer)).buffer.asByteData()]; // Returning as a list containing ByteData
      }
      
      // Handle other loadString calls (like test_taxes.json)
      if (call.method == 'loadString' && assetPath.endsWith('.json')) {
         final file = File('$testDir/test/test_assets/test_taxes.json');
         return await file.readAsString();
      }


      // Handle load for TFLite binary files
      if (call.method == 'load' && assetPath.endsWith('.tflite')) {
        return ByteData(1024);
      }

      // Default case for any other load calls
      if (call.method == 'load') {
        return ByteData(0);
      }

      return null;
    });

    _isInitialized = true;
  }

  /// Initialise une base de données fraîche à partir de `test_taxes.json`.
  ///
  /// [forceReset] : supprime les données précédentes si `true`.
  static Future<DatabaseService> initializeDatabase(
      {bool forceReset = true}) async {
    await initialize();

    // Fermer l'instance existente si nécessaire
    if (_databaseService != null) {
      await _databaseService!.close();
      _databaseService = null;
    }

    // Créer et initialiser le service
    final svc = DatabaseService();
    await svc.initialize(forceReset: forceReset, seedData: true);
    _databaseService = svc;
    return svc;
  }
}
