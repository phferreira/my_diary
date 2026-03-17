import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/ui/widgets/diary_editor_content.dart';

class DiaryEditorDesktopLayout extends StatelessWidget {
  const DiaryEditorDesktopLayout({
    required this.dateLabel,
    required this.isLoadingEntry,
    required this.isPublic,
    required this.isUpdatingAccess,
    required this.contentController,
    required this.editorFocusNode,
    required this.editorScrollController,
    required this.onSelectDate,
    required this.onChangeDay,
    required this.onChangeMonth,
    required this.onUpdateVisibility,
    required this.onSave,
    required this.editorContainerKey,
    super.key,
  });

  static const Key layoutKey = Key('diary-editor-desktop');

  final String dateLabel;
  final bool isLoadingEntry;
  final bool isPublic;
  final bool isUpdatingAccess;
  final QuillController contentController;
  final FocusNode editorFocusNode;
  final ScrollController editorScrollController;
  final VoidCallback onSelectDate;
  final Future<void> Function(int delta) onChangeDay;
  final Future<void> Function(int delta) onChangeMonth;
  final ValueChanged<bool> onUpdateVisibility;
  final Future<void> Function() onSave;
  final Key editorContainerKey;

  @override
  Widget build(BuildContext context) {
    return DiaryEditorContent(
      key: layoutKey,
      dateHeader: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            tooltip: AppStrings.previousMonth,
            onPressed: isLoadingEntry ? null : () => onChangeMonth(-1),
            icon: const Icon(Icons.keyboard_double_arrow_left),
          ),
          IconButton(
            tooltip: AppStrings.previousDay,
            onPressed: isLoadingEntry ? null : () => onChangeDay(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton(
            onPressed: isLoadingEntry ? null : onSelectDate,
            child: Text(
              dateLabel,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextDay,
            onPressed: isLoadingEntry ? null : () => onChangeDay(1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: AppStrings.nextMonth,
            onPressed: isLoadingEntry ? null : () => onChangeMonth(1),
            icon: const Icon(Icons.keyboard_double_arrow_right),
          ),
        ],
      ),
      isCompact: false,
      isPublic: isPublic,
      isUpdatingAccess: isUpdatingAccess,
      contentController: contentController,
      editorFocusNode: editorFocusNode,
      editorScrollController: editorScrollController,
      editorContainerKey: editorContainerKey,
      onUpdateVisibility: onUpdateVisibility,
      onSave: onSave,
    );
  }
}
