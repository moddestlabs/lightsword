import 'dart:io';
import 'package:bible_core/data/sources/usfm_parser.dart';

Future<void> main() async {
  print('Testing USFM parser with BSB John...\n');
  
  final johnFile = File('/workspaces/dabar/bible_app/assets/data/usfm/bsb/73-JHNengbsb.usfm');
  final content = await johnFile.readAsString();
  
  print('File size: ${content.length} bytes\n');
  
  print('Parsing verses...');
  final verses = UsfmParser.parseVerses(content);
  print('✓ Parsed ${verses.length} verses\n');
  
  // Find John 1:1-10
  final john1 = verses.where((v) => 
    v.bookId == 'John' && v.chapter == 1 && v.number >= 1 && v.number <= 10
  ).toList();
  
  print('John 1:1-10: ${john1.length} verses found\n');
  
  for (final v in john1) {
    print('${v.reference}:');
    print('  ${v.text}\n');
  }
  
  if (john1.isEmpty) {
    print('⚠️  WARNING: No John 1:1-10 verses found!');
    print('Sample of parsed verses:');
    for (int i = 0; i < (verses.length < 5 ? verses.length : 5); i++) {
      print('  ${verses[i].reference}: ${verses[i].text.substring(0, verses[i].text.length < 50 ? verses[i].text.length : 50)}...');
    }
  }
}
