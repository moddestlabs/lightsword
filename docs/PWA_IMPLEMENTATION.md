# PWA Implementation Guide

## Overview

LightSword is implemented as a Progressive Web App (PWA) with full offline support and installability on mobile devices. This document describes the PWA features and how they work.

## Features Implemented

### ✅ Core PWA Features

1. **Web App Manifest** ([web/manifest.json](../bible_app/web/manifest.json))
   - App metadata (name, description, theme colors)
   - App icons (192x192 and 512x512)
   - Standalone display mode (looks like native app)
   - App shortcuts for quick actions
   - Share target integration

2. **Service Worker** (Custom post-build worker)
   - Precaches the Flutter app shell for offline startup
   - Runtime-caches Bible content after it has been opened once
   - Automatic updates when new versions available

3. **Persistent Storage**
   - Requests persistent storage to prevent browser from clearing cache
   - Monitors storage usage and quota
   - Shows storage info in Settings

4. **Install Prompt**
   - Detects when app can be installed
   - Shows native install banner (Android/Chrome)
   - Provides iOS-specific instructions (Safari)
   - Can be dismissed and won't show again until next session

5. **Offline Detection**
   - Monitors network connectivity
   - Shows banner when offline
   - Indicates that app works fully offline with cached content

### 🔊 TTS Platform Detection

The PWA automatically detects TTS capabilities:

- **Web Speech API** support detection
- **Language availability** checking (Hebrew, Greek, English)
- **Voice counting** - shows how many voices installed
- **Warning indicators** when Hebrew/Greek not available

### 📱 Platform Awareness

The PWA knows its environment:

- **iOS vs Android vs Desktop** detection
- **Installed PWA vs Browser** distinction
- **Mobile vs Desktop** detection
- Platform-specific UI adaptations

## Architecture

### JavaScript Bridge ([web/pwa.js](../bible_app/web/pwa.js))

Handles browser-specific APIs that aren't available in Dart:

- `beforeinstallprompt` event capture
- Storage Persistence API
- Platform detection
- TTS capability checking
- Network status monitoring

Exposes `window.lightswordPwa` object with:
- `platform` - Platform information
- `storage` - Storage status and estimate
- `tts` - TTS support information
- `showInstallPrompt()` - Trigger install prompt
- `getStorageEstimate()` - Refresh storage info

### Dart PWA Service ([lib/services/pwa_service.dart](../bible_app/lib/services/pwa_service.dart))

Dart interface to JavaScript PWA features:

```dart
// Check if PWA features available
if (PwaService.instance.isWeb) {
  // Initialize PWA
  await PwaService.instance.initialize();
  
  // Check install status
  if (PwaService.instance.isInstallable) {
    await PwaService.instance.showInstallPrompt();
  }
  
  // Listen to events
  PwaService.instance.onlineStatusStream.listen((isOnline) {
    print('Network status: $isOnline');
  });
}
```

### UI Components ([lib/ui/widgets/pwa_widgets.dart](../bible_app/lib/ui/widgets/pwa_widgets.dart))

Three main widgets:

1. **`PwaBanner`** - Shows at top of app
   - Install prompt with platform-specific instructions
   - Offline indicator banner
   - Auto-dismissible

2. **`OfflineIndicator`** - Small icon for app bar
   - Shows cloud-off icon when offline
   - Unobtrusive persistent indicator

3. **`TtsCapabilityIndicator`** - Info card
   - Shows TTS language support status
   - Warns if Hebrew/Greek unavailable
   - Used in Settings screen

## Usage in App

