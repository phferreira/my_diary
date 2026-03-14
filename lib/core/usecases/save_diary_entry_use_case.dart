import 'package:my_diary/core/repositories/diary_repository.dart';

class SaveDiaryEntryUseCase {
  SaveDiaryEntryUseCase(this._repository);

  final DiaryRepository _repository;

  Future<void> call({
    required String diaryId,
    required DateTime date,
    required String content,
  }) {
    return _repository.upsertDiaryEntry(
      diaryId: diaryId,
      date: date,
      content: content,
    );
  }
}
