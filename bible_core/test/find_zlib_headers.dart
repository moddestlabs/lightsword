import 'dart:io';

Future<void> main() async {
  print('Searching for ZLIB block headers in BSB NT data...\n');
  
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final data = await ntDataFile.readAsBytes();
  
  print('File size: ${data.length} bytes\n');
  
  // Search for ZLIB magic bytes (78 9c)
  final zlibHeaders = <int>[];
  for (int i = 0; i < data.length - 1; i++) {
    if (data[i] == 0x78 && data[i + 1] == 0x9c) {
      zlibHeaders.add(i);
    }
  }
  
  print('Found ${zlibHeaders.length} ZLIB headers at offsets:');
  for (int i = 0; i < (zlibHeaders.length < 20 ? zlibHeaders.length : 20); i++) {
    print('  Offset ${zlibHeaders[i]}');
  }
  if (zlibHeaders.length > 20) {
    print('  ... and ${zlibHeaders.length - 20} more');
  }
  
  // Check the pattern
  if (zlibHeaders.length > 1) {
    print('\nDistances between headers:');
    for (int i = 1; i < (zlibHeaders.length < 10 ? zlibHeaders.length : 10); i++) {
      final distance = zlibHeaders[i] - zlibHeaders[i - 1];
      print('  Headers $i-${i-1}: $distance bytes');
    }
  }
}
