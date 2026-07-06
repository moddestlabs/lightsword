import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/book.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/services/deep_linking_service.dart';
import 'package:bible_app/ui/widgets/chapter_picker_modal.dart';
import 'package:bible_app/ui/widgets/book_selection_page.dart';
import 'package:bible_app/ui/widgets/interlinear_view.dart';
import 'package:bible_app/ui/widgets/interlinear_chapter_view.dart';
import 'package:bible_app/ui/widgets/tts_control_widget.dart';
import 'package:bible_app/ui/models/view_mode.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => ReaderScreenState();
}

class ReaderScreenState extends State<ReaderScreen> {
  List<Verse> _verses = [];
  Book? _currentBook;
  List<Book> _allBooks = [];
  bool _isLoading = true;
  String? _error;
  
  String _bookId = 'John';
  int _chapter = 1;
  int? _startVerse; // For verse ranges
  int? _endVerse;   // For verse ranges
  String _translation = 'BSB'; // Bible version abbreviation
  ViewMode _viewMode = ViewMode.standard; // Current display mode
  
  PassageReference get _currentRef => PassageReference(
    bookId: _bookId,
    chapter: _chapter,
    startVerse: _startVerse,
    endVerse: _endVerse,
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
      
      // Filter verses if we have a verse range
      List<Verse> filteredVerses = verses;
      if (_startVerse != null && _endVerse != null) {
        filteredVerses = verses
            .where((v) => v.number >= _startVerse! && v.number <= _endVerse!)
            .toList();
      }
      
      setState(() {
        _verses = filteredVerses;
        _isLoading = false;
      });
      
      // Update URL to reflect current location
      _updateUrl();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Update browser URL to match current passage (web only)
  void _updateUrl() {
    DeepLinkingService.instance.updateWebUrl(_currentRef, _viewMode);
  }

  /// Navigate to a specific reference (called from deep links)
  void navigateToReference(PassageReference reference, {ViewMode? viewMode}) {
    setState(() {
      _bookId = reference.bookId;
      _chapter = reference.chapter;
      _startVerse = reference.startVerse;
      _endVerse = reference.endVerse;
      if (viewMode != null) {
        _viewMode = viewMode;
      }
    });
    _loadBook();
    _loadVerses();
  }

  void _previousChapter() {
    if (_chapter > 1) {
      setState(() {
        _chapter--;
        _startVerse = null; // Clear verse range when changing chapters
        _endVerse = null;
      });
      _loadVerses();
    }
  }

  void _nextChapter() {
    if (_currentBook != null && _chapter < _currentBook!.chapterCount) {
      setState(() {
        _chapter++;
        _startVerse = null; // Clear verse range when changing chapters
        _endVerse = null;
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
          _startVerse = null; // Clear verse range
          _endVerse = null;
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
          _startVerse = null; // Clear verse range
          _endVerse = null;
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

  void _toggleViewMode() {
    setState(() {
      // Toggle between standard and interlinear
      _viewMode = _viewMode == ViewMode.standard 
          ? ViewMode.interlinear 
          : ViewMode.standard;
    });
    // Update URL to reflect new view mode
    _updateUrl();
  }

  /// Public method to set interlinear mode (called from navigation)
  void setInterlinearMode() {
    if (_viewMode != ViewMode.interlinear) {
      setState(() {
        _viewMode = ViewMode.interlinear;
      });
      _updateUrl();
    }
  }

  /// Public method to set standard reading mode (called from navigation)
  void setStandardMode() {
    if (_viewMode != ViewMode.standard) {
      setState(() {
        _viewMode = ViewMode.standard;
      });
      _updateUrl();
    }
  }

  void _showInterlinear(Verse verse) {
    if (_currentBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading book information...')),
      );
      return;
    }

    InterlinearReaderPage.show(
      context: context,
      bookName: _currentBook!.name,
      bookId: _currentBook!.id,
      chapter: _chapter,
      verseNumber: verse.number,
      verse: verse,
    );
  }

  void _startTtsReading() {
    if (_verses.isEmpty) return;
    TtsService.instance.readVerses(_verses);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
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
                Listener(
                  onPointerDown: (event) {
                    if (event.buttons == kMiddleMouseButton) {
                      _showChapterPicker();
                    }
                  },
                  child: GestureDetector(
                    onTap: _previousChapter,
                    onLongPress: _showChapterPicker,
                    child: Icon(
                      Icons.chevron_left,
                      color: _chapter > 1 
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.38),
                      size: 24,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showChapterPicker,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Listener(
                          onPointerDown: (event) {
                            if (event.buttons == kMiddleMouseButton) {
                              _showChapterPicker();
                            }
                          },
                          child: GestureDetector(
                            onTap: _showBookSelection,
                            onLongPress: _showChapterPicker,
                            child: Text(
                              _currentBook?.name ?? _bookId,
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_chapter',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Listener(
                  onPointerDown: (event) {
                    if (event.buttons == kMiddleMouseButton) {
                      _showChapterPicker();
                    }
                  },
                  child: GestureDetector(
                    onTap: _nextChapter,
                    onLongPress: _showChapterPicker,
                    child: Icon(
                      Icons.chevron_right,
                      color: _currentBook != null && _chapter < _currentBook!.chapterCount
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.38),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            // Center: App name
            Text(
              'LIGHTSWORD',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Right: Translation + Bookmark + TTS
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showTranslationPicker,
                  child: Text(
                    _translation,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: Icon(
                    Icons.bookmark_border,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _verses.isNotEmpty ? _startTtsReading : null,
                  child: Icon(
                    Icons.volume_up,
                    color: _verses.isNotEmpty ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.38),
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                        'ERROR: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _buildContentView(),
          // Floating TTS controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: TtsControlWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    switch (_viewMode) {
      case ViewMode.standard:
        return _buildStandardView();
      case ViewMode.interlinear:
        return _buildInterlinearView();
      case ViewMode.paragraph:
        // Not yet implemented
        return _buildStandardView();
    }
  }

  Widget _buildStandardView() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final verse in _verses)
            GestureDetector(
              onTap: () => _showInterlinear(verse),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verse number in left margin
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${verse.number}',
                        style: TextStyle(
                          color: colorScheme.primary,
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
                        style: TextStyle(
                          color: colorScheme.onSurface,
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
            ),
          // Add padding at bottom for TTS controls
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInterlinearView() {
    return InterlinearChapterView(
      verses: _verses,
      bookId: _bookId,
      chapter: _chapter,
    );
  }
}
