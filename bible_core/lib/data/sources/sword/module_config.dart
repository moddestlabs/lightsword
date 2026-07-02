/// SWORD module configuration from .conf file
class SwordModuleConfig {
  final String name;
  final String description;
  final String dataPath;
  final ModuleDriver driver;
  final SourceType sourceType;
  final String encoding;
  final CompressionType compression;
  final String? versification;
  final String? lang;
  final Map<String, String> rawConfig;

  const SwordModuleConfig({
    required this.name,
    required this.description,
    required this.dataPath,
    required this.driver,
    required this.sourceType,
    required this.encoding,
    required this.compression,
    this.versification,
    this.lang,
    this.rawConfig = const {},
  });

  /// Parse a SWORD .conf file
  static SwordModuleConfig parse(String confContent) {
    final lines = confContent.split('\n');
    final config = <String, String>{};
    String? currentSection;

    for (final line in lines) {
      final trimmed = line.trim();
      
      // Skip comments and empty lines
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('//')) {
        continue;
      }

      // Section header [ModuleName]
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        currentSection = trimmed.substring(1, trimmed.length - 1);
        config['_name'] = currentSection;
        continue;
      }

      // Key=Value pairs
      if (trimmed.contains('=')) {
        final parts = trimmed.split('=');
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        config[key] = value;
      }
    }

    return SwordModuleConfig(
      name: config['_name'] ?? 'Unknown',
      description: config['Description'] ?? '',
      dataPath: config['DataPath'] ?? '',
      driver: _parseDriver(config['ModDrv'] ?? 'RawText'),
      sourceType: _parseSourceType(config['SourceType'] ?? 'OSIS'),
      encoding: config['Encoding'] ?? 'UTF-8',
      compression: _parseCompression(config['CompressType']),
      versification: config['Versification'],
      lang: config['Lang'],
      rawConfig: config,
    );
  }

  static ModuleDriver _parseDriver(String driver) {
    switch (driver.toLowerCase()) {
      case 'ztext':
        return ModuleDriver.zText;
      case 'rawtext':
        return ModuleDriver.rawText;
      case 'rawtext4':
        return ModuleDriver.rawText4;
      case 'rawld':
        return ModuleDriver.rawLD;
      case 'rawld4':
        return ModuleDriver.rawLD4;
      default:
        return ModuleDriver.rawText;
    }
  }

  static SourceType _parseSourceType(String type) {
    switch (type.toUpperCase()) {
      case 'OSIS':
        return SourceType.osis;
      case 'THML':
        return SourceType.thml;
      case 'GBF':
        return SourceType.gbf;
      case 'TEI':
        return SourceType.tei;
      default:
        return SourceType.osis;
    }
  }

  static CompressionType _parseCompression(String? type) {
    if (type == null) return CompressionType.none;
    switch (type.toUpperCase()) {
      case 'ZIP':
        return CompressionType.zip;
      case 'LZSS':
        return CompressionType.lzss;
      default:
        return CompressionType.none;
    }
  }
}

/// SWORD module driver types
enum ModuleDriver {
  zText,      // Compressed text (Bible)
  rawText,    // Uncompressed text
  rawText4,   // 4-byte addressing
  rawLD,      // Lexicon/Dictionary
  rawLD4,     // Lexicon/Dictionary with 4-byte addressing
}

/// Source markup types
enum SourceType {
  osis,   // Open Scripture Information Standard (XML)
  thml,   // Theological Markup Language
  gbf,    // General Bible Format
  tei,    // Text Encoding Initiative
}

/// Compression types
enum CompressionType {
  none,
  zip,
  lzss,
}
