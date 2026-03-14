import 'package:flutter_test/flutter_test.dart';
import 'package:my_diary/core/usecases/load_diary_entry_use_case.dart';
import 'package:my_diary/core/usecases/save_diary_entry_use_case.dart';
import 'package:my_diary/data/repositories/in_memory_diary_repository.dart';

void main() {
  test('SaveDiaryEntryUseCase stores content by date', () async {
    final repository = InMemoryDiaryRepository();
    final saveUseCase = SaveDiaryEntryUseCase(repository);
    final loadUseCase = LoadDiaryEntryUseCase(repository);

    const diaryId = '1';
    final targetDate = DateTime(2026, 3, 14, 10, 30);

    await saveUseCase(
      diaryId: diaryId,
      date: targetDate,
      content: 'Conteudo do dia 14',
    );

    final entry = await loadUseCase(
      diaryId: diaryId,
      date: DateTime(2026, 3, 14, 23, 59),
    );

    expect(entry, isNotNull);
    expect(entry!.content, 'Conteudo do dia 14');
  });

  test('LoadDiaryEntryUseCase returns null when no entry exists', () async {
    final repository = InMemoryDiaryRepository();
    final loadUseCase = LoadDiaryEntryUseCase(repository);

    final entry = await loadUseCase(
      diaryId: '1',
      date: DateTime(2026, 3, 15),
    );

    expect(entry, isNull);
  });
}
