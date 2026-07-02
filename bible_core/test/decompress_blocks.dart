import 'dart:io';
import 'package:archive/archive.dart';

Future<void> main() async {
  print('Decompressing individual ZLIB blocks from BSB NT...\n');
  
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final data = await ntDataFile.readAsBytes();
  
  // Known block offsets
  final blockOffsets = [0, 1110, 5041, 19594, 117567];
  
  for (int i = 0; i < blockOffsets.length && i < 3; i++) {
    final start = blockOffsets[i];
    final end = i + 1 < blockOffsets.length ? blockOffsets[i + 1] : data.length;
    
    print('Block $i: bytes $start-${end-1} (${end-start} bytes compressed)');
    
    try {
      final blockData = data.sublist(start, end);
      final decompressed = ZLibDecoder().decodeBytes(blockData);
      final text = String.fromCharCodes(decompressed);
      
      print('  Decompressed: ${decompressed.length} bytes');
      print('  First 200 chars: ${text.substring(0, text.length < 200 ? text.length : 200)}');
      
      // Count verses
      final verseCount = '<verse '.allMatches(text).length;
      print('  Contains ~$verseCount verse tags\n');
    } catch (e) {
      print('  ERROR: $e\n');
    }
  }
}
