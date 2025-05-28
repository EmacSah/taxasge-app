import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_service.dart';
import '../services/localization_service.dart';
// Assuming models are not directly needed here as data comes in a Map.

class TaxDetailScreen extends StatefulWidget {
  final String conceptoId;

  const TaxDetailScreen({
    super.key,
    required this.conceptoId,
  });

  @override
  State<TaxDetailScreen> createState() => _TaxDetailScreenState();
}

class _TaxDetailScreenState extends State<TaxDetailScreen> {
  late Future<Map<String, dynamic>?> _conceptoDetailsFuture;
  late LocalizationService _localizationService;

  @override
  void initState() {
    super.initState();
    // It's better to get this once if it doesn't change during the widget's lifecycle,
    // or listen to it if it can change and this widget needs to react.
    // For langCode, it's usually fine to get it once for the initial load.
    // If language can change while this screen is open, a more reactive approach would be needed
    // for the _loadConceptoDetails call, perhaps by making LocalizationService a ListenableProvider.
    // For this iteration, getting it once in initState for the initial load.
    _localizationService = Provider.of<LocalizationService>(context, listen: false);
    _loadConceptoDetails();
  }

  void _loadConceptoDetails() {
    setState(() {
      _conceptoDetailsFuture = DatabaseService().getConceptoWithDetails(
        widget.conceptoId,
        langCode: _localizationService.currentLanguage,
      );
    });
  }

  Future<void> _toggleFavorite(String conceptoId) async {
    await DatabaseService().favoriDao.toggleFavorite(conceptoId);
    // Refresh details to update the favorite icon and potentially other data
    _loadConceptoDetails();
  }

  String _formatAmount(dynamic amount, String currentLang) {
    if (amount == null || amount.toString().isEmpty || amount.toString() == "-") {
      return "N/A"; // Not Available
    }
    if (amount.toString().toLowerCase() == "gratuita") {
      return currentLang == 'fr' ? "Gratuite" : "Gratuita"; // Or use proper localization keys
    }
    // Assuming amount is a number or string that can be directly displayed
    return amount.toString();
  }

  Widget _buildHierarchy(Map<String, dynamic> details, String currentLang) {
    List<String> parts = [];
    if (details['ministerio_nombre'] != null) parts.add(details['ministerio_nombre']);
    if (details['sector_nombre'] != null) parts.add(details['sector_nombre']);
    if (details['categoria_nombre'] != null) parts.add(details['categoria_nombre']);
    if (details['subcategoria_nombre'] != null && details['subcategoria_nombre'].isNotEmpty) {
      parts.add(details['subcategoria_nombre']);
    } else if (parts.isNotEmpty && details['subcategoria_nombre'] != null && details['subcategoria_nombre'].isEmpty) {
      // Handle case where subcategory is "Taxes / Services Directs" (empty name)
      // by not adding an empty part, or showing a default if needed.
      // For now, just skip if empty.
    }
    
    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        parts.join(' > '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-obtain localizationService here if language can change and UI needs to rebuild
    // For now, _localizationService from initState is used for initial load and _formatAmount.
    // If future is re-run due to language change, this would be ideal.
    final currentLang = _localizationService.currentLanguage;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _conceptoDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chargement...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          final conceptoDetails = snapshot.data!;
          final String conceptName = conceptoDetails['nombre_current'] ?? conceptoDetails['nombre_es'] ?? 'Détail';
          final bool isFavorite = conceptoDetails['es_favorito'] ?? false;

          List<Map<String, dynamic>> documentos = [];
          if (conceptoDetails['documentos'] is List) {
            documentos = List<Map<String, dynamic>>.from(conceptoDetails['documentos']);
          }

          List<Map<String, dynamic>> procedimientos = [];
          if (conceptoDetails['procedimientos'] is List) {
            procedimientos = List<Map<String, dynamic>>.from(conceptoDetails['procedimientos']);
            procedimientos.sort((a, b) => (a['orden'] ?? 0).compareTo(b['orden'] ?? 0));
          }
          
          List<String> palabrasClave = [];
          if (conceptoDetails['palabras_clave'] is List) {
            palabrasClave = List<String>.from(conceptoDetails['palabras_clave'].map((e) => e.toString()));
          }


          return Scaffold(
            appBar: AppBar(
              title: Text(conceptName),
              actions: [
                IconButton(
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  onPressed: () => _toggleFavorite(widget.conceptoId),
                  tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(conceptName, style: Theme.of(context).textTheme.headlineSmall),
                    _buildHierarchy(conceptoDetails, currentLang),
                    const Divider(height: 20),

                    Text("Montants", style: Theme.of(context).textTheme.titleMedium),
                    ListTile(
                      title: const Text("Taxe d'expédition"),
                      trailing: Text(_formatAmount(conceptoDetails['tasa_expedicion'], currentLang)),
                    ),
                    ListTile(
                      title: const Text("Taxe de renouvellement"),
                      trailing: Text(_formatAmount(conceptoDetails['tasa_renovacion'], currentLang)),
                    ),
                    const SizedBox(height: 10),
                    
                    if (documentos.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text("Documents Requis", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8.0),
                      ...documentos.map((doc) {
                        final docName = doc['nombre_current'] ?? doc['nombre_es'] ?? 'Document inconnu';
                        return ListTile(
                          leading: const Icon(Icons.article_outlined),
                          title: Text(docName),
                          // subtitle: Text(doc['descripcion_current'] ?? doc['descripcion_es'] ?? ''), // If description is available
                        );
                      }),
                    ] else ...[
                      const Divider(height: 20),
                      Text("Documents Requis", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8.0),
                      const Text("Aucun document spécifique requis."),
                    ],
                    const SizedBox(height: 10),

                    if (procedimientos.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text("Procédure", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8.0),
                      ...procedimientos.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Map<String, dynamic> proc = entry.value;
                        final procDesc = proc['description_current'] ?? proc['description_es'] ?? 'Étape non décrite';
                        return ListTile(
                          leading: CircleAvatar(child: Text('${idx + 1}')),
                          title: Text(procDesc),
                        );
                      }),
                    ] else ...[
                      const Divider(height: 20),
                      Text("Procédure", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8.0),
                      const Text("Aucune procédure spécifique décrite."),
                    ],
                    const SizedBox(height: 10),

                    if (palabrasClave.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text("Mots-clés", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: palabrasClave.map((keyword) => Chip(label: Text(keyword))).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: const Text('Détail')),
            body: const Center(child: Text('Détails de la taxe non disponibles.')),
          );
        }
      },
    );
  }
}
