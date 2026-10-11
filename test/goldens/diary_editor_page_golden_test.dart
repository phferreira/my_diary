import 'dart:typed_data';

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
    final previousComparator = goldenFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      Uri.parse('test/goldens/diary_editor_page_golden_test.dart'),
      // Allow minor text rasterization differences between Linux environments.
      precisionTolerance: 0.0003,
    );
    addTearDown(() => goldenFileComparator = previousComparator);

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
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'diary_editor_page');
  });
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required this.precisionTolerance,
  });

  final double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= precisionTolerance) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
