import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/localization_service.dart';
import 'services/database_service.dart';
import 'services/chatbot_service.dart';
import 'theme/app_theme.dart';

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
    await DatabaseService.instance.initialize(seedData: true);
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
            theme: AppTheme.getLocalizedTheme(localizationService.currentLanguage),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('TaxasGE'),
              ),
              body: const Center(
                child: Text('Bienvenue à TaxasGE'),
              ),
            ),
          );
        },
      ),
    );
  }
}
