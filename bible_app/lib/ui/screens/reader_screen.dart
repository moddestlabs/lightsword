import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/services/deep_linking_service.dart';
import 'package:bible_app/services/preferences_service.dart';
import 'package:bible_app/services/pwa_service.dart';
import 'package:bible_app/state/chapter_view_controller.dart';
import 'package:bible_app/ui/widgets/chapter_picker_modal.dart';
import 'package:bible_app/ui/widgets/book_selection_page.dart';
import 'package:bible_app/ui/widgets/chapter_view.dart';
import 'package:bible_app/ui/widgets/chapter_view_editor_dialog.dart';
import 'package:bible_app/ui/widgets/configurable_chapter_view.dart';
import 'package:bible_app/ui/widgets/tts_control_widget.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';
import 'package:bible_app/ui/models/view_mode.dart' as old_view;

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
  PassageReference? _offlineFallbackReference;
  
  String _bookId = 'John';
  int _chapter = 1;
  int? _startVerse; // For verse ranges
  int? _endVerse;   // For verse ranges
  BibleTextSource _textSource = BibleService.currentSource;
  ReadingMode _viewMode = ReadingMode.verse; // Reading vs study surface
  List<ChapterViewDefinition> _customViews = const [];
  ChapterViewDefinition _selectedView = ChapterViewDefinition.lineByLineView;
  
  // Persistent repository instance to maintain user content across rebuilds
  final LocalUserContentRepository _contentRepository = LocalUserContentRepository();
  
  PassageReference get _currentRef => PassageReference(
    bookId: _bookId,
    chapter: _chapter,
    startVerse: _startVerse,
    endVerse: _endVerse,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedViews();
    _loadBooks();
    _loadBook();
    _loadVerses();
  }

  List<ChapterViewDefinition> get _availableViews => [
        ...ChapterViewDefinition.defaults,
        ..._customViews,
      ];

  IconData get _selectedViewIcon {
    if (_selectedView.showOriginalLanguage || _selectedView.showGloss) {
      return Icons.translate;
    }
    if (_selectedView.lineByLine) {
      return Icons.format_list_numbered;
    }
    return Icons.notes;
  }

  void _loadSavedViews() {
    final savedCustomViews = PreferencesService.instance.getCustomChapterViews();
    final savedViewId = PreferencesService.instance.getSelectedChapterViewId();
    final matchingView = [
      ...ChapterViewDefinition.defaults,
      ...savedCustomViews,
    ].where((view) => view.id == savedViewId).firstOrNull;

    setState(() {
      _customViews = savedCustomViews;
      _selectedView = matchingView ?? ChapterViewDefinition.lineByLineView;
      _textSource = BibleService.currentSource;
    });
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
      _offlineFallbackReference = null;
    });

    try {
      final verses = await BibleService.instance.getVerses(_currentRef);

      final offlineMessage = _buildOfflineUnavailableMessage(
        reference: _currentRef,
        loadedVerses: verses,
      );
      if (offlineMessage != null) {
        setState(() {
          _verses = const [];
          _error = offlineMessage;
          _offlineFallbackReference = const PassageReference(
            bookId: 'John',
            chapter: 1,
          );
          _isLoading = false;
        });
        return;
      }
      
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
        _offlineFallbackReference = null;
      });
      
      // Update URL to reflect current location
      _updateUrl();
    } catch (e) {
      final offlineMessage = _buildOfflineUnavailableMessage(
        reference: _currentRef,
        loadedVerses: null,
      );
      setState(() {
        _error = offlineMessage ?? e.toString();
        _offlineFallbackReference = offlineMessage == null
            ? null
            : const PassageReference(
                bookId: 'John',
                chapter: 1,
              );
        _isLoading = false;
      });
    }
  }

  String? _buildOfflineUnavailableMessage({
    required PassageReference reference,
    required List<Verse>? loadedVerses,
  }) {
    final pwa = PwaService.instance;
    if (!pwa.isWeb || pwa.isOnline) {
      return null;
    }

    final book = _resolveBook(reference.bookId);
    final isOldTestament = book?.testament == Testament.old;
    final otPackStatus = pwa.offlinePackStatuses[OfflinePackId.originalLanguageOt];
    final hasOtOfflinePack = otPackStatus?.isInstalled ?? false;

    if (_textSource == BibleTextSource.originalLanguage &&
        isOldTestament &&
        !hasOtOfflinePack &&
        (loadedVerses == null || loadedVerses.isEmpty)) {
      return 'This Old Testament chapter is not installed for offline use yet. Open Settings while online and download the Original Language OT pack, or use the offline fallback below.';
    }

    if (_textSource == BibleTextSource.bsb &&
        (loadedVerses == null || loadedVerses.isEmpty)) {
      return 'The BSB translation is not currently cached offline. Switch to Hebrew/Greek Glosses or use the offline fallback below.';
    }

    return null;
  }

  Book? _resolveBook(String bookId) {
    if (_currentBook?.id == bookId) {
      return _currentBook;
    }

    for (final book in _allBooks) {
      if (book.id == bookId) {
        return book;
      }
    }

    return null;
  }

  Future<void> _openOfflineFallback() async {
    final fallbackReference = _offlineFallbackReference;
    if (fallbackReference == null) {
      return;
    }

    if (_textSource != BibleTextSource.originalLanguage) {
      await BibleService.setSource(BibleTextSource.originalLanguage);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _textSource = BibleTextSource.originalLanguage;
      _bookId = fallbackReference.bookId;
      _chapter = fallbackReference.chapter;
      _startVerse = fallbackReference.startVerse;
      _endVerse = fallbackReference.endVerse;
      _error = null;
      _offlineFallbackReference = null;
    });

    await _loadBook();
    await _loadVerses();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opened John 1 from the default offline pack.'),
      ),
    );
  }

  /// Update browser URL to match current passage (web only)
  void _updateUrl() {
    final oldMode = _viewMode == ReadingMode.study || _viewMode == ReadingMode.drawing
      ? old_view.ViewMode.paragraph
      : _selectedView.showOriginalLanguage || _selectedView.showGloss
        ? old_view.ViewMode.interlinear
        : _selectedView.lineByLine
          ? old_view.ViewMode.standard
          : old_view.ViewMode.paragraph;
    DeepLinkingService.instance.updateWebUrl(_currentRef, oldMode);
  }

  /// Navigate to a specific reference (called from deep links)
  void navigateToReference(PassageReference reference, {old_view.ViewMode? viewMode}) {
    setState(() {
      _bookId = reference.bookId;
      _chapter = reference.chapter;
      _startVerse = reference.startVerse;
      _endVerse = reference.endVerse;
      if (viewMode != null) {
        _viewMode = ReadingMode.verse;
        _selectedView = switch (viewMode) {
          old_view.ViewMode.interlinear => ChapterViewDefinition.interlinearView,
          old_view.ViewMode.paragraph => ChapterViewDefinition.paragraphView,
          old_view.ViewMode.standard => ChapterViewDefinition.lineByLineView,
        };
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

  Future<void> _showTranslationPicker() async {
    final selectedSource = await showModalBottomSheet<BibleTextSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in BibleService.availableSources)
                ListTile(
                  leading: Icon(
                    option.isTranslation ? Icons.menu_book : Icons.translate,
                  ),
                  title: Text(option.label),
                  subtitle: Text(option.description),
                  trailing: option.source == _textSource
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(option.source),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedSource == null || selectedSource == _textSource) {
      return;
    }

    await BibleService.setSource(selectedSource);
    if (!mounted) {
      return;
    }

    setState(() {
      _textSource = selectedSource;
    });
    await _loadBooks();
    await _loadBook();
    await _loadVerses();
  }

  Future<void> _showViewPicker() async {
    final result = await showModalBottomSheet<_ViewPickerResult>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final availableViews = _availableViews;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final view in availableViews)
                ListTile(
                  leading: Icon(
                    view.showOriginalLanguage || view.showGloss
                        ? Icons.translate
                        : view.lineByLine
                            ? Icons.format_list_numbered
                            : Icons.notes,
                  ),
                  title: Text(view.name),
                  subtitle: Text(_describeView(view)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedView.id == view.id)
                        const Icon(Icons.check, size: 18),
                      IconButton(
                        tooltip: view.isBuiltIn ? 'Duplicate and edit' : 'Edit view',
                        onPressed: () {
                          Navigator.of(context).pop(
                            _ViewPickerResult.edit(view),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      if (!view.isBuiltIn)
                        IconButton(
                          tooltip: 'Delete view',
                          onPressed: () {
                            Navigator.of(context).pop(
                              _ViewPickerResult.delete(view),
                            );
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop(_ViewPickerResult.select(view));
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create View'),
                subtitle: const Text('Save a custom chapter reading layout'),
                onTap: () {
                  Navigator.of(context).pop(const _ViewPickerResult.create());
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result.action) {
      case _ViewPickerAction.select:
        if (result.view != null) {
          _applySelectedView(result.view!);
        }
        break;
      case _ViewPickerAction.create:
        await _createView();
        break;
      case _ViewPickerAction.edit:
        if (result.view != null) {
          await _editView(result.view!);
        }
        break;
      case _ViewPickerAction.delete:
        if (result.view != null) {
          await _deleteView(result.view!);
        }
        break;
    }
  }

  Future<void> _createView() async {
    final createdView = await ChapterViewEditorDialog.show(
      context,
      title: 'Create View',
      initialView: ChapterViewDefinition.lineByLineView.copyWith(
        id: _newViewId(),
        name: 'Custom View',
        isBuiltIn: false,
      ),
    );
    if (createdView == null) {
      return;
    }

    await _saveCustomView(createdView, selectAfterSave: true);
  }

  Future<void> _editView(ChapterViewDefinition view) async {
    final draft = view.isBuiltIn
        ? view.copyWith(
            id: _newViewId(),
            name: '${view.name} Copy',
            isBuiltIn: false,
          )
        : view;

    final updatedView = await ChapterViewEditorDialog.show(
      context,
      title: view.isBuiltIn ? 'Duplicate View' : 'Edit View',
      initialView: draft,
    );
    if (updatedView == null) {
      return;
    }

    await _saveCustomView(updatedView, selectAfterSave: true);
  }

  Future<void> _deleteView(ChapterViewDefinition view) async {
    if (view.isBuiltIn) {
      return;
    }

    final updatedViews = _customViews.where((item) => item.id != view.id).toList();
    await PreferencesService.instance.setCustomChapterViews(updatedViews);

    final nextView = _selectedView.id == view.id
        ? ChapterViewDefinition.lineByLineView
        : _selectedView;

    setState(() {
      _customViews = updatedViews;
      _selectedView = nextView;
      _viewMode = _viewMode == ReadingMode.study ? ReadingMode.study : ReadingMode.verse;
    });

    await PreferencesService.instance.setSelectedChapterViewId(nextView.id);
    _updateUrl();
  }

  Future<void> _saveCustomView(
    ChapterViewDefinition view, {
    required bool selectAfterSave,
  }) async {
    final existingIndex = _customViews.indexWhere((item) => item.id == view.id);
    final updatedViews = [..._customViews];
    if (existingIndex >= 0) {
      updatedViews[existingIndex] = view;
    } else {
      updatedViews.add(view);
    }

    await PreferencesService.instance.setCustomChapterViews(updatedViews);

    setState(() {
      _customViews = updatedViews;
      if (selectAfterSave) {
        _selectedView = view;
        _viewMode = ReadingMode.verse;
      } else if (_selectedView.id == view.id) {
        _selectedView = view;
      }
    });

    if (selectAfterSave || _selectedView.id == view.id) {
      await PreferencesService.instance.setSelectedChapterViewId(view.id);
      _updateUrl();
    }
  }

  void _applySelectedView(ChapterViewDefinition view) {
    setState(() {
      _selectedView = view;
      _viewMode = ReadingMode.verse;
    });
    PreferencesService.instance.setSelectedChapterViewId(view.id);
    _updateUrl();
  }

  String _newViewId() {
    return 'view_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _describeView(ChapterViewDefinition view) {
    final layout = view.lineByLine ? 'Line-by-line' : 'Paragraph';
    final layers = <String>[];
    if (view.showOriginalLanguage) {
      layers.add('Hebrew/Greek');
    }
    if (view.showTranslation) {
      layers.add('Primary text');
    }
    if (view.showGloss) {
      layers.add('Glosses');
    }
    return '$layout • ${layers.join(' • ')}';
  }

  /// Public method to set verse mode (called from navigation)
  void setVerseMode() {
    _applySelectedView(ChapterViewDefinition.lineByLineView);
  }

  bool get isShowingStudySurface {
    return _viewMode == ReadingMode.study || _viewMode == ReadingMode.drawing;
  }

  void showCurrentReadingView() {
    if (!isShowingStudySurface) {
      return;
    }

    setState(() {
      _viewMode = ReadingMode.verse;
    });
    _updateUrl();
  }

  void cycleAvailableView() {
    if (_availableViews.isEmpty) {
      return;
    }

    final currentIndex = _availableViews.indexWhere(
      (view) => view.id == _selectedView.id,
    );
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % _availableViews.length;
    _applySelectedView(_availableViews[nextIndex]);
  }

  /// Public method to set interlinear mode (called from navigation)
  void setInterlinearMode() {
    _applySelectedView(ChapterViewDefinition.interlinearView);
  }

  /// Public method to set standard reading mode (called from navigation)
  void setStandardMode() {
    // Alias for setVerseMode for backward compatibility
    setVerseMode();
  }

  /// Public method to set study mode (called from navigation)
  void setStudyMode() {
    if (_viewMode != ReadingMode.study) {
      setState(() {
        _viewMode = ReadingMode.study;
      });
      _updateUrl();
    }
  }

  // Old interlinear viewer - now handled by ChapterView ReadingMode.interlinear
  // void _showInterlinear(Verse verse) { ... }

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
            // Right: Translation + View + TTS
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showTranslationPicker,
                  child: Text(
                    BibleService.sourceLabel(_textSource),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showViewPicker,
                  child: Icon(
                    _selectedViewIcon,
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off, size: 36),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            if (_offlineFallbackReference != null) ...[
                              const SizedBox(height: 16),
                              FilledButton.tonalIcon(
                                onPressed: _openOfflineFallback,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Open John 1 Offline'),
                              ),
                            ],
                          ],
                        ),
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
    print('DEBUG: _buildContentView called, verses count: ${_verses.length}, mode: $_viewMode');
    
    if (_verses.isEmpty) {
      print('DEBUG: Verses are empty, showing error message');
      return const Center(child: Text('No verses loaded'));
    }

    // Create Chapter object from loaded verses
    final chapter = Chapter(
      bookId: _bookId,
      number: _chapter,
      verseCount: _verses.length,
      verses: _verses,
    );
    
    print('DEBUG: Created chapter ${chapter.bookId} ${chapter.number} with ${chapter.verses.length} verses');

    if (_viewMode == ReadingMode.study || _viewMode == ReadingMode.drawing) {
      return ChapterView(
        chapter: chapter,
        contentRepository: _contentRepository,
        initialMode: _viewMode,
        showAppBar: false,
        onModeChanged: (mode) {
          print('DEBUG: Mode changed callback received: $mode');
          setState(() {
            _viewMode = mode;
          });
          _updateUrl();
        },
      );
    }

    return ConfigurableChapterView(
      chapter: chapter,
      bookName: _currentBook?.name,
      view: _selectedView,
    );
  }
}

enum _ViewPickerAction {
  select,
  create,
  edit,
  delete,
}

class _ViewPickerResult {
  final _ViewPickerAction action;
  final ChapterViewDefinition? view;

  const _ViewPickerResult._(this.action, this.view);

  const _ViewPickerResult.select(ChapterViewDefinition view)
      : this._(_ViewPickerAction.select, view);

  const _ViewPickerResult.create()
      : this._(_ViewPickerAction.create, null);

  const _ViewPickerResult.edit(ChapterViewDefinition view)
      : this._(_ViewPickerAction.edit, view);

  const _ViewPickerResult.delete(ChapterViewDefinition view)
      : this._(_ViewPickerAction.delete, view);
}
