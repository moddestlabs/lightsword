import 'package:flutter/material.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';

class ChapterViewEditorDialog extends StatelessWidget {
  final ChapterViewDefinition initialView;
  final String title;

  const ChapterViewEditorDialog({
    super.key,
    required this.initialView,
    required this.title,
  });

  static Future<ChapterViewDefinition?> show(
    BuildContext context, {
    required ChapterViewDefinition initialView,
    required String title,
  }) {
    return showDialog<ChapterViewDefinition>(
      context: context,
      builder: (context) {
        return ChapterViewEditorDialog(
          initialView: initialView,
          title: title,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: initialView.name);
    var showVerseNumbers = initialView.showVerseNumbers;
    var lineByLine = initialView.lineByLine;
    var showOriginalLanguage = initialView.showOriginalLanguage;
    var showMorphology = initialView.showMorphology;
    var useCompactMorphologyLabels = initialView.useCompactMorphologyLabels;
    var colorOriginalLanguageByGender =
      initialView.colorOriginalLanguageByGender;
    var showSyntaxLinks = initialView.showSyntaxLinks;
    var showTranslation = initialView.showTranslation;
    var showGloss = initialView.showGloss;
    var textDirection = initialView.originalLanguageTextDirection;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'View name',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show verse numbers'),
                  value: showVerseNumbers,
                  onChanged: (value) {
                    setDialogState(() {
                      showVerseNumbers = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Line-by-line verses'),
                  subtitle: const Text('Turn off for paragraph form'),
                  value: lineByLine,
                  onChanged: (value) {
                    setDialogState(() {
                      lineByLine = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Hebrew/Greek'),
                  value: showOriginalLanguage,
                  onChanged: (value) {
                    setDialogState(() {
                      showOriginalLanguage = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show translation'),
                  value: showTranslation,
                  onChanged: (value) {
                    setDialogState(() {
                      showTranslation = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show glosses'),
                  value: showGloss,
                  onChanged: (value) {
                    setDialogState(() {
                      showGloss = value;
                    });
                  },
                ),
                if (showOriginalLanguage) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show morphology tags'),
                    subtitle: const Text('Display parsed word tags below Hebrew/Greek'),
                    value: showMorphology,
                    onChanged: (value) {
                      setDialogState(() {
                        showMorphology = value;
                      });
                    },
                  ),
                  if (showMorphology)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use compact morphology labels'),
                      subtitle: const Text('Show short labels like Noun Fem Sg Abs'),
                      value: useCompactMorphologyLabels,
                      onChanged: (value) {
                        setDialogState(() {
                          useCompactMorphologyLabels = value;
                        });
                      },
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Color by grammatical gender'),
                    subtitle: const Text('Masculine blue, feminine pink, neuter gray'),
                    value: colorOriginalLanguageByGender,
                    onChanged: (value) {
                      setDialogState(() {
                        colorOriginalLanguageByGender = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show syntax links'),
                    subtitle: const Text('Enable Macula-derived referents and syntax connections when available'),
                    value: showSyntaxLinks,
                    onChanged: (value) {
                      setDialogState(() {
                        showSyntaxLinks = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ChapterViewTextDirection>(
                    initialValue: textDirection,
                    decoration: const InputDecoration(
                      labelText: 'Original language direction',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ChapterViewTextDirection.auto,
                        child: Text('Auto'),
                      ),
                      DropdownMenuItem(
                        value: ChapterViewTextDirection.rtl,
                        child: Text('Right to left'),
                      ),
                      DropdownMenuItem(
                        value: ChapterViewTextDirection.ltr,
                        child: Text('Left to right'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        textDirection = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final trimmedName = nameController.text.trim();
                if (trimmedName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name is required')),
                  );
                  return;
                }
                if (!showOriginalLanguage && !showTranslation && !showGloss) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select at least one content line')),
                  );
                  return;
                }

                Navigator.of(context).pop(
                  initialView.copyWith(
                    name: trimmedName,
                    isBuiltIn: false,
                    showVerseNumbers: showVerseNumbers,
                    lineByLine: lineByLine,
                    showOriginalLanguage: showOriginalLanguage,
                    showMorphology: showMorphology,
                    useCompactMorphologyLabels: useCompactMorphologyLabels,
                    colorOriginalLanguageByGender:
                      colorOriginalLanguageByGender,
                    showSyntaxLinks: showSyntaxLinks,
                    showTranslation: showTranslation,
                    showGloss: showGloss,
                    originalLanguageTextDirection: textDirection,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}