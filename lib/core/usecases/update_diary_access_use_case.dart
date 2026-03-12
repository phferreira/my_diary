import 'package:my_diary/core/repositories/diary_repository.dart';

class UpdateDiaryAccessUseCase {
  UpdateDiaryAccessUseCase(this._repository);

  final DiaryRepository _repository;

  Future<void> call({
    required String diaryId,
    required bool isPublic,
    String? password,
  }) {
    return _repository.updateDiaryAccess(
      id: diaryId,
      isPublic: isPublic,
      password: password,
    );
  }
}
