import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/usecases/create_diary_use_case.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
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
    final loadEntryUseCase = LoadDiaryEntryUseCase(repository);
    final saveEntryUseCase = SaveDiaryEntryUseCase(repository);
    final updateAccessUseCase = UpdateDiaryAccessUseCase(repository);
    return (
      viewModel: LoginViewModel(findUseCase, createUseCase),
      loadEntryUseCase: loadEntryUseCase,
      saveEntryUseCase: saveEntryUseCase,
      updateAccessUseCase: updateAccessUseCase,
    );
  }

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
}
