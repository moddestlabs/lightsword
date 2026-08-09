import 'package:flutter/material.dart';
import 'study_toolbar.dart';

/// Right-side vertical toolbar for Markup mode
/// Provides quick access to highlight colors, eraser tool, show/hide notes toggle, and conditional note editor
class StudyVerticalToolbar extends StatelessWidget {
  final void Function(Color color) onColorSelected;
  final VoidCallback onErase;
  final bool isEraserActive;
  final Color? activeColor;
  final VoidCallback? onNote;
  final VoidCallback? onCopy;
  final bool showNotes;
  final VoidCallback? onToggleShowNotes;
  final bool hasActiveHighlight;
  final bool hasExistingNote;

  const StudyVerticalToolbar({
    super.key,
    required this.onColorSelected,
    required this.onErase,
    this.isEraserActive = false,
    this.activeColor,
    this.onNote,
    this.onCopy,
    this.showNotes = true,
    this.onToggleShowNotes,
    this.hasActiveHighlight = false,
    this.hasExistingNote = false,
  });

  static const List<Color> _paletteColors = [
    HighlightColors.yellow,
    HighlightColors.green,
    HighlightColors.blue,
    HighlightColors.pink,
    HighlightColors.purple,
    HighlightColors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: colorScheme.surface.withOpacity(0.95),
      shadowColor: Colors.black38,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color palette swatches
              for (final color in _paletteColors) ...[
                _ColorSwatchButton(
                  color: color,
                  isSelected: activeColor?.value == color.value && !isEraserActive,
                  onTap: () => onColorSelected(color),
                ),
                const SizedBox(height: 6),
              ],

              const Divider(height: 12),

              // Eraser Tool Button
              Tooltip(
                message: isEraserActive
                    ? 'Eraser active (drag/tap to remove highlight & note)'
                    : 'Eraser tool (remove highlight & note)',
                child: InkWell(
                  onTap: onErase,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isEraserActive
                          ? colorScheme.errorContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cleaning_services_outlined,
                      size: 22,
                      color: isEraserActive
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSurface,
                    ),

                  ),
                ),
              ),

              const Divider(height: 12),

              // Show/Hide Notes Toggle Button
              if (onToggleShowNotes != null)
                Tooltip(
                  message: showNotes ? 'Hide notes' : 'Show notes',
                  child: IconButton(
                    icon: Icon(
                      showNotes
                          ? Icons.sticky_note_2
                          : Icons.sticky_note_2_outlined,
                      size: 20,
                      color: showNotes
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleShowNotes,
                    visualDensity: VisualDensity.compact,
                  ),
                ),

              // Conditional Add/Edit Note Button (Only visible when highlight is active)
              if (hasActiveHighlight && onNote != null)
                Tooltip(
                  message: hasExistingNote ? 'Edit note' : 'Add note',
                  child: IconButton(
                    icon: Icon(
                      hasExistingNote ? Icons.edit_note : Icons.note_add_outlined,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    onPressed: onNote,
                    visualDensity: VisualDensity.compact,
                  ),
                ),

              if (onCopy != null)
                IconButton(
                  tooltip: 'Copy selected text',
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: onCopy,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatchButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${HighlightColors.getColorName(color)} highlight',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isSelected ? 28 : 24,
          height: isSelected ? 28 : 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.black87 : Colors.black26,
              width: isSelected ? 2.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 14, color: Colors.black87)
              : null,
        ),
      ),
    );
  }
}
