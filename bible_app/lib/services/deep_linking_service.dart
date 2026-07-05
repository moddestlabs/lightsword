import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_app/services/reference_parser.dart';
import 'package:bible_app/ui/models/view_mode.dart';

// Conditional imports for web-specific functionality
import 'deep_linking_service_stub.dart'
    if (dart.library.html) 'deep_linking_service_web.dart';

/// Request to navigate to a specific passage
class NavigationRequest {
  final PassageReference reference;
  final ViewMode? viewMode;
  final DateTime timestamp;

  NavigationRequest({
    required this.reference,
    this.viewMode,
  }) : timestamp = DateTime.now();
}

/// Service for handling deep links and URL parameters
/// Supports both web (URL params) and native (deep links)
class DeepLinkingService {
  static final DeepLinkingService _instance = DeepLinkingService._internal();
  static DeepLinkingService get instance => _instance;

  DeepLinkingService._internal();

  final StreamController<NavigationRequest> _navigationController =
      StreamController<NavigationRequest>.broadcast();

  /// Stream of navigation requests from deep links or URL changes
  Stream<NavigationRequest> get navigationStream => _navigationController.stream;

  bool _initialized = false;
  NavigationRequest? _initialRequest;

  /// Get and consume the initial navigation request (if any)
  /// This should be called once by the app after subscribing to navigationStream
  NavigationRequest? consumeInitialRequest() {
    final request = _initialRequest;
    _initialRequest = null; // Clear so it's only consumed once
    return request;
  }

  /// Initialize the deep linking service
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      await _initializeWeb();
    } else {
      // Native deep linking will be implemented here
      // TODO: Add uni_links or app_links package support
      _initializeNative();
    }
  }

  /// Initialize web-specific URL parameter handling
  Future<void> _initializeWeb() async {
    // Check initial URL on startup and cache it
    _initialRequest = await _checkWebUrl();

    // Listen for URL changes (browser back/forward)
    listenToWebUrlChanges((params) {
      final request = _parseUrlParameters(params);
      if (request != null) {
        _navigationController.add(request);
      }
    });
  }

  /// Initialize native deep linking (placeholder for future implementation)
  void _initializeNative() {
    // TODO: Implement with uni_links or app_links package
    // Example:
    // uriLinkStream.listen((uri) {
    //   if (uri != null) {
    //     final request = _parseNativeUri(uri);
    //     if (request != null) {
    //       _navigationController.add(request);
    //     }
    //   }
    // });
  }

  /// Check current web URL for navigation parameters
  Future<NavigationRequest?> _checkWebUrl() async {
    final params = getWebUrlParameters();
    return _parseUrlParameters(params);
  }

  /// Parse URL parameters into a navigation request
  NavigationRequest? _parseUrlParameters(Map<String, String> params) {
    final referenceStr = params['r'] ?? params['ref'];
    if (referenceStr == null || referenceStr.isEmpty) {
      return null;
    }

    final modeStr = params['mode'] ?? params['view'];
    final parsed = ReferenceParser.parseWithMode(referenceStr, modeStr);
    
    if (parsed == null) return null;

    return NavigationRequest(
      reference: parsed.reference,
      viewMode: parsed.viewMode,
    );
  }

  /// Parse native deep link URI (for future use)
  NavigationRequest? _parseNativeUri(Uri uri) {
    // Expected formats:
    // lightsword://gen1.4
    // lightsword://gen1.4?mode=interlinear
    // https://moddestlabs.github.io/lightsword?r=gen1.4
    
    String? referenceStr;
    String? modeStr;

    if (uri.queryParameters.containsKey('r') || uri.queryParameters.containsKey('ref')) {
      // URL with query parameters
      referenceStr = uri.queryParameters['r'] ?? uri.queryParameters['ref'];
      modeStr = uri.queryParameters['mode'] ?? uri.queryParameters['view'];
    } else if (uri.pathSegments.isNotEmpty) {
      // Path-based: lightsword://gen1.4
      referenceStr = uri.pathSegments.last;
      modeStr = uri.queryParameters['mode'];
    }

    if (referenceStr == null) return null;

    final parsed = ReferenceParser.parseWithMode(referenceStr, modeStr);
    if (parsed == null) return null;

    return NavigationRequest(
      reference: parsed.reference,
      viewMode: parsed.viewMode,
    );
  }

  /// Update browser URL without triggering navigation (web only)
  void updateWebUrl(PassageReference reference, ViewMode? viewMode) {
    if (!kIsWeb) return;

    final referenceStr = ReferenceParser.format(reference);
    final params = <String, String>{'r': referenceStr};
    
    if (viewMode != null && viewMode != ViewMode.standard) {
      params['mode'] = viewMode.name;
    }

    updateBrowserUrl(params);
  }

  /// Dispose resources
  void dispose() {
    _navigationController.close();
  }
}
