import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';
import 'package:my_diary/ui/pages/diary_editor_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';
import 'package:my_diary/ui/widgets/diary_search_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.viewModel,
    required this.loadDiaryEntryUseCase,
    required this.saveDiaryEntryUseCase,
    required this.updateDiaryAccessUseCase,
    this.appVersion,
    super.key,
  });

  final LoginViewModel viewModel;
  final LoadDiaryEntryUseCase loadDiaryEntryUseCase;
  final SaveDiaryEntryUseCase saveDiaryEntryUseCase;
  final UpdateDiaryAccessUseCase updateDiaryAccessUseCase;
  final String? appVersion;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _queryController = TextEditingController();

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    if (widget.appVersion case final providedVersion?
        when providedVersion.isNotEmpty) {
      setState(() => _appVersion = providedVersion);
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }

    final buildNumber = packageInfo.buildNumber.trim();
    final version = buildNumber.isEmpty
        ? packageInfo.version
        : '${packageInfo.version}+$buildNumber';

    setState(() => _appVersion = version);
  }

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
          loadDiaryEntryUseCase: widget.loadDiaryEntryUseCase,
          saveDiaryEntryUseCase: widget.saveDiaryEntryUseCase,
          updateDiaryAccessUseCase: widget.updateDiaryAccessUseCase,
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
      body: Stack(
        children: <Widget>[
          Center(
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
                      DiarySearchField(
                        controller: _queryController,
                        onSubmitted: (_) => _onFindDiary(),
                      ),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Text(
              _appVersion.isEmpty
                  ? ''
                  : '${AppStrings.appVersionPrefix}$_appVersion',
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    setState(() => _error = null);

    if (_passwordController.text.trim().length < 4) {
      setState(() => _error = AppStrings.passwordMinLength);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = AppStrings.passwordsDontMatch);
      return;
    }

    final diary = await widget.onCreate(
      password: _passwordController.text.trim(),
      isPublic: false,
    );
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
            const SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: false,
              title: Text(AppStrings.createWithoutPassword),
              onChanged: null,
            ),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: AppStrings.newDiaryPasswordLabel,
                hintText: AppStrings.newDiaryPasswordHint,
                suffixIcon: IconButton(
                  tooltip: _showPassword
                      ? AppStrings.hidePassword
                      : AppStrings.showPassword,
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: AppStrings.confirmPasswordLabel,
                suffixIcon: IconButton(
                  tooltip: _showConfirmPassword
                      ? AppStrings.hidePassword
                      : AppStrings.showPassword,
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                ),
              ),
            ),
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
