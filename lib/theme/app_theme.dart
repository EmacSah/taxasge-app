import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Classe qui définit la charte graphique complète de l'application TaxasGE
class AppTheme {
  AppTheme._();

  // ======== COULEURS ========
  
  // Couleurs principales
  static const Color primaryColor = Color(0xFF4285F4);     // Bleu principal
  static const Color secondaryColor = Color(0xFF34A853);   // Vert secondaire
  static const Color accentColor = Color(0xFFEA4335);      // Rouge d'accentuation
  
  // Couleurs neutrales
  static const Color backgroundLight = Color(0xFFF5F5F5);  // Fond gris clair
  static const Color backgroundWhite = Color(0xFFFFFFFF);  // Fond blanc
  static const Color textDark = Color(0xFF333333);         // Texte principal
  static const Color textMedium = Color(0xFF666666);       // Texte secondaire
  static const Color textLight = Color(0xFF888888);        // Texte tertiaire
  static const Color dividerColor = Color(0xFFDDDDDD);     // Séparateurs
  
  // Couleurs fonctionnelles
  static const Color errorColor = Color(0xFFB31412);       // Erreur
  static const Color successColor = Color(0xFF0F9D58);     // Succès
  static const Color warningColor = Color(0xFFF57F17);     // Avertissement
  static const Color infoColor = Color(0xFF2A56C6);        // Information
  
  // Système de couleurs des ministères
  // Palette de couleurs dynamique pour les ministères
  static const List<Color> ministryColorPalette = [
    Color(0xFF4285F4),  // Bleu principal
    Color(0xFF34A853),  // Vert secondaire
    Color(0xFFEA4335),  // Rouge
    Color(0xFFFBBC05),  // Jaune
    Color(0xFF9DE7D7),  // Turquoise
    Color(0xFFFFCC80),  // Orange
    Color(0xFF90CAF9),  // Bleu ciel
    Color(0xFF80CBC4),  // Turquoise foncé
    Color(0xFFFFCDD2),  // Rose
    Color(0xFFCFD8DC),  // Gris
    Color(0xFFFFAB91),  // Saumon
    Color(0xFFB39DDB),  // Violet
    Color(0xFFDCE775),  // Vert clair
    Color(0xFFFFD54F),  // Jaune doré
    Color(0xFFE6EE9C),  // Vert-jaune pâle
    Color(0xFFFFAB40),  // Orange vif
    Color(0xFF81D4FA),  // Bleu clair
    Color(0xFFA1887F),  // Brun
    Color(0xFFCE93D8),  // Mauve
    Color(0xFFFF8A65),  // Corail
  ];
  
  // Map pour les ministères communs (pour ceux explicitement définis dans les images)
  static const Map<String, Color> predefinedMinistryColors = {
    'ASUNTOS EXTERIORES': Color(0xFFFCE083),  // Jaune (Asuntos Exteriores)
    'HACIENDA': Color(0xFF9DE7D7),            // Turquoise (Hacienda)
    'TRANSPORTE': Color(0xFFFFCC80),          // Orange (Transporte y Correos)
    'EDUCACIÓN': Color(0xFF90CAF9),           // Bleu ciel (Educación)
    'COMERCIO': Color(0xFF80CBC4),            // Turquoise foncé (Comercio)
    'INFORMACIÓN': Color(0xFFFBBC05),         // Jaune foncé (Información)
    'JUSTICIA': Color(0xFFFFCDD2),            // Rose (Justicia)
    'AVIACIÓN CIVIL': Color(0xFFCFD8DC),      // Gris (Aviación Civil)
    'PRESIDENCIA': Color(0xFFFFAB91),         // Saumon (Presidencia)
  };
  
