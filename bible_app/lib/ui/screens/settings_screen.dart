import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            title: Text('Text-to-Speech'),
            leading: Icon(Icons.volume_up_outlined),
          ),
          ListTile(
            title: const Text('Speech Rate'),
            subtitle: const Text('Adjust reading speed'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: TTS rate slider
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
}
