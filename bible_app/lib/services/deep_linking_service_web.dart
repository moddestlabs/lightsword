library deep_linking_service_web;

/// Web-specific implementation for URL parameter handling
/// This file is used only when running on web
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Get current URL parameters
Map<String, String> getWebUrlParameters() {
  final uri = Uri.parse(web.window.location.href);
  return uri.queryParameters;
}

/// Listen to URL changes (popstate event for browser back/forward)
void listenToWebUrlChanges(Function(dynamic) callback) {
  web.window.addEventListener('popstate', ((web.Event event) {
    // URL changed via browser navigation
    final params = getWebUrlParameters();
    callback(params);
  }).toJS);
}

/// Update browser URL without reloading the page
void updateBrowserUrl(Map<String, String> params) {
  final currentUri = Uri.parse(web.window.location.href);
  
  // Build new URL with updated query parameters
  final newUri = currentUri.replace(queryParameters: params.isNotEmpty ? params : null);
  
  // Use pushState to update URL without reload
  web.window.history.pushState(
    null,
    '',
    newUri.toString(),
  );
}
