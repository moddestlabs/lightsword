import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class TestAssetsScreen extends StatefulWidget {
  const TestAssetsScreen({super.key});

  @override
  State<TestAssetsScreen> createState() => _TestAssetsScreenState();
}

class _TestAssetsScreenState extends State<TestAssetsScreen> {
  String _status = 'Testing asset loading...';
  
  @override
  void initState() {
    super.initState();
    _testAssets();
  }
  
  Future<void> _testAssets() async {
    final results = <String>[];
    
    // Test different path variations
    final pathsToTest = [
      'assets/data/usfm/bsb/73-JHNengbsb.usfm',
      'data/usfm/bsb/73-JHNengbsb.usfm',
      'assets/data/usfm/bsb/',
    ];
    
    for (final path in pathsToTest) {
      try {
        results.add('Trying: $path');
        final content = await rootBundle.loadString(path);
        results.add('✅ SUCCESS: Loaded ${content.length} bytes from $path');
        break;
      } catch (e) {
        results.add('❌ FAILED: $path - $e');
      }
    }
    
    setState(() {
      _status = results.join('\n');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asset Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            _status,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ),
    );
  }
}
