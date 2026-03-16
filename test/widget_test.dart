import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/constants/app_strings.dart';
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
  testWidgets('renderiza tela de login com CTA principal',
      (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository();
    final viewModel = LoginViewModel(
      FindDiaryUseCase(repository),
      CreateDiaryUseCase(repository),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: viewModel,
          loadDiaryEntryUseCase: LoadDiaryEntryUseCase(repository),
          saveDiaryEntryUseCase: SaveDiaryEntryUseCase(repository),
          updateDiaryAccessUseCase: UpdateDiaryAccessUseCase(repository),
          appVersion: '1.0.0+1',
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      find.widgetWithText(AppPrimaryButton, AppStrings.findDiaryButton),
      findsOneWidget,
    );
  });
}
