import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/entities/diary_access.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';

class UnlockDiaryUseCase {
  UnlockDiaryUseCase(this._repository);

  final DiaryRepository _repository;

  Future<DiaryAccess?> call({required Diary diary, required String password}) {
    return _repository.unlockDiary(diary: diary, password: password);
  }
}
