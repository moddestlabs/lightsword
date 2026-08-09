import 'package:flutter/material.dart';
import 'package:bible_core/bible_core.dart';
import 'package:bible_app/services/local_reading_history_service.dart';
import 'package:bible_app/services/deep_linking_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<DateTime, List<HistoryEntry>> _groupedHistory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    final grouped =
        await LocalReadingHistoryService.instance.getGroupedHistory();

    if (mounted) {
      setState(() {
        _groupedHistory = grouped;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Reading History?'),
        content: const Text(
          'This will permanently remove all visited verse history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalReadingHistoryService.instance.clearHistory();
      await _loadHistory();
    }
  }

  Future<void> _deleteEntry(String id) async {
    await LocalReadingHistoryService.instance.deleteEntry(id);
    await _loadHistory();
  }

  void _onEntryTapped(HistoryEntry entry) {
    DeepLinkingService.instance.navigateTo(entry.reference);
    // Pop history screen if pushed onto stack
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    } else if (target == yesterday) {
      return 'Yesterday';
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];


    final weekdayStr = weekdays[date.weekday - 1];
    final monthStr = months[date.month - 1];
    final day = date.day;

    String suffix = 'th';
    if (day % 10 == 1 && day % 100 != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day % 100 != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day % 100 != 13) {
      suffix = 'rd';
    }

    return '$weekdayStr, $monthStr $day$suffix';
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final days = _groupedHistory.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        actions: [
          if (days.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear History',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : days.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reading history yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verses you visit will be listed here per day.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: days.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final dayDate = days[index];
                    final entries = _groupedHistory[dayDate] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            _formatDateHeader(dayDate),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        ...entries.map(
                          (entry) => Dismissible(
                            key: Key(entry.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              color: Theme.of(context).colorScheme.errorContainer,
                              child: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                            onDismissed: (_) => _deleteEntry(entry.id),
                            child: ListTile(
                              leading: const Icon(Icons.menu_book),
                              title: Text(
                                entry.reference.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(_formatTime(entry.timestamp)),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              onTap: () => _onEntryTapped(entry),
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                      ],
                    );
                  },
                ),
    );
  }
}
