import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Classe qui définit la charte graphique complète de l'application TaxasGE avec support multilingue
class AppTheme {
  AppTheme._();

  // ======== COULEURS ========

  // Couleurs principales
  static const Color primaryColor = Color(0xFF4285F4); // Bleu principal
  static const Color secondaryColor = Color(0xFF34A853); // Vert secondaire
  static const Color accentColor = Color(0xFFEA4335); // Rouge d'accentuation

  // Couleurs neutrales
  static const Color backgroundLight = Color(0xFFF5F5F5); // Fond gris clair
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Fond blanc
  static const Color textDark = Color(0xFF333333); // Texte principal
  static const Color textMedium = Color(0xFF666666); // Texte secondaire
  static const Color textLight = Color(0xFF888888); // Texte tertiaire
  static const Color dividerColor = Color(0xFFDDDDDD); // Séparateurs

  // Couleurs fonctionnelles
  static const Color errorColor = Color(0xFFB31412); // Erreur
  static const Color successColor = Color(0xFF0F9D58); // Succès
  static const Color warningColor = Color(0xFFF57F17); // Avertissement
  static const Color infoColor = Color(0xFF2A56C6); // Information

  // Système de couleurs des ministères
  // Palette de couleurs dynamique pour les ministères
  static const List<Color> ministryColorPalette = [
    Color(0xFF4285F4), // Bleu principal
    Color(0xFF34A853), // Vert secondaire
    Color(0xFFEA4335), // Rouge
    Color(0xFFFBBC05), // Jaune
    Color(0xFF9DE7D7), // Turquoise
    Color(0xFFFFCC80), // Orange
    Color(0xFF90CAF9), // Bleu ciel
    Color(0xFF80CBC4), // Turquoise foncé
    Color(0xFFFFCDD2), // Rose
    Color(0xFFCFD8DC), // Gris
    Color(0xFFFFAB91), // Saumon
    Color(0xFFB39DDB), // Violet
    Color(0xFFDCE775), // Vert clair
    Color(0xFFFFD54F), // Jaune doré
    Color(0xFFE6EE9C), // Vert-jaune pâle
    Color(0xFFFFAB40), // Orange vif
    Color(0xFF81D4FA), // Bleu clair
    Color(0xFFA1887F), // Brun
    Color(0xFFCE93D8), // Mauve
    Color(0xFFFF8A65), // Corail
  ];

  // Map pour les ministères communs (pour ceux explicitement définis dans les images)
  // Mise à jour avec équivalents multilingues
  static const Map<String, Color> predefinedMinistryColors = {
    // Espagnol (original)
    'ASUNTOS EXTERIORES': Color(0xFFFCE083),
    'HACIENDA': Color(0xFF9DE7D7),
    'TRANSPORTE': Color(0xFFFFCC80),
    'EDUCACIÓN': Color(0xFF90CAF9),
    'COMERCIO': Color(0xFF80CBC4),
    'INFORMACIÓN': Color(0xFFFBBC05),
    'JUSTICIA': Color(0xFFFFCDD2),
    'AVIACIÓN CIVIL': Color(0xFFCFD8DC),
    'PRESIDENCIA': Color(0xFFFFAB91),

    // Français
    'AFFAIRES ÉTRANGÈRES': Color(0xFFFCE083),
    'FINANCES': Color(0xFF9DE7D7),
    'TRANSPORT': Color(0xFFFFCC80),
    'ÉDUCATION': Color(0xFF90CAF9),
    'COMMERCE': Color(0xFF80CBC4),
    'INFORMATION': Color(0xFFFBBC05),
    'JUSTICE': Color(0xFFFFCDD2),
    'AVIATION CIVILE': Color(0xFFCFD8DC),
    'PRÉSIDENCE': Color(0xFFFFAB91),

    // Anglais
    'FOREIGN AFFAIRS': Color(0xFFFCE083),
    'FINANCE': Color(0xFF9DE7D7),
    'TRANSPORTATION': Color(0xFFFFCC80),
    'EDUCATION': Color(0xFF90CAF9),
    'TRADE': Color(0xFF80CBC4),
    'CIVIL AVIATION': Color(0xFFCFD8DC),
    'PRESIDENCY': Color(0xFFFFAB91),

    // Nouveaux ministères ajoutés
    'SALUD': Color(0xFFC5E1A5),
    'SANTÉ': Color(0xFFC5E1A5),
    'HEALTH': Color(0xFFC5E1A5),

    'DEFENSA': Color(0xFFB0BEC5),
    'DÉFENSE': Color(0xFFB0BEC5),
    'DEFENSE': Color(0xFFB0BEC5),

    'INTERIOR': Color(0xFFA1887F),
    'INTÉRIEUR': Color(0xFFA1887F),
    'HOME AFFAIRS': Color(0xFFA1887F),

    'CULTURA': Color(0xFFFFCC80),
    'CULTURE': Color(0xFFFFCC80),
  };

