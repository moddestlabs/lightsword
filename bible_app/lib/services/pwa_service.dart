import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;

/// JS interop extensions
extension JSAnyExtension on JSAny {
  external JSAny? operator [](String property);
  external bool hasOwnProperty(String property);
}

@JS('window.lightswordPwa')
external JSAny? get _lightswordPwa;

@JS('window.addEventListener')
external void _addEventListener(String event, JSFunction handler);

@JS()
@staticInterop
class _PwaApi {}

extension _PwaApiExtension on _PwaApi {
  external JSPromise showInstallPrompt();
  external JSPromise getStorageEstimate();
}

_PwaApi? get _pwaApi => _lightswordPwa as _PwaApi?;

bool _hasProperty(JSAny obj, String prop) {
  try {
    return obj.hasOwnProperty(prop);
  } catch (e) {
    return false;
  }
}

JSAny? _getProperty(JSAny obj, String prop) {
  try {
    return obj[prop];
  } catch (e) {
    return null;
  }
}

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
      
      _addEventListener(
        'lightsword-pwa-ready',
        ((web.Event event) {
          _handlePwaReady();
          completer.complete();
        }).toJS,
      );

      // Set up event listeners
      _setupEventListeners();

      // Check if already initialized
      if (_lightswordPwa != null) {
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
      final pwa = _lightswordPwa;
      if (pwa == null) return;

      // Parse platform info
      final platformObj = _getProperty(pwa, 'platform');
      if (platformObj != null) {
        _platformInfo = PlatformInfo(
          isIOS: (_getProperty(platformObj, 'ios') as JSBoolean?)?.toDart ?? false,
          isAndroid: (_getProperty(platformObj, 'android') as JSBoolean?)?.toDart ?? false,
          isMobile: (_getProperty(platformObj, 'mobile') as JSBoolean?)?.toDart ?? false,
          isStandalone: (_getProperty(platformObj, 'standalone') as JSBoolean?)?.toDart ?? false,
        );
        _isInstalled = _platformInfo!.isStandalone;
        _isInstallable = (_getProperty(platformObj, 'installable') as JSBoolean?)?.toDart ?? false;
      }

      // Parse TTS info
      final ttsObj = _getProperty(pwa, 'tts');
      if (ttsObj != null) {
        _ttsInfo = TtsInfo(
          supported: (_getProperty(ttsObj, 'supported') as JSBoolean?)?.toDart ?? false,
          hasHebrew: (_getProperty(ttsObj, 'hasHebrew') as JSBoolean?)?.toDart ?? false,
          hasGreek: (_getProperty(ttsObj, 'hasGreek') as JSBoolean?)?.toDart ?? false,
          voiceCount: (_getProperty(ttsObj, 'voiceCount') as JSNumber?)?.toDartInt ?? 0,
        );
      }

      // Parse storage info
      final storageObj = _getProperty(pwa, 'storage');
      if (storageObj != null) {
        final estimateObj = _getProperty(storageObj, 'estimate');
        _storageInfo = StorageInfo(
          persisted: (_getProperty(storageObj, 'persisted') as JSBoolean?)?.toDart ?? false,
          usage: estimateObj != null ? ((_getProperty(estimateObj, 'usage') as JSNumber?)?.toDartInt ?? 0) : 0,
          quota: estimateObj != null ? ((_getProperty(estimateObj, 'quota') as JSNumber?)?.toDartInt ?? 0) : 0,
          percentUsed: estimateObj != null ? ((_getProperty(estimateObj, 'percentUsed') as JSNumber?)?.toDartDouble ?? 0.0) : 0.0,
        );
      }

      print('📱 Platform: $_platformInfo');
      print('🔊 TTS: $_ttsInfo');
      print('🗄️ Storage: $_storageInfo');
    } catch (e) {
      print('❌ Error parsing PWA info: $e');
    }
  }

  void _setupEventListeners() {
    // Install available
    _addEventListener(
      'lightsword-install-available',
      ((web.Event event) {
        _isInstallable = true;
        _installAvailableController.add(null);
        print('📱 Install prompt available');
      }).toJS,
    );

    // App installed
    _addEventListener(
      'lightsword-app-installed',
      ((web.Event event) {
        _isInstalled = true;
        _isInstallable = false;
        _appInstalledController.add(null);
        print('✅ App installed');
      }).toJS,
    );

    // Online
    _addEventListener(
      'lightsword-online',
      ((web.Event event) {
        _isOnline = true;
        _onlineStatusController.add(true);
        print('🌐 Online');
      }).toJS,
    );

    // Offline
    _addEventListener(
      'lightsword-offline',
      ((web.Event event) {
        _isOnline = false;
        _onlineStatusController.add(false);
        print('📡 Offline');
      }).toJS,
    );
  }

  /// Show install prompt to user
  Future<bool> showInstallPrompt() async {
    if (!isWeb || !_isInstallable) {
      print('ℹ️ Install prompt not available');
      return false;
    }

    try {
      final api = _pwaApi;
      if (api == null) return false;

      // Call the JS function and await result
      final result = await api.showInstallPrompt().toDart;
      final resultObj = result as JSAny?;
      
      return (_getProperty(resultObj!, 'accepted') as JSBoolean?)?.toDart ?? false;
    } catch (e) {
      print('❌ Error showing install prompt: $e');
      return false;
    }
  }

  /// Refresh storage estimate
  Future<StorageInfo?> refreshStorageEstimate() async {
    if (!isWeb) return null;

    try {
      final api = _pwaApi;
      if (api == null) return null;

      final result = await api.getStorageEstimate().toDart;
      final estimate = result as JSAny?;

      if (estimate != null) {
        _storageInfo = StorageInfo(
          persisted: _storageInfo?.persisted ?? false,
          usage: (_getProperty(estimate, 'usage') as JSNumber?)?.toDartInt ?? 0,
          quota: (_getProperty(estimate, 'quota') as JSNumber?)?.toDartInt ?? 0,
          percentUsed: (_getProperty(estimate, 'percentUsed') as JSNumber?)?.toDartDouble ?? 0.0,
        );
      }

      return _storageInfo;
    } catch (e) {
      print('❌ Error refreshing storage estimate: $e');
      return null;
    }
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
