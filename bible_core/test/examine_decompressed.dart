import 'dart:io';
import 'dart:typed_data';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';

Future<void> main() async {
  print('Examining decompressed BSB content...\n');
  
  final ntFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntFile.readAsBytes();
  
  final decompressed = ZTextReader.decompressAllBlocks(Uint8List.fromList(ntData), null);
  
  print('Decompressed size: ${decompressed.length} bytes\n');
  print('First 1000 characters:');
  print(decompressed.substring(0, decompressed.length < 1000 ? decompressed.length : 1000));
  print('\n---\n');
  print('Last 500 characters:');
  final start = decompressed.length > 500 ? decompressed.length - 500 : 0;
  print(decompressed.substring(start));
}
