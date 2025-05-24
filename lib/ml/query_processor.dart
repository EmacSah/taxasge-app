import 'dart:async';
//import 'package:flutter/foundation.dart';
import '../database/database_service.dart';
import '../services/localization_service.dart';
import 'model_service.dart';

/// Classe qui gère le traitement des requêtes utilisateur pour le chatbot.
///
/// Cette classe analyse les requêtes textuelles, identifie leur intention
/// et les prépare pour le modèle NLP.
class QueryProcessor {
  // Services
  final ModelService _modelService;
  final DatabaseService _dbService;
  final LocalizationService _localizationService;

  // Cache des concepts fréquemment demandés
  final Map<String, Map<String, dynamic>> _conceptCache = {};

  // Compteurs de fréquence des requêtes
  final Map<String, int> _queryFrequency = {};

  // Constructeur
  QueryProcessor({
    ModelService? modelService,
    DatabaseService? dbService,
    LocalizationService? localizationService,
  })  : _modelService = modelService ?? ModelService.instance,
        _dbService = dbService ?? DatabaseService(),
        _localizationService =
            localizationService ?? LocalizationService.instance;

  /// Traite une requête utilisateur
  ///
  /// Retourne un objet contenant l'intention détectée et les paramètres extraits
  Future<Map<String, dynamic>> processQuery(String query) async {
    // S'assurer que le modèle est initialisé
    if (!_modelService.isInitialized) {
      await _modelService.initialize();
    }

    // Normaliser la requête
    final normalizedQuery = _normalizeQuery(query);

    // Mettre à jour les statistiques
    _updateQueryStats(normalizedQuery);

    // Détecter si c'est une salutation ou un remerciement
    if (_isGreeting(normalizedQuery)) {
      return {
        'type': 'greeting',
        'query': normalizedQuery,
      };
    }
    if (_isThanks(normalizedQuery)) {
      return {
        'type': 'thanks',
        'query': normalizedQuery,
      };
    }

    // Encoder la requête avec le modèle
    final encodedState = await _modelService.encodeQuestion(normalizedQuery);

    // Identifier les concepts mentionnés
    final mentionedConcepts = await _identifyConcepts(normalizedQuery);

    // Détecter l'intention principale
    final intent = await _detectIntent(normalizedQuery, encodedState);

    // Construire le résultat
    return {
      'type': 'query',
      'raw_query': query,
      'normalized_query': normalizedQuery,
      'intent': intent,
      'concepts': mentionedConcepts,
      'encoded_state': encodedState,
      'language': _localizationService.currentLanguage,
    };
  }

  /// Normalise une requête utilisateur
  String _normalizeQuery(String query) {
    // Convertir en minuscules
    var normalized = query.toLowerCase();

    // Supprimer la ponctuation inutile
    normalized = normalized.replaceAll(RegExp(r'[^\w\s\?\.\,\!\:]'), '');

    // Remplacer les espaces multiples
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Supprimer les espaces au début et à la fin
    normalized = normalized.trim();

    return normalized;
  }

  /// Met à jour les statistiques des requêtes
  void _updateQueryStats(String query) {
    _queryFrequency[query] = (_queryFrequency[query] ?? 0) + 1;

    // Nettoyer le cache des anciennes requêtes si nécessaire
    if (_queryFrequency.length > 1000) {
      final sortedQueries = _queryFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _queryFrequency.clear();
      for (var i = 0; i < 500; i++) {
        _queryFrequency[sortedQueries[i].key] = sortedQueries[i].value;
      }
    }
  }

  /// Vérifie si la requête est une salutation
  bool _isGreeting(String query) {
    final greetings = {
      'es': [
        'hola',
        'buenos dias',
        'buenas tardes',
        'buenas noches',
        'saludos'
      ],
      'fr': ['bonjour', 'salut', 'bonsoir', 'coucou'],
      'en': ['hello', 'hi', 'good morning', 'good afternoon', 'good evening'],
    };

    final currentLang = _localizationService.currentLanguage;
    final langGreetings = greetings[currentLang] ?? greetings['es']!;

    return langGreetings.any((greeting) => query.contains(greeting));
  }

  /// Vérifie si la requête est un remerciement
  bool _isThanks(String query) {
    final thanks = {
      'es': ['gracias', 'muchas gracias', 'te agradezco', 'gracias por'],
      'fr': ['merci', 'je vous remercie', 'merci beaucoup'],
      'en': ['thank', 'thanks', 'thank you'],
    };

    final currentLang = _localizationService.currentLanguage;
    final langThanks = thanks[currentLang] ?? thanks['es']!;

    return langThanks.any((thank) => query.contains(thank));
  }

  /// Identifie les concepts mentionnés dans la requête
  Future<List<Map<String, dynamic>>> _identifyConcepts(String query) async {
    // Chercher d'abord dans le cache
    final cacheKey = '${_localizationService.currentLanguage}_$query';
    if (_conceptCache.containsKey(cacheKey)) {
      return [_conceptCache[cacheKey]!];
    }

    // Rechercher des concepts correspondants dans la base de données
    final results = await _dbService.searchConceptos(
      searchTerm: query,
      langCode: _localizationService.currentLanguage,
    );

    // Mettre en cache le meilleur résultat si pertinent
    if (results.isNotEmpty) {
      _conceptCache[cacheKey] = results.first;

      // Nettoyer le cache si nécessaire
      if (_conceptCache.length > 100) {
        _conceptCache.remove(_conceptCache.keys.first);
      }
    }

    return results;
  }

  /// Détecte l'intention principale de la requête
  Future<String> _detectIntent(String query, List<double> encodedState) async {
    // Liste des intentions possibles avec leurs mots-clés associés
    final intents = {
      'prix': {
        'es': ['cuesta', 'precio', 'valor', 'tasa', 'pagar', 'costo'],
        'fr': ['coûte', 'prix', 'valeur', 'taux', 'payer', 'coût'],
        'en': ['cost', 'price', 'fee', 'rate', 'pay', 'charge'],
      },
      'documents': {
        'es': ['documentos', 'papeles', 'requisitos', 'necesito'],
        'fr': ['documents', 'papiers', 'requis', 'nécessaire'],
        'en': ['documents', 'papers', 'requirements', 'need'],
      },
      'procedure': {
        'es': ['procedimiento', 'proceso', 'trámite', 'cómo', 'obtener'],
        'fr': ['procédure', 'processus', 'démarche', 'comment', 'obtenir'],
        'en': ['procedure', 'process', 'steps', 'how', 'obtain'],
      },
      'info': {
        'es': ['información', 'detalles', 'explicar', 'qué es'],
        'fr': ['information', 'détails', 'expliquer', 'qu\'est-ce'],
        'en': ['information', 'details', 'explain', 'what is'],
      },
    };

    // Langue courante
    final currentLang = _localizationService.currentLanguage;

    // Compter les occurrences de mots-clés pour chaque intention
    Map<String, int> scores = {};

    for (var entry in intents.entries) {
      final intentKeywords = entry.value[currentLang] ?? entry.value['es']!;
      int score = 0;

      for (var keyword in intentKeywords) {
        if (query.contains(keyword)) {
          score += 1;
        }
      }

      scores[entry.key] = score;
    }

    // Retourner l'intention avec le score le plus élevé
    // ou 'info' par défaut si aucun mot-clé n'est trouvé
    return scores.entries.isEmpty
        ? 'info'
        : scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Nettoie les ressources du processeur
  void dispose() {
    _conceptCache.clear();
    _queryFrequency.clear();
  }
}
