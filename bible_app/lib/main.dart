import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'ui/screens/home_screen.dart';
import 'services/tts_service.dart';
import 'services/pwa_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize TTS service
  await TtsService.instance.initialize();
  
  // Initialize PWA service (web only)
  if (kIsWeb) {
    await PwaService.instance.initialize();
  }
  
  runApp(const DabarApp());
}

class DabarApp extends StatelessWidget {
  const DabarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dabar',
      debugShowCheckedModeBanner: false,
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
  }
}
