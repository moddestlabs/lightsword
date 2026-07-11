import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';

/// Predefined highlight colors
class HighlightColors {
  static const yellow = Color(0xFFFFEB3B);
  static const green = Color(0xFF4CAF50);
  static const blue = Color(0xFF2196F3);
  static const orange = Color(0xFFFF9800);
  static const purple = Color(0xFF9C27B0);
  static const pink = Color(0xFFE91E63);
  static const red = Color(0xFFF44336);
  static const cyan = Color(0xFF00BCD4);

  static const List<Color> all = [
    yellow,
    green,
    blue,
    orange,
    purple,
    pink,
    red,
    cyan,
  ];

  static String getColorName(Color color) {
    if (color == yellow) return 'Yellow';
    if (color == green) return 'Green';
    if (color == blue) return 'Blue';
    if (color == orange) return 'Orange';
    if (color == purple) return 'Purple';
    if (color == pink) return 'Pink';
    if (color == red) return 'Red';
    if (color == cyan) return 'Cyan';
    return 'Custom';
  }
}

/// Floating toolbar that appears when text is selected
class StudyToolbar extends StatelessWidget {
  final VoidCallback onHighlight;
  final VoidCallback onArc;
  final VoidCallback onNote;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const StudyToolbar({
    super.key,
    required this.onHighlight,
    required this.onArc,
    required this.onNote,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarButton(
              icon: Icons.highlight,
              label: 'Highlight',
              onPressed: onHighlight,
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.timeline,
              label: 'Arc',
              onPressed: onArc,
            ),
            const SizedBox(width: 4),
            _ToolbarButton(
              icon: Icons.note_add,
              label: 'Note',
              onPressed: onNote,
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.copy,
                label: 'Copy',
                onPressed: onCopy!,
              ),
            ],
            if (onShare != null) ...[
              const SizedBox(width: 4),
              _ToolbarButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: onShare!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color picker for highlights
class HighlightColorPicker extends StatelessWidget {
  final void Function(Color color) onColorSelected;

  const HighlightColorPicker({
    super.key,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Highlight Color',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: HighlightColors.all.map((color) {
              return InkWell(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      HighlightColors.getColorName(color),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Arc type picker
class ArcTypePicker extends StatelessWidget {
  final void Function(ArcType type, Color color) onArcSelected;

  const ArcTypePicker({
    super.key,
    required this.onArcSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Arc Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...ArcType.values.map((type) {
            return ListTile(
              title: Text(type.displayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show color picker for this arc type
                _showColorPicker(context, type);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, ArcType type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Color for ${type.displayName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: HighlightColors.all.map((color) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onArcSelected(type, color);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
