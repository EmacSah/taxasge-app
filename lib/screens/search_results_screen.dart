import 'package:flutter/material.dart';
import 'package:taxasge/models/concepto.dart'; // Placeholder model
import 'package:taxasge/screens/tax_detail_screen.dart'; // Placeholder

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  // Placeholder data - replace with actual search logic and data
  List<Concepto> _getPlaceholderResults(String query) {
    if (query.toLowerCase().contains("passeport")) {
      return [
        Concepto(
          idConcepto: 1,
          nombreFR: "Passeport Ordinaire",
          nombreES: "Pasaporte Ordinario",
          nombreEN: "Ordinary Passport",
          idCategoria: 1, // Example ID
          // Initialize other required fields with default/placeholder values
          descripcionFR: "Description détaillée du passeport ordinaire...",
          descripcionES: "Descripción detallada del pasaporte ordinario...",
          descripcionEN: "Detailed description of the ordinary passport...",
          precioActual: 50000, // Example price
          // Add any other fields that are non-nullable or required by the constructor
        ),
        Concepto(
          idConcepto: 2,
          nombreFR: "Passeport Diplomatique",
          nombreES: "Pasaporte Diplomático",
          nombreEN: "Diplomatic Passport",
          idCategoria: 1, // Example ID
          descripcionFR: "Description détaillée du passeport diplomatique...",
          descripcionES: "Descripción detallada del pasaporte diplomático...",
          descripcionEN: "Detailed description of the diplomatic passport...",
          precioActual: 100000, // Example price
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final List<Concepto> results = _getPlaceholderResults(searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats pour "$searchQuery"'),
      ),
      body: results.isEmpty
          ? const Center(
              child: Text('Aucun résultat trouvé.'),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final concepto = results[index];
                return ListTile(
                  title: Text(concepto.nombreFR ?? 'Concept sans nom (FR)'),
                  subtitle: Text('Prix: ${concepto.precioActual} XAF'), // Example, adapt as needed
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaxDetailScreen(concepto: concepto),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
