import 'package:test/test.dart';
import 'package:bible_core/bible_core.dart';

void main() {
  group('HistoryEntry', () {
    test('toJson and fromJson work symmetrically', () {
      final now = DateTime(2026, 8, 8, 14, 30);
      final entry = HistoryEntry(
        id: '123',
        reference: const PassageReference(
          bookId: 'Jhn',
          chapter: 3,
          startVerse: 16,
          endVerse: 16,
        ),
        timestamp: now,
        sourceId: 'BSB',
      );

      final json = entry.toJson();
      final restored = HistoryEntry.fromJson(json);

      expect(restored.id, equals('123'));
      expect(restored.reference.bookId, equals('Jhn'));
      expect(restored.reference.chapter, equals(3));
      expect(restored.reference.startVerse, equals(16));
      expect(restored.sourceId, equals('BSB'));
      expect(restored.timestamp, equals(now));
    });

    test('groupEntriesByDay groups items correctly by local date descending',
        () {
      final day1 = DateTime(2026, 8, 2, 10, 0);
      final day1Later = DateTime(2026, 8, 2, 15, 30);
      final day2 = DateTime(2026, 8, 1, 9, 0);

      final e1 = HistoryEntry(
        id: '1',
        reference:
            const PassageReference(bookId: 'Ezk', chapter: 2, startVerse: 1),
        timestamp: day1,
      );
      final e2 = HistoryEntry(
        id: '2',
        reference:
            const PassageReference(bookId: 'Jhn', chapter: 5, startVerse: 6),
        timestamp: day1Later,
      );
      final e3 = HistoryEntry(
        id: '3',
        reference:
            const PassageReference(bookId: 'Jud', chapter: 1, startVerse: 3),
        timestamp: day2,
      );

      final grouped = groupEntriesByDay([e1, e3, e2]);

      expect(grouped.keys.length, equals(2));

      final dates = grouped.keys.toList();
      expect(dates[0], equals(normalizeDateToDay(day1)));
      expect(dates[1], equals(normalizeDateToDay(day2)));

      expect(grouped[dates[0]]!.map((e) => e.id), equals(['2', '1']));
      expect(grouped[dates[1]]!.map((e) => e.id), equals(['3']));
    });
  });

  group('NavigationStack', () {
    test('manages push, undo (goBack), redo (goForward) correctly', () {
      final stack = NavigationStack();
      final ref1 = const PassageReference(bookId: 'Gen', chapter: 1);
      final ref2 = const PassageReference(bookId: 'Exo', chapter: 2);
      final ref3 = const PassageReference(bookId: 'Lev', chapter: 3);

      expect(stack.canGoBack, isFalse);
      expect(stack.canGoForward, isFalse);

      stack.push(ref1);
      expect(stack.current, equals(ref1));
      expect(stack.canGoBack, isFalse);

      stack.push(ref2);
      stack.push(ref3);
      expect(stack.current, equals(ref3));
      expect(stack.canGoBack, isTrue);
      expect(stack.canGoForward, isFalse);

      final backRef = stack.goBack();
      expect(backRef, equals(ref2));
      expect(stack.current, equals(ref2));
      expect(stack.canGoForward, isTrue);

      final backRef2 = stack.goBack();
      expect(backRef2, equals(ref1));

      final ref4 = const PassageReference(bookId: 'Num', chapter: 4);
      stack.push(ref4);
      expect(stack.current, equals(ref4));
      expect(stack.canGoForward, isFalse);
    });
  });
}
