import 'dart:async';
import 'dart:math';
//import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../services/localization_service.dart';
import 'model_service.dart';

/// Classe qui gère la génération des réponses du chatbot.
///
/// Cette classe utilise le modèle NLP pour générer des réponses contextuelles
/// et cohérentes aux requêtes des utilisateurs.
class ResponseGenerator {
  // Services
  final ModelService _modelService;
  final DatabaseService _dbService;
  final LocalizationService _localizationService;

  // Templates de réponses pour différents cas
  final Map<String, Map<String, List<String>>> _responseTemplates = {
    'greeting': {
      'es': [
        'Hola, ¿en qué puedo ayudarte?',
        'Buenos días, ¿qué información sobre tasas fiscales necesitas?',
        'Hola, soy el asistente virtual de TaxasGE. ¿Cómo puedo ayudarte?',
      ],
      'fr': [
        'Bonjour, comment puis-je vous aider ?',
        'Bonjour, quelle information sur les taxes fiscales vous faut-il ?',
        'Bonjour, je suis l\'assistant virtuel de TaxasGE. Comment puis-je vous aider ?',
      ],
      'en': [
        'Hello, how can I help you?',
        'Good day, what information about fiscal taxes do you need?',
        'Hi, I\'m the TaxasGE virtual assistant. How can I help you?',
      ],
    },
    'thanks': {
      'es': [
        'De nada, estoy aquí para ayudar.',
        'Un placer. ¿Necesitas algo más?',
        'No hay problema. ¿Puedo ayudarte con algo más?',
      ],
      'fr': [
        'De rien, je suis là pour aider.',
        'Avec plaisir. Avez-vous besoin d\'autre chose ?',
        'Pas de problème. Puis-je vous aider avec autre chose ?',
      ],
      'en': [
        'You\'re welcome, I\'m here to help.',
        'My pleasure. Do you need anything else?',
        'No problem. Can I help you with something else?',
      ],
    },
    'error': {
      'es': [
        'Lo siento, no pude entender tu pregunta. ¿Podrías reformularla?',
        'Disculpa, no tengo información sobre eso. ¿Podrías ser más específico?',
      ],
      'fr': [
        'Désolé, je n\'ai pas compris votre question. Pourriez-vous la reformuler ?',
        'Pardon, je n\'ai pas d\'information à ce sujet. Pourriez-vous être plus précis ?',
      ],
      'en': [
        'Sorry, I couldn\'t understand your question. Could you rephrase it?',
        'I apologize, I don\'t have information about that. Could you be more specific?',
      ],
    },
  };

  // Templates de réponses contextuelles
  final Map<String, Map<String, String>> _contextualTemplates = {
    'prix': {
      'es':
          'El costo de {concepto} es {tasa_expedicion} para expedición y {tasa_renovacion} para renovación.',
      'fr':
          'Le coût de {concepto} est de {tasa_expedicion} pour l\'émission et {tasa_renovacion} pour le renouvellement.',
      'en':
          'The cost of {concepto} is {tasa_expedicion} for issuance and {tasa_renovacion} for renewal.',
    },
    'documents': {
      'es': 'Los documentos requeridos para {concepto} son: {documentos}',
      'fr': 'Les documents requis pour {concepto} sont : {documentos}',
      'en': 'The required documents for {concepto} are: {documentos}',
    },
    'procedure': {
      'es': 'El procedimiento para {concepto} es: {procedimiento}',
      'fr': 'La procédure pour {concepto} est : {procedimiento}',
      'en': 'The procedure for {concepto} is: {procedimiento}',
    },
    'info': {
      'es': '{concepto} es un trámite del Ministerio de {ministerio}.',
      'fr': '{concepto} est une démarche du Ministère de {ministerio}.',
      'en': '{concepto} is a procedure of the Ministry of {ministerio}.',
    },
  };

  // Générateur de nombres aléatoires
  final Random _random = Random();

  // Constructeur
  ResponseGenerator({
    ModelService? modelService,
    DatabaseService? dbService,
    LocalizationService? localizationService,
  })  : _modelService = modelService ?? ModelService.instance,
        _dbService = dbService ?? DatabaseService(),
        _localizationService =
            localizationService ?? LocalizationService.instance;

