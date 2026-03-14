import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/config/app_environment.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
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
  final loadDiaryEntryUseCase = LoadDiaryEntryUseCase(repository);
  final saveDiaryEntryUseCase = SaveDiaryEntryUseCase(repository);
  final loginViewModel = LoginViewModel(findDiaryUseCase, createDiaryUseCase);

  runApp(
    MyDiaryApp(
      loginViewModel: loginViewModel,
      loadDiaryEntryUseCase: loadDiaryEntryUseCase,
      saveDiaryEntryUseCase: saveDiaryEntryUseCase,
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
    required this.loadDiaryEntryUseCase,
    required this.saveDiaryEntryUseCase,
    super.key,
  });

  final LoginViewModel loginViewModel;
  final LoadDiaryEntryUseCase loadDiaryEntryUseCase;
  final SaveDiaryEntryUseCase saveDiaryEntryUseCase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      home: LoginPage(
        viewModel: loginViewModel,
        loadDiaryEntryUseCase: loadDiaryEntryUseCase,
        saveDiaryEntryUseCase: saveDiaryEntryUseCase,
      ),
    );
  }
}
