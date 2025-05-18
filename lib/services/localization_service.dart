// lib/services/localization_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../database/schema.dart';
import '../database/database_service.dart';

/// Service qui gère les préférences linguistiques et l'accès aux traductions.
///
/// Ce service est un singleton accessible depuis toute l'application pour
/// obtenir la langue actuelle et formater les données localisées.
class LocalizationService extends ChangeNotifier {
  // Singleton
  static final LocalizationService _instance = LocalizationService._internal();
  static LocalizationService get instance => _instance;

  // Base de données
  final DatabaseService _dbService = DatabaseService();

  // Langue actuellement sélectionnée
  String _currentLanguage = DatabaseSchema.defaultLanguage;

  // Langue de secours si la traduction n'existe pas
  String _fallbackLanguage = DatabaseSchema.defaultLanguage;

  // Flag pour indiquer si le service a été initialisé
  bool _isInitialized = false;

  // Langues supportées
  final List<String> supportedLanguages = DatabaseSchema.supportedLanguages;

  // Constructeur privé
  LocalizationService._internal();

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Obtient la langue actuellement sélectionnée
  String get currentLanguage => _currentLanguage;

  /// Obtient la langue de secours
  String get fallbackLanguage => _fallbackLanguage;

  /// Initialise le service avec les préférences sauvegardées
  Future<void> initialize() async {
    try {
      // Vérifier si la base de données est initialisée
      if (!_dbService.isOpen) {
        await _dbService.initialize();
      }

      // Récupérer les préférences de SharedPreferences (pour une initialisation rapide)
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('preferred_language') ??
          DatabaseSchema.defaultLanguage;
      _fallbackLanguage = prefs.getString('fallback_language') ??
          DatabaseSchema.defaultLanguage;

      // Récupérer les préférences de la base de données (plus complètes)
      try {
        final languagePrefs = await _getLanguagePrefsFromDb();
        if (languagePrefs != null) {
          _currentLanguage =
              languagePrefs['preferred_language'] ?? _currentLanguage;
          _fallbackLanguage =
              languagePrefs['fallback_language'] ?? _fallbackLanguage;
        }
      } catch (e) {
        // Continuer avec les préférences de SharedPreferences en cas d'erreur
        debugPrint(
            'Erreur lors de la récupération des préférences de langue depuis la base de données: $e');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint(
          'Erreur lors de l\'initialisation du service de localisation: $e');
      // Utiliser les valeurs par défaut en cas d'erreur
      _currentLanguage = DatabaseSchema.defaultLanguage;
      _fallbackLanguage = DatabaseSchema.defaultLanguage;
      _isInitialized = true;
    }
  }

  /// Récupère les préférences de langue depuis la base de données
  Future<Map<String, String>?> _getLanguagePrefsFromDb() async {
    // Cette méthode devrait interroger la table language_prefs pour obtenir les préférences
    // Pour simplifier, cette implémentation est laissée vide
    // Dans une implémentation réelle, utilisez un DAO dédié aux préférences linguistiques
    return null;
  }

  /// Sauvegarde les préférences de langue dans la base de données
  Future<void> _saveLanguagePrefsToDb(
      String preferredLanguage, String fallbackLanguage) async {
    // Cette méthode devrait sauvegarder les préférences dans la table language_prefs
    // Pour simplifier, cette implémentation est laissée vide
    // Dans une implémentation réelle, utilisez un DAO dédié aux préférences linguistiques
  }

  /// Définit la langue actuellement sélectionnée
  Future<void> setLanguage(String languageCode) async {
    if (!isInitialized) {
      await initialize();
    }

    if (!supportedLanguages.contains(languageCode)) {
      throw ArgumentError('Langue non supportée: $languageCode');
    }

    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;

      try {
        // Sauvegarder dans SharedPreferences (rapide)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('preferred_language', languageCode);

        // Sauvegarder dans la base de données (persistant)
        await _saveLanguagePrefsToDb(languageCode, _fallbackLanguage);

        // Notifier les écouteurs (widgets, etc.)
        notifyListeners();
      } catch (e) {
        debugPrint(
            'Erreur lors de la sauvegarde des préférences de langue: $e');
        // Continuer malgré l'erreur, la préférence est déjà mise à jour en mémoire
      }
    }
  }

