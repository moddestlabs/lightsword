import 'package:flutter/material.dart';
import 'package:bible_app/services/tts_service.dart';
import 'package:bible_app/platform/tts/language_detector.dart';
import 'package:bible_core/models/verse.dart';

/// Demo page to showcase TTS capabilities with Hebrew, Greek, and English
class TtsDemoPage extends StatefulWidget {
  const TtsDemoPage({super.key});

  @override
  State<TtsDemoPage> createState() => _TtsDemoPageState();
}

class _TtsDemoPageState extends State<TtsDemoPage> {
  final TtsService _tts = TtsService.instance;

  // Sample texts in different languages
  final List<Map<String, String>> _samples = [
    {
      'language': 'Hebrew',
      'reference': 'Genesis 1:1',
      'text': 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ',
      'transliteration': 'Bereshit bara Elohim et hashamayim ve\'et ha\'aretz',
      'translation': 'In the beginning God created the heavens and the earth.',
    },
    {
      'language': 'Greek',
      'reference': 'John 1:1',
      'text': 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν, καὶ θεὸς ἦν ὁ λόγος.',
      'transliteration': 'En archē ēn ho logos, kai ho logos ēn pros ton theon, kai theos ēn ho logos.',
      'translation': 'In the beginning was the Word, and the Word was with God, and the Word was God.',
    },
    {
      'language': 'English',
      'reference': 'Psalm 23:1',
      'text': 'The Lord is my shepherd; I shall not want.',
      'transliteration': '',
      'translation': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => _tts.stop(),
            tooltip: 'Stop all',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text-to-Speech Demo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap any sample to hear it read aloud with automatic language detection.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Samples
          for (final sample in _samples) _buildSampleCard(sample),

          const SizedBox(height: 16),

          // Sequential reading demo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sequential Reading Demo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Read all three samples in sequence:',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _readAllSequentially,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Read All (Hebrew → Greek → English)'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Language detection info
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('🔍', 'Automatic language detection by Unicode ranges'),
                  _buildInfoRow('🗣️', 'Uses platform-native TTS engines'),
                  _buildInfoRow('🇮🇱', 'Hebrew: Modern Israeli pronunciation'),
                  _buildInfoRow('🇬🇷', 'Greek: Modern pronunciation (not Koine)'),
                  _buildInfoRow('⚙️', 'Configurable rate, pitch, and volume'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCard(Map<String, String> sample) {
    final detectedLang = LanguageDetector.detect(sample['text']!);
    final langName = LanguageDetector.getLanguageName(detectedLang);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _tts.speak(sample['text']!),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sample['language']!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  Chip(
                    label: Text(langName),
                    backgroundColor: Colors.green.shade100,
                  ),
                ],
              ),
              Text(
                sample['reference']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sample['text']!,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.6,
                ),
              ),
              if (sample['transliteration']!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sample['transliteration']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (sample['translation']!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sample['translation']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.volume_up, size: 16, color: Color(0xFF007AFF)),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to hear',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _readAllSequentially() async {
    for (final sample in _samples) {
      await _tts.speak(sample['text']!);
      // Wait for TTS to complete (simplified - in production use TTS callbacks)
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
