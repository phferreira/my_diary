import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/save_diary_content_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({
    required this.diary,
    required this.saveDiaryContentUseCase,
    super.key,
  });

  final Diary diary;
  final SaveDiaryContentUseCase saveDiaryContentUseCase;

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final TextEditingController _contentController;

  TextAlign _textAlign = TextAlign.left;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.diary.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    await widget.saveDiaryContentUseCase(
      diaryId: widget.diary.id,
      content: _contentController.text,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.contentSaved)),
    );
  }

  void _applyMarkdownMarker(String marker) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (!selection.isValid || text.isEmpty) {
      return;
    }

    final targetSelection = selection.isCollapsed
        ? _expandToCurrentWord(text, selection.start)
        : selection;

    if (!targetSelection.isValid || targetSelection.start == targetSelection.end) {
      return;
    }

    final selectedText = text.substring(targetSelection.start, targetSelection.end);
    final wrappedText = selectedText.startsWith(marker) &&
            selectedText.endsWith(marker) &&
            selectedText.length > marker.length * 2
        ? selectedText.substring(marker.length, selectedText.length - marker.length)
        : '$marker$selectedText$marker';

    final updatedText = text.replaceRange(
      targetSelection.start,
      targetSelection.end,
      wrappedText,
    );

    _contentController.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: targetSelection.start + wrappedText.length,
      ),
    );
  }

  TextSelection _expandToCurrentWord(String text, int cursorPosition) {
    if (cursorPosition < 0 || cursorPosition > text.length) {
      return const TextSelection.collapsed(offset: -1);
    }

    var start = cursorPosition;
    var end = cursorPosition;

    while (start > 0 && !_isWordBoundary(text[start - 1])) {
      start--;
    }

    while (end < text.length && !_isWordBoundary(text[end])) {
      end++;
    }

    return TextSelection(baseOffset: start, extentOffset: end);
  }

  bool _isWordBoundary(String char) {
    return RegExp(r'\s').hasMatch(char);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diary.name),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Negrito (.md)',
                      onPressed: () => _applyMarkdownMarker('**'),
                      icon: const Icon(Icons.format_bold),
                    ),
                    IconButton(
                      tooltip: 'Itálico (.md)',
                      onPressed: () => _applyMarkdownMarker('*'),
                      icon: const Icon(Icons.format_italic),
                    ),
                    IconButton(
                      tooltip: 'Alinhar à esquerda',
                      onPressed: () => setState(() => _textAlign = TextAlign.left),
                      icon: Icon(
                        Icons.format_align_left,
                        color: _textAlign == TextAlign.left
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Centralizar',
                      onPressed: () => setState(() => _textAlign = TextAlign.center),
                      icon: Icon(
                        Icons.format_align_center,
                        color: _textAlign == TextAlign.center
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Alinhar à direita',
                      onPressed: () => setState(() => _textAlign = TextAlign.right),
                      icon: Icon(
                        Icons.format_align_right,
                        color: _textAlign == TextAlign.right
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    maxLength: 4000,
                    textAlign: _textAlign,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      height: 1.4,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      LengthLimitingTextInputFormatter(4000),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: AppStrings.diaryEditorContentLabel,
                      hintText: AppStrings.diaryEditorContentHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: isCompact ? double.infinity : 180,
                    child: AppPrimaryButton(
                      onPressed: _saveContent,
                      label: AppStrings.save,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
