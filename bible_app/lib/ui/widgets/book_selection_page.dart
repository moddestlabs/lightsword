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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                          ? const Color(0xFFF2F2F7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'OT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedTestament == Testament.old
                            ? Colors.black
                            : Colors.grey.shade600,
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
                          ? const Color(0xFFF2F2F7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _selectedTestament == Testament.new_
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Done button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF007AFF),
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
                color: isCurrentBook ? const Color(0xFFF2F2F7) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        book.abbreviation,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.grey.shade500,
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
