import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/update_diary_access_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';
import 'package:my_diary/ui/pages/diary_editor_page.dart';

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testGoldens('diary editor layouts', (WidgetTester tester) async {
    final repository = InMemoryDiaryRepository();

    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(
        devices: <Device>[
          Device.phone,
          Device.tabletLandscape,
        ],
      )
      ..addScenario(
        name: 'Diary editor',
        widget: MaterialApp(
          localizationsDelegates:
              FlutterQuillLocalizations.localizationsDelegates,
          supportedLocales: FlutterQuillLocalizations.supportedLocales,
          home: DiaryEditorPage(
            diary: const Diary(id: '1', name: 'Diario', content: ''),
            loadDiaryEntryUseCase: LoadDiaryEntryUseCase(repository),
            saveDiaryEntryUseCase: SaveDiaryEntryUseCase(repository),
            updateDiaryAccessUseCase: UpdateDiaryAccessUseCase(repository),
            initialDate: DateTime(2026, 3, 16),
          ),
        ),
      );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'diary_editor_page');
  });
}
