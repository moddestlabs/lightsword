import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class OfflinePackManager extends StatefulWidget {
  const OfflinePackManager({super.key});

  @override
  State<OfflinePackManager> createState() => _OfflinePackManagerState();
}

class _OfflinePackManagerState extends State<OfflinePackManager> {
  bool _isLoading = false;
  Map<OfflinePackId, OfflinePackStatus> _statuses = const {};

  @override
  void initState() {
    super.initState();
    _refreshStatus();
    PwaService.instance.offlinePackStatusStream.listen((statuses) {
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
      });
    });
  }

  Future<void> _refreshStatus() async {
    final statuses = await PwaService.instance.refreshOfflinePackStatus();
    if (!mounted) return;
    setState(() {
      _statuses = statuses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pwa = PwaService.instance;
    if (!pwa.isWeb) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Packs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!pwa.isAvailable) ...[
              Text(
                'PWA controls are unavailable because the web bridge did not initialize in this session.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Text(
                'Install larger study packs only when you want them offline. The default install keeps this separate to stay reliable on iPhone.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final pack in offlinePackDefinitions)
                _buildPackTile(context, pack, _statuses[pack.id]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackTile(
    BuildContext context,
    OfflinePackDefinition pack,
    OfflinePackStatus? status,
  ) {
    final theme = Theme.of(context);
    final statusText = switch (status) {
      null => 'Not checked yet',
      final s when s.isInstalled => 'Installed (${s.cachedFiles}/${s.totalFiles} files)',
      final s when s.isPartial => 'Partial (${s.cachedFiles}/${s.totalFiles} files)',
      final s => 'Not installed (${s.cachedFiles}/${s.totalFiles} files)',
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        status?.isInstalled == true ? Icons.download_done : Icons.download,
      ),
      title: Text(pack.title),
      subtitle: Text('${pack.subtitle}\n$statusText • ${pack.sizeLabel}'),
      isThreeLine: true,
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton.tonal(
              onPressed: status?.isInstalled == true ? _refreshStatus : () => _downloadPack(pack.id),
              child: Text(status?.isInstalled == true ? 'Refresh' : 'Download'),
            ),
      iconColor: theme.colorScheme.primary,
    );
  }

  Future<void> _downloadPack(OfflinePackId packId) async {
    setState(() {
      _isLoading = true;
    });

    final result = await PwaService.instance.cacheOfflinePack(packId);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? 'Offline pack downloaded.'
              : 'Could not download offline pack${result.error != null ? ': ${result.error}' : ''}',
        ),
      ),
    );
  }
}

class PwaDiagnosticsCard extends StatefulWidget {
  const PwaDiagnosticsCard({super.key});

  @override
  State<PwaDiagnosticsCard> createState() => _PwaDiagnosticsCardState();
}

class _PwaDiagnosticsCardState extends State<PwaDiagnosticsCard> {
  PwaDiagnostics? _diagnostics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    setState(() {
      _isLoading = true;
    });

    final diagnostics = await PwaService.instance.getDiagnostics();
    if (!mounted) {
      return;
    }

    setState(() {
      _diagnostics = diagnostics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pwa = PwaService.instance;
    if (!pwa.isWeb) {
      return const SizedBox.shrink();
    }

    final diagnostics = _diagnostics;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PWA Diagnostics',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshDiagnostics,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            Text(
              'Use this on iPhone to confirm whether the home-screen app has a controller, registration scope, and cached shell before testing Airplane mode.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!pwa.isAvailable)
              Text(
                'PWA bridge unavailable. This usually means the page is not running the web PWA helpers yet, or initialization did not complete. Refresh once and check whether this page is the web build.',
                style: theme.textTheme.bodyMedium,
              )
            else if (diagnostics == null)
              Text(
                _isLoading ? 'Loading diagnostics…' : 'Diagnostics unavailable.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    context,
                    label: diagnostics.online ? 'Online' : 'Offline',
                    icon: diagnostics.online ? Icons.cloud_done : Icons.cloud_off,
                  ),
                  _buildChip(
                    context,
                    label: diagnostics.standalone ? 'Standalone' : 'Browser Tab',
                    icon: diagnostics.standalone ? Icons.phone_iphone : Icons.public,
                  ),
                  _buildChip(
                    context,
                    label: diagnostics.serviceWorkerController ? 'SW Controlled' : 'No SW Controller',
                    icon: diagnostics.serviceWorkerController ? Icons.shield_outlined : Icons.warning_amber_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildValue(context, 'Launch URL', diagnostics.locationHref),
              _buildValue(context, 'Path', diagnostics.locationPathname),
              _buildValue(context, 'Base Href', diagnostics.baseHref),
              _buildValue(context, 'Referrer', diagnostics.referrer),
              _buildValue(context, 'Registration Scope', diagnostics.serviceWorkerRegistrationScope),
              _buildValue(context, 'Controller Script', diagnostics.serviceWorkerControllerScriptUrl),
              _buildValue(context, 'Active Script', diagnostics.serviceWorkerRegistrationActiveScriptUrl),
              _buildValue(context, 'Active State', diagnostics.serviceWorkerRegistrationActiveState),
              _buildValue(context, 'Boot Status', diagnostics.bootStatus),
              _buildValue(context, 'Boot Detail', diagnostics.bootLastDetail),
              _buildValue(
                context,
                'Last Boot Failure',
                diagnostics.bootLastFailure?.summary,
              ),
              _buildValue(context, 'Shell Cache', diagnostics.shellStatus?.summary),
              _buildValue(context, 'Default Pack Cache', diagnostics.defaultPackStatus?.summary),
              for (final entry in diagnostics.optionalPacks.entries)
                _buildValue(context, 'Pack ${entry.key}', entry.value.summary),
              _buildValue(
                context,
                'Cache Buckets',
                diagnostics.cacheKeys.isEmpty ? 'none' : diagnostics.cacheKeys.join(', '),
              ),
              if (diagnostics.errors.isNotEmpty)
                _buildValue(context, 'Errors', diagnostics.errors.join(' | ')),
              if (diagnostics.bootEvents.isNotEmpty)
                _buildValue(context, 'Boot Events', diagnostics.bootEvents.join(' | ')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _copyDiagnostics(diagnostics),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy Diagnostics'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildValue(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(
            value == null || value.isEmpty ? 'unknown' : value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _copyDiagnostics(PwaDiagnostics diagnostics) async {
    await Clipboard.setData(ClipboardData(text: diagnostics.toDebugReport()));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diagnostics copied to clipboard')),
    );
  }
}
