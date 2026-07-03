import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/services/pwa_service.dart';
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
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              // TODO: Implement theme switching
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
          const ListTile(
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TtsCapabilityIndicator(),
            ),
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
          if (kIsWeb)
            _buildPwaInfo(),
              _testTts();
            },
          ),
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
   

  Widget _buildPwaInfo() {
    final pwa = PwaService.instance;
    
    if (!pwa.isAvailable) {
      return const SizedBox.shrink();
    }

    final platform = pwa.platformInfo;
    final storage = pwa.storageInfo;

    return Column(
      children: [
        ListTile(
          title: const Text('Platform'),
          subtitle: Text(_getPlatformDescription(platform)),
          leading: Icon(
            platform?.isStandalone ?? false
                ? Icons.install_mobile
                : Icons.web,
          ),
        ),
        if (storage != null)
          ListTile(
            title: const Text('Storage'),
            subtitle: Text(
              '${storage.usageMB} MB used of ${storage.quotaMB} MB\n'
              '${storage.persisted ? "Persisted" : "May be cleared by browser"}',
            ),
            leading: Icon(
              storage.persisted ? Icons.storage : Icons.storage_outlined,
            ),
            trailing: TextButton(
              onPressed: _refreshStorageInfo,
              child: const Text('Refresh'),
            ),
          ),
      ],
    );
  }

  String _getPlatformDescription(PlatformInfo? platform) {
    if (platform == null) return 'Web Browser';
    
    final parts = <String>[];
    if (platform.isStandalone) {
      parts.add('Installed PWA');
    } else {
      parts.add('Web Browser');
    }
    
    if (platform.isIOS) {
      parts.add('iOS');
    } else if (platform.isAndroid) {
      parts.add('Android');
    } else if (platform.isMobile) {
      parts.add('Mobile');
    } else {
      parts.add('Desktop');
    }
    
    return parts.join(' • ');
  }

  Future<void> _refreshStorageInfo() async {
    final storage = await PwaService.instance.refreshStorageEstimate();
    if (storage != null && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Storage: ${storage.usageMB} MB / ${storage.quotaMB} MB'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }   'el-GR': 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν',
    };

    for (final entry in samples.entries) {
      await _ttsService.speak(entry.value);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
