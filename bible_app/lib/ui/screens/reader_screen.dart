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
  
  String _bookId = 'John';
  int _chapter = 1;
  
  PassageReference get _currentRef => PassageReference(
    bookId: _bookId,
    chapter: _chapter,
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

  void _previousChapter() {
    if (_chapter > 1) {
      setState(() {
        _chapter--;
      });
      _loadVerses();
    }
  }

  void _nextChapter() {
    setState(() {
      _chapter++;
    });
    _loadVerses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_bookId $_chapter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('ERROR: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verses loaded: ${_verses.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Divider(height: 32),
                      for (final verse in _verses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '${verse.number}. ${verse.text}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _chapter > 1 ? _previousChapter : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
            Text(
              '$_bookId $_chapter',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _nextChapter,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
