import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For LocalizationService
import '../database/database_service.dart';
import '../services/localization_service.dart';
import '../models/categoria.dart';
import 'tax_subcategories_screen.dart';

class TaxCategoriesScreen extends StatelessWidget {
  final String sectorId;
  final String sectorNombre;

  const TaxCategoriesScreen({
    super.key,
    required this.sectorId,
    required this.sectorNombre,
  });

  @override
  Widget build(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    final String currentLang = localizationService.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(sectorNombre),
      ),
      body: FutureBuilder<List<Categoria>>(
        future: DatabaseService()
            .categoriaDao
            .getBySectorId(sectorId, langCode: currentLang),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Erreur: ${snapshot.error}')); // Localization later
          } else if (snapshot.hasData) {
            final categorias = snapshot.data!;
            if (categorias.isEmpty) {
              return const Center(
                  child: Text(
                      'Aucune catégorie trouvée pour ce secteur.')); // Localization later
            }
            return ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                final categoriaName = categoria.getNombre(currentLang);
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(categoriaName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaxSubCategoriesScreen(
                            categoriaId: categoria.id,
                            categoriaNombre:
                                categoriaName, // categoria.getNombre(currentLang) also works
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
            return const Center(
                child: Text(
                    'Aucune catégorie disponible pour ce secteur.')); // Localization later
          }
        },
      ),
    );
  }
}
