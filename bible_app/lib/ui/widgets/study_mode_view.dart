import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/state/chapter_view_controller.dart';
import 'package:bible_app/ui/widgets/arc_painter.dart';
import 'package:bible_app/ui/widgets/study_toolbar.dart';

/// Study mode view with paragraph layout, highlights, arcs, and notes
class StudyModeView extends StatefulWidget {
  final ChapterViewController controller;

  const StudyModeView({
    super.key,
    required this.controller,
  });

  @override
  State<StudyModeView> createState() => _StudyModeViewState();
}

class _StudyModeViewState extends State<StudyModeView> {
  final GlobalKey _textKey = GlobalKey();
  TextSelection? _currentSelection;
  Offset? _selectionOffset;
  final Map<int, ArcGeometry> _arcGeometry = {};

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final settings = state.studySettings;

    return Stack(
      children: [
        // Main text with highlights and arcs
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text with highlights
                CustomPaint(
                  key: _textKey,
                  painter: settings.showArcs
                      ? ArcPainter(
                          arcs: state.arcs,
                          arcGeometry: _arcGeometry,
                        )
                      : null,
                  child: SelectableText.rich(
                    TextSpan(
                      children: _buildTextSpans(state),
                      style: TextStyle(
                        fontSize: settings.textSize,
                        height: 1.8,
                      ),
                    ),
                    onSelectionChanged: _handleSelectionChanged,
                  ),
                ),

                // Study notes section
                if (settings.showNotes && state.notes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _NotesSection(
                    notes: state.notes,
                    onEditNote: (note) => _showNoteEditor(context, note),
                    onDeleteNote: (id) => widget.controller.deleteNote(id),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Floating toolbar
        if (_currentSelection != null && _selectionOffset != null)
          Positioned(
            top: _selectionOffset!.dy - 80,
            left: _selectionOffset!.dx,
            child: StudyToolbar(
              onHighlight: _showHighlightColorPicker,
              onArc: _showArcTypePicker,
              onNote: _showNoteEditor,
              onCopy: _copySelection,
            ),
          ),
      ],
    );
  }

  List<InlineSpan> _buildTextSpans(ChapterViewState state) {
    final spans = <InlineSpan>[];
    final settings = state.studySettings;

    for (var verse in state.chapter.verses) {
      // Verse number (optional)
      if (state.showVerseNumbers) {
        spans.add(TextSpan(
          text: '${verse.number} ',
          style: TextStyle(
            fontSize: settings.textSize * 0.7,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.superscripts()],
          ),
        ));
      }

      // Verse text with highlights
      if (settings.showHighlights) {
        spans.addAll(_buildHighlightedText(verse, state.highlights));
      } else {
        spans.add(TextSpan(text: '${verse.text} '));
      }

      // Add space between verses in paragraph mode
      if (settings.paragraphMode) {
        spans.add(const TextSpan(text: ' '));
      } else {
        // Add line break for verse-per-line mode
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  List<InlineSpan> _buildHighlightedText(Verse verse, List<Highlight> allHighlights) {
    final spans = <InlineSpan>[];
    final verseHighlights = allHighlights
        .where((h) {
          final start = h.reference.startVerse;
          final end = h.reference.endVerse;
          if (start == null) return false;
          return start == verse.number ||
              (end != null && start <= verse.number && end >= verse.number);
        })
        .toList();

    if (verseHighlights.isEmpty) {
      spans.add(TextSpan(text: '${verse.text} '));
      return spans;
    }

    // Word-level highlighting: tokenize verse and apply highlights to word ranges
    final words = _tokenizeVerse(verse.text);
    
    for (int i = 0; i < words.length; i++) {
      // Check if this word is highlighted
      Highlight? activeHighlight;
      for (var highlight in verseHighlights) {
        if (i >= highlight.wordStart && i <= highlight.wordEnd) {
          activeHighlight = highlight;
          break;
        }
      }
      
      spans.add(TextSpan(
        text: words[i],
        style: activeHighlight != null
            ? TextStyle(backgroundColor: activeHighlight.color.withOpacity(0.3))
            : null,
      ));
    }
    
    spans.add(const TextSpan(text: ' ')); // Space after verse

    return spans;
  }
  
  /// Tokenize verse text into words, preserving spaces and punctuation
  List<String> _tokenizeVerse(String text) {
    final words = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);
      
      // Add word on space or end of string
      if (char == ' ' || i == text.length - 1) {
        words.add(buffer.toString());
        buffer.clear();
      }
    }
    
    return words;
  }

  void _handleSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    if (selection.isCollapsed) {
      setState(() {
        _currentSelection = null;
        _selectionOffset = null;
      });
      return;
    }

    // Get the render box to calculate selection position
    final renderBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _currentSelection = selection;
        // Approximate position - in production, calculate more precisely
        _selectionOffset = Offset(
          renderBox.size.width / 2 - 100,
          50.0,
        );
      });
    }
  }

  void _showHighlightColorPicker() {
    if (_currentSelection == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => HighlightColorPicker(
        onColorSelected: (color) {
          _addHighlight(color);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showArcTypePicker() {
    if (_currentSelection == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => ArcTypePicker(
        onArcSelected: (type, color) {
          _addArc(type, color);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showNoteEditor([BuildContext? ctx, StudyNote? existingNote]) {
    final dialogContext = ctx ?? context;
    
    showDialog(
      context: dialogContext,
      builder: (context) => _NoteEditorDialog(
        note: existingNote,
        reference: PassageReference(
          bookId: widget.controller.state.chapter.bookId,
          chapter: widget.controller.state.chapter.number,
        ),
        onSave: (note) {
          if (existingNote != null) {
            widget.controller.updateNote(note);
          } else {
            widget.controller.addNote(note);
          }
        },
      ),
    );

    // Clear selection after showing dialog - setState needed here to update UI immediately
    setState(() {
      _currentSelection = null;
      _selectionOffset = null;
    });
  }

  void _addHighlight(Color color) {
    if (_currentSelection == null) return;

    // Calculate which verse and words were selected
    final verses = widget.controller.state.chapter.verses;
    final showVerseNumbers = widget.controller.state.showVerseNumbers;
    
    // Build full text to map character positions
    int charPosition = 0;
    Verse? selectedVerse;
    int wordStart = 0;
    int wordEnd = 0;
    
    for (var verse in verses) {
      // Account for verse number if shown
      if (showVerseNumbers) {
        charPosition += '${verse.number} '.length;
      }
      
      final verseTextStart = charPosition;
      final verseTextEnd = charPosition + verse.text.length;
      
      // Check if selection overlaps with this verse
      if (_currentSelection!.start >= verseTextStart && _currentSelection!.start < verseTextEnd) {
        selectedVerse = verse;
        
        // Calculate word indices within the verse
        final words = _tokenizeVerse(verse.text);
        int wordCharPos = verseTextStart;
        
        // Find start word
        for (int i = 0; i < words.length; i++) {
          final wordLen = words[i].length;
          if (_currentSelection!.start >= wordCharPos && _currentSelection!.start < wordCharPos + wordLen) {
            wordStart = i;
          }
          if (_currentSelection!.end >= wordCharPos && _currentSelection!.end <= wordCharPos + wordLen) {
            wordEnd = i;
          }
          wordCharPos += wordLen;
        }
        
        break;
      }
      
      charPosition = verseTextEnd + 1; // +1 for space or newline
    }
    
    if (selectedVerse == null) {
      print('DEBUG: Could not determine selected verse');
      return;
    }
    
    print('DEBUG: Adding highlight to verse ${selectedVerse.number}, words $wordStart-$wordEnd');
    
    final highlight = Highlight.create(
      reference: PassageReference(
        bookId: widget.controller.state.chapter.bookId,
        chapter: widget.controller.state.chapter.number,
        startVerse: selectedVerse.number,
        endVerse: selectedVerse.number,
      ),
      wordStart: wordStart,
      wordEnd: wordEnd,
      color: color,
    );

    widget.controller.addHighlight(highlight);
    
    // Don't call setState - the controller will notify listeners which triggers rebuild
    // Just clear the selection state for the next interaction
    _currentSelection = null;
    _selectionOffset = null;
  }

  void _addArc(ArcType type, Color color) {
    if (_currentSelection == null) return;

    // TODO: Calculate actual verse and word indices from selection
    final firstVerse = widget.controller.state.chapter.verses.first;

    final arc = Arc.create(
      reference: PassageReference(
        bookId: widget.controller.state.chapter.bookId,
        chapter: widget.controller.state.chapter.number,
        startVerse: firstVerse.number,
        endVerse: firstVerse.number,
      ),
      fromWordIndex: 0,
      toWordIndex: 3,
      type: type,
      color: color,
    );

    widget.controller.addArc(arc);
    
    // Don't call setState - the controller will notify listeners which triggers rebuild
    _currentSelection = null;
    _selectionOffset = null;
  }

  void _copySelection() async {
    if (_currentSelection == null) return;
    
    // Build full text from verses
    final verses = widget.controller.state.chapter.verses;
    final showVerseNumbers = widget.controller.state.showVerseNumbers;
    final buffer = StringBuffer();
    
    for (var verse in verses) {
      if (showVerseNumbers) {
        buffer.write('${verse.number} ');
      }
      buffer.write(verse.text);
      buffer.write(' ');
    }
    
    final fullText = buffer.toString();
    final selectedText = fullText.substring(
      _currentSelection!.start,
      _currentSelection!.end,
    );
    
    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: selectedText));
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // Clear selection - no setState needed, just update local state
    _currentSelection = null;
    _selectionOffset = null;
  }
}

/// Section displaying study notes
class _NotesSection extends StatelessWidget {
  final List<StudyNote> notes;
  final void Function(StudyNote note) onEditNote;
  final void Function(String id) onDeleteNote;

  const _NotesSection({
    required this.notes,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Notes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...notes.map((note) => _NoteCard(
              note: note,
              onEdit: () => onEditNote(note),
              onDelete: () => onDeleteNote(note.id),
            )),
      ],
    );
  }
}

/// Card displaying a single study note
class _NoteCard extends StatelessWidget {
  final StudyNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.reference.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.content),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: note.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating/editing notes
class _NoteEditorDialog extends StatefulWidget {
  final StudyNote? note;
  final PassageReference reference;
  final void Function(StudyNote note) onSave;

  const _NoteEditorDialog({
    this.note,
    required this.reference,
    required this.onSave,
  });

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late TextEditingController _contentController;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _tagsController = TextEditingController(
      text: widget.note?.tags.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma-separated)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveNote,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveNote() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final note = widget.note?.copyWith(
          content: content,
          tags: tags,
          modifiedAt: DateTime.now(),
        ) ??
        StudyNote.create(
          reference: widget.reference,
          content: content,
          tags: tags,
        );

    widget.onSave(note);
    Navigator.pop(context);
  }
}
