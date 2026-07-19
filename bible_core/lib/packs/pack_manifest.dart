/// Stable identifiers for first-party LightSword data packs.
class PackIds {
  static const maculaSyntax = 'macula-syntax';
  static const originalLanguageOt = 'original-language-ot';
  static const originalLanguageNt = 'original-language-nt';
  static const strongsLexicon = 'strongs-lexicon';

  const PackIds._();
}

/// Versioned metadata describing a portable data pack.
class PackManifest {
  final String id;
  final String title;
  final String version;
  final int schemaVersion;
  final String contentType;
  final String? language;
  final String? license;
  final String? source;
  final List<String> books;
  final List<PackFile> files;
  final List<PackDependency> dependencies;

  const PackManifest({
    required this.id,
    required this.title,
    required this.version,
    required this.schemaVersion,
    required this.contentType,
    this.language,
    this.license,
    this.source,
    this.books = const [],
    this.files = const [],
    this.dependencies = const [],
  });

  factory PackManifest.fromJson(Map<String, dynamic> json) {
    return PackManifest(
      id: json['id'] as String,
      title: json['title'] as String,
      version: json['version'] as String,
      schemaVersion: json['schema_version'] as int,
      contentType: json['content_type'] as String,
      language: json['language'] as String?,
      license: json['license'] as String?,
      source: json['source'] as String?,
      books: (json['books'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      files: (json['files'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PackFile.fromJson)
          .toList(growable: false),
      dependencies:
          (json['dependencies'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(PackDependency.fromJson)
              .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'version': version,
      'schema_version': schemaVersion,
      'content_type': contentType,
      if (language != null) 'language': language,
      if (license != null) 'license': license,
      if (source != null) 'source': source,
      'books': books,
      'files': files.map((file) => file.toJson()).toList(growable: false),
      'dependencies': dependencies
          .map((dependency) => dependency.toJson())
          .toList(growable: false),
    };
  }
}

/// A file inside a pack, addressed by relative path.
class PackFile {
  final String path;
  final int? byteSize;
  final String? sha256;
  final String? mediaType;

  const PackFile({
    required this.path,
    this.byteSize,
    this.sha256,
    this.mediaType,
  });

  factory PackFile.fromJson(Map<String, dynamic> json) {
    return PackFile(
      path: json['path'] as String,
      byteSize: json['byte_size'] as int?,
      sha256: json['sha256'] as String?,
      mediaType: json['media_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      if (byteSize != null) 'byte_size': byteSize,
      if (sha256 != null) 'sha256': sha256,
      if (mediaType != null) 'media_type': mediaType,
    };
  }
}

/// A dependency on another pack.
class PackDependency {
  final String id;
  final String? versionConstraint;

  const PackDependency({
    required this.id,
    this.versionConstraint,
  });

  factory PackDependency.fromJson(Map<String, dynamic> json) {
    return PackDependency(
      id: json['id'] as String,
      versionConstraint: json['version_constraint'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (versionConstraint != null) 'version_constraint': versionConstraint,
    };
  }
}