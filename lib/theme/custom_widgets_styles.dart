import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/localization_service.dart';

/// Classe qui définit les styles personnalisés pour les widgets spécifiques
/// de l'application TaxasGE avec support multilingue
class CustomWidgetStyles {
  CustomWidgetStyles._();

  // ======== STYLES DES CARTES DE MINISTÈRE ========

  /// Style pour les cartes de ministère sur l'écran d'accueil
  ///
  /// [title] Titre du ministère (sera affiché dans la langue courante)
  /// [backgroundColor] Couleur de fond optionnelle (sinon déterminée à partir du titre)
  /// [icon] Icône à afficher
  /// [onTap] Action à exécuter lors du tap
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget ministryCard({
    required String title,
    Color? backgroundColor,
    required IconData icon,
    required VoidCallback onTap,
    String? langCode,
  }) {
    // Obtenir la langue active de l'application si non spécifiée
    //final effectiveLangCode =
    //    langCode ?? LocalizationService.instance.currentLanguage;

    // Si aucune couleur n'est fournie, utiliser la couleur dynamique basée sur le nom du ministère
    final color = backgroundColor ?? AppTheme.getMinistryColor(title);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        decoration: AppTheme.ministryGridItemDecoration(
          backgroundColor: color,
        ),
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              title,
              style: AppTheme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ======== STYLES DES CARTES DE TAXES ========

  /// Style pour les cartes de taxes dans les résultats de recherche
  ///
  /// [title] Titre de la taxe (dans la langue courante)
  /// [ministry] Nom du ministère (dans la langue courante)
  /// [price] Prix formaté (dans la langue courante)
  /// [onTap] Action à exécuter lors du tap
  /// [iconPath] Chemin vers l'icône optionnelle
  /// [iconBackgroundColor] Couleur de fond de l'icône
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget taxCard({
    required String title,
    required String ministry,
    required String price,
    required VoidCallback onTap,
    String? iconPath,
    Color? iconBackgroundColor,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
      child: Container(
        decoration: AppTheme.taxCardDecoration,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Icône (si fournie)
            if (iconPath != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ??
                      AppTheme.primaryColor.withAlpha((0.1 * 255).toInt()),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.paddingMedium),
            ],

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment:
                    isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection:
                        isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                  const SizedBox(height: AppTheme.paddingExtraSmall),
                  Text(
                    ministry,
                    style: AppTheme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection:
                        isRtl ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ],
              ),
            ),

            // Prix
            Text(
              price,
              style: AppTheme.monoTextStyleBold.copyWith(
                color: AppTheme.secondaryColor,
              ),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }

  // ======== STYLES DES FILTRES DE RECHERCHE ========

  /// Style pour les chips de filtre dans la recherche
  ///
  /// [label] Texte du filtre (dans la langue courante)
  /// [isSelected] État de sélection du filtre
  /// [onTap] Action à exécuter lors du tap
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusButton),
      child: Container(
        decoration: AppTheme.filterChipDecoration(isSelected: isSelected),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        child: Text(
          label,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  // ======== STYLES DES SECTIONS DE DÉTAIL ========

  /// Style pour les sections de détail de taxe
  ///
  /// [title] Titre de la section (dans la langue courante)
  /// [content] Contenu de la section
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget detailSection({
    required String title,
    required Widget content,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.textTheme.headlineSmall,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        content,
        const SizedBox(height: AppTheme.paddingMedium),
        const Divider(),
      ],
    );
  }

  /// Style pour les lignes de montant dans la section de détail
  ///
  /// [label] Libellé du montant (dans la langue courante)
  /// [amount] Montant formaté (dans la langue courante)
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget amountRow({
    required String label,
    required String amount,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Row(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodyMedium,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          Text(
            amount,
            style: AppTheme.monoTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  // ======== STYLES DU CHATBOT ========

  /// Style pour les bulles de message du chatbot (assistant)
  ///
  /// [message] Texte du message (dans la langue courante)
  /// [additionalContent] Contenu supplémentaire optionnel
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget chatbotBubble({
    required String message,
    Widget? additionalContent,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return Align(
      alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: AppTheme.chatbotBubbleDecoration,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        margin: EdgeInsets.only(
          bottom: AppTheme.paddingMedium,
          right: isRtl ? 0 : AppTheme.paddingLarge,
          left: isRtl ? AppTheme.paddingLarge : 0,
        ),
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTheme.textTheme.bodyMedium,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
            if (additionalContent != null) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              additionalContent,
            ],
          ],
        ),
      ),
    );
  }

  /// Style pour les bulles de message de l'utilisateur
  ///
  /// [message] Texte du message (dans la langue courante)
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget userBubble({
    required String message,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return Align(
      alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: AppTheme.userChatBubbleDecoration,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        margin: EdgeInsets.only(
          bottom: AppTheme.paddingMedium,
          left: isRtl ? 0 : AppTheme.paddingLarge,
          right: isRtl ? AppTheme.paddingLarge : 0,
        ),
        child: Text(
          message,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDark,
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  /// Style pour les suggestions du chatbot
  ///
  /// [text] Texte de la suggestion (dans la langue courante)
  /// [onTap] Action à exécuter lors du tap
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget chatbotSuggestion({
    required String text,
    required VoidCallback onTap,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        margin: const EdgeInsets.only(right: AppTheme.paddingSmall),
        child: Text(
          text,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.primaryColor,
          ),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  // ======== STYLES POUR LA NAVIGATION ========

  /// Style pour l'en-tête de breadcrumb (fil d'Ariane)
  ///
  /// [pathItems] Liste des éléments du chemin (dans la langue courante)
  /// [onTap] Fonction à exécuter lors du tap sur un élément
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget breadcrumbHeader({
    required List<String> pathItems,
    required Function(int) onTap,
    String? langCode,
  }) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pathItems.length,
        reverse: isRtl, // Inverser l'ordre pour les langues RTL
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isRtl ? Icons.chevron_left : Icons.chevron_right,
            size: 16,
            color: AppTheme.textLight,
          ),
        ),
        itemBuilder: (context, index) {
          // Pour les langues RTL, inverser l'index
          final effectiveIndex = isRtl ? pathItems.length - 1 - index : index;
          final isLast = effectiveIndex == pathItems.length - 1;

          return GestureDetector(
            onTap: isLast ? null : () => onTap(effectiveIndex),
            child: Center(
              child: Text(
                pathItems[effectiveIndex],
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: isLast ? AppTheme.textDark : AppTheme.primaryColor,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          );
        },
      ),
    );
  }

  // ======== STYLES POUR LE MODE HORS LIGNE ========

  /// Style pour l'indicateur de mode hors ligne
  ///
  /// [langCode] Code de langue optionnel (si différent de la langue courante)
  static Widget offlineIndicator({String? langCode}) {
    // Obtenir la langue active si non spécifiée
    final effectiveLangCode =
        langCode ?? LocalizationService.instance.currentLanguage;
    final isRtl = LocalizationService.instance.isRtl(effectiveLangCode);

    // Texte adapté à la langue
    String offlineText;
    switch (effectiveLangCode) {
      case 'fr':
        offlineText = "Mode hors connexion";
        break;
      case 'en':
        offlineText = "Offline mode";
        break;
      case 'es':
      default:
        offlineText = "Modo sin conexión";
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.paddingSmall,
        horizontal: AppTheme.paddingMedium,
      ),
      color: AppTheme.warningColor.withAlpha((0.2 * 255).toInt()),
      child: Row(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          Text(
            offlineText,
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.warningColor,
            ),
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  // ======== STYLES POUR LES ÉLÉMENTS MULTILINGUES ========

  /// Style pour afficher le sélecteur de langue
  ///
  /// [currentLangCode] Code de langue actuellement sélectionné
  /// [availableLanguages] Liste des codes de langue disponibles
  /// [onLanguageSelected] Fonction appelée lors de la sélection d'une langue
  static Widget languageSelector({
    required String currentLangCode,
    required List<String> availableLanguages,
    required Function(String) onLanguageSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: availableLanguages.map((langCode) {
        final isSelected = langCode == currentLangCode;

        // Obtenir le nom localisé de la langue
        final langName = LocalizationService.instance.getLanguageName(langCode);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: InkWell(
            onTap: isSelected ? null : () => onLanguageSelected(langCode),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingSmall,
                vertical: AppTheme.paddingExtraSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Text(
                langName,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMedium,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Style pour afficher des informations sur la disponibilité des traductions
  ///
  /// [availableLanguages] Map des langues disponibles par type de contenu
  /// [onLanguageSelected] Fonction appelée lors de la sélection d'une langue
  static Widget translationAvailabilityInfo({
    required Map<String, List<String>> availableLanguages,
    required Function(String, String) onLanguageSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: availableLanguages.entries.map((entry) {
        final contentType = entry.key;
        final languages = entry.value;

        // Traduire le type de contenu
        String contentTypeLabel;
        switch (contentType) {
          case 'nombre':
            contentTypeLabel = "Nom";
            break;
          case 'procedimiento':
            contentTypeLabel = "Procédure";
            break;
          case 'documentos_requeridos':
            contentTypeLabel = "Documents requis";
            break;
          default:
            contentTypeLabel = contentType;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contentTypeLabel,
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: languages.map((langCode) {
                  // Obtenir le nom localisé de la langue
                  final langName =
                      LocalizationService.instance.getLanguageName(langCode);

                  return InkWell(
                    onTap: () => onLanguageSelected(contentType, langCode),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor
                            .withAlpha((0.1 * 255).toInt()),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        langName,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
