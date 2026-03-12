import 'package:flutter/material.dart';
import 'package:my_diary/core/config/app_environment.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_content_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/data/repositories/supabase_diary_repository.dart';
import 'package:my_diary/ui/design_system/theme/app_theme.dart';
import 'package:my_diary/ui/pages/login_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await _buildRepository();
  final findDiaryUseCase = FindDiaryUseCase(repository);
  final createDiaryUseCase = CreateDiaryUseCase(repository);
  final saveDiaryContentUseCase = SaveDiaryContentUseCase(repository);
  final updateDiaryAccessUseCase = UpdateDiaryAccessUseCase(repository);
  final loginViewModel = LoginViewModel(findDiaryUseCase, createDiaryUseCase);

  runApp(
    MyDiaryApp(
      loginViewModel: loginViewModel,
      saveDiaryContentUseCase: saveDiaryContentUseCase,
      updateDiaryAccessUseCase: updateDiaryAccessUseCase,
    ),
  );
}

Future<DiaryRepository> _buildRepository() async {
  if (!AppEnvironment.hasSupabaseConfig) {
    debugPrint(
      'Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY com --dart-define para usar persistência remota.',
    );
    return InMemoryDiaryRepository();
  }

  await Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    anonKey: AppEnvironment.supabaseAnonKey,
  );

  return SupabaseDiaryRepository();
}

class MyDiaryApp extends StatelessWidget {
  const MyDiaryApp({
    required this.loginViewModel,
    required this.saveDiaryContentUseCase,
    required this.updateDiaryAccessUseCase,
    super.key,
  });

  final LoginViewModel loginViewModel;
  final SaveDiaryContentUseCase saveDiaryContentUseCase;
  final UpdateDiaryAccessUseCase updateDiaryAccessUseCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      home: LoginPage(
        viewModel: loginViewModel,
        saveDiaryContentUseCase: saveDiaryContentUseCase,
        updateDiaryAccessUseCase: updateDiaryAccessUseCase,
      ),
    );
  }
}
