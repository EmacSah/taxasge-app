import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Classe qui définit les styles personnalisés pour les widgets spécifiques
/// de l'application TaxasGE
class CustomWidgetStyles {
  CustomWidgetStyles._();
  
  // ======== STYLES DES CARTES DE MINISTÈRE ========
  
  /// Style pour les cartes de ministère sur l'écran d'accueil
  static Widget ministryCard({
    required String title,
    Color? backgroundColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
  static Widget taxCard({
    required String title,
    required String ministry,
    required String price,
    required VoidCallback onTap,
    String? iconPath,
    Color? iconBackgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusCard),
      child: Container(
        decoration: AppTheme.taxCardDecoration,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Row(
          children: [
            // Icône (si fournie)
            if (iconPath != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingMedium),
            ],
            
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.paddingExtraSmall),
                  Text(
                    ministry,
                    style: AppTheme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
  
  // ======== STYLES DES FILTRES DE RECHERCHE ========
  
  /// Style pour les chips de filtre dans la recherche
  static Widget filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
        ),
      ),
    );
  }
  
  // ======== STYLES DES SECTIONS DE DÉTAIL ========
  
  /// Style pour les sections de détail de taxe
  static Widget detailSection({
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        content,
        const SizedBox(height: AppTheme.paddingMedium),
        const Divider(),
      ],
    );
  }
  
  /// Style pour les lignes de montant dans la section de détail
  static Widget amountRow({
    required String label,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textTheme.bodyMedium,
          ),
          Text(
            amount,
            style: AppTheme.monoTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // ======== STYLES DU CHATBOT ========
  
  /// Style pour les bulles de message du chatbot (assistant)
  static Widget chatbotBubble({
    required String message,
    Widget? additionalContent,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: AppTheme.chatbotBubbleDecoration,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        margin: const EdgeInsets.only(
          bottom: AppTheme.paddingMedium,
          right: AppTheme.paddingLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTheme.textTheme.bodyMedium,
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
  static Widget userBubble({
    required String message,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: AppTheme.userChatBubbleDecoration,
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        margin: const EdgeInsets.only(
          bottom: AppTheme.paddingMedium,
          left: AppTheme.paddingLarge,
        ),
        child: Text(
          message,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textDark,
          ),
        ),
      ),
    );
  }
  
  /// Style pour les suggestions du chatbot
  static Widget chatbotSuggestion({
    required String text,
    required VoidCallback onTap,
  }) {
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
        ),
      ),
    );
  }
  
  // ======== STYLES POUR LA NAVIGATION ========
  
  /// Style pour l'en-tête de breadcrumb (fil d'Ariane)
  static Widget breadcrumbHeader({
    required List<String> pathItems,
    required Function(int) onTap,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pathItems.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right,
            size: 16,
            color: AppTheme.textLight,
          ),
        ),
        itemBuilder: (context, index) {
          final isLast = index == pathItems.length - 1;
          
          return GestureDetector(
            onTap: isLast ? null : () => onTap(index),
            child: Center(
              child: Text(
                pathItems[index],
                style: AppTheme.textTheme.bodySmall?.copyWith(
                  color: isLast ? AppTheme.textDark : AppTheme.primaryColor,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // ======== STYLES POUR LE MODE HORS LIGNE ========
  
  /// Style pour l'indicateur de mode hors ligne
  static Widget offlineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.paddingSmall,
        horizontal: AppTheme.paddingMedium,
      ),
      color: AppTheme.warningColor.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          Text(
            "Modo sin conexión",
            style: AppTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }
}