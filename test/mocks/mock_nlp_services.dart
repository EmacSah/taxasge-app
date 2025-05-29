import 'package:mockito/mockito.dart';
import 'package:taxasge/ml/model_service.dart';
import 'package:taxasge/ml/query_processor.dart';
import 'package:taxasge/ml/response_generator.dart';

// Générer les mocks avec build_runner (`flutter pub run build_runner build`)
// ou définir des classes mock manuellement si build_runner n'est pas utilisé dans ce contexte.
// Pour ce subtask, je vais définir des classes mock manuelles simples.

class MockModelService extends Mock implements ModelService {
  // Comportement par défaut ou spécifique pour les tests
  @override
  Future<void> initialize() async {
    // Simuler l'initialisation
    return;
  }
  // Ajouter d'autres méthodes si nécessaire pour les tests de ChatbotService
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
       return {'intent': 'consulta_precio', 'concepts': [{'id': 'T-001', 'nombre': 'Impuesto Alpha'}], 'original_query': message};
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

// Pour exécuter les tests qui utilisent ces mocks, il faudra peut-être
// configurer un peu plus les comportements dans les tests eux-mêmes avec when(...).thenReturn(...)
// ou s'assurer que les comportements par défaut ici sont suffisants.
