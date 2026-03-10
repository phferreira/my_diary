import 'package:flutter/material.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/ui/design_system/theme/app_theme.dart';
import 'package:my_diary/ui/pages/login_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';

void main() {
  final repository = InMemoryDiaryRepository();
  final findDiaryUseCase = FindDiaryUseCase(repository);
  final loginViewModel = LoginViewModel(findDiaryUseCase);

  runApp(MyDiaryApp(loginViewModel: loginViewModel));
}

class MyDiaryApp extends StatelessWidget {
  const MyDiaryApp({
    required this.loginViewModel,
    super.key,
  });

  final LoginViewModel loginViewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      home: LoginPage(viewModel: loginViewModel),
    );
  }
}
