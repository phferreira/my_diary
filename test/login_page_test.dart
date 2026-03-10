import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/ui/pages/login_page.dart';

void main() {
  testWidgets('exibe erros de validação ao submeter campo vazio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    await tester.tap(find.text('Encontrar diário'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o diário que deseja encontrar'), findsOneWidget);
  });

  testWidgets('bloqueia caractere especial no campo', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    final finder = find.byType(TextFormField);
    await tester.enterText(finder, 'diario@123');
    await tester.pump();

    final textField = tester.widget<TextFormField>(finder);
    final formatters = textField.inputFormatters!;
    final formatter = formatters.firstWhere(
      (TextInputFormatter item) => item is FilteringTextInputFormatter,
    ) as FilteringTextInputFormatter;

    final oldValue = const TextEditingValue();
    const newValue = TextEditingValue(text: 'diario@123');
    final formatted = formatter.formatEditUpdate(oldValue, newValue);

    expect(formatted.text, 'diario123');
  });
}