  /// Obtient une couleur pour un ministère donné
  /// Si le ministère est dans la liste prédéfinie, retourne sa couleur
  /// Sinon, génère une couleur déterministe basée sur le nom du ministère
  static Color getMinistryColor(String ministryName) {
    // Normaliser le nom du ministère (majuscules, sans accents)
    final normalizedName = ministryName.toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U');
    
    // Vérifier si le ministère a une couleur prédéfinie
    for (final entry in predefinedMinistryColors.entries) {
      if (normalizedName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Sinon, générer une couleur déterministe basée sur le nom
    int hashCode = normalizedName.hashCode;
    return ministryColorPalette[hashCode.abs() % ministryColorPalette.length];
  }
  
  // ======== TYPOGRAPHIE ========
  
  // Polices principales
  static TextTheme textTheme = GoogleFonts.robotoTextTheme().copyWith(
    // Titres
    displayLarge: GoogleFonts.roboto(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: textDark,
    ),
    displayMedium: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: textDark,
    ),
    displaySmall: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textDark,
    ),
    
    // Sous-titres
    headlineLarge: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textDark,
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textDark,
    ),
    headlineSmall: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: textDark,
    ),
    
    // Corps de texte
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: textDark,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textDark,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: textMedium,
    ),
    
    // Autres éléments
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: primaryColor,
    ),
    labelMedium: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: primaryColor,
    ),
    labelSmall: GoogleFonts.roboto(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: textMedium,
    ),
  );
  
  // Police pour les données numériques
  static TextStyle monoTextStyle = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textDark,
  );
  
  // Police pour les données numériques (en gras)
  static TextStyle monoTextStyleBold = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: textDark,
  );
  
  // ======== ÉLÉVATIONS ========
  
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // ======== RAYONS DE BORD ========
  
  static const double borderRadiusSmall = 5.0;
  static const double borderRadiusMedium = 10.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusButton = 25.0;
  static const double borderRadiusCard = 10.0;
  
  // ======== ESPACEMENT ========
  
  static const double paddingExtraSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;
  
  // ======== THÈME LIGHT ========
  
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundLight,
      surface: backgroundWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onBackground: textDark,
      onSurface: textDark,
    ),
    
    // Appbar
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: elevationSmall,
      centerTitle: true,
      titleTextStyle: textTheme.headlineMedium?.copyWith(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    
    // Cartes
    cardTheme: CardTheme(
      elevation: elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusCard),
      ),
      color: backgroundWhite,
      margin: const EdgeInsets.symmetric(
        vertical: paddingSmall,
        horizontal: paddingMedium,
      ),
    ),
    
    // Boutons principaux
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationSmall,
        padding: const EdgeInsets.symmetric(
          vertical: paddingSmall,
          horizontal: paddingLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusButton),
        ),
        textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    
    // Boutons secondaires
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(
          vertical: paddingSmall,
          horizontal: paddingLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusButton),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    
    // Boutons texte
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
          vertical: paddingSmall,
          horizontal: paddingMedium,
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    
    // Champs de texte
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusButton),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusButton),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusButton),
        borderSide: const BorderSide(color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadiusButton),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingSmall,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: textLight),
      errorStyle: textTheme.bodySmall?.copyWith(color: errorColor),
    ),
    
    // Dialogues
    dialogTheme: DialogTheme(
      backgroundColor: backgroundWhite,
      elevation: elevationLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
    
    // Tabs
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: textMedium,
      indicator: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge?.copyWith(color: textMedium),
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      indent: paddingMedium,
      endIndent: paddingMedium,
    ),
    
    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundWhite,
      selectedItemColor: primaryColor,
      unselectedItemColor: textMedium,
      type: BottomNavigationBarType.fixed,
      elevation: elevationSmall,
    ),
    
    // Autres
    textTheme: textTheme,
    dividerColor: dividerColor,
    splashColor: primaryColor.withOpacity(0.1),
    highlightColor: primaryColor.withOpacity(0.05),
  );
  
  // ======== STYLES SPÉCIFIQUES DES COMPOSANTS ========
  
  // Style pour les cartes de taxe
  static BoxDecoration taxCardDecoration = BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(borderRadiusCard),
    border: Border.all(color: dividerColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ],
  );
  
  // Style pour les items de grille de ministère
  static BoxDecoration ministryGridItemDecoration({required Color backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // Style pour les chips de filtre
  static BoxDecoration filterChipDecoration({bool isSelected = false}) {
    return BoxDecoration(
      color: isSelected ? primaryColor : backgroundLight,
      borderRadius: BorderRadius.circular(borderRadiusButton),
      border: Border.all(
        color: isSelected ? primaryColor : dividerColor,
      ),
    );
  }
  
  // Style pour les bulles du chatbot (assistant)
  static BoxDecoration chatbotBubbleDecoration = BoxDecoration(
    color: backgroundLight,
    borderRadius: BorderRadius.circular(borderRadiusMedium).copyWith(
      topLeft: const Radius.circular(0),
    ),
  );
  
  // Style pour les bulles du chatbot (utilisateur)
  static BoxDecoration userChatBubbleDecoration = BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(borderRadiusMedium).copyWith(
      topRight: const Radius.circular(0),
    ),
  );
  
  // ======== SUPPORT MULTILINGUE ========
  
  // Langues supportées dans l'application
  static const List<Locale> supportedLocales = [
    Locale('es'), // Espagnol (par défaut)
    Locale('fr'), // Français
    Locale('en'), // Anglais
  ];
  
  // Langue par défaut
  static const Locale defaultLocale = Locale('es');
  
  // ======== ANIMATIONS ========
  
  // Durées d'animation standard
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);
  
  // Courbes d'animation standard
  static const Curve animationCurveDefault = Curves.easeInOut;
  static const Curve animationCurveFast = Curves.fastOutSlowIn;
}