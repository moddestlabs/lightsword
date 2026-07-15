import 'package:flutter/material.dart';
import 'package:bible_app/services/pwa_service.dart';
import 'package:bible_app/ui/models/chapter_view_definition.dart';
import 'package:bible_app/ui/screens/settings_screen.dart';

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
    final pwa = PwaService.instance;
    final offlinePackStatusFuture = pwa.isWeb
        ? pwa.refreshOfflinePackStatus()
        : Future.value(const <OfflinePackId, OfflinePackStatus>{});
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
    var showWordGlosses = initialView.showWordGlosses;
    var textDirection = initialView.originalLanguageTextDirection;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        final canCheckMaculaPack = pwa.isWeb && pwa.isAvailable;
        void openSettings() {
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            );
          });
        }

        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: FutureBuilder<Map<OfflinePackId, OfflinePackStatus>>(
              future: offlinePackStatusFuture,
              builder: (context, snapshot) {
                final maculaPackInstalled = !pwa.isWeb ||
                    (snapshot.data?[OfflinePackId.maculaSyntax]?.isInstalled ?? false);
                final syntaxLinksEnabled = !pwa.isWeb || maculaPackInstalled;
                final syntaxLinksSubtitle = !pwa.isWeb
                    ? 'Enable Macula-derived referents and syntax connections when available'
                    : snapshot.connectionState != ConnectionState.done
                        ? 'Checking whether the Macula Syntax pack is installed...'
                        : !canCheckMaculaPack
                            ? 'PWA pack status is unavailable in this session. Open Settings and confirm the web PWA is initialized.'
                            : maculaPackInstalled
                                ? 'Enable Macula-derived referents and syntax connections when available'
                                : 'Install the Macula Syntax pack in Settings to enable referents and syntax connections in web views.';

                return Column(
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
                      title: const Text('Show gloss line'),
                      subtitle: const Text('Display verse-level gloss text as a separate line'),
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
                        title: const Text('Show word glosses'),
                        subtitle: const Text('Display glosses below each Hebrew/Greek word'),
                        value: showWordGlosses,
                        onChanged: (value) {
                          setDialogState(() {
                            showWordGlosses = value;
                          });
                        },
                      ),
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
                        subtitle: Text(syntaxLinksSubtitle),
                        value: syntaxLinksEnabled && showSyntaxLinks,
                        onChanged: syntaxLinksEnabled
                            ? (value) {
                                setDialogState(() {
                                  showSyntaxLinks = value;
                                });
                              }
                            : null,
                      ),
                      if (pwa.isWeb &&
                          snapshot.connectionState == ConnectionState.done &&
                          !maculaPackInstalled)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: openSettings,
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Open Settings'),
                          ),
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
                );
              },
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

                final canUseSyntaxLinks = !pwa.isWeb ||
                    (pwa.offlinePackStatuses[OfflinePackId.maculaSyntax]?.isInstalled ?? false);
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
                    showSyntaxLinks: canUseSyntaxLinks ? showSyntaxLinks : false,
                    showTranslation: showTranslation,
                    showGloss: showGloss,
                    showWordGlosses:
                        showOriginalLanguage ? showWordGlosses : false,
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