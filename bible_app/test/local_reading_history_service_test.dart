import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/services/local_reading_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalReadingHistoryService', () {
    test('records visits and retrieves grouped history', () async {
      final service = LocalReadingHistoryService.instance;
      await service.clearHistory();

      const ref1 = PassageReference(bookId: 'Ezk', chapter: 2, startVerse: 1);
      const ref2 = PassageReference(bookId: 'Jhn', chapter: 5, startVerse: 6);

      await service.addVisit(reference: ref1, sourceId: 'BSB');
      await service.addVisit(reference: ref2, sourceId: 'BSB');

      final history = await service.getHistory();
      expect(history.length, equals(2));
      expect(history[0].reference, equals(ref2));
      expect(history[1].reference, equals(ref1));

      final grouped = await service.getGroupedHistory();
      expect(grouped.isNotEmpty, isTrue);
    });

    test('clears history correctly', () async {
      final service = LocalReadingHistoryService.instance;
      const ref = PassageReference(bookId: 'Jud', chapter: 1, startVerse: 3);

      await service.addVisit(reference: ref);
      expect((await service.getHistory()).isNotEmpty, isTrue);

      await service.clearHistory();
      expect((await service.getHistory()).isEmpty, isTrue);
    });
  });
}
