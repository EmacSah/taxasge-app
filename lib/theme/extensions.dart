import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extensions pour simplifier l'accès au thème dans l'application TaxasGE
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
}

/// Extensions pour faciliter le mapping des ministères aux couleurs appropriées
extension MinistryColorExtension on String {
  /// Obtient la couleur associée à un ministère
  Color getMinistryColor() {
    return AppTheme.getMinistryColor(this);
  }
  
  /// Obtient une version plus claire de la couleur du ministère
  Color getLightMinistryColor() {
    final color = AppTheme.getMinistryColor(this);
    return Color.fromARGB(
      40,  // Faible opacité
      color.red,
      color.green,
      color.blue,
    );
  }
  
  /// Obtient une couleur de texte appropriée (blanc ou noir) selon la couleur du ministère
  Color getMinistryTextColor() {
    final color = AppTheme.getMinistryColor(this);
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? AppTheme.textDark : Colors.white;
  }
}