### Main App ([lib/main.dart](../bible_app/lib/main.dart))

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize PWA on web platform
  if (kIsWeb) {
    await PwaService.instance.initialize();
  }
  
   runApp(const LightSwordApp());
}
```

### Home Screen ([lib/ui/screens/home_screen.dart](../bible_app/lib/ui/screens/home_screen.dart))

```dart
Scaffold(
  body: Column(
    children: [
      const PwaBanner(),  // Install prompt / offline indicator
      Expanded(child: /* main content */),
    ],
  ),
)
```

### Settings Screen ([lib/ui/screens/settings_screen.dart](../bible_app/lib/ui/screens/settings_screen.dart))

Shows:
- TTS capability indicator
- Platform information (installed PWA vs browser)
- Storage usage and persistence status
- Storage refresh button

## Platform-Specific Behavior

### iOS Safari

- **No native install prompt** - Must use Share > Add to Home Screen
- **Offline app shell** - Home-screen launch works offline after the first successful online load
- **Bible content is per-passage cached** - Open passages online once before expecting them offline
- **Storage is browser-managed** - Safari may evict cached data under storage pressure or prolonged inactivity
- **Status bar** - Black translucent style
- **Home screen icon** - Requires apple-touch-icon link

### Android Chrome

- **Native install prompt** - Banner with "Install" button
- **Unlimited storage** - With persistent storage granted
- **Full PWA features** - Best experience
- **App shortcuts** - Long-press icon shows shortcuts

### Desktop Browsers

- **Install available** - Chrome, Edge, Brave
- **Desktop app** - Opens in standalone window
- **Keyboard shortcuts** - Browser shortcuts work
- **No storage limits** - Generally unlimited

## Testing PWA Features

### Test Install Flow

1. **Desktop Chrome/Edge:**
   ```bash
   cd bible_app
   flutter run -d chrome
   ```
   - Look for install icon in address bar
   - Click to install
   - App opens in standalone window

2. **Android (via USB debugging):**
   ```bash
   cd bible_app
   flutter run -d <device-id>
   ```
   - Wait for install banner
   - Tap "Install"
   - Check home screen

3. **iOS Safari (deployed):**
   - Navigate to deployed URL
   - Tap Share button
   - Select "Add to Home Screen"
   - Name app and confirm

### Test Offline Mode

1. Open app in browser
2. Wait for full load
3. Open DevTools > Application > Service Workers
4. Check "Offline" box
5. Refresh page - app shell should still work
6. Re-open passages you already viewed - they should work offline
7. New passages not opened before may still require network

### Test TTS Detection

1. Open Settings screen
2. Look for TTS Capability Indicator
3. Should show:
   - ✅ Supported languages
   - ⚠️ Missing languages if Hebrew/Greek unavailable
4. Try "Test TTS" button
5. Check console for detailed voice info

### Test Storage

1. Open Settings > About section
2. Check Storage info
3. Note usage and quota
4. Tap "Refresh" to update
5. Check console for persistence status

## Building for Production

### GitHub Pages Deployment

```bash
cd bible_app
flutter build web --release --base-href /
../scripts/generate_pwa_service_worker.sh build/web
```

The build includes:
- Minified JavaScript
- Custom offline service worker
- All PWA assets (manifest, icons, pwa.js)
- Compressed assets

### Required Files

Ensure these exist in `bible_app/web/`:
- ✅ `manifest.json` - App manifest
- ✅ `pwa.js` - PWA JavaScript helpers
- ✅ `index.html` - Includes PWA script
- ⚠️ `icons/Icon-192.png` - 192x192 app icon
- ⚠️ `icons/Icon-512.png` - 512x512 app icon

**Note:** Icons need to be created/added. They're referenced but may not exist yet.

## Troubleshooting

### Install Prompt Not Showing

- **Check manifest** - Must be valid JSON
- **Check icons** - Must exist and be correct size
- **Check HTTPS** - Required (localhost exempt)
- **Check console** - Look for manifest errors
- **Already installed** - Won't show if already installed

### TTS Not Working

- **Check browser support** - Safari: iOS 14+, macOS 11+
- **Check voices** - Settings > TTS > Available Languages
- **Check permissions** - Some browsers need user gesture first
- **Check language** - Hebrew/Greek may not be installed

### Offline Not Working

- **Check service worker** - DevTools > Application > Service Workers
- **Check cache** - `lightsword_service_worker.js` should precache the app shell
- **Open content once online** - Bible data is cached on demand, not all at install time
- **Clear and reinstall** - Unregister service worker and reload
- **Check console** - Look for service worker errors

### Storage Being Cleared

- **iOS** - Always cleared after 7 days inactivity
- **Android** - Granted if persistent storage requested
- **Desktop** - Usually persisted automatically
- **Incognito** - Always cleared on close

## Future Enhancements

Potential PWA features to add:

1. **Background Sync** - Sync reading progress when back online
2. **Push Notifications** - Daily reading reminders (opt-in)
3. **Share Target** - Receive Bible references from other apps
4. **File Handling** - Open downloaded Bible modules
5. **Periodic Background Sync** - Update content daily
6. **Badge API** - Show unread verse count
7. **Shortcuts** - Quick actions from home screen icon
8. **Screenshots** - Better app store listings

## References

- [MDN: Progressive Web Apps](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [Web.dev: PWA Checklist](https://web.dev/pwa-checklist/)
- [Flutter Web: Building a PWA](https://docs.flutter.dev/deployment/web#building-a-pwa)
- [Web App Manifest Spec](https://www.w3.org/TR/appmanifest/)
- [Service Worker API](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
