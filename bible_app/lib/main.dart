import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'ui/screens/home_screen.dart';
import 'services/tts_service.dart';
// import 'services/pwa_service.dart';  // Temporarily disabled - has dart:js compatibility issues
import 'services/deep_linking_service.dart';
import 'services/preferences_service.dart';
import 'state/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize preferences service
  await PreferencesService.instance.initialize();
  
  // Initialize TTS service
  await TtsService.instance.initialize();
  
  // Initialize PWA service (web only)
  // Temporarily disabled - has dart:js compatibility issues
  // if (kIsWeb) {
  //   await PwaService.instance.initialize();
  // }
  
  // Initialize deep linking service
  await DeepLinkingService.instance.initialize();
  
  runApp(const LightswordApp());
}

class LightswordApp extends StatelessWidget {
  const LightswordApp({super.key});

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
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF8B4513),
                brightness: Brightness.light,
              ),
              fontFamily: 'Georgia',
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF8B4513),
                brightness: Brightness.dark,
              ),
              fontFamily: 'Georgia',
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
