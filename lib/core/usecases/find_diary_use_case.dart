import 'package:my_diary/core/entities/diary.dart';
import 'package:my_diary/core/repositories/diary_repository.dart';
import 'package:my_diary/core/value_objects/diary_query.dart';

class FindDiaryUseCase {
  FindDiaryUseCase(this._repository);

  final DiaryRepository _repository;

  Future<Diary?> call(String rawQuery) async {
    final validationError = DiaryQuery.validate(rawQuery);
    if (validationError != null) {
      return null;
    }

    return _repository.findByName(rawQuery.trim());
  }
}
