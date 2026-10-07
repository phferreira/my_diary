import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_diary/core/constants/app_strings.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/ui/pages/diary_editor_page.dart';

void main() {
  DiaryEditorPage buildSubject({
    required InMemoryDiaryRepository repository,
    Diary diary = const Diary(id: '1', name: 'Diario', content: ''),
    DateTime? initialDate,
    bool canEdit = true,
  }) {
    return DiaryEditorPage(
      diary: diary,
      loadDiaryEntryUseCase: LoadDiaryEntryUseCase(repository),
      saveDiaryEntryUseCase: SaveDiaryEntryUseCase(repository),
      updateDiaryAccessUseCase: UpdateDiaryAccessUseCase(repository),
      canEdit: canEdit,
      initialDate: initialDate,
    );
  }

  testWidgets('mantém texto visível quando o backend rejeita o salvamento',
      (WidgetTester tester) async {
    final repository = _FailingSaveRepository();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      home: buildSubject(repository: repository),
    ));
    await tester.pumpAndSettle();
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    editor.controller.document.insert(0, 'rascunho local');
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.entrySaveFailed), findsOneWidget);
    expect(
        editor.controller.document.toPlainText(), contains('rascunho local'));
  });

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

  testWidgets('mostra botão de configuração em modo editável',
      (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository(
      seedDiaries: const <Diary>[
        Diary(id: '1', name: 'Diario', content: '', isPublic: true),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: buildSubject(
          repository: repository,
          diary: const Diary(
            id: '1',
            name: 'Diario',
            content: '',
            isPublic: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(AppStrings.configuration), findsOneWidget);
  });

  testWidgets('mostra erro quando o backend rejeita a configuração de acesso',
      (WidgetTester tester) async {
    final repository = _FailingAccessUpdateRepository();
    const diary = Diary(id: '1', name: 'Diario', content: 'rascunho');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: buildSubject(repository: repository, diary: diary),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.configuration));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.diaryVisibilityError), findsOneWidget);
    expect(find.byType(DiaryEditorPage), findsOneWidget);
  });

  testWidgets('abre diário público em modo somente leitura',
      (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository(
      seedDiaries: <Diary>[
        const Diary(
          id: '1',
          name: 'Diario',
          content: '',
          isPublic: true,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: buildSubject(
          repository: repository,
          diary: const Diary(
            id: '1',
            name: 'Diario',
            content: '',
            isPublic: true,
          ),
          canEdit: false,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.publicAccessReadOnlyDescription),
      findsOneWidget,
    );
    expect(find.text(AppStrings.configuration), findsNothing);
    expect(find.byType(QuillSimpleToolbar), findsNothing);
  });
}

class _FailingAccessUpdateRepository extends InMemoryDiaryRepository {
  @override
  Future<void> updateDiaryAccess({
    required String id,
    required bool isPublic,
    String? password,
    String? publicPassword,
  }) async =>
      throw StateError('backend unavailable');
}

class _FailingSaveRepository extends InMemoryDiaryRepository {
  @override
  Future<void> upsertDiaryEntry(
      {required String diaryId,
      required DateTime date,
      required String content}) async {
    throw StateError('backend save failed');
  }
}
