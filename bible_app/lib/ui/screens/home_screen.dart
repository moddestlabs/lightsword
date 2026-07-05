import 'package:flutter/material.dart';
import 'dart:async';
import 'reader_screen.dart';
import 'study_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import '../widgets/pwa_widgets.dart';
import 'package:bible_app/services/deep_linking_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription<NavigationRequest>? _navigationSubscription;
  final GlobalKey<ReaderScreenState> _readerKey = GlobalKey<ReaderScreenState>();

  @override
  void initState() {
    super.initState();
    _listenToNavigationRequests();
    
    // Check for initial navigation request from URL params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialRequest = DeepLinkingService.instance.consumeInitialRequest();
      if (initialRequest != null) {
        _handleNavigationRequest(initialRequest);
      }
    });
  }

  void _listenToNavigationRequests() {
    _navigationSubscription = DeepLinkingService.instance.navigationStream.listen((request) {
      _handleNavigationRequest(request);
    });
  }

  void _handleNavigationRequest(NavigationRequest request) {
    // Switch to reader screen
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    }
    
    // Navigate to the requested passage
    // Use addPostFrameCallback to ensure the reader screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readerKey.currentState?.navigateToReference(
        request.reference,
        viewMode: request.viewMode,
      );
    });
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }

  List<Widget> _buildScreens() {
    return [
      ReaderScreen(key: _readerKey),
      const StudyScreen(),
      const LibraryScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const PwaBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _buildScreens(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Read',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Study',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
