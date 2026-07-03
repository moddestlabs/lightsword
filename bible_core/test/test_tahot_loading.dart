import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:bible_core/data/sources/tahot_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TAHOT loads Genesis 1:1', () async {
    // Load Genesis 1:1
    final words = await TAHOTRepository.instance.getVerse('GEN', 1, 1);
    
    expect(words, isNotNull);
    expect(words!.length, greaterThan(0));
    
    // Check first word
    final firstWord = words[0];
    print('First word: ${firstWord.hebrew}');
    print('Transliteration: ${firstWord.translit}');
    print('Gloss: ${firstWord.gloss}');
    print('Strongs: ${firstWord.strongs}');
    
    // First word should be בְּ/רֵאשִׁ֖ית (in/beginning)
    expect(firstWord.gloss, contains('beginning'));
  });
}
