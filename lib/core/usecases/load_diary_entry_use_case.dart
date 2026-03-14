import 'package:my_diary/core/entities/diary_entry.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';

class LoadDiaryEntryUseCase {
  LoadDiaryEntryUseCase(this._repository);

  final DiaryRepository _repository;

  Future<DiaryEntry?> call({
    required String diaryId,
    required DateTime date,
  }) {
    return _repository.findEntryByDate(diaryId: diaryId, date: date);
  }
}
