import 'dart:io';
import 'dart:typed_data';

Future<void> main() async {
  print('Examining BSB NT index structure...\n');
  
  final ntIndexFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzv');
  final ntIndex = await ntIndexFile.readAsBytes();
  
  print('Index file size: ${ntIndex.length} bytes');
  print('Expected entries (10 bytes each): ${ntIndex.length ~/ 10}\n');
  
  // Read first 10 entries in detail
  print('First 10 index entries (raw bytes):');
  for (int i = 0; i < 10 && i * 10 < ntIndex.length; i++) {
    final offset = i * 10;
    final entry = ntIndex.sublist(offset, offset + 10);
    
    // Read as little-endian
    final dataOffset = ByteData.view(entry.buffer).getUint32(0, Endian.little);
    final compSize = ByteData.view(entry.buffer).getUint16(4, Endian.little);
    final uncompSize = ByteData.view(entry.buffer).getUint16(6, Endian.little);
    
    print('Entry $i: offset=$dataOffset, compSize=$compSize, uncompSize=$uncompSize');
    print('  Raw bytes: ${entry.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  }
  
  print('\nChecking compressed data file...');
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntDataFile.readAsBytes();
  print('Compressed data size: ${ntData.length} bytes');
  print('First 20 bytes: ${ntData.sublist(0, 20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
  
  // Check for BZIP2 magic number (BZ)
  if (ntData.length > 2 && ntData[0] == 0x42 && ntData[1] == 0x5A) {
    print('✓ Found BZIP2 magic number (BZ) at start');
  } else {
    print('✗ BZIP2 magic number NOT found at start!');
  }
}
