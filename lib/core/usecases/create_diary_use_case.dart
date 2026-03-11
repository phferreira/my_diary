import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';

class CreateDiaryUseCase {
  CreateDiaryUseCase(this._repository);

  final DiaryRepository _repository;

  Future<Diary> call({
    required String name,
    required String? password,
    required bool isPublic,
  }) {
    return _repository.createDiary(
      name: name,
      password: password,
      isPublic: isPublic,
    );
  }
}
