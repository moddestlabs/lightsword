import 'package:flutter/material.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/ui/widgets/chapter_picker_modal.dart';
import 'package:bible_app/ui/widgets/book_selection_page.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<Verse> _verses = [];
  Book? _currentBook;
  List<Book> _allBooks = [];
  bool _isLoading = true;
  String? _error;
  
  String _bookId = 'John';
  int _chapter = 1;
  String _translation = 'BSB'; // Bible version abbreviation
  
  PassageReference get _currentRef => PassageReference(
    bookId: _bookId,
    chapter: _chapter,
  );

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadBook();
    _loadVerses();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await BibleService.instance.getBooks();
      setState(() {
        _allBooks = books;
      });
    } catch (e) {
      debugPrint('Failed to load books: $e');
    }
  }

  Future<void> _loadBook() async {
    try {
      final book = await BibleService.instance.getBook(_bookId);
      setState(() {
        _currentBook = book;
      });
    } catch (e) {
      // Book loading failed, but we can still display verses
      debugPrint('Failed to load book: $e');
    }
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verses = await BibleService.instance.getVerses(_currentRef);
      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _previousChapter() {
    if (_chapter > 1) {
      setState(() {
        _chapter--;
      });
      _loadVerses();
    }
  }

  void _nextChapter() {
    if (_currentBook != null && _chapter < _currentBook!.chapterCount) {
      setState(() {
        _chapter++;
      });
      _loadVerses();
    }
  }

  void _showBookSelection() {
    if (_allBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading books...')),
      );
      return;
    }

    BookSelectionPage.show(
      context: context,
      currentBookId: _bookId,
      books: _allBooks,
      onBookSelected: (book) {
        setState(() {
          _bookId = book.id;
          _chapter = 1; // Reset to chapter 1 when changing books
          _currentBook = book;
        });
        _loadVerses();
      },
    );
  }

  void _showChapterPicker() {
    if (_currentBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading book information...')),
      );
      return;
    }

    ChapterPickerModal.show(
      context: context,
      bookName: _currentBook!.name,
      currentChapter: _chapter,
      chapterCount: _currentBook!.chapterCount,
      onChapterSelected: (chapter) {
        setState(() {
          _chapter = chapter;
        });
        _loadVerses();
      },
    );
  }

  void _showTranslationPicker() {
    // TODO: Implement translation picker modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Translation picker coming soon')),
    );
  }

  void _toggleBookmark() {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 44,
        leading: null,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Chapter navigation
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _previousChapter,
                  child: Icon(
                    Icons.chevron_left,
                    color: _chapter > 1 
                        ? const Color(0xFF007AFF)
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                GestureDetector(
                  onTap: _showChapterPicker,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _showBookSelection,
                          child: Text(
                            _currentBook?.name ?? _bookId,
                            style: const TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_chapter',
                          style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _nextChapter,
                  child: Icon(
                    Icons.chevron_right,
                    color: _currentBook != null && _chapter < _currentBook!.chapterCount
                        ? const Color(0xFF007AFF)
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
              ],
            ),
            // Center: App name
            const Text(
              'Dabar',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Right: Translation + Bookmark
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showTranslationPicker,
                  child: Text(
                    _translation,
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: const Icon(
                    Icons.bookmark_border,
                    color: Color(0xFF007AFF),
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    'ERROR: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final verse in _verses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Verse number in left margin
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${verse.number}',
                                  style: const TextStyle(
                                    color: Color(0xFF007AFF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              // Verse text
                              Expanded(
                                child: Text(
                                  verse.text,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w400,
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
