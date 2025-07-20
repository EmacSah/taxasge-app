import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_service.dart';
import '../services/localization_service.dart';
import '../models/ministerio.dart';
import '../theme/app_theme.dart';
import 'tax_sectors_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Ministerio> _ministerios = [];
  List<Ministerio> _filteredMinisterios = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMinisterios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMinisterios() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final localizationService = Provider.of<LocalizationService>(context, listen: false);
      final currentLang = localizationService.currentLanguage;

      final ministerios = await DatabaseService().ministerioDao.getAll(langCode: [currentLang]);
      
      setState(() {
        _ministerios = ministerios;
        _filteredMinisterios = ministerios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterMinisterios(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMinisterios = _ministerios;
      });
      return;
    }

    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final currentLang = localizationService.currentLanguage;

    setState(() {
      _filteredMinisterios = _ministerios.where((ministerio) {
        final nombre = ministerio.getNombre(currentLang).toLowerCase();
        return nombre.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _navigateToSearch(String query) {
    if (query.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          searchQuery: query.trim(),
        ),
      ),
    );
  }

  void _navigateToMinisterio(Ministerio ministerio) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    final currentLang = localizationService.currentLanguage;
    final ministerioName = ministerio.getNombre(currentLang);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaxSectorsScreen(
          ministerioId: ministerio.id,
          ministerioNombre: ministerioName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final currentLang = localizationService.currentLanguage;
    final isRtl = localizationService.isRtl(currentLang);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaxasGE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchFocusNode.requestFocus(),
            tooltip: 'Rechercher',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String langCode) {
              localizationService.setLanguage(langCode);
              _loadMinisterios(); // Recharger avec la nouvelle langue
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'es',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Español'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fr',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Français'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.green),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche principale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getWelcomeText(currentLang),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: _getSearchHint(currentLang),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterMinisterios('');
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () {
                              // Filtres avancés à implémenter
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    _filterMinisterios(value);
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _navigateToSearch(value);
                    }
                  },
                  textInputAction: TextInputAction.search,
                ),
              ],
            ),
          ),

          // Section des ministères
          Expanded(
            child: _buildMinisteriosSection(currentLang, isRtl),
          ),
        ],
      ),
    );
  }

  Widget _buildMinisteriosSection(String currentLang, bool isRtl) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des ministères...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMinisterios,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredMinisterios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isNotEmpty 
                  ? Icons.search_off 
                  : Icons.folder_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Aucun ministère trouvé'
                  : 'Aucun ministère disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Essayez avec d\'autres termes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.account_balance,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                _getMinisteriosTitle(currentLang),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
              const Spacer(),
              if (_searchController.text.isNotEmpty)
                Text(
                  '${_filteredMinisterios.length} résultat${_filteredMinisterios.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),

        // Liste des ministères
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _filteredMinisterios.length,
            itemBuilder: (context, index) {
              final ministerio = _filteredMinisterios[index];
              return _buildMinisterioCard(ministerio, currentLang, isRtl);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMinisterioCard(Ministerio ministerio, String currentLang, bool isRtl) {
    final ministerioName = ministerio.getNombre(currentLang);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToMinisterio(ministerio),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône du ministère
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Nom du ministère
              Expanded(
                child: Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      ministerioName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _getSectorCount(ministerio.id),
                      builder: (context, snapshot) {
                        final sectorCount = snapshot.data ?? 0;
                        return Text(
                          '$sectorCount secteur${sectorCount > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Flèche de navigation
              Icon(
                isRtl ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _getSectorCount(String ministerioId) async {
    try {
      final sectors = await DatabaseService().sectorDao.getByMinisterioId(ministerioId);
      return sectors.length;
    } catch (e) {
      return 0;
    }
  }

  String _getWelcomeText(String currentLang) {
    switch (currentLang) {
      case 'es':
        return '¡Bienvenido a TaxasGE!';
      case 'fr':
        return 'Bienvenue à TaxasGE !';
      case 'en':
        return 'Welcome to TaxasGE!';
      default:
        return '¡Bienvenido a TaxasGE!';
    }
  }

  String _getSearchHint(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Buscar una tasa o palabra clave...';
      case 'fr':
        return 'Rechercher une taxe ou un mot-clé...';
      case 'en':
        return 'Search for a tax or keyword...';
      default:
        return 'Buscar una tasa o palabra clave...';
    }
  }

  String _getMinisteriosTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Ministerios';
      case 'fr':
        return 'Ministères';
      case 'en':
        return 'Ministries';
      default:
        return 'Ministerios';
    }
  }
}