  /// Génère une réponse appropriée à une requête analysée
  Future<String> generateResponse(Map<String, dynamic> processedQuery) async {
    final queryType = processedQuery['type'];
    final currentLang = _localizationService.currentLanguage;

    // Traiter les cas spéciaux (salutations, remerciements)
    if (queryType == 'greeting' || queryType == 'thanks') {
      return _getRandomTemplate(queryType, currentLang);
    }

    // Pour une requête standard
    if (queryType == 'query') {
      final intent = processedQuery['intent'];
      final concepts = processedQuery['concepts'] as List<Map<String, dynamic>>;
      final encodedState = processedQuery['encoded_state'] as List<double>;

      // Si des concepts ont été identifiés, générer une réponse contextuelle
      if (concepts.isNotEmpty) {
        return await _generateContextualResponse(
          intent,
          concepts.first,
          encodedState,
          currentLang,
        );
      }

      // Sinon, utiliser le modèle NLP pour générer une réponse
      final response = await _modelService.generateResponse(encodedState);

      // Si la réponse générée est vide ou inappropriée, utiliser une réponse d'erreur
      if (response.isEmpty || response.length < 10) {
        return _getRandomTemplate('error', currentLang);
      }

      return response;
    }

    // Cas par défaut
    return _getRandomTemplate('error', currentLang);
  }

  /// Retourne un template aléatoire pour un type donné
  String _getRandomTemplate(String type, String language) {
    final templates = _responseTemplates[type]?[language] ??
        _responseTemplates[type]?['es'] ??
        _responseTemplates['error']!['es']!;

    return templates[_random.nextInt(templates.length)];
  }

  /// Génère une réponse contextuelle basée sur l'intention et le concept
  Future<String> _generateContextualResponse(
    String intent,
    Map<String, dynamic> concept,
    List<double> encodedState,
    String language,
  ) async {
    // Récupérer les détails complets du concept si nécessaire
    final conceptDetails = await _dbService.getConceptoWithDetails(
      concept['id'],
      langCode: language,
    );

    if (conceptDetails == null) {
      return _getRandomTemplate('error', language);
    }

    // Obtenir le template pour l'intention
    final template = _contextualTemplates[intent]?[language] ??
        _contextualTemplates[intent]?['es'] ??
        _contextualTemplates['info']!['es']!;

    // Remplacer les placeholders
    var response = template
        .replaceAll('{concepto}',
            conceptDetails['nombre_current'] ?? conceptDetails['nombre'])
        .replaceAll('{ministerio}',
            conceptDetails['ministerio']['nombre_current'] ?? '')
        .replaceAll(
            '{tasa_expedicion}', conceptDetails['tasa_expedicion'] ?? 'N/A')
        .replaceAll(
            '{tasa_renovacion}', conceptDetails['tasa_renovacion'] ?? 'N/A');

    // Traiter les documents et procédures
    if (intent == 'documents' && conceptDetails['documentos'] != null) {
      final docs = conceptDetails['documentos']
          .map((doc) => doc['nombre_current'] ?? doc['nombre'])
          .join(', ');
      response = response.replaceAll('{documentos}', docs);
    }

    if (intent == 'procedure' && conceptDetails['procedimientos'] != null) {
      final proc = conceptDetails['procedimientos']
          .map((p) => p['description_current'] ?? p['description'])
          .join(' ');
      response = response.replaceAll('{procedimiento}', proc);
    }

    // Si des informations sont manquantes, générer une réponse avec le modèle
    if (response.contains('{') && response.contains('}')) {
      final generatedResponse =
          await _modelService.generateResponse(encodedState);
      if (generatedResponse.isNotEmpty) {
        return generatedResponse;
      }
      return _getRandomTemplate('error', language);
    }

    return response;
  }

  /// Combine plusieurs réponses en une seule réponse cohérente
  String _combineResponses(List<String> responses) {
    if (responses.isEmpty) return '';
    if (responses.length == 1) return responses[0];

    final language = _localizationService.currentLanguage;
    final joinWord = language == 'fr'
        ? ' et '
        : language == 'en'
            ? ' and '
            : ' y ';

    return responses.join('. ').replaceAll('. .', '.');
  }

  /// Ajoute une suggestion de suivi à la réponse si approprié
  String _addFollowUp(String response, String intent, String language) {
    final followUps = {
      'prix': {
        'es': '¿Necesitas información sobre los documentos requeridos?',
        'fr': 'Avez-vous besoin d\'informations sur les documents requis ?',
        'en': 'Do you need information about the required documents?',
      },
      'documents': {
        'es': '¿Quieres conocer el procedimiento a seguir?',
        'fr': 'Voulez-vous connaître la procédure à suivre ?',
        'en': 'Would you like to know the procedure to follow?',
      },
      'procedure': {
        'es': '¿Necesitas saber el costo?',
        'fr': 'Avez-vous besoin de connaître le coût ?',
        'en': 'Do you need to know the cost?',
      },
    };

    final followUp = followUps[intent]?[language] ?? followUps[intent]?['es'];

    if (followUp != null) {
      return '$response\n\n$followUp';
    }

    return response;
  }
}
