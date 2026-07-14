# SWORD Module Support Implementation Plan

## Overview

SWORD (Standard Works of Reference Data) is the industry-standard format for Bible modules, maintained by CrossWire Bible Society. Supporting SWORD modules gives LightSword access to hundreds of open-source Bible translations, lexicons, and dictionaries.

## SWORD Module Format

### Module Structure
```
module_name/
├── mods.d/
│   └── module.conf          # Module metadata and configuration
└── modules/
    └── texts/
        ├── ztext/            # Compressed text modules
        ├── rawtext/          # Uncompressed text
        └── rawld/            # Lexicon/dictionary data
```

### Configuration File (.conf)
Key fields:
- `[ModuleName]` - Unique identifier
- `DataPath` - Path to module data relative to SWORD library root
- `ModDrv` - Driver type (zText, RawText, RawLD, etc.)
- `SourceType` - Markup format (OSIS, ThML, GBF, TEI)
- `Encoding` - Text encoding (usually UTF-8)
- `CompressType` - Compression (ZIP, LZSS, or none)
- `Versification` - Versification system (KJV, NRSV, Vulgate, etc.)
- `Lang` - ISO language code
- `Feature` - Module features (StrongsNumbers, Morphology, etc.)

### Text Formats

#### OSIS (Open Scripture Information Standard)
XML-based format, most modern and feature-rich:
```xml
<verse osisID="Gen.1.1">
  <w lemma="strong:H07225" morph="He,R:Ncfsa">בְּרֵאשִׁ֖ית</w>
  <w lemma="strong:H01254" morph="He,V:Vqp3ms">בָּרָ֣א</w>
  ...
</verse>
```

#### ThML (Theological Markup Language)
Older HTML-like format

#### GBF (General Bible Format)
Legacy tag-based format

## Implementation Strategy

### Phase 1: Basic OSIS Support (Current Goal)
- Parse uncompressed OSIS XML files
- Extract verse text, book/chapter/verse references
- Support basic markup (verses, paragraphs, titles)
- **Defer:** Strong's numbers, morphology, footnotes

### Phase 2: Enhanced OSIS Features
- Parse Strong's numbers from `<w lemma="strong:HNNNN">` tags
- Parse morphology codes from `<w morph="...">` tags
- Handle cross-references and footnotes
- Support red letter (words of Christ)

### Phase 3: Module Management
- Parse .conf files
- Download modules from CrossWire repositories
- Handle versification mapping
- Support multiple simultaneous modules

### Phase 4: Compression Support
- Implement ZIP decompression for zText modules
- Handle block compression schemes
- Optimize for web (consider pre-decompressing for GitHub Pages)

## Technical Approach

### Package Structure
```
bible_core/lib/data/sources/sword/
├── sword_parser.dart         # Main SWORD module parser
├── sword_repository.dart     # BibleRepository implementation
├── osis_parser.dart          # OSIS XML parser
├── module_config.dart        # .conf file parser
└── versification.dart        # Versification systems
```

### Key Classes

```dart
/// SWORD module metadata from .conf file
class SwordModuleConfig {
  final String name;
  final String dataPath;
  final ModuleDriver driver;
  final SourceType sourceType;
  final String encoding;
  final CompressionType compression;
  final VersificationSystem versification;
}

/// Parse OSIS XML into verse data
class OsisParser {
  static List<Verse> parseBook(String osisXml);
  static Word parseWord(String wordXml);  // For interlinear
}

/// SWORD-based BibleRepository implementation
class SwordRepository implements BibleRepository {
  final DataSource _dataSource;
  final SwordModuleConfig _config;
  // ...
}
```

## Dart/Flutter Considerations

### XML Parsing
Use `xml` package (already pub-installable, pure Dart):
```dart
dependencies:
  xml: ^6.5.0
```

### Web Compatibility
- SWORD modules can be large (4-10MB per Bible)
- For web deployment, consider:
  1. Pre-convert SWORD to JSON during build
  2. Split by book for lazy loading
  3. Use IndexedDB for caching
  4. Provide download progress UI

### Native Compatibility
- Can bundle SWORD modules in assets
- Can download and cache in app documents directory
- Consider using `path_provider` for module storage

## Data Sources

### CrossWire Repositories
- Main: https://www.crosswire.org/ftpmirror/pub/sword/
- Packages organized by format: `rawtext/`, `rawzip/`, `ztext/`

### Open-Licensed Modules
Priority candidates (all public domain or CC):
- **World English Bible (WEB)** - Modern English, includes Deuterocanon
- **King James Version (KJV)** - Public domain, widely used
- **Berean Study Bible (BSB)** - CC BY-SA 4.0, includes Strong's tagging
- **OSHB (Open Scriptures Hebrew Bible)** - Hebrew OT with morphology
- **Berean Interlinear Bible** - Greek NT with interlinear

## Next Steps

1. ✅ Research SWORD format and module structure
2. 🔄 Add `xml` package dependency to `bible_core`
3. ⬜ Implement basic OSIS XML parser
4. ⬜ Create `SwordRepository` implementing `BibleRepository`
5. ⬜ Download and test with WEB SWORD module
6. ⬜ Wire up to Flutter app alongside JSON repository
7. ⬜ Add module selection UI

## Resources

- SWORD Project: https://crosswire.org/sword/
- OSIS Documentation: https://crosswire.org/osis/
- Module Repository: https://crosswire.org/sword/modules/
- Wiki: https://wiki.crosswire.org/
