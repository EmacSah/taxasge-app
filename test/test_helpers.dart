import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupTestAssets() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock les assets
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('flutter/assets'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'load') {
        final String key = methodCall.arguments as String;

        // Retourner des données mockées selon le fichier
        if (key.contains('taxes.json')) {
          return Uint8List.fromList('{"taxes":[]}'.codeUnits);
        } else if (key.contains('tokenizer.json')) {
          return Uint8List.fromList('{"vocab":{}}'.codeUnits);
        }

        // Pour les autres assets, retourner une chaîne vide
        return Uint8List.fromList(''.codeUnits);
      }
      return null;
    },
  );
}
