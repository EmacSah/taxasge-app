import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/localization_service.dart';
import '../ml/model_service.dart';
import '../ml/query_processor.dart';
import '../ml/response_generator.dart';

/// Service qui gère la logique du chatbot et maintient l'état de la conversation.
class ChatbotService extends ChangeNotifier {
  // Singleton
  static final ChatbotService _instance = ChatbotService._internal();
  static ChatbotService get instance => _instance;

  // Services du modèle NLP
  final ModelService _modelService = ModelService.instance;
  final QueryProcessor _queryProcessor = QueryProcessor();
  final ResponseGenerator _responseGenerator = ResponseGenerator();

  // Service de localisation
  final LocalizationService _localizationService = LocalizationService.instance;

  // État de la conversation
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  String? _lastIntent;
  Map<String, dynamic>? _lastConcept;

  // Constructeur privé
  ChatbotService._internal();

  /// Retourne la liste des messages de la conversation
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Indique si le chatbot est en train de traiter un message
  bool get isProcessing => _isProcessing;

  /// Initialise le service du chatbot
  Future<void> initialize() async {
    try {
      // Initialiser le modèle NLP
      await _modelService.initialize();

      // Ajouter un message de bienvenue
      _addWelcomeMessage();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du chatbot: $e');
      rethrow;
    }
  }

  /// Ajoute un message de bienvenue dans la langue actuelle
  void _addWelcomeMessage() {
    final welcomeMessages = {
      'es':
          '¡Hola! Soy el asistente virtual de TaxasGE. ¿En qué puedo ayudarte?',
      'fr':
          'Bonjour ! Je suis l\'assistant virtuel de TaxasGE. Comment puis-je vous aider ?',
      'en': 'Hi! I\'m the TaxasGE virtual assistant. How can I help you?',
    };

    final currentLang = _localizationService.currentLanguage;
    final welcomeMessage =
        welcomeMessages[currentLang] ?? welcomeMessages['es']!;

    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  /// Envoie un message au chatbot et obtient une réponse
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      _isProcessing = true;
      notifyListeners();

      // Ajouter le message de l'utilisateur
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();

      // Traiter la requête
      final processedQuery = await _queryProcessor.processQuery(message);

      // Sauvegarder le contexte
      _lastIntent = processedQuery['intent'];
      if (processedQuery['concepts'] != null &&
          (processedQuery['concepts'] as List).isNotEmpty) {
        _lastConcept = processedQuery['concepts'][0];
      }

      // Générer la réponse
      final response =
          await _responseGenerator.generateResponse(processedQuery);

      // Ajouter la réponse
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        metadata: {
          'intent': _lastIntent,
          'concept': _lastConcept,
        },
      ));

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du traitement du message: $e');

      // Ajouter un message d'erreur
      final errorMessages = {
        'es': 'Lo siento, ha ocurrido un error. Por favor, inténtalo de nuevo.',
        'fr': 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        'en': 'Sorry, an error occurred. Please try again.',
      };

      final currentLang = _localizationService.currentLanguage;
      final errorMessage = errorMessages[currentLang] ?? errorMessages['es']!;

      _messages.add(ChatMessage(
        text: errorMessage,
        isUser: false,
        timestamp: DateTime.now(),
        metadata: {'error': true},
      ));

      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Retourne une liste de suggestions de questions basées sur le contexte
  List<String> getSuggestions() {
    final currentLang = _localizationService.currentLanguage;

    // Si aucun concept n'a été mentionné, retourner des suggestions générales
    if (_lastConcept == null) {
      final generalSuggestions = {
        'es': [
          '¿Qué trámites existen?',
          '¿Cómo obtener un pasaporte?',
          '¿Cuánto cuesta un visado?',
        ],
        'fr': [
          'Quelles démarches existent ?',
          'Comment obtenir un passeport ?',
          'Combien coûte un visa ?',
        ],
        'en': [
          'What procedures exist?',
          'How to get a passport?',
          'How much does a visa cost?',
        ],
      };

      return generalSuggestions[currentLang] ?? generalSuggestions['es']!;
    }

    // Sinon, générer des suggestions basées sur le dernier concept
    final conceptName =
        _lastConcept!['nombre_current'] ?? _lastConcept!['nombre'];

    final suggestions = {
      'es': [
        '¿Cuánto cuesta $conceptName?',
        '¿Qué documentos necesito para $conceptName?',
        '¿Cuál es el procedimiento para $conceptName?',
      ],
      'fr': [
        'Combien coûte $conceptName ?',
        'Quels documents sont nécessaires pour $conceptName ?',
        'Quelle est la procédure pour $conceptName ?',
      ],
      'en': [
        'How much does $conceptName cost?',
        'What documents do I need for $conceptName?',
        'What is the procedure for $conceptName?',
      ],
    };

    return suggestions[currentLang] ?? suggestions['es']!;
  }

  /// Efface l'historique de la conversation
  void clearHistory() {
    _messages.clear();
    _lastIntent = null;
    _lastConcept = null;
    _addWelcomeMessage();
    notifyListeners();
  }

  /// Met à jour la langue de l'interface
  void updateLanguage(String newLanguage) {
    if (_localizationService.currentLanguage != newLanguage) {
      clearHistory();
    }
  }

  @override
  void dispose() {
    _queryProcessor.dispose();
    super.dispose();
  }
}
