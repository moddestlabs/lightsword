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
  external JSPromise cacheOfflinePack(JSString packName);
  external JSPromise getOfflinePackStatus();
  external JSPromise getPwaDiagnostics();
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
  final Map<OfflinePackId, OfflinePackStatus> _offlinePackStatuses = {};

  final _installAvailableController = StreamController<void>.broadcast();
  final _appInstalledController = StreamController<void>.broadcast();
  final _onlineStatusController = StreamController<bool>.broadcast();
  final _offlinePackStatusController =
      StreamController<Map<OfflinePackId, OfflinePackStatus>>.broadcast();

  /// Stream of install availability events
  Stream<void> get installAvailableStream => _installAvailableController.stream;

  /// Stream of app installed events
  Stream<void> get appInstalledStream => _appInstalledController.stream;

  /// Stream of online/offline status changes
  Stream<bool> get onlineStatusStream => _onlineStatusController.stream;

  Stream<Map<OfflinePackId, OfflinePackStatus>> get offlinePackStatusStream =>
      _offlinePackStatusController.stream;

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

  Map<OfflinePackId, OfflinePackStatus> get offlinePackStatuses =>
      Map.unmodifiable(_offlinePackStatuses);

  Future<PwaDiagnostics?> getDiagnostics() async {
    if (!isWeb) {
      return null;
    }

    try {
      final api = _pwaApi;
      if (api == null) {
        return null;
      }

      final result = await api.getPwaDiagnostics().toDart;
      final diagnosticsObj = result as JSAny?;
      if (diagnosticsObj == null) {
        return null;
      }

      final optionalPacks = <String, OfflinePackStatus>{};
      final optionalPacksObj = _getProperty(diagnosticsObj, 'optionalPacks');
      if (optionalPacksObj != null) {
        for (final pack in _optionalPackNames.entries) {
          final rawStatus = _getProperty(optionalPacksObj, pack.value);
          if (rawStatus == null) {
            continue;
          }
          optionalPacks[pack.value] = OfflinePackStatus(
            totalFiles: (_getProperty(rawStatus, 'total') as JSNumber?)?.toDartInt ?? 0,
            cachedFiles: (_getProperty(rawStatus, 'cached') as JSNumber?)?.toDartInt ?? 0,
          );
        }
      }

      return PwaDiagnostics(
        timestamp: (_getProperty(diagnosticsObj, 'timestamp') as JSString?)?.toDart,
        online: (_getProperty(diagnosticsObj, 'online') as JSBoolean?)?.toDart ?? _isOnline,
        locationHref: (_getProperty(diagnosticsObj, 'locationHref') as JSString?)?.toDart,
        locationPathname: (_getProperty(diagnosticsObj, 'locationPathname') as JSString?)?.toDart,
        referrer: (_getProperty(diagnosticsObj, 'referrer') as JSString?)?.toDart,
        userAgent: (_getProperty(diagnosticsObj, 'userAgent') as JSString?)?.toDart,
        standalone: (_getProperty(diagnosticsObj, 'standalone') as JSBoolean?)?.toDart ?? false,
        displayModeStandalone: (_getProperty(diagnosticsObj, 'displayModeStandalone') as JSBoolean?)?.toDart ?? false,
        iosStandalone: (_getProperty(diagnosticsObj, 'iosStandalone') as JSBoolean?)?.toDart ?? false,
        baseHref: (_getProperty(diagnosticsObj, 'baseHref') as JSString?)?.toDart,
        serviceWorkerSupported: (_getProperty(diagnosticsObj, 'serviceWorkerSupported') as JSBoolean?)?.toDart ?? false,
        serviceWorkerController: (_getProperty(diagnosticsObj, 'serviceWorkerController') as JSBoolean?)?.toDart ?? false,
        serviceWorkerControllerScriptUrl: (_getProperty(diagnosticsObj, 'serviceWorkerControllerScriptUrl') as JSString?)?.toDart,
        serviceWorkerRegistrationScope: (_getProperty(diagnosticsObj, 'serviceWorkerRegistrationScope') as JSString?)?.toDart,
        serviceWorkerRegistrationActiveScriptUrl: (_getProperty(diagnosticsObj, 'serviceWorkerRegistrationActiveScriptUrl') as JSString?)?.toDart,
        serviceWorkerRegistrationInstallingScriptUrl: (_getProperty(diagnosticsObj, 'serviceWorkerRegistrationInstallingScriptUrl') as JSString?)?.toDart,
        serviceWorkerRegistrationWaitingScriptUrl: (_getProperty(diagnosticsObj, 'serviceWorkerRegistrationWaitingScriptUrl') as JSString?)?.toDart,
        serviceWorkerRegistrationActiveState: (_getProperty(diagnosticsObj, 'serviceWorkerRegistrationActiveState') as JSString?)?.toDart,
        cacheKeys: _toStringList(_getProperty(diagnosticsObj, 'cacheKeys')),
        shellStatus: _parseOfflinePackStatus(_getProperty(diagnosticsObj, 'shell')),
        defaultPackStatus: _parseOfflinePackStatus(_getProperty(diagnosticsObj, 'defaultPack')),
        optionalPacks: optionalPacks,
        launchProbes: _parseLaunchProbes(_getProperty(diagnosticsObj, 'launchProbes')),
        bootStatus: (_getProperty(diagnosticsObj, 'bootStatus') as JSString?)?.toDart,
        bootLastDetail: (_getProperty(diagnosticsObj, 'bootLastDetail') as JSString?)?.toDart,
        bootLastUpdated: (_getProperty(diagnosticsObj, 'bootLastUpdated') as JSString?)?.toDart,
        bootLastFailure: _parseBootFailure(_getProperty(diagnosticsObj, 'bootLastFailure')),
        bootEvents: _toStringList(_getProperty(diagnosticsObj, 'bootEvents')),
        previousBootStatus: (_getProperty(diagnosticsObj, 'previousBootStatus') as JSString?)?.toDart,
        previousBootLastDetail: (_getProperty(diagnosticsObj, 'previousBootLastDetail') as JSString?)?.toDart,
        previousBootLastUpdated: (_getProperty(diagnosticsObj, 'previousBootLastUpdated') as JSString?)?.toDart,
        previousBootLastFailure: _parseBootFailure(_getProperty(diagnosticsObj, 'previousBootLastFailure')),
        previousBootEvents: _toStringList(_getProperty(diagnosticsObj, 'previousBootEvents')),
        errors: _toStringList(_getProperty(diagnosticsObj, 'errors')),
      );
    } catch (e) {
      print('❌ Error retrieving PWA diagnostics: $e');
      return null;
    }
  }

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
      await refreshOfflinePackStatus();
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

  Future<OfflinePackOperationResult> cacheOfflinePack(OfflinePackId packId) async {
    if (!isWeb) {
      return const OfflinePackOperationResult(
        ok: false,
        cachedCount: 0,
        error: 'not_web',
      );
    }

    try {
      final api = _pwaApi;
      if (api == null) {
        return const OfflinePackOperationResult(
          ok: false,
          cachedCount: 0,
          error: 'pwa_unavailable',
        );
      }

      final result = await api.cacheOfflinePack(_packName(packId).toJS).toDart;
      final resultObj = result as JSAny?;
      final operation = OfflinePackOperationResult(
        ok: (_getProperty(resultObj!, 'ok') as JSBoolean?)?.toDart ?? false,
        cachedCount:
            (_getProperty(resultObj, 'cachedCount') as JSNumber?)?.toDartInt ?? 0,
        error: (_getProperty(resultObj, 'error') as JSString?)?.toDart,
      );

      await refreshOfflinePackStatus();
      return operation;
    } catch (e) {
      return OfflinePackOperationResult(
        ok: false,
        cachedCount: 0,
        error: e.toString(),
      );
    }
  }

  Future<Map<OfflinePackId, OfflinePackStatus>> refreshOfflinePackStatus() async {
    if (!isWeb) {
      return offlinePackStatuses;
    }

    try {
      final api = _pwaApi;
      if (api == null) {
        return offlinePackStatuses;
      }

      final result = await api.getOfflinePackStatus().toDart;
      final statusObj = result as JSAny?;
      if (statusObj == null) {
        return offlinePackStatuses;
      }

      _offlinePackStatuses.clear();
      for (final packId in OfflinePackId.values) {
        final rawPackStatus = _getProperty(statusObj, _packName(packId));
        if (rawPackStatus == null) {
          continue;
        }

        _offlinePackStatuses[packId] = OfflinePackStatus(
          totalFiles:
              (_getProperty(rawPackStatus, 'total') as JSNumber?)?.toDartInt ?? 0,
          cachedFiles:
              (_getProperty(rawPackStatus, 'cached') as JSNumber?)?.toDartInt ?? 0,
        );
      }

      _offlinePackStatusController.add(offlinePackStatuses);
    } catch (e) {
      print('❌ Error refreshing offline pack status: $e');
    }

    return offlinePackStatuses;
  }

  String _packName(OfflinePackId packId) {
    return _optionalPackNames[packId]!;
  }

  OfflinePackStatus? _parseOfflinePackStatus(JSAny? rawStatus) {
    if (rawStatus == null) {
      return null;
    }

    return OfflinePackStatus(
      totalFiles: (_getProperty(rawStatus, 'total') as JSNumber?)?.toDartInt ?? 0,
      cachedFiles: (_getProperty(rawStatus, 'cached') as JSNumber?)?.toDartInt ?? 0,
    );
  }

  List<String> _toStringList(JSAny? rawList) {
    if (rawList == null) {
      return const [];
    }

    try {
      final jsArray = rawList as JSArray<JSString?>;
      final values = <String>[];
      for (var index = 0; index < jsArray.length; index++) {
        final value = jsArray[index];
        if (value != null) {
          values.add(value.toDart);
        }
      }
      return values;
    } catch (_) {
      return const [];
    }
  }

  List<PwaLaunchProbe> _parseLaunchProbes(JSAny? rawList) {
    if (rawList == null) {
      return const [];
    }

    try {
      final jsArray = rawList as JSArray<JSAny?>;
      final probes = <PwaLaunchProbe>[];
      for (var index = 0; index < jsArray.length; index++) {
        final value = jsArray[index];
        if (value == null) {
          continue;
        }
        probes.add(
          PwaLaunchProbe(
            url: (_getProperty(value, 'url') as JSString?)?.toDart ?? 'unknown',
            anyCache: (_getProperty(value, 'anyCache') as JSBoolean?)?.toDart ?? false,
            shellCache: (_getProperty(value, 'shellCache') as JSBoolean?)?.toDart ?? false,
          ),
        );
      }
      return probes;
    } catch (_) {
      return const [];
    }
  }

  PwaBootFailure? _parseBootFailure(JSAny? rawFailure) {
    if (rawFailure == null) {
      return null;
    }

    return PwaBootFailure(
      step: (_getProperty(rawFailure, 'step') as JSString?)?.toDart ?? 'unknown',
      detail: (_getProperty(rawFailure, 'detail') as JSString?)?.toDart,
      at: (_getProperty(rawFailure, 'at') as JSString?)?.toDart,
    );
  }

  static const Map<OfflinePackId, String> _optionalPackNames = {
    OfflinePackId.originalLanguageOt: 'original-language-ot',
  };

  /// Dispose resources
  void dispose() {
    _installAvailableController.close();
    _appInstalledController.close();
    _onlineStatusController.close();
    _offlinePackStatusController.close();
  }
}

