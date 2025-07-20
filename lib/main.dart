import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/localization_service.dart';
import 'database/database_service.dart';
import 'services/chatbot_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/chatbot_screen.dart';

void main() {
  runApp(const TaxasGEApp());
}

class TaxasGEApp extends StatefulWidget {
  const TaxasGEApp({super.key});

  @override
  State<TaxasGEApp> createState() => _TaxasGEAppState();
}

class _TaxasGEAppState extends State<TaxasGEApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await LocalizationService.instance.initialize();
    await DatabaseService().initialize(seedData: true);
    await ChatbotService.instance.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.eco,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Initialisation de TaxasGE...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: LocalizationService.instance),
        ChangeNotifierProvider.value(value: ChatbotService.instance),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(localizationService.currentLanguage),
            supportedLocales: AppTheme.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme:
                AppTheme.getLocalizedTheme(localizationService.currentLanguage),
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavigationTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final currentLang = localizationService.currentLanguage;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          const HomeScreen(),
          const SearchTabScreen(),
          const FavoritesScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationTapped,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            activeIcon: const Icon(Icons.home),
            label: _getTabLabel('home', currentLang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            activeIcon: const Icon(Icons.search),
            label: _getTabLabel('search', currentLang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            activeIcon: const Icon(Icons.favorite),
            label: _getTabLabel('favorites', currentLang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: _getTabLabel('profile', currentLang),
          ),
        ],
      ),
    );
  }

  String _getTabLabel(String tab, String currentLang) {
    final labels = {
      'home': {
        'es': 'Inicio',
        'fr': 'Accueil',
        'en': 'Home',
      },
      'search': {
        'es': 'Buscar',
        'fr': 'Rechercher',
        'en': 'Search',
      },
      'favorites': {
        'es': 'Favoritos',
        'fr': 'Favoris',
        'en': 'Favorites',
      },
      'profile': {
        'es': 'Perfil',
        'fr': 'Profil',
        'en': 'Profile',
      },
    };

    return labels[tab]?[currentLang] ?? labels[tab]?['es'] ?? tab;
  }
}

// Écran temporaire pour l'onglet Recherche
class SearchTabScreen extends StatefulWidget {
  const SearchTabScreen({super.key});

  @override
  State<SearchTabScreen> createState() => _SearchTabScreenState();
}

class _SearchTabScreenState extends State<SearchTabScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(searchQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final currentLang = localizationService.currentLanguage;
    final isRtl = localizationService.isRtl(currentLang);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getSearchTitle(currentLang)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Champ de recherche principal
            TextField(
              controller: _searchController,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: _getSearchHint(currentLang),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
            ),

            const SizedBox(height: 24),

            // Bouton de recherche
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _searchController.text.trim().isNotEmpty
                    ? _performSearch
                    : null,
                icon: const Icon(Icons.search),
                label: Text(_getSearchButtonText(currentLang)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Section des recherches suggérées ou récentes
            Text(
              _getSuggestionsTitle(currentLang),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Suggestions de recherche
            Expanded(
              child: ListView(
                children: [
                  _buildSuggestionTile(context, 'Passeport', Icons.credit_card),
                  _buildSuggestionTile(
                      context, 'Permis de conduire', Icons.drive_eta),
                  _buildSuggestionTile(context, 'Certificat de naissance',
                      Icons.baby_changing_station),
                  _buildSuggestionTile(context, 'Visa', Icons.flight_takeoff),
                  _buildSuggestionTile(
                      context, 'Carte d\'identité', Icons.badge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(
      BuildContext context, String suggestion, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(suggestion),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SearchResultsScreen(searchQuery: suggestion),
            ),
          );
        },
      ),
    );
  }

  String _getSearchTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Búsqueda Avanzada';
      case 'fr':
        return 'Recherche Avancée';
      case 'en':
        return 'Advanced Search';
      default:
        return 'Búsqueda Avanzada';
    }
  }

  String _getSearchHint(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Buscar tasas, documentos, procedimientos...';
      case 'fr':
        return 'Rechercher taxes, documents, procédures...';
      case 'en':
        return 'Search taxes, documents, procedures...';
      default:
        return 'Buscar tasas, documentos, procedimientos...';
    }
  }

  String _getSearchButtonText(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Buscar';
      case 'fr':
        return 'Rechercher';
      case 'en':
        return 'Search';
      default:
        return 'Buscar';
    }
  }

  String _getSuggestionsTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Búsquedas Populares';
      case 'fr':
        return 'Recherches Populaires';
      case 'en':
        return 'Popular Searches';
      default:
        return 'Búsquedas Populares';
    }
  }
}

