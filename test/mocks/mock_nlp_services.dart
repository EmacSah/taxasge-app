// test/mocks/mock_nlp_services.dart
import 'package:mockito/mockito.dart';
import 'package:taxasge/ml/model_service.dart';
import 'package:taxasge/ml/query_processor.dart';
import 'package:taxasge/ml/response_generator.dart';
// Import Uint8List

// Generate mocks with build_runner (`flutter pub run build_runner build`)
// or define mock classes manually if build_runner is not used in this context.
// For this subtask, I will define simple manual mock classes.

class MockModelService extends Mock implements ModelService {
  // Mock initialize to do nothing
  @override
  Future<void> initialize() async {
    return;
  }

  // Mock encodeText
  @override
  List<int> encodeText(String text, bool isQuestion) {
    // Return dummy encoded data based on input or a fixed sequence
    // You can add more sophisticated logic here if needed for your tests
    return [1, 2, 3, 4]; // Example dummy data
  }

  // Mock decodeSequence
  @override
  String decodeSequence(List<int> sequence) {
    // Return a dummy decoded string
    return "mocked response"; // Example dummy response
  }

  // Mock encodeQuestion
  @override
  Future<List<double>> encodeQuestion(String question) async {
    // Return dummy encoder state
    return Future.value([0.1, 0.2, 0.3]); // Example dummy data
  }

  // Mock generateResponse
  @override
  Future<String> generateResponse(List<double> encoderState) async {
    // Return a dummy generated response string
    return Future.value("This is a mocked response."); // Example dummy response
  }

  // Mock dispose
  @override
  Future<void> dispose() async {
    // Do nothing for dispose
    return;
  }

  // You might need to mock other methods if they are called
  // by the code you are testing.
}

class MockQueryProcessor extends Mock implements QueryProcessor {
  @override
  Future<Map<String, dynamic>> processQuery(String message) async {
    if (message.toLowerCase().contains("hola")) {
      return {'intent': 'saludo', 'concepts': [], 'original_query': message};
    }
    if (message.toLowerCase().contains("adios")) {
      return {'intent': 'despedida', 'concepts': [], 'original_query': message};
    }
    if (message.toLowerCase().contains("precio de impuesto alpha")) {
      return {
        'intent': 'consulta_precio',
        'concepts': [
          {'id': 'T-001', 'nombre': 'Impuesto Alpha'}
        ],
        'original_query': message
      };
    }
    return {'intent': 'desconocido', 'concepts': [], 'original_query': message};
  }
}

class MockResponseGenerator extends Mock implements ResponseGenerator {
  @override
  Future<String> generateResponse(Map<String, dynamic> processedQuery) async {
    final intent = processedQuery['intent'];
    if (intent == 'saludo') {
      return Future.value("Hola! ¿Cómo puedo ayudarte?");
    }
    if (intent == 'despedida') {
      return Future.value("Adiós! Que tengas un buen día.");
    }
    if (intent == 'consulta_precio') {
      final concept = processedQuery['concepts'][0]['nombre'];
      return Future.value("El precio de $concept es X.");
    }
    return Future.value("No he entendido tu pregunta.");
  }
}

// To run tests that use these mocks, you may need to
// configure more behaviors in the tests themselves with when(...).thenReturn(...)
// or ensure the default behaviors here are sufficient.

// Global instances for easy access in tests
final mockModelService = MockModelService();
