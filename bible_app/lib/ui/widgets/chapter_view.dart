import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/state/chapter_view_controller.dart';
import 'package:bible_app/ui/widgets/verse_reading_view.dart';
import 'package:bible_app/ui/widgets/interlinear_chapter_view.dart';
import 'package:bible_app/ui/widgets/study_mode_view.dart';
import 'package:bible_app/ui/widgets/study_mode_with_drawing_view.dart';

/// Main chapter view that switches between reading modes
class ChapterView extends StatefulWidget {
  final Chapter chapter;
  final UserContentRepository? contentRepository;
  final ReadingMode? initialMode;
  final void Function(ReadingMode)? onModeChanged;
  final bool showAppBar;

  const ChapterView({
    super.key,
    required this.chapter,
    this.contentRepository,
    this.initialMode,
    this.onModeChanged,
    this.showAppBar = true,
  });

  @override
  State<ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<ChapterView> {
  late ChapterViewController _controller;

  @override
  void initState() {
    super.initState();
    // Use provided repository or create default local repository
    final repository = widget.contentRepository ?? LocalUserContentRepository();
    _controller = ChapterViewController(repository, widget.chapter);
    
    // Set initial mode if provided
    if (widget.initialMode != null) {
      _controller.switchMode(widget.initialMode!);
    }
    
    // Listen to mode changes if callback provided
    if (widget.onModeChanged != null) {
      _controller.addListener(_notifyModeChange);
    }
  }

  void _notifyModeChange() {
    if (widget.onModeChanged != null) {
      widget.onModeChanged!(_controller.state.mode);
    }
  }

  @override
  void didUpdateWidget(ChapterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the chapter changed (different book or chapter number)
    final oldChapter = oldWidget.chapter;
    final newChapter = widget.chapter;
    final chapterChanged = oldChapter.bookId != newChapter.bookId ||
        oldChapter.number != newChapter.number ||
        oldChapter.verses.length != newChapter.verses.length;
    
    // Check if the mode changed
    final modeChanged = widget.initialMode != oldWidget.initialMode &&
        widget.initialMode != null;
    
    if (chapterChanged) {
      print('DEBUG ChapterView: Chapter changed from ${oldChapter.bookId} ${oldChapter.number} to ${newChapter.bookId} ${newChapter.number}');
      
      // Dispose old controller
      if (widget.onModeChanged != null) {
        _controller.removeListener(_notifyModeChange);
      }
      _controller.dispose();
      
      // Create new controller with new chapter
      final repository = widget.contentRepository ?? LocalUserContentRepository();
      _controller = ChapterViewController(repository, newChapter);
      
      // Restore mode if provided
      if (widget.initialMode != null) {
        _controller.switchMode(widget.initialMode!);
      }
      
      // Re-attach listener
      if (widget.onModeChanged != null) {
        _controller.addListener(_notifyModeChange);
      }
    } else if (modeChanged) {
      // Only mode changed, not the chapter
      print('DEBUG ChapterView: Mode changed to ${widget.initialMode}');
      _controller.switchMode(widget.initialMode!);
    }
  }

  @override
  void dispose() {
    if (widget.onModeChanged != null) {
      _controller.removeListener(_notifyModeChange);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      // Return just the content without app bar
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapter.bookId} ${widget.chapter.number}'),
        actions: [
          // Mode selector
          PopupMenuButton<ReadingMode>(
            icon: const Icon(Icons.view_module),
            tooltip: 'Reading Mode',
            onSelected: (mode) => _controller.switchMode(mode),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ReadingMode.verse,
                child: ListTile(
                  leading: const Icon(Icons.format_list_numbered),
                  title: const Text('Verse Mode'),
                  subtitle: const Text('Traditional verse-by-verse'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: ReadingMode.interlinear,
                child: ListTile(
                  leading: const Icon(Icons.translate),
                  title: const Text('Interlinear Mode'),
                  subtitle: const Text('Word-by-word with Hebrew/Greek'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: ReadingMode.study,
                child: ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Study Mode'),
                  subtitle: const Text('With highlights and arcs'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: ReadingMode.drawing,
                child: ListTile(
                  leading: const Icon(Icons.draw),
                  title: const Text('Drawing Mode'),
                  subtitle: const Text('Freehand sketching'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          
          // Options menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'toggle_verse_numbers',
                checked: _controller.state.showVerseNumbers,
                child: const Text('Show Verse Numbers'),
              ),
              if (_controller.state.mode == ReadingMode.study || 
                  _controller.state.mode == ReadingMode.drawing) ...[
                const PopupMenuDivider(),
                CheckedPopupMenuItem(
                  value: 'toggle_highlights',
                  checked: _controller.state.studySettings.showHighlights,
                  child: const Text('Show Highlights'),
                ),
                CheckedPopupMenuItem(
                  value: 'toggle_arcs',
                  checked: _controller.state.studySettings.showArcs,
                  child: const Text('Show Arcs'),
                ),
                CheckedPopupMenuItem(
                  value: 'toggle_notes',
                  checked: _controller.state.studySettings.showNotes,
                  child: const Text('Show Notes'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'export',
                  child: Text('Export Content'),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Text('Import Content'),
                ),
              ],
            ],
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        print('DEBUG ChapterView: mode=${state.mode}, isLoading=${state.isLoading}, verses=${state.chapter.verses.length}');
        
        if (state.isLoading) {
          print('DEBUG ChapterView: Showing loading indicator');
          return const Center(child: CircularProgressIndicator());
        }

        print('DEBUG ChapterView: Rendering mode ${state.mode}');
        switch (state.mode) {
          case ReadingMode.verse:
            print('DEBUG ChapterView: Building VerseReadingView');
            return VerseReadingView(controller: _controller);
          case ReadingMode.interlinear:
            print('DEBUG ChapterView: Building InterlinearChapterView');
            return InterlinearChapterView(
              verses: widget.chapter.verses,
              bookId: widget.chapter.bookId,
              chapter: widget.chapter.number,
            );
          case ReadingMode.study:
            print('DEBUG ChapterView: Building StudyModeView');
            return StudyModeView(controller: _controller);
          case ReadingMode.drawing:
            print('DEBUG ChapterView: Building DrawingModeView');
            return StudyModeWithDrawingView(controller: _controller);
        }
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_verse_numbers':
        _controller.toggleVerseNumbers();
        break;
      case 'toggle_highlights':
        _controller.updateStudySettings(
          _controller.state.studySettings.copyWith(
            showHighlights: !_controller.state.studySettings.showHighlights,
          ),
        );
        break;
      case 'toggle_arcs':
        _controller.updateStudySettings(
          _controller.state.studySettings.copyWith(
            showArcs: !_controller.state.studySettings.showArcs,
          ),
        );
        break;
      case 'toggle_notes':
        _controller.updateStudySettings(
          _controller.state.studySettings.copyWith(
            showNotes: !_controller.state.studySettings.showNotes,
          ),
        );
        break;
      case 'export':
        _exportContent();
        break;
      case 'import':
        _importContent();
        break;
    }
  }

  Future<void> _exportContent() async {
    // Get all content IDs for this chapter
    final highlights = _controller.state.highlights;
    final arcs = _controller.state.arcs;
    final notes = _controller.state.notes;
    
    final ids = [
      ...highlights.map((h) => h.id),
      ...arcs.map((a) => a.id),
      ...notes.map((n) => n.id),
    ];

    if (ids.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No content to export')),
      );
      return;
    }

    final json = await _controller.exportContent(ids);
    
    // TODO: Share or save the JSON
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${ids.length} items')),
    );
  }

  Future<void> _importContent() async {
    // TODO: Show file picker or paste dialog
    // For now, just show a placeholder message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon')),
    );
  }
}
