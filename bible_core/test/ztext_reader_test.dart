import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';

void main() {
  group('ZTextReader', () {
    test('getVerseLocation parses verse index entry', () {
      // Create a simple verse index with one entry:
      // offset=1000, compressedSize=500, uncompressedSize=800
      final indexData = Uint8List.fromList([
        // Entry 0: offset (little-endian 32-bit)
        0xE8, 0x03, 0x00, 0x00, // 1000
        // compressedSize (little-endian 16-bit)
        0xF4, 0x01, // 500
        // uncompressedSize (little-endian 16-bit)
        0x20, 0x03, // 800
        // padding
        0x00, 0x00,
      ]);

      final location = ZTextReader.getVerseLocation(indexData, 0);
      
      expect(location, isNotNull);
      expect(location!.offset, equals(1000));
      expect(location.compressedSize, equals(500));
      expect(location.uncompressedSize, equals(800));
    });

    test('getVerseLocation returns null for out-of-bounds index', () {
      final indexData = Uint8List.fromList([
        0xE8, 0x03, 0x00, 0x00,
        0xF4, 0x01,
        0x20, 0x03,
        0x00, 0x00,
      ]);

      final location = ZTextReader.getVerseLocation(indexData, 1);
      
      expect(location, isNull);
    });

    test('getVerseLocation returns null for empty verse', () {
      final indexData = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00, // offset = 0
        0x00, 0x00,              // compressedSize = 0
        0x00, 0x00,              // uncompressedSize = 0
        0x00, 0x00,              // padding
      ]);

      final location = ZTextReader.getVerseLocation(indexData, 0);
      
      expect(location, isNull);
    });
  });
}
