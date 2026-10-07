import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/config/app_environment.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/core/usecases/unlock_diary_use_case.dart';
import 'package:my_diary/data/clients/dio_diary_api_client.dart';
import 'package:my_diary/data/clients/diary_api_client.dart';
import 'package:my_diary/data/clients/unavailable_diary_api_client.dart';
import 'package:my_diary/data/repositories/backend_diary_repository.dart';
import 'package:my_diary/ui/design_system/theme/app_theme.dart';
import 'package:my_diary/ui/pages/login_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (apiClient, configurationMessage) = _buildApiClient();
  final repository = BackendDiaryRepository(apiClient);
  final findDiaryUseCase = FindDiaryUseCase(repository);
  final createDiaryUseCase = CreateDiaryUseCase(repository);
  final unlockDiaryUseCase = UnlockDiaryUseCase(repository);
  final loadDiaryEntryUseCase = LoadDiaryEntryUseCase(repository);
  final saveDiaryEntryUseCase = SaveDiaryEntryUseCase(repository);
  final updateDiaryAccessUseCase = UpdateDiaryAccessUseCase(repository);
  final loginViewModel =
      LoginViewModel(findDiaryUseCase, createDiaryUseCase, unlockDiaryUseCase);
  runApp(MyDiaryApp(
    loginViewModel: loginViewModel,
    loadDiaryEntryUseCase: loadDiaryEntryUseCase,
    saveDiaryEntryUseCase: saveDiaryEntryUseCase,
    updateDiaryAccessUseCase: updateDiaryAccessUseCase,
    configurationMessage: configurationMessage,
  ));
}

(DiaryApiClient, String?) _buildApiClient() {
  if (!AppEnvironment.hasBackendConfig) {
    return (
      const UnavailableDiaryApiClient(
        BackendConfigurationFailure(AppStrings.backendConfigurationMissing),
      ),
      AppStrings.backendConfigurationMissing,
    );
  }
  try {
    return (DioDiaryApiClient(), null);
  } on BackendConfigurationFailure catch (failure) {
    return (
      UnavailableDiaryApiClient(failure),
      AppStrings.backendConfigurationMissing
    );
  }
}

class MyDiaryApp extends StatelessWidget {
  const MyDiaryApp({
    required this.loginViewModel,
    required this.loadDiaryEntryUseCase,
    required this.saveDiaryEntryUseCase,
    required this.updateDiaryAccessUseCase,
    this.configurationMessage,
    super.key,
  });

  final LoginViewModel loginViewModel;
  final LoadDiaryEntryUseCase loadDiaryEntryUseCase;
  final SaveDiaryEntryUseCase saveDiaryEntryUseCase;
  final UpdateDiaryAccessUseCase updateDiaryAccessUseCase;
  final String? configurationMessage;

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
        updateDiaryAccessUseCase: updateDiaryAccessUseCase,
        configurationMessage: configurationMessage,
      ),
    );
  }
}