enum OfflinePackId {
  originalLanguageOt,
}

class OfflinePackDefinition {
  const OfflinePackDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sizeLabel,
  });

  final OfflinePackId id;
  final String title;
  final String subtitle;
  final String sizeLabel;
}

class OfflinePackStatus {
  const OfflinePackStatus({
    required this.totalFiles,
    required this.cachedFiles,
  });

  final int totalFiles;
  final int cachedFiles;

  bool get isInstalled => totalFiles > 0 && cachedFiles >= totalFiles;
  bool get isPartial => cachedFiles > 0 && cachedFiles < totalFiles;

  String get summary => '$cachedFiles/$totalFiles files';
}

class OfflinePackOperationResult {
  const OfflinePackOperationResult({
    required this.ok,
    required this.cachedCount,
    this.error,
  });

  final bool ok;
  final int cachedCount;
  final String? error;
}

class PwaDiagnostics {
  const PwaDiagnostics({
    required this.timestamp,
    required this.online,
    required this.locationHref,
    required this.locationPathname,
    required this.referrer,
    required this.userAgent,
    required this.standalone,
    required this.displayModeStandalone,
    required this.iosStandalone,
    required this.baseHref,
    required this.serviceWorkerSupported,
    required this.serviceWorkerController,
    required this.serviceWorkerControllerScriptUrl,
    required this.serviceWorkerRegistrationScope,
    required this.serviceWorkerRegistrationActiveScriptUrl,
    required this.serviceWorkerRegistrationInstallingScriptUrl,
    required this.serviceWorkerRegistrationWaitingScriptUrl,
    required this.serviceWorkerRegistrationActiveState,
    required this.cacheKeys,
    required this.shellStatus,
    required this.defaultPackStatus,
    required this.optionalPacks,
    required this.launchProbes,
    required this.bootStatus,
    required this.bootLastDetail,
    required this.bootLastUpdated,
    required this.bootLastFailure,
    required this.bootEvents,
    required this.previousBootStatus,
    required this.previousBootLastDetail,
    required this.previousBootLastUpdated,
    required this.previousBootLastFailure,
    required this.previousBootEvents,
    required this.errors,
  });

