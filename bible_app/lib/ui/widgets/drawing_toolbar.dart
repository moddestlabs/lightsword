import 'package:flutter/material.dart';
import 'package:bible_core/models/drawing.dart';
import 'package:bible_app/ui/widgets/drawing_canvas.dart';

/// Toolbar for drawing tools and settings
class DrawingToolbar extends StatelessWidget {
  final DrawingToolSettings settings;
  final void Function(DrawingToolSettings) onSettingsChanged;
  final VoidCallback onToggleDrawingMode;
  final bool isDrawingMode;
  final VoidCallback? onUndo;
  final VoidCallback? onClear;

  const DrawingToolbar({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onToggleDrawingMode,
    required this.isDrawingMode,
    this.onUndo,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          // Drawing mode toggle
          IconButton(
            icon: Icon(
              isDrawingMode ? Icons.edit_off : Icons.edit,
              color: isDrawingMode
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: isDrawingMode ? 'Exit Drawing Mode' : 'Drawing Mode',
            onPressed: onToggleDrawingMode,
          ),

          if (isDrawingMode) ...[
            const VerticalDivider(),

            // Stroke style selector
            _StyleButton(
              icon: Icons.mode_edit,
              label: 'Pen',
              isSelected: settings.style == StrokeStyle.pen,
              onPressed: () => onSettingsChanged(
                settings.copyWith(style: StrokeStyle.pen),
              ),
            ),
            _StyleButton(
              icon: Icons.highlight,
              label: 'Highlighter',
              isSelected: settings.style == StrokeStyle.highlighter,
              onPressed: () => onSettingsChanged(
                settings.copyWith(style: StrokeStyle.highlighter),
              ),
            ),
            _StyleButton(
              icon: Icons.draw,
              label: 'Pencil',
              isSelected: settings.style == StrokeStyle.pencil,
              onPressed: () => onSettingsChanged(
                settings.copyWith(style: StrokeStyle.pencil),
              ),
            ),

            const VerticalDivider(),

            // Color picker
            _ColorButton(
              color: settings.color,
              onPressed: () => _showColorPicker(context),
            ),

            const SizedBox(width: 8),

            // Stroke width selector
            _StrokeWidthSelector(
              value: settings.strokeWidth,
              onChanged: (width) => onSettingsChanged(
                settings.copyWith(strokeWidth: width),
              ),
            ),

            const Spacer(),

            // Undo button
            if (onUndo != null)
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: onUndo,
              ),

            // Clear all button
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear All',
                onPressed: () => _confirmClear(context),
              ),
          ],

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ColorPickerSheet(
        currentColor: settings.color,
        onColorSelected: (color) {
          onSettingsChanged(settings.copyWith(color: color));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Drawings'),
        content: const Text(
          'Are you sure you want to clear all drawings? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onClear?.call();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _StyleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _StyleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _ColorButton({
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _StrokeWidthSelector extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;

  const _StrokeWidthSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.line_weight, size: 16),
        const SizedBox(width: 4),
        SizedBox(
          width: 100,
          child: Slider(
            value: value,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  final Color currentColor;
  final void Function(Color) onColorSelected;

  const _ColorPickerSheet({
    required this.currentColor,
    required this.onColorSelected,
  });

  static final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Color',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colors.map((color) {
              final isSelected = color.value == currentColor.value;
              return InkWell(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
