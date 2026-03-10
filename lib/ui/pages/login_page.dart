import 'package:flutter/material.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/design_system/widgets/app_surface_card.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';
import 'package:my_diary/ui/widgets/diary_search_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.viewModel,
    super.key,
  });

  final LoginViewModel viewModel;

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

    final message = await widget.viewModel.findDiaryMessage(_queryController.text);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                    AppStrings.loginTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DiarySearchField(controller: _queryController),
                  const SizedBox(height: 16),
                  AppPrimaryButton(
                    onPressed: _onFindDiary,
                    label: 'Encontrar diário',
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