  /// Obtient une couleur pour un ministère donné avec support multilingue
  ///
  /// Cette méthode améliorée vérifie d'abord une correspondance exacte, puis
  /// normalise le nom du ministère (suppression des accents, majuscules)
  /// pour trouver une correspondance dans la map prédéfinie. Si aucune
  /// correspondance n'est trouvée, génère une couleur déterministe.
  ///
  /// [ministryName] : Nom du ministère dans n'importe quelle langue supportée
  static Color getMinistryColor(String ministryName) {
    // 1. Vérification directe dans la map (correspondance exacte)
    if (predefinedMinistryColors.containsKey(ministryName)) {
      return predefinedMinistryColors[ministryName]!;
    }

    // 2. Vérification avec le nom en majuscules (insensible à la casse)
    final upperName = ministryName.toUpperCase();
    if (predefinedMinistryColors.containsKey(upperName)) {
      return predefinedMinistryColors[upperName]!;
    }

    // 3. Normaliser le nom (enlever les accents, etc.)
    final normalizedName = _normalizeMinistryName(ministryName);

    // 4. Recherche partielle - vérifier si le nom normalisé contient
    // une des clés ou si une clé contient le nom normalisé
    for (final entry in predefinedMinistryColors.entries) {
      final normalizedKey = _normalizeMinistryName(entry.key);
      if (normalizedName.contains(normalizedKey) ||
          normalizedKey.contains(normalizedName)) {
        return entry.value;
      }
    }

    // 5. Si aucune correspondance, utiliser une couleur déterministe
    int hashCode = normalizedName.hashCode;
    return ministryColorPalette[hashCode.abs() % ministryColorPalette.length];
  }

  /// Normalise un nom de ministère pour faciliter les comparaisons multilingues
  ///
  /// Cette méthode supporte la correspondance entre noms équivalents dans
  /// différentes langues en normalisant le format (majuscules sans accents).
  static String _normalizeMinistryName(String name) {
    // Convertir en majuscules
    String normalized = name
        .toUpperCase()
        // Supprimer les accents
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll('Ü', 'U')
        // Remplacer les préfixes courants
        .replaceAll('MINISTÈRE DES ', '')
        .replaceAll('MINISTÈRE DE ', '')
        .replaceAll('MINISTÈRE DU ', '')
        .replaceAll('MINISTRY OF ', '')
        .replaceAll('MINISTERIO DE ', '')
        .replaceAll('MINISTERIO DEL ', '');

    return normalized;
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

  /// Obtient un style de texte adapté à la direction du texte
  /// pour une langue spécifique (RTL/LTR)
  static TextStyle getDirectionalTextStyle(TextStyle style, String langCode) {
    // Vérifier si la langue est RTL
    final isRtl = _isRtlLanguage(langCode);

    if (!isRtl) {
      return style;
    }

    // Ajuster les propriétés pour les langues RTL
    return style.copyWith(
        // Ajustements spécifiques pour RTL si nécessaire
        );
  }

  /// Vérifie si une langue s'écrit de droite à gauche (RTL)
  static bool _isRtlLanguage(String langCode) {
    // Liste des langues RTL courantes
    const List<String> rtlLanguages = ['ar', 'fa', 'he', 'ur'];
    return rtlLanguages.contains(langCode);
  }

  /// Obtient la direction du texte pour une langue donnée
  static TextDirection getTextDirection(String langCode) {
    return _isRtlLanguage(langCode) ? TextDirection.rtl : TextDirection.ltr;
  }

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
      surface: backgroundLight,
      //surface: backgroundWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
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
    splashColor: primaryColor.withAlpha((0.1 * 255).toInt()),
    highlightColor: primaryColor.withAlpha((0.05 * 255).toInt()),
  );

