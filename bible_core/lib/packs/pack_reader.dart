import 'dart:typed_data';

import 'package:bible_core/data/repository.dart';

/// Reads files from logical data packs without exposing their storage location.
abstract class PackReader {
  Future<bool> hasPack(String packId);

  Future<String> loadText(String packId, String relativePath);

  Future<Uint8List> loadBytes(String packId, String relativePath);
}

/// Pack reader backed by the existing DataSource path abstraction.
class DataSourcePackReader implements PackReader {
  final DataSource dataSource;
  final Map<String, String> packBasePaths;

  const DataSourcePackReader({
    required this.dataSource,
    required this.packBasePaths,
  });

  @override
  Future<bool> hasPack(String packId) async {
    return packBasePaths.containsKey(packId);
  }

  @override
  Future<String> loadText(String packId, String relativePath) {
    return dataSource.loadAsset(_resolvePath(packId, relativePath));
  }

  @override
  Future<Uint8List> loadBytes(String packId, String relativePath) {
    return dataSource.loadBytes(_resolvePath(packId, relativePath));
  }

  String _resolvePath(String packId, String relativePath) {
    final basePath = packBasePaths[packId];
    if (basePath == null) {
      throw StateError('Unknown pack: $packId');
    }

    final normalizedBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final normalizedRelative = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return '$normalizedBase/$normalizedRelative';
  }
}