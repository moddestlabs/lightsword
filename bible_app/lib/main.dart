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
import 'state/font_size_provider.dart';

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
  
  runApp(const LightSwordApp());
}

class LightSwordApp extends StatelessWidget {
  const LightSwordApp({super.key});

  ThemeData _buildTheme({
    required ThemeProvider themeProvider,
    required String fontFamily,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: themeProvider.seedColor,
      brightness: brightness,
    );
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );

    const fallbackFonts = <String>['NotoSansHebrew', 'NotoRashiHebrew'];
    final activeFontFamily = fontFamily.isNotEmpty ? fontFamily : 'Cardo';

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: activeFontFamily,
      textTheme: baseTheme.textTheme.apply(
        fontFamily: activeFontFamily,
        fontFamilyFallback: fallbackFonts,
      ),
      primaryTextTheme: baseTheme.primaryTextTheme.apply(
        fontFamily: activeFontFamily,
        fontFamilyFallback: fallbackFonts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()..initialize()),
      ],
      child: Consumer2<ThemeProvider, FontSizeProvider>(
        builder: (context, themeProvider, fontSizeProvider, child) {
          return MaterialApp(
            title: 'LightSword',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildTheme(
              themeProvider: themeProvider,
              fontFamily: fontSizeProvider.fontFamily,
              brightness: Brightness.light,
            ),
            darkTheme: _buildTheme(
              themeProvider: themeProvider,
              fontFamily: fontSizeProvider.fontFamily,
              brightness: Brightness.dark,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
