import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxasge/main.dart';
import 'package:taxasge/services/localization_service.dart';
import 'package:taxasge/ml/model_service.dart';
import '../test/test_utils/test_config.dart';
import '../test/mocks/mock_nlp_services.dart';

void main() {
  group('TaxasGE Widget Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize test configuration
      await TestConfig.initialize();

      // Mock SharedPreferences for LocalizationService
      SharedPreferences.setMockInitialValues({
        'language_code': 'es', // Default language
      });

      // Inject mock ModelService to avoid real NLP model initialization
      ModelService.setTestInstance(mockModelService);
    });

    testWidgets('App initializes and shows loading screen',
        (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const TaxasGEApp());

      // Initially, we should see the loading screen
      expect(find.text('Initialisation de TaxasGE...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget); // App icon
    });

    testWidgets('App completes initialization and shows main navigation',
        (WidgetTester tester) async {
      // Build our app and wait for initialization to complete
      await tester.pumpWidget(const TaxasGEApp());

      // Wait for initialization to complete (should take a few seconds max)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // After initialization, we should see the main navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Check that all navigation tabs are present
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Favoritos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // Check that we start on the home tab
      final BottomNavigationBar bottomNav =
          tester.widget(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('Home screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check that the home screen elements are present
      expect(find.text('TaxasGE'), findsOneWidget); // AppBar title
      expect(
          find.byIcon(Icons.search), findsOneWidget); // Search icon in AppBar
      expect(find.byIcon(Icons.language), findsOneWidget); // Language selector

      // Check welcome text (should be in Spanish by default)
      expect(find.text('¡Bienvenido a TaxasGE!'), findsOneWidget);

      // Check search field
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Buscar una tasa o palabra clave...'), findsOneWidget);

      // Check ministries section title
      expect(find.text('Ministerios'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsWidgets);
    });

    testWidgets('Bottom navigation works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap on Search tab
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      // Should show search screen
      expect(find.text('Búsqueda Avanzada'), findsOneWidget);
      expect(find.text('Búsquedas Populares'), findsOneWidget);

      // Tap on Favorites tab
      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();

      // Should show favorites screen
      expect(find.text('No tienes favoritos aún'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // Tap on Profile tab
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      // Should show profile screen
      expect(find.text('Perfil del Usuario'), findsOneWidget);
      expect(find.text('Nombre Apellido'), findsOneWidget);
      expect(find.text('Version 1.0'), findsOneWidget);

      // Go back to Home tab
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      // Should be back to home screen
      expect(find.text('¡Bienvenido a TaxasGE!'), findsOneWidget);
    });

    testWidgets('Search functionality works from home screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find the search field on home screen
      final Finder searchField = find.byType(TextField).first;
      expect(searchField, findsOneWidget);

      // Enter text in search field
      await tester.enterText(searchField, 'passeport');
      await tester.pumpAndSettle();

      // Submit search
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Should navigate to SearchResultsScreen
      expect(find.text('Résultats de recherche'), findsOneWidget);
      expect(find.text('passeport'),
          findsWidgets); // Search query should be visible
    });

    testWidgets('Language selector works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap on language selector
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();

      // Should show language options
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Select French
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      // UI should update to French
      expect(find.text('Bienvenue à TaxasGE !'), findsOneWidget);
      expect(find.text('Rechercher une taxe ou un mot-clé...'), findsOneWidget);
      expect(find.text('Ministères'), findsOneWidget);

      // Bottom navigation should also be in French
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Rechercher'), findsOneWidget);
      expect(find.text('Favoris'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Search suggestions work correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Go to search tab
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      // Should see search suggestions
      expect(find.text('Passeport'), findsOneWidget);
      expect(find.text('Permis de conduire'), findsOneWidget);
      expect(find.text('Certificat de naissance'), findsOneWidget);

      // Tap on a suggestion
      await tester.tap(find.text('Passeport'));
      await tester.pumpAndSettle();

      // Should navigate to search results
      expect(find.text('Résultats de recherche'), findsOneWidget);
      expect(find.text('Passeport'), findsWidgets);
    });

    testWidgets('Profile screen functionality works',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Go to profile tab
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();

      // Test language change from profile
      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      // Should show language dialog
      expect(find.text('Español'), findsWidgets);
      expect(find.text('Français'), findsWidgets);
      expect(find.text('English'), findsWidgets);

      // Select English
      await tester.tap(
          find.text('English').last); // Last one in case there are multiple
      await tester.pumpAndSettle();

      // Profile should now be in English
      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // Test sync functionality
      await tester.tap(find.text('Data Sync'));
      await tester.pumpAndSettle();

      // Should show sync message
      expect(find.text('Sync completed'), findsOneWidget);
    });

    testWidgets('Error handling works correctly', (WidgetTester tester) async {
      // Test with a corrupted test configuration to simulate errors
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          // Simulate asset loading failure
          throw PlatformException(
            code: 'AssetNotFound',
            message: 'Test asset not found',
          );
        },
      );

      await tester.pumpWidget(const TaxasGEApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should still show some UI (initialization might fail gracefully)
      // The exact behavior depends on how error handling is implemented
      expect(find.byType(Scaffold), findsWidgets);

      // Reset the mock for other tests
      await TestConfig.initialize();
    });
  });
}
