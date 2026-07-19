import 'dart:io';
import 'dart:typed_data';

import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/tagnt_repository.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';
import 'package:bible_core/packs/pack_manifest.dart';
import 'package:bible_core/packs/pack_reader.dart';
import 'package:test/test.dart';

class FileDataSource implements DataSource {
  const FileDataSource();

  @override
  Future<String> loadAsset(String path) {
    return File(path).readAsString();
  }

  @override
  Future<Uint8List> loadBytes(String path) {
    return File(path).readAsBytes();
  }

  @override
  Future<bool> assetExists(String path) {
    return File(path).exists();
  }
}

void main() {
  test('TAHOT loads Genesis 1:1', () async {
    final repository = TAHOTRepository(
      const FileDataSource(),
      assetBasePath: 'assets/data/tahot',
    );

    final words = await repository.getVerse('Gen', 1, 1);

    expect(words, isNotNull);
    expect(words!.length, greaterThan(0));

    // Check first word
    final firstWord = words[0];
    // First word should be בְּ/רֵאשִׁ֖ית (in/beginning)
    expect(firstWord.gloss, contains('beginning'));
  });

  test('TAHOT loads through a PackReader', () async {
    final repository = TAHOTRepository.fromPackReader(
      const DataSourcePackReader(
        dataSource: FileDataSource(),
        packBasePaths: {PackIds.originalLanguageOt: 'assets/data/tahot'},
      ),
    );

    final words = await repository.getVerse('Gen', 1, 1);

    expect(words, isNotNull);
    expect(words, isNotEmpty);
    expect(words!.first.gloss, contains('beginning'));
  });

  test('TAGNT loads through a PackReader', () async {
    final repository = TAGNTRepository.fromPackReader(
      const DataSourcePackReader(
        dataSource: FileDataSource(),
        packBasePaths: {PackIds.originalLanguageNt: 'assets/data/greek'},
      ),
    );

    final words = await repository.getVerse('Eph', 1, 1);

    expect(words, isNotNull);
    expect(words, isNotEmpty);
    expect(words!.first.greek, isNotEmpty);
  });
}
