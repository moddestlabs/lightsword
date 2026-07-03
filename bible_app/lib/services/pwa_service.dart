import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

/// PWA service for handling Progressive Web App features
/// Only functional on web platform
class PwaService {
  static final PwaService _instance = PwaService._internal();
  static PwaService get instance => _instance;

  PwaService._internal();

  bool _isInitialized = false;
  bool _isInstallable = false;
  bool _isInstalled = false;
  bool _isOnline = true;
  PlatformInfo? _platformInfo;
  TtsInfo? _ttsInfo;
  StorageInfo? _storageInfo;

  final _installAvailableController = StreamController<void>.broadcast();
  final _appInstalledController = StreamController<void>.broadcast();
  final _onlineStatusController = StreamController<bool>.broadcast();

  /// Stream of install availability events
  Stream<void> get installAvailableStream => _installAvailableController.stream;

  /// Stream of app installed events
  Stream<void> get appInstalledStream => _appInstalledController.stream;

  /// Stream of online/offline status changes
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;

  /// Check if running on web
  bool get isWeb => kIsWeb;

  /// Check if PWA features are available
  bool get isAvailable => isWeb && _isInitialized;

  /// Check if app can be installed
  bool get isInstallable => _isInstallable;

  /// Check if app is already installed
  bool get isInstalled => _isInstalled;

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Get platform information
  PlatformInfo? get platformInfo => _platformInfo;

  /// Get TTS information
  TtsInfo? get ttsInfo => _ttsInfo;

  /// Get storage information
  StorageInfo? get storageInfo => _storageInfo;

  /// Initialize PWA service
  Future<void> initialize() async {
    if (!kIsWeb) {
      print('ℹ️ PWA service only available on web platform');
      return;
    }

    try {
      // Wait for PWA initialization
      final completer = Completer<void>();
      
      js.context['addEventListener']?.apply([
        'dabar-pwa-ready',
        js.allowInterop((event) {
          _handlePwaReady();
          completer.complete();
        })
      ]);

      // Set up event listeners
      _setupEventListeners();

      // Check if already initialized
      if (js.context['dabarPwa'] != null) {
        _handlePwaReady();
        completer.complete();
      }

      // Wait for initialization with timeout
      await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ PWA initialization timeout - continuing anyway');
        },
      );

