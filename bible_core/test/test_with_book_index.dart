import 'dart:io';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';
import 'package:bible_core/data/sources/sword/osis_parser.dart';

Future<void> main() async {
  print('Testing BSB decompression with book index...\n');
  
  final ntDataFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntDataFile.readAsBytes();
  print('✓ Loaded compressed data: ${ntData.length} bytes');
  
  final ntIndexFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzs');
  final ntIndex = await ntIndexFile.readAsBytes();
  print('✓ Loaded book index: ${ntIndex.length} bytes');
  
  // Parse book index
  print('\nBook index entries:');
  for (int i = 0; i < ntIndex.length ~/ 6; i++) {
    final offset = i * 6;
    final entry = ntIndex.sublist(offset, offset + 6);
    final blockOffset = entry[0] | (entry[1] << 8) | (entry[2] << 16) | (entry[3] << 24);
    final blockSize = entry[4] | (entry[5] << 8);
    print('  Book $i: offset=$blockOffset, size=$blockSize');
  }
  
  print('\nDecompressing with book index...');
  final decompressed = ZTextReader.decompressAllBlocks(
    Uint8List.fromList(ntData),
    Uint8List.fromList(ntIndex)
  );
  print('✓ Decompressed: ${decompressed.length} bytes\n');
  
  // Wrap in OSIS tags
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">');
  buffer.writeln('<osisText>');
  buffer.write(decompressed);
  buffer.writeln('</osisText>');
  buffer.writeln('</osis>');
  
  final wrapped = buffer.toString();
  
  print('Parsing XML...');
  try {
    final doc = XmlDocument.parse(wrapped);
    print('✓ XML parses successfully!\n');
    
    print('Parsing verses...');
    final verses = OsisParser.parseVerses(wrapped);
    print('✓ Parsed ${verses.length} verses\n');
    
    // Find John 1:1-10
    final johnVerses = verses.where((v) => 
      v.bookId == 'John' && v.chapter == 1 && v.number >= 1 && v.number <= 10
    ).toList();
    
    print('John 1:1-10: ${johnVerses.length} verses found');
    for (final v in johnVerses) {
      final text = v.text.length > 80 ? '${v.text.substring(0, 80)}...' : v.text;
      print('  ${v.reference}: $text');
    }
    
  } catch (e) {
    print('✗ Error: $e');
  }
}
