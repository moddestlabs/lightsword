import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'test_assets.dart';

void main() {
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
