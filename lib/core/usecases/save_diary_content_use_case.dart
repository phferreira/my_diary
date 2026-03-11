import 'package:my_diary/core/repositories/diary_repository.dart';

class SaveDiaryContentUseCase {
  SaveDiaryContentUseCase(this._repository);

  final DiaryRepository _repository;

  Future<void> call({
    required String diaryId,
    required String content,
  }) {
    return _repository.updateDiaryContent(id: diaryId, content: content);
  }
}
