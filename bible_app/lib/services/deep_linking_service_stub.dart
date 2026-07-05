library deep_linking_service_stub;

/// Stub implementation for non-web platforms
/// This file is used when not running on web

/// Get URL parameters (stub - returns empty on native)
Map<String, String> getWebUrlParameters() {
  return {};
}

/// Listen to URL changes (stub - no-op on native)
void listenToWebUrlChanges(Function(dynamic) callback) {
  // No-op for native platforms
  // Native deep linking will use different mechanism (uni_links/app_links)
}

/// Update browser URL (stub - no-op on native)
void updateBrowserUrl(Map<String, String> params) {
  // No-op for native platforms
}
