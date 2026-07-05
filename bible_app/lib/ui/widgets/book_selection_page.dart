import 'package:flutter/material.dart';
import 'package:bible_core/models/book.dart';

/// Full-screen page for selecting a Bible book
class BookSelectionPage extends StatefulWidget {
  final String currentBookId;
  final List<Book> books;
  final Function(Book) onBookSelected;

  const BookSelectionPage({
    super.key,
    required this.currentBookId,
    required this.books,
    required this.onBookSelected,
  });

  /// Show the book selection as a full-screen page
  static Future<void> show({
    required BuildContext context,
    required String currentBookId,
    required List<Book> books,
    required Function(Book) onBookSelected,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookSelectionPage(
          currentBookId: currentBookId,
          books: books,
          onBookSelected: onBookSelected,
        ),
      ),
    );
  }

  @override
  State<BookSelectionPage> createState() => _BookSelectionPageState();
}

class _BookSelectionPageState extends State<BookSelectionPage> {
  Testament _selectedTestament = Testament.new_;

  @override
  void initState() {
    super.initState();
    // Default to the testament of the current book
    final currentBook = widget.books.where((b) => b.id == widget.currentBookId).firstOrNull;
    if (currentBook != null) {
      _selectedTestament = currentBook.testament;
    }
  }

  List<Book> get _filteredBooks {
    return widget.books
        .where((book) => book.testament == _selectedTestament)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: const SizedBox.shrink(),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // OT/NT Tabs
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTestament = Testament.old;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedTestament == Testament.old
                          ? colorScheme.surfaceContainerHighest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'OT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedTestament == Testament.old
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTestament = Testament.new_;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedTestament == Testament.new_
                          ? colorScheme.surfaceContainerHighest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedTestament == Testament.new_
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Done button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Done',
                style: TextStyle(
                  fontSize: 17,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredBooks.length,
        itemBuilder: (context, index) {
          final book = _filteredBooks[index];
          final isCurrentBook = book.id == widget.currentBookId;

          return GestureDetector(
            onTap: () {
              widget.onBookSelected(book);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isCurrentBook ? colorScheme.surfaceContainerHighest : colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    book.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        book.abbreviation,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.75),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
