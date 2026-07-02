import 'dart:io';
import 'dart:typed_data';
import 'package:bible_core/data/sources/usfm_repository.dart';
import 'package:bible_core/data/repository.dart';
import 'package:bible_core/models/passage_reference.dart';

class FileDataSource implements DataSource {
  @override
  Future<String> loadAsset(String path) async {
    final file = File('/workspaces/dabar/bible_app/assets/$path');
    return await file.readAsString();
  }

  @override
  Future<Uint8List> loadBytes(String path) async {
    final file = File('/workspaces/dabar/bible_app/assets/$path');
    return Uint8List.fromList(await file.readAsBytes());
  }

  @override
  Future<bool> assetExists(String path) async {
    final file = File('/workspaces/dabar/bible_app/assets/$path');
    return await file.exists();
  }
}

Future<void> main() async {
  print('Testing UsfmRepository with FileDataSource...\n');
  
  final repo = UsfmRepository(FileDataSource(), 'data/usfm/bsb');
  
  print('Loading John 1...');
  try {
    final verses = await repo.getVerses(const PassageReference(
      bookId: 'John',
      chapter: 1,
    ));
    
    print('✓ Loaded ${verses.length} verses\n');
    
    if (verses.isEmpty) {
      print('⚠️  WARNING: No verses loaded!');
      
      // Try to debug
      print('\nTrying to load file directly...');
      final ds = FileDataSource();
      final exists = await ds.assetExists('data/usfm/bsb/73-JHNengbsb.usfm');
      print('File exists: $exists');
      
      if (exists) {
        final content = await ds.loadAsset('data/usfm/bsb/73-JHNengbsb.usfm');
        print('File size: ${content.length} bytes');
      }
    } else {
      for (int i = 0; i < (verses.length < 5 ? verses.length : 5); i++) {
        print('${verses[i].reference}: ${verses[i].text}');
      }
    }
  } catch (e, stack) {
    print('❌ Error: $e');
    print('Stack: $stack');
  }
}
