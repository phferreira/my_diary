import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/save_diary_content_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({
    required this.diary,
    required this.saveDiaryContentUseCase,
    required this.updateDiaryAccessUseCase,
    super.key,
  });

  final Diary diary;
  final SaveDiaryContentUseCase saveDiaryContentUseCase;
  final UpdateDiaryAccessUseCase updateDiaryAccessUseCase;

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final TextEditingController _contentController;

  TextAlign _textAlign = TextAlign.left;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isPublic = false;
  bool _isUpdatingAccess = false;

  @override
  void initState() {
    super.initState();
    final initialState = _parseStoredMarkdown(widget.diary.content);
    _textAlign = initialState.textAlign;
    _isBold = initialState.isBold;
    _isItalic = initialState.isItalic;
    _contentController = TextEditingController(text: initialState.content);
    _isPublic = widget.diary.isPublic;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContent() async {
    final markdownContent = _buildMarkdownContent();

    await widget.saveDiaryContentUseCase(
      diaryId: widget.diary.id,
      content: markdownContent,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.contentSaved)),
    );
  }

  String _buildMarkdownContent() {
    var content = _contentController.text;
    if (content.trim().isEmpty) {
      return content;
    }

    if (_isBold) {
      content = '**$content**';
    }

    if (_isItalic) {
      content = '*$content*';
    }

    final alignTag = _markdownAlignTag(_textAlign);
    if (alignTag != null) {
      content = '<div align="$alignTag">\n\n$content\n\n</div>';
    }

    return content;
  }

  _EditorInitialState _parseStoredMarkdown(String content) {
    var parsedContent = content.trim();
    var textAlign = TextAlign.left;
    var isBold = false;
    var isItalic = false;

    final alignMatch = RegExp(
      r'^<div align="(left|center|right)">\s*([\s\S]*?)\s*</div>$',
      caseSensitive: false,
    ).firstMatch(parsedContent);

    if (alignMatch != null) {
      textAlign = _textAlignFromTag((alignMatch.group(1) ?? 'left'));
      parsedContent = (alignMatch.group(2) ?? '').trim();
    }

    if (_isWrappedBy(parsedContent, '**')) {
      isBold = true;
      parsedContent = _unwrapMarker(parsedContent, '**');
    }

    if (_isWrappedBy(parsedContent, '*')) {
      isItalic = true;
      parsedContent = _unwrapMarker(parsedContent, '*');
    }

    return _EditorInitialState(
      content: parsedContent,
      textAlign: textAlign,
      isBold: isBold,
      isItalic: isItalic,
    );
  }

  bool _isWrappedBy(String content, String marker) {
    return content.startsWith(marker) &&
        content.endsWith(marker) &&
        content.length > marker.length * 2;
  }

  String _unwrapMarker(String content, String marker) {
    return content.substring(marker.length, content.length - marker.length);
  }

  String? _markdownAlignTag(TextAlign align) {
    return switch (align) {
      TextAlign.left || TextAlign.start => 'left',
      TextAlign.center => 'center',
      TextAlign.right || TextAlign.end => 'right',
      _ => null,
    };
  }

  TextAlign _textAlignFromTag(String alignTag) {
    return switch (alignTag.toLowerCase()) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
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
                        () => errorMessage = AppStrings.passwordMinLength,
                      );
                      return;
                    }

                    if (password != confirmation) {
                      setState(
                        () => errorMessage = AppStrings.passwordsDontMatch,
                      );
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    IconButton(
                      tooltip: AppStrings.markdownBoldTooltip,
                      onPressed: () => setState(() => _isBold = !_isBold),
                      icon: Icon(
                        Icons.format_bold,
                        color: _isBold
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.markdownItalicTooltip,
                      onPressed: () => setState(() => _isItalic = !_isItalic),
                      icon: Icon(
                        Icons.format_italic,
                        color: _isItalic
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.alignLeftTooltip,
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
                      tooltip: AppStrings.alignCenterTooltip,
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
                      tooltip: AppStrings.alignRightTooltip,
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
                      fontWeight: _isBold ? FontWeight.w700 : FontWeight.w400,
                      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
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

class _EditorInitialState {
  const _EditorInitialState({
    required this.content,
    required this.textAlign,
    required this.isBold,
    required this.isItalic,
  });

  final String content;
  final TextAlign textAlign;
  final bool isBold;
  final bool isItalic;
}
