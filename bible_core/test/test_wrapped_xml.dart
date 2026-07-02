import 'dart:io';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import 'package:bible_core/data/sources/sword/ztext_reader.dart';
import 'package:bible_core/data/sources/sword/osis_parser.dart';

Future<void> main() async {
  print('Testing OSIS wrapper generation...\n');
  
  // Simulate what sword_repository does
  final ntFile = File('/workspaces/dabar/bible_app/assets/data/sword/bsb/nt.bzz');
  final ntData = await ntFile.readAsBytes();
  
  final decompressed = ZTextReader.decompressAllBlocks(Uint8List.fromList(ntData), null);
  
  // Add wrapper like sword_repository should
  final buffer = StringBuffer();
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">');
  buffer.writeln('<osisText>');
  buffer.write(decompressed);
  buffer.writeln('</osisText>');
  buffer.writeln('</osis>');
  
  final wrapped = buffer.toString();
  
  print('Wrapped XML size: ${wrapped.length} bytes');
  print('\nFirst 500 characters:');
  print(wrapped.substring(0, 500));
  
  // Try to parse
  print('\n\nAttempting to parse XML...');
  try {
    final doc = XmlDocument.parse(wrapped);
    print('✓ XML parses successfully!');
    print('Root element: ${doc.rootElement.name}');
    
    // Try to parse verses
    print('\nParsing verses...');
    final verses = OsisParser.parseVerses(wrapped);
    print('✓ Parsed ${verses.length} verses');
    
    // Show first few verses
    print('\nFirst 3 verses:');
    for (int i = 0; i < (verses.length < 3 ? verses.length : 3); i++) {
      final v = verses[i];
      final text = v.text.length > 60 ? '${v.text.substring(0, 60)}...' : v.text;
      print('  ${v.reference}: $text');
    }
    
  } catch (e) {
    print('✗ Error: $e');
  }
}
