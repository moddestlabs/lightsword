import 'dart:typed_data';

import 'package:bible_core/data/repository.dart';
import 'package:bible_core/packs/pack_manifest.dart';
import 'package:bible_core/packs/pack_reader.dart';
import 'package:test/test.dart';

class MemoryDataSource implements DataSource {
  final Map<String, String> textAssets;
  final Map<String, Uint8List> byteAssets;

  const MemoryDataSource({
    this.textAssets = const {},
    this.byteAssets = const {},
  });

  @override
  Future<bool> assetExists(String path) async {
    return textAssets.containsKey(path) || byteAssets.containsKey(path);
  }

  @override
  Future<String> loadAsset(String path) async {
    final value = textAssets[path];
    if (value == null) {
      throw StateError('Missing text asset: $path');
    }
    return value;
  }

  @override
  Future<Uint8List> loadBytes(String path) async {
    final value = byteAssets[path];
    if (value == null) {
      throw StateError('Missing byte asset: $path');
    }
    return value;
  }
}

void main() {
  group('PackManifest', () {
    test('round-trips manifest metadata', () {
      const manifest = PackManifest(
        id: PackIds.maculaSyntax,
        title: 'Macula Syntax',
        version: '1.0.0',
        schemaVersion: 1,
        contentType: 'syntax',
        language: 'grc',
        license: 'CC BY 4.0',
        source: 'Macula Greek',
        books: ['Eph'],
        files: [
          PackFile(
            path: 'EPH_syntax.json',
            byteSize: 123,
            sha256: 'abc123',
            mediaType: 'application/json',
          ),
        ],
        dependencies: [
          PackDependency(
            id: PackIds.originalLanguageNt,
            versionConstraint: '^1.0.0',
          ),
        ],
      );

      final decoded = PackManifest.fromJson(manifest.toJson());

      expect(decoded.id, PackIds.maculaSyntax);
      expect(decoded.title, 'Macula Syntax');
      expect(decoded.schemaVersion, 1);
      expect(decoded.files.single.path, 'EPH_syntax.json');
      expect(decoded.dependencies.single.id, PackIds.originalLanguageNt);
    });
  });

  group('DataSourcePackReader', () {
    test('loads pack-relative text and byte files', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final reader = DataSourcePackReader(
        dataSource: MemoryDataSource(
          textAssets: {'packs/syntax/EPH_syntax.json': '{"2":{}}'},
          byteAssets: {'packs/syntax/blob.bin': bytes},
        ),
        packBasePaths: const {PackIds.maculaSyntax: 'packs/syntax'},
      );

      expect(await reader.hasPack(PackIds.maculaSyntax), isTrue);
      expect(await reader.hasPack(PackIds.originalLanguageOt), isFalse);
      expect(
        await reader.loadText(PackIds.maculaSyntax, 'EPH_syntax.json'),
        '{"2":{}}',
      );
      expect(
        await reader.loadBytes(PackIds.maculaSyntax, '/blob.bin'),
        bytes,
      );
    });
  });
}