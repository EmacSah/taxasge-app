import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For LocalizationService
import '../services/database_service.dart';
import '../services/localization_service.dart';
import '../models/concepto.dart';
import 'tax_detail_screen.dart';

class TaxConceptsScreen extends StatelessWidget {
  final String subCategoriaId;
  final String subCategoriaNombre;

  const TaxConceptsScreen({
    super.key,
    required this.subCategoriaId,
    required this.subCategoriaNombre,
  });

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final String currentLang = localizationService.currentLanguage;

    // As per instruction, subCategoriaNombre is used directly for AppBar title for this iteration.
    // The logic for "Taxes / Services Directs" to fetch parent category name is deferred.
    String appBarTitle = subCategoriaNombre;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: FutureBuilder<List<Concepto>>(
        future: DatabaseService.instance.conceptoDao.getBySubCategoriaId(subCategoriaId, langCode: currentLang),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}')); // Localization later
          } else if (snapshot.hasData) {
            final conceptos = snapshot.data!;
            if (conceptos.isEmpty) {
              return const Center(child: Text('Aucune taxe trouvée pour cette sous-catégorie.')); // Localization later
            }
            return ListView.builder(
              itemCount: conceptos.length,
              itemBuilder: (context, index) {
                final concepto = conceptos[index];
                final conceptoName = concepto.getNombre(currentLang);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(conceptoName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaxDetailScreen(
                            conceptoId: concepto.id,
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
            return const Center(child: Text('Aucune taxe disponible pour cette sous-catégorie.')); // Localization later
          }
        },
      ),
    );
  }
}
