import 'package:flutter/material.dart';
import 'package:bible_core/models/verse.dart';
import 'package:bible_core/models/passage_reference.dart';
import 'package:bible_app/services/bible_service.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<Verse> _verses = [];
  bool _isLoading = true;
  String? _error;
  final PassageReference _currentRef = const PassageReference(
    bookId: 'john',
    chapter: 1,
    startVerse: 1,
    endVerse: 10,
  );

  @override
  void initState() {
    super.initState();
    _loadVerses();
  }

  Future<void> _loadVerses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final verses = await BibleService.instance.getVerses(_currentRef);
      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRef.toString()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement passage picker
            },
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: () {
              // TODO: Implement TTS
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVerses,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTranslationChip('WEB'),
                    const SizedBox(height: 16),
                    ..._verses.map((verse) => _buildVerse(verse)),
                  ],
                ),
    );
  }

  Widget _buildTranslationChip(String translation) {
    return Chip(
      label: Text(translation),
      avatar: const Icon(Icons.translate, size: 18),
    );
  }

  Widget _buildVerse(Verse verse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${verse.number}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ),
          Expanded(
            child: Text(
              verse.text,
              style: const TextStyle(
                fontSize: 17,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
