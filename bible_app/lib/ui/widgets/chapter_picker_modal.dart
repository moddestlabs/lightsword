import 'package:flutter/material.dart';

/// Full-screen page for selecting a chapter within the current book
class ChapterPickerModal extends StatelessWidget {
  final String bookName;
  final int currentChapter;
  final int chapterCount;
  final Function(int) onChapterSelected;

  const ChapterPickerModal({
    super.key,
    required this.bookName,
    required this.currentChapter,
    required this.chapterCount,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: const SizedBox.shrink(), // No back button on left
        title: Text(
          bookName,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Done',
              style: TextStyle(
                fontSize: 17,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: chapterCount,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          final isCurrentChapter = chapter == currentChapter;
          
          return GestureDetector(
            onTap: () {
              onChapterSelected(chapter);
              Navigator.of(context).pop();
            },
            child: Container(
              decoration: BoxDecoration(
                color: isCurrentChapter 
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$chapter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isCurrentChapter 
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show the chapter picker as a full-screen page
  static Future<void> show({
    required BuildContext context,
    required String bookName,
    required int currentChapter,
    required int chapterCount,
    required Function(int) onChapterSelected,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChapterPickerModal(
          bookName: bookName,
          currentChapter: currentChapter,
          chapterCount: chapterCount,
          onChapterSelected: onChapterSelected,
        ),
      ),
    );
  }
}
