# Deep Linking Guide

LIGHTSWORD supports deep linking to specific Bible passages and view modes via URL parameters on web and custom schemes on native platforms.

## URL Format

### Web (GitHub Pages)

```
https://moddestlabs.github.io/lightsword?r=<reference>&mode=<mode>
```

**Parameters:**
- `r` or `ref`: Bible reference (required)
- `mode` or `view`: Display mode (optional, defaults to `standard`)

### Examples

**Full chapter:**
```
https://moddestlabs.github.io/lightsword?r=gen1
```

**Single verse:**
```
https://moddestlabs.github.io/lightsword?r=john3.16
```

**Verse range:**
```
```
https://moddestlabs.github.io/lightsword?r=rom8.1-10
```

**With view mode:**
```
https://moddestlabs.github.io/lightsword?r=gen1.1&mode=interlinear
```

## Reference Format

The reference parameter (`r`) supports flexible formats:

### Format: `book[chapter[.verse[-endVerse]]]`

**Book abbreviations** (case-insensitive):
- Old Testament: `gen`, `exo`, `lev`, `num`, `deu`, `jos`, `jdg`, `rut`, `1sa`, `2sa`, `1ki`, `2ki`, `1ch`, `2ch`, `ezr`, `neh`, `est`, `job`, `ps`, `pro`, `ecc`, `sng`, `isa`, `jer`, `lam`, `ezk`, `dan`, `hos`, `jol`, `amo`, `oba`, `jon`, `mic`, `nam`, `hab`, `zep`, `hag`, `zec`, `mal`
- New Testament: `mat`, `mrk`, `luk`, `jhn`, `act`, `rom`, `1co`, `2co`, `gal`, `eph`, `php`, `col`, `1th`, `2th`, `1ti`, `2ti`, `tit`, `phm`, `heb`, `jas`, `1pe`, `2pe`, `1jn`, `2jn`, `3jn`, `jud`, `rev`

**Examples:**
- `gen1` → Genesis chapter 1
- `john3.16` → John 3:16 (single verse)
- `rom8.1-10` → Romans 8:1-10 (verse range)
- `ps23` → Psalm 23 (full chapter)
- `matt5.3` → Matthew 5:3

## View Modes

Available view modes:
- `standard` (default) - Verse-by-verse reading view
- `interlinear` - Hebrew/Greek with morphology and glosses
- `paragraph` - Continuous text (coming soon)

## Implementation

### Architecture

The deep linking system consists of:

1. **ReferenceParser** ([`services/reference_parser.dart`](../bible_app/lib/services/reference_parser.dart))
   - Parses reference strings (e.g., `gen1.4`)
   - Normalizes book abbreviations
   - Supports chapter, verse, and verse ranges
   - Formats references back to compact strings

2. **DeepLinkingService** ([`services/deep_linking_service.dart`](../bible_app/lib/services/deep_linking_service.dart))
   - Reads URL parameters on web startup
   - Listens to browser history changes (back/forward)
   - Updates URL as user navigates
   - Prepared for native deep links (uni_links/app_links)

3. **Platform-specific implementations:**
   - Web: [`deep_linking_service_web.dart`](../bible_app/lib/services/deep_linking_service_web.dart) - Uses `dart:html`
   - Native: [`deep_linking_service_stub.dart`](../bible_app/lib/services/deep_linking_service_stub.dart) - Placeholder

### Integration Flow

1. **App Startup:**
   - `main()` initializes `DeepLinkingService`
   - Service checks URL parameters
   - Emits `NavigationRequest` if valid reference found

2. **HomeScreen:**
   - Listens to `navigationStream`
   - Switches to reader tab
   - Calls `ReaderScreen.navigateToReference()`

3. **ReaderScreen:**
   - Accepts navigation requests
   - Loads specified passage and view mode
   - Updates URL when user navigates manually

4. **Browser Navigation:**
   - User clicks back/forward
   - Service detects URL change
   - Emits new navigation request
   - Reader updates to match URL

### URL Updates

The app updates the browser URL as you navigate:
- Change book/chapter → URL updates
- Toggle view mode → URL updates
- Browser back/forward → Reader follows URL

## Native Deep Linking (Future)

To add native deep linking support:

1. **Add dependency** (choose one):
   ```yaml
   dependencies:
     app_links: ^3.0.0  # Recommended (Google-maintained)
     # OR
     uni_links: ^0.5.1  # Alternative
   ```

2. **Configure platform:**

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>lightsword</string>
       </array>
     </dict>
   </array>
   ```

   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <intent-filter>
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="lightsword" />
   </intent-filter>
   ```

3. **Update service:**
   Implement `_initializeNative()` in `deep_linking_service.dart` to listen to the app_links/uni_links stream.

### Native URL Formats

Once native support is added:

**Custom scheme:**
```
lightsword://gen1.4
lightsword://john3.16?mode=interlinear
```

**Universal Links** (iOS/Android App Links):
```
https://moddestlabs.github.io/lightsword?r=gen1.4
```

## Testing

### Local Testing

```bash
cd bible_app
flutter run -d chrome --web-port 8080
```

Then open:
```
http://localhost:8080?r=gen1.1
http://localhost:8080?r=john3.16&mode=interlinear
http://localhost:8080?r=rom8.1-10
```

### Production Testing

After deploying to GitHub Pages:
```
https://moddestlabs.github.io/lightsword?r=ps23
https://moddestlabs.github.io/lightsword?r=matt5.3-12&mode=interlinear
```

## Use Cases

1. **Sharing verses:**
   - Copy URL from address bar
   - Share with friends, post on social media
   - Link opens directly to the passage

2. **Study materials:**
   - Blog posts can link to specific verses
   - Study guides with direct verse references
   - Course materials with embedded Bible links

3. **Reading plans:**
   - Create reading plan pages with direct links
   - Daily devotional emails with verse links

4. **Sermon notes:**
   - Link to passages referenced in sermon
   - Interactive Bible study materials

5. **Cross-references:**
   - Future: Click cross-reference → opens new tab with passage
   - Hover previews of linked passages

## Future Enhancements

Planned features:
- **Highlighted text:** `?r=gen1.1&highlight=light`
- **Commentary mode:** `?r=gen1.1&mode=commentary&note=creation`
- **Parallel translations:** `?r=gen1.1&translations=BSB,KJV`
- **Reading plans:** `?plan=chronological&day=1`
- **Search links:** `?search=love+faith`

---

**Related Documentation:**
- [Architecture Overview](ARCHITECTURE.md)
- [View Modes](../bible_app/lib/ui/models/view_mode.dart)
- [Passage References](../bible_core/lib/models/passage_reference.dart)
