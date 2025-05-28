import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For LocalizationService
import '../database/database_service.dart';
import '../services/localization_service.dart';
import '../models/sector.dart';
import 'tax_categories_screen.dart';

class TaxSectorsScreen extends StatelessWidget {
  final String ministerioId;
  final String ministerioNombre;

  const TaxSectorsScreen({
    super.key,
    required this.ministerioId,
    required this.ministerioNombre,
  });

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final String currentLang = localizationService.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(ministerioNombre),
      ),
      body: FutureBuilder<List<Sector>>(
        future: DatabaseService().sectorDao.getByMinisterioId(ministerioId, langCode: currentLang),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}')); // Localization later
          } else if (snapshot.hasData) {
            final sectores = snapshot.data!;
            if (sectores.isEmpty) {
              return const Center(child: Text('Aucun secteur trouvé pour ce ministère.')); // Localization later
            }
            return ListView.builder(
              itemCount: sectores.length,
              itemBuilder: (context, index) {
                final sector = sectores[index];
                final sectorName = sector.getNombre(currentLang);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(sectorName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaxCategoriesScreen(
                            sectorId: sector.id,
                            sectorNombre: sectorName, // sector.getNombre(currentLang) also works
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
            return const Center(child: Text('Aucun secteur disponible pour ce ministère.')); // Localization later
          }
        },
      ),
    );
  }
}
