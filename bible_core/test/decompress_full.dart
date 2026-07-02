import 'dart:io';
import 'package:archive/archive.dart';

Future<void> main() async {
  print('Attempting to decompress entire BSB NT data file...\n');
  
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final compressedData = await ntDataFile.readAsBytes();
  
  print('Compressed size: ${compressedData.length} bytes');
  print('First 20 bytes: ${compressedData.sublist(0, 20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}\n');
  
  try {
    print('Decompressing with ZLibDecoder...');
    final decompressed = ZLibDecoder().decodeBytes(compressedData);
    
    print('✓ Decompression successful!');
    print('Decompressed size: ${decompressed.length} bytes');
    
    final text = String.fromCharCodes(decompressed);
    print('\nFirst 500 characters:');
    print(text.substring(0, text.length < 500 ? text.length : 500));
    
    print('\n\nLast 300 characters:');
    final start = text.length > 300 ? text.length - 300 : 0;
    print(text.substring(start));
    
    // Check if it's valid OSIS XML
    if (text.contains('<verse') || text.contains('<div')) {
      print('\n✓ Contains XML verse tags!');
    }
    if (text.contains('osisID')) {
      print('✓ Contains osisID attributes!');
    }
    
  } catch (e) {
    print('✗ Decompression failed: $e');
  }
}
