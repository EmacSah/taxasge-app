import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For LocalizationService
import '../services/database_service.dart';
import '../services/localization_service.dart';
import '../models/sub_categoria.dart';
import 'tax_concepts_screen.dart';

class TaxSubCategoriesScreen extends StatelessWidget {
  final String categoriaId;
  final String categoriaNombre;

  const TaxSubCategoriesScreen({
    super.key,
    required this.categoriaId,
    required this.categoriaNombre,
  });

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final String currentLang = localizationService.currentLanguage;
    const String defaultSubCategoryName = "Taxes / Services Directs"; // Localization later

    return Scaffold(
      appBar: AppBar(
        title: Text(categoriaNombre),
      ),
      body: FutureBuilder<List<SubCategoria>>(
        future: DatabaseService.instance.subCategoriaDao.getByCategoriaId(categoriaId, langCode: currentLang),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}')); // Localization later
          } else if (snapshot.hasData) {
            final subCategorias = snapshot.data!;
            if (subCategorias.isEmpty) {
              return const Center(child: Text('Aucune sous-catégorie trouvée pour cette catégorie.')); // Localization later
            }
            return ListView.builder(
              itemCount: subCategorias.length,
              itemBuilder: (context, index) {
                final subCategoria = subCategorias[index];
                String displayName = subCategoria.getNombre(currentLang);
                if (displayName.isEmpty) {
                  displayName = defaultSubCategoryName;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(displayName),
                    onTap: () {
                      final String subCategoriaNombreDisplay = subCategoria.getNombre(currentLang).isNotEmpty
                          ? subCategoria.getNombre(currentLang)
                          : defaultSubCategoryName; // defaultSubCategoryName is "Taxes / Services Directs"
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaxConceptsScreen(
                            subCategoriaId: subCategoria.id,
                            subCategoriaNombre: subCategoriaNombreDisplay,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            // Fallback, though ideally covered by hasData and isEmpty check.
            return const Center(child: Text('Aucune sous-catégorie disponible pour cette catégorie.')); // Localization later
          }
        },
      ),
    );
  }
}
