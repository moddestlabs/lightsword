import 'package:flutter/material.dart';
import 'dart:async';
import 'reader_screen.dart';
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
      const LibraryScreen(),
      const SettingsScreen(),
    ];
  }

  void _setInterlinearMode() {
    // Always set to interlinear mode (not toggle)
    _readerKey.currentState?.setInterlinearMode();
  }

  void _setStandardMode() {
    // Always set to standard reading mode
    _readerKey.currentState?.setStandardMode();
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
        selectedIndex: _currentIndex == 0 ? 0 : _currentIndex + 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            // Read button - switch to standard mode and ensure we're on reader screen
            setState(() {
              _currentIndex = 0;
            });
            _setStandardMode();
            return;
          }
          if (index == 1) {
            // Study button - switch to interlinear mode and ensure we're on reader screen
            setState(() {
              _currentIndex = 0;
            });
            _setInterlinearMode();
            return;
          }
          // Adjust index for other screens (Library is now index 1, Settings is 2)
          setState(() {
            _currentIndex = index > 1 ? index - 1 : index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Read',
          ),
          NavigationDestination(
            icon: Icon(Icons.text_fields_outlined),
            selectedIcon: Icon(Icons.text_fields),
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
