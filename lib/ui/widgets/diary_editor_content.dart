import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';

class DiaryEditorContent extends StatelessWidget {
  const DiaryEditorContent({
    required this.dateHeader,
    required this.isCompact,
    required this.isPublic,
    required this.contentController,
    required this.editorFocusNode,
    required this.editorScrollController,
    required this.onSave,
    super.key,
  });

  final Widget dateHeader;
  final bool isCompact;
  final bool isPublic;
  final QuillController contentController;
  final FocusNode editorFocusNode;
  final ScrollController editorScrollController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        dateHeader,
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: isPublic,
          title: const Text(AppStrings.diaryPublicLabel),
          subtitle: Text(
            isPublic
                ? AppStrings.diaryPublicDescription
                : AppStrings.diaryPrivateDescription,
          ),
          onChanged: null,
        ),
        const SizedBox(height: 12),
        QuillSimpleToolbar(
          controller: contentController,
          config: QuillSimpleToolbarConfig(
            multiRowsDisplay: !isCompact,
            showAlignmentButtons: true,
            showCodeBlock: false,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.diaryEditorContentLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QuillEditor(
              controller: contentController,
              focusNode: editorFocusNode,
              scrollController: editorScrollController,
              config: const QuillEditorConfig(
                padding: EdgeInsets.all(12),
                placeholder: AppStrings.diaryEditorContentHint,
                expands: true,
                autoFocus: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: isCompact ? double.infinity : 180,
            child: AppPrimaryButton(
              onPressed: onSave,
              label: AppStrings.save,
            ),
          ),
        ),
      ],
    );
  }
}
