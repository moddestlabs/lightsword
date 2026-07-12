import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/screens/home_screen.dart';
import 'services/tts_service.dart';
import 'services/pwa_service.dart';
import 'services/deep_linking_service.dart';
import 'services/bible_service.dart';
import 'services/preferences_service.dart';
import 'state/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize preferences service
  await PreferencesService.instance.initialize();
  
  // Initialize TTS service
  await TtsService.instance.initialize();

  // Initialize primary text source
  await BibleService.initialize();
  
  // Initialize PWA service (web only)
  if (kIsWeb) {
    await PwaService.instance.initialize();
  }
  
  // Initialize deep linking service
  await DeepLinkingService.instance.initialize();
  
  runApp(const LightswordApp());
}

class LightswordApp extends StatelessWidget {
  const LightswordApp({super.key});

  ThemeData _buildTheme({
    required ThemeProvider themeProvider,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeProvider.seedColor,
      brightness: brightness,
      contrastLevel: themeProvider.palette.contrastLevel,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );

    const fallbackFonts = <String>['NotoSansHebrew', 'NotoRashiHebrew'];

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Cardo',
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Cardo',
        fontFamilyFallback: fallbackFonts,
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamily: 'Cardo',
        fontFamilyFallback: fallbackFonts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..initialize(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'LIGHTSWORD',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildTheme(
              themeProvider: themeProvider,
              brightness: Brightness.light,
            ),
            darkTheme: _buildTheme(
              themeProvider: themeProvider,
              brightness: Brightness.dark,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
