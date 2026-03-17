import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({
    required this.diary,
    required this.loadDiaryEntryUseCase,
    required this.saveDiaryEntryUseCase,
    required this.updateDiaryAccessUseCase,
    this.initialDate,
    super.key,
  });

  final Diary diary;
  final LoadDiaryEntryUseCase loadDiaryEntryUseCase;
  final SaveDiaryEntryUseCase saveDiaryEntryUseCase;
  final UpdateDiaryAccessUseCase updateDiaryAccessUseCase;
  final DateTime? initialDate;

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final QuillController _contentController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  bool _isPublic = false;
  bool _isUpdatingAccess = false;
  bool _isLoadingEntry = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _contentController = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _isPublic = widget.diary.isPublic;
    _selectedDate = _normalizeDate(widget.initialDate ?? DateTime.now());
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
      content: jsonEncode(_contentController.document.toDelta().toJson()),
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

    _contentController.document = _loadDocument(entry?.content ?? '');
    setState(() => _isLoadingEntry = false);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) {
      return;
    }

    await _loadEntryForDate(picked);
  }

  Future<void> _changeDay(int delta) async {
    final nextDate = _selectedDate.add(Duration(days: delta));
    await _loadEntryForDate(nextDate);
  }

  Future<void> _changeMonth(int delta) async {
    final targetMonth =
        DateTime(_selectedDate.year, _selectedDate.month + delta, 1);
    final lastDayOfMonth =
        DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = _selectedDate.day.clamp(1, lastDayOfMonth);
    final nextDate = DateTime(targetMonth.year, targetMonth.month, day);
    await _loadEntryForDate(nextDate);
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _updateVisibility(bool isPublic) async {
    if (_isUpdatingAccess || isPublic == _isPublic) {
      return;
    }

    String? password;
    if (!isPublic) {
      password = await _promptNewPassword();
      if (!mounted || password == null) {
        setState(() => _isPublic = true);
        return;
      }
    }

    setState(() {
      _isUpdatingAccess = true;
      _isPublic = isPublic;
    });

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
    final localizations = MaterialLocalizations.of(context);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      tooltip: AppStrings.previousMonth,
                      onPressed:
                          _isLoadingEntry ? null : () => _changeMonth(-1),
                      icon: const Icon(Icons.keyboard_double_arrow_left),
                    ),
                    IconButton(
                      tooltip: AppStrings.previousDay,
                      onPressed: _isLoadingEntry ? null : () => _changeDay(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    TextButton(
                      onPressed: _isLoadingEntry ? null : _selectDate,
                      child: Text(
                        localizations.formatFullDate(_selectedDate),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.nextDay,
                      onPressed: _isLoadingEntry ? null : () => _changeDay(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(
                      tooltip: AppStrings.nextMonth,
                      onPressed: _isLoadingEntry ? null : () => _changeMonth(1),
                      icon: const Icon(Icons.keyboard_double_arrow_right),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isPublic,
                  title: const Text(AppStrings.diaryPublicLabel),
                  subtitle: Text(
                    _isPublic
                        ? AppStrings.diaryPublicDescription
                        : AppStrings.diaryPrivateDescription,
                  ),
                  onChanged: _isUpdatingAccess ? null : _updateVisibility,
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
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
