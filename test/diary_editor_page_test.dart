import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/ui/pages/diary_editor_page.dart';

void main() {
  DiaryEditorPage buildSubject({
    required InMemoryDiaryRepository repository,
    DateTime? initialDate,
  }) {
    return DiaryEditorPage(
      diary: const Diary(id: '1', name: 'Diario', content: ''),
      loadDiaryEntryUseCase: LoadDiaryEntryUseCase(repository),
      saveDiaryEntryUseCase: SaveDiaryEntryUseCase(repository),
      updateDiaryAccessUseCase: UpdateDiaryAccessUseCase(repository),
      initialDate: initialDate,
    );
  }

  testWidgets('exibe data inicial configurada', (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository();
    final initialDate = DateTime(2026, 3, 16, 18, 45);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: buildSubject(
          repository: repository,
          initialDate: initialDate,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DiaryEditorPage));
    final localizations = MaterialLocalizations.of(context);
    final expectedLabel = localizations.formatFullDate(DateTime(2026, 3, 16));

    expect(find.text(expectedLabel), findsOneWidget);
  });

  testWidgets('usa layout mobile em telas estreitas',
      (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository();

    tester.binding.window.physicalSizeTestValue = const Size(420, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: buildSubject(repository: repository),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diary-editor-mobile')), findsOneWidget);
    expect(find.byKey(const Key('diary-editor-desktop')), findsNothing);
  });

  testWidgets('usa layout desktop em telas largas',
      (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository();

    tester.binding.window.physicalSizeTestValue = const Size(1024, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: buildSubject(repository: repository),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diary-editor-desktop')), findsOneWidget);
    expect(find.byKey(const Key('diary-editor-mobile')), findsNothing);
  });
}
