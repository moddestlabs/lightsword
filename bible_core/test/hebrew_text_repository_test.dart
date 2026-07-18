import 'dart:io';
import 'dart:typed_data';

import 'package:bible_core/data/repository.dart';
import 'package:bible_core/data/sources/hebrew_text_repository.dart';
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
  test('loads Hebrew text through a DataSource', () async {
    final repository = HebrewTextRepository(
      const FileDataSource(),
      assetBasePath: 'assets/data/hebrew',
    );

    final verse = await repository.getVerse('Gen', 1, 1);

    expect(verse, isNotNull);
    expect(verse, isNotEmpty);
  });
}
