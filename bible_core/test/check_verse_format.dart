import 'dart:io';
import 'dart:typed_data';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';

Future<void> main() async {
  print('Examining BSB verse format...\n');
  
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntDataFile.readAsBytes();
  
  final ntIndexFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzs');
  final ntIndex = await ntIndexFile.readAsBytes();
  
  final decompressed = ZTextReader.decompressAllBlocks(
    Uint8List.fromList(ntData),
    Uint8List.fromList(ntIndex)
  );
  
  print('Decompressed size: ${decompressed.length} bytes\n');
  print('First 2000 characters:');
  print(decompressed.substring(0, decompressed.length < 2000 ? decompressed.length : 2000));
  
  // Search for verse patterns
  print('\n\nSearching for verse patterns...');
  if (decompressed.contains('<verse')) {
    print('✓ Found <verse tags');
    final firstVerse = decompressed.indexOf('<verse');
    print('First verse at position: $firstVerse');
    print(decompressed.substring(firstVerse, firstVerse + 200));
  } else {
    print('✗ No <verse tags found');
  }
  
  if (decompressed.contains('osisID="Matt')) {
    print('\n✓ Found Matthew osisID');
  }
  if (decompressed.contains('osisID="John')) {
    print('✓ Found John osisID');
    final johnPos = decompressed.indexOf('osisID="John');
    print('Context:');
    print(decompressed.substring(johnPos - 50, johnPos + 300));
  }
}