  final String? timestamp;
  final bool online;
  final String? locationHref;
  final String? locationPathname;
  final String? referrer;
  final String? userAgent;
  final bool standalone;
  final bool displayModeStandalone;
  final bool iosStandalone;
  final String? baseHref;
  final bool serviceWorkerSupported;
  final bool serviceWorkerController;
  final String? serviceWorkerControllerScriptUrl;
  final String? serviceWorkerRegistrationScope;
  final String? serviceWorkerRegistrationActiveScriptUrl;
  final String? serviceWorkerRegistrationInstallingScriptUrl;
  final String? serviceWorkerRegistrationWaitingScriptUrl;
  final String? serviceWorkerRegistrationActiveState;
  final List<String> cacheKeys;
  final OfflinePackStatus? shellStatus;
  final OfflinePackStatus? defaultPackStatus;
  final Map<String, OfflinePackStatus> optionalPacks;
  final List<PwaLaunchProbe> launchProbes;
  final String? bootStatus;
  final String? bootLastDetail;
  final String? bootLastUpdated;
  final PwaBootFailure? bootLastFailure;
  final List<String> bootEvents;
  final String? previousBootStatus;
  final String? previousBootLastDetail;
  final String? previousBootLastUpdated;
  final PwaBootFailure? previousBootLastFailure;
  final List<String> previousBootEvents;
  final List<String> errors;

