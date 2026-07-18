import 'dart:io';
import 'dart:typed_data';

import 'package:bible_core/data/repository.dart';
import 'package:bible_core/lexicon/strongs.dart';
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
  test('loads Strong entries through a DataSource', () async {
    final lookup = StrongsLookup(
      const FileDataSource(),
      assetBasePath: 'assets/data/lexicon',
    );

    final entry = await lookup.getEntry('H7225');

    expect(entry, isNotNull);
    expect(entry!.number, 'H7225');
    expect(lookup.isLoaded, isTrue);
    expect(lookup.entryCount, greaterThan(0));
  });
}
