import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:bible_core/tts/tts_engine.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/state/theme_provider.dart';
import 'package:bible_app/state/font_size_provider.dart';
import '../widgets/pwa_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TtsService _ttsService = TtsService.instance;

  @override
  void initState() {
    super.initState();
    _loadVoices();
  }

  Future<void> _loadVoices() async {
    await _ttsService.refreshAvailableVoices();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Appearance'),
            leading: Icon(Icons.palette_outlined),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(
              '${_getThemeModeLabel(themeProvider.themeMode)} • ${themeProvider.palette.label}',
            ),
            leading: Icon(_getThemeModeIcon(themeProvider.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog(context, themeProvider);
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Reading'),
            leading: Icon(Icons.text_fields),
          ),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Text(
              '${fontSizeProvider.fontSize.toStringAsFixed(0)} pt (${_getFontSizeLabel(fontSizeProvider.fontSize)})',
            ),
            leading: const Icon(Icons.format_size),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${fontSizeProvider.fontSize.toStringAsFixed(0)} pt',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              _showTextSizeDialog(context, fontSizeProvider);
            },
          ),
          ListTile(
            title: const Text('Font Family'),
            subtitle: Text(fontSizeProvider.fontFamily),
            leading: const Icon(Icons.font_download_outlined),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fontSizeProvider.fontFamily,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              _showFontFamilyDialog(context, fontSizeProvider);
            },
          ),
          SwitchListTile(
            title: const Text('Pinch to Zoom Text'),
            subtitle: const Text('Pinch on reading screens to adjust text size'),
            secondary: const Icon(Icons.pinch_outlined),
            value: fontSizeProvider.pinchToZoomEnabled,
            onChanged: (enabled) {
              fontSizeProvider.setPinchToZoomEnabled(enabled);
            },
          ),
          ListTile(
            title: const Text('Primary Text Source'),
            subtitle: Text(BibleService.currentSourceOption.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change the text source from the reader header.'),
                ),
              );
            },
          ),
          const Divider(),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TtsCapabilityIndicator(),
            ),
          const ListTile(
            title: Text('Text-to-Speech'),
            leading: Icon(Icons.volume_up_outlined),
          ),
          ListTile(
            title: const Text('Volume'),
            subtitle: Slider(
              value: _ttsService.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(_ttsService.volume * 100).round()}%',
              onChanged: (value) {
                setState(() {
                  _ttsService.setVolume(value);
                });
              },
            ),
          ),
          ..._buildVoiceSelectionTiles(context),
          ListTile(
            title: const Text('Test TTS'),
            subtitle: const Text('Hear a sample in each language'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              _testTts();
            },
          ),
          if (kIsWeb) ..._buildPwaWidgets(),
          const Divider(),
          const ListTile(
            title: Text('About'),
            leading: Icon(Icons.info_outlined),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('0.1.0'),
          ),
          ListTile(
            title: const Text('Data Licenses'),
            subtitle: const Text('Open source Bible texts & lexicons'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show data licenses
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getFontSizeLabel(double size) {
    if (size < 16.0) return 'Small';
    if (size < 20.0) return 'Medium';
    if (size < 24.0) return 'Large';
    return 'Extra Large';
  }

  Future<void> _showTextSizeDialog(
    BuildContext context,
    FontSizeProvider fontSizeProvider,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, provider, child) => AlertDialog(
          title: const Text('Text Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Font Size'),
                  Text(
                    '${provider.fontSize.toStringAsFixed(0)} pt (${_getFontSizeLabel(provider.fontSize)})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: provider.fontSize,
                min: FontSizeProvider.minFontSize,
                max: FontSizeProvider.maxFontSize,
                divisions: (FontSizeProvider.maxFontSize - FontSizeProvider.minFontSize).toInt(),
                label: '${provider.fontSize.toStringAsFixed(0)} pt',
                onChanged: (value) {
                  provider.setFontSize(value);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Small (14pt)'),
                    onPressed: () => provider.setFontSize(14.0),
                  ),
                  ActionChip(
                    label: const Text('Medium (18pt)'),
                    onPressed: () => provider.setFontSize(18.0),
                  ),
                  ActionChip(
                    label: const Text('Large (22pt)'),
                    onPressed: () => provider.setFontSize(22.0),
                  ),
                  ActionChip(
                    label: const Text('XL (26pt)'),
                    onPressed: () => provider.setFontSize(26.0),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIEW',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In the beginning God created the heavens and the earth.',
                      style: TextStyle(
                        fontSize: provider.fontSize,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFontFamilyDialog(
    BuildContext context,
    FontSizeProvider fontSizeProvider,
  ) async {
    final fonts = <Map<String, String>>[
      {
        'id': 'Cardo',
        'name': 'Cardo (Default Serif)',
        'desc': 'Classic serif font optimized for Bible study and ancient languages',
      },
      {
        'id': 'NotoSansHebrew',
        'name': 'Noto Sans (Sans-Serif)',
        'desc': 'Clean, highly legible sans-serif font for easy reading',
      },
      {
        'id': 'NotoRashiHebrew',
        'name': 'Noto Rashi (Rashi Script)',
        'desc': 'Traditional Rabbinic commentary Rashi script',
      },
      {
        'id': 'Sans-Serif',
        'name': 'System Sans-Serif',
        'desc': 'Uses your device default sans-serif font',
      },
      {
        'id': 'Serif',
        'name': 'System Serif',
        'desc': 'Uses your device default serif font',
      },
      {
        'id': 'Monospace',
        'name': 'Monospace',
        'desc': 'Fixed-width font for aligned study displays',
      },
    ];

    return showDialog(
      context: context,
      builder: (context) => Consumer<FontSizeProvider>(
        builder: (context, provider, child) => AlertDialog(
          title: const Text('Font Family'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: fonts.map((f) {
                final fontId = f['id']!;
                final fontName = f['name']!;
                final fontDesc = f['desc']!;
                return RadioListTile<String>(
                  title: Text(
                    fontName,
                    style: TextStyle(
                      fontFamily: fontId.startsWith('System') ||
                              fontId == 'Sans-Serif' ||
                              fontId == 'Serif' ||
                              fontId == 'Monospace'
                          ? null
                          : fontId,
                    ),
                  ),
                  subtitle: Text(fontDesc),
                  value: fontId,
                  groupValue: provider.fontFamily,
                  onChanged: (value) {
                    if (value != null) {
                      provider.setFontFamily(value);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemeDialog(BuildContext context, ThemeProvider themeProvider) async {
    return showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, provider, child) => AlertDialog(
          title: const Text('Theme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      subtitle: const Text('Follow system theme'),
                      value: ThemeMode.system,
                      groupValue: provider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          provider.setThemeMode(value);
                        }
                      },
                      secondary: const Icon(Icons.brightness_auto),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      subtitle: const Text('Always use light theme'),
                      value: ThemeMode.light,
                      groupValue: provider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          provider.setThemeMode(value);
                        }
                      },
                      secondary: const Icon(Icons.light_mode),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      subtitle: const Text('Always use dark theme'),
                      value: ThemeMode.dark,
                      groupValue: provider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          provider.setThemeMode(value);
                        }
                      },
                      secondary: const Icon(Icons.dark_mode),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Palette',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppPalette.values
                      .map(
                        (palette) => RadioListTile<AppPalette>(
                          title: Text(palette.label),
                          subtitle: Text(palette.description),
                          value: palette,
                          groupValue: provider.palette,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setPalette(value);
                            }
                          },
                          secondary: Icon(palette.icon),
                        ),
                      )
                      .toList(),
                ),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testTts() async {
    // Test samples in different languages
    const samples = {
      'en-US': 'In the beginning, God created the heavens and the earth.',
      'he-IL': 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ',
      'el-GR': 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν',
    };

    for (final entry in samples.entries) {
      await _ttsService.speak(entry.value);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  List<Widget> _buildVoiceSelectionTiles(BuildContext context) {
    return [
      _buildVoiceSection(
        context,
        title: 'English Voice',
        languageCode: 'en-US',
        voices: _ttsService.englishVoices,
        selectedVoice: _ttsService.selectedEnglishVoice,
      ),
      _buildVoiceSection(
        context,
        title: 'Hebrew Voice',
        languageCode: 'he-IL',
        voices: _ttsService.hebrewVoices,
        selectedVoice: _ttsService.selectedHebrewVoice,
      ),
      _buildVoiceSection(
        context,
        title: 'Greek Voice',
        languageCode: 'el-GR',
        voices: _ttsService.greekVoices,
        selectedVoice: _ttsService.selectedGreekVoice,
      ),
    ];
  }

  Widget _buildVoiceSection(
    BuildContext context, {
    required String title,
    required String languageCode,
    required List<TtsVoice> voices,
    required TtsVoice? selectedVoice,
  }) {
    final hasVoices = voices.isNotEmpty;
    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(
            hasVoices
                ? (selectedVoice?.label ?? 'Automatic (${voices.length} available)')
                : 'No voices detected on this device/browser',
          ),
          trailing: hasVoices ? const Icon(Icons.chevron_right) : null,
          onTap: hasVoices
              ? () => _showVoiceSelectionDialog(
                    context,
                    title: title,
                    languageCode: languageCode,
                    voices: voices,
                    selectedVoice: selectedVoice,
                  )
              : null,
        ),
        _buildVoiceSliderTile(
          context,
          title: 'Speech Rate',
          value: _ttsService.rateForLanguage(languageCode),
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: '${(_ttsService.rateForLanguage(languageCode) * 100).round()}%',
          onChanged: (value) async {
            await _ttsService.setRateForLanguage(languageCode, value);
            if (mounted) {
              setState(() {});
            }
          },
        ),
        _buildVoiceSliderTile(
          context,
          title: 'Speech Pitch',
          value: _ttsService.pitchForLanguage(languageCode),
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: _ttsService.pitchForLanguage(languageCode).toStringAsFixed(1),
          onChanged: (value) async {
            await _ttsService.setPitchForLanguage(languageCode, value);
            if (mounted) {
              setState(() {});
            }
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildVoiceSliderTile(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(title),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _showVoiceSelectionDialog(
    BuildContext context, {
    required String title,
    required String languageCode,
    required List<TtsVoice> voices,
    required TtsVoice? selectedVoice,
  }) async {
    final selectedId = await showDialog<String?>(
      context: context,
      builder: (context) {
        String? draftValue = selectedVoice?.id;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  RadioListTile<String?>(
                    value: null,
                    groupValue: draftValue,
                    onChanged: (value) {
                      setStateDialog(() {
                        draftValue = value;
                      });
                    },
                    title: const Text('Automatic'),
                    subtitle: const Text('Let the platform choose the default voice.'),
                  ),
                  for (final voice in voices)
                    RadioListTile<String?>(
                      value: voice.id,
                      groupValue: draftValue,
                      onChanged: (value) {
                        setStateDialog(() {
                          draftValue = value;
                        });
                      },
                      title: Text(voice.name),
                      subtitle: Text(voice.locale),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(draftValue),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    final voice = voices.where((item) => item.id == selectedId).cast<TtsVoice?>().firstWhere(
          (item) => item != null,
          orElse: () => null,
        );
    await _ttsService.selectVoiceForLanguage(languageCode, voice);
    if (mounted) {
      setState(() {});
    }
  }

  List<Widget> _buildPwaWidgets() {
    return const [
      Divider(),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: OfflinePackManager(),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: PwaDiagnosticsCard(),
      ),
    ];
  }
}
