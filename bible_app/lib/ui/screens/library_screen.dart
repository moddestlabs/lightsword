import 'package:flutter/material.dart';
import 'history_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: const Text('Bookmarks'),
            subtitle: const Text('Your saved verses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to bookmarks
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.note_outlined),
            title: const Text('Notes'),
            subtitle: const Text('Your study notes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notes
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Reading Plans'),
            subtitle: const Text('Structured reading schedules'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to reading plans
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            subtitle: const Text('Recently viewed passages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

