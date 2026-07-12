import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:bible_core/tts/tts_engine.dart';
import 'package:bible_app/services/bible_service.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/state/theme_provider.dart';
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
            subtitle: const Text('Adjust reading text size'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Text size selector
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
                RadioGroup<ThemeMode>(
                  groupValue: provider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      provider.setThemeMode(value);
                    }
                  },
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('System'),
                        subtitle: Text('Follow system theme'),
                        value: ThemeMode.system,
                        secondary: Icon(Icons.brightness_auto),
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Light'),
                        subtitle: Text('Always use light theme'),
                        value: ThemeMode.light,
                        secondary: Icon(Icons.light_mode),
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Dark'),
                        subtitle: Text('Always use dark theme'),
                        value: ThemeMode.dark,
                        secondary: Icon(Icons.dark_mode),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Palette',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                RadioGroup<AppPalette>(
                  groupValue: provider.palette,
                  onChanged: (value) {
                    if (value != null) {
                      provider.setPalette(value);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: AppPalette.values
                        .map(
                          (palette) => RadioListTile<AppPalette>(
                            title: Text(palette.label),
                            subtitle: Text(palette.description),
                            value: palette,
                            secondary: Icon(palette.icon),
                          ),
                        )
                        .toList(),
                  ),
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
              child: RadioGroup<String?>(
                groupValue: draftValue,
                onChanged: (value) {
                  setStateDialog(() {
                    draftValue = value;
                  });
                },
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const RadioListTile<String?>(
                      value: null,
                      title: Text('Automatic'),
                      subtitle: Text('Let the platform choose the default voice.'),
                    ),
                    for (final voice in voices)
                      RadioListTile<String?>(
                        value: voice.id,
                        title: Text(voice.name),
                        subtitle: Text(voice.locale),
                      ),
                  ],
                ),
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
