import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/usecases/find_diary_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/ui/pages/login_page.dart';
import 'package:my_diary/ui/view_models/login_view_model.dart';

void main() {
  LoginViewModel buildViewModel() {
    final repository = InMemoryDiaryRepository();
    final useCase = FindDiaryUseCase(repository);
    return LoginViewModel(useCase);
  }

  testWidgets('exibe erros de validação ao submeter campo vazio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(viewModel: buildViewModel()),
      ),
    );

    await tester.tap(find.text('Encontrar diário'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o diário que deseja encontrar'), findsOneWidget);
  });

  testWidgets('configura formatter para bloquear caracteres especiais', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(viewModel: buildViewModel()),
      ),
    );

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    final formatters = field.inputFormatters ?? <TextInputFormatter>[];

    expect(formatters.whereType<FilteringTextInputFormatter>(), isNotEmpty);

    final formatter = FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]'));
    final formatted = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(text: 'diario@123'),
    );

    expect(formatted.text, 'diario123');
  });

  testWidgets('mostra feedback quando diário é encontrado', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(viewModel: buildViewModel()),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'Trabalho');
    await tester.tap(find.text('Encontrar diário'));
    await tester.pumpAndSettle();

    expect(find.text('Diário encontrado: Trabalho'), findsOneWidget);
  });
}
