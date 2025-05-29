import 'dart:io';
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

    // Mock global pour rootBundle : JSON et modèles TFLite
    const assetChannel = MethodChannel('flutter/assets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(assetChannel, (MethodCall call) async {
      final asset = call.arguments as String;

      // Tout JSON (*.json) renvoie le fichier de test unique
      if (call.method == 'loadString' && asset.endsWith('.json')) {
        final file = File('test/test_assets/test_taxes.json');
        return await file.readAsString();
      }

      // Tout binaire (*.tflite) renvoie un ByteData vide
      if (call.method == 'load' && asset.endsWith('.tflite')) {
        return ByteData(0);
      }

      return null;
    });

    _isInitialized = true;
  }

  /// Initialise une base de données fraîche à partir de `test_taxes.json`.
  ///
  /// [forceReset] : supprime les données précédentes si `true`.
  static Future<DatabaseService> initializeDatabase({bool forceReset = true}) async {
    await initialize();

    // Fermer l'instance existante si nécessaire
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