// Écran temporaire pour les Favoris
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final currentLang = localizationService.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getFavoritesTitle(currentLang)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Favoris'),
                  content:
                      const Text('Fonctionnalité en cours de développement'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getFavoritesEmptyMessage(currentLang),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getFavoritesEmptySubtitle(currentLang),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getFavoritesTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Favoritos';
      case 'fr':
        return 'Favoris';
      case 'en':
        return 'Favorites';
      default:
        return 'Favoritos';
    }
  }

  String _getFavoritesEmptyMessage(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'No tienes favoritos aún';
      case 'fr':
        return 'Vous n\'avez pas encore de favoris';
      case 'en':
        return 'You don\'t have any favorites yet';
      default:
        return 'No tienes favoritos aún';
    }
  }

  String _getFavoritesEmptySubtitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Agrega tasas a favoritos para acceder rápidamente';
      case 'fr':
        return 'Ajoutez des taxes aux favoris pour un accès rapide';
      case 'en':
        return 'Add taxes to favorites for quick access';
      default:
        return 'Agrega tasas a favoritos para acceder rápidamente';
    }
  }
}

// Écran temporaire pour le Profil
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    final currentLang = localizationService.currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getProfileTitle(currentLang)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar et nom
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nombre Apellido',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Options du profil
          _buildProfileOption(
            context,
            Icons.bookmark,
            _getFavoritesTitle(currentLang),
            () {
              // Navigation vers les favoris
              DefaultTabController.of(context)?.animateTo(2);
            },
          ),
          _buildProfileOption(
            context,
            Icons.language,
            _getLanguageTitle(currentLang),
            () =>
                _showLanguageDialog(context, localizationService, currentLang),
          ),
          _buildProfileOption(
            context,
            Icons.cloud_sync,
            _getSyncTitle(currentLang),
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_getSyncMessage(currentLang))),
              );
            },
          ),
          _buildProfileOption(
            context,
            Icons.help_outline,
            _getHelpTitle(currentLang),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotScreen()),
              );
            },
          ),
          _buildProfileOption(
            context,
            Icons.info_outline,
            _getAboutTitle(currentLang),
            () => _showAboutDialog(context, currentLang),
          ),

          const SizedBox(height: 32),

          // Version
          Center(
            child: Text(
              'Version 1.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context,
      LocalizationService localizationService, String currentLang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getLanguageTitle(currentLang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: currentLang,
              onChanged: (value) {
                if (value != null) {
                  localizationService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: currentLang,
              onChanged: (value) {
                if (value != null) {
                  localizationService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLang,
              onChanged: (value) {
                if (value != null) {
                  localizationService.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, String currentLang) {
    showAboutDialog(
      context: context,
      applicationName: 'TaxasGE',
      applicationVersion: '1.0',
      applicationIcon: Icon(
        Icons.eco,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        Text(_getAboutDescription(currentLang)),
      ],
    );
  }

  // Méthodes de localisation pour ProfileScreen
  String _getProfileTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Perfil del Usuario';
      case 'fr':
        return 'Profil Utilisateur';
      case 'en':
        return 'User Profile';
      default:
        return 'Perfil del Usuario';
    }
  }

  String _getFavoritesTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Favoritos';
      case 'fr':
        return 'Favoris';
      case 'en':
        return 'Favorites';
      default:
        return 'Favoritos';
    }
  }

  String _getLanguageTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Idioma';
      case 'fr':
        return 'Langue';
      case 'en':
        return 'Language';
      default:
        return 'Idioma';
    }
  }

  String _getSyncTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Sincronización de datos';
      case 'fr':
        return 'Synchronisation des données';
      case 'en':
        return 'Data Sync';
      default:
        return 'Sincronización de datos';
    }
  }

  String _getHelpTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Contacto / Soporte';
      case 'fr':
        return 'Contact / Support';
      case 'en':
        return 'Contact / Support';
      default:
        return 'Contacto / Soporte';
    }
  }

  String _getAboutTitle(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Aviso legal y condiciones';
      case 'fr':
        return 'Mentions légales et conditions';
      case 'en':
        return 'Legal notice and conditions';
      default:
        return 'Aviso legal y condiciones';
    }
  }

  String _getSyncMessage(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'Sincronización completada';
      case 'fr':
        return 'Synchronisation terminée';
      case 'en':
        return 'Sync completed';
      default:
        return 'Sincronización completada';
    }
  }

  String _getAboutDescription(String currentLang) {
    switch (currentLang) {
      case 'es':
        return 'TaxasGE es una aplicación oficial para consultar tasas y procedimientos administrativos de Guinea Ecuatorial.';
      case 'fr':
        return 'TaxasGE est une application officielle pour consulter les taxes et procédures administratives de Guinée équatoriale.';
      case 'en':
        return 'TaxasGE is an official application to consult taxes and administrative procedures of Equatorial Guinea.';
      default:
        return 'TaxasGE es una aplicación oficial para consultar tasas y procedimientos administrativos de Guinea Ecuatorial.';
    }
  }
}
