import 'package:flutter/material.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/save_diary_content_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';
import 'package:my_diary/ui/pages/diary_editor_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';
import 'package:my_diary/ui/widgets/diary_search_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.viewModel,
    required this.saveDiaryContentUseCase,
    super.key,
  });

  final LoginViewModel viewModel;
  final SaveDiaryContentUseCase saveDiaryContentUseCase;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _onFindDiary() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final result = await widget.viewModel.findDiary(_queryController.text);
    if (!mounted) {
      return;
    }

    switch (result.status) {
      case DiaryLookupStatus.open:
        await _openDiary(result.diary!);
      case DiaryLookupStatus.requiresPassword:
        await _promptDiaryPassword(result.diary!);
      case DiaryLookupStatus.notFound:
        await _promptCreateDiary(_queryController.text.trim());
    }
  }

  Future<void> _openDiary(Diary diary) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiaryEditorPage(
          diary: diary,
          saveDiaryContentUseCase: widget.saveDiaryContentUseCase,
        ),
      ),
    );
  }

  Future<void> _promptDiaryPassword(Diary diary) async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(AppStrings.protectedDiaryNeedsPassword),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppStrings.diaryPasswordLabel,
              hintText: AppStrings.diaryPasswordHint,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text(AppStrings.confirm),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || password == null) {
      return;
    }

    final unlockedDiary = await widget.viewModel.unlockDiary(
      diary: diary,
      password: password,
    );

    if (!mounted) {
      return;
    }

    if (unlockedDiary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.invalidPassword)),
      );
      return;
    }

    await _openDiary(unlockedDiary);
  }

  Future<void> _promptCreateDiary(String diaryName) async {
    final createdDiary = await showDialog<Diary>(
      context: context,
      builder: (BuildContext context) {
        return _CreateDiaryDialog(
          diaryName: diaryName,
          onCreate: ({required String? password, required bool isPublic}) {
            return widget.viewModel.createDiary(
              name: diaryName,
              password: password,
              isPublic: isPublic,
            );
          },
        );
      },
    );

    if (!mounted || createdDiary == null) {
      return;
    }

    await _openDiary(createdDiary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppSurfaceCard(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DiarySearchField(controller: _queryController),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    onPressed: _onFindDiary,
                    label: AppStrings.findDiaryButton,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateDiaryDialog extends StatefulWidget {
  const _CreateDiaryDialog({
    required this.diaryName,
    required this.onCreate,
  });

  final String diaryName;
  final Future<Diary> Function({
    required String? password,
    required bool isPublic,
  }) onCreate;

  @override
  State<_CreateDiaryDialog> createState() => _CreateDiaryDialogState();
}

class _CreateDiaryDialogState extends State<_CreateDiaryDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPublic = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    setState(() => _error = null);

    String? password;

    if (!_isPublic) {
      if (_passwordController.text.trim().length < 4) {
        setState(() => _error = AppStrings.passwordMinLength);
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _error = AppStrings.passwordsDontMatch);
        return;
      }

      password = _passwordController.text.trim();
    }

    final diary = await widget.onCreate(password: password, isPublic: _isPublic);
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(diary);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.createDiaryTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('${AppStrings.createDiaryQuestion}\n"${widget.diaryName}"'),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isPublic,
              title: const Text(AppStrings.createWithoutPassword),
              onChanged: (bool value) => setState(() => _isPublic = value),
            ),
            if (!_isPublic) ...<Widget>[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.newDiaryPasswordLabel,
                  hintText: AppStrings.newDiaryPasswordHint,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.confirmPasswordLabel,
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
          onPressed: _handleCreate,
          child: const Text(AppStrings.openDiary),
        ),
      ],
    );
  }
}
