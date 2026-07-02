import 'dart:io';
import 'dart:typed_data';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';
import 'package:bible_core/data/sources/sword/module_config.dart';

Future<void> main() async {
  print('Testing BSB module decompression...\n');
  
  // Load BSB config
  final confFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb.conf');
  final confContent = await confFile.readAsString();
  final config = SwordModuleConfig.parse(confContent);
  
  print('Module: ${config.name}');
  print('Driver: ${config.driver}');
  print('Compression: ${config.compression}');
  print('Source: ${config.sourceType}\n');
  
  // Test NT decompression
  print('Loading NT index...');
  final ntIndexFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzv');
  final ntIndex = await ntIndexFile.readAsBytes();
  print('NT index size: ${ntIndex.length} bytes');
  
  print('Loading NT compressed data...');
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntDataFile.readAsBytes();
  print('NT compressed data size: ${ntData.length} bytes\n');
  
  // Check first few verse locations
  print('First 5 verse locations:');
  for (int i = 0; i < 5; i++) {
    final loc = ZTextReader.getVerseLocation(Uint8List.fromList(ntIndex), i);
    if (loc != null) {
      print('  Verse $i: $loc');
    }
  }
  
  // Try to decompress first block
  print('\nDecompressing first verse block...');
  final firstLoc = ZTextReader.getVerseLocation(Uint8List.fromList(ntIndex), 0);
  if (firstLoc != null) {
    try {
      final decompressed = ZTextReader.decompressVerse(Uint8List.fromList(ntData), firstLoc);
      if (decompressed != null) {
        print('Decompressed successfully!');
        print('Decompressed size: ${decompressed.length} bytes');
        print('First 200 chars:');
        print(decompressed.substring(0, decompressed.length < 200 ? decompressed.length : 200));
      } else {
        print('ERROR: Decompression returned null');
      }
    } catch (e) {
      print('ERROR during decompression: $e');
    }
  } else {
    print('ERROR: Could not read first verse location');
  }
}