  /// Définit la langue de secours
  Future<void> setFallbackLanguage(String languageCode) async {
    if (!isInitialized) {
      await initialize();
    }

    if (!supportedLanguages.contains(languageCode)) {
      throw ArgumentError('Langue non supportée: $languageCode');
    }

    if (_fallbackLanguage != languageCode) {
      _fallbackLanguage = languageCode;

      try {
        // Sauvegarder dans SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fallback_language', languageCode);

        // Sauvegarder dans la base de données
        await _saveLanguagePrefsToDb(_currentLanguage, languageCode);

        // Pas besoin de notifier les écouteurs pour la langue de secours
        // car elle n'affecte pas directement l'UI
      } catch (e) {
        debugPrint('Erreur lors de la sauvegarde de la langue de secours: $e');
      }
    }
  }

  /// Obtient la traduction à partir d'une Map de traductions
  String getTranslation(Map<String, String>? translations) {
    if (translations == null || translations.isEmpty) {
      return '';
    }

    // Essayer la langue actuelle
    if (translations.containsKey(_currentLanguage) &&
        translations[_currentLanguage]!.isNotEmpty) {
      return translations[_currentLanguage]!;
    }

    // Essayer la langue de secours
    if (translations.containsKey(_fallbackLanguage) &&
        translations[_fallbackLanguage]!.isNotEmpty) {
      return translations[_fallbackLanguage]!;
    }

    // Essayer la langue par défaut
    if (translations.containsKey(DatabaseSchema.defaultLanguage) &&
        translations[DatabaseSchema.defaultLanguage]!.isNotEmpty) {
      return translations[DatabaseSchema.defaultLanguage]!;
    }

    // Prendre la première traduction disponible
    return translations.values.firstWhere(
      (value) => value.isNotEmpty,
      orElse: () => '',
    );
  }

  /// Formate une date selon la locale actuelle
  String formatDate(DateTime date, {String? format}) {
    try {
      if (format != null) {
        final DateFormat formatter = DateFormat(format, _currentLanguage);
        return formatter.format(date);
      }

      // Formats par défaut selon la langue
      switch (_currentLanguage) {
        case 'fr':
          return DateFormat('dd/MM/yyyy', 'fr').format(date);
        case 'en':
          return DateFormat('MM/dd/yyyy', 'en').format(date);
        case 'es':
        default:
          return DateFormat('dd/MM/yyyy', 'es').format(date);
      }
    } catch (e) {
      // Fallback en cas d'erreur
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Localise une chaîne simple
  String localizeText(String text, Map<String, String> translations) {
    return translations[_currentLanguage] ??
        translations[_fallbackLanguage] ??
        translations[DatabaseSchema.defaultLanguage] ??
        text;
  }

  /// Obtient le nom localisé de la langue
  String getLanguageName(String languageCode) {
    final localizedNames = {
      'es': {
        'es': 'Español',
        'fr': 'Espagnol',
        'en': 'Spanish',
      },
      'fr': {
        'es': 'Francés',
        'fr': 'Français',
        'en': 'French',
      },
      'en': {
        'es': 'Inglés',
        'fr': 'Anglais',
        'en': 'English',
      },
    };

    if (localizedNames.containsKey(languageCode)) {
      return localizedNames[languageCode]![_currentLanguage] ??
          localizedNames[languageCode]![DatabaseSchema.defaultLanguage] ??
          languageCode;
    }

    return languageCode;
  }

  /// Détermine si une langue est RTL (Right-to-Left)
  bool isRtl(String languageCode) {
    // Liste des langues RTL
    const List<String> rtlLanguages = ['ar', 'fa', 'he', 'ur'];
    return rtlLanguages.contains(languageCode);
  }

  /// Obtient la direction du texte pour la langue actuelle
  TextDirection get textDirection =>
      isRtl(_currentLanguage) ? TextDirection.rtl : TextDirection.ltr;

  /// Réinitialise les préférences de langue
  Future<void> resetToDefaults() async {
    await setLanguage(DatabaseSchema.defaultLanguage);
    await setFallbackLanguage(DatabaseSchema.defaultLanguage);
  }
}