  String toDebugReport() {
    final buffer = StringBuffer()
      ..writeln('LIGHTSWORD PWA Diagnostics')
      ..writeln('timestamp: ${timestamp ?? 'unknown'}')
      ..writeln('online: $online')
      ..writeln('standalone: $standalone')
      ..writeln('displayModeStandalone: $displayModeStandalone')
      ..writeln('iosStandalone: $iosStandalone')
      ..writeln('locationHref: ${locationHref ?? 'unknown'}')
      ..writeln('locationPathname: ${locationPathname ?? 'unknown'}')
      ..writeln('baseHref: ${baseHref ?? 'unknown'}')
      ..writeln('referrer: ${referrer ?? 'unknown'}')
      ..writeln('serviceWorkerSupported: $serviceWorkerSupported')
      ..writeln('serviceWorkerController: $serviceWorkerController')
      ..writeln('controllerScriptUrl: ${serviceWorkerControllerScriptUrl ?? 'none'}')
      ..writeln('registrationScope: ${serviceWorkerRegistrationScope ?? 'none'}')
      ..writeln('registrationActiveScriptUrl: ${serviceWorkerRegistrationActiveScriptUrl ?? 'none'}')
      ..writeln('registrationInstallingScriptUrl: ${serviceWorkerRegistrationInstallingScriptUrl ?? 'none'}')
      ..writeln('registrationWaitingScriptUrl: ${serviceWorkerRegistrationWaitingScriptUrl ?? 'none'}')
      ..writeln('registrationActiveState: ${serviceWorkerRegistrationActiveState ?? 'none'}')
      ..writeln('bootStatus: ${bootStatus ?? 'unknown'}')
      ..writeln('bootLastDetail: ${bootLastDetail ?? 'none'}')
      ..writeln('bootLastUpdated: ${bootLastUpdated ?? 'none'}')
      ..writeln('shellStatus: ${shellStatus?.summary ?? 'none'}')
      ..writeln('defaultPackStatus: ${defaultPackStatus?.summary ?? 'none'}');

    if (bootLastFailure != null) {
      buffer.writeln('bootLastFailure: ${bootLastFailure!.summary}');
    }
    if (previousBootStatus != null || previousBootLastFailure != null) {
      buffer.writeln('previousBootStatus: ${previousBootStatus ?? 'unknown'}');
      buffer.writeln('previousBootLastDetail: ${previousBootLastDetail ?? 'none'}');
      buffer.writeln('previousBootLastUpdated: ${previousBootLastUpdated ?? 'none'}');
      if (previousBootLastFailure != null) {
        buffer.writeln('previousBootLastFailure: ${previousBootLastFailure!.summary}');
      }
    }

    for (final entry in optionalPacks.entries) {
      buffer.writeln('${entry.key}: ${entry.value.summary}');
    }

    for (final probe in launchProbes) {
      buffer.writeln(
        'launchProbe: ${probe.url} | shellCache=${probe.shellCache} | anyCache=${probe.anyCache}',
      );
    }

    for (final event in bootEvents) {
      buffer.writeln('bootEvent: $event');
    }
    for (final event in previousBootEvents) {
      buffer.writeln('previousBootEvent: $event');
    }

    buffer.writeln('cacheKeys: ${cacheKeys.join(', ')}');
    if (errors.isNotEmpty) {
      buffer.writeln('errors: ${errors.join(' | ')}');
    }
    if (userAgent != null && userAgent!.isNotEmpty) {
      buffer.writeln('userAgent: $userAgent');
    }
    return buffer.toString();
  }
}

class PwaLaunchProbe {
  const PwaLaunchProbe({
    required this.url,
    required this.anyCache,
    required this.shellCache,
  });

  final String url;
  final bool anyCache;
  final bool shellCache;
}

class PwaBootFailure {
  const PwaBootFailure({
    required this.step,
    required this.detail,
    required this.at,
  });

  final String step;
  final String? detail;
  final String? at;

  String get summary => '$step${detail == null || detail!.isEmpty ? '' : ' (${detail!})'}${at == null || at!.isEmpty ? '' : ' @ $at'}';
}

const List<OfflinePackDefinition> offlinePackDefinitions = [
  OfflinePackDefinition(
    id: OfflinePackId.originalLanguageOt,
    title: 'Original Language OT',
    subtitle: 'TAHOT Hebrew OT pack for offline Torah, Prophets, and Writings.',
    sizeLabel: '34.45 MB',
  ),
];

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
