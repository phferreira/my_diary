import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/core/usecases/unlock_diary_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/ui/design_system/widgets/app_primary_button.dart';
import 'package:my_diary/ui/pages/login_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';

void main() {
  ({
    LoginViewModel viewModel,
    LoadDiaryEntryUseCase loadEntryUseCase,
    SaveDiaryEntryUseCase saveEntryUseCase,
    UpdateDiaryAccessUseCase updateAccessUseCase,
  }) buildDependencies() {
    final repository = InMemoryDiaryRepository();
    final findUseCase = FindDiaryUseCase(repository);
    final createUseCase = CreateDiaryUseCase(repository);
    final unlockUseCase = UnlockDiaryUseCase(repository);
    final loadEntryUseCase = LoadDiaryEntryUseCase(repository);
    final saveEntryUseCase = SaveDiaryEntryUseCase(repository);
    final updateAccessUseCase = UpdateDiaryAccessUseCase(repository);
    return (
      viewModel: LoginViewModel(findUseCase, createUseCase, unlockUseCase),
      loadEntryUseCase: loadEntryUseCase,
      saveEntryUseCase: saveEntryUseCase,
      updateAccessUseCase: updateAccessUseCase,
    );
  }

  testWidgets('exibe erro de configuração do backend no login',
      (WidgetTester tester) async {
    final deps = buildDependencies();
    await tester.pumpWidget(MaterialApp(
        home: LoginPage(
      viewModel: deps.viewModel,
      loadDiaryEntryUseCase: deps.loadEntryUseCase,
      saveDiaryEntryUseCase: deps.saveEntryUseCase,
      updateDiaryAccessUseCase: deps.updateAccessUseCase,
      configurationMessage: AppStrings.backendConfigurationMissing,
      appVersion: '1.0.0+1',
    )));
    expect(find.text(AppStrings.backendConfigurationMissing), findsOneWidget);
  });

  testWidgets('exibe falha de backend ao buscar diário e mantém a tela',
      (WidgetTester tester) async {
    final repository = _FailingLookupRepository();
    final viewModel = LoginViewModel(
      FindDiaryUseCase(repository),
      CreateDiaryUseCase(repository),
      UnlockDiaryUseCase(repository),
    );
    await tester.pumpWidget(MaterialApp(
        home: LoginPage(
      viewModel: viewModel,
      loadDiaryEntryUseCase: LoadDiaryEntryUseCase(repository),
      saveDiaryEntryUseCase: SaveDiaryEntryUseCase(repository),
      updateDiaryAccessUseCase: UpdateDiaryAccessUseCase(repository),
      appVersion: '1.0.0+1',
    )));
    await tester.enterText(find.byType(TextFormField), 'Diário');
    await tester
        .tap(find.widgetWithText(AppPrimaryButton, AppStrings.findDiaryButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.backendRequestFailed), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('exibe erros de validação ao submeter campo vazio', (
    WidgetTester tester,
  ) async {
    final deps = buildDependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: deps.viewModel,
          loadDiaryEntryUseCase: deps.loadEntryUseCase,
          saveDiaryEntryUseCase: deps.saveEntryUseCase,
          updateDiaryAccessUseCase: deps.updateAccessUseCase,
          appVersion: '1.0.0+1',
        ),
      ),
    );

    await tester.tap(
      find.widgetWithText(AppPrimaryButton, 'Encontrar diário'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informe o diário que deseja encontrar'), findsOneWidget);
  });

  testWidgets('pede senha ao encontrar diário protegido',
      (WidgetTester tester) async {
    final deps = buildDependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: deps.viewModel,
          loadDiaryEntryUseCase: deps.loadEntryUseCase,
          saveDiaryEntryUseCase: deps.saveEntryUseCase,
          updateDiaryAccessUseCase: deps.updateAccessUseCase,
          appVersion: '1.0.0+1',
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Trabalho');
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Encontrar diário'));
    await tester.pumpAndSettle();

    expect(find.text('Este diário é protegido por senha'), findsOneWidget);
  });

  testWidgets('submete ao pressionar enter no campo de diário', (
    WidgetTester tester,
  ) async {
    final deps = buildDependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: deps.viewModel,
          loadDiaryEntryUseCase: deps.loadEntryUseCase,
          saveDiaryEntryUseCase: deps.saveEntryUseCase,
          updateDiaryAccessUseCase: deps.updateAccessUseCase,
          appVersion: '1.0.0+1',
        ),
      ),
    );

    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.enterText(field, 'Trabalho');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Este diário é protegido por senha'), findsOneWidget);
  });

  testWidgets('oferece criação quando diário não é encontrado', (
    WidgetTester tester,
  ) async {
    final deps = buildDependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: deps.viewModel,
          loadDiaryEntryUseCase: deps.loadEntryUseCase,
          saveDiaryEntryUseCase: deps.saveEntryUseCase,
          updateDiaryAccessUseCase: deps.updateAccessUseCase,
          appVersion: '1.0.0+1',
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Diario Inexistente');
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Encontrar diário'));
    await tester.pumpAndSettle();

    expect(find.text('Criar diário'), findsOneWidget);
  });

  testWidgets('mantém campos de criação visíveis sem opção pública', (
    WidgetTester tester,
  ) async {
    final deps = buildDependencies();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: deps.viewModel,
          loadDiaryEntryUseCase: deps.loadEntryUseCase,
          saveDiaryEntryUseCase: deps.saveEntryUseCase,
          updateDiaryAccessUseCase: deps.updateAccessUseCase,
          appVersion: '1.0.0+1',
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Novo Diario');
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Encontrar diário'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.createDiaryTitle), findsOneWidget);
    expect(find.text(AppStrings.newDiaryPasswordLabel), findsOneWidget);
    expect(find.text(AppStrings.confirmPasswordLabel), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('mantém diálogo e mostra erro quando o backend falha ao criar', (
    WidgetTester tester,
  ) async {
    final repository = _FailingCreateRepository();
    final viewModel = LoginViewModel(
      FindDiaryUseCase(repository),
      CreateDiaryUseCase(repository),
      UnlockDiaryUseCase(repository),
    );
    await tester.pumpWidget(MaterialApp(
      home: LoginPage(
        viewModel: viewModel,
        loadDiaryEntryUseCase: LoadDiaryEntryUseCase(repository),
        saveDiaryEntryUseCase: SaveDiaryEntryUseCase(repository),
        updateDiaryAccessUseCase: UpdateDiaryAccessUseCase(repository),
      ),
    ));
    await tester.enterText(find.byType(TextFormField), 'Novo Diário');
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Encontrar diário'));
    await tester.pumpAndSettle();

    final passwordField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == AppStrings.newDiaryPasswordLabel,
    );
    final confirmationField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == AppStrings.confirmPasswordLabel,
    );
    await tester.enterText(passwordField, '1234');
    await tester.enterText(confirmationField, '1234');
    expect(tester.widget<TextField>(passwordField).controller!.text, '1234');
    expect(
        tester.widget<TextField>(confirmationField).controller!.text, '1234');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final createButton =
        find.widgetWithText(FilledButton, AppStrings.openDiary);
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.passwordMinLength), findsNothing);
    expect(find.text(AppStrings.passwordsDontMatch), findsNothing);
    expect(repository.createCalled, isTrue);
    expect(find.text(AppStrings.backendRequestFailed), findsOneWidget);
    expect(find.text(AppStrings.createDiaryTitle), findsOneWidget);
  });
}

class _FailingLookupRepository extends InMemoryDiaryRepository {
  @override
  Future<Diary?> findByName(String query) async =>
      throw StateError('backend unavailable');
}

class _FailingCreateRepository extends InMemoryDiaryRepository {
  bool createCalled = false;

  @override
  Future<Diary> createDiary({
    required String name,
    required String? password,
    required bool isPublic,
    String? publicPassword,
  }) async {
    createCalled = true;
    throw StateError('backend unavailable');
  }
}
