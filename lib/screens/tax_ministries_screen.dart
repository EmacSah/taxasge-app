import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For LocalizationService
import '../database/database_service.dart';
import '../services/localization_service.dart';
import '../models/ministerio.dart';
import 'tax_sectors_screen.dart';

class TaxMinistriesScreen extends StatelessWidget {
  const TaxMinistriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService =
        Provider.of<LocalizationService>(context, listen: false);
    final String currentLang = localizationService.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministères'), // Localization will be handled later
      ),
      body: FutureBuilder<List<Ministerio>>(
        future: DatabaseService().ministerioDao.getAll(langCode: [currentLang]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final ministerios = snapshot.data!;
            if (ministerios.isEmpty) {
              return const Center(
                  child: Text('Aucun ministère trouvé.')); // Localization later
            }
            return ListView.builder(
              itemCount: ministerios.length,
              itemBuilder: (context, index) {
                final ministerio = ministerios[index];
                final ministerioName = ministerio.getNombre(currentLang);
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(ministerioName),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaxSectorsScreen(
                            ministerioId: ministerio.id,
                            ministerioNombre:
                                ministerioName, // ministerio.getNombre(currentLang) also works
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            // This case should ideally not be reached if hasData is true and empty is handled.
            // But as a fallback:
            return const Center(
                child:
                    Text('Aucun ministère disponible.')); // Localization later
          }
        },
      ),
    );
  }
}
