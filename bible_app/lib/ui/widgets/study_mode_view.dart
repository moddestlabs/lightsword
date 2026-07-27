import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/state/chapter_view_controller.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/ui/widgets/study_toolbar.dart';
import 'package:bible_app/ui/widgets/study_vertical_toolbar.dart';

/// Chapter-wide word reference with character bounds for gapless text rendering
class ChapterWordRef {
  final int globalIndex;
  final int verseNumber;
  final int wordIndex;
  final String text;
  final int charStart;
  final int charEnd;

  const ChapterWordRef({
    required this.globalIndex,
    required this.verseNumber,
    required this.wordIndex,
    required this.text,
    required this.charStart,
    required this.charEnd,
  });
}

/// Markup mode view with gapless continuous drag-to-select word highlighting & anchored notes
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
  final TtsService _ttsService = TtsService.instance;
  final Map<String, GlobalKey> _noteChipKeys = {};

  // Drag selection state
  bool _isDragging = false;
  int? _dragStartGlobal;
  int? _dragCurrentGlobal;
  Highlight? _activeHighlight;

  Color _activeHighlightColor = HighlightColors.yellow;
  bool _isEraserActive = false;
  bool _showNotes = true;

  final List<ChapterWordRef> _allWords = [];

  @override
  void initState() {
    super.initState();
    _ttsService.addListener(_handleTtsChanged);
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(StudyModeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _noteChipKeys.clear();
    _ttsService.removeListener(_handleTtsChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  GlobalKey _getOrCreateNoteChipKey(String id) {
    return _noteChipKeys.putIfAbsent(id, () => GlobalKey());
  }

  bool _isPointerOverNoteChip(Offset globalPosition) {
    if (!_showNotes) return false;
    for (var key in _noteChipKeys.values) {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final localPos = renderBox.globalToLocal(globalPosition);
        if (renderBox.paintBounds.contains(localPos)) {
          return true;
        }
      }
    }
    return false;
  }

  void _handleTtsChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  int? _getWordIndexAtOffset(Offset globalPosition) {
    final renderObj = _textKey.currentContext?.findRenderObject();
    if (renderObj == null || renderObj is! RenderParagraph) return null;

    final renderParagraph = renderObj;
    final localPos = renderParagraph.globalToLocal(globalPosition);
    final pos = renderParagraph.getPositionForOffset(localPos);
    final charIdx = pos.offset;

    for (var word in _allWords) {
      if (charIdx >= word.charStart && charIdx < word.charEnd) {
        return word.globalIndex;
      }
    }

    if (_allWords.isNotEmpty) {
      if (charIdx < _allWords.first.charStart) return 0;
      if (charIdx >= _allWords.last.charEnd) return _allWords.length - 1;
    }

    return null;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isPointerOverNoteChip(event.position)) {
      // Overrides text drag selection when tapping an anchored note chip
      return;
    }

    final wordIdx = _getWordIndexAtOffset(event.position);
    if (wordIdx != null) {
      Highlight? tappedHl;
      final wordRef = _allWords[wordIdx];
      for (var h in widget.controller.state.highlights) {
        final sVerse = h.reference.startVerse ?? 0;
        final eVerse = h.reference.endVerse ?? sVerse;
        if (wordRef.verseNumber >= sVerse && wordRef.verseNumber <= eVerse) {
          final realStart = min(h.wordStart, h.wordEnd);
          final realEnd = max(h.wordStart, h.wordEnd);
          if (wordRef.wordIndex >= realStart && wordRef.wordIndex <= realEnd) {
            tappedHl = h;
            break;
          }
        }
      }

      setState(() {
        _isDragging = true;
        _dragStartGlobal = wordIdx;
        _dragCurrentGlobal = wordIdx;
        _activeHighlight = tappedHl;
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isDragging || _dragStartGlobal == null) return;
    final wordIdx = _getWordIndexAtOffset(event.position);
    if (wordIdx != null && wordIdx != _dragCurrentGlobal) {
      setState(() {
        _dragCurrentGlobal = wordIdx;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) async {
    if (_isDragging && _dragStartGlobal != null && _dragCurrentGlobal != null) {
      final startIdx = min(_dragStartGlobal!, _dragCurrentGlobal!);
      final endIdx = max(_dragStartGlobal!, _dragCurrentGlobal!);

      await _applyHighlightRange(startIdx, endIdx);
    }

    setState(() {
      _isDragging = false;
      _dragStartGlobal = null;
      _dragCurrentGlobal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final settings = state.studySettings;

    return Stack(
      children: [
        // Main text with gapless word-based drag highlighting & anchored note overlays
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 68, 16),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text.rich(
                    key: _textKey,
                    TextSpan(
                      children: _buildTextSpans(state),
                      style: TextStyle(
                        fontSize: settings.textSize,
                        height: 1.8,
                      ),
                    ),
                  ),

                  // Anchored Floating Notes Overlays
                  if (_showNotes) ..._buildAnchoredNoteOverlays(state, context),
                ],
              ),
            ),
          ),
        ),

        // Vertical toolbar on right side
        Positioned(
          right: 12,
          top: 16,
          child: StudyVerticalToolbar(
            activeColor: _activeHighlightColor,
            isEraserActive: _isEraserActive,
            showNotes: _showNotes,
            hasActiveHighlight: _activeHighlight != null || _dragStartGlobal != null,
            hasExistingNote: _activeHighlight?.note != null && _activeHighlight!.note!.isNotEmpty,
            onColorSelected: (color) {
              setState(() {
                _activeHighlightColor = color;
                _isEraserActive = false;
              });
            },
            onErase: () {
              setState(() {
                _isEraserActive = !_isEraserActive;
              });
            },
            onToggleShowNotes: () {
              setState(() {
                _showNotes = !_showNotes;
              });
            },
            onNote: () => _showNoteEditor(context),
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _buildTextSpans(ChapterViewState state) {
    _allWords.clear();

    final spans = <InlineSpan>[];
    final settings = state.studySettings;
    int globalWordCounter = 0;
    int currentCharOffset = 0;

    int? dragMin;
    int? dragMax;
    if (_dragStartGlobal != null && _dragCurrentGlobal != null) {
      dragMin = min(_dragStartGlobal!, _dragCurrentGlobal!);
      dragMax = max(_dragStartGlobal!, _dragCurrentGlobal!);
    }

    for (var verse in state.chapter.verses) {
      // Verse number (optional)
      if (state.showVerseNumbers) {
        final verseNumText = '${verse.number} ';
        spans.add(
          TextSpan(
            text: verseNumText,
            style: TextStyle(
              fontSize: settings.textSize * 0.7,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.superscripts()],
            ),
          ),
        );
        currentCharOffset += verseNumText.length;
      }

      final words = _tokenizeVerse(verse.text);

      final verseHighlights = settings.showHighlights
          ? state.highlights.where((h) {
              final start = h.reference.startVerse;
              final end = h.reference.endVerse;
              if (start == null) return false;
              return start == verse.number ||
                  (end != null && start <= verse.number && end >= verse.number);
            }).toList()
          : <Highlight>[];

      final progress = _ttsService.progressState;
      final isActiveVerse = _ttsService.currentVerseNumber == verse.number &&
          progress != null &&
          progress.contentType == TtsContentType.translation &&
          progress.verseNumber == verse.number;

      for (int i = 0; i < words.length; i++) {
        final token = words[i];
        final tokenCharStart = currentCharOffset;
        final tokenCharEnd = tokenCharStart + token.length;
        currentCharOffset = tokenCharEnd;

        final currentGlobalIndex = globalWordCounter++;
        _allWords.add(
          ChapterWordRef(
            globalIndex: currentGlobalIndex,
            verseNumber: verse.number,
            wordIndex: i,
            text: token,
            charStart: tokenCharStart,
            charEnd: tokenCharEnd,
          ),
        );

        Highlight? activeHighlight;
        for (var highlight in verseHighlights) {
          final realStart = min(highlight.wordStart, highlight.wordEnd);
          final realEnd = max(highlight.wordStart, highlight.wordEnd);
          if (i >= realStart && i <= realEnd) {
            activeHighlight = highlight;
            break;
          }
        }

        final hasTtsHighlight = isActiveVerse &&
            progress.startOffset < tokenCharEnd &&
            progress.endOffset > tokenCharStart;

        final isDraggedWord = dragMin != null &&
            dragMax != null &&
            currentGlobalIndex >= dragMin &&
            currentGlobalIndex <= dragMax;

        final baseStyle = TextStyle(
          fontSize: settings.textSize,
          height: 1.8,
        );

        TextStyle style = baseStyle;
        if (activeHighlight != null) {
          final hlColor = Color(activeHighlight.colorValue);
          style = style.copyWith(
            backgroundColor: hlColor.withOpacity(0.45),
            color: hlColor.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          );
        }
        if (hasTtsHighlight) {
          final ttsColor = Theme.of(context).colorScheme.tertiaryContainer;
          style = style.copyWith(
            backgroundColor: ttsColor,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          );
        }
        if (isDraggedWord) {
          final hlColor = _isEraserActive
              ? Theme.of(context).colorScheme.errorContainer
              : _activeHighlightColor;
          style = style.copyWith(
            backgroundColor: hlColor.withOpacity(0.55),
            color: hlColor.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          );
        }

        spans.add(
          TextSpan(
            text: token,
            style: style,
          ),
        );
      }

      // Add space or newline between verses
      final sepText = settings.paragraphMode ? ' ' : '\n';
      spans.add(TextSpan(text: sepText));
      currentCharOffset += sepText.length;
    }

    return spans;
  }

  /// Tokenize verse text into words, preserving spaces and punctuation
  List<String> _tokenizeVerse(String text) {
    final words = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(char);

      if (char == ' ' || i == text.length - 1) {
        words.add(buffer.toString());
        buffer.clear();
      }
    }

    return words;
  }

  Future<void> _applyHighlightRange(int startGlobal, int endGlobal) async {
    if (startGlobal < 0 || endGlobal >= _allWords.length) return;

    final Map<int, List<ChapterWordRef>> wordsByVerse = {};
    for (int g = startGlobal; g <= endGlobal; g++) {
      final w = _allWords[g];
      wordsByVerse.putIfAbsent(w.verseNumber, () => []).add(w);
    }

    if (_isEraserActive) {
      final highlights = List<Highlight>.from(widget.controller.state.highlights);
      for (var entry in wordsByVerse.entries) {
        final verseNum = entry.key;
        final verseWords = entry.value;
        final minW = verseWords.map((w) => w.wordIndex).reduce(min);
        final maxW = verseWords.map((w) => w.wordIndex).reduce(max);

        for (var h in highlights) {
          final hStartV = h.reference.startVerse ?? 0;
          final hEndV = h.reference.endVerse ?? hStartV;
          if (hStartV <= verseNum && hEndV >= verseNum) {
            final realStart = min(h.wordStart, h.wordEnd);
            final realEnd = max(h.wordStart, h.wordEnd);
            if (minW <= realEnd && maxW >= realStart) {
              await widget.controller.deleteHighlight(h.id);
            }
          }
        }
      }
      setState(() {
        _activeHighlight = null;
      });
    } else {
      Highlight? lastCreated;
      for (var entry in wordsByVerse.entries) {
        final verseNum = entry.key;
        final verseWords = entry.value;
        final minW = verseWords.map((w) => w.wordIndex).reduce(min);
        final maxW = verseWords.map((w) => w.wordIndex).reduce(max);

        final highlight = Highlight.create(
          reference: PassageReference(
            bookId: widget.controller.state.chapter.bookId,
            chapter: widget.controller.state.chapter.number,
            startVerse: verseNum,
            endVerse: verseNum,
          ),
          wordStart: minW,
          wordEnd: maxW,
          colorValue: _activeHighlightColor.value,
        );
        await widget.controller.addHighlight(highlight);
        lastCreated = highlight;
      }
      setState(() {
        _activeHighlight = lastCreated;
      });
    }
  }

  /// Builds floating note chips anchored over the first word of each highlight with note content
  List<Widget> _buildAnchoredNoteOverlays(
    ChapterViewState state,
    BuildContext context,
  ) {
    final renderObj = _textKey.currentContext?.findRenderObject();
    if (renderObj == null || renderObj is! RenderParagraph) return const [];

    final renderParagraph = renderObj;
    final overlays = <Widget>[];
    final screenWidth = MediaQuery.of(context).size.width;

    for (var h in state.highlights) {
      if (h.note == null || h.note!.trim().isEmpty) continue;

      final startVerse = h.reference.startVerse;
      if (startVerse == null) continue;

      final minW = min(h.wordStart, h.wordEnd);
      ChapterWordRef? firstWord;
      for (var w in _allWords) {
        if (w.verseNumber == startVerse && w.wordIndex == minW) {
          firstWord = w;
          break;
        }
      }
      if (firstWord == null) continue;

      final caretOffset = renderParagraph.getOffsetForCaret(
        TextPosition(offset: firstWord.charStart),
        Rect.zero,
      );

      // Clamp horizontal offset to guarantee visibility on page without overflowing screen edge
      final maxLeft = max(16.0, screenWidth - 240.0);
      final clampedX = caretOffset.dx.clamp(16.0, maxLeft);
      final topY = max(0.0, caretOffset.dy - 34.0);

      overlays.add(
        Positioned(
          left: clampedX,
          top: topY,
          child: KeyedSubtree(
            key: _getOrCreateNoteChipKey(h.id),
            child: _AnchoredNoteChip(
              noteText: h.note!,
              color: Color(h.colorValue),
              onTap: () {
                setState(() {
                  _activeHighlight = h;
                });
                _showNoteEditor(context, h);
              },
            ),
          ),
        ),
      );
    }

    return overlays;
  }

  void _showNoteEditor(BuildContext context, [Highlight? targetHl]) async {
    final hl = targetHl ?? _activeHighlight;
    if (hl == null && _dragStartGlobal != null) {
      // If user highlighted text, create highlight first then prompt note
      final startIdx =
          min(_dragStartGlobal!, _dragCurrentGlobal ?? _dragStartGlobal!);
      final endIdx =
          max(_dragStartGlobal!, _dragCurrentGlobal ?? _dragStartGlobal!);
      await _applyHighlightRange(startIdx, endIdx);
    }

    final activeHl = targetHl ?? _activeHighlight;
    if (activeHl == null || !mounted) return;

    showDialog(
      context: this.context,
      builder: (context) => _NoteEditorDialog(
        existingNoteText: activeHl.note,
        onSave: (noteText) async {
          final updated = activeHl.copyWith(
            note: noteText.isEmpty ? null : noteText,
            modifiedAt: DateTime.now(),
          );
          await widget.controller.updateHighlight(updated);
          setState(() {
            _activeHighlight = updated;
          });
        },
        onDelete: () async {
          final updated = activeHl.copyWith(
            clearNote: true,
            modifiedAt: DateTime.now(),
          );
          await widget.controller.updateHighlight(updated);
          setState(() {
            _activeHighlight = updated;
          });
        },
      ),
    );
  }
}

/// Floating note badge chip anchored over text
class _AnchoredNoteChip extends StatelessWidget {
  final String noteText;
  final Color color;
  final VoidCallback onTap;

  const _AnchoredNoteChip({
    required this.noteText,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sticky_note_2,
                size: 14,
                color: color.computeLuminance() > 0.5
                    ? Colors.orange[800]
                    : color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  noteText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for creating/editing a highlight note
class _NoteEditorDialog extends StatefulWidget {
  final String? existingNoteText;
  final void Function(String noteText) onSave;
  final VoidCallback onDelete;

  const _NoteEditorDialog({
    this.existingNoteText,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.existingNoteText ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNoteText != null &&
        widget.existingNoteText!.isNotEmpty;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Note' : 'Add Note to Highlight'),
      content: TextField(
        controller: _contentController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Note content',
          border: OutlineInputBorder(),
        ),
        maxLines: 4,
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Note'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_contentController.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save Note'),
        ),
      ],
    );
  }
}
