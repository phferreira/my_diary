import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/ui/design_system/widgets/app_filled_icon_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';

class DiaryEditorContent extends StatelessWidget {
  const DiaryEditorContent({
    required this.dateHeader,
    required this.isCompact,
    required this.isPublic,
    required this.canEdit,
    required this.contentController,
    required this.editorFocusNode,
    required this.editorScrollController,
    required this.onSave,
    required this.onConfigure,
    super.key,
  });

  final Widget dateHeader;
  final bool isCompact;
  final bool isPublic;
  final bool canEdit;
  final QuillController contentController;
  final FocusNode editorFocusNode;
  final ScrollController editorScrollController;
  final Future<void> Function() onSave;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        dateHeader,
        const SizedBox(height: 12),
        if (isPublic)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              canEdit
                  ? AppStrings.diaryPrivateDescription
                  : AppStrings.publicAccessReadOnlyDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 12),
        if (canEdit) ...<Widget>[
          QuillSimpleToolbar(
            controller: contentController,
            config: QuillSimpleToolbarConfig(
              multiRowsDisplay: !isCompact,
              showAlignmentButtons: true,
              showCodeBlock: false,
            ),
          ),
          const SizedBox(height: 12),
        ],
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
        if (canEdit)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: <Widget>[
                SizedBox(
                  width: 180,
                  child: AppPrimaryButton(
                    onPressed: onSave,
                    label: AppStrings.save,
                  ),
                ),
                if (onConfigure != null)
                  SizedBox(
                    width: 180,
                    child: AppFilledIconButton(
                      onPressed: onConfigure,
                      icon: Icons.settings_outlined,
                      label: AppStrings.configuration,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
