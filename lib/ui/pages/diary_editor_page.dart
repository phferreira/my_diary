import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';
import 'package:my_diary/ui/widgets/diary_editor_desktop_layout.dart';
import 'package:my_diary/ui/widgets/diary_editor_mobile_layout.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({
    required this.diary,
    required this.loadDiaryEntryUseCase,
    required this.saveDiaryEntryUseCase,
    required this.updateDiaryAccessUseCase,
    this.canEdit = true,
    this.initialDate,
    super.key,
  });

  final Diary diary;
  final LoadDiaryEntryUseCase loadDiaryEntryUseCase;
  final SaveDiaryEntryUseCase saveDiaryEntryUseCase;
  final UpdateDiaryAccessUseCase updateDiaryAccessUseCase;
  final bool canEdit;
  final DateTime? initialDate;

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final QuillController _contentController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  bool _isPublic = false;
  bool _isLoadingEntry = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _contentController = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _contentController.readOnly = !widget.canEdit;
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
    if (!widget.canEdit) {
      return;
    }

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

  Future<void> _openConfiguration() async {
    if (!widget.canEdit) {
      return;
    }

    final config = await showDialog<_DiaryAccessConfigResult>(
      context: context,
      builder: (BuildContext context) {
        return _DiaryAccessConfigDialog(
          diary: widget.diary,
          initialIsPublic: _isPublic,
        );
      },
    );

    if (config == null || !mounted) {
      return;
    }

    try {
      await widget.updateDiaryAccessUseCase(
        diaryId: widget.diary.id,
        isPublic: config.isPublic,
        publicPassword: config.publicPassword,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.diaryVisibilityError)),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPublic = config.isPublic;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          config.isPublic
              ? AppStrings.diaryPublicEnabled
              : AppStrings.diaryPrivateEnabled,
        ),
      ),
    );
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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
    final dateLabel = localizations.formatFullDate(_selectedDate);

    final content = isCompact
        ? DiaryEditorMobileLayout(
            dateLabel: dateLabel,
            isLoadingEntry: _isLoadingEntry,
            isPublic: _isPublic,
            canEdit: widget.canEdit,
            contentController: _contentController,
            editorFocusNode: _editorFocusNode,
            editorScrollController: _editorScrollController,
            onSelectDate: _selectDate,
            onChangeDay: _changeDay,
            onChangeMonth: _changeMonth,
            onSave: _saveContent,
            onConfigure: widget.canEdit ? _openConfiguration : null,
          )
        : DiaryEditorDesktopLayout(
            dateLabel: dateLabel,
            isLoadingEntry: _isLoadingEntry,
            isPublic: _isPublic,
            canEdit: widget.canEdit,
            contentController: _contentController,
            editorFocusNode: _editorFocusNode,
            editorScrollController: _editorScrollController,
            onSelectDate: _selectDate,
            onChangeDay: _changeDay,
            onChangeMonth: _changeMonth,
            onSave: _saveContent,
            onConfigure: widget.canEdit ? _openConfiguration : null,
          );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.diary.name),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height -
              MediaQuery.of(context).padding.top * 2,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: AppSurfaceCard(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaryAccessConfigResult {
  const _DiaryAccessConfigResult({
    required this.isPublic,
    this.publicPassword,
  });

  final bool isPublic;
  final String? publicPassword;
}

class _DiaryAccessConfigDialog extends StatefulWidget {
  const _DiaryAccessConfigDialog({
    required this.diary,
    required this.initialIsPublic,
  });

  final Diary diary;
  final bool initialIsPublic;

  @override
  State<_DiaryAccessConfigDialog> createState() =>
      _DiaryAccessConfigDialogState();
}

class _DiaryAccessConfigDialogState extends State<_DiaryAccessConfigDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _publicPasswordController =
      TextEditingController();
  final TextEditingController _confirmPublicPasswordController =
      TextEditingController();

  bool _isPublic = false;
  bool _showPublicPassword = false;
  bool _showConfirmPublicPassword = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.initialIsPublic;
  }

  @override
  void dispose() {
    _publicPasswordController.dispose();
    _confirmPublicPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_isPublic) {
      Navigator.of(context)
          .pop(const _DiaryAccessConfigResult(isPublic: false));
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final publicPassword = _publicPasswordController.text.trim();
    Navigator.of(context).pop(
      _DiaryAccessConfigResult(
        isPublic: true,
        publicPassword: publicPassword,
      ),
    );
  }

  String? _validatePublicPassword(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return AppStrings.publicPasswordRequired;
    }
    if (trimmedValue.length < 4) {
      return AppStrings.passwordMinLength;
    }
    if (widget.diary.hasPassword &&
        widget.diary.matchesPassword(trimmedValue)) {
      return AppStrings.publicPasswordMustDifferFromMaster;
    }

    return null;
  }

  String? _validateConfirmPublicPassword(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return AppStrings.publicPasswordRequired;
    }
    if (trimmedValue != _publicPasswordController.text.trim()) {
      return AppStrings.passwordsDontMatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('"${widget.diary.name}"'),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isPublic,
              title: const Text(AppStrings.publicAccessLabel),
              subtitle: Text(
                _isPublic
                    ? AppStrings.publicAccessDescription
                    : AppStrings.diaryPrivateDescription,
              ),
              onChanged: (bool value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            if (_isPublic) ...<Widget>[
              const SizedBox(height: 8),
              TextFormField(
                controller: _publicPasswordController,
                obscureText: !_showPublicPassword,
                validator: _validatePublicPassword,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                decoration: InputDecoration(
                  labelText: AppStrings.publicDiaryPasswordLabel,
                  hintText: AppStrings.publicDiaryPasswordHint,
                  suffixIcon: IconButton(
                    tooltip: _showPublicPassword
                        ? AppStrings.hidePassword
                        : AppStrings.showPassword,
                    icon: Icon(
                      _showPublicPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _showPublicPassword = !_showPublicPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPublicPasswordController,
                obscureText: !_showConfirmPublicPassword,
                validator: _validateConfirmPublicPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  labelText: AppStrings.confirmPublicDiaryPasswordLabel,
                  hintText: AppStrings.publicDiaryPasswordHint,
                  suffixIcon: IconButton(
                    tooltip: _showConfirmPublicPassword
                        ? AppStrings.hidePassword
                        : AppStrings.showPassword,
                    icon: Icon(
                      _showConfirmPublicPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _showConfirmPublicPassword =
                          !_showConfirmPublicPassword,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return AlertDialog(
      title: const Text(AppStrings.accessConfigurationTitle),
      content: content,
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _handleSubmit,
          child: const Text(AppStrings.confirm),
        ),
      ],
    );
  }
}
