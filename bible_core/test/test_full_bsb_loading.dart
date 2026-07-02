import 'dart:io';
import 'dart:typed_data';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';
import 'package:bible_core/data/sources/sword/module_config.dart';
import 'package:bible_core/data/sources/sword/osis_parser.dart';

Future<void> main() async {
  print('Testing complete BSB loading process...\n');
  
  // 1. Load config
  final confFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb.conf');
  final confContent = await confFile.readAsString();
  final config = SwordModuleConfig.parse(confContent);
  
  print('✓ Config loaded: ${config.name}');
  print('  Driver: ${config.driver}');
  print('  Compression: ${config.compression}');
  print('  DataPath: ${config.dataPath}\n');
  
  // 2. Load NT compressed data
  final ntFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntFile.readAsBytes();
  print('✓ NT data loaded: ${ntData.length} bytes compressed\n');
  
  // 3. Decompress
  print('Decompressing NT...');
  final decompressed = ZTextReader.decompressAllBlocks(Uint8List.fromList(ntData), null);
  print('✓ Decompressed: ${decompressed.length} bytes\n');
  
  // 4. Parse verses
  print('Parsing verses...');
  final verses = OsisParser.parseVerses(decompressed);
  print('✓ Parsed ${verses.length} verses\n');
  
  // 5. Find John 1:1-10
  final johnVerses = verses.where((v) => 
    v.bookId == 'John' && v.chapter == 1 && v.number >= 1 && v.number <= 10
  ).toList();
  
  print('John 1:1-10 verses found: ${johnVerses.length}');
  for (final v in johnVerses) {
    print('  ${v.reference}: ${v.text.substring(0, v.text.length < 60 ? v.text.length : 60)}...');
  }
  
  if (johnVerses.isEmpty) {
    print('\n⚠️  WARNING: No John verses found!');
    print('Sample of parsed verses:');
    for (int i = 0; i < (verses.length < 5 ? verses.length : 5); i++) {
      print('  ${verses[i].reference}: ${verses[i].text.substring(0, verses[i].text.length < 40 ? verses[i].text.length : 40)}...');
    }
    
    print('\nFirst 500 chars of decompressed XML:');
    print(decompressed.substring(0, decompressed.length < 500 ? decompressed.length : 500));
  }
}
