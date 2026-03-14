import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({
    required this.diary,
    required this.loadDiaryEntryUseCase,
    required this.saveDiaryEntryUseCase,
    super.key,
  });

  final Diary diary;
  final LoadDiaryEntryUseCase loadDiaryEntryUseCase;
  final SaveDiaryEntryUseCase saveDiaryEntryUseCase;

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final QuillController _contentController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  TextAlign _textAlign = TextAlign.left;
  DateTime _selectedDate = _normalizeDate(DateTime.now());
  bool _isLoadingEntry = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _loadEntryForDate(_selectedDate);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    await widget.saveDiaryEntryUseCase(
      diaryId: widget.diary.id,
      date: _selectedDate,
      content: _contentController.text,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.contentSaved)),
    );
  }

  Future<void> _loadEntryForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    setState(() {
      _isLoadingEntry = true;
      _selectedDate = normalizedDate;
    });

    final entry = await widget.loadDiaryEntryUseCase(
      diaryId: widget.diary.id,
      date: normalizedDate,
    );

    if (!mounted) {
      return;
    }

    _contentController.text = entry?.content ?? '';
    setState(() => _isLoadingEntry = false);
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

    if (!targetSelection.isValid ||
        targetSelection.start == targetSelection.end) {
      return;
    }

    final selectedText =
        text.substring(targetSelection.start, targetSelection.end);
    final wrappedText = selectedText.startsWith(marker) &&
            selectedText.endsWith(marker) &&
            selectedText.length > marker.length * 2
        ? selectedText.substring(
            marker.length, selectedText.length - marker.length)
        : '$marker$selectedText$marker';

    try {
      await widget.updateDiaryAccessUseCase(
        diaryId: widget.diary.id,
        isPublic: isPublic,
        password: password,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPublic
                ? AppStrings.diaryPublicEnabled
                : AppStrings.diaryPrivateEnabled,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isPublic = !isPublic);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.diaryVisibilityError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAccess = false);
      }
    }
  }

  Future<String?> _promptNewPassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;
    bool showPassword = false;
    bool showConfirmation = false;

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text(AppStrings.setDiaryPasswordTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(AppStrings.setDiaryPasswordDescription),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: AppStrings.newDiaryPasswordLabel,
                        hintText: AppStrings.newDiaryPasswordHint,
                        suffixIcon: IconButton(
                          tooltip: showPassword
                              ? AppStrings.hidePassword
                              : AppStrings.showPassword,
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => showPassword = !showPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      obscureText: !showConfirmation,
                      decoration: InputDecoration(
                        labelText: AppStrings.confirmPasswordLabel,
                        suffixIcon: IconButton(
                          tooltip: showConfirmation
                              ? AppStrings.hidePassword
                              : AppStrings.showPassword,
                          icon: Icon(
                            showConfirmation
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => showConfirmation = !showConfirmation,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final password = passwordController.text.trim();
                    final confirmation = confirmController.text.trim();

                    if (password.length < 4) {
                      setState(
                          () => errorMessage = AppStrings.passwordMinLength);
                      return;
                    }

                    if (password != confirmation) {
                      setState(
                          () => errorMessage = AppStrings.passwordsDontMatch);
                      return;
                    }

                    Navigator.of(context).pop(password);
                  },
                  child: const Text(AppStrings.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();

    return result;
  }

  Document _loadDocument(String content) {
    if (content.trim().isEmpty) {
      return Document();
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return Document.fromJson(decoded);
      }
      if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        return Document.fromJson(decoded['ops'] as List<dynamic>);
      }
    } catch (_) {
      // Fallback to plain text content.
    }

    return _documentFromPlainText(content);
  }

  Document _documentFromPlainText(String content) {
    final document = Document();
    if (content.isEmpty) {
      return document;
    }

    final normalized = content.endsWith('\n') ? content : '$content\n';
    document.insert(0, normalized);
    return document;
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
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
                      onPressed: () =>
                          setState(() => _textAlign = TextAlign.left),
                      icon: Icon(
                        Icons.format_align_left,
                        color: _textAlign == TextAlign.left
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Centralizar',
                      onPressed: () =>
                          setState(() => _textAlign = TextAlign.center),
                      icon: Icon(
                        Icons.format_align_center,
                        color: _textAlign == TextAlign.center
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Alinhar à direita',
                      onPressed: () =>
                          setState(() => _textAlign = TextAlign.right),
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
                QuillSimpleToolbar(
                  controller: _contentController,
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
                  child: TextField(
                    controller: _contentController,
                    enabled: !_isLoadingEntry,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    maxLength: 4000,
                    textAlign: _textAlign,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      height: 1.4,
                    ),
                    child: QuillEditor(
                      controller: _contentController,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
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
