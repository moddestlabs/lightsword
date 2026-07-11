import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
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
            title: const Text('Default Translation'),
            subtitle: const Text('ESV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Translation picker
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
            title: const Text('Speech Rate'),
            subtitle: Slider(
              value: _ttsService.rate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: '${(_ttsService.rate * 100).round()}%',
              onChanged: (value) {
                setState(() {
                  _ttsService.setRate(value);
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Speech Pitch'),
            subtitle: Slider(
              value: _ttsService.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _ttsService.pitch.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _ttsService.setPitch(value);
                });
              },
            ),
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
          ListTile(
            title: const Text('Available Languages'),
            subtitle: const Text('Check TTS language support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAvailableLanguages(context);
            },
          ),
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

  Future<void> _showAvailableLanguages(BuildContext context) async {
    final languages = await _ttsService.getAvailableLanguages();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Available TTS Languages'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSupported = lang.code == 'en-US' || 
                                 lang.code == 'he-IL' || 
                                 lang.code == 'el-GR';
              return ListTile(
                leading: Icon(
                  isSupported ? Icons.check_circle : Icons.circle_outlined,
                  color: isSupported ? Colors.green : Colors.grey,
                ),
                title: Text(lang.name),
                subtitle: Text(lang.code),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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

  List<Widget> _buildPwaWidgets() {
    return [];
  }
}