      _isInitialized = true;
      print('✅ PWA service initialized');
    } catch (e) {
      print('❌ Error initializing PWA service: $e');
    }
  }

  void _handlePwaReady() {
    try {
      final pwa = js.context['dabarPwa'];
      if (pwa == null) return;

      // Parse platform info
      final platform = pwa['platform'];
      if (platform != null) {
        _platformInfo = PlatformInfo(
          isIOS: platform['ios'] ?? false,
          isAndroid: platform['android'] ?? false,
          isMobile: platform['mobile'] ?? false,
          isStandalone: platform['standalone'] ?? false,
        );
        _isInstalled = _platformInfo!.isStandalone;
        _isInstallable = platform['installable'] ?? false;
      }

      // Parse TTS info
      final tts = pwa['tts'];
      if (tts != null) {
        _ttsInfo = TtsInfo(
          supported: tts['supported'] ?? false,
          hasHebrew: tts['hasHebrew'] ?? false,
          hasGreek: tts['hasGreek'] ?? false,
          voiceCount: tts['voiceCount'] ?? 0,
        );
      }

      // Parse storage info
      final storage = pwa['storage'];
      if (storage != null) {
        final estimate = storage['estimate'];
        _storageInfo = StorageInfo(
          persisted: storage['persisted'] ?? false,
          usage: estimate?['usage'] ?? 0,
          quota: estimate?['quota'] ?? 0,
          percentUsed: estimate?['percentUsed'] ?? 0.0,
        );
      }

      print('📱 Platform: ${_platformInfo}');
      print('🔊 TTS: ${_ttsInfo}');
      print('🗄️ Storage: ${_storageInfo}');
    } catch (e) {
      print('❌ Error parsing PWA info: $e');
    }
  }

  void _setupEventListeners() {
    // Install available
    js.context['addEventListener']?.apply([
      'dabar-install-available',
      js.allowInterop((event) {
        _isInstallable = true;
        _installAvailableController.add(null);
        print('📱 Install prompt available');
      })
    ]);

    // App installed
    js.context['addEventListener']?.apply([
      'dabar-app-installed',
      js.allowInterop((event) {
        _isInstalled = true;
        _isInstallable = false;
        _appInstalledController.add(null);
        print('✅ App installed');
      })
    ]);

    // Online
    js.context['addEventListener']?.apply([
      'dabar-online',
      js.allowInterop((event) {
        _isOnline = true;
        _onlineStatusController.add(true);
        print('🌐 Online');
      })
    ]);

    // Offline
    js.context['addEventListener']?.apply([
      'dabar-offline',
      js.allowInterop((event) {
        _isOnline = false;
        _onlineStatusController.add(false);
        print('📡 Offline');
      })
    ]);
  }

  /// Show install prompt to user
  Future<bool> showInstallPrompt() async {
    if (!isWeb || !_isInstallable) {
      print('ℹ️ Install prompt not available');
      return false;
    }

    try {
      final pwa = js.context['dabarPwa'];
      if (pwa == null) return false;

      final showPrompt = pwa['showInstallPrompt'];
      if (showPrompt == null) return false;

      // Call the JS function and await result
      final resultPromise = showPrompt.apply([]);
      final result = await _promiseToFuture(resultPromise);
      
      return result['accepted'] ?? false;
    } catch (e) {
      print('❌ Error showing install prompt: $e');
      return false;
    }
  }

  /// Refresh storage estimate
  Future<StorageInfo?> refreshStorageEstimate() async {
    if (!isWeb) return null;

    try {
      final pwa = js.context['dabarPwa'];
      if (pwa == null) return null;

      final getEstimate = pwa['getStorageEstimate'];
      if (getEstimate == null) return null;

      final resultPromise = getEstimate.apply([]);
      final estimate = await _promiseToFuture(resultPromise);

      if (estimate != null) {
        _storageInfo = StorageInfo(
          persisted: _storageInfo?.persisted ?? false,
          usage: estimate['usage'] ?? 0,
          quota: estimate['quota'] ?? 0,
          percentUsed: estimate['percentUsed'] ?? 0.0,
        );
      }

      return _storageInfo;
    } catch (e) {
      print('❌ Error refreshing storage estimate: $e');
      return null;
    }
  }

  /// Convert JS Promise to Dart Future
  Future<dynamic> _promiseToFuture(dynamic promise) {
    final completer = Completer<dynamic>();
    
    promise.callMethod('then', [
      js.allowInterop((result) {
        completer.complete(result);
      })
    ]).callMethod('catch', [
      js.allowInterop((error) {
        completer.completeError(error);
      })
    ]);
    
    return completer.future;
  }

  /// Dispose resources
  void dispose() {
    _installAvailableController.close();
    _appInstalledController.close();
    _onlineStatusController.close();
  }
}

/// Platform information
class PlatformInfo {
  final bool isIOS;
  final bool isAndroid;
  final bool isMobile;
  final bool isStandalone;

  PlatformInfo({
    required this.isIOS,
    required this.isAndroid,
    required this.isMobile,
    required this.isStandalone,
  });

  @override
  String toString() => 'PlatformInfo(iOS: $isIOS, Android: $isAndroid, Mobile: $isMobile, Standalone: $isStandalone)';
}

/// TTS support information
class TtsInfo {
  final bool supported;
  final bool hasHebrew;
  final bool hasGreek;
  final int voiceCount;

  TtsInfo({
    required this.supported,
    required this.hasHebrew,
    required this.hasGreek,
    required this.voiceCount,
  });

  String get supportSummary {
    if (!supported) return 'Not supported';
    final List<String> langs = [];
    if (hasHebrew) langs.add('Hebrew');
    if (hasGreek) langs.add('Greek');
    if (langs.isEmpty) return 'English only';
    return langs.join(', ') + ', English';
  }

  @override
  String toString() => 'TtsInfo(Supported: $supported, Voices: $voiceCount, Hebrew: $hasHebrew, Greek: $hasGreek)';
}

/// Storage information
class StorageInfo {
  final bool persisted;
  final int usage;
  final int quota;
  final double percentUsed;

  StorageInfo({
    required this.persisted,
    required this.usage,
    required this.quota,
    required this.percentUsed,
  });

  String get usageMB => (usage / 1024 / 1024).toStringAsFixed(2);
  String get quotaMB => (quota / 1024 / 1024).toStringAsFixed(2);

  @override
  String toString() => 'StorageInfo(Persisted: $persisted, Used: $usageMB MB / $quotaMB MB, ${percentUsed.toStringAsFixed(1)}%)';
}
