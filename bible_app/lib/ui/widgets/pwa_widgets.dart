import 'package:flutter/material.dart';
import '../../services/pwa_service.dart';

/// Banner widget that shows online/offline status and install prompt
class PwaBanner extends StatefulWidget {
  const PwaBanner({super.key});

  @override
  State<PwaBanner> createState() => _PwaBannerState();
}

class _PwaBannerState extends State<PwaBanner> {
  bool _isOnline = true;
  bool _showInstallPrompt = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _initializePwa();
  }

  void _initializePwa() {
    final pwa = PwaService.instance;
    
    if (!pwa.isWeb) return;

    // Initial state
    setState(() {
      _isOnline = pwa.isOnline;
      _showInstallPrompt = pwa.isInstallable && !pwa.isInstalled;
    });

    // Listen to online/offline changes
    pwa.onlineStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });

    // Listen to install availability
    pwa.installAvailableStream.listen((_) {
      if (mounted && !pwa.isInstalled) {
        setState(() {
          _showInstallPrompt = true;
          _isDismissed = false;
        });
      }
    });

    // Listen to app installed
    pwa.appInstalledStream.listen((_) {
      if (mounted) {
        setState(() {
          _showInstallPrompt = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PwaService.instance.isWeb) {
      return const SizedBox.shrink();
    }

    // Show offline banner
    if (!_isOnline) {
      return _buildOfflineBanner(context);
    }

    // Show install prompt
    if (_showInstallPrompt && !_isDismissed) {
      return _buildInstallBanner(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You\'re offline. LIGHTSWORD works offline with cached content.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallBanner(BuildContext context) {
    final platform = PwaService.instance.platformInfo;
    final isIOS = platform?.isIOS ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.install_mobile,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Install LIGHTSWORD',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isIOS
                      ? 'Tap Share > Add to Home Screen'
                      : 'Install for offline access and better performance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isIOS)
            FilledButton(
              onPressed: _handleInstall,
              child: const Text('Install'),
            ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: () {
              setState(() {
                _isDismissed = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleInstall() async {
    final success = await PwaService.instance.showInstallPrompt();
    if (success && mounted) {
      setState(() {
        _showInstallPrompt = false;
      });
    }
  }
}

/// Offline indicator icon for app bar
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeStatus();
  }

  void _initializeStatus() {
    final pwa = PwaService.instance;
    
    if (!pwa.isWeb) return;

    setState(() {
      _isOnline = pwa.isOnline;
    });

    pwa.onlineStatusStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PwaService.instance.isWeb || _isOnline) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'Offline',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(
          Icons.cloud_off,
          color: Colors.orange.shade700,
          size: 20,
        ),
      ),
    );
  }
}

/// Widget showing TTS capabilities on the current platform
class TtsCapabilityIndicator extends StatelessWidget {
  const TtsCapabilityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final pwa = PwaService.instance;
    
    if (!pwa.isWeb || !pwa.isAvailable) {
      return const SizedBox.shrink();
    }

    final ttsInfo = pwa.ttsInfo;
    if (ttsInfo == null || !ttsInfo.supported) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Text-to-speech not supported on this browser',
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show warning if Hebrew or Greek not available
    if (!ttsInfo.hasHebrew || !ttsInfo.hasGreek) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Text(
                    'TTS Language Support',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Available: ${ttsInfo.supportSummary}',
                style: TextStyle(color: Colors.blue.shade900),
              ),
              if (!ttsInfo.hasHebrew || !ttsInfo.hasGreek) ...[
                const SizedBox(height: 4),
                Text(
                  'Missing: ${[
                    if (!ttsInfo.hasHebrew) 'Hebrew',
                    if (!ttsInfo.hasGreek) 'Greek',
                  ].join(', ')}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
