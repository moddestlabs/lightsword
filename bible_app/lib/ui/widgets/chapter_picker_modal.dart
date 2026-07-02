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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(), // No back button on left
        title: Text(
          bookName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF007AFF),
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
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$chapter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isCurrentChapter 
                        ? Colors.white
                        : Colors.black,
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
