import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/localization_service.dart';
import '../database/schema.dart'; // Ajout de l'import pour DatabaseSchema

/// Extensions pour simplifier l'accès au thème et aux fonctionnalités multilingues dans l'application TaxasGE
extension ThemeExtension on BuildContext {
  /// Accès au thème actuel
  ThemeData get theme => Theme.of(this);

  /// Accès au schéma de couleurs
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Accès au thème de texte
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Couleur primaire
  Color get primaryColor => Theme.of(this).primaryColor;

  /// Couleur secondaire
  Color get secondaryColor => colorScheme.secondary;

  /// Couleur d'accentuation
  Color get accentColor => AppTheme.accentColor;

  /// Couleur d'erreur
  Color get errorColor => colorScheme.error;

  /// Couleur de fond claire
  Color get backgroundLight => AppTheme.backgroundLight;

  /// Couleur de fond blanche
  Color get backgroundWhite => AppTheme.backgroundWhite;

  /// Couleur de texte foncée
  Color get textDark => AppTheme.textDark;

  /// Couleur de texte moyenne
  Color get textMedium => AppTheme.textMedium;

  /// Couleur de texte claire
  Color get textLight => AppTheme.textLight;

  /// Couleur de séparateur
  Color get dividerColor => AppTheme.dividerColor;

  /// Style de texte monospace
  TextStyle get monoTextStyle => AppTheme.monoTextStyle;

  /// Style de texte monospace en gras
  TextStyle get monoTextStyleBold => AppTheme.monoTextStyleBold;

  /// Service de localisation
  LocalizationService get localizationService => LocalizationService.instance;

  /// Code de langue actuellement actif
  String get currentLanguage => localizationService.currentLanguage;

  /// Code de langue de secours
  String get fallbackLanguage => localizationService.fallbackLanguage;

  /// Direction du texte basée sur la langue actuelle (LTR ou RTL)
  TextDirection get textDirection => localizationService.textDirection;

  /// Vérifie si la langue actuelle est RTL (droite à gauche)
  bool get isRtl => localizationService.isRtl(currentLanguage);

  /// Obtient la traduction d'un texte à partir d'une map de traductions
  String getTranslation(Map<String, String>? translations) =>
      localizationService.getTranslation(translations);

  /// Formate une date selon la locale actuelle
  String formatDate(DateTime date, {String? format}) =>
      localizationService.formatDate(date, format: format);

  /// Obtient le nom localisé d'une langue
  String getLanguageName(String languageCode) =>
      localizationService.getLanguageName(languageCode);
}

/// Extensions pour faciliter le mapping des ministères aux couleurs appropriées
extension MinistryColorExtension on String {
  /// Obtient la couleur associée à un ministère
  Color getMinistryColor() {
    return AppTheme.getMinistryColor(this);
  }

  /// Obtient une version plus claire de la couleur du ministère
  Color getLightMinistryColor([double opacity = 0.15]) {
    final baseColor = AppTheme.getMinistryColor(this);
    final alpha = (opacity.clamp(0.0, 1.0) * 255).toDouble();
    return baseColor.withValues(alpha: alpha);
  }

  /// Obtient une couleur de texte appropriée (blanc ou noir) selon la couleur du ministère
  Color getMinistryTextColor() {
    final color = AppTheme.getMinistryColor(this);
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? AppTheme.textDark : Colors.white;
  }
}

/// Extensions pour faciliter la gestion des textes multilingues
extension MultilingualStringExtension on String {
  /// Tronque le texte à une longueur maximale et ajoute des points de suspension si nécessaire
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return "${substring(0, maxLength)}...";
  }

  /// Capitalise la première lettre de chaque mot
  String capitalize() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Adapte automatiquement le texte pour les écrans RTL en ajoutant des marqueurs Unicode
  //String adaptToRtl(bool isRtl) {
  //  if (!isRtl) return this;
  // Ajouter des marqueurs RLM (Right-to-Left Mark) autour des nombres et des caractères latins
  //  return replaceAllMapped(RegExp(r'[0-9a-zA-Z]+'), (match) {
  //    return '\u200F${match.group(0)}\u200F';
  //  });
  //}

  /// Vérifie si la chaîne contient des caractères RTL
  //bool get containsRtlCharacters {
  // Gammes Unicode pour les langues RTL principales (arabe, hébreu, etc.)
  //  final rtlRanges = [
  //    RegExp(r'[\u0600-\u06FF]'), // Arabe
  //    RegExp(r'[\u0750-\u077F]'), // Arabe supplément
  //    RegExp(r'[\u08A0-\u08FF]'), // Arabe étendu-A
  //    RegExp(r'[\uFB50-\uFDFF]'), // Arabe présenté-A
  //    RegExp(r'[\uFE70-\uFEFF]'), // Arabe présenté-B
  //    RegExp(r'[\u0590-\u05FF]'), // Hébreu
  //    RegExp(r'[\u07C0-\u07FF]'), // NKo
  //    RegExp(r'[\u0780-\u07BF]'), // Thaana
  //  ];

  //  for (final range in rtlRanges) {

  //if (range.hasMatch(this)) return true;
  //}

  //return false;
  //}
}

/// Extensions pour faciliter la gestion des maps de traductions
extension TranslationMapExtension on Map<String, String>? {
  /// Obtient la traduction pour une langue spécifiée
  String getTranslation(String langCode, {String? fallbackLang}) {
    if (this == null || this!.isEmpty) return '';

    // Essayer la langue demandée
    if (hasTranslation(langCode)) return this![langCode]!;

    // Essayer la langue de secours si spécifiée
    if (fallbackLang != null && hasTranslation(fallbackLang)) {
      return this![fallbackLang]!;
    }

    // Essayer la langue par défaut
    final defaultLang = DatabaseSchema.defaultLanguage;
    if (hasTranslation(defaultLang)) return this![defaultLang]!;

    // Prendre la première traduction disponible
    return this!
        .entries
        .firstWhere((e) => e.value.isNotEmpty, orElse: () => MapEntry('', ''))
        .value;
  }

  /// Vérifie si la map contient une traduction pour la langue spécifiée
  bool hasTranslation(String langCode) {
    if (this == null) return false;
    return this!.containsKey(langCode) && this![langCode]!.isNotEmpty;
  }

  /// Obtient le nombre de traductions disponibles
  int get translationCount {
    if (this == null) return 0;
    return this!.entries.where((e) => e.value.isNotEmpty).length;
  }

  /// Vérifie si la map a au moins une traduction
  bool get hasAnyTranslation => translationCount > 0;
}