  /// Produit une version directionnelle du thème pour les langues RTL
  ///
  /// Cette méthode génère une variante du thème principal adaptée aux langues
  /// qui s'écrivent de droite à gauche (RTL) comme l'arabe.
  //static ThemeData getRtlTheme() {
  //  return lightTheme.copyWith(
  //    textDirection: TextDirection.rtl,
  // Autres ajustements spécifiques pour RTL si nécessaire
  //  );
  //}

  /// Obtient le thème approprié pour une langue donnée
  static ThemeData getLocalizedTheme(String langCode) {
    //return _isRtlLanguage(langCode) ? getRtlTheme() : lightTheme;
    return lightTheme;
  }

  // ======== STYLES SPÉCIFIQUES DES COMPOSANTS ========

  // Style pour les cartes de taxe
  static BoxDecoration taxCardDecoration = BoxDecoration(
    color: backgroundWhite,
    borderRadius: BorderRadius.circular(borderRadiusCard),
    border: Border.all(color: dividerColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha((0.05 * 255).toInt()),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Style pour les items de grille de ministère
  static BoxDecoration ministryGridItemDecoration(
      {required Color backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.1 * 255).toInt()),
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
    color: primaryColor.withAlpha((0.1 * 255).toInt()),
    borderRadius: BorderRadius.circular(borderRadiusMedium).copyWith(
      topRight: const Radius.circular(0),
    ),
  );

  /// Style pour les bulles du chatbot avec adaptation RTL/LTR
  ///
  /// Cette méthode retourne un style de bulle adapté à la direction du texte
  /// selon la langue spécifiée (RTL ou LTR)
  static BoxDecoration getChatbotBubbleDecoration(String langCode) {
    final isRtl = _isRtlLanguage(langCode);

    return BoxDecoration(
      color: backgroundLight,
      borderRadius: BorderRadius.circular(borderRadiusMedium).copyWith(
        // Inverser le coin carré selon la direction
        topLeft: isRtl ? null : const Radius.circular(0),
        topRight: isRtl ? const Radius.circular(0) : null,
      ),
    );
  }

  /// Style pour les bulles de l'utilisateur avec adaptation RTL/LTR
  static BoxDecoration getUserChatBubbleDecoration(String langCode) {
    final isRtl = _isRtlLanguage(langCode);

    return BoxDecoration(
      color: primaryColor.withAlpha((0.1 * 255).toInt()),
      borderRadius: BorderRadius.circular(borderRadiusMedium).copyWith(
        // Inverser le coin carré selon la direction
        topRight: isRtl ? null : const Radius.circular(0),
        topLeft: isRtl ? const Radius.circular(0) : null,
      ),
    );
  }

  // ======== SUPPORT MULTILINGUE ========

  // Langues supportées dans l'application
  static const List<Locale> supportedLocales = [
    Locale('es'), // Espagnol (par défaut)
    Locale('fr'), // Français
    Locale('en'), // Anglais
  ];

  // Langue par défaut
  static const Locale defaultLocale = Locale('es');

  /// Obtient les codes de langue supportés
  static List<String> get supportedLanguageCodes =>
      supportedLocales.map((locale) => locale.languageCode).toList();

  /// Vérifie si une langue est supportée
  static bool isLanguageSupported(String langCode) {
    return supportedLanguageCodes.contains(langCode);
  }

  /// Obtient la locale par défaut pour une langue
  static Locale getLocaleForLanguage(String langCode) {
    if (!isLanguageSupported(langCode)) {
      return defaultLocale;
    }
    return Locale(langCode);
  }

  // ======== ANIMATIONS ========

  // Durées d'animation standard
  static const Duration animationDurationShort = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationLong = Duration(milliseconds: 500);

  // Courbes d'animation standard
  static const Curve animationCurveDefault = Curves.easeInOut;
  static const Curve animationCurveFast = Curves.fastOutSlowIn;
}
